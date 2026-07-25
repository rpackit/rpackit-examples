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

The commands below use the published Windows x86_64 R 4.6.1 prototype. The
release is intentionally marked as an unsigned development prerelease; verify
the digest before extracting it and do not treat it as a signed installer.

In PowerShell:

```powershell
$releaseBase = "https://github.com/rpackit/portable-r-windows/releases/download/v4.6.1"
$runtimeUrl = "$releaseBase/portable-r-windows-x86_64-4.6.1.zip"
$expectedSha256 = "d106a4ad618a5279d9db4a61412505a5353c94e402920c0d3a627d37c5f1bf50"
$downloadPath = Join-Path $PWD "portable-r-windows-x86_64-4.6.1.zip"
$runtimeParent = Join-Path $PWD "portable-r-runtime"

Invoke-WebRequest -Uri $runtimeUrl -OutFile $downloadPath
$actualSha256 = (
  Get-FileHash -LiteralPath $downloadPath -Algorithm SHA256
).Hash.ToLowerInvariant()
if ($actualSha256 -ne $expectedSha256) {
  throw "Portable R SHA-256 mismatch."
}

New-Item -ItemType Directory -Path $runtimeParent | Out-Null
Expand-Archive -LiteralPath $downloadPath -DestinationPath $runtimeParent
```

The extracted runtime directory is
`portable-r-runtime/portable-r-windows-x86_64-4.6.1`. Install the development
package into your current R session, then prepare and run a new bundle:

```r
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak", repos = "https://cloud.r-project.org")
}
pak::pkg_install("rpackit/rpackit")

runtime_dir <- file.path(
  getwd(),
  "portable-r-runtime",
  "portable-r-windows-x86_64-4.6.1"
)
output_dir <- file.path(
  tempdir(),
  paste0("hello-shiny-desktop-", format(Sys.time(), "%Y%m%d-%H%M%S"))
)

bundle <- rpackit::prepare_desktop(
  ".",
  runtime_dir = runtime_dir,
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
