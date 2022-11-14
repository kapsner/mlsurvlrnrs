dataset <- survival::colon |>
  data.table::as.data.table() |>
  na.omit()
dataset <- dataset[get("etype") == 2, ]

seed <- 123
surv_cols <- c("status", "time", "rx")

feature_cols <- colnames(dataset)[3:(ncol(dataset) - 1)]
cat_vars <- c("sex", "obstruct", "perfor", "adhere", "differ", "extent",
              "surg", "node4", "rx")

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

test_that(
  desc = "test cv - surv_coxph_cox",
  code = {

    surv_coxph_cox_optimizer <- mlexperiments::MLCrossValidation$new(
      learner = LearnerSurvCoxPHCox$new(),
      fold_list = fold_list,
      ncores = -1L,
      seed = seed
    )
    surv_coxph_cox_optimizer$performance_metric <- c_index

    # set data
    surv_coxph_cox_optimizer$set_data(
      x = train_x,
      y = train_y,
      cat_vars = cat_vars
    )

    cv_results <- surv_coxph_cox_optimizer$execute()
    expect_type(cv_results, "list")
    expect_equal(dim(cv_results), c(3, 2))
    expect_true(inherits(
      x = surv_coxph_cox_optimizer$results,
      what = "mlexCV"
    ))
  }
)
