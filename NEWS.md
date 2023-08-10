# mlsurvlrnrs NEWS

## Unreleased (2023-08-10)

#### Bug fixes

-   added cat\_vars adaptions
    ([2b85d9c](https://github.com/kapsner/mlsurvlrnrs/tree/2b85d9c2535c274d892121a7a7dbe29d27ca8431))

#### Tests

-   removed tests with bayesian optimization as number of set cores
    seems to be ignored
    ([a14a610](https://github.com/kapsner/mlsurvlrnrs/tree/a14a610775fc2eadce9816cb2e0a7d36abb29130))
-   hard coding ncores since *R\_CHECK\_LIMIT\_CORES* seems not to work
    on cran
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
[`v0.0.1...a14a610`](https://github.com/kapsner/mlsurvlrnrs/compare/v0.0.1...a14a610)

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
