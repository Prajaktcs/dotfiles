require('lint').linters_by_ft = {
  terraform = {"terraform_validate"},
  tf = {"terraform_validate"},
}

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function()
    require("lint").try_lint()
  end,
})
