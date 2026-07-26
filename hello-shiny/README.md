# hello-shiny

A deliberately small Shiny application for exercising rpackit's implemented
inspection, dependency planning, portable-resource preparation, authenticated
managed-process lifecycle, and native-shell handoff contract.

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
prepare, and start a newly built backend:

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
validation <- rpackit::validate_desktop_bundle(
  bundle$path,
  verify_runtime = TRUE
)
stopifnot(validation$valid, validation$network_token_enforced)

local({
  process <- rpackit::start_desktop_app(bundle$path)
  on.exit(
    rpackit::stop_desktop_app(process, quiet = TRUE),
    add = TRUE
  )

  status <- rpackit::desktop_app_status(process)
  launch <- rpackit::desktop_app_launch_config(process)
  stopifnot(
    status$ready,
    status$host == "127.0.0.1",
    status$network_token_enforced,
    identical(launch$url, status$url),
    identical(names(launch$headers), "Shiny-Shared-Secret"),
    identical(launch$request_types, c("http", "websocket")),
    identical(launch$follow_redirects, FALSE)
  )

  # Native integration boundary:
  # Give `launch` directly to a trusted native shell or loopback proxy. It must
  # attach launch$headers to navigation, subresources, and WebSocket upgrades
  # for exactly launch$origin. Never print, log, serialize, or persist `launch`.

  rpackit::stop_desktop_app(process)
  rm(launch)
})
```

Do not replace the native integration step with
`utils::browseURL(status$url)`. A stock browser cannot add the protected
header to top-level navigation or ordinary `WebSocket()` calls, so direct
navigation is expected to be denied. To explore this example without a native
shell, use `shiny::runApp(".")` from the first section; that runs the source app
with the current R installation rather than the authenticated desktop bundle.

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

This workflow produces and starts validated desktop resources; it does not
produce a native Tauri executable. Each `start_desktop_app()` call creates a
fresh 256-bit session credential in a current-account-private, one-time file.
Windows DACLs are restricted and verified for the current account plus SYSTEM;
POSIX modes 0700/0600 are verified. Only the file path is passed to the
launcher. The launcher consumes and deletes the file before app or port
validation, and rpackit never places the credential in the process command
line, environment, URL, manifest, generated lifecycle-event fields, returned
status, or printed output. Launcher errors and returned logs/events are
redacted; arbitrary app output in the private raw log is outside that
guarantee.

Shiny enforces that credential as the `Shiny-Shared-Secret` request header for
dynamic HTTP, static resources, and WebSocket session acceptance. Missing or
wrong HTTP credentials receive 403. Shiny may complete a WebSocket upgrade
with 101 and then immediately close the unauthenticated socket before the app
server starts. Consequently, newly prepared manifests and runtime status
report `network_token_enforced = TRUE`. New launch configurations are
available only while the managed process is running, but a previously returned
`launch` object retains its credential until the caller removes every copy. A
native shell or loopback proxy must keep its header outside JavaScript,
restrict injection to the exact loopback origin, and never forward the
credential across a redirect.

Bundles built with the older unauthenticated launcher contract must be rebuilt
into a new `output_dir` before they can run. They remain inspectable with
`validate_desktop_bundle()`, but `start_desktop_app()` intentionally refuses
to launch them.
