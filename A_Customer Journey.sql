- A. Customer Journey
-- Based off the 8 sample customers provided in the sample subscriptions table below, write a brief description about each customer’s onboarding journey.

SELECT s.customer_id,f.plan_id, f.plan_name,  s.start_date
FROM foodie_fi.plans f
JOIN foodie_fi.subscriptions s
ON f.plan_id = s.plan_id
WHERE s.customer_id IN (1,2,11,13,15,16,18,19)

-- Customer 2 signed up for a free trial on the 20th of September 2020 and decided to upgrade to the pro annual plan right after it ended.
-- Customer 13 started the free trial on 15 Dec 2020, then subscribed to the basic monthly plan on 22 Dec 2020. 3 months later on 29 Mar 2021, customer upgraded to the pro monthly plan.
-- Customer 19 signed up for a free trial on the 22nd of June 2020, went on to pay for the pro monthly plan right after it ended and upgraded to the pro annual plan two months in.