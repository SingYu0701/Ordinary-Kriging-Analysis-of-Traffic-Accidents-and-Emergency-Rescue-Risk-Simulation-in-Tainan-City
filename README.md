# Ordinary-Kriging-Analysis-of-Traffic-Accidents-and-Emergency-Rescue-Risk-Simulation-in-Tainan-City

**Final report of Geo-statistics, Jun 2024**
![Made with R](https://img.shields.io/badge/Made%20with-R-276DC3?logo=r&logoColor=white)
- Performed spatial analysis using Ordinary Kriging to identify traffic accident hotspots, providing actionable insights for city traffic safety planning.
- Evaluated emergency rescue risks across different regions by combining logistic regression with hospital proximity, supporting data-driven emergency response strategies.
- Generated interpretable results for decision-making in traffic management and public safety using spatial and statistical modeling techniques.

## Abstract

This project analyzes traffic accident data in Tainan City, Taiwan, during the second half of 2023 (July 1 – December 31). An Ordinary Kriging approach is applied to model the spatial distribution of traffic accident frequency. Fatal and injury-related accidents (A1/A2 types) are examined using logistic regression with distance to the nearest emergency hospital as a predictor. The resulting probability surface is then interpolated using Kriging to simulate spatial emergency rescue risk.

Results indicate that while densely populated downtown areas exhibit high accident frequencies, fatality risk does not necessarily increase. Instead, remote mountainous and coastal districts show relatively higher modeled emergency rescue risk, likely due to longer distances to medical facilities and reduced rescue timeliness.

## Introduction

Traffic safety has become a major public issue in Taiwan. Tainan City frequently appears among regions with high accident occurrences. This study uses spatial statistical techniques to analyze the spatial distribution of traffic accidents and evaluate emergency rescue risk related to the distance between accident locations and emergency hospitals.

The dataset, obtained from Taiwan’s open data platform, covers all registered traffic accidents in Tainan City from July to December 2023.

## Objectives

- Identify accident hotspots using Ordinary Kriging interpolation.

- Evaluate fatality-related risks using logistic regression with distance to hospitals as a predictor.

- Simulate emergency rescue risk using the fitted probability surface and Kriging interpolation.

- Provide insights into areas where emergency medical resources may need strengthening.

## Methods
**Semivariogram**

Spatial dependence was modeled using empirical semivariograms.
Parameters considered:

- Nugget

- Sill

- Range

A logarithmic transformation was applied to accident counts to mitigate the effect of extreme values.

**Ordinary Kriging**

Ordinary Kriging assumes:

- Unknown constant mean

- Best Linear Unbiased Prediction (BLUP)

- Weight sum equals 1

Kriging interpolation was conducted on a 100×100 spatial grid covering Tainan City.

**Leave-One-Out Cross-Validation**

LOOCV was used to evaluate model performance:

- Mean residual

- Mean squared prediction error (MSPE)

- Residual normality

**Correlation between predicted values and residuals**

- Shapiro–Wilk Normality Test

Used to test whether residuals follow a normal distribution.
Residuals of log-transformed accident counts passed normality assumptions.

- Logistic Regression

A logistic regression model was used:

$$logit(P)=β0+β1(distance to nearest hospital)$$

Response: A1 fatalities / total injuries

Predictor: distance to nearest emergency hospital

ROC AUC = 0.963, indicating strong classification performance

## Results
Accident Count Analysis

Raw accident counts range from single digits to over 500 at individual coordinates.

Log-transformed counts improve stability and interpolation quality.

Kriging predictions show:

Clear hotspots in urban districts (East, North, and West Central Districts).

Good residual distribution and model fit.
<img width="1048" height="750" alt="圖片" src="https://github.com/user-attachments/assets/d7a10023-cf7b-434a-b691-8d2443970eae" />

**Fatality-Related Risk**

Dense urban centers show many accidents but low fatality ratios.

Rural and mountainous regions show higher predicted fatality rates.

Semivariogram fitted with Gaussian model:

Sill = 0.0015

Range = 8000

Nugget = 0.0001

**Emergency Rescue Risk Simulation**

Using 6 Kriging simulations:

Highest risk in:

Mountainous districts (Nansi, Nanhua)

Adjacent districts (Baihe, Dongshan, Zuozhen, Longqi)

Coastal districts (Qigu, Annan, Jiangjun)

Reflects delays in emergency response and hospital accessibility.
<img width="880" height="505" alt="圖片" src="https://github.com/user-attachments/assets/fa1918df-5190-4397-9073-e3f9390137f2" />

## Conclusion

- **Accident frequency is highly correlated with population density and urban activity.**

- **Fatality risk is not highest in accident hotspots.**

- **Distance to emergency hospitals plays a critical role in fatality risk.**

- **Mountainous and coastal regions show the greatest emergency rescue risks.**

## Findings suggest prioritizing:

- **Increased medical resources**

- **Optimized ambulance dispatch**

- **Improved emergency infrastructure in remote districts**
