# rpkgTemplate

<!-- badges: start -->
[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R build status](https://github.com/kapsner/rpkgTemplate/workflows/R%20CMD%20Check%20via%20{tic}/badge.svg?branch=main)](https://github.com/kapsner/rpkgTemplate/actions)
[![R build status](https://github.com/kapsner/rpkgTemplate/workflows/lint/badge.svg?branch=main)](https://github.com/kapsner/rpkgTemplate/actions)
[![R build status](https://github.com/kapsner/rpkgTemplate/workflows/test-coverage/badge.svg?branch=main)](https://github.com/kapsner/rpkgTemplate/actions)
[![codecov](https://codecov.io/gh/kapsner/rpkgTemplate/branch/main/graph/badge.svg?branch=main)](https://app.codecov.io/gh/kapsner/rpkgTemplate)
<!-- badges: end -->

The goal of rpkgTemplate is to provide a minimal template for R package development that includes a

- setup for [GitHub actions](.github/workflows)
- [linter configuration](.lintr)
- a file for reproducible updates of the package setup: [devstuffs.R](./data-raw/devstuffs.R)
