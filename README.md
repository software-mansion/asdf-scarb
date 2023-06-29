# asdf-scarb

[Scarb] plugin for the [asdf] version manager.

## Install

This plugin needs `bash`, `curl`, `tar` and other generic POSIX utilities.
Everything should be included by default on your system.

```shell
asdf plugin add scarb
# or
asdf plugin add scarb https://github.com/software-mansion-labs/asdf-scarb.git
```

## Use

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

[asdf]: https://asdf-vm.com

[scarb]: https://docs.swmansion.com/scarb
