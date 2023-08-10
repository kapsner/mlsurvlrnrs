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

ncores <- 2L

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
# %% NESTED CV
# ###########################################################################

test_that(
  desc = "test nested cv, grid - surv_glmnet_cox",
  code = {

    surv_glmnet_cox_optimizer <- mlexperiments::MLNestedCV$new(
      learner = LearnerSurvGlmnetCox$new(),
      strategy = "grid",
      fold_list = fold_list,
      k_tuning = 3L,
      ncores = ncores,
      seed = seed
    )

    set.seed(seed)
    selected_rows <- sample(
      x = seq_len(nrow(param_list_glmnet)),
      size = 2,
      replace = FALSE
    )
    surv_glmnet_cox_optimizer$parameter_grid <-
      kdry::mlh_subset(param_list_glmnet, selected_rows)
    surv_glmnet_cox_optimizer$split_type <- "stratified"
    surv_glmnet_cox_optimizer$split_vector <- split_vector

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
