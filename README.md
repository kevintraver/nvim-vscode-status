# nvim-vscode-status

VSCode Plugin Status for your Neovim/Lazy.nvim setup. Shows which plugins are:

- Enabled for VSCode (`vscode = true`)
- Explicitly disabled for VSCode (`vscode = false`)
- Not enabled for VSCode (no `vscode` flag)

Renders a clean popup using `nui.nvim`.

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

- `:VSCodeStatus` — Opens a popup with three sections:
  - Enabled for VSCode
  - Explicitly Disabled for VSCode
  - Not enabled for VSCode

Tip: To enable a plugin for VSCode, add `vscode = true` to its Lazy spec, for example:

```lua
return {
  "folke/flash.nvim",
  vscode = true,
}
```

## Notes

- This inspects your local plugin specs under `lua/plugins/` and infers VSCode status from each spec table.
- Output is read-only and can be closed with `q` or `Esc`.

## License

MIT
