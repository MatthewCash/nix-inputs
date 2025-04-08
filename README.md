# nix-inputs

Flake inputs for [nixos-config](https://github.com/MatthewCash/nixos-config)

Current inputs size: <!---size-->`670M`<!---/size-->

## Why

Many of my flake's inputs use the `github:` fetcher, but GitHub aggressively rate-limits their API for unauthenticated users to [60](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28#primary-rate-limit-for-unauthenticated-users) requests / hour.

To prevent a rate-limit error when performing flake-related operations, dependencies are automatically consolidated in this repository and loaded as a single input.

## How

1. A dummy flake is created and its dependencies are solved using the provided [`inputs.nix`](inputs.nix)
2. The sources for the dummy flake's inputs and all of the input's dependencies are copied to [`deps/`](deps)
3. The output flake, [`flake.nix`](flake.nix), is generated with all inputs redirected to [`deps`](deps)
4. The dummy flake's lockfile is copied to [`resolved-flake.lock`](resolved-flake.lock) for simpler dependency tracking
