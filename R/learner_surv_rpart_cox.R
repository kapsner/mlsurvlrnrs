#' @title LearnerSurvRpartCox R6 class
#'
#' @description
#' This learner is a wrapper around [rpart::rpart()] in order to fit recursive
#'   partitioning and regression trees with survival data.
#'
#' @details
#' Optimization metric: C-index
#' *
#' Can be used with
#' * [mlexperiments::MLTuneParameters]
#' * [mlexperiments::MLCrossValidation]
#' * [mlexperiments::MLNestedCV]
#'
#' Implemented methods:
#' * `$fit` To fit the model.
#' * `$predict` To predict new data with the model.
#' * `$cross_validation` To perform a grid search (hyperparameter
#'   optimization).
#' * `$bayesian_scoring_function` To perform a Bayesian hyperparameter
#'   optimization.
#'
#' Parameters that are specified with `parameter_grid` and / or `learner_args`
#'   are forwarded to `rpart`'s argument `control` (see
#'   [rpart::rpart.control()] for further details).
#'
#' @seealso [rpart::rpart()], [c_index()],
#'   [rpart::rpart.control()]
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
#' surv_rpart_optimizer <- mlexperiments::MLCrossValidation$new(
#'   learner = LearnerSurvRpartCox$new(),
#'   fold_list = fold_list,
#'   ncores = ncores,
#'   seed = seed
#' )
#' surv_rpart_optimizer$learner_args <- list(
#'   minsplit = 10L,
#'   maxdepth = 20L,
#'   cp = 0.03,
#'   method = "exp"
#' )
#' surv_rpart_optimizer$performance_metric <- c_index
#'
#' # set data
#' surv_rpart_optimizer$set_data(
#'   x = train_x,
#'   y = train_y
#' )
#'
#' surv_rpart_optimizer$execute()
#'
#' @export
#'
LearnerSurvRpartCox <- R6::R6Class( # nolint
  classname = "LearnerSurvRpartCox",
  inherit = mlexperiments::MLLearnerBase,
  public = list(
    #'
    #' @description
    #' Create a new `LearnerSurvRpartCox` object.
    #'
    #' @details
    #' This learner is a wrapper around [rpart::rpart()] in order to fit
    #'   recursive partitioning and regression trees with survival data.
    #'
    #' @seealso [rpart::rpart()], [c_index()],
    #'
    #' @examples
    #' LearnerSurvRpartCox$new()
    #'
    #' @export
    #'
    initialize = function() {
      if (!requireNamespace("rpart", quietly = TRUE)) {
        stop(
          paste0(
            "Package \"rpart\" must be installed to use ",
            "'learner = \"LearnerSurvRpartCox\"'."
          ),
          call. = FALSE
        )
      }
      super$initialize(
        metric_optimization_higher_better = TRUE # C-index
      )
      self$environment <- "mlsurvlrnrs"
      self$cluster_export <- c(
        "surv_rpart_cox_optimization", "surv_rpart_cox_fit",
        "surv_rpart_cox_predict"
      )
      private$fun_optim_cv <- surv_rpart_cox_optimization
      private$fun_fit <- function(x, y, ncores, seed, ...) {
        kwargs <- list(...)
        stopifnot(kwargs$method == "exp",
                  inherits(y, "Surv"))
        args <- kdry::list.append(
          list(
            x = x, y = y, ncores = ncores, seed = seed
          ),
          kwargs
        )
        return(do.call(surv_rpart_cox_fit, args))
      }
      private$fun_predict <- surv_rpart_cox_predict
      private$fun_bayesian_scoring_function <- surv_rpart_cox_bsF
    }
  )
)


surv_rpart_cox_bsF <- function(...) { # nolint
  params <- list(...)

  stopifnot(inherits(y, "Surv"))

  params <- kdry::list.append(
    main_list = params,
    append_list = method_helper$execute_params["cat_vars"]
  )

  # call to surv_rpart_cox_optimization here with ncores = 1, since the Bayesian
  # search is parallelized already / "FUN is fitted n times in m threads"
  set.seed(seed)#, kind = "L'Ecuyer-CMRG")
  bayes_opt_rpart <- surv_rpart_cox_optimization(
    x = x,
    y = y,
    params = params,
    fold_list = method_helper$fold_list,
    ncores = 1L, # important, as bayesian search is already parallelized
    seed = seed
  )

  ret <- kdry::list.append(
    list("Score" = bayes_opt_rpart$metric_optim_mean),
    bayes_opt_rpart
  )

  return(ret)
}


surv_rpart_cox_cv <- function(
    x,
    y,
    params,
    fold_list,
    ncores,
    seed
) {
  stopifnot(inherits(y, "Surv"))

  outlist <- list()

  # loop over the folds
  for (fold in names(fold_list)) {

    # get row-ids of the current fold
    train_idx <- fold_list[[fold]]

    # train the model for this cv-fold
    args <- kdry::list.append(
      list(
        y = kdry::mlh_subset(y, train_idx),
        x = kdry::mlh_subset(x, train_idx),
        ncores = ncores,
        seed = seed
      ),
      params
    )
    set.seed(seed)
    cvfit <- do.call(surv_rpart_cox_fit, args)
    outlist[[fold]] <- list(cvfit = cvfit,
                            train_idx = train_idx)
  }
  return(outlist)
}

surv_rpart_cox_optimization <- function(x, y, params, fold_list, ncores, seed) {
  stopifnot(
    is.list(params),
    "method" %in% names(params),
    params$method == "exp",
    inherits(y, "Surv")
  )

  args <- list(
    x = x,
    y = y,
    params = params,
    fold_list = fold_list,
    ncores = ncores,
    seed = seed
  )
  cv_fit_list <- do.call(surv_rpart_cox_cv, args)

  # initialize a dataframe to store the results
  results_df <- data.table::data.table(
    "fold" = character(0),
    "metric" = numeric(0)
  )

  for (fold in names(cv_fit_list)) {

    cvfit <- cv_fit_list[[fold]][["cvfit"]]
    train_idx <- cv_fit_list[[fold]][["train_idx"]]

    pred_args <- list(
      model = cvfit,
      newdata = kdry::mlh_subset(x, -train_idx),
      ncores = ncores,
      type = "vector",
      cat_vars = params[["cat_vars"]]
    )

    preds <- do.call(surv_rpart_cox_predict, pred_args)

    perf <- c_index(
      predictions = preds,
      ground_truth = kdry::mlh_subset(y, -train_idx)
    )

    results_df <- data.table::rbindlist(
      l = list(
        results_df,
        list(
          "fold" = fold,
          "validation_metric" = perf
        )
      ),
      fill = TRUE
    )
  }

  res <- list(
    "metric_optim_mean" = mean(results_df$validation_metric)
  )

  return(res)
}

surv_rpart_cox_fit <- function(x, y, ncores, seed, ...) {
  kwargs <- list(...)
  stopifnot("method" %in% names(kwargs),
            kwargs$method == "exp",
            inherits(y, "Surv"))
  fit_args <- kdry::list.append(
    list(
      x = x,
      y = y,
      ncores = ncores,
      seed = seed
    ),
    kwargs
  )
  return(do.call(mlexperiments:::rpart_fit, fit_args))
}

surv_rpart_cox_predict <- function(model, newdata, ncores, ...) {
  kwargs <- list(...)

  args <- list(
    model = model,
    newdata = newdata,
    ncores = ncores,
    kwargs = kwargs
  )
  preds <- do.call(mlexperiments:::rpart_predict_base, args)

  return(preds)
}
