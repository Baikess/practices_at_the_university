

CREATE TABLE write_off (
  id integer NOT NULL PRIMARY KEY,
  number varchar(500) NOT NULL UNIQUE,
  date timestamp with time zone NOT NULL,
  employee_id integer NOT NULL,
  reason varchar(500) NOT NULL
);


CREATE TABLE paymant_type (
  id integer NOT NULL PRIMARY KEY,
  name varchar(500) NOT NULL UNIQUE
);


CREATE TABLE stock (
  id serial NOT NULL PRIMARY KEY,
  product_id integer NOT NULL,
  store_id integer NOT NULL,
  quantity integer NOT NULL,
  min_quantity integer,
  link_inventory_id integer NOT NULL
);


CREATE TABLE sale (
  id integer NOT NULL PRIMARY KEY,
  number varchar(500) NOT NULL UNIQUE,
  date timestamp with time zone NOT NULL,
  employee integer NOT NULL,
  client_id integer,
  payment_type_id integer NOT NULL,
  total_amount numeric NOT NULL
);


CREATE TABLE sale_item (
  id serial NOT NULL PRIMARY KEY,
  sale_id integer NOT NULL,
  product_id integer NOT NULL,
  quantity integer NOT NULL,
  price numeric NOT NULL
);


CREATE TABLE product (
  id integer NOT NULL PRIMARY KEY,
  name varchar(500) NOT NULL,
  category_id integer NOT NULL,
  manufacturer_id integer NOT NULL,
  unit_id integer NOT NULL,
  barcode char NOT NULL UNIQUE,
  retail_price numeric NOT NULL,
  expiration_date date
);


CREATE TABLE supplier (
  id integer NOT NULL PRIMARY KEY,
  name varchar(500) NOT NULL UNIQUE,
  inn varchar(500) NOT NULL UNIQUE,
  phone varchar(500),
  address varchar(500)
);


CREATE TABLE loyalty_level (
  id integer NOT NULL PRIMARY KEY,
  name varchar(500) NOT NULL UNIQUE,
  discount numeric NOT NULL
);


CREATE TABLE loyalty_card (
  id serial NOT NULL PRIMARY KEY,
  number varchar(500) NOT NULL UNIQUE,
  client_id integer NOT NULL,
  loyalty_level integer NOT NULL,
  issue_date date NOT NULL
);


CREATE TABLE return_item (
  id serial NOT NULL PRIMARY KEY,
  return_id integer NOT NULL,
  product_id integer NOT NULL,
  quantity integer NOT NULL,
  reason varchar(500) NOT NULL
);


CREATE TABLE store (
  id integer NOT NULL PRIMARY KEY,
  name varchar(500) NOT NULL UNIQUE,
  address varchar(500) NOT NULL,
  phone varchar(500)
);


CREATE TABLE write_off_item (
  id serial NOT NULL PRIMARY KEY,
  write_off_id integer NOT NULL,
  product_id integer NOT NULL,
  quantity integer NOT NULL
);


CREATE TABLE manufacturer (
  id integer NOT NULL PRIMARY KEY,
  country_id integer NOT NULL,
  name varchar(500) NOT NULL UNIQUE
);


CREATE TABLE supply_item (
  id serial NOT NULL PRIMARY KEY,
  supply_id integer NOT NULL,
  product_id integer NOT NULL,
  quantity integer NOT NULL,
  price numeric NOT NULL
);


CREATE TABLE category (
  id integer NOT NULL PRIMARY KEY,
  name varchar(500) NOT NULL UNIQUE
);


CREATE TABLE country (
  id integer NOT NULL PRIMARY KEY,
  name varchar(500) NOT NULL UNIQUE,
  code char NOT NULL UNIQUE
);


CREATE TABLE supply (
  id integer NOT NULL PRIMARY KEY,
  number varchar(500) NOT NULL UNIQUE,
  date timestamp with time zone NOT NULL,
  supplier_id integer NOT NULL,
  store_id integer NOT NULL,
  summa numeric NOT NULL
);


CREATE TABLE client (
  id integer NOT NULL PRIMARY KEY,
  last_name varchar(500),
  first_name varchar(500),
  phone varchar(500) NOT NULL UNIQUE,
  email varchar(500) UNIQUE
);


CREATE TABLE position (
  id integer NOT NULL PRIMARY KEY,
  name varchar(500) NOT NULL UNIQUE
);


CREATE TABLE unit (
  id integer NOT NULL PRIMARY KEY,
  name varchar(500) NOT NULL UNIQUE,
  short_name char NOT NULL UNIQUE
);


CREATE TABLE return (
  id integer NOT NULL PRIMARY KEY,
  number varchar(500) NOT NULL UNIQUE,
  date timestamp with time zone NOT NULL,
  sale_id integer NOT NULL,
  client_id integer NOT NULL,
  return_amount numeric NOT NULL
);


CREATE TABLE employee (
  id integer NOT NULL PRIMARY KEY,
  last_name varchar(500) NOT NULL,
  first_name varchar(500) NOT NULL,
  middle_name varchar(500),
  position_id integer NOT NULL,
  store_id integer NOT NULL,
  hire_date date NOT NULL,
  password_date varchar(500) NOT NULL UNIQUE
);


CREATE TABLE inventory (
  id integer NOT NULL PRIMARY KEY,
  date timestamp with time zone NOT NULL,
  store_id integer NOT NULL,
  employee_id integer NOT NULL,
  actual_store integer NOT NULL
);


ALTER TABLE supply ADD CONSTRAINT supply_supplier_id_fk FOREIGN KEY (supplier_id) REFERENCES supplier (id);
ALTER TABLE supply_item ADD CONSTRAINT supply_item_supply_id_fk FOREIGN KEY (supply_id) REFERENCES supply (id);
ALTER TABLE product ADD CONSTRAINT product_category_id_fk FOREIGN KEY (category_id) REFERENCES category (id);
ALTER TABLE product ADD CONSTRAINT product_manufacturer_id_fk FOREIGN KEY (manufacturer_id) REFERENCES manufacturer (id);
ALTER TABLE product ADD CONSTRAINT product_unit_id_fk FOREIGN KEY (unit_id) REFERENCES unit (id);
ALTER TABLE manufacturer ADD CONSTRAINT manufacturer_country_id_fk FOREIGN KEY (country_id) REFERENCES country (id);
ALTER TABLE employee ADD CONSTRAINT employee_position_id_fk FOREIGN KEY (position_id) REFERENCES position (id);
ALTER TABLE employee ADD CONSTRAINT employee_store_id_fk FOREIGN KEY (store_id) REFERENCES store (id);
ALTER TABLE loyalty_card ADD CONSTRAINT loyalty_card_client_id_fk FOREIGN KEY (client_id) REFERENCES client (id);
ALTER TABLE loyalty_card ADD CONSTRAINT loyalty_card_loyalty_level_fk FOREIGN KEY (loyalty_level) REFERENCES loyalty_level (id);
ALTER TABLE supply_item ADD CONSTRAINT supply_item_product_id_fk FOREIGN KEY (product_id) REFERENCES product (id);
ALTER TABLE sale ADD CONSTRAINT sale_employee_fk FOREIGN KEY (employee) REFERENCES employee (id);
ALTER TABLE sale ADD CONSTRAINT sale_client_id_fk FOREIGN KEY (client_id) REFERENCES client (id);
ALTER TABLE sale ADD CONSTRAINT sale_payment_type_id_fk FOREIGN KEY (payment_type_id) REFERENCES paymant_type (id);
ALTER TABLE sale_item ADD CONSTRAINT sale_item_sale_id_fk FOREIGN KEY (sale_id) REFERENCES sale (id);
ALTER TABLE sale_item ADD CONSTRAINT sale_item_product_id_fk FOREIGN KEY (product_id) REFERENCES product (id);
ALTER TABLE write_off ADD CONSTRAINT write_off_employee_id_fk FOREIGN KEY (employee_id) REFERENCES employee (id);
ALTER TABLE return ADD CONSTRAINT return_sale_id_fk FOREIGN KEY (sale_id) REFERENCES sale (id);
ALTER TABLE return ADD CONSTRAINT return_client_id_fk FOREIGN KEY (client_id) REFERENCES client (id);
ALTER TABLE supply ADD CONSTRAINT supply_store_id_fk FOREIGN KEY (store_id) REFERENCES store (id);
ALTER TABLE write_off_item ADD CONSTRAINT write_off_item_write_off_id_fk FOREIGN KEY (write_off_id) REFERENCES write_off (id);
ALTER TABLE write_off_item ADD CONSTRAINT write_off_item_product_id_fk FOREIGN KEY (product_id) REFERENCES product (id);
ALTER TABLE return_item ADD CONSTRAINT return_item_return_id_fk FOREIGN KEY (return_id) REFERENCES return (id);
ALTER TABLE return_item ADD CONSTRAINT return_item_product_id_fk FOREIGN KEY (product_id) REFERENCES product (id);
ALTER TABLE stock ADD CONSTRAINT stock_product_id_fk FOREIGN KEY (product_id) REFERENCES product (id);
ALTER TABLE stock ADD CONSTRAINT stock_store_id_fk FOREIGN KEY (store_id) REFERENCES store (id);
ALTER TABLE stock ADD CONSTRAINT stock_link_inventory_id_fk FOREIGN KEY (link_inventory_id) REFERENCES inventory (id);
ALTER TABLE inventory ADD CONSTRAINT inventory_store_id_fk FOREIGN KEY (store_id) REFERENCES store (id);
ALTER TABLE inventory ADD CONSTRAINT inventory_employee_id_fk FOREIGN KEY (employee_id) REFERENCES employee (id);
