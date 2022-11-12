#' @title c_index
#'
#' @description Calculate the Harrell's concordance index (C-index)
#'
#' @details
#' A wrapper function around [glmnet::Cindex()] for use with `mlexperiments`.
#'
#' @param ground_truth A `survival::Surv` object with the ground truth.
#' @param predictions A vector with predictions.
#'
#' @seealso [glmnet::Cindex()]
#'
#' @examples
#' set.seed(123)
#' gt <- survival::Surv(
#'   time = rnorm(100, 50, 15),
#'   event = sample(0:1, 100, TRUE)
#' )
#' preds <- rbeta(100, 2, 5)
#'
#' c_index(gt, preds)
#'
#' @export
#'
c_index <- function(ground_truth, predictions) {
  return(glmnet::Cindex(pred = predictions, y = ground_truth))
}
