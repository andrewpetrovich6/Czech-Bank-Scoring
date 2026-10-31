DROP SCHEMA IF EXISTS clean CASCADE;
CREATE SCHEMA clean;

CREATE VIEW clean.loan AS
SELECT
    loan_id,
    account_id,
    to_date(date, 'YYMMDD') AS loan_date,
    amount,
    duration,
    payments,
    status
FROM raw.loan;

CREATE VIEW clean.account AS
SELECT
    account_id,
    district_id,
    CASE frequency
        WHEN 'POPLATEK MESICNE'   THEN 'monthly'
        WHEN 'POPLATEK TYDNE'     THEN 'weekly'
        WHEN 'POPLATEK PO OBRATU' THEN 'after_transaction'
    END AS statement_frequency,
    to_date(date, 'YYMMDD') AS open_date
FROM raw.account;

CREATE VIEW clean.trans AS
SELECT
    trans_id,
    account_id,
    to_date(date, 'YYMMDD') AS trans_date,
    CASE type
        WHEN 'PRIJEM' THEN 'credit'
        WHEN 'VYDAJ'  THEN 'withdrawal'
        WHEN 'VYBER'  THEN 'cash_withdrawal'
    END AS trans_type,
    CASE operation
        WHEN 'VKLAD'          THEN 'cash_credit'
        WHEN 'PREVOD Z UCTU'  THEN 'transfer_in'
        WHEN 'VYBER'          THEN 'cash_withdrawal'
        WHEN 'VYBER KARTOU'   THEN 'card_withdrawal'
        WHEN 'PREVOD NA UCET' THEN 'transfer_out'
    END AS operation,
    amount,
    CASE WHEN type = 'PRIJEM' THEN amount ELSE -amount END AS signed_amount,
    balance,
    CASE TRIM(k_symbol)
        WHEN 'UROK'        THEN 'interest'
        WHEN 'SANKC. UROK' THEN 'sanction_interest'
        WHEN 'SLUZBY'      THEN 'statement_fee'
        WHEN 'SIPO'        THEN 'household'
        WHEN 'DUCHOD'      THEN 'pension'
        WHEN 'POJISTNE'    THEN 'insurance'
        WHEN 'UVER'        THEN 'loan_payment'
    END AS k_symbol,
    NULLIF(TRIM(bank), '')    AS bank,
    NULLIF(TRIM(account), '') AS account
FROM raw.trans;

CREATE VIEW clean.orders AS
SELECT
    order_id,
    account_id,
    bank_to,
    account_to,
    amount,
    CASE TRIM(k_symbol)
        WHEN 'SIPO'     THEN 'household'
        WHEN 'UVER'     THEN 'loan_payment'
        WHEN 'POJISTNE' THEN 'insurance'
        WHEN 'LEASING'  THEN 'leasing'
    END AS k_symbol
FROM raw.orders;

CREATE VIEW clean.card AS
SELECT
    card_id,
    disp_id,
    type AS card_type,
    to_date(LEFT(issued, 6), 'YYMMDD') AS issue_date
FROM raw.card;

CREATE VIEW clean.client AS
WITH parts AS (
    SELECT
        client_id,
        district_id,
        SUBSTR(birth_number, 1, 2)::int AS yy,
        SUBSTR(birth_number, 3, 2)::int AS mm,
        SUBSTR(birth_number, 5, 2)::int AS dd
    FROM raw.client
)
SELECT
    client_id,
    district_id,
    CASE WHEN mm > 50 THEN 'F' ELSE 'M' END AS gender,
    make_date(1900 + yy, CASE WHEN mm > 50 THEN mm - 50 ELSE mm END, dd) AS birth_date
FROM parts;

CREATE VIEW clean.disp AS
SELECT
    disp_id,
    client_id,
    account_id,
    LOWER(type) AS disp_type
FROM raw.disp;

CREATE VIEW clean.account_owner AS
SELECT
    account_id,
    client_id
FROM raw.disp
WHERE type = 'OWNER';

CREATE VIEW clean.district AS
SELECT
    a1                        AS district_id,
    a2                        AS district_name,
    a3                        AS region,
    a4                        AS population,
    a5                        AS n_munic_lt_500,
    a6                        AS n_munic_500_1999,
    a7                        AS n_munic_2000_9999,
    a8                        AS n_munic_ge_10000,
    a9                        AS n_cities,
    a10                       AS urban_ratio,
    a11                       AS avg_salary,
    NULLIF(a12, '?')::numeric AS unemployment_95,
    a13                       AS unemployment_96,
    a14                       AS entrepreneurs_per_1000,
    NULLIF(a15, '?')::int     AS crimes_95,
    a16                       AS crimes_96
FROM raw.district;
