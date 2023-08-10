dataset <- survival::colon |>
  data.table::as.data.table() |>
  na.omit()
dataset <- dataset[get("etype") == 2, ]

seed <- 123
surv_cols <- c("status", "time", "rx")

feature_cols <- colnames(dataset)[3:(ncol(dataset) - 1)]
cat_vars <- c("sex", "obstruct", "perfor", "adhere", "differ", "extent",
              "surg", "node4", "rx")

ncores <- 2L

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

# ###########################################################################
# %% TUNING
# ###########################################################################

param_list_rpart <- expand.grid(
  minsplit = seq(2L, 82L, 10L),
  cp = seq(0.01, 0.1, 0.01),
  maxdepth = seq(2L, 30L, 5L)
)

# ###########################################################################
# %% NESTED CV
# ###########################################################################

test_that(
  desc = "test nested cv, grid - surv_rpart_cox",
  code = {

    surv_rpart_cox_optimizer <- mlexperiments::MLNestedCV$new(
      learner = LearnerSurvRpartCox$new(),
      strategy = "grid",
      fold_list = fold_list,
      k_tuning = 3L,
      ncores = ncores,
      seed = seed
    )
    surv_rpart_cox_optimizer$learner_args <- list(method = "exp")

    set.seed(seed)
    selected_rows <- sample(
      x = seq_len(nrow(param_list_rpart)),
      size = 10,
      replace = FALSE
    )

    surv_rpart_cox_optimizer$parameter_grid <-
      param_list_rpart[selected_rows, ]
    surv_rpart_cox_optimizer$split_type <- "stratified"
    surv_rpart_cox_optimizer$split_vector <- split_vector

    surv_rpart_cox_optimizer$performance_metric <- c_index

    # set data
    surv_rpart_cox_optimizer$set_data(
      x = train_x,
      y = train_y,
      cat_vars = cat_vars
    )

    cv_results <- surv_rpart_cox_optimizer$execute()
    expect_type(cv_results, "list")
    expect_true(inherits(
      x = surv_rpart_cox_optimizer$results,
      what = "mlexCV"
    ))
  }
)
