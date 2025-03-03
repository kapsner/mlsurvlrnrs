# mlsurvlrnrs

<!-- badges: start -->

[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![](https://www.r-pkg.org/badges/version/mlsurvlrnrs)](https://cran.r-project.org/package=mlsurvlrnrs)
[![CRAN
checks](https://badges.cranchecks.info/worst/mlsurvlrnrs.svg)](https://cran.r-project.org/web/checks/check_results_mlsurvlrnrs.html)
[![](http://cranlogs.r-pkg.org/badges/grand-total/mlsurvlrnrs?color=blue)](https://cran.r-project.org/package=mlsurvlrnrs)
[![](http://cranlogs.r-pkg.org/badges/last-month/mlsurvlrnrs?color=blue)](https://cran.r-project.org/package=mlsurvlrnrs)
[![Dependencies](https://tinyverse.netlify.app/badge/mlsurvlrnrs)](https://cran.r-project.org/package=mlsurvlrnrs)
[![R build
status](https://github.com/kapsner/mlsurvlrnrs/workflows/R%20CMD%20Check%20via%20%7Btic%7D/badge.svg)](https://github.com/kapsner/mlsurvlrnrs/actions)
[![R build
status](https://github.com/kapsner/mlsurvlrnrs/workflows/lint/badge.svg)](https://github.com/kapsner/mlsurvlrnrs/actions)
[![R build
status](https://github.com/kapsner/mlsurvlrnrs/workflows/test-coverage/badge.svg)](https://github.com/kapsner/mlsurvlrnrs/actions)
[![](https://codecov.io/gh/https://github.com/kapsner/mlsurvlrnrs/branch/main/graph/badge.svg)](https://app.codecov.io/gh/https://github.com/kapsner/mlsurvlrnrs)
<!-- badges: end -->

The goal of `mlsurvlrnrs` is to enhance the
[`mlexperiments`](https://github.com/kapsner/mlexperiments) R package
with survival learners.

Currently implemented learners are:

| Name | Based on | Description / Tasks |
|----|----|----|
| LearnerSurvCoxPHCox | `survival::coxph` | Cox Proportional Hazards Regression |
| LearnerSurvGlmnetCox | `glmnet::glmnet` | Regularized Cox Regression |
| LearnerSurvRangerCox | `ranger::ranger` | Random Survival Forest with right-censored data |
| LearnerSurvRpartCox | `rpart::rpart` | Random Survival Forest with right-censored data |
| LearnerSurvXgboostCox | `xgboost::xgb.train` | Cox Regression with right-censored data |
| LearnerSurvXgboostAft | `xgboost::xgb.train` | [Accelerated failure time models](https://xgboost.readthedocs.io/en/stable/tutorials/aft_survival_analysis.html) with right-censored data |

For a short introduction on how to use the learners together with the
`mlexperiments` R package, please visit the [wiki
page](https://github.com/kapsner/mlsurvlrnrs/wiki).

## Installation

To install the development version, run

``` r
install.packages("remotes")
remotes::install_github("kapsner/mlsurvlrnrs")
```
