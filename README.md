# Customer Loyalty & Retention Analytics

A D2C fashion brand with 3,900 customers runs an active promo program but has no structured way to tell whether customers stay because they're loyal or because they're discounted. This project builds that structure — from raw transaction data to a validated loyalty framework, SQL-driven segmentation, and a retention playbook.

## Problem

- 3,900 customers, $233K in revenue, no customer intelligence layer.
- Is retention driven by genuine loyalty or by continuous discounting?
- Where's the opportunity for profitable growth without over-discounting?

## Workflow

| Step | Notebook / File | Output |
|---|---|---|
| 1. Data Cleaning | `Python/01_Data_Cleaning.ipynb` | `cleaned_dataset.csv` |
| 2. Feature Engineering | `Python/02_Feature_Engineering.ipynb` | 12 behavioral features → `engineered_dataset.csv` |
| 3. Loyalty Scoring | `Python/03_loyalty_models.ipynb` | Two independent loyalty models → `loyalty_dataset.csv` |
| 4. Segmentation | `Python/04_segmentation.ipynb` | `Customer_Segment` labels → `final_dataset.csv` |
| 5. SQL Analysis | `SQL/analysis .sql` | Value/promo/geographic breakdowns |
| 6. Dashboard | `Power BI/customer.pbix` | Interactive reporting |
| 7. Strategy | `Report/Executive summary.pdf`, `Report/Playbook.pdf` | 90-day promo sunset plan |

## Engineered Features (12)

Frequency Score, Promo Dependent flag, Satisfaction Flag, Tenure Band, Spend Tier, Customer Value Score, Value Tier, Promo × Value Segment, Age Group, Premium Shipping Flag, High Value Flag, Retention Risk Score.

## Loyalty Models

Two scoring formulas were built and validated against each other, each penalizing promo dependency differently:

- **Model A — Behavioral Commitment**: `0.40 × Previous_Purchases + 0.40 × Frequency_Score + 0.20 × (1 − Promo_Dependent)`
- **Model B — Engaged Value**: `0.35 × Review_Rating + 0.25 × Subscription_Status + 0.25 × Purchase_Amount + 0.15 × (1 − Promo_Dependent)`

**Model A was selected** — its "Loyal" segment showed a lower promo-dependency rate and longer purchase history than Model B's, making it the more trustworthy signal of genuine (not discount-driven) loyalty.

## Key Findings

- **43%** of customers (1,677) are promo-dependent; 57% (2,223) buy without relying on promos.
- **Champions (873 customers)**: high spend, frequent purchases, zero promo dependency — the strongest segment.
- **Promo Convert Targets (564 customers)**: high value, long purchase history, but fully promo-dependent — the biggest opportunity.
- Clothing is the top category among high-value customers; Arizona, Alaska, Pennsylvania, Virginia, and Tennessee are the strongest markets by Geographic Opportunity Score.
- Age does not meaningfully differentiate high-value customers.

## Strategy

1. **90-Day Promotional Sunset** — phase the 564 Promo Convert Targets off discounts (taper → substitute with loyalty perks → organic).
2. **Protect Champions** — no unnecessary discounting for the 873 Champions; retain via exclusivity and recognition instead.
3. **Prioritize high-value markets** for acquisition spend.
4. **Acquire on category and geography, not age.**

## Tech Stack

`Python` (pandas, matplotlib/seaborn) · `SQL` · `Power BI`

## Repo Structure

```
Data/        Raw → cleaned → engineered → loyalty → final datasets
Python/      4 notebooks: cleaning → features → loyalty models → segmentation
SQL/         Segmentation & revenue analysis queries
Power BI/    Interactive dashboard (.pbix)
Report/      Executive summary + 90-day playbook
Screenshots/ Key chart exports
```

## Note on Data

No timestamps or explicit churn labels exist in the source data — `Previous_Purchases` is used as a tenure proxy, and geographic analysis is state-level. `Discount_Applied` and `Promo_Code_Used` are treated as one feature (perfectly correlated). Segment definitions should be read as patterns in this dataset, not confirmed causal or demographic claims.
