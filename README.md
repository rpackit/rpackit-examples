# rpackit examples

Small applications used to test rpackit target selection, build outputs, and
authenticated desktop lifecycle contracts.

## Included

- [`hello-shiny`](hello-shiny) — a minimal app with one input and one plot,
  plus a Windows portable-runtime quickstart for preparing a bundle, starting
  its authenticated backend, generating a native application, and publishing
  a remotely verified Windows installer.

Examples stay compact, deterministic, and free of credentials or large data.
Larger compatibility fixtures are added only when a target builder needs them.

The desktop quickstart intentionally does not open the managed app with a
stock browser. rpackit's authenticated launcher requires a native shell or
loopback proxy to add `Shiny-Shared-Secret` to HTTP, static-resource, and
WebSocket requests without exposing the credential to browser JavaScript.

Verified binaries stay in
[GitHub Releases](https://github.com/rpackit/rpackit-examples/releases);
this repository contains only the small example source and release workflow.
