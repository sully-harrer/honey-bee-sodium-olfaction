# ==============================================================================
# Summarizes the fitted candidate models and produces the numerical results
# used in the manuscript, including:
# - proportions for choice, time, and visits
# - AICc model-selection tables for each response variable
# - selected-model estimates and 95% confidence intervals
# Requires 01_clean_data.R and 02_fit_models.R to have been run.
# Uses data/processed/trial_data_clean.rds and results/model_results.rds.
# Writes results/model_selection.md and results/estimates.csv.
# ==============================================================================

library(dplyr)
library(tidyr)
library(tibble)
library(knitr)

# descriptive stats
trial_data <- readRDS(here::here("data", "processed", "trial_data_clean.rds"))
choice_prop <- mean(trial_data$chose_trt, na.rm = TRUE)
time_prop <- mean(trial_data$prop_trt_time_secs, na.rm = TRUE)
visits_prop <- sum(trial_data$trt_visits, na.rm = TRUE) / sum(
  trial_data$trt_visits + trial_data$ctrl_visits,
  na.rm = TRUE
)


# make model selection table
model_results <- readRDS(here::here("results", "model_results.rds"))

make_model_table <- function(results, response_name) {
  results$selection_table |>
    as.data.frame() |>
    rownames_to_column("Model name") |>
    select(
      `Model name`,
      delta,
      logLik,
      df
    ) |>
    # Best-supported model first
    arrange(delta) |>
    mutate(
      Response = response_name
    ) |>
    select(
      Response,
      `Model name`,
      delta,
      logLik,
      df
    )
}

results_table <- bind_rows(
  make_model_table(
    model_results$choice,
    "Choice"
  ),
  make_model_table(
    model_results$time,
    "Time"
  ),
  make_model_table(
    model_results$visits,
    "Visits"
  )
)

results_table <- results_table |>
  mutate(
    delta = round(delta, 2),
    logLik = round(logLik, 2)
  )

# Only show response name on first row of each section
results_table <- results_table |>
  group_by(Response) |>
  mutate(
    Response = if_else(
      row_number() == 1,
      Response,
      ""
    )
  ) |>
  ungroup()

results_table <- results_table |>
  rename(
    `ΔAICc` = delta,
    `Log likelihood` = logLik
  )
# Markdown + the GDocifyMd extension was the easiest way to get
# this formatted quickly in Google Docs (at least that i found)
markdown_table <- knitr::kable(
  results_table,
  format = "pipe",
  align = c("l", "l", "r", "r", "r")
)
writeLines(markdown_table, here::here("results", "model_selection.md"))

# selected model stats
get_intercept <- function(model) {
  coefs <- summary(model)$coefficients$cond["(Intercept)", ]
  ci <- plogis(confint(model, parm = "beta_", method = "wald"))
  data.frame(
    est   = plogis(coefs[["Estimate"]]),
    lower = ci[1, 1],
    upper = ci[1, 2],
    z     = coefs[["z value"]],
    p     = coefs[["Pr(>|z|)"]]
  )
}

choice_res <- get_intercept(model_results$choice$best)
time_res <- get_intercept(model_results$time$best)
visits_res <- get_intercept(model_results$visits$best)

# for second paragraph stats about sodium level's impact
get_sodium <- function(model) {
  coefs <- summary(model)$coefficients$cond
  row <- grep("sodium", rownames(coefs), ignore.case = TRUE)
  ci <- confint(model, parm = rownames(coefs)[row], method = "wald")
  data.frame(
    est   = coefs[row, "Estimate"],
    lower = ci[1, 1],
    upper = ci[1, 2],
    z     = coefs[row, "z value"],
    p     = coefs[row, "Pr(>|z|)"]
  )
}

choice_sodium <- get_sodium(model_results$choice$salt)
time_sodium <- get_sodium(model_results$time$salt)
visits_sodium <- get_sodium(model_results$visits$salt)

# print results
report_result <- function(label, res, stat = "estimate") {
  f <- function(x) sprintf("%.2f", x)
  message(
    label, ": ", stat, " = ", f(res$est),
    ", 95% CI [", f(res$lower), ", ", f(res$upper), "]",
    ", z = ", f(res$z),
    ", p = ", f(res$p)
  )
}

message("Choice proportion: ", round(choice_prop, 2))
message("Time proportion: ", round(time_prop, 2))
message("Visits proportion: ", round(visits_prop, 2))
message("\nBest model estimates:")
report_result("Choice", choice_res)
report_result("Time", time_res)
report_result("Visits", visits_res)
message("\nSodium estimates:")
report_result("Choice", choice_sodium, stat = "beta")
report_result("Time", time_sodium, stat = "beta")
report_result("Visits", visits_sodium, stat = "beta")

# save everything above in one table
estimates <- bind_rows(
  data.frame(
    analysis = "proportion",
    response = c("choice", "time", "visits"),
    model = NA,
    term = NA,
    scale = "proportion",
    est = c(choice_prop, time_prop, visits_prop),
    lower = NA, upper = NA, z = NA, p = NA
  ),
  data.frame(
    analysis = "preference",
    response = c("choice", "time", "visits"),
    model = c(
      model_results$choice$best_model_name,
      model_results$time$best_model_name,
      model_results$visits$best_model_name
    ),
    term = "(Intercept)",
    scale = "probability",
    bind_rows(choice_res, time_res, visits_res)
  ),
  data.frame(
    analysis = "sodium",
    response = c("choice", "time", "visits"),
    model = "salt",
    term = "sodium_levellow",
    scale = "log-odds",
    bind_rows(choice_sodium, time_sodium, visits_sodium)
  )
) |>
  mutate(across(c(est, lower, upper, z, p), \(x) signif(x, 6)))

write.csv(
  estimates,
  here::here("results", "estimates.csv"),
  row.names = FALSE, na = ""
)
