# Dependency declarations that the renv code scan cannot see.
#
# THIS FILE IS NEVER SOURCED. It exists only so that `renv::dependencies()`
# finds these packages, and it is `.Rbuildignore`d so that `R CMD check` does
# not report a non-standard file at top level. Do not put runnable code here.
#
# Why this file exists: `renv::dependencies()` reads DESCRIPTION (Depends /
# Imports / Suggests) and scans R code. A development tool that is only ever
# invoked from the command line -- `Rscript -e 'roxygen2::roxygenise()'` in
# CLAUDE.md, or `rcmdcheck` from a check script -- appears in neither, so the
# scan drops it and, because .Rprofile sets `renv.config.auto.snapshot = TRUE`,
# the next snapshot removes it from renv.lock without comment.
#
# These do NOT belong in DESCRIPTION Suggests: that field is a claim about what
# a *user* of the installed package may need, and it is what the R-CMD-check
# matrix installs on all six runners. Development tooling is neither.
#
# `renv::record()` alone does not fix this. Beyond the house rule against it
# (it writes degraded lockfile records; see the global CLAUDE.md), the package
# would return to renv.lock while `renv::status()` kept reporting it as unused,
# and the next snapshot would drop it again. The declaration has to live in a
# file the scanner reads.
#
# Verify a declaration works:
#   renv::dependencies()   # this file must appear in the Source column
#   renv::status()         # must report no issues

# `Rscript -e 'roxygen2::roxygenise()'` -- regenerates man/ and NAMESPACE.
library(roxygen2)

# `R CMD check` driver used by the R-CMD-check workflow and locally.
library(rcmdcheck)
