% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/i4results.R
\name{i4results}
\alias{i4results}
\title{Side-by-side comparison of models}
\usage{
i4results(original_model, robustness_models, out = NULL, append = FALSE)
}
\arguments{
\item{original_model}{A fitted model object understood by \code{broom::tidy}.}
\item{robustness_models}{A named list of additional fitted models.}
\item{out}{(Optional) Path to an Excel file for output.}
\item{append}{Logical. If TRUE, append to existing Excel file, otherwise overwrite.}
}
\value{
A data frame (invisibly) with the combined original and robustness statistics.
}
\description{
Exports side-by-side comparisons of coefficients from one original model and any number of robustness models. Uses \code{broom::tidy} so that many estimator types are supported. Results can optionally be written to Excel.
}
\examples{
\dontrun{
  mod_orig <- lm(mpg ~ cyl + disp, data = mtcars)
  mod_rep1 <- glm(mpg ~ cyl + disp + drat, data = mtcars)
  my_robustness <- list(rep1 = mod_rep1)
  i4results(mod_orig, my_robustness)
}
}
