# nolint start
packagename <- "mlsurvlrnrs"

# remove existing description object
unlink("DESCRIPTION")
# Create a new description object
my_desc <- desc::description$new("!new")
# Set your package name
my_desc$set("Package", packagename)
#Set your name
my_desc$set_authors(c(
  person(
    given = "Lorenz A.",
    family = "Kapsner",
    email = "lorenz.kapsner@gmail.com",
    role = c('cre', 'aut', 'cph'),
    comment = c(ORCID = "0000-0003-1866-860X")
  )
))
# Remove some author fields
my_desc$del("Maintainer")
# Set the version
my_desc$set_version("0.0.6.9004")
# The title of your package
my_desc$set(Title = "R6-Based ML Survival Learners for 'mlexperiments'")
# The description of your package
my_desc$set(
  Description = paste0(
    "Enhances 'mlexperiments' <https://CRAN.R-project.org/package=mlexperiments> ",
    "with additional machine learning ('ML') learners for survival analysis. ",
    "The package provides R6-based survival learners for the following algorithms: ",
    "'glmnet' <https://CRAN.R-project.org/package=glmnet>, ",
    "'ranger' <https://CRAN.R-project.org/package=ranger>, ",
    "'xgboost' <https://CRAN.R-project.org/package=xgboost>, and ",
    "'rpart' <https://CRAN.R-project.org/package=rpart>. These can be ",
    "used directly with the 'mlexperiments' R package."
  )
)
# The description of your package
my_desc$set("Date/Publication" = paste(as.character(Sys.time()), "UTC"))
# The urls
my_desc$set("URL", "https://github.com/kapsner/mlsurvlrnrs")
my_desc$set("BugReports", "https://github.com/kapsner/mlsurvlrnrs/issues")

# Vignette Builder
my_desc$set("VignetteBuilder" = "quarto")
# Quarto
my_desc$set(
  "SystemRequirements" = paste0(
    "Quarto command line tools ",
    "(https://github.com/quarto-dev/quarto-cli)."
  )
)

# Testthat stuff
my_desc$set("Config/testthat/parallel" = "false")
my_desc$set("Config/testthat/edition" = "3")
# Roxygen
my_desc$set("Roxygen" = "list(markdown = TRUE)")

# Save everyting
my_desc$write(file = "DESCRIPTION")

# License
usethis::use_gpl3_license()

# Depends
usethis::use_package("R", min_version = "4.1.0", type = "Depends")

# Imports
# https://cran.r-project.org/web/packages/data.table/vignettes/datatable-importing.html
usethis::use_package("R6", type = "Imports")
usethis::use_package("data.table", type = "Imports")
usethis::use_package("kdry", type = "Imports")
usethis::use_package("stats", type = "Imports")
usethis::use_package("mlexperiments", type = "Imports", min_version = "0.0.8")
usethis::use_package("mllrnrs", type = "Imports")

# Suggests
usethis::use_package("testthat", type = "Suggests", min_version = "3.0.1")
usethis::use_package("lintr", type = "Suggests")
usethis::use_package("quarto", type = "Suggests")
usethis::use_package("glmnet", type = "Suggests")
usethis::use_package("xgboost", type = "Suggests", min_version = "3.1.1.1")
usethis::use_package("ranger", type = "Suggests")
usethis::use_package("rpart", type = "Suggests")
usethis::use_package("survival", type = "Suggests")
usethis::use_package("splitTools", type = "Suggests")
usethis::use_package("measures", type = "Suggests")
usethis::use_package("ParBayesianOptimization", type = "Suggests")


# define remotes
remotes_append_vector <- NULL

# Development package 1
tag1 <- "cran" # e.g. "v0.1.7", "development" or "cran"
if (tag1 == "cran") {
  install.packages("mlexperiments")
} else {
  remotes::install_github(
    repo = "kapsner/mlexperiments",
    ref = tag1
  )
  # add_remotes <- paste0(
  #   "url::https://gitlab.miracum.org/miracum/misc/diztools/-/archive/", tools_tag, "/diztools-", tools_tag, ".zip"
  # )
  add_remotes <- paste0(
    "github::kapsner/mlexperiments@",
    tag1
  )

  if (is.null(remotes_append_vector)) {
    remotes_append_vector <- add_remotes
  } else {
    remotes_append_vector <- c(remotes_append_vector, add_remotes)
  }
}

tag2 <- "cran" # e.g. "v0.1.7", "development" or "cran"
if (tag2 == "cran") {
  install.packages("kdry")
} else {
  remotes::install_github(
    repo = "kapsner/kdry",
    ref = tag2
  )
  # add_remotes <- paste0(
  #   "url::https://gitlab.miracum.org/miracum/misc/dizutils/-/archive/", utils_tag, "/dizutils-", utils_tag, ".zip"
  # )
  add_remotes <- paste0(
    "github::kapsner/kdry@",
    tag2
  )

  if (is.null(remotes_append_vector)) {
    remotes_append_vector <- add_remotes
  } else {
    remotes_append_vector <- c(remotes_append_vector, add_remotes)
  }
}

tag3 <- "cran" # e.g. "v0.1.7", "development" or "cran"
if (tag1 == "cran") {
  install.packages("mllrnrs")
} else {
  remotes::install_github(
    repo = "kapsner/mllrnrs",
    ref = tag3
  )
  # add_remotes <- paste0(
  #   "url::https://gitlab.miracum.org/miracum/misc/diztools/-/archive/", tools_tag, "/diztools-", tools_tag, ".zip"
  # )
  add_remotes <- paste0(
    "github::kapsner/mllrnrs@",
    tag3
  )

  if (is.null(remotes_append_vector)) {
    remotes_append_vector <- add_remotes
  } else {
    remotes_append_vector <- c(remotes_append_vector, add_remotes)
  }
}

# finally, add remotes (if required)
if (!is.null(remotes_append_vector)) {
  desc::desc_set_remotes(
    remotes_append_vector,
    file = usethis::proj_get()
  )
}

usethis::use_build_ignore("cran-comments.md")
usethis::use_build_ignore(".lintr")
usethis::use_build_ignore("tic.R")
usethis::use_build_ignore(".github")
usethis::use_build_ignore("NEWS.md")
usethis::use_build_ignore("README.md")
usethis::use_build_ignore("README.qmd")
usethis::use_build_ignore("docs")
usethis::use_build_ignore("Meta")
usethis::use_build_ignore("revdep")
usethis::use_build_ignore(".pre-commit-config.yaml")

usethis::use_git_ignore("!NEWS.md")
usethis::use_git_ignore("!README.md")
usethis::use_git_ignore("!README.qmd")
usethis::use_git_ignore("!cran-comments.md")
usethis::use_git_ignore("docs")
usethis::use_git_ignore("Meta")
usethis::use_git_ignore("!vignettes/*.qmd")
usethis::use_git_ignore("revdep")

usethis::use_tidy_description()

quarto::quarto_render(input = "README.qmd")


# https://github.com/gitpython-developers/GitPython/issues/1016#issuecomment-1104114129
# system(
#  command = paste0("git config --global --add safe.directory ", getwd())
# )

# create NEWS.md using the python-package "auto-changelog" (must be installed)
# https://www.conventionalcommits.org/en/v1.0.0/
# build|ci|docs|feat|fix|perf|refactor|test
# system(
#   command = 'auto-changelog -u -t "sjtable2df NEWS" --tag-prefix "v" -o "NEWS.md"'
# )
an <- autonewsmd::autonewsmd$new(repo_name = packagename)
an$generate()
an$write(force = TRUE)

# rcmdcheck::rcmdcheck(
#   args = c("--as-cran", "--no-vignettes"),
#   build_args = c("--no-build-vignettes")
# )

# nolint end
