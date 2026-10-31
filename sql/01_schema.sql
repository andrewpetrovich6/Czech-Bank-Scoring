create schema if not exists raw;
DROP TABLE IF EXISTS raw.trans;
create table raw.trans(
	trans_id int,
	account_id int, 
	date varchar,
	type varchar,
	operation varchar,
	amount numeric(12, 2),
	balance numeric(12, 2), 
	k_symbol varchar,
	bank varchar,
	account varchar,
	primary key(trans_id)	
);

DROP TABLE IF EXISTS raw.account;
create table raw.account(
	account_id int,
	district_id int,
	frequency varchar,
	date varchar,
	primary key(account_id)
);

DROP TABLE IF EXISTS raw.client;
create table raw.client(
	client_id int,
	birth_number varchar,
	district_id int,
	primary key(client_id)
);

DROP TABLE IF EXISTS raw.disp;
create table raw.disp(
	disp_id int,
	client_id int,
	account_id int,
	type varchar,
	primary key(disp_id)
);

DROP TABLE IF EXISTS raw.loan;
create table raw.loan(
	loan_id int,
	account_id int,
	date varchar,
	amount numeric(12, 2),
	duration int,
	payments numeric(12, 2),
	status varchar,
	primary key(loan_id)
);

DROP TABLE IF EXISTS raw.card;
create table raw.card(
	card_id int,
	disp_id int,
	type varchar,
	issued varchar,
	primary key(card_id)
);

DROP TABLE IF EXISTS raw.orders;
create table raw.orders(
	order_id int,
	account_id int,
	bank_to varchar,
	account_to varchar,
	amount numeric(12, 2),
	k_symbol varchar,
	primary key(order_id)
);

DROP TABLE IF EXISTS raw.district;
create table raw.district(
	a1 int,
	a2 varchar,
	a3 varchar,
	a4 int,
	a5 int,
	a6 int,
	a7 int,
	a8 int,
	a9 int,
	a10 numeric,
	a11 int,
	a12 varchar,
	a13 numeric,
	a14 int,
	a15 varchar,
	a16 int,
	primary key(a1)
);
