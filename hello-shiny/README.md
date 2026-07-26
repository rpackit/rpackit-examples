# hello-shiny

A deliberately small Shiny application for exercising rpackit's implemented
inspection, dependency planning, portable-resource preparation, and managed
process lifecycle.

## Run with the current R installation

From this directory:

```r
shiny::runApp(".")
rpackit::check_app(".")
rpackit::plan_dependencies(".")
```

## Windows portable-runtime quickstart

The current verified registry entry is the published Windows x86_64 R 4.6.1
development prerelease. It is unsigned: rpackit verifies that its SHA-256
matches the registry record, but this is not a code-signing guarantee.

Install the development package into your current R session, then resolve,
prepare, and run a new bundle:

```r
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak", repos = "https://cloud.r-project.org")
}
pak::pkg_install("rpackit/rpackit")

runtime <- rpackit::resolve_portable_runtime()
stopifnot(
  runtime$r_version == "4.6.1",
  runtime$platform == "windows",
  runtime$arch == "x86_64",
  runtime$status == "verified"
)

output_dir <- file.path(
  tempdir(),
  paste0("hello-shiny-desktop-", format(Sys.time(), "%Y%m%d-%H%M%S"))
)

bundle <- rpackit::prepare_desktop(
  ".",
  runtime_dir = NULL,
  r_version = runtime$r_version,
  output_dir = output_dir
)
rpackit::validate_desktop_bundle(
  bundle$path,
  verify_runtime = TRUE
)

process <- rpackit::start_desktop_app(bundle$path)
on.exit(
  rpackit::stop_desktop_app(process, quiet = TRUE),
  add = TRUE
)

status <- rpackit::desktop_app_status(process)
stopifnot(status$ready, status$host == "127.0.0.1")
utils::browseURL(status$url)

rpackit::stop_desktop_app(process)
```

The explicit `resolve_portable_runtime()` call above makes the selected
version, SHA-256, and cache state visible. Passing that version to
`prepare_desktop(runtime_dir = NULL)` then reuses the same verified cache entry
without downloading the artifact again.
For later offline preparation, pass `offline = TRUE`; it fails clearly instead
of accessing the runtime registry or artifact network when no matching cache
entry exists.

`prepare_desktop()` deliberately refuses to replace an existing
`output_dir`; choose a new path for another build. Package restoration also
requires network access and may fail when an application depends on
unavailable repositories, Bioconductor packages, or external system
libraries.

This workflow produces and runs validated desktop resources. It does not
produce a native Tauri executable. The session token is currently a private
correlation/bootstrap value, not HTTP or WebSocket authentication; the
manifest and runtime status therefore report
`network_token_enforced = FALSE`.
