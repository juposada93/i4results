install.packages("~/Dropbox/I4R/packages/R/i4results_0.1.0.tar.gz", repos = NULL, type = "source")

library(i4results)

# Example models
mtcars_lm_original <- lm(mpg ~ cyl + disp, data = mtcars)
mtcars_lm_rep1     <- lm(mpg ~ cyl + disp + drat, data = mtcars)
mtcars_lm_rep2     <- lm(mpg ~ cyl + disp + hp, data = mtcars)

my_robustness_list <- list(
  rep1 = mtcars_lm_rep1,
  rep2 = mtcars_lm_rep2
)

# export to Excel
i4results(mtcars_lm_original, my_robustness_list,
                  out = "~/Dropbox/I4R/packages/R/results.xlsx")


# append new results
my_robustness_list$rep3     <- lm(mpg ~ cyl + disp + wt, data = mtcars)

i4results(mtcars_lm_original, my_robustness_list,
                  out = "~/Dropbox/I4R/packages/R/results.xlsx", append = TRUE)