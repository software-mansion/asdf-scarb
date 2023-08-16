# asdf-scarb

[Scarb] plugin for the [asdf] version manager.

## Install

This plugin needs `bash`, `curl`, `tar` and other generic POSIX utilities.
Everything should be included by default on your system.

```shell
asdf plugin add scarb
```

or

```shell
asdf plugin add scarb https://github.com/software-mansion/asdf-scarb.git
```

## Use

Show all installable versions:

```shell
asdf list-all scarb
```

Install latest version:

```shell
asdf install scarb latest
```

Install specific version:

```shell
asdf install scarb 0.5.0
```

Install latest nightly version:

```shell
asdf install scarb latest:nightly
```

Install specific nightly version:

```shell
asdf install scarb nightly-2023-08-10
```

Set a version globally (in your `~/.tool-versions` file):

```shell
asdf global scarb latest
```

Now scarb commands are available:

```shell
scarb --version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to install & manage versions.

[asdf]: https://asdf-vm.com
[scarb]: https://docs.swmansion.com/scarb
