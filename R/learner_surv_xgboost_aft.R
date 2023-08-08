#' @title R6 Class to construct a Xgboost survival learner for accelerated
#'   failure time models
#'
#' @description
#' The `LearnerSurvXgboostAft` class is the interface to accelerated failure
#'   time models with the `xgboost` R package for use with the `mlexperiments`
#'   package.
#'
#' @details
#' Optimization metric: needs to be specified with the learner parameter
#'   `eval_metric`.
#' Can be used with
#' * [mlexperiments::MLTuneParameters]
#' * [mlexperiments::MLCrossValidation]
#' * [mlexperiments::MLNestedCVs]
#' Also see the official xgboost documentation on
#'   [aft models](https://xgboost.readthedocs.io/en/stable/tutorials/aft_
#'   survival_analysis.html)
#'
#' @seealso [xgboost::xgb.train()], [xgboost::xgb.cv()]
#'
#' @examples
#' \donttest{# execution time >2.5 sec
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
#'   objective = "survival:aft",
#'   eval_metric = "aft-nloglik",
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
#' surv_xgboost_aft_optimizer <- mlexperiments::MLCrossValidation$new(
#'   learner = LearnerSurvXgboostAft$new(
#'     metric_optimization_higher_better = FALSE
#'   ),
#'   fold_list = fold_list,
#'   ncores = ncores,
#'   seed = seed
#' )
#' surv_xgboost_aft_optimizer$learner_args <- c(as.list(
#'   data.table::data.table(param_list_xgboost[1, ], stringsAsFactors = FALSE)
#' ),
#' nrounds = 45L
#' )
#' surv_xgboost_aft_optimizer$performance_metric <- c_index
#'
#' # set data
#' surv_xgboost_aft_optimizer$set_data(
#'   x = train_x,
#'   y = train_y
#' )
#'
#' surv_xgboost_aft_optimizer$execute()
#' }
#'
#' @export
#'
LearnerSurvXgboostAft <- R6::R6Class( # nolint
  classname = "LearnerSurvXgboostAft",
  inherit = mllrnrs::LearnerXgboost,
  public = list(

    #' @description
    #' Create a new `LearnerSurvXgboostAft` object.
    #'
    #' @param metric_optimization_higher_better A logical. Defines the direction
    #'  of the optimization metric used throughout the hyperparameter
    #'  optimization.
    #'
    #' @return A new `LearnerSurvXgboostAft` R6 object.
    #'
    #' @examples
    #' LearnerSurvXgboostAft$new(metric_optimization_higher_better = FALSE)
    #'
    initialize = function(metric_optimization_higher_better) { # nolint
      super$initialize(metric_optimization_higher_better =
                         metric_optimization_higher_better)
      self$environment <- "mlsurvlrnrs"
      self$cluster_export <- surv_xgboost_aft_ce()
      private$fun_optim_cv <- surv_xgboost_aft_optimization
      private$fun_bayesian_scoring_function <- surv_xgboost_aft_bsF
    }
  )
)


surv_xgboost_aft_ce <- function() {
  c("surv_xgboost_aft_optimization")
}


surv_xgboost_aft_bsF <- function(...) { # nolint

  params <- list(...)

  set.seed(seed)#, kind = "L'Ecuyer-CMRG")
  bayes_opt_xgboost <- surv_xgboost_aft_optimization(
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

surv_xgboost_aft_optimization <- function(
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
    params$objective == "survival:aft"
  )

  # initialize a dataframe to store the results
  results_df <- data.table::data.table(
    "fold" = character(0),
    "metric" = numeric(0)
  )

  # loop over the folds
  for (fold in names(fold_list)) {

    # get row-ids of the current fold
    train_idx <- fold_list[[fold]]

    dtrain <- mllrnrs:::setup_xgb_dataset(
      x = kdry::mlh_subset(x, train_idx),
      y = kdry::mlh_subset(y, train_idx),
      objective = params$objective
    )

    # use the rest for testing
    dtest <- mllrnrs:::setup_xgb_dataset(
      x = kdry::mlh_subset(x, -train_idx),
      y = kdry::mlh_subset(y, -train_idx),
      objective = params$objective
    )

    # setup the watchlist for monitoring the validation-metric using dtest
    # this is important for early-stopping
    watchlist <- list(train = dtrain, val = dtest)

    fit_args <- list(
      data = dtrain,
      params = params,
      print_every_n = as.integer(options("mlexperiments.xgb.print_every_n")),
      nthread = ncores,
      nrounds = as.integer(options("mlexperiments.optim.xgb.nrounds")),
      watchlist = watchlist,
      early_stopping_rounds = as.integer(
        options("mlexperiments.optim.xgb.early_stopping_rounds")
      ),
      verbose = as.logical(options("mlexperiments.xgb.verbose"))
    )

    set.seed(seed)
    # fit the model
    cvfit <- do.call(xgboost::xgb.train, fit_args)

    # create predictions for calculating the c-index
    preds <- mllrnrs:::xgboost_predict(
      model = cvfit,
      newdata = dtest,
      ncores = ncores
    )

    # calculate Harrell's c-index using the `glmnet::Cindex`-implementation
    perf <- c_index(
      predictions = preds,
      ground_truth = kdry::mlh_subset(y, -train_idx)
    )

    # save the results of this fold into a dataframe
    # from help("ranger::ranger"):
    # prediction.error - Overall out of bag prediction error. [...] for
    # survival one minus Harrell's C-index.
    results_df <- data.table::rbindlist(
      l = list(
        results_df,
        list(
          "fold" = fold,
          "metric" = cvfit$best_score,
          "validation_metric" = perf,
          "best_iteration" = cvfit$best_iteration
        )
      ),
      fill = TRUE
    )
  }

  res <- list(
    "metric_optim_mean" = mean(results_df$metric),
    "nrounds" = mean(results_df$best_iteration)
    #% nrounds + ceiling(nrounds * (1 / length(fold_list)))
  )

  return(res)
}
