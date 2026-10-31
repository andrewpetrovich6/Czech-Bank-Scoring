--Подсчет строк
select 'account' as tbl, count(*) as n_rows from raw.account 
union select 'card',count(*) from raw.card
union select 'client',count(*) from raw.client
union select 'disp',count(*) from raw.disp
union select 'district',count(*) from raw.district
union select 'loan',count(*) from raw.loan
union select 'orders',count(*) from raw.orders
union select 'trans',count(*) from raw.trans order by tbl asc;
--Проверка дубликатов в первичном ключе
select 'account' as tbl, count(*) = count(distinct account_id) as eq from raw.account 
union select 'card',count(*) = count(distinct card_id) from raw.card
union select 'client',count(*)= count(distinct client_id)  from raw.client
union select 'disp',count(*)= count(distinct disp_id)  from raw.disp
union select 'district', count(*) = count(distinct a1) from raw.district
union select 'loan',count(*)= count(distinct loan_id) from raw.loan
union select 'orders',count(*)= count(distinct order_id) from raw.orders
union select 'trans',count(*)= count(distinct trans_id)  from raw.trans order by tbl asc;
--Проверка на ссылку на несуществующую запись
select count(*) from raw.loan as l left join raw.account as r on l.account_id = r.account_id where r.account_id is Null;
select count(*) from raw.trans as l left join raw.account as r on l.account_id = r.account_id where r.account_id is Null;
select count(*) from raw.orders as l left join raw.account as r on l.account_id = r.account_id where r.account_id is Null;
select count(*) from raw.disp as l left join raw.account as r on l.account_id = r.account_id where r.account_id is Null;
select count(*) from raw.disp as l left join raw.client as r on l.client_id = r.client_id where r.client_id is Null;
select count(*) from raw.card as l left join raw.disp as r on l.disp_id = r.disp_id where r.disp_id is Null;
select count(*) from raw.account as l left join raw.district as r on l.district_id = r.a1 where r.a1 is Null;
select count(*) from raw.client as l left join raw.district as r on l.district_id = r.a1 where r.a1 is Null;
--Проверка на количество кредитов каждого человека из loan
select account_id, count(*) as cnt from raw.loan as l group by l.account_id having count(*) > 1;
