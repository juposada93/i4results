#' Side-by-side comparison of models
#'
#' Extract coefficients from an original model and several robustness models using
#' [broom::tidy]. Any model supported by `broom` can be used (e.g. `lm`, `glm`,
#' `glm.nb`, `coxph`, `gam`, `lmer`, `feols`, ...). The output can be returned as
#' a data frame or written to an Excel file.
#'
#' @param original_model A fitted model object.
#' @param robustness_models A named list of additional fitted models.
#' @param out Optional path to an Excel file for exporting results.
#' @param append If `TRUE`, append to an existing Excel file.
#'
#' @return Invisibly returns a data frame with the combined statistics.
#' @export
#'
#' @examples
#' orig <- lm(mpg ~ wt, data = mtcars)
#' rob  <- list(glm = glm(mpg ~ wt, data = mtcars))
#' i4results(orig, rob)
#'
#' @importFrom broom tidy
#' @importFrom stats nobs
#' @importFrom openxlsx read.xlsx write.xlsx
#' @family i4r
i4results <- function(original_model,
                      robustness_models,
                      out = NULL,
                      append = FALSE) {
  if (!is.null(out) && !requireNamespace("openxlsx", quietly = TRUE)) {
    stop("Package 'openxlsx' needed for Excel import/export. Please install it.")
  }
  if (!requireNamespace("broom", quietly = TRUE)) {
    stop("Package 'broom' needed for model extraction. Please install it.")
  }

  if (length(robustness_models) > 5) {
    stop("You can supply up to 5 robustness models only.")
  }

  o_cmdline <- paste(deparse(original_model$call), collapse = " ")
  o_n <- tryCatch(stats::nobs(original_model), error = function(e) NA)
  tidy_o <- broom::tidy(original_model, conf.int = TRUE)
  tidy_o <- tidy_o[!(tidy_o$term %in% "(Intercept)"), ]
  paramlist_all <- tidy_o$term

  results_list <- list()

  for (rep_name in names(robustness_models)) {
    rep_model <- robustness_models[[rep_name]]
    r_cmdline <- paste(deparse(rep_model$call), collapse = " ")
    r_n <- tryCatch(stats::nobs(rep_model), error = function(e) NA)
    tidy_r <- broom::tidy(rep_model, conf.int = TRUE)
    tidy_r <- tidy_r[!(tidy_r$term %in% "(Intercept)"), ]

    for (p in paramlist_all) {
      o_row <- tidy_o[tidy_o$term == p, ]
      r_row <- if (p %in% tidy_r$term) {
        tidy_r[tidy_r$term == p, ]
      } else {
        data.frame(term = p, estimate = NA, std.error = NA, statistic = NA,
                   p.value = NA, conf.low = NA, conf.high = NA)
      }

      record <- data.frame(
        paramname = p,
        study = rep_name,
        o_cmdline = substring(o_cmdline, 1, 244),
        r_cmdline = substring(r_cmdline, 1, 244),
        o_n = o_n,
        r_n = r_n,
        o_coeff = round(o_row$estimate, 3),
        o_std_err = round(o_row$std.error, 3),
        o_t = round(o_row$statistic, 3),
        o_p_val = round(o_row$p.value, 3),
        o_ci_lower = round(o_row$conf.low, 3),
        o_ci_upper = round(o_row$conf.high, 3),
        r_coeff = round(r_row$estimate, 3),
        r_std_err = round(r_row$std.error, 3),
        r_t = round(r_row$statistic, 3),
        r_p_val = round(r_row$p.value, 3),
        r_ci_lower = round(r_row$conf.low, 3),
        r_ci_upper = round(r_row$conf.high, 3),
        stringsAsFactors = FALSE
      )
      results_list[[length(results_list) + 1]] <- record
    }
  }

  results_df <- do.call(rbind, results_list)

  if (!is.null(out)) {
    if (append && file.exists(out)) {
      oldres <- openxlsx::read.xlsx(out)
      combined <- rbind(oldres, results_df)
      openxlsx::write.xlsx(combined, file = out, asTable = FALSE)
      message(paste("Appended results to Excel file:", out))
    } else {
      openxlsx::write.xlsx(results_df, file = out, asTable = FALSE)
      if (append) {
        message(paste("File did not exist, so created a new Excel file:", out))
      } else {
        message(paste("Exported results to Excel file:", out))
      }
    }
  } else {
    message("Data with original & robustness comparisons returned as a data frame.")
  }

  invisible(results_df)
}
