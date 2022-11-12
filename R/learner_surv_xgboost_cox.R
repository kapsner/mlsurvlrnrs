#' @title R6 Class to construct a Xgboost survival learner for Cox regression
#'
#' @description
#' The `LearnerSurvXgboostCox` class is the interface to perform a Cox
#'   regression with the `xgboost` R package for use with the `mlexperiments`
#'   package.
#'
#' @details
#' Optimization metric: needs to be specified with the learner parameter
#'   `eval_metric`.
#' Can be used with
#' * [mlexperiments::MLTuneParameters]
#' * [mlexperiments::MLCrossValidation]
#' * [mlexperiments::MLNestedCVs]
#'
#' @seealso [xgboost::xgb.train()], [xgboost::xgb.cv()]
#'
#' @examples
#' # survival analysis
#'
#' dataset <- survival::colon |>
#'   data.table::as.data.table() |>
#'   na.omit()
#' dataset <- dataset[get("etype") == 2, ]
#'
#' seed <- 123
#' surv_cols <- c("status", "time", "rx")
#'
#' feature_cols <- colnames(dataset)[3:(ncol(dataset) - 1)]
#'
#' param_list_xgboost <- expand.grid(
#'   objective = "survival:cox",
#'   eval_metric = "cox-nloglik",
#'   subsample = seq(0.6, 1, .2),
#'   colsample_bytree = seq(0.6, 1, .2),
#'   min_child_weight = seq(1, 5, 4),
#'   learning_rate = c(0.1, 0.2),
#'   max_depth = seq(1, 5, 4)
#' )
#' ncores <- 2L
#'
#' split_vector <- splitTools::multi_strata(
#'   df = dataset[, .SD, .SDcols = surv_cols],
#'   strategy = "kmeans",
#'   k = 4
#' )
#'
#' train_x <- model.matrix(
#'   ~ -1 + .,
#'   dataset[, .SD, .SDcols = setdiff(feature_cols, surv_cols[1:2])]
#' )
#' train_y <- survival::Surv(
#'   event = (dataset[, get("status")] |>
#'              as.character() |>
#'              as.integer()),
#'   time = dataset[, get("time")],
#'   type = "right"
#' )
#'
#' fold_list <- splitTools::create_folds(
#'   y = split_vector,
#'   k = 3,
#'   type = "stratified",
#'   seed = seed
#' )
#'
#' surv_xgboost_cox_optimizer <- mlexperiments::MLCrossValidation$new(
#'   learner = mllrnrs::LearnerSurvXgboostCox$new(
#'     metric_optimization_higher_better = FALSE
#'   ),
#'   fold_list = fold_list,
#'   ncores = ncores,
#'   seed = seed
#' )
#' surv_xgboost_cox_optimizer$learner_args <- c(as.list(
#'   data.table::data.table(param_list_xgboost[1, ], stringsAsFactors = FALSE)
#' ),
#' nrounds = 45L
#' )
#' surv_xgboost_cox_optimizer$performance_metric <- c_index
#'
#' # set data
#' surv_xgboost_cox_optimizer$set_data(
#'   x = train_x,
#'   y = train_y
#' )
#'
#' surv_xgboost_cox_optimizer$execute()

#' @export
#'
LearnerSurvXgboostCox <- R6::R6Class( # nolint
  classname = "LearnerSurvXgboostCox",
  inherit = mllrnrs::LearnerXgboost,
  public = list(

    #' @description
    #' Create a new `LearnerSurvXgboostCox` object.
    #'
    #' @param metric_optimization_higher_better A logical. Defines the direction
    #'  of the optimization metric used throughout the hyperparameter
    #'  optimization.
    #'
    #' @return A new `LearnerSurvXgboostCox` R6 object.
    #'
    #' @examples
    #' LearnerSurvXgboostCox$new(metric_optimization_higher_better = FALSE)
    #'
    initialize = function(metric_optimization_higher_better) { # nolint
      super$initialize(metric_optimization_higher_better =
                         metric_optimization_higher_better)
      self$environment <- "mlsurvlrnrs"
      self$cluster_export <- surv_xgboost_cox_ce()
      private$fun_optim_cv <- surv_xgboost_cox_optimization
      private$fun_bayesian_scoring_function <- surv_xgboost_cox_bsF
    }
  )
)


surv_xgboost_cox_ce <- function() {
  c("surv_xgboost_cox_optimization", "setup_surv_xgb_dataset",
    mllrnrs:::xgboost_ce())
}


surv_xgboost_cox_bsF <- function(...) { # nolint

  params <- list(...)

  set.seed(seed)#, kind = "L'Ecuyer-CMRG")
  bayes_opt_xgboost <- surv_xgboost_cox_optimization(
    x = x,
    y = y,
    params = params,
    fold_list = method_helper$fold_list,
    ncores = 1L, # important, as bayesian search is already parallelized
    seed = seed
  )

  ret <- kdry::list.append(
    list("Score" = bayes_opt_xgboost$metric_optim_mean),
    bayes_opt_xgboost
  )

  return(ret)
}

# tune lambda
surv_xgboost_cox_optimization <- function(
    x,
    y,
    params,
    fold_list,
    ncores,
    seed
  ) {
  stopifnot(
    inherits(x = y, what = "Surv"),
    is.list(params),
    params$objective == "survival:cox"
  )

  return(mllrnrs:::xgboost_optimization(x, y, params, fold_list, ncores, seed))
}
