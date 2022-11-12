#' @import data.table
#' @importFrom R6 R6Class
#' @importFrom mlexperiments MLLearnerBase
NULL

#% https://community.rstudio.com/t/how-to-solve-no-visible-binding-for-global-
#% variable-note/28887
utils::globalVariables(c("seed", "method_helper", "x", "y"))

mlexperiments_default_options <- list(
  mlexperiments.learner = c(
    LearnerSurvCoxPHCox$classname,
    LearnerSurvGlmnetCox$classname, # = "LearnerSurvGlmnetCox"
    LearnerSurvXgboostCox$classname,
    LearnerSurvXgboostAft$classname,
    LearnerSurvRangerCox$classname,
    LearnerSurvSurvivalsvm$classname,
    LearnerSurvRpartCox$classname
  ),
  mlexperiments.optim.xgb.nrounds = 5000L,
  mlexperiments.optim.xgb.early_stopping_rounds = 500L,
  mlexperiments.xgb.print_every_n = 50L,
  mlexperiments.xgb.verbose = FALSE
)


.onLoad <- function(libname, pkgname) {
  op <- options()
  toset <- !(names(mlexperiments_default_options) %in% names(op))
  if (any(toset)) options(mlexperiments_default_options[toset])
  invisible()
}

NULL
