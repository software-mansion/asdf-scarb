<div align="center">

# asdf-scarb [![Build](https://github.com/software-mansion-labs/asdf-scarb/actions/workflows/build.yml/badge.svg)](https://github.com/software-mansion-labs/asdf-scarb/actions/workflows/build.yml) [![Lint](https://github.com/software-mansion-labs/asdf-scarb/actions/workflows/lint.yml/badge.svg)](https://github.com/software-mansion-labs/asdf-scarb/actions/workflows/lint.yml)

[scarb](https://docs.swmansion.com/scarb) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

**TODO: adapt this section**

- `bash`, `curl`, `tar`: generic POSIX utilities.
- `SOME_ENV_VAR`: set this environment variable in your shell config to load the correct version of tool x.

# Install

Plugin:

```shell
asdf plugin add scarb
# or
asdf plugin add scarb https://github.com/software-mansion-labs/asdf-scarb.git
```

scarb:

```shell
# Show all installable versions
asdf list-all scarb

# Install specific version
asdf install scarb latest

# Set a version globally (on your ~/.tool-versions file)
asdf global scarb latest

# Now scarb commands are available
scarb --version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/software-mansion-labs/asdf-scarb/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Software Mansion](https://github.com/software-mansion-labs/)
