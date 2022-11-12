#' @title R6 Class to construct a Support Vector Machine survival learner
#'
#' @description
#' The `LearnerSurvSurvivalsvm` class is the interface to the `survivalsvm`
#'   R package for use with the `mlexperiments` package.
#'
#' @details
#' Optimization metric: C-index
#' Can be used with
#' * [mlexperiments::MLTuneParameters]
#' * [mlexperiments::MLCrossValidation]
#' * [mlexperiments::MLNestedCVs]
#'
#' @seealso [survivalsvm::survivalsvm()]
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
#' param_list_survivalsvm <- expand.grid(
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
#' surv_survivalsvm_optimizer <- mlexperiments::MLCrossValidation$new(
#'   learner = mllrnrs::LearnerSurvSurvivalsvm$new(),
#'   fold_list = fold_list,
#'   ncores = ncores,
#'   seed = seed
#' )
#' surv_survivalsvm_optimizer$learner_args <- as.list(
#'   data.table::data.table(param_list_survivalsvm[1, ],
#'                          stringsAsFactors = FALSE)
#' )
#' surv_survivalsvm_optimizer$performance_metric <- c_index
#'
#' # set data
#' surv_survivalsvm_optimizer$set_data(
#'   x = train_x,
#'   y = train_y
#' )
#'
#' surv_survivalsvm_optimizer$execute()
#'
#' @export
LearnerSurvSurvivalsvm <- R6::R6Class( # nolint
  classname = "LearnerSurvSurvivalsvm",
  inherit = mlexperiments::MLLearnerBase,
  public = list(

    #' @description
    #' Create a new `LearnerSurvSurvivalsvm` object.
    #'
    #' @return A new `LearnerSurvSurvivalsvm` R6 object.
    #'
    #' @examples
    #' LearnerSurvSurvivalsvm$new()
    #'
    initialize = function() {
      if (!requireNamespace("survivalsvm", quietly = TRUE)) {
        stop(
          paste0(
            "Package \"survivalsvm\" must be installed to use ",
            "'learner = \"LearnerSurvSurvivalsvm\"'."
          ),
          call. = FALSE
        )
      }
      super$initialize(metric_optimization_higher_better = TRUE)
      self$environment <- "mlsurvlrnrs"
      self$cluster_export <- surv_survivalsvm_ce()
      private$fun_optim_cv <- surv_survivalsvm_optimization
      private$fun_fit <- surv_survivalsvm_fit
      private$fun_predict <- surv_survivalsvm_predict
      private$fun_bayesian_scoring_function <- surv_survivalsvm_bsF
    }
  )
)


surv_survivalsvm_ce <- function() {
  c("surv_survivalsvm_optimization", "surv_survivalsvm_fit",
    "surv_survivalsvm_cv",
    "surv_survivalsvm_predict", "c_index")
}

surv_survivalsvm_bsF <- function(...) { # nolint

  params <- list(...)

  if (params$opt.meth == "ipop") {
    stop(paste0(
      "Bayesian optimization currently not possible with ",
      "'opt.meth = \"ipop\"' due to issues with parallelization."))
  }

  set.seed(seed)#, kind = "L'Ecuyer-CMRG")
  bayes_opt_survivalsvm <- surv_survivalsvm_optimization(
    x = x,
    y = y,
    params = params,
    fold_list = method_helper$fold_list,
    ncores = 1L, # important, as bayesian search is already parallelized
    seed = seed
  )

  ret <- kdry::list.append(
    list("Score" = bayes_opt_survivalsvm$metric_optim_mean),
    bayes_opt_survivalsvm
  )

  return(ret)
}

# Survivalsvm-cv is not implemented yet
surv_survivalsvm_cv <- function(
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

  # currently, there is no cross validation implemented in the survivalsvm
  # package.

  # loop over the folds
  for (fold in names(fold_list)) {

    # get row-ids of the current fold
    train_idx <- fold_list[[fold]]

    # train the model for this cv-fold
    args <- kdry::list.append(
      list(
        x = kdry::mlh_subset(x, train_idx),
        y = kdry::mlh_subset(y, train_idx),
        ncores = ncores,
        seed = seed
      ),
      params
    )

    outlist[[fold]] <- list()

    set.seed(seed)
    outlist[[fold]][["cvfit"]] <- do.call(surv_survivalsvm_fit, args)
    outlist[[fold]][["train_idx"]] <- train_idx

  }
  return(outlist)
}

surv_survivalsvm_optimization <- function(
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

  cvfit_list <- surv_survivalsvm_cv(
    x = x,
    y = y,
    params = params,
    fold_list = fold_list,
    ncores = ncores,
    seed = seed
  )

  # currently, there is no cross validation implemented in the Survivalsvm
  # package.
  # as the code has already been written for xgboost, I just adapt it here
  # to work for survival models with Survivalsvm and to accept a list of
  # parameters from the parmeter grid-search.

  # loop over the folds
  for (fold in names(cvfit_list)) {

    # get row-ids of the current fold
    cvfit <- cvfit_list[[fold]][["cvfit"]]
    train_idx <- cvfit_list[[fold]][["train_idx"]]

    # create predictions for calculating the c-index
    preds <- surv_survivalsvm_predict(
      model = cvfit,
      newdata = kdry::mlh_subset(x, -train_idx),
      cat_vars = params[["cat_vars"]],
      ncores = ncores
    )

    # calculate Harrell's c-index using the `glmnet::Cindex`-implementation
    perf <- c_index(
      predictions = preds,
      ground_truth = kdry::mlh_subset(y, -train_idx)
    )


    # save the results of this fold into a dataframe
    # from help("Survivalsvm::Survivalsvm"):
    # prediction.error - Overall out of bag prediction error. [...] for
    # survival one minus Harrell's C-index.
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

surv_survivalsvm_fit <- function(x, y, ncores, seed, ...) {
  kwargs <- list(...)
  stopifnot(
    inherits(y, "Surv"),
    (sapply(
    X = c("type", "gamma.mu"),
    FUN = function(x) {
      x %in% names(kwargs)
    }
  )),
  (!sapply(
    X = c("formula", "data", "subset",
          "time.variable.name", "status.variable.name"),
    FUN = function(x) {
      x %in% names(kwargs)
    }
  )))

  if ("cat_vars" %in% names(kwargs)) {
    cat_vars <- kwargs[["cat_vars"]]
    svm_params <- kwargs[names(kwargs) != "cat_vars"]
  } else {
    cat_vars <- NULL
    svm_params <- kwargs
  }

  svm_formula <- stats::as.formula(object = "y ~ .")

  fit_args <- kdry::list.append(
    list(
      formula = svm_formula,
      data = kdry::dtr_matrix2df(x, cat_vars = cat_vars)
    ),
    svm_params
  )

  #% initialize the parallel backend, if required
  #% if (ncores > 1L) {
  #%   cl <- kdry::pch_register_parallel(ncores)
  #%   on.exit(
  #%     expr = {
  #%       kdry::pch_clean_up(cl)
  #%     }
  #%   )
  #% }

  set.seed(seed)
  # train final model
  fit <- do.call(survivalsvm::survivalsvm, fit_args)
  return(fit)
}

surv_survivalsvm_predict <- function(model, newdata, ncores, ...) {
  kwargs <- list()
  if ("cat_vars" %in% names(kwargs)) {
    cat_vars <- kwargs[["cat_vars"]]
    svm_params <- kwargs[names(kwargs) != "cat_vars"]
  } else {
    cat_vars <- NULL
    svm_params <- kwargs
  }
  pred_args <- kdry::list.append(
    list(
      object = model,
      newdata = kdry::dtr_matrix2df(newdata, cat_vars = cat_vars)
    ),
    svm_params
  )
  preds <- do.call(stats::predict, pred_args)
  return(preds$predicted[1, ])
}
