# ==============================================================================
# Fits GLMMs for:
#   - first arm choice (binary)
#   - proportion of time in treatment arm
#   - visit count to treatment and control arms
# using the same set of candidate models for each response, then compares them
# by AICc. The candidate models were chosen by considering which combinations
# of predictors are biologically meaningful and feasible.
# Requires 01_clean_data.R to have been run.
# Outputs results/model_results.rds
# ==============================================================================

library(glmmTMB)
library(MuMIn)
library(dplyr)

trial_data <- readRDS(here::here("data", "processed", "trial_data_clean.rds"))

# Each response variable gets the same 8 candidate models (fixed effects below).
# Every model also has a random intercept for start_date.
candidate_fixed_effects <- c(
  null = "1",
  starv = "starvation_duration_mins_z",
  arm = "trt_arm",
  salt = "sodium_level",
  starv_arm = "starvation_duration_mins_z + trt_arm",
  starv_salt = "starvation_duration_mins_z + sodium_level",
  arm_salt = "trt_arm + sodium_level",
  full = "starvation_duration_mins_z + trt_arm + sodium_level"
)

# glmmTMB must be used for time preference, because glmer does not support
# beta_family, so it has been used for all the models over glmer for consistency
fit_candidates <- function(response_var, data, family) {
  create_formula <- function(fixed_effects) {
    as.formula(paste(response_var, "~", fixed_effects, "+ (1|start_date)"))
  }
  models <- lapply(candidate_fixed_effects, function(fixed_effects) {
    glmmTMB(
      formula = create_formula(fixed_effects),
      data = data,
      family = family,
      na.action = "na.fail"
    )
  })

  selection_table <- model.sel(models)

  # best model should be the one with the best AICc
  # OR the simplest model with a delta AIC <= 2 to the best model
  model_options <- filter(as.data.frame(selection_table), delta <= 2)
  # 'df' represents the parameter count. because the table is already sorted by
  # AICc, the first match picks the simplest model with the best AICc
  best_model_name <- rownames(model_options)[which.min(model_options$df)]

  # append selection table and best model
  c(
    models,
    list(
      selection_table = selection_table,
      best = models[[best_model_name]],
      best_model_name = best_model_name
    )
  )
}

choice_results <- fit_candidates("chose_trt", data = trial_data, family = binomial)
message(sprintf("Best model selected for chose_trt: %s", choice_results$best_model_name))

time_results <- fit_candidates("prop_trt_time_secs", data = trial_data, family = ordbeta())
message(sprintf("Best model selected for prop_trt_time_secs: %s", time_results$best_model_name))

visits_results <- fit_candidates(
  "cbind(trt_visits, ctrl_visits)",
  data = trial_data,
  family = binomial
)
message(sprintf(
  "Best model selected for cbind(trt_visits, ctrl_visits): %s",
  visits_results$best_model_name
))

dir.create(here::here("results"), showWarnings = FALSE)
saveRDS(
  list(choice = choice_results, time = time_results, visits = visits_results),
  here::here("results", "model_results.rds")
)

message("Model results saved and written to results/")
