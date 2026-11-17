# Honey bees show no olfactory preference for sodium-enriched nectar

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.24298904.svg)](https://doi.org/10.5281/zenodo.24298904)

Data, R analysis code, and Y-maze design files for a behavioral study of whether western honey bees
(*Apis mellifera*) prefer the odor of sodium-enriched artificial nectar.

## Reproducing the analysis

1. Open `honey-bee-sodium-olfaction.Rproj` in RStudio, or start R in the project root. This activates
   renv automatically.
2. In R, install the packages and run everything:

   ```r
   renv::restore()
   source("R/main.R")
   ```

Requirements:

- R 4.6.2.
- An internet connection. Figure S1 downloads satellite map tiles, and `main.R` stops before running
  anything if there is no connection.
- Arial is used in the published figures. Without it, the figures use the system's default sans-serif font and print a warning.
- On Linux, some packages (for example `sf`) compile from source and need system libraries such as GDAL, GEOS, PROJ, FreeType, HarfBuzz, and libcurl.

Outputs are written to `data/processed/`, `results/`, and `plots/`. The `.rds` files are not tracked in
git and are recreated by the run. If you are not using renv, `results/session_info.txt` lists the R and
package versions from the last run.

## Repository layout

```
R/            Analysis scripts
data/         Raw CSVs, cleaned data, and data dictionary (data/README.md)
results/      Model-selection table and estimates
plots/        Figures (vector PDF and 600 dpi PNG)
CAD/          Laser-cut Y-maze design files (.dxf); see CAD/README.md
renv.lock     Package versions
```

## Analysis pipeline

`R/main.R` runs these scripts in order. Each script's header comment describes it in more detail.

- `01_clean_data.R`: checks and joins the raw CSVs and derives the analysis variables
- `02_fit_models.R`: fits 8 candidate GLMMs per behavioral metric and compares them by AICc
- `04_analyze_results.R`: descriptive statistics, model-selection table, and estimates with 95% Wald CIs
- `05_make_plots.R`: Figure 2 and Figures S1-S3

`03_check_diagnostics.R` is not part of the pipeline. It produces DHARMa residual diagnostics for
interactive review and can be run on its own. It uses the same seed as `05_make_plots.R`, so its
residuals match Figure S2.

## Data

The raw data are `full_trial_data.csv`, `full_collection_data.csv`, `full_batch_data.csv`, and
`hive_location.csv` in `data/`. Every column, its units, and how the files link together are described
in [`data/README.md`](data/README.md).

## License

| Content | License | File |
|---|---|---|
| Code (`R/` and other scripts) | MIT | [`LICENSE`](LICENSE) |
| Data (`data/`) | CC BY 4.0 | [`data/LICENSE`](data/LICENSE) |
| Y-maze design files (`CAD/`) | CC BY 4.0 | [`CAD/LICENSE`](CAD/LICENSE) |

## Citation

Please cite this repository as described in [`CITATION.cff`](CITATION.cff), or use GitHub's "Cite this
repository" button.

## Acknowledgements

We thank Dave Weed for providing access to his honey bee colonies; Rowan Benda, Alex Haas, and Ceinwyn Erb for their help with sample collection; Foxy Designs LTD for fabrication of the Y-maze; Mark Hammond for support in our use of the Plant Ecology Field Lab (PEFL) space during our experiments; the W.K. Kellogg Biological Station for hosting this project and providing research facilities; and the members of the Haddad Lab for their support and for feedback on the manuscript. S.H. was funded by the Doug and Maria Bayer Scholarship Fund. A.L.D. was funded by a National Science Foundation Graduate Research Fellowship (award number 2235783).

Figure S1 uses Esri World Imagery: Esri, Maxar, Earthstar Geographics, and the GIS User Community.
World Imagery [basemap], https://www.arcgis.com/home/item.html?id=10df2279f9684e4a9f6a7f08febac2a9.
