#' Side-by-side comparison of models
#'
#' Extracts coefficients from an original model and any number of robustness
#' models using [broom::tidy]. Any model supported by `broom` works (lm, glm,
#' glm.nb, coxph, gam, lmer, feols, ...). Results are returned as a
#' data.frame or exported to Excel.
#'
#' @param original_model  Fitted model object.
#' @param robustness_models Named list of additional models.
#' @param out   Optional path to an Excel file.
#' @param append If `TRUE`, append to an existing Excel workbook.
#'
#' @return Invisibly returns a data.frame with the combined statistics.
#' @export
#'
#' @importFrom broom tidy
#' @importFrom stats nobs
#' @importFrom openxlsx read.xlsx write.xlsx
#' @family i4r
i4results <- function(original_model,
                      robustness_models,
                      out    = NULL,
                      append = FALSE) {
  
  ## ── Dependencies ────────────────────────────────────────────────────────────
  if (!is.null(out) && !requireNamespace("openxlsx", quietly = TRUE)) {
    stop("Package 'openxlsx' needed for Excel import/export. Please install it.")
  }
  if (!requireNamespace("broom", quietly = TRUE)) {
    stop("Package 'broom' needed for model extraction. Please install it.")
  }
  ## Any number of robustness models can be compared
  
  ## ── Helper to ensure numeric columns ──────────────────────────────
  safe_tidy <- function(model) {
    tx <- broom::tidy(model, conf.int = TRUE)
    tx <- tx[!(tx$term %in% "(Intercept)"), ]
    
    needed <- c("estimate", "std.error", "statistic",
                "p.value", "conf.low", "conf.high")
    for (col in needed) {
      if (!col %in% names(tx)) tx[[col]] <- NA_real_
    }
    tx
  }
  
  ## ── Original model ────────────────────────────────────────────────────────
  o_cmdline <- paste(deparse(original_model$call), collapse = " ")
  o_n       <- tryCatch(stats::nobs(original_model), error = function(e) NA)
  tidy_o    <- safe_tidy(original_model)
  paramlist_all <- tidy_o$term
  
  ## ── Iterate over robustness models ───────────────────────────────────────
  results_list <- list()
  
  for (rep_name in names(robustness_models)) {
    rep_model <- robustness_models[[rep_name]]
    
    r_cmdline <- paste(deparse(rep_model$call), collapse = " ")
    r_n       <- tryCatch(stats::nobs(rep_model), error = function(e) NA)
    tidy_r    <- safe_tidy(rep_model)
    
    for (p in paramlist_all) {
      o_row <- tidy_o[tidy_o$term == p, ]
      r_row <- if (p %in% tidy_r$term) {
        tidy_r[tidy_r$term == p, ]
      } else {
        # If the term does not exist in the robustness model, fill with NAs
        data.frame(term = p,
                   estimate  = NA_real_,
                   std.error = NA_real_,
                   statistic = NA_real_,
                   p.value   = NA_real_,
                   conf.low  = NA_real_,
                   conf.high = NA_real_)
      }
      
      record <- data.frame(
        paramname  = p,
        study      = rep_name,
        o_cmdline  = substring(o_cmdline, 1, 244),
        r_cmdline  = substring(r_cmdline, 1, 244),
        o_n        = o_n,
        r_n        = r_n,
        o_coeff    = round(o_row$estimate,   3),
        o_std_err  = round(o_row$std.error,  3),
        o_t        = round(o_row$statistic,  3),
        o_p_val    = round(o_row$p.value,    3),
        o_ci_lower = round(o_row$conf.low,   3),
        o_ci_upper = round(o_row$conf.high,  3),
        r_coeff    = round(r_row$estimate,   3),
        r_std_err  = round(r_row$std.error,  3),
        r_t        = round(r_row$statistic,  3),
        r_p_val    = round(r_row$p.value,    3),
        r_ci_lower = round(r_row$conf.low,   3),
        r_ci_upper = round(r_row$conf.high,  3),
        stringsAsFactors = FALSE
      )
      
      results_list[[length(results_list) + 1]] <- record
    }
  }
  
  results_df <- do.call(rbind, results_list)
  
  ## ── Export or return ─────────────────────────────────────────────────────
  if (!is.null(out)) {
    if (append && file.exists(out)) {
      oldres   <- openxlsx::read.xlsx(out)
      combined <- rbind(oldres, results_df)
      openxlsx::write.xlsx(combined, file = out, asTable = FALSE)
      message("Appended results to Excel file: ", out)
    } else {
      openxlsx::write.xlsx(results_df, file = out, asTable = FALSE)
      if (append) {
        message("File did not exist, so created a new Excel file: ", out)
      } else {
        message("Exported results to Excel file: ", out)
      }
    }
  } else {
    message("Data with original & robustness comparisons returned as a data frame.")
  }
  
  invisible(results_df)
}