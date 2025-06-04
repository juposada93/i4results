library(testthat)

# Simple unit test for i4results function

test_that("i4results handles lm models", {
  skip_if_not_installed("i4results")
  # fit original and robustness models
  orig <- lm(mpg ~ wt, data = mtcars)
  rob  <- list(rep1 = lm(mpg ~ wt + hp, data = mtcars))

  res <- i4results(orig, rob)

  expect_s3_class(res, "data.frame")
  expect_true(all(c("paramname", "study", "o_coeff", "r_coeff") %in% colnames(res)))
})
