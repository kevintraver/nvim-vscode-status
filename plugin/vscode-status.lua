local M = require("vscode-status")

vim.api.nvim_create_user_command("VSCodeStatus", M.show_status, {
  desc = "Show VSCode status for Neovim plugins",
})
