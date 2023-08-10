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
# %% NESTED CV
# ###########################################################################

test_that(
  desc = "test nested cv, grid - surv_ranger_cox",
  code = {

    surv_ranger_cox_optimizer <- mlexperiments::MLNestedCV$new(
      learner = LearnerSurvRangerCox$new(),
      strategy = "grid",
      fold_list = fold_list,
      k_tuning = 3L,
      ncores = ncores,
      seed = seed
    )

    set.seed(seed)
    selected_rows <- sample(
      x = seq_len(nrow(param_list_ranger)),
      size = 10,
      replace = FALSE
    )

    surv_ranger_cox_optimizer$parameter_grid <-
      param_list_ranger[selected_rows, ]
    surv_ranger_cox_optimizer$split_type <- "stratified"
    surv_ranger_cox_optimizer$split_vector <- split_vector

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
