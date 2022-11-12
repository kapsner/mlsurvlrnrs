dataset <- survival::colon |>
  data.table::as.data.table() |>
  na.omit()
dataset <- dataset[get("etype") == 2, ]

seed <- 123
surv_cols <- c("status", "time", "rx")

feature_cols <- colnames(dataset)[3:(ncol(dataset) - 1)]

param_list_glmnet <- expand.grid(
  alpha = seq(0, 1, .2)
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


# ###########################################################################
# %% CV
# ###########################################################################


test_that(
  desc = "test cv - surv_glmnet_cox",
  code = {

    surv_glmnet_cox_optimizer <- mlexperiments::MLCrossValidation$new(
      learner = mllrnrs::LearnerSurvGlmnetCox$new(),
      fold_list = fold_list,
      ncores = ncores,
      seed = seed
    )
    surv_glmnet_cox_optimizer$learner_args <- list(
      alpha = 0.8,
      lambda = 0.002
    )
    surv_glmnet_cox_optimizer$performance_metric <- c_index

    # set data
    surv_glmnet_cox_optimizer$set_data(
      x = train_x,
      y = train_y
    )

    cv_results <- surv_glmnet_cox_optimizer$execute()
    expect_type(cv_results, "list")
    expect_equal(dim(cv_results), c(3, 4))
    expect_true(inherits(
      x = surv_glmnet_cox_optimizer$results,
      what = "mlexCV"
    ))
  }
)

# ###########################################################################
# %% TUNING
# ###########################################################################

glmnet_bounds <- list(alpha = c(0., 1.))
optim_args <- list(
  iters.n = ncores,
  kappa = 3.5,
  acq = "ucb"
)

test_that(
  desc = "test bayesian tuner, initGrid - surv_glmnet_cox",
  code = {

    surv_glmnet_cox_tuner <- mlexperiments::MLTuneParameters$new(
      learner = mllrnrs::LearnerSurvGlmnetCox$new(),
      strategy = "bayesian",
      ncores = ncores,
      seed = seed
    )
    surv_glmnet_cox_tuner$parameter_bounds <- glmnet_bounds
    surv_glmnet_cox_tuner$parameter_grid <- param_list_glmnet
    surv_glmnet_cox_tuner$optim_args <- optim_args

    # create split-strata from training dataset
    surv_glmnet_cox_tuner$split_vector <- split_vector

    # set data
    surv_glmnet_cox_tuner$set_data(
      x = train_x,
      y = train_y
    )

    tune_results <- surv_glmnet_cox_tuner$execute(k = 3)
    expect_type(tune_results, "list")
    expect_true(inherits(x = surv_glmnet_cox_tuner$results, what = "mlexTune"))
  }
)


test_that(
  desc = "test bayesian tuner, initPoints - surv_glmnet_cox",
  code = {

    surv_glmnet_cox_tuner <- mlexperiments::MLTuneParameters$new(
      learner = mllrnrs::LearnerSurvGlmnetCox$new(),
      strategy = "bayesian",
      ncores = ncores,
      seed = seed
    )
    surv_glmnet_cox_tuner$parameter_bounds <- glmnet_bounds
    surv_glmnet_cox_tuner$optim_args <- optim_args

    # create split-strata from training dataset
    surv_glmnet_cox_tuner$split_vector <- split_vector

    # set data
    surv_glmnet_cox_tuner$set_data(
      x = train_x,
      y = train_y
    )

    tune_results <- surv_glmnet_cox_tuner$execute(k = 3)
    expect_type(tune_results, "list")
    expect_true(inherits(x = surv_glmnet_cox_tuner$results, what = "mlexTune"))
  }
)


test_that(
  desc = "test grid tuner - surv_glmnet_cox",
  code = {

    surv_glmnet_cox_tuner <- mlexperiments::MLTuneParameters$new(
      learner = mllrnrs::LearnerSurvGlmnetCox$new(),
      strategy = "grid",
      ncores = ncores,
      seed = seed
    )
    surv_glmnet_cox_tuner$parameter_grid <- param_list_glmnet

    # create split-strata from training dataset
    surv_glmnet_cox_tuner$split_vector <- split_vector

    # set data
    surv_glmnet_cox_tuner$set_data(
      x = train_x,
      y = train_y
    )

    tune_results <- surv_glmnet_cox_tuner$execute(k = 3)
    expect_type(tune_results, "list")
    expect_equal(dim(tune_results), c(nrow(param_list_glmnet), 4))
    expect_true(inherits(x = surv_glmnet_cox_tuner$results, what = "mlexTune"))
  }
)

# ###########################################################################
# %% NESTED CV
# ###########################################################################

test_that(
  desc = "test nested cv, bayesian - surv_glmnet_cox",
  code = {

    surv_glmnet_cox_optimizer <- mlexperiments::MLNestedCV$new(
      learner = mllrnrs::LearnerSurvGlmnetCox$new(),
      strategy = "bayesian",
      fold_list = fold_list,
      k_tuning = 3L,
      ncores = ncores,
      seed = seed
    )

    surv_glmnet_cox_optimizer$parameter_bounds <- glmnet_bounds
    surv_glmnet_cox_optimizer$parameter_grid <- param_list_glmnet
    surv_glmnet_cox_optimizer$split_type <- "stratified"
    surv_glmnet_cox_optimizer$split_vector <- split_vector
    surv_glmnet_cox_optimizer$optim_args <- optim_args

    surv_glmnet_cox_optimizer$performance_metric <- c_index

    # set data
    surv_glmnet_cox_optimizer$set_data(
      x = train_x,
      y = train_y
    )

    cv_results <- surv_glmnet_cox_optimizer$execute()
    expect_type(cv_results, "list")
    expect_equal(dim(cv_results), c(3, 4))
    expect_true(inherits(
      x = surv_glmnet_cox_optimizer$results,
      what = "mlexCV"
    ))
  }
)


test_that(
  desc = "test nested cv, grid - surv_glmnet_cox",
  code = {

    surv_glmnet_cox_optimizer <- mlexperiments::MLNestedCV$new(
      learner = mllrnrs::LearnerSurvGlmnetCox$new(),
      strategy = "grid",
      fold_list = fold_list,
      k_tuning = 3L,
      ncores = ncores,
      seed = seed
    )

    surv_glmnet_cox_optimizer$parameter_grid <- param_list_glmnet
    surv_glmnet_cox_optimizer$split_type <- "stratified"
    surv_glmnet_cox_optimizer$split_vector <- split_vector
    surv_glmnet_cox_optimizer$optim_args <- optim_args

    surv_glmnet_cox_optimizer$performance_metric <- c_index

    # set data
    surv_glmnet_cox_optimizer$set_data(
      x = train_x,
      y = train_y
    )

    cv_results <- surv_glmnet_cox_optimizer$execute()
    expect_type(cv_results, "list")
    expect_equal(dim(cv_results), c(3, 4))
    expect_true(inherits(
      x = surv_glmnet_cox_optimizer$results,
      what = "mlexCV"
    ))
  }
)
