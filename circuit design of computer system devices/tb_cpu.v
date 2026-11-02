`timescale 1ns/1ps
// ============================================================
// Тестбенч для cpu_top
// Набор входных чисел n совпадает с набором тестов эмулятора
// (verify.py, список TESTS); ожидаемый результат считается
// независимо от процессора - поведенческой функцией digits().
// Запуск:  iverilog -o sim tb_cpu.v cpu_core.v && vvp sim
// (файл prog.mem должен лежать в текущей папке)
// ============================================================
module tb_cpu;
    localparam NTESTS    = 14;
    localparam CYC_LIMIT = 400000;   // с запасом: максимум по тестам ~87500 тактов
    localparam [9:0] OUT_ADDR = 10'd20;

    reg         clk = 1'b0;
    reg         rst = 1'b1;
    wire [15:0] rd_data;
    wire        done;

    reg [15:0] vec [0:NTESTS-1];
    integer    t;
    integer    errors;
    integer    cycles;
    integer    expected;

    cpu_top uut (
        .clk     (clk),
        .rst     (rst),
        .rd_addr (OUT_ADDR),
        .rd_data (rd_data),
        .done    (done)
    );

    always #5 clk = ~clk;            // период 10 нс

    // эталон: количество десятичных цифр числа
    function integer digits;
        input integer v;
        integer x;
        begin
            if (v == 0)
                digits = 1;
            else begin
                digits = 0;
                x = v;
                while (x > 0) begin
                    digits = digits + 1;
                    x = x / 10;
                end
            end
        end
    endfunction

    initial begin
        // те же числа, что в тестах эмулятора (1000000 заменён на 65535 - предел 16 бит)
        vec[0]  = 16'd0;     vec[1]  = 16'd9;     vec[2]  = 16'd10;
        vec[3]  = 16'd99;    vec[4]  = 16'd100;   vec[5]  = 16'd999;
        vec[6]  = 16'd12345; vec[7]  = 16'd65535; vec[8]  = 16'd1;
        vec[9]  = 16'd5;     vec[10] = 16'd42;    vec[11] = 16'd1000;
        vec[12] = 16'd9999;  vec[13] = 16'd10000;

        errors = 0;
        for (t = 0; t < NTESTS; t = t + 1) begin
            // число n подставляется в литерал команды 0 (LTR r0, n), как в эмуляторе
            uut.u_prog.mem[0] = {4'h0, 4'h0, vec[t]};

            // сброс
            rst = 1'b1;
            repeat (2) @(posedge clk);
            #1 rst = 1'b0;

            // ждём останова
            cycles = 0;
            while (!done && cycles < CYC_LIMIT) begin
                @(posedge clk);
                cycles = cycles + 1;
            end

            // чтение из памяти данных синхронное: ждём 2 такта
            repeat (2) @(posedge clk);
            #1;

            expected = digits(vec[t]);
            if (!done) begin
                $display("FAIL n=%0d : таймаут (%0d тактов)", vec[t], cycles);
                errors = errors + 1;
            end else if (rd_data !== expected[15:0]) begin
                $display("FAIL n=%0d : получено %0d, ожидалось %0d", vec[t], rd_data, expected);
                errors = errors + 1;
            end else begin
                $display("PASS n=%0d : цифр = %0d (тактов: %0d)", vec[t], rd_data, cycles);
            end
        end

        if (errors == 0)
            $display("ВСЕ %0d ТЕСТОВ ПРОЙДЕНЫ", NTESTS);
        else
            $display("ОШИБОК: %0d", errors);
        $finish;
    end
endmodule
