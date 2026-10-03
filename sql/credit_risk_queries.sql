CREATE DATABASE IF NOT EXISTS credit_risk;
USE credit_risk;

CREATE TABLE application_train (
SK_ID_CURR BIGINT PRIMARY KEY,
TARGET INTEGER,
NAME_CONTRACT_TYPE VARCHAR(50),
CODE_GENDER VARCHAR(10),
FLAG_OWN_CAR VARCHAR(5),
FLAG_OWN_REALTY VARCHAR(5),
CNT_CHILDREN INTEGER,
AMT_INCOME_TOTAL DECIMAL(18,2),
AMT_CREDIT DECIMAL(18,2),
AMT_ANNUITY DECIMAL(18,2),
AMT_GOODS_PRICE DECIMAL(18,2),
NAME_INCOME_TYPE VARCHAR(100),
NAME_EDUCATION_TYPE VARCHAR(100),
NAME_FAMILY_STATUS VARCHAR(100),
NAME_HOUSING_TYPE VARCHAR(100),
DAYS_BIRTH INTEGER,
DAYS_EMPLOYED INTEGER,
OCCUPATION_TYPE VARCHAR(100),
CNT_FAM_MEMBERS DECIMAL(5,1),
REGION_RATING_CLIENT INTEGER,
EXT_SOURCE_1 DECIMAL(10,6),
EXT_SOURCE_2 DECIMAL(10,6),
EXT_SOURCE_3 DECIMAL(10,6)
);

SELECT COUNT(*) FROM application_train;
SELECT * FROM application_train LIMIT 3;

-- Query 1: Overall default rate
SELECT
COUNT(*) AS total_borrowers,
SUM(TARGET) AS total_defaults,
ROUND(AVG(TARGET) * 100, 2) AS default_rate_pct,
COUNT(*) - SUM(TARGET) AS total_non_defaults
FROM application_train;

-- Finding income distributions
SELECT
ROUND(AVG(AMT_INCOME_TOTAL), 0) AS avg_income,
ROUND(MIN(AMT_INCOME_TOTAL), 0) AS min_income,
ROUND(MAX(AMT_INCOME_TOTAL), 0) AS max_income
FROM application_train
WHERE AMT_INCOME_TOTAL > 0;

SELECT SK_ID_CURR, AMT_INCOME_TOTAL
FROM application_train
ORDER BY AMT_INCOME_TOTAL DESC
LIMIT 10;

-- Query 2: Default rate by income segment
SELECT
CASE
WHEN AMT_INCOME_TOTAL < 100000 THEN '1. Low Income'
WHEN AMT_INCOME_TOTAL < 200000 THEN '2. Lower Mid'
WHEN AMT_INCOME_TOTAL < 350000 THEN '3. Upper Mid'
ELSE '4. High Income'
END AS income_segment,
COUNT(*) AS borrower_count,
SUM(TARGET) AS defaults,
ROUND(AVG(TARGET) * 100, 2) AS default_rate_pct,
ROUND(AVG(AMT_INCOME_TOTAL), 0) AS avg_income
FROM application_train
GROUP BY income_segment
ORDER BY income_segment;

-- Query 3: Default rate by employment type
SELECT
NAME_INCOME_TYPE AS employment_type,
COUNT(*) AS borrower_count,
SUM(TARGET) AS defaults,
ROUND(AVG(TARGET) * 100, 2) AS default_rate_pct
FROM application_train
WHERE NAME_INCOME_TYPE IS NOT NULL
GROUP BY NAME_INCOME_TYPE
ORDER BY default_rate_pct DESC;

-- Query 4: DTI cohorts
-- DTI = Loan Amount / Annual Income
SELECT
CASE
WHEN (AMT_CREDIT / NULLIF(AMT_INCOME_TOTAL, 0)) < 1 THEN '1. Low DTI'
WHEN (AMT_CREDIT / NULLIF(AMT_INCOME_TOTAL, 0)) < 2 THEN '2. Moderate DTI'
WHEN (AMT_CREDIT / NULLIF(AMT_INCOME_TOTAL, 0)) < 3 THEN '3. High DTI'
ELSE '4. Very High DTI'
END AS dti_cohort,
COUNT(*) AS borrower_count,
SUM(TARGET) AS defaults,
ROUND(AVG(TARGET) * 100, 2) AS default_rate_pct,
ROUND(AVG(AMT_CREDIT / NULLIF(AMT_INCOME_TOTAL, 0)), 2) AS avg_dti
FROM application_train
WHERE AMT_INCOME_TOTAL > 0
GROUP BY dti_cohort
ORDER BY dti_cohort;

-- Query 5: Default rate by age group
SELECT
CASE
WHEN FLOOR(ABS(DAYS_BIRTH) / 365) < 30 THEN '1. Under 30'
WHEN FLOOR(ABS(DAYS_BIRTH) / 365) < 40 THEN '2. Age 30-39'
WHEN FLOOR(ABS(DAYS_BIRTH) / 365) < 50 THEN '3. Age 40-49'
WHEN FLOOR(ABS(DAYS_BIRTH) / 365) < 60 THEN '4. Age 50-59'
ELSE '5. Age 60+'
END AS age_group,
COUNT(*) AS borrower_count,
SUM(TARGET) AS defaults,
ROUND(AVG(TARGET) * 100, 2) AS default_rate_pct,
ROUND(AVG(ABS(DAYS_BIRTH) / 365.0), 1) AS avg_age
FROM application_train
WHERE DAYS_BIRTH IS NOT NULL
GROUP BY age_group
ORDER BY age_group;

-- Query 6: Master view for Python
CREATE VIEW borrower_cohort AS
SELECT
SK_ID_CURR,
TARGET,
FLOOR(ABS(DAYS_BIRTH) / 365) AS age_years,
CASE
WHEN DAYS_EMPLOYED = 365243 THEN NULL
ELSE FLOOR(ABS(DAYS_EMPLOYED) / 365)
END AS employment_years,
AMT_INCOME_TOTAL AS annual_income,
AMT_CREDIT AS loan_amount,
AMT_ANNUITY AS annual_repayment,
ROUND(AMT_CREDIT / NULLIF(AMT_INCOME_TOTAL, 0), 3) AS debt_to_income,
ROUND(AMT_ANNUITY / NULLIF(AMT_INCOME_TOTAL, 0), 3) AS repayment_burden,
CODE_GENDER AS gender,
NAME_INCOME_TYPE AS employment_type,
NAME_EDUCATION_TYPE AS education,
NAME_FAMILY_STATUS AS family_status,
FLAG_OWN_CAR AS owns_car,
FLAG_OWN_REALTY AS owns_property,
CNT_CHILDREN AS num_children,
REGION_RATING_CLIENT AS region_risk_rating,
EXT_SOURCE_1,
EXT_SOURCE_2,
EXT_SOURCE_3
FROM application_train
WHERE AMT_INCOME_TOTAL > 0
AND DAYS_BIRTH IS NOT NULL;

-- Export master view to CSV for Python
SELECT 'SK_ID_CURR', 'TARGET', 'age_years', 'employment_years',
'annual_income', 'loan_amount', 'annual_repayment',
'debt_to_income', 'repayment_burden', 'gender',
'employment_type', 'education', 'family_status',
'owns_car', 'owns_property', 'num_children',
'region_risk_rating', 'EXT_SOURCE_1', 'EXT_SOURCE_2', 'EXT_SOURCE_3'
UNION ALL
SELECT * FROM borrower_cohort
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/borrower_cohort.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';