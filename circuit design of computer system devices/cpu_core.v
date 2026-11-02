// ============================================================
// Последовательное процессорное ядро (RTL-модель)
// Вариант: количество цифр в десятичной записи числа n
// Система команд: LTR, SUB, INCR, JMPL, JMP, RTM
// Каждая команда выполняется за 3 такта: FETCH -> DECODE -> EXECUTE
// ============================================================

// ------------------------------------------------------------
// Память команд PROG: 1024 x 24 бит, синхронное чтение -> блочная память
// ------------------------------------------------------------
module prog_mem #(
    parameter AW   = 10,
    parameter DW   = 24,
    parameter INIT = "prog.mem"
) (
    input  wire          clk,
    input  wire [AW-1:0] addr,
    output reg  [DW-1:0] dout
);
    (* ram_style = "block" *) reg [DW-1:0] mem [0:(1<<AW)-1];

    integer i;
    initial begin
        for (i = 0; i < (1<<AW); i = i + 1)
            mem[i] = {DW{1'b0}};
        $readmemh(INIT, mem);
    end

    always @(posedge clk)
        dout <= mem[addr];
endmodule

// ------------------------------------------------------------
// Память данных MEM: 1024 x 16 бит, запись + синхронное чтение -> блочная память
// Порт чтения нужен, чтобы результат был виден снаружи
// (иначе синтезатор удалит память, в которую никто не читает)
// ------------------------------------------------------------
module data_mem #(
    parameter AW = 10,
    parameter DW = 16
) (
    input  wire          clk,
    input  wire          we,
    input  wire [AW-1:0] waddr,
    input  wire [DW-1:0] wdata,
    input  wire [AW-1:0] raddr,
    output reg  [DW-1:0] rdata
);
    (* ram_style = "block" *) reg [DW-1:0] mem [0:(1<<AW)-1];

    integer i;
    initial begin
        for (i = 0; i < (1<<AW); i = i + 1)
            mem[i] = {DW{1'b0}};
    end

    always @(posedge clk) begin
        if (we)
            mem[waddr] <= wdata;
        rdata <= mem[raddr];
    end
endmodule

// ------------------------------------------------------------
// Верхний модуль: процессорное ядро + PROG + MEM
// ------------------------------------------------------------
module cpu_top #(
    parameter HALT_ADDR = 10'd21,        // адрес команды JMP на себя (останов)
    parameter INIT      = "prog.mem"
) (
    input  wire        clk,
    input  wire        rst,              // синхронный сброс, активный уровень 1
    input  wire [9:0]  rd_addr,          // адрес чтения из памяти данных (результат)
    output wire [15:0] rd_data,          // данные памяти данных (с задержкой в 1 такт)
    output wire        done              // 1, когда программа дошла до останова
);
    // коды операций
    localparam [3:0] OP_LTR  = 4'd0;
    localparam [3:0] OP_SUB  = 4'd1;
    localparam [3:0] OP_INCR = 4'd2;
    localparam [3:0] OP_JMPL = 4'd3;
    localparam [3:0] OP_JMP  = 4'd4;
    localparam [3:0] OP_RTM  = 4'd5;

    // состояния автомата
    localparam [1:0] S_FETCH  = 2'd0;
    localparam [1:0] S_DECODE = 2'd1;
    localparam [1:0] S_EXEC   = 2'd2;
    localparam [1:0] S_HALT   = 2'd3;

    reg [1:0]  state;
    reg [9:0]  pc;                       // счётчик команд PC
    reg [23:0] rg_com;                   // регистр команд RG_COM
    reg [15:0] reg_a;                    // регистр-операнд A
    reg [15:0] reg_b;                    // регистр-операнд B
    reg [15:0] rf [0:15];                // регистровый файл RF

    wire [23:0] prog_dout;               // выход блочной памяти команд

    // память команд: адрес берётся из PC
    prog_mem #(.AW(10), .DW(24), .INIT(INIT)) u_prog (
        .clk  (clk),
        .addr (pc),
        .dout (prog_dout)
    );

    // память данных: запись команды RTM происходит в такте EXECUTE
    wire        mem_we = (state == S_EXEC) && (rg_com[23:20] == OP_RTM);

    data_mem #(.AW(10), .DW(16)) u_data (
        .clk   (clk),
        .we    (mem_we),
        .waddr (reg_a[9:0]),
        .wdata (reg_b),
        .raddr (rd_addr),
        .rdata (rd_data)
    );

    assign done = (state == S_HALT);

    integer k;
    always @(posedge clk) begin
        if (rst) begin
            state  <= S_FETCH;
            pc     <= 10'd0;
            rg_com <= 24'd0;
            reg_a  <= 16'd0;
            reg_b  <= 16'd0;
            for (k = 0; k < 16; k = k + 1)
                rf[k] <= 16'd0;
        end else begin
            case (state)
                // ---- FETCH: адрес = PC уже подан на память команд,
                //      к следующему такту команда окажется на prog_dout
                S_FETCH: begin
                    if (pc == HALT_ADDR)
                        state <= S_HALT;
                    else
                        state <= S_DECODE;
                end

                // ---- DECODE: сохраняем команду в RG_COM, читаем операнды
                S_DECODE: begin
                    rg_com <= prog_dout;
                    case (prog_dout[23:20])
                        OP_LTR: begin
                            reg_a <= prog_dout[15:0];
                            reg_b <= {12'd0, prog_dout[19:16]};
                        end
                        OP_INCR: begin
                            reg_a <= rf[prog_dout[19:16]];
                            reg_b <= 16'd1;
                        end
                        OP_SUB, OP_JMPL, OP_RTM: begin
                            reg_a <= rf[prog_dout[19:16]];
                            reg_b <= rf[prog_dout[15:12]];
                        end
                        default: begin
                            // JMP: операнды не нужны
                        end
                    endcase
                    state <= S_EXEC;
                end

                // ---- EXECUTE: выполнение и формирование нового PC
                S_EXEC: begin
                    case (rg_com[23:20])
                        OP_LTR: begin
                            rf[reg_b[3:0]] <= reg_a;
                            pc <= pc + 10'd1;
                        end
                        OP_SUB: begin
                            rf[rg_com[11:8]] <= reg_a - reg_b;
                            pc <= pc + 10'd1;
                        end
                        OP_INCR: begin
                            rf[rg_com[19:16]] <= reg_a + reg_b;
                            pc <= pc + 10'd1;
                        end
                        OP_JMPL: begin
                            if (reg_a < reg_b)
                                pc <= rg_com[9:0];
                            else
                                pc <= pc + 10'd1;
                        end
                        OP_JMP: begin
                            pc <= rg_com[9:0];
                        end
                        OP_RTM: begin
                            // запись в MEM выполняет память данных (mem_we)
                            pc <= pc + 10'd1;
                        end
                        default: begin
                            pc <= pc + 10'd1;
                        end
                    endcase
                    state <= S_FETCH;
                end

                // ---- HALT: программа завершена
                S_HALT: begin
                    state <= S_HALT;
                end
            endcase
        end
    end
endmodule
