# Retail Sales Profitability Analysis

Where does this store make money, where does it lose money, and why?
This project answers those questions with **SQL (MySQL)** and **Python (pandas)**.

## Dataset

- 9,994 sales records, 13 columns (the Sample Superstore dataset, US retail).
- Columns: ship mode, segment, location, region, category, sub-category, sales, quantity, discount, profit.
- It is a sample dataset, and it is **one flat table with no order id, dates or product names**. So the analysis works at category, sub-category, region and state level, and there is no trend or order-level analysis.

## Questions answered

1. How profitable is the business overall?
2. Which categories and sub-categories make or lose money?
3. What role do discounts play in the losses?
4. Are the loss-making sub-categories bad products, or badly discounted?
5. Which regions and states lose money?

## Key findings

| Finding | Number |
|---|---|
| Sales / profit / margin | $2.30M / $286K / **12.5%** |
| Loss-making records | 18.7% of records, $156K total loss |
| Furniture | 32% of sales but 6.4% of profit (2.49% margin) |
| Loss-making sub-categories | Tables (-8.6%), Bookcases (-3.0%), Supplies (-2.5%) |
| Margin when discount is 20% or less | **21.8%** |
| Margin when discount is above 20% | **-37.3%** |
| Deep-discount records | 13.9% of records, lost $135K, **88.7% of all loss dollars** |
| States with a net loss | 10 of 49 ($98.2K combined), led by Texas, Ohio, Pennsylvania, Illinois |
| Central vs West margin | 7.9% vs 14.9% (average discount 24.0% vs 10.9%) |
| Profit if deep-discount sales had not happened | $421,773 instead of $286,397 (+47.3%) |

What the discount analysis shows:

- The 11 to 20% discount band still earns 11.6%, but the 21 to 30% band drops to -10.0%, and 92% of its records lose money. That is why 20% is the line used here.
- **Tables** earn about 11% at normal discounts but -34% under deep discounts. **Bookcases** go from about 9% to -39%. For these two, the discounting is the problem, not the product.
- **Supplies** loses money even at low discounts (average discount 7.7%), so it looks like a cost or pricing problem, not a discount problem.
- Customer segment (11.5 to 14.0% margin) and ship mode (12.1 to 13.9%) barely matter.

![Profit by sub-category](images/profit_by_subcategory.png)
![Margin by discount band](images/margin_by_discount_band.png)
![States with a net loss](images/loss_making_states.png)

## Ideas to test (not proven)

- Cap discounts at 20%.
- Review pricing and costs for Supplies.
- Review discount practice for Furniture in the Central region and in the loss-making states.

## Data notes

- 17 exact duplicate rows exist. Without an order id they could be real repeat purchases, so they are kept. Dropping them changes total profit from $286,397 to $286,241.
- Margin is always total profit divided by total sales, never an average of row margins.
- Discounts may have been given to items that were already selling badly, so a discount can be a symptom as well as a cause.

## Project structure

```
superstore-sales-analysis/
├── data/SampleSuperstore.csv
├── sql/superstore_analysis.sql
├── notebooks/superstore_analysis.ipynb
├── images/
├── requirements.txt
└── README.md
```

## How to run

**SQL (MySQL 8):** open `sql/superstore_analysis.sql`, change the CSV path in Step 2, and run the file from top to bottom. The queries use window functions (RANK, DENSE_RANK), CTEs, CASE statements and a JOIN.

**Python:**

```bash
pip install -r requirements.txt
jupyter notebook notebooks/superstore_analysis.ipynb
```

## Tools

MySQL, Python (pandas, matplotlib), Jupyter Notebook.

## Author

Ashok Pulletikurthi, [GitHub](https://github.com/Ashok4510), [LinkedIn](https://www.linkedin.com/in/ashok-pulletikurthi-007a6b331)
