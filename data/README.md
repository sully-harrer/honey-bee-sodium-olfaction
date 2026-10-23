# Data dictionary

All data were collected in June–July 2026 at the W.K. Kellogg Biological Station (Hickory Corners,
Michigan, USA). Subjects are western honey bees (*Apis mellifera*).

The raw files in this folder are the data as entered from the datasheets. The pipeline only reads them, it
never modifies them. `processed/trial_data_clean.csv` is written by `R/01_clean_data.R`.

| File | One row per | Rows |
|---|---|---|
| `full_trial_data.csv` | Y-maze trial (one bee) | 102 |
| `full_collection_data.csv` | Collection of bees into a cage | 28 |
| `full_batch_data.csv` | Batch of artificial nectar | 26 |
| `hive_location.csv` | Known hive location (Figure S1) | 1 |
| `processed/trial_data_clean.csv` | Included trial, with derived variables | 100 |

**Formats used in the raw files**

- Dates: `M/D/YYYY` (e.g. `6/24/2026`)
- Times of day: `H:MM:SS AM/PM` (e.g. `9:30:00 AM`), local time
- Durations: `M:SS` (minutes:seconds, e.g. `2:05`)
- Initials: 2–3 uppercase letters. Several people are listed in one cell separated by `, ` (e.g.
  `SCH, RMB, AGH`)
- Coordinates: decimal degrees, WGS 84
- Missing or blank values: empty cell

**How the files link**

- Each trial's `batch_id` matches a `batch_id` in `full_batch_data.csv`.
- Each trial's `cage_id` and parent batch number match a `cage_id` and `parent_batch_id` in
  `full_collection_data.csv`. The parent batch number is the number at the start of `batch_id` (for
  `4C` it is `4`).

`R/01_clean_data.R` stops with an error if any trial has no matching batch or collection.

## `full_trial_data.csv`

| Column | Datasheet name | Description | Type | Values / units |
|---|---|---|---|---|
| `start_date` | Date | Date the trial was run | date | `M/D/YYYY` |
| `cage_id` | Cage # | Cage the bee was taken from | integer | 1–4 |
| `species` | Species | Species of the test subject | text | `Apis mellifera` |
| `batch_id` | Batch ID | Nectar batch used for the trial | text | `<number><letter>`, e.g. `1A`; must be in `full_batch_data.csv` |
| `starving_since` | Starvation start time | Time the bee's starvation period began (same day as `start_date`) | time | `H:MM:SS AM/PM` |
| `temp` | Room temp | Room temperature during the trial | number | °C |
| `start_time` | Start time | Time the trial began | time | `H:MM:SS AM/PM` |
| `trt_arm` | Na Arm | Y-maze arm holding the sodium-enriched nectar | text | `L` or `R` |
| `first_choice` | First Choice | Y-maze arm the bee entered first | text | `L` or `R` |
| `latency` | Time to first choice | Time from the start of the trial to the bee first entering an arm | duration | `M:SS` |
| `left_visits` | L arm visits | Number of entries into the left arm during the trial | integer | greater than or equal to 0 |
| `right_visits` | R arm visits | Number of entries into the right arm during the trial | integer | greater than or equal to 0 |
| `left_time` | Time in L | Total time spent in the left arm during the trial | duration | `M:SS` |
| `right_time` | Time in R | Total time spent in the right arm during the trial | duration | `M:SS` |
| `is_excluded` | Excl? | Whether the trial is excluded from analysis (reason in `notes`) | logical | `TRUE` / `FALSE` |
| `sodium_level` | -- | Sodium concentration of the treatment nectar | text | `low` (35 mM Na⁺) or `high` (3500 mM Na⁺) |
| `notes` | Notes | Observations about the trial | text | free text |

## `full_collection_data.csv`

| Column | Datasheet name | Description | Type | Values / units |
|---|---|---|---|---|
| `date` | Date | Date of collection | date | `M/D/YYYY` |
| `time` | Collection start time | Time collection began | time | `H:MM:SS AM/PM` |
| `collectors` | Collector(s) | Initials of the people who collected the bees | text | initials, `, `-separated |
| `num_bees` | # bees | Number of bees collected | integer | > 0 |
| `species` | Species | Species collected | text | `Apis mellifera` |
| `location` | Location | Collection site | text | `"latitude, longitude"` in decimal degrees, e.g. `"42.4033115, -85.3841674"` |
| `flower` | Flower | Plant the bees were collected from | text | scientific name |
| `cage_id` | Cage num | Cage the bees were placed in | integer | 1–4 |
| `parent_batch_id` | Batch ID | Nectar batch the bees were fed while in the cage, before testing | integer | > 0; the number at the start of a `full_batch_data.csv` `batch_id` |
| `notes` | Notes | Observations about the collection | text | free text |

Cage numbers are reused, so a cage is identified by (`cage_id`, `parent_batch_id`).

## `full_batch_data.csv`

Each batch is 2:1 water:honey artificial nectar with NaCl added. Sub-batches made from the same parent
mix share the parent number (`4A`, `4B`, `4C`). The column and datasheet names say "sodium" or "Na", but
the amounts are mg of NaCl.

| Column | Datasheet name | Description | Type | Values / units |
|---|---|---|---|---|
| `batch_id` | ID | Batch identifier | text | `<number><letter>`, e.g. `1A` |
| `preparers` | Preparer | Initials of the people who prepared the batch | text | initials, `, `-separated |
| `honey_lot` | Honey lot | Bottle of honey used for the batch | text | `B`-`H` |
| `mix_date` | Mixing date | Date the water and honey were mixed | date | `M/D/YYYY` |
| `mix_time` | Mixing time | Time the water and honey were mixed | time | `H:MM:SS AM/PM` |
| `target_sodium` | Target Na | NaCl needed to bring the batch to its target concentration | number | mg; 306.81 (35 mM, `low`) or 30681 (3500 mM, `high`) |
| `actual_sodium` | Actual Na | NaCl actually added | number | mg; greater than or equal to 0 |
| `sodium_add_date` | Date Na added | Date NaCl was added | date | `M/D/YYYY`; on or after `mix_date` |
| `sodium_add_time` | Time Na added | Time NaCl was added | time | `H:MM:SS AM/PM` |
| `notes` | Notes | Observations about the batch | text | free text |

## `hive_location.csv`

| Column | Description | Type | Values / units |
|---|---|---|---|
| `latitude` | Latitude of the known honey bee hive near the collection sites | number | decimal degrees, WGS 84 |
| `longitude` | Longitude of the same hive | number | decimal degrees, WGS 84 |

Used only to mark the hive in Figure S1.

## `processed/trial_data_clean.csv`

Written by `R/01_clean_data.R`. Do not edit by hand. Excluded trials (`is_excluded == TRUE`) are removed,
and rows are sorted by trial start time. It keeps the trial columns above except `starving_since`,
`start_time`, `left_visits`, `right_visits`, `left_time` and `right_time`, which are replaced by the
columns below. `latency` is converted to seconds. Date-times are written as `YYYY-MM-DD HH:MM:SS`, local
time.

| Column | Description | Units |
|---|---|---|
| `trial_ID` | Trial number, in chronological order | 1–100 |
| `starving_start` | Date-time the starvation period began | date-time |
| `trial_start` | Date-time the trial began | date-time |
| `starvation_duration_mins` | `trial_start` − `starving_start` | minutes |
| `chose_trt` | Whether the first choice was the treatment arm (`first_choice == trt_arm`) | 1 / 0 |
| `trt_visits`, `ctrl_visits` | Visits to the treatment and control arms (from `left_visits`/`right_visits` via `trt_arm`) | count |
| `trt_time_secs`, `ctrl_time_secs` | Time in the treatment and control arms | seconds |
| `prop_trt_time_secs` | `trt_time_secs / (trt_time_secs + ctrl_time_secs)` | proportion, 0–1 |
| `parent_batch_id` | Number at the start of `batch_id` | integer |
| `cage_id_char`, `batch_id_char` | Text copies of `cage_id` and `batch_id`, used for the joins | -- |
| `location`, `flower` | From `full_collection_data.csv` | as above |
| `pct_sodium_error` | `(target_sodium − actual_sodium) / target_sodium` from the trial's batch; positive = less NaCl than targeted | proportion (not %) |
| `sodium_add_datetime` | Date-time NaCl was added to the trial's batch | date-time |
| `time_since_sodium_added` | `trial_start` − `sodium_add_datetime` | minutes |
| `time_of_day_hrs` | Trial start time as decimal hours | hours, e.g. 12.5 = 12:30 PM |
| `starvation_duration_mins_z`, `temp_z`, `pct_sodium_error_z`, `time_since_sodium_added_z`, `time_of_day_hrs_z` | z-scores (mean 0, SD 1) of the matching column, computed across the 100 included trials | SD units |
