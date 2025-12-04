#' @title R6 Class to construct a Ranger survival learner for Cox regression
#'
#' @description
#' The `LearnerSurvRangerCox` class is the interface to perform a Cox
#'   regression with the `ranger` R package for use with the `mlexperiments`
#'   package.
#'
#' @details
#' Optimization metric: C-index
#' Can be used with
#' * [mlexperiments::MLTuneParameters]
#' * [mlexperiments::MLCrossValidation]
#' * [mlexperiments::MLNestedCV]
#'
#' @seealso [ranger::ranger()]
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
#' param_list_ranger <- expand.grid(
#'   sample.fraction = seq(0.6, 1, .2),
#'   min.node.size = seq(1, 5, 4),
#'   mtry = seq(2, 6, 2),
#'   num.trees = c(5L, 10L),
#'   max.depth = seq(1, 5, 4)
#' )
#'
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
#' surv_ranger_cox_optimizer <- mlexperiments::MLCrossValidation$new(
#'   learner = LearnerSurvRangerCox$new(),
#'   fold_list = fold_list,
#'   ncores = ncores,
#'   seed = seed
#' )
#' surv_ranger_cox_optimizer$learner_args <- as.list(
#'   data.table::data.table(param_list_ranger[1, ], stringsAsFactors = FALSE)
#' )
#' surv_ranger_cox_optimizer$performance_metric <- c_index
#'
#' # set data
#' surv_ranger_cox_optimizer$set_data(
#'   x = train_x,
#'   y = train_y
#' )
#'
#' surv_ranger_cox_optimizer$execute()
#'
#' @export
LearnerSurvRangerCox <- R6::R6Class( # nolint
  classname = "LearnerSurvRangerCox",
  inherit = mlexperiments::MLLearnerBase,
  public = list(

    #' @description
    #' Create a new `LearnerSurvRangerCox` object.
    #'
    #' @return A new `LearnerSurvRangerCox` R6 object.
    #'
    #' @examples
    #' LearnerSurvRangerCox$new()
    #'
    initialize = function() {
      if (!requireNamespace("ranger", quietly = TRUE)) {
        stop(
          paste0(
            "Package \"ranger\" must be installed to use ",
            "'learner = \"LearnerSurvRangerCox\"'."
          ),
          call. = FALSE
        )
      }
      super$initialize(metric_optimization_higher_better = TRUE)
      self$environment <- "mlsurvlrnrs"
      self$cluster_export <- surv_ranger_cox_ce()
      private$fun_optim_cv <- surv_ranger_cox_optimization
      private$fun_fit <- mllrnrs:::ranger_fit
      private$fun_predict <- surv_ranger_cox_predict
      private$fun_bayesian_scoring_function <- surv_ranger_cox_bsF
    }
  )
)


surv_ranger_cox_ce <- function() {
  c("surv_ranger_cox_optimization", "surv_ranger_cox_cv",
    "surv_ranger_cox_predict", "c_index")
}

surv_ranger_cox_bsF <- function(...) { # nolint

  params <- list(...)

  params <- kdry::list.append(
    main_list = params,
    append_list = method_helper$execute_params["cat_vars"]
  )

  set.seed(seed)#, kind = "L'Ecuyer-CMRG")
  bayes_opt_ranger <- surv_ranger_cox_optimization(
    x = x,
    y = y,
    params = params,
    fold_list = method_helper$fold_list,
    ncores = 1L, # important, as bayesian search is already parallelized
    seed = seed
  )

  ret <- kdry::list.append(
    list("Score" = bayes_opt_ranger$metric_optim_mean),
    bayes_opt_ranger
  )

  return(ret)
}

# ranger-cv is not implemented yet
surv_ranger_cox_cv <- function(
    x,
    y,
    params,
    fold_list,
    ncores,
    seed
) {
  stopifnot(
    is.list(params)
  )

  outlist <- list()

  # currently, there is no cross validation implemented in the ranger package.
  # as the code has already been written for xgboost, I just adapt it here
  # to work for survival models with ranger and to accept a list of parameters
  # from the parmeter grid-search.

  # loop over the folds
  for (fold in names(fold_list)) {

    # get row-ids of the current fold
    ranger_train_idx <- fold_list[[fold]]

    # train the model for this cv-fold
    args <- kdry::list.append(
      list(
        x = kdry::mlh_subset(x, ranger_train_idx),
        y = kdry::mlh_subset(y, ranger_train_idx),
        ncores = ncores,
        seed = seed
      ),
      params
    )

    outlist[[fold]] <- list()

    set.seed(seed)
    outlist[[fold]][["cvfit"]] <- do.call(mllrnrs:::ranger_fit, args)
    outlist[[fold]][["train_idx"]] <- ranger_train_idx

  }
  return(outlist)
}

surv_ranger_cox_optimization <- function(
    x,
    y,
    params,
    fold_list,
    ncores,
    seed
) {

  # initialize a dataframe to store the results
  results_df <- data.table::data.table(
    "fold" = character(0),
    "metric" = numeric(0)
  )

  cvfit_list <- surv_ranger_cox_cv(
    x = x,
    y = y,
    params = params,
    fold_list = fold_list,
    ncores = ncores,
    seed = seed
  )

  # currently, there is no cross validation implemented in the ranger package.
  # as the code has already been written for xgboost, I just adapt it here
  # to work for survival models with ranger and to accept a list of parameters
  # from the parmeter grid-search.
  # loop over the folds
  for (fold in names(cvfit_list)) {

    # get row-ids of the current fold
    cvfit <- cvfit_list[[fold]][["cvfit"]]
    ranger_train_idx <- cvfit_list[[fold]][["train_idx"]]

    # create predictions for calculating the c-index
    preds <- surv_ranger_cox_predict(
      model = cvfit,
      newdata = kdry::mlh_subset(x, -ranger_train_idx),
      ncores = ncores,
      cat_vars = params[["cat_vars"]]
    )

    # calculate Harrell's c-index using the `glmnet::Cindex`-implementation
    perf <- c_index(
      predictions = preds,
      ground_truth = kdry::mlh_subset(y, -ranger_train_idx)
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
          "oob_metric" = 1 - cvfit$prediction.error,
          "metric" = perf
        )
      ),
      fill = TRUE
    )
  }

  res <- list(
    "metric_optim_mean" = mean(results_df$metric)
  )

  return(res)
}

surv_ranger_cox_predict <- function(model, newdata, ncores, ...) {
  preds <- mllrnrs:::ranger_predict_base(model, newdata, ncores, ...)

  # From the docs:
  # For type = 'response' (the default), the [...] survival probabilities
  # (survival) are returned.

  # ranger returns the survival probability S(t), which is the conditional
  # probability that a subject survives >= t, given that is has survived until t

  # https://github.com/imbs-hl/ranger/issues/617#issuecomment-1144443486
  # Internally, ranger uses the sum of chf over time to calculate the c-index,
  # i.e. rowSums(preds_ranger_prep$chf)
  pred_probs <- rowSums(preds$chf)

  # The Integrated/Cumulative Harzard H(t) = -log(S(t))
  #% time_point <-
  #%   which(preds$unique.death.times == max(preds$unique.death.times))
  #% pred_probs <- -log(preds$survival[, time_point])
  return(pred_probs)
}
