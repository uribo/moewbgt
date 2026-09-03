# renv user-level config. Must be set BEFORE renv activates: renv resolves
# config as R option > RENV_CONFIG_* env var > default, and some options are
# read at load time.
#
# Deliberately NOT set here: Sys.setenv(TZ = ...). The research-project-template
# pins TZ, but this is a package. Environment variables set in this profile are
# inherited by the R CMD check subprocesses, so a pinned TZ would hide any
# time-zone dependence that CRAN's own machines (which run UTC) would expose.
options(
  # Snapshot library changes into renv.lock automatically. Convenience over
  # strictness: review the renv.lock diff before committing regardless -- the
  # PreToolUse hook in .claude/settings.json makes an agent stop and show it.
  renv.config.auto.snapshot = TRUE,
  # Route renv::install()/restore() through pak, so system requirements are
  # resolved in the same pass. Reached through data-raw/, sf needs GDAL/GEOS/
  # PROJ and pdftools needs poppler; renv's own installer does not resolve them.
  renv.config.pak.enabled = TRUE,
  # A file the dependency scanner cannot parse must stop the enumeration. The
  # lockfile here is snapshot.type = "implicit": DESCRIPTION covers the package
  # itself, but the rest of the development environment (the data-raw/
  # derivation scripts, the tests, _dependencies.R) is declared only by the code
  # scan, and the default "reported" silently drops a broken file's
  # dependencies.
  renv.config.dependency.errors = "fatal"
)

# Activate renv only after it has been initialized (renv::init writes
# renv/activate.R). The guard keeps R startup from erroring in a checkout where
# the file is absent.
if (file.exists("renv/activate.R")) {
  source("renv/activate.R")
}

# Locale pin. Two categories are pinned, for two different reasons:
#
#   LC_COLLATE drives sort()/order()/factor() level order and is a silent
#   source of cross-machine differences -- even for pure ASCII, where C sorts
#   by code point ("Zebra" < "apple") and most system locales sort
#   case-insensitively ("apple" < "Zebra").
#
#   LC_TIME drives the month and weekday names returned by format()/strftime()
#   with %b/%B/%a/%A. Unpinned under LANG=ja_JP.UTF-8 those come back in
#   Japanese, which is how a date axis in an English document quietly acquires
#   Japanese labels.
#
# Never pin either of these with LC_ALL: that overrides LC_CTYPE as well, and
# under LC_ALL=C a comparison against a Japanese string stops matching with no
# error and no warning, so the affected rows vanish from the result.
#
# This is the fallback layer. The primary pin is the environment -- the `env`
# block of .claude/settings.json and the [shell_environment_policy.set] block
# of .codex/config.toml both set LC_COLLATE=C and LC_TIME=C -- because renv's
# reset (below) lands back on whatever the environment says. This file covers a
# plain shell session started outside either agent.
#
# These two lines MUST come after renv activates. `renv/activate.R` can reset
# the locale to the system default, so setting it earlier is undone with no
# error and no warning. The mechanism is upstream:
# renv:::renv_parse_impl_native() defers a bare `Sys.setlocale()`, which resets
# LC_ALL to the environment default rather than restoring the saved value, and
# it fires whenever renv falls back to native-encoding parsing. That also makes
# this layer the weaker one -- a later renv call can undo it again, while the
# environment layer changes what the reset resets *to*.
#
# Verify: Rscript -e 'Sys.getlocale("LC_COLLATE")'  -> must print "C"
#         Rscript -e 'Sys.getlocale("LC_TIME")'     -> must print "C"
invisible(Sys.setlocale("LC_COLLATE", "C"))
invisible(Sys.setlocale("LC_TIME", "C"))
