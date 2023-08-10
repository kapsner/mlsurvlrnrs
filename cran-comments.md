## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.
* Examples for the exported functions and classes were already available (see email conversation with Victoria)
* Examples and unit-tests have been checked to run at max with 2 cores. Vignettes were already static (`eval=FALSE`).
* BTW: I had to remove the environment variable `_R_CHECK_LIMIT_CORES_` and instead hard-code ncores. Is this env-var not set anymore on CRAN servers?
