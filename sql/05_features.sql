DROP TABLE IF EXISTS mart.features;

CREATE TABLE mart.features AS
WITH tx_before AS (
    SELECT
        l.loan_id,
        l.loan_date,
        t.trans_date,
        t.trans_type,
        t.amount,
        t.balance,
        t.k_symbol
    FROM mart.loan_target AS l
    JOIN clean.trans AS t
        ON t.account_id = l.account_id
       AND t.trans_date < l.loan_date
),
balance_feats AS (
    SELECT
        loan_id,
        AVG(balance)    FILTER (WHERE trans_date >= loan_date - 90)  AS balance_mean_90d,
        MIN(balance)    FILTER (WHERE trans_date >= loan_date - 90)  AS balance_min_90d,
        COUNT(*)        FILTER (WHERE trans_date >= loan_date - 90)  AS n_trans_90d,
        COUNT(*)        FILTER (WHERE balance < 0)                   AS n_negative_balance,
        COUNT(*)        FILTER (WHERE k_symbol = 'sanction_interest') AS n_sanction_interest
    FROM tx_before
    GROUP BY loan_id
),
monthly_income AS (
    SELECT
        loan_id,
        DATE_TRUNC('month', trans_date) AS month,
        SUM(amount) AS income
    FROM tx_before
    WHERE trans_type = 'credit'
      AND k_symbol IS DISTINCT FROM 'interest'
    GROUP BY loan_id, DATE_TRUNC('month', trans_date)
),
income_feats AS (
    SELECT
        loan_id,
        AVG(income) AS income_month_mean
    FROM monthly_income
    GROUP BY loan_id
),
client_feats AS (
    SELECT
        l.loan_id,
        c.gender,
        EXTRACT(YEAR FROM AGE(l.loan_date, c.birth_date))::int AS age_at_loan,
        (EXTRACT(YEAR FROM AGE(l.loan_date, a.open_date)) * 12
         + EXTRACT(MONTH FROM AGE(l.loan_date, a.open_date)))::int AS account_age_months,
        a.district_id
    FROM mart.loan_target AS l
    JOIN clean.account       AS a  ON a.account_id = l.account_id
    JOIN clean.account_owner AS ao ON ao.account_id = l.account_id
    JOIN clean.client        AS c  ON c.client_id = ao.client_id
),
disp_feats AS (
    SELECT
        l.loan_id,
        MAX(CASE WHEN d.disp_type = 'disponent' THEN 1 ELSE 0 END) AS has_disponent,
        MAX(k.card_type) FILTER (WHERE k.issue_date < l.loan_date)  AS card_type
    FROM mart.loan_target AS l
    JOIN clean.disp AS d ON d.account_id = l.account_id
    LEFT JOIN clean.card AS k ON k.disp_id = d.disp_id
    GROUP BY l.loan_id
),
order_feats AS (
    SELECT
        l.loan_id,
        COUNT(o.order_id) AS n_orders
    FROM mart.loan_target AS l
    LEFT JOIN clean.orders AS o
        ON o.account_id = l.account_id
       AND o.k_symbol IS DISTINCT FROM 'loan_payment'
    GROUP BY l.loan_id
)
SELECT
    l.loan_id,
    l.amount,
    l.duration,
    b.balance_mean_90d,
    b.balance_min_90d,
    b.n_trans_90d,
    b.n_negative_balance,
    b.n_sanction_interest,
    i.income_month_mean,
    l.payments / NULLIF(i.income_month_mean, 0) AS payment_to_income,
    cf.gender,
    cf.age_at_loan,
    cf.account_age_months,
    df.has_disponent,
    COALESCE(df.card_type, 'none') AS card_type,
    o.n_orders,
    d.avg_salary AS district_avg_salary,
    l.bad_loan
FROM mart.loan_target AS l
LEFT JOIN balance_feats  AS b  ON b.loan_id  = l.loan_id
LEFT JOIN income_feats   AS i  ON i.loan_id  = l.loan_id
LEFT JOIN client_feats   AS cf ON cf.loan_id = l.loan_id
LEFT JOIN disp_feats     AS df ON df.loan_id = l.loan_id
LEFT JOIN order_feats    AS o  ON o.loan_id  = l.loan_id
LEFT JOIN clean.district AS d  ON d.district_id = cf.district_id;

ALTER TABLE mart.features ADD PRIMARY KEY (loan_id);
