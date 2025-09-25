# nvim-vscode-status

VSCode status for your Lazy.nvim plugins — simple enabled vs disabled.

- Enabled in VSCode (`vscode = true`)
- Disabled in VSCode (`vscode = false` or unset)

Renders a small read-only popup using `nui.nvim`. Close with `q` or `Esc`.

## Requirements

- Neovim ≥ 0.9
- [`MunifTanjim/nui.nvim`](https://github.com/MunifTanjim/nui.nvim)

## Install (Lazy.nvim)

```lua
return {
  "kevintraver/nvim-vscode-status",
  cmd = "VSCodeStatus",
  dependencies = { "MunifTanjim/nui.nvim" },
}
```

## Usage

- `:VSCodeStatus` — shows each plugin's VSCode status (Enabled or Disabled).

To enable a plugin for VSCode, set `vscode = true` in its Lazy spec:

```lua
return {
  "folke/flash.nvim",
  vscode = true,
}
```

## License

MIT
