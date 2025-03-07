% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/learner_surv_ranger_cox.R
\name{LearnerSurvRangerCox}
\alias{LearnerSurvRangerCox}
\title{R6 Class to construct a Ranger survival learner for Cox regression}
\description{
The \code{LearnerSurvRangerCox} class is the interface to perform a Cox
regression with the \code{ranger} R package for use with the \code{mlexperiments}
package.
}
\details{
Optimization metric: C-index
Can be used with
\itemize{
\item \link[mlexperiments:MLTuneParameters]{mlexperiments::MLTuneParameters}
\item \link[mlexperiments:MLCrossValidation]{mlexperiments::MLCrossValidation}
\item \link[mlexperiments:MLNestedCV]{mlexperiments::MLNestedCV}
}
}
\examples{
# survival analysis

dataset <- survival::colon |>
  data.table::as.data.table() |>
  na.omit()
dataset <- dataset[get("etype") == 2, ]

seed <- 123
surv_cols <- c("status", "time", "rx")

feature_cols <- colnames(dataset)[3:(ncol(dataset) - 1)]

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

surv_ranger_cox_optimizer <- mlexperiments::MLCrossValidation$new(
  learner = LearnerSurvRangerCox$new(),
  fold_list = fold_list,
  ncores = ncores,
  seed = seed
)
surv_ranger_cox_optimizer$learner_args <- as.list(
  data.table::data.table(param_list_ranger[1, ], stringsAsFactors = FALSE)
)
surv_ranger_cox_optimizer$performance_metric <- c_index

# set data
surv_ranger_cox_optimizer$set_data(
  x = train_x,
  y = train_y
)

surv_ranger_cox_optimizer$execute()


## ------------------------------------------------
## Method `LearnerSurvRangerCox$new`
## ------------------------------------------------

LearnerSurvRangerCox$new()

}
\seealso{
\code{\link[ranger:ranger]{ranger::ranger()}}
}
\section{Super class}{
\code{\link[mlexperiments:MLLearnerBase]{mlexperiments::MLLearnerBase}} -> \code{LearnerSurvRangerCox}
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-LearnerSurvRangerCox-new}{\code{LearnerSurvRangerCox$new()}}
\item \href{#method-LearnerSurvRangerCox-clone}{\code{LearnerSurvRangerCox$clone()}}
}
}
\if{html}{\out{
<details open><summary>Inherited methods</summary>
<ul>
<li><span class="pkg-link" data-pkg="mlexperiments" data-topic="MLLearnerBase" data-id="bayesian_scoring_function"><a href='../../mlexperiments/html/MLLearnerBase.html#method-MLLearnerBase-bayesian_scoring_function'><code>mlexperiments::MLLearnerBase$bayesian_scoring_function()</code></a></span></li>
<li><span class="pkg-link" data-pkg="mlexperiments" data-topic="MLLearnerBase" data-id="cross_validation"><a href='../../mlexperiments/html/MLLearnerBase.html#method-MLLearnerBase-cross_validation'><code>mlexperiments::MLLearnerBase$cross_validation()</code></a></span></li>
<li><span class="pkg-link" data-pkg="mlexperiments" data-topic="MLLearnerBase" data-id="fit"><a href='../../mlexperiments/html/MLLearnerBase.html#method-MLLearnerBase-fit'><code>mlexperiments::MLLearnerBase$fit()</code></a></span></li>
<li><span class="pkg-link" data-pkg="mlexperiments" data-topic="MLLearnerBase" data-id="predict"><a href='../../mlexperiments/html/MLLearnerBase.html#method-MLLearnerBase-predict'><code>mlexperiments::MLLearnerBase$predict()</code></a></span></li>
</ul>
</details>
}}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-LearnerSurvRangerCox-new"></a>}}
\if{latex}{\out{\hypertarget{method-LearnerSurvRangerCox-new}{}}}
\subsection{Method \code{new()}}{
Create a new \code{LearnerSurvRangerCox} object.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{LearnerSurvRangerCox$new()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
A new \code{LearnerSurvRangerCox} R6 object.
}
\subsection{Examples}{
\if{html}{\out{<div class="r example copy">}}
\preformatted{LearnerSurvRangerCox$new()

}
\if{html}{\out{</div>}}

}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-LearnerSurvRangerCox-clone"></a>}}
\if{latex}{\out{\hypertarget{method-LearnerSurvRangerCox-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{LearnerSurvRangerCox$clone(deep = FALSE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{deep}}{Whether to make a deep clone.}
}
\if{html}{\out{</div>}}
}
}
}
