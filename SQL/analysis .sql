-- ============================================================
-- FILE     : analysis.sql
-- DATABASE : customer_retention
-- TABLE    : customers
-- DATA     : Data/final_dataset.csv
-- ============================================================

-- ================================================================
-- DATASET NOTES AND INTERPRETATION CONSIDERATIONS
-- ================================================================
--
-- Discount_Applied and Subscription_Status have specific patterns
-- in the raw dataset:
-- - Discount_Applied is "No" for all female customers.
-- - All subscribers have Discount_Applied = "Yes".
--
-- Therefore, Promo_Dependent shows a strong relationship with these
-- fields in this dataset. Any analysis combining Promo_Dependent with
-- Gender or Subscription_Status (Q2C, Q6B, Q7A, Q8C, Q9A, Q10A)
-- should be interpreted within the context of this dataset.
--
-- Discount_Applied and Promo_Code_Used are identical 100% of the time,
-- so Promo_Dependent represents a single promotional behavior signal.
--
-- State-level analysis within smaller segments such as Champion and
-- Ideal Customer contains limited samples (approximately 11–28 customers
-- per state). Therefore, state-level comparisons in Q9C and Q10B should
-- be considered directional insights.
--
-- ================================================================

USE customer_retention;

-- ============================================================
-- SECTION 0 : TABLE CHECK
-- ============================================================

SELECT COUNT(*)  AS total_customers FROM customers;
SELECT * FROM customers LIMIT 5;

-- ============================================================
-- SECTION 1 : LOYAL vs DISCOUNT CUSTOMERS
-- Business Question: Who buys without needing a discount?
-- ============================================================

-- Q1A: Overall promo dependency split
SELECT
    Promo_Dependent,
    COUNT(*)                                            AS customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) 
          FROM customers), 1)                           AS pct_of_total,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Frequency_Score), 1)                      AS avg_frequency_score,
    ROUND(AVG(Customer_Value_Score), 3)                 AS avg_value_score
FROM customers
GROUP BY Promo_Dependent
ORDER BY Promo_Dependent DESC;

-- Q1B: Loyalty Label breakdown with promo behavior
SELECT
    Loyalty_Label_A,
    Promo_Dependent,
    COUNT(*)                                            AS customer_count,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Review_Rating), 2)                        AS avg_rating
FROM customers
GROUP BY Loyalty_Label_A, Promo_Dependent
ORDER BY Loyalty_Label_A, Promo_Dependent DESC;

-- Q1C: Promo dependency % by loyalty tier
SELECT
    Loyalty_Label_A,
    COUNT(*)                                            AS total,
    SUM(Promo_Dependent)                                AS promo_users,
    ROUND(SUM(Promo_Dependent) * 100.0 / COUNT(*), 1)  AS promo_pct
FROM customers
GROUP BY Loyalty_Label_A
ORDER BY promo_pct DESC;

-- Q1D: Promo Value Segment deep dive
SELECT
    Promo_Value_Segment,
    COUNT(*)                                            AS customer_count,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Customer_Value_Score), 3)                 AS avg_cvs,
    ROUND(AVG(Review_Rating), 2)                        AS avg_rating
FROM customers
GROUP BY Promo_Value_Segment
ORDER BY avg_cvs DESC;

-- ============================================================
-- SECTION 2 : HIGH VALUE CUSTOMER ANALYSIS
-- Business Question: What separates high value from low value?
-- ============================================================

-- Q2A: High Value vs Low Value full profile comparison
SELECT
    High_Value_Flag,
    COUNT(*)                                            AS customer_count,
    ROUND(AVG(Age), 1)                                  AS avg_age,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Frequency_Score), 1)                      AS avg_frequency,
    ROUND(AVG(Review_Rating), 2)                        AS avg_rating,
    ROUND(AVG(Subscription_Status), 2)                  AS subscription_rate,
    ROUND(AVG(Promo_Dependent), 2)                      AS promo_dependency_rate,
    ROUND(AVG(Premium_Shipping_Flag), 2)                AS premium_shipping_rate
FROM customers
GROUP BY High_Value_Flag
ORDER BY High_Value_Flag DESC;

-- Q2B: Value Tier deep dive
SELECT
    Value_Tier,
    COUNT(*)                                            AS customer_count,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Frequency_Score), 1)                      AS avg_frequency,
    ROUND(SUM(Promo_Dependent) * 100.0 / COUNT(*), 1)  AS promo_pct,
    ROUND(AVG(Review_Rating), 2)                        AS avg_rating,
    ROUND(AVG(Subscription_Status) * 100, 1)            AS subscription_pct
FROM customers
GROUP BY Value_Tier
ORDER BY avg_spend DESC;

-- Q2C: Subscription status impact on value
-- Note: every subscriber here is also discount-driven, and no female
-- customer subscribes (see note at top of file).
SELECT
    Subscription_Status,
    Value_Tier,
    COUNT(*)                                            AS customer_count,
    ROUND(AVG(Customer_Value_Score), 3)                 AS avg_cvs,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases
FROM customers
GROUP BY Subscription_Status, Value_Tier
ORDER BY Subscription_Status DESC, avg_cvs DESC;

-- ============================================================
-- SECTION 3 : REVENUE CONCENTRATION
-- Business Question: How concentrated is value in top tiers?
-- ============================================================

-- Q3A: Revenue share by Value Tier
SELECT
    Value_Tier,
    COUNT(*)                                            AS customer_count,
    ROUND(SUM(Purchase_Amount), 0)                      AS total_spend,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(SUM(Purchase_Amount) * 100.0 /
          (SELECT SUM(Purchase_Amount) 
           FROM customers), 1)                          AS revenue_share_pct,
    ROUND(COUNT(*) * 100.0 /
          (SELECT COUNT(*) FROM customers), 1)          AS customer_share_pct
FROM customers
GROUP BY Value_Tier
ORDER BY total_spend DESC;

-- Q3B: Revenue share by Loyalty Label
SELECT
    Loyalty_Label_A,
    COUNT(*)                                            AS customers,
    ROUND(SUM(Purchase_Amount), 0)                      AS total_revenue,
    ROUND(SUM(Purchase_Amount) * 100.0 /
          (SELECT SUM(Purchase_Amount) 
           FROM customers), 1)                          AS revenue_pct,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend
FROM customers
GROUP BY Loyalty_Label_A
ORDER BY total_revenue DESC;

-- Q3C: Estimated promo cost impact
-- Assumes average discount of 15% on promo purchases
SELECT
    Promo_Dependent,
    COUNT(*)                                            AS customers,
    ROUND(SUM(Purchase_Amount), 0)                      AS gross_revenue,
    ROUND(SUM(Purchase_Amount) * 0.15, 0)               AS estimated_discount_cost,
    ROUND(SUM(Purchase_Amount) * 0.85, 0)               AS estimated_net_revenue
FROM customers
GROUP BY Promo_Dependent;

-- ============================================================
-- SECTION 4 : GEOGRAPHIC ANALYSIS
-- Business Question: Which states show organic demand
--                    vs discount driven volume?
-- ============================================================

-- Q4A: State level performance overview
-- Every state has n >= 63 in the full customer base, so no minimum sample
-- size filter is needed here (unlike Q9C/Q10B below, which query smaller
-- subsegments). This is the most robust state-level ranking in the file.
SELECT
    Location                                            AS state,
    COUNT(*)                                            AS customer_count,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Customer_Value_Score), 3)                 AS avg_cvs,
    ROUND(SUM(Promo_Dependent) * 100.0 / COUNT(*), 1)  AS promo_dependency_pct,
    ROUND(AVG(Review_Rating), 2)                        AS avg_rating
FROM customers
GROUP BY Location
ORDER BY avg_cvs DESC
LIMIT 20;

-- Q4B: Geographic opportunity matrix
-- High Spend + Low Promo = Organic Demand = Priority Market
SELECT
    Location                                            AS state,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(SUM(Promo_Dependent) * 100.0 / COUNT(*), 1)  AS promo_pct,
    ROUND(AVG(Customer_Value_Score), 3)                 AS avg_cvs,
    CASE
        WHEN AVG(Purchase_Amount) >= 60
         AND SUM(Promo_Dependent) * 100.0 / COUNT(*) < 50
        THEN 'Priority — High Spend Organic'
        WHEN AVG(Purchase_Amount) >= 60
         AND SUM(Promo_Dependent) * 100.0 / COUNT(*) >= 50
        THEN 'Discount Market — High Spend Promo Driven'
        WHEN AVG(Purchase_Amount) < 60
         AND SUM(Promo_Dependent) * 100.0 / COUNT(*) < 50
        THEN 'Growth Market — Low Spend Organic'
        ELSE 'Low Priority — Low Spend High Promo'
    END                                                 AS market_type
FROM customers
GROUP BY Location
HAVING COUNT(*) >= 20
ORDER BY avg_spend DESC;

-- Q4C: Top 10 states by total revenue
SELECT
    Location,
    COUNT(*)                                            AS customers,
    ROUND(SUM(Purchase_Amount), 0)                      AS total_spend,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(SUM(Promo_Dependent) * 100.0 / COUNT(*), 1)  AS promo_pct
FROM customers
GROUP BY Location
ORDER BY total_spend DESC
LIMIT 10;

-- ============================================================
-- SECTION 5 : CATEGORY ANALYSIS
-- Business Question: Which categories are entry point
--                    vs retention categories?
-- ============================================================

-- Q5A: Category performance overview
SELECT
    Category,
    COUNT(*)                                            AS customer_count,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Customer_Value_Score), 3)                 AS avg_cvs,
    ROUND(SUM(Promo_Dependent) * 100.0 / COUNT(*), 1)  AS promo_dependency_pct,
    ROUND(AVG(Review_Rating), 2)                        AS avg_rating,
    ROUND(AVG(Frequency_Score), 1)                      AS avg_frequency
FROM customers
GROUP BY Category
ORDER BY avg_prev_purchases DESC;

-- Q5B: Category funnel — entry point vs retention
SELECT
    Category,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(SUM(Promo_Dependent) * 100.0 / COUNT(*), 1)  AS promo_pct,
    CASE
        WHEN AVG(Previous_Purchases) < 20
        THEN 'Entry Point Category'
        WHEN AVG(Previous_Purchases) < 30
        THEN 'Mid Journey Category'
        ELSE 'Retention Category'
    END                                                 AS category_role
FROM customers
GROUP BY Category
ORDER BY avg_prev_purchases ASC;

-- Q5C: Category x Season analysis
SELECT
    Category,
    Season,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(SUM(Promo_Dependent) * 100.0 / COUNT(*), 1)  AS promo_pct
FROM customers
GROUP BY Category, Season
ORDER BY Category, avg_prev_purchases ASC;

-- Q5D: Category x Loyalty Label
SELECT
    Category,
    Loyalty_Label_A,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases
FROM customers
GROUP BY Category, Loyalty_Label_A
ORDER BY Category, avg_prev_purchases DESC;

-- ============================================================
-- SECTION 6 : DEMOGRAPHIC ANALYSIS
-- Business Question: Which demographics are underlevered?
-- ============================================================

-- Q6A: Age Group performance
SELECT
    Age_Group,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Customer_Value_Score), 3)                 AS avg_cvs,
    ROUND(SUM(Promo_Dependent) * 100.0 / COUNT(*), 1)  AS promo_pct,
    ROUND(AVG(Subscription_Status) * 100, 1)            AS subscription_pct,
    ROUND(AVG(Review_Rating), 2)                        AS avg_rating
FROM customers
GROUP BY Age_Group
ORDER BY Age_Group;

-- Q6B: Gender analysis
-- Note: Promo_Dependent and Subscription_Status are 0 for 100% of female
-- customers by construction in the raw data, so the gender split on these
-- two columns is a data artifact, not a real behavioral difference (see
-- note at top of file). Purchase_Amount, Previous_Purchases, and
-- Customer_Value_Score aren't affected and can be compared normally.
SELECT
    Gender,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(SUM(Promo_Dependent) * 100.0 / COUNT(*), 1)  AS promo_pct,
    ROUND(AVG(Customer_Value_Score), 3)                 AS avg_cvs,
    ROUND(AVG(Subscription_Status) * 100, 1)            AS subscription_pct
FROM customers
GROUP BY Gender;

-- Q6C: Age Group x Category
SELECT
    Age_Group,
    Category,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases
FROM customers
GROUP BY Age_Group, Category
ORDER BY Age_Group, customers DESC;

-- ============================================================
-- SECTION 7 : PROMOTION DEPENDENCY DEEP DIVE
-- Business Question: Who needs discounts and who does not?
-- ============================================================

-- Q7A: Promo dependency by subscription status
-- Note: this returns only 3 rows, not 4 — there are zero customers with
-- Subscription_Status = 1 AND Promo_Dependent = 0 in this dataset (see
-- note at top of file). Expected, not a query bug.
SELECT
    Subscription_Status,
    Promo_Dependent,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Customer_Value_Score), 3)                 AS avg_cvs
FROM customers
GROUP BY Subscription_Status, Promo_Dependent
ORDER BY Subscription_Status DESC, Promo_Dependent DESC;

-- Q7B: Promo dependency by purchase frequency
SELECT
    Frequency_of_Purchases,
    Frequency_Score,
    ROUND(SUM(Promo_Dependent) * 100.0 / COUNT(*), 1)  AS promo_pct,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend
FROM customers
GROUP BY Frequency_of_Purchases, Frequency_Score
ORDER BY Frequency_Score DESC;

-- Q7C: Promotional sunset plan candidates
-- These are your core sunset segment
-- High tenure + Loyal + Promo Dependent
SELECT
    Customer_Segment,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Frequency_Score), 1)                      AS avg_frequency,
    ROUND(AVG(Customer_Value_Score), 3)                 AS avg_cvs,
    ROUND(AVG(Review_Rating), 2)                        AS avg_rating
FROM customers
WHERE Customer_Segment = 'Promo Convert Target'
GROUP BY Customer_Segment;

-- Q7D: Full detail of sunset candidates
SELECT
    Age,
    Gender,
    Location,
    Category,
    Purchase_Amount,
    Previous_Purchases,
    Frequency_of_Purchases,
    Frequency_Score,
    Loyalty_Label_A,
    Value_Tier,
    Customer_Value_Score,
    Tenure_Band,
    Review_Rating,
    Satisfaction_Flag
FROM customers
WHERE Customer_Segment = 'Promo Convert Target'
ORDER BY Customer_Value_Score DESC
LIMIT 50;

-- ============================================================
-- SECTION 8 : CUSTOMER SEGMENT ANALYSIS
-- Business Question: Full breakdown of all segments
-- ============================================================

-- Q8A: Complete segment summary
SELECT
    Customer_Segment,
    COUNT(*)                                            AS customer_count,
    ROUND(COUNT(*) * 100.0 /
          (SELECT COUNT(*) FROM customers), 1)          AS pct_of_base,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Frequency_Score), 1)                      AS avg_frequency,
    ROUND(AVG(Customer_Value_Score), 3)                 AS avg_cvs,
    ROUND(SUM(Promo_Dependent) * 100.0 / COUNT(*), 1)  AS promo_pct,
    ROUND(AVG(Review_Rating), 2)                        AS avg_rating,
    ROUND(AVG(Subscription_Status) * 100, 1)            AS subscription_pct
FROM customers
GROUP BY Customer_Segment
ORDER BY avg_cvs DESC;

-- Q8B: Segment x Category cross analysis
SELECT
    Customer_Segment,
    Category,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend
FROM customers
GROUP BY Customer_Segment, Category
ORDER BY Customer_Segment, customers DESC;

-- Q8C: Segment x Gender
-- Note: At Risk, Discount Dependent, and Promo Convert Target come back
-- 100% male because those segments require Promo_Dependent = 1, which no
-- female customer has (see note at top of file). Data artifact, not a
-- finding about gender and discount-driven behavior.
SELECT
    Customer_Segment,
    Gender,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Customer_Value_Score), 3)                 AS avg_cvs
FROM customers
GROUP BY Customer_Segment, Gender
ORDER BY Customer_Segment, customers DESC;

-- ============================================================
-- SECTION 9 : IDEAL CUSTOMER PROFILE
-- Business Question: What does the best customer look like?
-- ============================================================

-- Q9A: Ideal customer demographics
-- Top 25% by CVS + Non Promo Dependent
-- Note: age is evenly distributed across this segment (no single decade
-- dominates) — don't treat the average age as a narrow targeting band.
SELECT
    Gender,
    ROUND(AVG(Age), 0)                                  AS avg_age,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Frequency_Score), 1)                      AS avg_frequency,
    ROUND(AVG(Review_Rating), 2)                        AS avg_rating,
    ROUND(AVG(Subscription_Status) * 100, 1)            AS subscription_pct,
    COUNT(*)                                            AS customer_count
FROM customers
WHERE High_Value_Flag = 1
  AND Promo_Dependent = 0
GROUP BY Gender
ORDER BY avg_spend DESC;

-- Q9B: Ideal customer top category
SELECT
    Category,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend
FROM customers
WHERE High_Value_Flag = 1
  AND Promo_Dependent = 0
GROUP BY Category
ORDER BY customers DESC;

-- Q9C: Ideal customer top states
-- Note: per-state sample size within this 930-customer segment is small
-- (n = 12-28 per state, see note at top of file). Treat as directional —
-- use Q4A/Q4B (full customer base) for actual geographic targeting.
SELECT
    Location,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Customer_Value_Score), 3)                 AS avg_cvs
FROM customers
WHERE High_Value_Flag = 1
  AND Promo_Dependent = 0
GROUP BY Location
ORDER BY customers DESC
LIMIT 10;

-- Q9D: Ideal customer top payment method
SELECT
    Payment_Method,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend
FROM customers
WHERE High_Value_Flag = 1
  AND Promo_Dependent = 0
GROUP BY Payment_Method
ORDER BY customers DESC;

-- Q9E: Ideal customer top season
SELECT
    Season,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend
FROM customers
WHERE High_Value_Flag = 1
  AND Promo_Dependent = 0
GROUP BY Season
ORDER BY customers DESC;

-- Q9F: At Risk segment profile
SELECT
    COUNT(*)                                            AS at_risk_customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Review_Rating), 2)                        AS avg_rating,
    ROUND(AVG(Frequency_Score), 1)                      AS avg_frequency
FROM customers
WHERE Customer_Segment = 'At Risk';

-- ============================================================
-- SECTION 10 : CHAMPION SEGMENT DEEP DIVE
-- Your 873 best customers
-- ============================================================

-- Q10A: Champion profile
-- Note: unlike At Risk / Discount Dependent / Promo Convert Target, the
-- Champion segment isn't gender-restricted by the Promo_Dependent artifact
-- (Champions require Promo_Dependent = 0, which both genders can satisfy),
-- so this gender comparison can be read normally.
SELECT
    Gender,
    ROUND(AVG(Age), 0)                                  AS avg_age,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Frequency_Score), 1)                      AS avg_frequency,
    ROUND(AVG(Review_Rating), 2)                        AS avg_rating,
    ROUND(AVG(Subscription_Status) * 100, 1)            AS subscription_pct,
    COUNT(*)                                            AS customers
FROM customers
WHERE Customer_Segment = 'Champion'
GROUP BY Gender;

-- Q10B: Champion top locations
-- Note: per-state sample size within this 873-customer segment is small
-- (n = 11-28 per state, see note at top of file). Treat as directional —
-- use Q4A/Q4B (full customer base) for actual geographic targeting.
SELECT
    Location,
    COUNT(*)                                            AS champion_customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend
FROM customers
WHERE Customer_Segment = 'Champion'
GROUP BY Location
ORDER BY champion_customers DESC
LIMIT 10;

-- Q10C: Champion top categories
SELECT
    Category,
    COUNT(*)                                            AS customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases
FROM customers
WHERE Customer_Segment = 'Champion'
GROUP BY Category
ORDER BY customers DESC;

-- ============================================================
-- SECTION 11 : FINAL SUMMARY QUERIES FOR EXECUTIVE SUMMARY
-- These give you the headline numbers
-- ============================================================

-- Overall brand health summary
SELECT
    COUNT(*)                                            AS total_customers,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(SUM(Purchase_Amount), 0)                      AS total_revenue,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases,
    ROUND(AVG(Review_Rating), 2)                        AS avg_rating,
    ROUND(AVG(Subscription_Status) * 100, 1)            AS subscription_pct,
    ROUND(SUM(Promo_Dependent) * 100.0 / COUNT(*), 1)  AS overall_promo_pct,
    ROUND(SUM(High_Value_Flag) * 100.0 / COUNT(*), 1)  AS high_value_pct
FROM customers;

-- Champion vs rest comparison
SELECT
    CASE WHEN Customer_Segment = 'Champion'
         THEN 'Champion'
         ELSE 'Rest of Base'
    END                                                 AS customer_group,
    COUNT(*)                                            AS customers,
    ROUND(SUM(Purchase_Amount) * 100.0 /
          (SELECT SUM(Purchase_Amount)
           FROM customers), 1)                          AS revenue_share_pct,
    ROUND(AVG(Purchase_Amount), 2)                      AS avg_spend,
    ROUND(AVG(Previous_Purchases), 1)                   AS avg_prev_purchases
FROM customers
GROUP BY customer_group;

-- Promo dependency revenue impact
SELECT
    ROUND(SUM(CASE WHEN Promo_Dependent = 1
              THEN Purchase_Amount ELSE 0 END), 0)      AS promo_revenue,
    ROUND(SUM(CASE WHEN Promo_Dependent = 0
              THEN Purchase_Amount ELSE 0 END), 0)      AS organic_revenue,
    ROUND(SUM(CASE WHEN Promo_Dependent = 1
              THEN Purchase_Amount * 0.15 ELSE 0 END),0)AS estimated_discount_cost,
    ROUND(SUM(Purchase_Amount), 0)                      AS total_revenue
FROM customers;