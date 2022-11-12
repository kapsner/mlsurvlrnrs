#' @title R6 Class to construct a Cox proportional hazards survival learner
#'
#' @description
#' The `LearnerSurvXgboostCox` class is the interface to perform a Cox
#'   regression with the `survival` R package for use with the `mlexperiments`
#'   package.
#'
#' @details
#' Can be used with
#' * [mlexperiments::MLCrossValidation]
#'
#' @seealso [survival::coxph()]
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
#'
#' surv_coxph_cox_optimizer <- mlexperiments::MLCrossValidation$new(
#'   learner = mllrnrs::LearnerSurvCoxPHCox$new(),
#'   fold_list = fold_list,
#'   ncores = -1L,
#'   seed = seed
#' )
#' surv_coxph_cox_optimizer$performance_metric <- c_index
#'
#' # set data
#' surv_coxph_cox_optimizer$set_data(
#'   x = train_x,
#'   y = train_y
#' )
#'
#' surv_coxph_cox_optimizer$execute()
#'
#' @export
#'
LearnerSurvCoxPHCox <- R6::R6Class( # nolint
  classname = "LearnerSurvCoxPHCox",
  inherit = mlexperiments::MLLearnerBase,
  public = list(

    #' @description
    #' Create a new `LearnerSurvCoxPHCox` object.
    #'
    #' @return A new `LearnerSurvCoxPHCox` R6 object.
    #'
    #' @examples
    #' LearnerSurvCoxPHCox$new()
    #'
    initialize = function() {
      if (!requireNamespace("survival", quietly = TRUE)) {
        stop(
          paste0(
            "Package \"survival\" must be installed to use ",
            "'learner = \"LearnerSurvCoxPHCox\"'."
          ),
          call. = FALSE
        )
      }
      super$initialize(metric_optimization_higher_better = NULL)
      self$environment <- "mlsurvlrnrs"
      private$fun_fit <- surv_coxph_cox_fit
      private$fun_predict <- surv_coxph_cox_predict

      # there is no optimization step here, so all related functions / fields
      # are set to NULL
      self$cluster_export <- NULL
      private$fun_optim_cv <- NULL
      private$fun_bayesian_scoring_function <- NULL
    }
  )
)

# pass parameters as ...
surv_coxph_cox_fit <- function(x, y, ncores, seed, ...) {
  message("Parameter 'ncores' is ignored for learner 'LearnerSurvCoxPHCox'.")
  params <- list(...)

  if ("cat_vars" %in% names(params)) {
    cat_vars <- params[["cat_vars"]]
  } else {
    cat_vars <- NULL
  }

  x <- kdry::dtr_matrix2df(matrix = x, cat_vars = cat_vars)

  cox_formula <- stats::as.formula(object = "y ~ .")

  args <- list(
    formula = cox_formula,
    data = x
  )

  set.seed(seed)
  # fit the model
  bst <- do.call(survival::coxph, args)
  return(bst)
}

surv_coxph_cox_predict <- function(model, newdata, ncores, ...) {
  params <- list(...)

  if ("cat_vars" %in% names(params)) {
    cat_vars <- params[["cat_vars"]]
  } else {
    cat_vars <- NULL
  }

  newdata <- kdry::dtr_matrix2df(matrix = newdata, cat_vars = cat_vars)

  # type the type of predicted value. Choices are the linear predictor ("lp"),
  # the risk score exp(lp) ("risk"), the expected number of events given the
  # covariates and follow-up time ("expected"), and the terms of the linear
  # predictor ("terms"). The survival probability for a subject is equal
  # to exp(-expected).
  return(stats::predict(model, newdata = newdata, type = "risk"))
}
