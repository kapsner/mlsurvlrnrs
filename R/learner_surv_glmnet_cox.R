#' @title R6 Class to construct a Glmnet survival learner for Cox regression
#'
#' @description
#' The `LearnerSurvGlmnetCox` class is the interface to perform a Cox
#'   regression with the `glmnet` R package for use with the `mlexperiments`
#'   package.
#'
#' @details
#' Optimization metric: C-index
#' Can be used with
#' * [mlexperiments::MLTuneParameters]
#' * [mlexperiments::MLCrossValidation]
#' * [mlexperiments::MLNestedCV]
#'
#' @seealso [glmnet::glmnet()], [glmnet::cv.glmnet()]
#'
#' @examples
#' # survival analysis
#' if (requireNamespace("survival", quietly = TRUE) &&
#' requireNamespace("glmnet", quietly = TRUE)) {
#'
#'   dataset <- survival::colon |>
#'     data.table::as.data.table() |>
#'     na.omit()
#'   dataset <- dataset[get("etype") == 2, ]
#'
#'   seed <- 123
#'   surv_cols <- c("status", "time", "rx")
#'
#'   feature_cols <- colnames(dataset)[3:(ncol(dataset) - 1)]
#'
#'   param_list_glmnet <- expand.grid(
#'     alpha = seq(0, 1, .2)
#'   )
#'
#'   ncores <- 2L
#'
#'   split_vector <- splitTools::multi_strata(
#'     df = dataset[, .SD, .SDcols = surv_cols],
#'     strategy = "kmeans",
#'     k = 4
#'   )
#'
#'   train_x <- model.matrix(
#'     ~ -1 + .,
#'     dataset[, .SD, .SDcols = setdiff(feature_cols, surv_cols[1:2])]
#'   )
#'   train_y <- survival::Surv(
#'     event = (dataset[, get("status")] |>
#'                as.character() |>
#'                as.integer()),
#'     time = dataset[, get("time")],
#'     type = "right"
#'   )
#'
#'
#'   fold_list <- splitTools::create_folds(
#'     y = split_vector,
#'     k = 3,
#'     type = "stratified",
#'     seed = seed
#'   )
#'
#'   surv_glmnet_cox_optimizer <- mlexperiments::MLCrossValidation$new(
#'     learner = LearnerSurvGlmnetCox$new(),
#'     fold_list = fold_list,
#'     ncores = ncores,
#'     seed = seed
#'   )
#'   surv_glmnet_cox_optimizer$learner_args <- list(
#'     alpha = 0.8,
#'     lambda = 0.002
#'   )
#'   surv_glmnet_cox_optimizer$performance_metric <- c_index
#'
#'   # set data
#'   surv_glmnet_cox_optimizer$set_data(
#'     x = train_x,
#'     y = train_y
#'   )
#'
#'   surv_glmnet_cox_optimizer$execute()
#' }
#'
#' @export
#'
LearnerSurvGlmnetCox <- R6::R6Class(
  # nolint
  classname = "LearnerSurvGlmnetCox",
  inherit = mlexperiments::MLLearnerBase,
  public = list(
    #' @description
    #' Create a new `LearnerSurvGlmnetCox` object.
    #'
    #' @return A new `LearnerSurvGlmnetCox` R6 object.
    #'
    #' @examples
    #' if (requireNamespace("glmnet", quietly = TRUE)) {
    #'   LearnerSurvGlmnetCox$new()
    #' }
    #'
    initialize = function() {
      if (!requireNamespace("glmnet", quietly = TRUE)) {
        stop(
          paste0(
            "Package \"glmnet\" must be installed to use ",
            "'learner = \"LearnerSurvGlmnetCox\"'."
          ),
          call. = FALSE
        )
      }
      super$initialize(metric_optimization_higher_better = TRUE)
      self$environment <- "mlsurvlrnrs"
      self$cluster_export <- surv_glmnet_cox_ce()
      private$fun_optim_cv <- surv_glmnet_cox_optimization
      private$fun_fit <- surv_glmnet_cox_fit
      private$fun_predict <- surv_glmnet_cox_predict
      private$fun_bayesian_scoring_function <- surv_glmnet_cox_bsF
    }
  )
)


surv_glmnet_cox_ce <- function() {
  c("surv_glmnet_cox_optimization", "surv_glmnet_cox_fit")
}

surv_glmnet_cox_bsF <- function(...) {
  # nolint
  kwargs <- list(...)
  # call to surv_glmnet_cox_optimization here with ncores = 1, since the
  # Bayesian search is parallelized already / "FUN is fitted n times
  # in m threads"
  set.seed(seed) #, kind = "L'Ecuyer-CMRG")
  bayes_opt_glmnet <- surv_glmnet_cox_optimization(
    x = x,
    y = y,
    params = kwargs,
    fold_list = method_helper$fold_list,
    ncores = 1L, # important, as bayesian search is already parallelized
    seed = seed
  )

  ret <- kdry::list.append(
    list("Score" = bayes_opt_glmnet$metric_optim_mean),
    bayes_opt_glmnet
  )

  return(ret)
}

# tune lambda
surv_glmnet_cox_optimization <- function(
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
    "alpha" %in% names(params),
    (!sapply(
      X = c("x", "y", "foldid", "standardize", "type.measure", "family"),
      FUN = function(x) {
        x %in% names(params)
      }
    ))
  )

  # from the documentation (help("glmnet::cv.glmnet")):
  # If users would like to cross-validate alpha as well, they should call
  # cv.glmnet with a pre-computed vector foldid, and then use this same
  # fold vector in separate calls to cv.glmnet with different values
  # of alpha.
  glmnet_fids <- kdry::mlh_outsample_row_indices(
    fold_list = fold_list,
    dataset_nrows = nrow(x),
    type = "glmnet"
  )

  # initialize the parallel backend, if required
  if (ncores > 1L) {
    cl <- kdry::pch_register_parallel(ncores)
    on.exit(
      expr = {
        kdry::pch_clean_up(cl)
      }
    )
    go_parallel <- TRUE
  } else {
    go_parallel <- FALSE
  }

  cv_args <- kdry::list.append(
    params,
    list(
      x = x,
      y = y,
      family = "cox",
      foldid = glmnet_fids$fold_id,
      type.measure = "C",
      parallel = go_parallel,
      standardize = TRUE
    )
  )

  set.seed(seed)
  # fit the glmnet-cv-model
  cvfit <- do.call(glmnet::cv.glmnet, cv_args)

  res <- list(
    "metric_optim_mean" = max(cvfit$cvm), # we are optimizing the C-index
    "lambda" = cvfit$lambda.min
  )

  return(res)
}

surv_glmnet_cox_fit <- function(x, y, ncores, seed, ...) {
  kwargs <- list(...)
  stopifnot(
    !sapply(
      X = c("x", "y", "family", "standardize"),
      FUN = function(x) {
        x %in% names(kwargs)
      }
    )
  )
  kwargs <- kdry::list.append(
    kwargs,
    list(
      family = "cox",
      standardize = TRUE
    )
  )
  fit_args <- kdry::list.append(
    list(
      x = x,
      y = y,
      ncores = ncores,
      seed = seed
    ),
    kwargs
  )
  return(do.call(mllrnrs:::glmnet_fit, fit_args))
}

surv_glmnet_cox_predict <- function(model, newdata, ncores, ...) {
  kwargs <- list(...) # nolint

  if (is.null(kwargs$type)) {
    kwargs$type <- "response"
  }
  args <- kdry::list.append(
    list(
      object = model,
      newx = newdata
    ),
    kwargs
  )
  preds <- do.call(stats::predict, args)
  # From the docs:
  # Type "response" gives [...] the fitted relative-risk for "cox".
  if (kwargs$type == "response") {
    preds <- preds[, 1]
  }
  return(preds)
}
