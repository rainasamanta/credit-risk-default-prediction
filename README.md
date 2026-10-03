# Credit Risk Default Prediction

An end-to-end credit risk project: SQL exploration, leak-free data preparation, a comparison of three machine learning models, a cost-based decision threshold, and a four-tier risk segmentation of loan applicants.

## Dataset

Built on the application data from the [Home Credit Default Risk](https://www.kaggle.com/c/home-credit-default-risk) dataset (307,511 loan applicants, 8.07% default rate).

## Workflow
 
### 1. SQL Exploration
- Profiled default rates by age, income, employment type and loan-to-income ratio
- Built a `borrower_cohort` view with derived features (age in years, employment years, loan-to-income ratio, repayment burden) and exported it to CSV
### 2. Data Cleaning
- Split the data 70 / 15 / 15 into train, validation and test sets, stratified by target, before any transformation
- Converted blank external scores, which MySQL stored as 0, back to missing values
- Created a `not_employed_flag` for the employment placeholder value (mostly pensioners) before imputing
- Imputed missing values and capped outliers at the 99.5th percentile, using values learned from the training set only
### 3. Exploratory Data Analysis
- Examined distributions, default rates by category and feature correlations, on training data only
### 4. Feature Engineering
- Created an average of the three external scores and a high loan-to-income flag
- Applied binary and one-hot encoding, with category lists fixed from the training set
### 5. Model Training and Selection
- Trained three class-weighted models to handle the 8% default rate:
  - Logistic Regression (in a Pipeline with StandardScaler)
  - Random Forest
  - XGBoost (using raw external scores with real missing values)
- Compared models with 5-fold cross-validation on train and ROC-AUC on the validation set
### 6. Cost-Based Threshold
- Chose the threshold that minimises the expected cost of missed defaults and wrongly rejected applicants (illustrative 10:1 cost ratio)
- Tested how the threshold changes under cost ratios from 5:1 to 20:1
### 7. Risk Segmentation and Final Evaluation
- Grouped applicants into four risk segments, with boundaries set on the validation set
- Evaluated the selected model once on the untouched test set
## Results
 
| Model | CV ROC-AUC | Validation ROC-AUC | Validation PR-AUC |
|---|---|---|---|
| Logistic Regression | 0.736 | 0.744 | 0.225 |
| Random Forest | 0.738 | 0.745 | 0.229 |
| XGBoost | 0.744 | 0.751 | 0.241 |
 
**Final test performance (XGBoost):** ROC-AUC of 0.753 (Gini 0.51), catching 60% of defaults at the cost-optimal threshold of 0.54, with an estimated 33.1% reduction in cost compared with approving every applicant.
 
| Segment | Suggested Action | Share of Applicants | Default Rate | Share of Defaults |
|---|---|---|---|---|
| A | Auto Approve | 49.6% | 2.9% | 17.9% |
| B | Standard Review | 10.3% | 6.1% | 7.8% |
| C | Manual Review | 13.7% | 8.6% | 14.5% |
| D | High-Risk Review | 26.4% | 18.3% | 59.8% |
 
The highest-risk segment holds 26% of applicants but 60% of all defaults.
 
## Evaluation Metrics
 
- ROC-AUC and Gini coefficient
- PR-AUC (average precision)
- Confusion matrix
- Classification report (precision, recall, F1-score)
- Expected cost at the chosen threshold

## Limitations

- **Protected attributes:** gender, age and family status are used as features, and gender ranks fourth in importance. A production credit model would need a fairness review, and would likely need to exclude them.
- **Risk scores, not probabilities:** class weighting inflates the model's outputs (average score 0.40 against a true default rate of 0.08). The scores rank applicants correctly but are not calibrated probabilities of default.
- **Illustrative costs:** the 10:1 cost ratio and the assumption that a defaulted loan is lost in full are simplifications. The sensitivity analysis shows the threshold moves from 0.67 to 0.30 across plausible ratios.
- **Limited data:** only 20 application fields were used. Credit bureau history and previous applications would likely improve performance.
- **Naming note:** the `debt_to_income` column is strictly a loan-to-income ratio (loan amount divided by annual income).

## Tools

MySQL 8.0 · Python · pandas · NumPy · scikit-learn · XGBoost · Matplotlib · Seaborn · Jupyter
