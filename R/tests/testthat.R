library(testthat)
remotes::install_github(
  "juposada93/i4results",
  subdir       = "R",                  # porque DESCRIPTION está allí
  INSTALL_opts = "--install-tests"     # para que test_check funcione
)

library(i4results)
test_package("i4results")

  


