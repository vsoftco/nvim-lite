# Modern Neovim starter kit

A minimal Neovim configuration intended as a starting point for your own
setup - simple, modern, and easy to extend, tailored for programming and
development workflows.

## Pre-requisites

- Neovim 12 or newer
- [`fzf`](https://github.com/junegunn/fzf)
- [Node.js](https://nodejs.org/)

## Features

- Uses the new built-in `vim.pack` plugin manager
- The entire configuration, except for the
  [language server configurations](after/lsp), is defined in
  [`init.lua`](init.lua)

## Installation

Clone this configuration into `~/.config/nvim` (make sure to back up your
existing one first)

```shell
git clone https://github.com/vsoftco/nvim-lite ~/.config/nvim
```

then launch Neovim

```shell
nvim
```

This configuration provides the following custom commands as wrappers around
`vim.pack`:

- `:PackUpdate` - updates plugins
- `:PackClean`- removes unused plugins from the disk
- `:PackSync` - pin plugins to the version recorded in
  [`nvim-pack-lock.json`](nvim-pack-lock.json)

## Test configuration (optional)

To try this configuration without affecting your current setup, clone it into a
separate directory under `~/.config`, for example

```shell
git clone https://github.com/vsoftco/nvim-lite ~/.config/nvim-test
```

Then start Neovim with

```shell
NVIM_APPNAME=nvim-test nvim
```
