# ==============================================================================
# Reads the raw trial, collection, and batch CSVs from data/, joins them, and
# creates the variables used downstream by the models and plots.
# Outputs data/processed/trial_data_clean.{rds,csv}
# ==============================================================================

library(lubridate)
library(dplyr)

trial_data <- read.csv(here::here("data", "full_trial_data.csv"))
collection_data <- read.csv(here::here("data", "full_collection_data.csv"))
batch_data <- read.csv(here::here("data", "full_batch_data.csv"))

trial_data <- filter(trial_data, !is_excluded)
n_trials <- nrow(trial_data)

# checks on the raw data so data entry problems stop the pipeline here
# instead of silently changing the joins or models below
trial_cage_batch <- paste(
  trial_data$cage_id,
  sub("^([0-9]+).*", "\\1", trial_data$batch_id)
)
collection_cage_batch <- paste(collection_data$cage_id, collection_data$parent_batch_id)
stopifnot(
  "trt_arm must be L or R" = all(trial_data$trt_arm %in% c("L", "R")),
  "first_choice must be L or R" = all(trial_data$first_choice %in% c("L", "R")),
  "sodium_level must be low or high" = all(trial_data$sodium_level %in% c("low", "high")),
  "every trial batch_id must be in full_batch_data.csv" =
    all(trial_data$batch_id %in% batch_data$batch_id),
  "every trial (cage_id, parent batch) must be in full_collection_data.csv" =
    all(trial_cage_batch %in% collection_cage_batch)
)

# helper function used in the following mutates
# times were recorded in local time at KBS (Michigan), so the time zone is set
# explicitly to keep results from depending on the machine's time zone
parse_datetime <- function(date, time) {
  as.POSIXct(paste(date, time), format = "%m/%d/%Y %I:%M:%S %p", tz = "America/Detroit")
}

trial_data <- trial_data |>
  mutate(
    across(c(species, cage_id, batch_id, trt_arm, first_choice, sodium_level), as.factor),
    starving_start = parse_datetime(start_date, starving_since),
    trial_start = parse_datetime(start_date, start_time),

    # the random intercept in every model. keep its levels as they are (see the csv write below)
    start_date = as.factor(start_date),
    across(c(latency, left_time, right_time), \(x) period_to_seconds(ms(x))),
    starvation_duration_mins = as.numeric(difftime(trial_start,
      starving_start,
      units = "mins"
    )),
    chose_trt = as.numeric(as.character(first_choice) == as.character(trt_arm)),

    # replace L/R columns with trt/ctrl
    trt_visits = ifelse(trt_arm == "L", left_visits, right_visits),
    ctrl_visits = ifelse(trt_arm == "R", left_visits, right_visits),
    trt_time_secs = ifelse(trt_arm == "L", left_time, right_time),
    ctrl_time_secs = ifelse(trt_arm == "R", left_time, right_time),

    # batch num needs to be gotten from batch_id. e.g. "4a" -> "4"
    parent_batch_id = sub("^([0-9]+).*", "\\1", as.character(batch_id)),

    # text copies of the factors used for the joins and dropped after
    cage_id_char = as.character(cage_id),
    batch_id_char = as.character(batch_id)
  ) |>
  left_join(
    collection_data |>
      mutate(
        cage_id_char = as.character(cage_id),
        parent_batch_id = as.character(parent_batch_id)
      ) |>
      select(location, flower, cage_id_char, parent_batch_id),
    by = c("cage_id_char", "parent_batch_id")
  ) |>
  left_join(
    batch_data |>
      mutate(
        batch_id_char = as.character(batch_id),
        sodium_add_datetime = parse_datetime(sodium_add_date, sodium_add_time)
      ) |>
      select(batch_id_char, sodium_add_datetime),
    by = "batch_id_char"
  ) |>
  mutate(
    # whole numbers now that the joins are done (cage_id is a factor, so go through text)
    cage_id = as.integer(as.character(cage_id)),
    parent_batch_id = as.integer(parent_batch_id),
    starvation_duration_mins_z = as.numeric(scale(starvation_duration_mins)),
    prop_trt_time_secs = trt_time_secs / (trt_time_secs + ctrl_time_secs)
  ) |>
  arrange(trial_start) |>
  tibble::rowid_to_column("trial_ID") |>
  select(
    -is_excluded,
    -cage_id_char,
    -batch_id_char,
    -starving_since,
    -start_time,
    -left_visits,
    -right_visits,
    -left_time,
    -right_time
  )

# checks on the cleaned data
modeled_columns <- c(
  "chose_trt", "prop_trt_time_secs", "trt_visits", "ctrl_visits",
  "starvation_duration_mins_z", "trt_arm", "sodium_level", "start_date"
)
stopifnot(
  "joins must not add or drop trials" = nrow(trial_data) == n_trials,
  "modeled columns must not contain NA" = !anyNA(trial_data[modeled_columns]),
  "prop_trt_time_secs must be between 0 and 1" =
    all(trial_data$prop_trt_time_secs >= 0 & trial_data$prop_trt_time_secs <= 1)
)

dir.create(here::here("data", "processed"), showWarnings = FALSE, recursive = TRUE)
saveRDS(trial_data, here::here("data", "processed", "trial_data_clean.rds"))

# start_date is written as YYYY-MM-DD in the csv only. the factor in the rds keeps
# its M/D/YYYY levels (and their order), since it's the random effect in every model
trial_data |>
  mutate(start_date = format(as.Date(as.character(start_date), format = "%m/%d/%Y"))) |>
  write.csv(here::here("data", "processed", "trial_data_clean.csv"), row.names = FALSE)

message("Data has been cleaned and written to data/processed/")
