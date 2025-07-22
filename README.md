# i4results

Flexible **R** function _and_ **Stata** `ado` program that produce the side-by-side coefficient table required by the **Institute for Replication (I4R)**. Feed an *original* model plus up to five *robustness/replication* models and get a tidy long-format data set—ready for spreadsheets, dashboards, or reports.

<p align="center">
  <img src="docs/preview.png" alt="preview screenshot">
</p>

---

## Key features

|                               | R implementation              | Stata implementation           |
|-------------------------------|-------------------------------|--------------------------------|
| Model-agnostic extraction     | via **broom**                 | parses `e(b)` / `e(V)`         |
| Stats returned                | coef, SE, t/z, *p*, 95 % CI, _N_ | same                           |
| Excel export / append         | **openxlsx**                  | `export excel`                 |
| Lightweight deps              | broom (+ openxlsx)            | none                           |

---

## Installation

### R

```r
# install.packages("remotes")
remotes::install_github("i4r-org/i4results", subdir = "R")
# or simply
source("R/i4results.R")
```

### Stata

```stata
net install i4results , ///
    from("https://raw.githubusercontent.com/i4r-org/i4results/main/Stata/") replace
```

---

## Quick start

### R example

```r
library(fixest)   # for feols
library(openxlsx) # for Excel output

orig <- lm(mpg ~ wt + hp, data = mtcars)
rob  <- list(
  "GLM"    = glm(mpg ~ wt + hp, data = mtcars, family = gaussian()),
  "FE cyl" = fixest::feols(mpg ~ wt + hp | cyl, data = mtcars)
)

results <- i4results(orig, rob, out = "robustness.xlsx")
head(results)
```

### Supported R models

Any model that `broom::tidy()` understands can be compared. This includes `lm()` and `glm()`, `MASS::glm.nb()`, `mgcv::gam()`, `survival::coxph()` and many others. If your favourite command isn't supported, please [open an issue](https://github.com/i4r-org/i4results/issues).


### Stata example

```stata
sysuse auto, clear

reg price weight mpg
est store orig

reg price weight mpg foreign
est store rep1

reg price weight mpg foreign gear_ratio
est store rep2

i4results , original(orig) robustness("rep1 rep2") out("robustness.xlsx")
```

---

## Output schema

| Column      | Description                                           |
|-------------|-------------------------------------------------------|
| `paramname` | Coefficient name (intercept excluded)                 |
| `study`     | Robustness ID (`rep1`, `rep2`, …)                     |
| `o_*`       | Stats for **original** model                          |
| `r_*`       | Stats for **robustness** model                        |

Each row contains one parameter from the original model paired with the corresponding parameter in a robustness model.

---

## Contributing

Pull requests are welcome! Open an issue first to discuss major changes.

If a particular estimator is not handled correctly, [open an issue](https://github.com/i4r-org/i4results/issues) so we can improve compatibility.
### Run tests (R)

```r
devtools::test()
```

### Style guide

* R code follows tidyverse style.  
* Stata code targets version 17 and avoids Mata for portability.

---

## License

MIT © Institute for Replication 2025
