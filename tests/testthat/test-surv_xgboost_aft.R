dataset <- survival::colon |>
  data.table::as.data.table() |>
  na.omit()
dataset <- dataset[get("etype") == 2, ]

seed <- 123
surv_cols <- c("status", "time", "rx")

feature_cols <- colnames(dataset)[3:(ncol(dataset) - 1)]


param_list_xgboost <- expand.grid(
  objective = "survival:aft",
  eval_metric = "aft-nloglik",
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

options("mlexperiments.bayesian.max_init" = 10L)
options("mlexperiments.optim.xgb.nrounds" = 100L)
options("mlexperiments.optim.xgb.early_stopping_rounds" = 10L)

fold_list <- splitTools::create_folds(
  y = split_vector,
  k = 3,
  type = "stratified",
  seed = seed
)

# ###########################################################################
# %% CV
# ###########################################################################

test_that(
  desc = "test cv - surv_xgboost_aft",
  code = {

    surv_xgboost_aft_optimizer <- mlexperiments::MLCrossValidation$new(
      learner = mllrnrs::LearnerSurvXgboostAft$new(
        metric_optimization_higher_better = FALSE
      ),
      fold_list = fold_list,
      ncores = ncores,
      seed = seed
    )
    surv_xgboost_aft_optimizer$learner_args <- c(as.list(
      data.table::data.table(param_list_xgboost[1, ], stringsAsFactors = FALSE)
    ),
    nrounds = 45L
    )
    surv_xgboost_aft_optimizer$performance_metric <- c_index

    # set data
    surv_xgboost_aft_optimizer$set_data(
      x = train_x,
      y = train_y
    )

    cv_results <- surv_xgboost_aft_optimizer$execute()
    expect_type(cv_results, "list")
    expect_equal(dim(cv_results), c(3, 10))
    expect_true(inherits(
      x = surv_xgboost_aft_optimizer$results,
      what = "mlexCV"
    ))
  }
)

# ###########################################################################
# %% TUNING
# ###########################################################################

xgboost_bounds <- list(
  subsample = c(0.2, 1),
  colsample_bytree = c(0.2, 1),
  min_child_weight = c(1L, 10L),
  learning_rate = c(0.1, 0.2),
  max_depth =  c(1L, 10L)
)
optim_args <- list(
  iters.n = ncores,
  kappa = 3.5,
  acq = "ucb"
)

test_that(
  desc = "test bayesian tuner, initGrid - surv_xgboost_aft",
  code = {

    surv_xgboost_aft_tuner <- mlexperiments::MLTuneParameters$new(
      learner = mllrnrs::LearnerSurvXgboostAft$new(
        metric_optimization_higher_better = FALSE
      ),
      strategy = "bayesian",
      ncores = ncores,
      seed = seed
    )
    surv_xgboost_aft_tuner$parameter_bounds <- xgboost_bounds
    surv_xgboost_aft_tuner$parameter_grid <- param_list_xgboost
    surv_xgboost_aft_tuner$optim_args <- optim_args

    # create split-strata from training dataset
    surv_xgboost_aft_tuner$split_vector <- split_vector

    # set data
    surv_xgboost_aft_tuner$set_data(
      x = train_x,
      y = train_y
    )

    tune_results <- surv_xgboost_aft_tuner$execute(k = 3)
    expect_type(tune_results, "list")
    expect_true(inherits(x = surv_xgboost_aft_tuner$results, what = "mlexTune"))
  }
)


test_that(
  desc = "test grid tuner - surv_xgboost_aft",
  code = {

    surv_xgboost_aft_tuner <- mlexperiments::MLTuneParameters$new(
      learner = mllrnrs::LearnerSurvXgboostAft$new(
        metric_optimization_higher_better = FALSE
      ),
      strategy = "grid",
      ncores = ncores,
      seed = seed
    )
    set.seed(seed)
    random_grid <- sample(seq_len(nrow(param_list_xgboost)), 10)
    surv_xgboost_aft_tuner$parameter_grid <- param_list_xgboost[random_grid, ]

    # create split-strata from training dataset
    surv_xgboost_aft_tuner$split_vector <- split_vector

    # set data
    surv_xgboost_aft_tuner$set_data(
      x = train_x,
      y = train_y
    )

    tune_results <- surv_xgboost_aft_tuner$execute(k = 3)
    expect_type(tune_results, "list")
    expect_equal(dim(tune_results), c(10, 10))
    expect_true(inherits(x = surv_xgboost_aft_tuner$results, what = "mlexTune"))
  }
)

# ###########################################################################
# %% NESTED CV
# ###########################################################################


test_that(
  desc = "test nested cv, bayesian - surv_xgboost_aft",
  code = {

    surv_xgboost_aft_optimizer <- mlexperiments::MLNestedCV$new(
      learner = mllrnrs::LearnerSurvXgboostAft$new(
        metric_optimization_higher_better = FALSE
      ),
      strategy = "bayesian",
      fold_list = fold_list,
      k_tuning = 3L,
      ncores = ncores,
      seed = seed
    )

    surv_xgboost_aft_optimizer$parameter_bounds <- xgboost_bounds
    surv_xgboost_aft_optimizer$parameter_grid <- param_list_xgboost
    surv_xgboost_aft_optimizer$split_type <- "stratified"
    surv_xgboost_aft_optimizer$split_vector <- split_vector
    surv_xgboost_aft_optimizer$optim_args <- optim_args

    surv_xgboost_aft_optimizer$performance_metric <- c_index

    # set data
    surv_xgboost_aft_optimizer$set_data(
      x = train_x,
      y = train_y
    )

    cv_results <- surv_xgboost_aft_optimizer$execute()
    expect_type(cv_results, "list")
    expect_equal(dim(cv_results), c(3, 10))
    expect_true(inherits(
      x = surv_xgboost_aft_optimizer$results,
      what = "mlexCV"
    ))
  }
)


test_that(
  desc = "test nested cv, grid - surv_xgboost_aft",
  code = {

    surv_xgboost_aft_optimizer <- mlexperiments::MLNestedCV$new(
      learner = mllrnrs::LearnerSurvXgboostAft$new(
        metric_optimization_higher_better = FALSE
      ),
      strategy = "grid",
      fold_list = fold_list,
      k_tuning = 3L,
      ncores = ncores,
      seed = seed
    )
    set.seed(seed)
    random_grid <- sample(seq_len(nrow(param_list_xgboost)), 10)
    surv_xgboost_aft_optimizer$parameter_grid <-
      param_list_xgboost[random_grid, ]
    surv_xgboost_aft_optimizer$split_type <- "stratified"
    surv_xgboost_aft_optimizer$split_vector <- split_vector
    surv_xgboost_aft_optimizer$optim_args <- optim_args

    surv_xgboost_aft_optimizer$performance_metric <- c_index

    # set data
    surv_xgboost_aft_optimizer$set_data(
      x = train_x,
      y = train_y
    )

    cv_results <- surv_xgboost_aft_optimizer$execute()
    expect_type(cv_results, "list")
    expect_equal(dim(cv_results), c(3, 10))
    expect_true(inherits(
      x = surv_xgboost_aft_optimizer$results,
      what = "mlexCV"
    ))
  }
)
