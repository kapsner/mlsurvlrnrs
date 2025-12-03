

# mlsurvlrnrs NEWS

## Unreleased (2025-12-03)

#### Bug fixes

-   added adaptions for package to work with xgboost \> version 3
    ([875dacc](https://github.com/kapsner/mlsurvlrnrs/tree/875dacc242318436955373ace052aa520df9e05c))
-   fixed adaptions to new xgboost version
    ([99824a3](https://github.com/kapsner/mlsurvlrnrs/tree/99824a3ef17d0bc7ace3ad5724d99c17a24dd4db))
-   work on fixing xgboost-aft learner
    ([3672862](https://github.com/kapsner/mlsurvlrnrs/tree/3672862250aa0a23e0ea0cc92f3b3ab6ffa51126))

#### Tests

-   added unittest for usecase when learner-args are in param-grid
    ([8027dfc](https://github.com/kapsner/mlsurvlrnrs/tree/8027dfc3440af0fc09be2ffdaa12ae267cb19a92))

#### CI

-   added pre-commit hooks
    ([00a702a](https://github.com/kapsner/mlsurvlrnrs/tree/00a702aab2cbc032d53bc75817ff9cce3b4862d6))

#### Other changes

-   update to v0.0.7
    ([eaed8a8](https://github.com/kapsner/mlsurvlrnrs/tree/eaed8a873416e1d3ca4e233acf02b9969ea9625b))
-   udated dev-version
    ([b6ab10c](https://github.com/kapsner/mlsurvlrnrs/tree/b6ab10cce54e8fd3290660700ebf598cd66d6a3a))
-   updated news.md
    ([a2ca4aa](https://github.com/kapsner/mlsurvlrnrs/tree/a2ca4aa32fcb7b4bef0df0a1bdf6fbe5601fe909))

Full set of changes:
[`v0.0.6...eaed8a8`](https://github.com/kapsner/mlsurvlrnrs/compare/v0.0.6...eaed8a8)

## v0.0.6 (2025-09-09)

#### Other changes

-   updated description and news.md
    ([7ac6388](https://github.com/kapsner/mlsurvlrnrs/tree/7ac638806aeb7b1f57c021f24884464882bb44c1))
-   prepared fix / adaption to new mlexperiments version
    ([23db7a2](https://github.com/kapsner/mlsurvlrnrs/tree/23db7a23b4007216c9ec6f85e2ec7b566b5aad4b))
-   new dev-version
    ([b0cde14](https://github.com/kapsner/mlsurvlrnrs/tree/b0cde1402d5df6b9cc8a81a456f9c2e6bd27d7d0))
-   updated news.md
    ([79e8efc](https://github.com/kapsner/mlsurvlrnrs/tree/79e8efc600f2252d26bb3fd194bca4f6e0c5cb21))

Full set of changes:
[`v0.0.5...v0.0.6`](https://github.com/kapsner/mlsurvlrnrs/compare/v0.0.5...v0.0.6)

## v0.0.5 (2025-03-03)

#### Other changes

-   adresses notes on cran-checks
    ([69a69b7](https://github.com/kapsner/mlsurvlrnrs/tree/69a69b7cf54a592e5286f45ba33df359e78f051e))
-   updated dev-version
    ([10e794f](https://github.com/kapsner/mlsurvlrnrs/tree/10e794f8518996ea4901f33019b3854ec9a939ef))

Full set of changes:
[`v0.0.4...v0.0.5`](https://github.com/kapsner/mlsurvlrnrs/compare/v0.0.4...v0.0.5)

## v0.0.4 (2024-07-05)

#### CI

-   update gha
    ([6b1c869](https://github.com/kapsner/mlsurvlrnrs/tree/6b1c869bfe08472301bf53b4bf29cbcb8fe3181a))

#### Other changes

-   updated package for next cran-release
    ([34c6cfc](https://github.com/kapsner/mlsurvlrnrs/tree/34c6cfcb0e5cae3c462699e30fd2d16435b10999))
-   switched vignetteengine to quarto
    ([239e395](https://github.com/kapsner/mlsurvlrnrs/tree/239e39567361a83cf96f6ce3847ca19237508df7))
-   automated readme gen
    ([3fd0c35](https://github.com/kapsner/mlsurvlrnrs/tree/3fd0c35013f7010d0d26644799e000e6f894b2fb))
-   updated dev-version
    ([beb52a5](https://github.com/kapsner/mlsurvlrnrs/tree/beb52a59b3755e756698d6675ed01c80966f909b))
-   updated news.md
    ([3bbf43f](https://github.com/kapsner/mlsurvlrnrs/tree/3bbf43f8f65ceb6481164ac2568079af725c41f9))

Full set of changes:
[`v0.0.3...v0.0.4`](https://github.com/kapsner/mlsurvlrnrs/compare/v0.0.3...v0.0.4)

## v0.0.3 (2024-03-08)

#### Other changes

-   updated news.md
    ([5704c55](https://github.com/kapsner/mlsurvlrnrs/tree/5704c5588f23849b242c08e11f750b32be5ec030))
-   preparing v0.0.3
    ([f357782](https://github.com/kapsner/mlsurvlrnrs/tree/f3577822701386431c37471f7c0dd20f1bffcef8))
-   updated cran urls
    ([a602f3d](https://github.com/kapsner/mlsurvlrnrs/tree/a602f3d624fa8d91abc679eaa023c89eaa01b866))

Full set of changes:
[`v0.0.2...v0.0.3`](https://github.com/kapsner/mlsurvlrnrs/compare/v0.0.2...v0.0.3)

## v0.0.2 (2023-08-11)

#### Bug fixes

-   added cat_vars adaptions
    ([2b85d9c](https://github.com/kapsner/mlsurvlrnrs/tree/2b85d9c2535c274d892121a7a7dbe29d27ca8431))

#### Tests

-   back to bayesian optim
    ([1aef607](https://github.com/kapsner/mlsurvlrnrs/tree/1aef607374c2b907b1607a4ed5cff28a0ab83c6b))
-   removed tests with bayesian optimization as number of set cores
    seems to be ignored
    ([a14a610](https://github.com/kapsner/mlsurvlrnrs/tree/a14a610775fc2eadce9816cb2e0a7d36abb29130))
-   hard coding ncores since *R_CHECK_LIMIT_CORES* seems not to work on
    cran
    ([61af69f](https://github.com/kapsner/mlsurvlrnrs/tree/61af69fa535346fb6ef069f4f34ca1c71276d495))
-   updated unit tests
    ([1e6b5e7](https://github.com/kapsner/mlsurvlrnrs/tree/1e6b5e708f4dec1e9c45234b60e115f95f0bae08))
-   reduced runtime of unit-tests
    ([4d9b902](https://github.com/kapsner/mlsurvlrnrs/tree/4d9b9026d328bb52d86b8c568e587b99ce40319f))

#### Docs

-   wrapped xgboost examples into donttest
    ([675303d](https://github.com/kapsner/mlsurvlrnrs/tree/675303d5a11c581cc730b1f0399d8c49b9be6a45))
-   making vignettes static
    ([3dd080a](https://github.com/kapsner/mlsurvlrnrs/tree/3dd080a905589c727b337492a37c605fce198030))
-   fixed typo in vignettes
    ([7479fad](https://github.com/kapsner/mlsurvlrnrs/tree/7479fad1f53702102bff8d6e896b5a32b566da2c))
-   added coxph comparison to glmnet vignette
    ([570d375](https://github.com/kapsner/mlsurvlrnrs/tree/570d3758b6934fd1e87f9c93291af6ae7965d51a))

#### Other changes

-   updated news.md
    ([340e154](https://github.com/kapsner/mlsurvlrnrs/tree/340e154d1eb12cb5c4e07cbee0505ecbe3a3b0b5))
-   updated cran comments
    ([04889e3](https://github.com/kapsner/mlsurvlrnrs/tree/04889e39ce0b7fb87070a10621e705b52d19e5ef))
-   updated cran comments
    ([3c6e902](https://github.com/kapsner/mlsurvlrnrs/tree/3c6e9023a5d7290a36227d0f1049217109609c51))
-   updated version to 0.0.2
    ([2b86ec1](https://github.com/kapsner/mlsurvlrnrs/tree/2b86ec1efff73ea8eb798a78d64572dbce6a44c4))
-   survivalsvm to feature branch
    ([6ffbcc2](https://github.com/kapsner/mlsurvlrnrs/tree/6ffbcc20abc26ffe22eaee01b02e6f65f6547da3))
-   updated package description
    ([4286924](https://github.com/kapsner/mlsurvlrnrs/tree/428692428ec8fe7630ae826e9c2483506ca94188))
-   updated description and news.md
    ([5b2a189](https://github.com/kapsner/mlsurvlrnrs/tree/5b2a189258449e19bf1132cea57d69c56462acb4))
-   updated news.md
    ([47f1c21](https://github.com/kapsner/mlsurvlrnrs/tree/47f1c21f0bf91eba432dec35671411fab24bd4d0))

Full set of changes:
[`v0.0.1...v0.0.2`](https://github.com/kapsner/mlsurvlrnrs/compare/v0.0.1...v0.0.2)

## v0.0.1 (2022-11-13)

#### New features

-   transferred survival learners to new package
    ([a6de015](https://github.com/kapsner/mlsurvlrnrs/tree/a6de015f165d11be49859b5b99bab71b4163b324))

#### Bug fixes

-   fixed ci
    ([c659b70](https://github.com/kapsner/mlsurvlrnrs/tree/c659b70458f88c36ede5b390b6184a5555d96a53))

#### Other changes

-   renamed vignettes
    ([eabf108](https://github.com/kapsner/mlsurvlrnrs/tree/eabf108b05680f9e55e2657c445ed877ad7ddbe8))
-   updated urls in vignettes
    ([9e94f1c](https://github.com/kapsner/mlsurvlrnrs/tree/9e94f1c35e663e5bdfe98867c562c26603c3a6d5))

Full set of changes:
[`4fc6414...v0.0.1`](https://github.com/kapsner/mlsurvlrnrs/compare/4fc6414...v0.0.1)
