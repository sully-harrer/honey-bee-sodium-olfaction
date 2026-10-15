# ==============================================================================
# Produces Figure S1 showing collection locations of honey bees.
#
# Requires 01_clean_data.R to have been run.
# Uses data/processed/trial_data_clean.rds.
#
# Outputs plots/FigureS1_Collection_Locations.png
# ==============================================================================

library(dplyr)
library(tidyr)
library(sf)
library(ggplot2)
library(ggspatial)

# Register Esri World Imagery satellite basemap as a tile source for ggspatial.
# Esri World Imagery is free to reuse with attribution (see caption below).
rosm::register_tile_source(
  esri_imagery = rosm::as.tile_source(
    "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/${z}/${y}/${x}",
    extension = "jpeg",
    max_zoom = 19
  )
)

trial_data <- readRDS(
  here::here("data", "processed", "trial_data_clean.rds")
)

# Locations are stored as "latitude, longitude" in the location column.
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

# Convert collection locations to a spatial object.
collection_sf <- st_as_sf(
  collection_sites,
  coords = c("longitude", "latitude"),
  crs = 4326
)

# Known hive location (hardcoded).
hive_sf <- st_as_sf(
  data.frame(longitude = -85.389338, latitude = 42.397748),
  coords = c("longitude", "latitude"),
  crs = 4326
)

# Combine the two point sets with a category column so a single legend (key)
# is drawn distinguishing collection sites from the known hive location.
collection_sf$kind <- "Collection site"
hive_sf$kind <- "Known hive location"
map_points <- rbind(collection_sf, hive_sf)
map_points$kind <- factor(
  map_points$kind,
  levels = c("Collection site", "Known hive location")
)

# Widen the view beyond the data so there is empty map padding on the sides,
# making the figure roughly square rather than tall. The x-range is stretched
# to match the ground height of the y-range at this latitude.
bbox <- st_bbox(map_points)
lat_center <- mean(c(bbox[["ymin"]], bbox[["ymax"]]))
y_pad <- (bbox[["ymax"]] - bbox[["ymin"]]) * 0.06
y_lim <- c(bbox[["ymin"]] - y_pad, bbox[["ymax"]] + y_pad)
x_center <- mean(c(bbox[["xmin"]], bbox[["xmax"]]))
x_span <- (y_lim[2] - y_lim[1]) / cos(lat_center * pi / 180)
x_lim <- c(x_center - x_span / 2, x_center + x_span / 2)

# Express the view limits in the tile CRS (Web Mercator) so the basemap tiles
# are fetched for the padded extent.
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

fig_s1 <- ggplot() +
  annotation_map_tile(
    type = "esri_imagery",
    zoomin = 0,
    progress = "none"
  ) +
  geom_sf(
    data = map_points,
    mapping = aes(shape = kind, fill = kind, size = kind),
    stroke = 0.8,
    color = "white"
  ) +
  scale_shape_manual(
    values = c("Collection site" = 21, "Known hive location" = 23)
  ) +
  scale_fill_manual(
    values = c("Collection site" = "black", "Known hive location" = "gold")
  ) +
  scale_size_manual(
    values = c("Collection site" = 3.2, "Known hive location" = 4.4)
  ) +
  annotation_scale(
    location = "bl",
    width_hint = 0.25,
    unit_category = "metric",
    text_cex = 0.7,
    text_col = "white",
    line_col = "white",
    pad_x = unit(0.3, "cm"),
    pad_y = unit(0.3, "cm")
  ) +
  annotation_north_arrow(
    location = "tr",
    which_north = "true",
    height = unit(1, "cm"),
    width = unit(1, "cm"),
    pad_x = unit(0.3, "cm"),
    pad_y = unit(0.3, "cm"),
    style = north_arrow_minimal(
      text_size = 9,
      text_col = "white",
      line_col = "white"
    )
  ) +
  coord_sf(
    xlim = x_lim_m,
    ylim = y_lim_m,
    expand = FALSE
  ) +
  guides(
    shape = guide_legend(override.aes = list(stroke = 0.8)),
    size = "none"
  ) +
  labs(
    x = NULL,
    y = NULL,
    shape = NULL,
    fill = NULL,
    caption = "Imagery \u00a9 Esri, Maxar, Earthstar Geographics"
  ) +
  theme_void() +
  theme(
    legend.position = "inside",
    legend.position.inside = c(0.015, 0.985),
    legend.justification = c(0, 1),
    legend.title = element_blank(),
    legend.text = element_text(size = 8, color = "black"),
    legend.background = element_rect(fill = alpha("white", 0.75), color = NA),
    legend.margin = margin(4, 6, 4, 6),
    legend.key = element_blank(),
    legend.key.spacing.y = unit(1, "pt"),
    plot.caption = element_text(
      size = 7,
      color = "grey30",
      hjust = 1,
      margin = margin(t = 3)
    ),
    plot.margin = margin(5, 5, 5, 5)
  )

fig_s1

ggsave(
  here::here("plots", "FigureS1_Collection_Locations.png"),
  plot = fig_s1,
  width = 6,
  height = 6,
  units = "in",
  dpi = 600
)