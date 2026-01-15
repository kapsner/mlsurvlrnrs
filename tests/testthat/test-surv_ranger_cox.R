dataset <- survival::colon |>
  data.table::as.data.table() |>
  na.omit()
dataset <- dataset[get("etype") == 2, ]

seed <- 123
surv_cols <- c("status", "time", "rx")

feature_cols <- colnames(dataset)[3:(ncol(dataset) - 1)]
cat_vars <- c("sex", "obstruct", "perfor", "adhere", "differ", "extent",
              "surg", "node4", "rx")

param_list_ranger <- expand.grid(
  sample.fraction = seq(0.6, 1, .2),
  min.node.size = seq(1, 5, 4),
  mtry = seq(2, 6, 2),
  num.trees = c(5L, 10L),
  max.depth = seq(1, 5, 4)
)

if (isTRUE(as.logical(Sys.getenv("_R_CHECK_LIMIT_CORES_")))) {
  # on cran
  ncores <- 2L
} else {
  ncores <- ifelse(
    test = parallel::detectCores() > 4,
    yes = 4L,
    no = ifelse(
      test = parallel::detectCores() < 2L,
      yes = 1L,
      no = parallel::detectCores()
    )
  )
}

split_vector <- splitTools::multi_strata(
  df = dataset[, .SD, .SDcols = surv_cols],
  strategy = "kmeans",
  k = 4
)

train_x <- data.matrix(
  dataset[, .SD, .SDcols = setdiff(feature_cols, surv_cols[1:2])]
)
train_y <- survival::Surv(
  event = (dataset[, get("status")] |>
             as.character() |>
             as.integer()),
  time = dataset[, get("time")],
  type = "right"
)

fold_list <- splitTools::create_folds(
  y = split_vector,
  k = 3,
  type = "stratified",
  seed = seed
)

options("mlexperiments.bayesian.max_init" = 4L)

# ###########################################################################
# %% TUNING
# ###########################################################################

ranger_bounds <- list(
  sample.fraction = c(0.2, 1),
  min.node.size = c(1L, 10L),
  mtry = c(2L, 10L),
  num.trees = c(1L, 10L),
  max.depth =  c(1L, 10L)
)
optim_args <- list(
  n_iter = ncores,
  kappa = 3.5,
  acq = "ucb"
)

# ###########################################################################
# %% NESTED CV
# ###########################################################################

test_that(
  desc = "test nested cv, bayesian - surv_ranger_cox",
  code = {

    testthat::skip_if_not_installed("rBayesianOptimizaion")
    testthat::skip_if_not_installed("ranger")

    surv_ranger_cox_optimizer <- mlexperiments::MLNestedCV$new(
      learner = LearnerSurvRangerCox$new(),
      strategy = "bayesian",
      fold_list = fold_list,
      k_tuning = 3L,
      ncores = ncores,
      seed = seed
    )

    surv_ranger_cox_optimizer$parameter_bounds <- ranger_bounds
    surv_ranger_cox_optimizer$parameter_grid <- param_list_ranger
    surv_ranger_cox_optimizer$split_type <- "stratified"
    surv_ranger_cox_optimizer$split_vector <- split_vector
    surv_ranger_cox_optimizer$optim_args <- optim_args

    surv_ranger_cox_optimizer$performance_metric <- c_index

    # set data
    surv_ranger_cox_optimizer$set_data(
      x = train_x,
      y = train_y
    )

    cv_results <- surv_ranger_cox_optimizer$execute()
    expect_type(cv_results, "list")
    expect_equal(dim(cv_results), c(3, 7))
    expect_true(inherits(
      x = surv_ranger_cox_optimizer$results,
      what = "mlexCV"
    ))
  }
)
