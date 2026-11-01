DROP SCHEMA IF EXISTS mart CASCADE;
CREATE SCHEMA mart;

create view mart.loan_target as
select *, case when status in ('B', 'D') then 1 else 0 end as bad_loan from clean.loan;
--Прооверка
select count(*) from mart.loan_target;
--Доля
select round(sum(bad_loan)*1.0 / count(*) * 100, 2) from mart.loan_target; 
--Доля плохих по сроку
select duration, round(sum(bad_loan)*1.0 / count(*)*100, 2) as perc from mart.loan_target group by duration order by duration asc;
--Доля плохих по году
select extract(year from loan_date) as year, round(sum(bad_loan) * 1.0/count(*) * 100, 2) as perc from mart.loan_target group by extract(year from loan_date) ;
--Доля плохих по району
select district_id, round(sum(bad_loan)* 1.0 / count(*)*100, 2) as district_percent from (select t.loan_id, t.bad_loan, d.district_id from mart.loan_target as t inner join clean.account as d on t.account_id = d.account_id) as tmp group by district_id having count(*) >= 15 order by district_percent asc;
