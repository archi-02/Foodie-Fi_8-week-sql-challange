-- B. Data Analysis Questions
-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id)
FROM subscriptions AS s
---------------------------------------------------------------------------------------------------------------------

/* 2. What is the monthly distribution of trial plan start_date values for our dataset - 
use the start of the month as the group by value */
SELECT TO_CHAR(s.start_date, 'Month') AS month_name, COUNT(customer_id) AS customers
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id=p.plan_id
WHERE p.plan_name='trial'
GROUP BY month_name, EXTRACT(MONTH FROM start_date)
ORDER BY EXTRACT(MONTH FROM start_date) ASC
---------------------------------------------------------------------------------------------------------------------

/* 3. What plan start_date values occur after the year 2020 for our dataset? 
Show the breakdown by count of events for each plan_name */
SELECT p.plan_name, COUNT(p.plan_id) AS values_2021
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id=p.plan_id
WHERE EXTRACT(YEAR FROM start_date) > 2020
GROUP BY plan_name
---------------------------------------------------------------------------------------------------------------------

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT SUM(CASE WHEN plan_name='churn'THEN 1 ELSE 0 END) AS number_of_customers_churned,
       SUM(CASE WHEN plan_name='churn'THEN 1 ELSE 0 END)/COUNT(DISTINCT customer_id) AS percent_of_customers_churned
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id=p.plan_id
---------------------------------------------------------------------------------------------------------------------

/* 5. How many customers have churned straight after their initial free trial - 
what percentage is this rounded to the nearest whole number? */
WITH rnk_tbl AS (
SELECT s.customer_id, s.plan_id, p.plan_name,
       RANK() OVER (PARTITION BY s.customer_id ORDER BY s.plan_id) AS plan_rank 
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id = p.plan_id)
SELECT SUM(CASE WHEN plan_name='churn' AND plan_rank=2 THEN 1 ELSE 0 END) AS customers_churned_after_trial,
       COUNT(DISTINCT customer_id) AS total_customers,
	   ROUND(100 * SUM(CASE WHEN plan_name='churn' AND plan_rank=2 THEN 1 ELSE 0 END) / (SELECT COUNT(DISTINCT customer_id) 
                                                                                         FROM subscriptions),0) AS churn_percentage
FROM rnk_tbl
---------------------------------------------------------------------------------------------------------------------

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH cte AS(
SELECT s.customer_id, p.plan_id, p.plan_name,
       LEAD(p.plan_name)OVER(PARTITION BY s.customer_id ORDER BY p.plan_id) AS plan_after_trial
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id=p.plan_id)

SELECT plan_after_trial, COUNT(customer_id) AS total_plans, 
       ROUND(100 * CAST(COUNT(customer_id) AS NUMERIC)/(SELECT COUNT (DISTINCT customer_id) 
								       FROM subscriptions),2) AS percentage_of_plans
FROM cte
WHERE plan_name='trial'
GROUP BY plan_after_trial
ORDER BY COUNT(customer_id) DESC
---------------------------------------------------------------------------------------------------------------------

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH CTE AS(
SELECT *, LEAD(start_date,1) OVER( PARTITION BY customer_id ORDER BY plan_id) As next_date
FROM subscriptions
WHERE start_date <= '2020-12-31') 

SELECT c.plan_id,plan_name, count(C.plan_id)  AS customer_count,  
       (CAST(COUNT(C.plan_id) AS Float) *100 / (SELECT count(distinct customer_id) 
                                                FROM subscriptions) ) as Percentage_customer
FROM CTE AS c
LEFT JOIN plans AS p 
ON c.plan_id= p.plan_id
WHERE next_date IS NULL or next_date >'2020-12-31' 
GROUP BY c.plan_id,plan_name
ORDER BY plan_id
---------------------------------------------------------------------------------------------------------------------

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT p.plan_name, COUNT(s.plan_id) as number_annual_plan
FROM subscriptions AS s
INNER JOIN plans AS p 
ON s.plan_id = p.plan_id
WHERE plan_name = 'pro annual' AND start_date <='2020-12-31'
GROUP BY plan_name
---------------------------------------------------------------------------------------------------------------------

-- 9. How many days on average does it take for a customer to upgrade to an annual plan from the day they join Foodie-Fi?
WITH trial AS (
SELECT s.customer_id, p.plan_id, s.start_date AS trial_date, p.plan_name AS trial_plan
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id=p.plan_id
WHERE p.plan_name='trial'),
pro_annual AS (
SELECT s.customer_id, p.plan_id, s.start_date AS annual_date, p.plan_name AS annual_plan
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id=p.plan_id
WHERE p.plan_name='pro annual')

SELECT ROUND(AVG(annual_date-trial_date)) AS avg_days_to_uprade
FROM trial as t
JOIN pro_annual AS pa
ON t.customer_id=pa.customer_id
---------------------------------------------------------------------------------------------------------------------

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH trial AS (
SELECT s.customer_id, p.plan_id, s.start_date AS trial_date, p.plan_name AS trial_plan
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id=p.plan_id
WHERE p.plan_name='trial'),
pro_annual AS (
SELECT s.customer_id, p.plan_id, s.start_date AS annual_date, p.plan_name AS annual_plan
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id=p.plan_id
WHERE p.plan_name='pro annual'),
diff_date AS (
SELECT t.customer_id, t.trial_date, pa.annual_date, annual_date-trial_date AS diff
FROM trial as t
JOIN pro_annual AS pa
ON t.customer_id=pa.customer_id),
period_cte AS (
SELECT *, CONCAT(((WIDTH_BUCKET(diff, 0, 360, 12)-1)*30)+1 , ' - ', WIDTH_BUCKET(diff, 0, 360, 12)*30, ' days') AS periods
FROM diff_date)

SELECT periods, COUNT(customer_id) AS customers, ROUND(AVG(diff),2) AS avg_days
FROM period_cte
GROUP BY periods
---------------------------------------------------------------------------------------------------------------------
-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH pro_monthly AS (
SELECT s.customer_id, p.plan_id, p.plan_name AS pro, s.start_date AS initial_date
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id=p.plan_id
WHERE plan_name='pro monthly' AND EXTRACT(YEAR FROM s.start_date)=2020),
basic_monthly AS (
SELECT s.customer_id, p.plan_id, p.plan_name AS basic, s.start_date AS final_date
FROM subscriptions AS s
JOIN plans AS p
ON s.plan_id=p.plan_id
WHERE plan_name='basic monthly' AND EXTRACT(YEAR FROM s.start_date)=2020)

SELECT COUNT(*) AS pro_to_basic
FROM (SELECT pm.customer_id, pm.pro, pm.initial_date, bm.basic, bm.final_date
      FROM pro_monthly As pm
      JOIN basic_monthly AS bm
      ON pm.customer_id=bm.customer_id
      WHERE final_date > initial_date) AS sub_q