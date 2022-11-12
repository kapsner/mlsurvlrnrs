# mlsurvlrnrs

<!-- badges: start -->
[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R build status](https://github.com/kapsner/mlsurvlrnrs/workflows/R%20CMD%20Check%20via%20{tic}/badge.svg?branch=main)](https://github.com/kapsner/mlsurvlrnrs/actions)
[![R build status](https://github.com/kapsner/mlsurvlrnrs/workflows/lint/badge.svg?branch=main)](https://github.com/kapsner/mlsurvlrnrs/actions)
[![R build status](https://github.com/kapsner/mlsurvlrnrs/workflows/test-coverage/badge.svg?branch=main)](https://github.com/kapsner/mlsurvlrnrs/actions)
[![codecov](https://codecov.io/gh/kapsner/mlsurvlrnrs/branch/main/graph/badge.svg?branch=main)](https://app.codecov.io/gh/kapsner/mlsurvlrnrs)
<!-- badges: end -->

The goal of `mlsurvlrnrs` is to enhance the [`mlexperiments`](https://github.com/kapsner/mlexperiments) R package with survival learners. 

Currently implemented learners are:

| Name | Based on | Description / Tasks |
| ---- | -------- | ------------------- |
| LearnerSurvCoxPHCox | `survival::coxph` | Cox Proportional Hazards Regression |
| LearnerSurvGlmnetCox | `glmnet::glmnet` | Regularized Cox Regression |
| LearnerSurvRangerCox | `ranger::ranger` | Random Survival Forest with right-censored data |
| LearnerSurvRpartCox | `rpart::rpart` | Random Survival Forest with right-censored data |
| LearnerSurvXgboostCox | `xgboost::xgb.train` | Cox Regression with right-censored data |
| LearnerSurvXgboostAft | `xgboost::xgb.train` | [Accelerated failure time models](https://xgboost.readthedocs.io/en/stable/tutorials/aft_survival_analysis.html) with right-censored data |
| LearnerSurvSurvivalsvm | `survivalsvm::survivalsmv` | Survival support vector analysis |

For a short introduction on how to use the learners together with the `mlexperiments` R package, please visit the [wiki page](https://github.com/kapsner/mlsurvlrnrs/wiki).

## Installation

To install the development version, run

```r
install.packages("remotes")
remotes::install_github("kapsner/mlsurvlrnrs")
```
