# hello-shiny

A deliberately small Shiny application for the first rpackit desktop,
static-web, and server build demonstrations.

```r
shiny::runApp(".")
rpackit::check_app(".")
rpackit::plan_dependencies(".")
```

Prepare a portable desktop resource bundle after extracting a runtime from the
[`portable-r` registry](https://github.com/rpackit/portable-r):

```r
bundle <- rpackit::prepare_desktop(
  ".",
  runtime_dir = "/path/to/portable-r"
)
rpackit::validate_desktop_bundle(bundle$path, verify_runtime = TRUE)
```

This produces validated resources, not yet a native Tauri executable.
