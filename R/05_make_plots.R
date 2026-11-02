# ==============================================================================
# Produces all figures for the manuscript:
#   Figure 2  - Behavioral metrics (three panels)
#                 A: first arm choice (binary)
#                 B: proportion of time spent in the sodium arm
#                 C: number of visits to each arm
#   Figure S1 - Collection locations of honey bees (satellite map)
#   Figure S2 - DHARMa residual checks for the three selected models
#   Figure S3 - Sodium level effect on the three metrics
#
# Requires 01_clean_data.R and 02_fit_models.R to have been run.
#
# Each figure is written to plots/ twice:
#   .pdf - vector, fonts embedded, text editable
#   .png - 600 dpi at final print size
#
# Requires the Arial font to be installed on this machine.
# ==============================================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(patchwork)
library(DHARMa)
library(sf)
library(ggspatial)
library(prettymapr)


# ==============================================================================
# FIGURE STYLE
# ==============================================================================

font_family <- "Arial"
if (!font_family %in% systemfonts::system_fonts()$family) {
  stop(
    "The font '", font_family, "' is not installed on this machine. ",
    "Install it, then re-run this script."
  )
}

base_size <- 8 # tick labels, legend text
title_size <- base_size + 1 # axis titles, row/column headers
tag_size <- 12 # panel tags

tag_case <- "upper"
tag_levels <- if (tag_case == "upper") "A" else "a"
tag_label <- function(i) if (tag_case == "upper") LETTERS[i] else letters[i]

fig2_size <- c(width = 174, height = 70)
fig_s1_size <- c(width = 84, height = 84)
fig_s2_size <- c(width = 174, height = 190)
fig_s3_size <- c(width = 174, height = 70)
png_dpi <- 600

arm_colors <- c(ctrl = "#0072B2", trt = "#E69F00")
arm_shapes <- c(ctrl = 16, trt = 17)
arm_labels <- c(ctrl = "Control", trt = "Sodium")
signal_color <- "#D55E00"

pt <- function(points) points / (ggplot2::.pt * 72.27 / 96)
axis_lw <- pt(0.5)

seed <- 20261019

theme_manuscript <- function() {
  theme_classic(base_size = base_size, base_family = font_family) +
    theme(
      text = element_text(color = "black"),
      axis.text = element_text(size = base_size, color = "black"),
      axis.title = element_text(size = title_size, color = "black"),
      axis.line = element_line(linewidth = axis_lw, color = "black"),
      axis.ticks = element_line(linewidth = axis_lw, color = "black"),
      axis.ticks.length = unit(1.5, "pt"),
      legend.position = "none",
      plot.title = element_text(size = title_size, face = "bold", hjust = 0),
      plot.tag = element_text(
        size = tag_size, face = "bold",
        family = font_family
      ),
      plot.tag.location = "margin",
      plot.tag.position = "topleft",
      plot.background = element_rect(fill = "white", color = NA),
      plot.margin = margin(4, 4, 4, 4)
    )
}

save_figure <- function(plot, name, size) {
  ggsave(here::here("plots", paste0(name, ".pdf")), plot,
    width = size[["width"]], height = size[["height"]], units = "mm",
    device = cairo_pdf, bg = "white"
  )
  ggsave(here::here("plots", paste0(name, ".png")), plot,
    width = size[["width"]], height = size[["height"]], units = "mm",
    dpi = png_dpi, device = ragg::agg_png, bg = "white"
  )
}


# ==============================================================================
# Figure 2: Behavioral metrics
# ==============================================================================

trial_data <- readRDS(here::here("data", "processed", "trial_data_clean.rds"))

# one jittered column of a 0-1 response with its mean and bootstrapped 95% CI
# `points` is the geom_point() layer, so each panel can style its own points
single_column_plot <- function(data, response, points, y_label,
                               x_limits = c(0.55, 1.45)) {
  set.seed(seed)
  data$x <- 1 + runif(nrow(data), -0.3, 0.3) # computes horizontal jitter in advance

  # equivalent to stat_summary(fun.data = "mean_cl_boot") but
  # computed in advance
  set.seed(seed)
  ci <- Hmisc::smean.cl.boot(data[[response]])
  summary_data <- data.frame(
    x = 1,
    mean = ci[["Mean"]],
    lower = ci[["Lower"]],
    upper = ci[["Upper"]]
  )

  ggplot(data, aes(x = x, y = .data[[response]])) +
    geom_hline(
      yintercept = 0.5, linetype = "dashed",
      linewidth = pt(0.5), color = "gray40"
    ) +
    points +
    geom_pointrange(
      data = summary_data,
      aes(x = x, y = mean, ymin = lower, ymax = upper),
      inherit.aes = FALSE,
      color = "black",
      size = 0.35,
      linewidth = pt(1.2)
    ) +
    scale_x_continuous(limits = x_limits, breaks = NULL) +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
    labs(x = NULL, y = y_label) +
    theme_manuscript() +
    theme(axis.line.x = element_line(linewidth = axis_lw))
}

choice_data <- trial_data |>
  mutate(
    choice = factor(if_else(chose_trt == 1, "trt", "ctrl"),
      levels = c("ctrl", "trt")
    )
  )

# labels sit to the right of the jittered points, which span x = 0.7-1.3
choice_label_x <- 1.34

choice_plot <- single_column_plot(
  choice_data, "chose_trt",
  geom_point(
    aes(color = choice, shape = choice),
    alpha = 0.4,
    size = 1.1,
    stroke = 0
  ),
  "Probability of choosing\nsodium first",
  x_limits = c(0.55, 1.7)
) +
  annotate("text",
    x = choice_label_x, y = c(1, 0),
    label = arm_labels[c("trt", "ctrl")],
    color = arm_colors[c("trt", "ctrl")],
    hjust = 0,
    size = base_size / ggplot2::.pt, family = font_family
  ) +
  scale_color_manual(values = arm_colors) +
  scale_shape_manual(values = arm_shapes)


arm_levels <- c("ctrl", "trt")

plot_data <- trial_data |>
  select(trial_ID, trt_visits, ctrl_visits) |>
  pivot_longer(
    cols = -trial_ID,
    names_to = c("arm", "metric"),
    names_pattern = "^(trt|ctrl)_(.*)$",
    values_to = "value"
  ) |>
  mutate(
    arm = factor(arm, levels = arm_levels),
    x_box = as.numeric(arm),
    x_point = x_box + runif(n(), -0.07, 0.07)
  )

paired_plot <- function(data, y_label) {
  ggplot(data, aes(y = value)) +
    geom_line(
      aes(x = x_point, group = trial_ID),
      color = "gray55",
      alpha = 0.35,
      linewidth = pt(0.4)
    ) +
    geom_boxplot(
      aes(x = x_box, group = arm, color = arm, fill = arm),
      alpha = 0.25,
      width = 0.6,
      linewidth = pt(0.7),
      outlier.shape = NA
    ) +
    geom_point(
      aes(x = x_point, color = arm, shape = arm),
      alpha = 0.7,
      size = 1,
      stroke = 0
    ) +
    scale_color_manual(values = arm_colors) +
    scale_fill_manual(values = arm_colors) +
    scale_shape_manual(values = arm_shapes) +
    scale_x_continuous(
      breaks = seq_along(arm_levels),
      labels = arm_labels[arm_levels],
      limits = c(0.5, length(arm_levels) + 0.5),
      expand = c(0, 0)
    ) +
    labs(x = NULL, y = y_label) +
    theme_manuscript()
}

visit_plot <- paired_plot(
  filter(plot_data, metric == "visits"),
  "Number of visits"
)

time_plot <- single_column_plot(
  trial_data, "prop_trt_time_secs",
  geom_point(color = "gray55", alpha = 0.4, size = 1.1, stroke = 0),
  "Proportion of time\nin sodium arm"
)

figure_2 <- choice_plot + time_plot + visit_plot +
  plot_layout(ncol = 3, widths = c(1.3, 1, 1.2)) +
  plot_annotation(tag_levels = tag_levels)

save_figure(figure_2, "Figure2_Behavioral_Metrics", fig2_size)


# ==============================================================================
# Figure S2: DHARMa residual checks
# Redrawn in ggplot2 from DHARMa output so it matches the other figures.
# Mirrors DHARMa's plotQQunif() and plotResiduals()
# ==============================================================================

model_results <- readRDS(here::here("results", "model_results.rds"))

set.seed(seed)
sim_choice <- simulateResiduals(model_results$choice$best)
sim_time <- simulateResiduals(model_results$time$best)
sim_visits <- simulateResiduals(model_results$visits$best)

residual_quantiles <- c(0.25, 0.5, 0.75)

qq_panel <- function(sim) {
  res <- sort(sim$scaledResiduals)
  qq_data <- data.frame(expected = ppoints(length(res)), observed = res)

  ggplot(qq_data, aes(x = expected, y = observed)) +
    geom_abline(
      slope = 1, intercept = 0,
      linewidth = pt(0.6), color = "gray50"
    ) +
    geom_point(shape = 1, size = 0.9, stroke = pt(0.5), color = "black") +
    scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
    coord_fixed() +
    labs(x = "Expected", y = "Observed") +
    theme_manuscript()
}

# same as DHARMa's internal rankTransform() (DHARMa 0.5.0), copied here so
# the script doesn't depend on a non-exported function
rank_transform <- function(x) {
  r <- rank(x, ties.method = "average")
  r / max(r)
}

residual_panel <- function(sim) {
  res <- sim$scaledResiduals
  pred <- rank_transform(sim$fittedPredictedResponse)

  # this is the same rule DHARMa uses to decide
  # between a box plot and a scatter plot
  n_unique <- length(unique(pred))
  as_factor <- n_unique == 1 || (n_unique < 10 && length(pred) / n_unique > 10)

  x_title <- "Model predictions (rank transformed)"
  reference_lines <- geom_hline(
    yintercept = residual_quantiles,
    linetype = "dashed", linewidth = pt(0.5),
    color = "gray40"
  )

  if (as_factor) {
    group <- factor(round(pred, 2))
    # Within-group uniformity test, as in DHARMa::testCategorical()
    p_values <- tapply(res, group, function(r) {
      suppressWarnings(ks.test(r, "punif")$p.value)
    })
    flagged <- p.adjust(p_values) < 0.05
    box_data <- data.frame(group = group, res = res)
    box_fill <- setNames(
      ifelse(flagged, signal_color, "gray85"),
      levels(group)
    )

    p <- ggplot(box_data, aes(x = group, y = res, fill = group)) +
      reference_lines +
      geom_boxplot(
        width = 0.5, linewidth = pt(0.6), color = "black",
        outlier.shape = NA
      ) +
      scale_fill_manual(values = box_fill)

    if (nlevels(group) == 1) {
      p <- p + theme_manuscript() +
        theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
    } else {
      p <- p + theme_manuscript()
    }
  } else {
    test <- testQuantiles(res, pred,
      quantiles = residual_quantiles,
      plot = FALSE
    )
    fits <- test$predictions
    curves <- do.call(rbind, lapply(seq_along(residual_quantiles), function(i) {
      data.frame(
        pred = fits$pred,
        fit = fits[[2 * i]],
        se = fits[[2 * i + 1]],
        quantile = residual_quantiles[i],
        flagged = test$pvals[i] < 0.05
      )
    }))

    p <- ggplot(data.frame(pred = pred, res = res), aes(x = pred, y = res)) +
      reference_lines +
      geom_ribbon(
        data = curves,
        aes(
          x = pred, ymin = fit - se, ymax = fit + se,
          group = quantile, fill = flagged
        ),
        inherit.aes = FALSE, alpha = 0.2
      ) +
      geom_point(shape = 1, size = 0.9, stroke = pt(0.5), color = "black") +
      geom_line(
        data = curves,
        aes(x = pred, y = fit, group = quantile, color = flagged),
        linewidth = pt(1)
      ) +
      scale_color_manual(values = c("FALSE" = "black", "TRUE" = signal_color)) +
      scale_fill_manual(values = c("FALSE" = "gray50", "TRUE" = signal_color)) +
      scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
      theme_manuscript()
  }

  # clip conf bands that run out of bounds
  p +
    scale_y_continuous(breaks = seq(0, 1, 0.25)) +
    coord_cartesian(ylim = c(0, 1)) +
    labs(x = x_title, y = "Scaled residuals")
}

text_panel <- function(label, size = title_size, face = "bold", hjust = 0.5,
                       tag = NULL) {
  ggplot() +
    annotate("text",
      x = hjust, y = 0.5, label = label, hjust = hjust,
      size = size / ggplot2::.pt, fontface = face,
      family = font_family
    ) +
    scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
    labs(tag = tag) +
    theme_void(base_family = font_family) +
    theme(
      plot.tag = element_text(
        size = tag_size, face = "bold",
        family = font_family
      ),
      plot.tag.location = "margin",
      plot.tag.position = "left"
    )
}

s2_rows <- list(
  list(title = "First choice", sim = sim_choice),
  list(title = "Proportion of time", sim = sim_time),
  list(title = "Number of visits", sim = sim_visits)
)

s2_panels <- list(
  text_panel("Q-Q plot"),
  text_panel("Residuals vs predicted")
)
for (i in seq_along(s2_rows)) {
  s2_panels <- c(s2_panels, list(
    text_panel(s2_rows[[i]]$title, hjust = 0, tag = tag_label(i)),
    qq_panel(s2_rows[[i]]$sim),
    residual_panel(s2_rows[[i]]$sim)
  ))
}

s2_design <- "
AB
CC
DE
FF
GH
II
JK
"

figure_s2 <- wrap_plots(s2_panels, design = s2_design) +
  plot_layout(heights = c(0.08, 0.1, 1, 0.1, 1, 0.1, 1))

save_figure(figure_s2, "FigureS2_DHARMa_Checks", fig_s2_size)


# ==============================================================================
# Figure S3: Sodium level effect
# Raw per-trial responses with population-level predictions
# from the salt model for each response
# ==============================================================================

sodium_levels <- c("high", "low") # high is the reference level
sodium_labels <- c(high = "High", low = "Low")

predict_by_sodium <- function(model) {
  newdata <- data.frame(
    sodium_level = factor(sodium_levels, levels = levels(trial_data$sodium_level)),
    start_date = NA
  )
  pred <- predict(model, newdata, type = "link", se.fit = TRUE, re.form = NA)
  # all three families use a logit link
  data.frame(
    x = seq_along(sodium_levels),
    est = plogis(pred$fit),
    lower = plogis(pred$fit - qnorm(0.975) * pred$se.fit),
    upper = plogis(pred$fit + qnorm(0.975) * pred$se.fit)
  )
}

sodium_p_value <- function(model) {
  coefs <- summary(model)$coefficients$cond
  coefs[grep("sodium", rownames(coefs), ignore.case = TRUE), "Pr(>|z|)"]
}

set.seed(seed)
sodium_data <- trial_data |>
  mutate(
    prop_trt_visits = if_else(
      trt_visits + ctrl_visits > 0,
      trt_visits / (trt_visits + ctrl_visits),
      NA_real_
    ),
    x = match(sodium_level, sodium_levels) + runif(n(), -0.25, 0.25)
  )

sodium_panel <- function(response, model, y_label) {
  raw <- filter(sodium_data, !is.na(.data[[response]]))
  pred <- predict_by_sodium(model)

  ggplot(raw, aes(x = x, y = .data[[response]])) +
    geom_hline(
      yintercept = 0.5, linetype = "dashed",
      linewidth = pt(0.5), color = "gray40"
    ) +
    geom_point(
      color = "gray55",
      alpha = 0.4,
      size = 1.1,
      stroke = 0
    ) +
    geom_pointrange(
      data = pred,
      aes(x = x, y = est, ymin = lower, ymax = upper),
      inherit.aes = FALSE,
      color = "black",
      size = 0.35,
      linewidth = pt(1.2)
    ) +
    annotate("text",
      x = mean(seq_along(sodium_levels)), y = 1.1,
      label = sprintf("p = %.2f", sodium_p_value(model)),
      size = base_size / ggplot2::.pt, family = font_family
    ) +
    scale_x_continuous(
      breaks = seq_along(sodium_levels),
      labels = sodium_labels[sodium_levels],
      limits = c(0.5, length(sodium_levels) + 0.5),
      expand = c(0, 0)
    ) +
    scale_y_continuous(breaks = seq(0, 1, 0.25)) +
    # p-value sits above the panel, so let it draw outside the y range
    coord_cartesian(ylim = c(0, 1), clip = "off") +
    labs(x = "Sodium level", y = y_label) +
    theme_manuscript() +
    theme(plot.margin = margin(12, 4, 4, 4))
}

figure_s3 <- sodium_panel(
  "chose_trt", model_results$choice$salt,
  "Probability of choosing\nsodium first"
) +
  sodium_panel(
    "prop_trt_time_secs", model_results$time$salt,
    "Proportion of time\nin sodium arm"
  ) +
  sodium_panel(
    "prop_trt_visits", model_results$visits$salt,
    "Proportion of visits\nto sodium arm"
  ) +
  plot_layout(ncol = 3) +
  plot_annotation(tag_levels = tag_levels)

save_figure(figure_s3, "FigureS3_Sodium_Level", fig_s3_size)


# ==============================================================================
# Figure S1: Collection locations
# ==============================================================================

rosm::register_tile_source(
  esri_imagery = rosm::as.tile_source(
    "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/${z}/${y}/${x}", # nolint: line_length_linter.
    extension = "jpeg",
    max_zoom = 19
  )
)

# locations are stored as "latitude, longitude" in the location column.
collection_sites <- trial_data |>
  filter(!is.na(location)) |>
  distinct(location) |>
  separate(
    location,
    into = c("latitude", "longitude"),
    sep = ",",
    convert = TRUE
  ) |>
  mutate(
    latitude = as.numeric(trimws(latitude)),
    longitude = as.numeric(trimws(longitude))
  ) |>
  filter(
    !is.na(latitude),
    !is.na(longitude)
  )

# convert collection locations to a spatial object.
collection_sf <- st_as_sf(
  collection_sites,
  coords = c("longitude", "latitude"),
  crs = 4326
)

hive_sf <- st_as_sf(
  read.csv(here::here("data", "hive_location.csv")),
  coords = c("longitude", "latitude"),
  crs = 4326
)

# combine the two point sets with a category column so a single legend
# is drawn for both the collection sites and the known hive location.
collection_sf$kind <- "Collection site"
hive_sf$kind <- "Known hive location"
map_points <- rbind(collection_sf, hive_sf)
map_points$kind <- factor(
  map_points$kind,
  levels = c("Collection site", "Known hive location")
)

# sizing stuff for padding and overall shape
bbox <- st_bbox(map_points)
lat_center <- mean(c(bbox[["ymin"]], bbox[["ymax"]]))
y_pad <- (bbox[["ymax"]] - bbox[["ymin"]]) * 0.06
y_lim <- c(bbox[["ymin"]] - y_pad, bbox[["ymax"]] + y_pad)
x_center <- mean(c(bbox[["xmin"]], bbox[["xmax"]]))
x_span <- (y_lim[2] - y_lim[1]) / cos(lat_center * pi / 180)
x_lim <- c(x_center - x_span / 2, x_center + x_span / 2)

view_corners <- st_transform(
  st_sfc(
    st_point(c(x_lim[1], y_lim[1])),
    st_point(c(x_lim[2], y_lim[2])),
    crs = 4326
  ),
  3857
)
view_coords <- st_coordinates(view_corners)
x_lim_m <- view_coords[, 1]
y_lim_m <- view_coords[, 2]

map_shapes <- c("Collection site" = 21, "Known hive location" = 23)
map_fills <- c("Collection site" = "white", "Known hive location" = "#F0E442")
map_sizes <- c("Collection site" = 1.6, "Known hive location" = 2.4)
map_text_cex <- base_size / 12 # ggspatial text is scaled from 12 pt

fig_s1 <- ggplot() +
  annotation_map_tile(
    type = "esri_imagery",
    zoomin = 0,
    progress = "none"
  ) +
  geom_sf(
    data = map_points,
    mapping = aes(shape = kind, fill = kind, size = kind),
    stroke = pt(0.6),
    color = "black"
  ) +
  scale_shape_manual(values = map_shapes) +
  scale_fill_manual(values = map_fills) +
  scale_size_manual(values = map_sizes) +
  annotation_scale(
    location = "bl",
    width_hint = 0.25,
    unit_category = "metric",
    height = unit(1.2, "mm"),
    line_width = pt(0.5),
    text_cex = map_text_cex,
    text_family = font_family,
    text_col = "white",
    line_col = "white",
    pad_x = unit(2, "mm"),
    pad_y = unit(2, "mm")
  ) +
  annotation_north_arrow(
    location = "tl",
    which_north = "true",
    height = unit(6, "mm"),
    width = unit(6, "mm"),
    pad_x = unit(1.5, "mm"),
    pad_y = unit(1.5, "mm"),
    style = north_arrow_minimal(
      text_size = base_size,
      text_family = font_family,
      text_col = "white",
      line_col = "white",
      line_width = 1
    )
  ) +
  coord_sf(
    xlim = x_lim_m,
    ylim = y_lim_m,
    expand = FALSE
  ) +
  guides(
    shape = guide_legend(override.aes = list(size = unname(map_sizes))),
    size = "none"
  ) +
  labs(
    x = NULL,
    y = NULL,
    shape = NULL,
    fill = NULL,
    caption = paste0(
      "Imagery \u00a9 Esri, Maxar, Earthstar Geographics,\n",
      "and the GIS User Community"
    )
  ) +
  theme_void(base_size = base_size, base_family = font_family) +
  theme(
    legend.position = "inside",
    # top right was chosen bc its the only corner with no sites underneath
    legend.position.inside = c(0.98, 0.98),
    legend.justification = c(1, 1),
    legend.title = element_blank(),
    legend.text = element_text(size = base_size, color = "black"),
    legend.background = element_rect(fill = alpha("white", 0.8), color = NA),
    legend.margin = margin(2, 4, 2, 2),
    legend.key = element_blank(),
    legend.key.size = unit(3.5, "mm"),
    legend.key.spacing.y = unit(0.5, "pt"),
    plot.caption = element_text(
      size = 6,
      color = "gray30",
      hjust = 1,
      margin = margin(t = 2)
    ),
    plot.background = element_rect(fill = "white", color = NA),
    plot.margin = margin(2, 2, 2, 2)
  )

save_figure(fig_s1, "FigureS1_Collection_Locations", fig_s1_size)
