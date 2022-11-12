skip(message = "Skip all survivalsvm tests due to very long runtimes")

dataset <- survival::colon |>
  data.table::as.data.table() |>
  na.omit()
dataset <- dataset[get("etype") == 2, ]

seed <- 123
surv_cols <- c("status", "time", "rx")

feature_cols <- colnames(dataset)[3:(ncol(dataset) - 1)]

param_list_survivalsvm <- expand.grid(
  type = "regression",
  gamma.mu = seq(0.1, 0.9, 0.2),
  opt.meth = "ipop",
  kernel = "rbf_kernel",
  maxiter = 5
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
  desc = "test cv - surv_survivalsvm",
  code = {

    surv_survivalsvm_optimizer <- mlexperiments::MLCrossValidation$new(
      learner = mllrnrs::LearnerSurvSurvivalsvm$new(),
      fold_list = fold_list,
      ncores = ncores,
      seed = seed
    )
    surv_survivalsvm_optimizer$learner_args <- as.list(
      data.table::data.table(param_list_survivalsvm[1, ],
                             stringsAsFactors = FALSE)
    )
    surv_survivalsvm_optimizer$performance_metric <- c_index


    # set data
    surv_survivalsvm_optimizer$set_data(
      x = train_x,
      y = train_y
    )

    cv_results <- surv_survivalsvm_optimizer$execute()
    expect_type(cv_results, "list")
    expect_equal(dim(cv_results), c(3, 6))
    expect_true(inherits(
      x = surv_survivalsvm_optimizer$results,
      what = "mlexCV"
    ))
  }
)

# ###########################################################################
# %% TUNING
# ###########################################################################

survivalsvm_bounds <- list(
  gamma.mu = c(0., 1.)
)
optim_args <- list(
  iters.n = ncores,
  kappa = 3.5,
  acq = "ucb"
)

test_that(
  desc = "test bayesian tuner, initGrid - surv_survivalsvm",
  code = {

    surv_survivalsvm_tuner <- mlexperiments::MLTuneParameters$new(
      learner = mllrnrs::LearnerSurvSurvivalsvm$new(),
      strategy = "bayesian",
      ncores = ncores,
      seed = seed
    )
    surv_survivalsvm_tuner$parameter_bounds <- survivalsvm_bounds
    surv_survivalsvm_tuner$parameter_grid <- param_list_survivalsvm
    surv_survivalsvm_tuner$optim_args <- optim_args

    # create split-strata from training dataset
    surv_survivalsvm_tuner$split_vector <- split_vector

    # set data
    surv_survivalsvm_tuner$set_data(
      x = train_x,
      y = train_y
    )

    expect_error(surv_survivalsvm_tuner$execute(k = 3))
  }
)


test_that(
  desc = "test grid tuner - surv_survivalsvm",
  code = {

    surv_survivalsvm_tuner <- mlexperiments::MLTuneParameters$new(
      learner = mllrnrs::LearnerSurvSurvivalsvm$new(),
      strategy = "grid",
      ncores = ncores,
      seed = seed
    )
    surv_survivalsvm_tuner$parameter_grid <- param_list_survivalsvm

    # create split-strata from training dataset
    surv_survivalsvm_tuner$split_vector <- split_vector

    # set data
    surv_survivalsvm_tuner$set_data(
      x = train_x,
      y = train_y
    )

    tune_results <- surv_survivalsvm_tuner$execute(k = 3)
    expect_type(tune_results, "list")
    expect_equal(dim(tune_results), c(5, 6))
    expect_true(inherits(x = surv_survivalsvm_tuner$results, what = "mlexTune"))
  }
)

# ###########################################################################
# %% NESTED CV
# ###########################################################################

test_that(
  desc = "test nested cv, bayesian - surv_survivalsvm",
  code = {

    surv_survivalsvm_optimizer <- mlexperiments::MLNestedCV$new(
      learner = mllrnrs::LearnerSurvSurvivalsvm$new(),
      strategy = "bayesian",
      fold_list = fold_list,
      k_tuning = 3L,
      ncores = ncores,
      seed = seed
    )

    surv_survivalsvm_optimizer$parameter_bounds <- survivalsvm_bounds
    surv_survivalsvm_optimizer$parameter_grid <- param_list_survivalsvm
    surv_survivalsvm_optimizer$split_type <- "stratified"
    surv_survivalsvm_optimizer$split_vector <- split_vector
    surv_survivalsvm_optimizer$optim_args <- optim_args

    surv_survivalsvm_optimizer$performance_metric <- c_index

    # set data
    surv_survivalsvm_optimizer$set_data(
      x = train_x,
      y = train_y
    )

    expect_error(surv_survivalsvm_optimizer$execute())
  }
)


test_that(
  desc = "test nested cv, grid - surv_survivalsvm",
  code = {

    surv_survivalsvm_optimizer <- mlexperiments::MLNestedCV$new(
      learner = mllrnrs::LearnerSurvSurvivalsvm$new(),
      strategy = "grid",
      fold_list = fold_list,
      k_tuning = 3L,
      ncores = ncores,
      seed = seed
    )
    surv_survivalsvm_optimizer$parameter_grid <- param_list_survivalsvm
    surv_survivalsvm_optimizer$split_type <- "stratified"
    surv_survivalsvm_optimizer$split_vector <- split_vector
    surv_survivalsvm_optimizer$optim_args <- optim_args

    surv_survivalsvm_optimizer$performance_metric <- c_index

    # set data
    surv_survivalsvm_optimizer$set_data(
      x = train_x,
      y = train_y
    )

    cv_results <- surv_survivalsvm_optimizer$execute()
    expect_type(cv_results, "list")
    expect_equal(dim(cv_results), c(3, 6))
    expect_true(inherits(
      x = surv_survivalsvm_optimizer$results,
      what = "mlexCV"
    ))
  }
)
