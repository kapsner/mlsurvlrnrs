dataset <- survival::colon |>
  data.table::as.data.table() |>
  na.omit()
dataset <- dataset[get("etype") == 2, ]

seed <- 123
surv_cols <- c("status", "time", "rx")

feature_cols <- colnames(dataset)[3:(ncol(dataset) - 1)]


param_list_xgboost <- expand.grid(
  objective = "survival:cox",
  eval_metric = "cox-nloglik",
  subsample = seq(0.6, 1, .2),
  colsample_bytree = seq(0.6, 1, .2),
  min_child_weight = seq(1, 5, 4),
  learning_rate = c(0.1, 0.2),
  max_depth = seq(1, 5, 4)
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

train_x <- model.matrix(
  ~ -1 + .,
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
options("mlexperiments.optim.xgb.nrounds" = 20L)
options("mlexperiments.optim.xgb.early_stopping_rounds" = 5L)
# ###########################################################################
# %% TUNING
# ###########################################################################

learner_args <- NULL

xgboost_bounds <- list(
  subsample = c(0.2, 1),
  colsample_bytree = c(0.2, 1),
  min_child_weight = c(1L, 10L),
  learning_rate = c(0.1, 0.2),
  max_depth = c(1L, 10L)
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
  desc = "test nested cv, bayesian - surv_xgboost_cox",
  code = {

    testthat::skip_if_not_installed("rBayesianOptimizaion")
    testthat::skip_if_not_installed("xgboost")

    surv_xgboost_cox_optimizer <- mlexperiments::MLNestedCV$new(
      learner = LearnerSurvXgboostCox$new(
        metric_optimization_higher_better = FALSE
      ),
      strategy = "bayesian",
      fold_list = fold_list,
      k_tuning = 3L,
      ncores = ncores,
      seed = seed
    )

    set.seed(seed)
    random_grid <- sample(seq_len(nrow(param_list_xgboost)), 12)
    surv_xgboost_cox_optimizer$parameter_grid <-
      param_list_xgboost[random_grid, ]
    surv_xgboost_cox_optimizer$learner_args <- learner_args
    surv_xgboost_cox_optimizer$parameter_bounds <- xgboost_bounds
    surv_xgboost_cox_optimizer$split_type <- "stratified"
    surv_xgboost_cox_optimizer$split_vector <- split_vector
    surv_xgboost_cox_optimizer$optim_args <- optim_args

    surv_xgboost_cox_optimizer$performance_metric <- c_index

    # set data
    surv_xgboost_cox_optimizer$set_data(
      x = train_x,
      y = train_y
    )

    cv_results <- surv_xgboost_cox_optimizer$execute()
    expect_type(cv_results, "list")
    expect_equal(dim(cv_results), c(3, 10))
    expect_true(inherits(
      x = surv_xgboost_cox_optimizer$results,
      what = "mlexCV"
    ))
})


# ###########################################################################
# %% NESTED CV
# ###########################################################################

learner_args <- list(
  objective = "survival:cox",
  eval_metric = "cox-nloglik"
)


test_that(
  desc = "test nested cv, grid - surv_xgboost_cox",
  code = {

    testthat::skip_if_not_installed("xgboost")

    surv_xgboost_cox_optimizer <- mlexperiments::MLNestedCV$new(
      learner = LearnerSurvXgboostCox$new(
        metric_optimization_higher_better = FALSE
      ),
      strategy = "grid",
      fold_list = fold_list,
      k_tuning = 3L,
      ncores = ncores,
      seed = seed
    )

    set.seed(seed)
    random_grid <- sample(seq_len(nrow(param_list_xgboost)), 3)
    surv_xgboost_cox_optimizer$parameter_grid <-
      param_list_xgboost[random_grid, ]
    surv_xgboost_cox_optimizer$learner_args <- learner_args
    surv_xgboost_cox_optimizer$split_type <- "stratified"
    surv_xgboost_cox_optimizer$split_vector <- split_vector

    surv_xgboost_cox_optimizer$performance_metric <- c_index

    # set data
    surv_xgboost_cox_optimizer$set_data(
      x = train_x,
      y = train_y
    )

    cv_results <- surv_xgboost_cox_optimizer$execute()
    expect_type(cv_results, "list")
    expect_equal(dim(cv_results), c(3, 10))
    expect_true(inherits(
      x = surv_xgboost_cox_optimizer$results,
      what = "mlexCV"
    ))
})
