library(testthat)

models_to_test <- list(
  lm = lm(mpg ~ wt + hp, data = mtcars),
  glm = glm(vs ~ mpg + wt, data = mtcars, family = binomial()),
  glm_nb = MASS::glm.nb(round(abs(mpg)) ~ wt + hp, data = mtcars),
  gam = mgcv::gam(mpg ~ s(wt) + hp, data = mtcars),
  cox = survival::coxph(survival::Surv(time, status) ~ age + sex, data = survival::lung)
)

robust_models <- list(
  rep1 = lm(mpg ~ wt + hp + disp, data = mtcars)
)

for (nm in names(models_to_test)) {
  test_that(paste("i4results works with", nm), {
    skip_if_not_installed("i4results")
    expect_s3_class(
      i4results(models_to_test[[nm]], robust_models),
      "data.frame"
    )
  })
}
