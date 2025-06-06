# Contributing

We welcome contributions of all kinds, be it in terms of bug fixes,
reproductions, features or documentation.

In general, PRs are more likely to be merged quickly if they contain tests which
prove that a feature is working as intended or that a bug was indeed present and
has now been fixed. Creating a draft PR that reproduces a bug is also a great
way to help us fix issues quickly. Check out
[this PR](https://github.com/nix-community/disko/pull/330) as an example.

For more information on how to run and debug tests, check out
[Running and debugging tests](./docs/testing.md).

## Finding and Running Tests

### Listing All Available Tests

To see all available tests in the project:

```bash
# List all test files
ls tests/*.nix | grep -v default.nix

# List all tests using nix eval
nix eval --apply builtins.attrNames .#checks.x86_64-linux --json | jq -r '.[]' | sort
```

### Running Tests

```bash
# Run all tests and checks
nix-fast-build

# Run a specific test by name
nix build .#checks.x86_64-linux.simple-efi -L

# Run tests matching a pattern
nix eval --apply 'checks: builtins.filter (name: builtins.match ".*luks.*" name != null) (builtins.attrNames checks)' .#checks.x86_64-linux --json | jq -r '.[]' | xargs -I {} echo nix build .#checks.x86_64-linux.{} -L
```

### Understanding Test Structure

Each test file in `tests/` corresponds to an example configuration in `example/`:
- `tests/simple-efi.nix` tests `example/simple-efi.nix`
- `tests/luks-lvm.nix` tests `example/luks-lvm.nix`
- etc.

Tests use NixOS's `make-test-python.nix` framework to create VMs that actually partition disks and verify the configurations work correctly.


## How to find issues to work on

If you're looking for a low-hanging fruit, check out
[this list of `good first issue`s](https://github.com/nix-community/disko/labels/good%20first%20issue).
These are issues that we have confirmed to be real and which have a strategy for
a fix already lined out in the comments. All you need to do is implement.

If you're looking for something more challenging, check out
[this list of issues tagged `contributions welcome`](https://github.com/nix-community/disko/labels/contributions%20welcome).
These are issues that we have confirmed to be real and we know we want to be
fixed.

For the real though nuts, we also have
[the `help wanted` label](https://github.com/nix-community/disko/labels/help%20wanted)
for issues that we feel like we need external help with. If you want a real
challenge, take a look there!

If you're looking for bugs that still need to be reproduced, have a look at
[this list of non-`confirmed` bugs](https://github.com/nix-community/disko/issues?q=is%3Aissue+is%3Aopen+label%3Abug+-label%3Aconfirmed+).
These are things that look like bugs but that we haven't reproduced yet.

If you're looking to contribute to the documentation, check out
[the `documentation` tag](https://github.com/nix-community/disko/issues?q=is%3Aissue+is%3Aopen+label%3Adocumentation)
or just read through [our docs](./docs/INDEX.md) and see if you can find any
issues.
