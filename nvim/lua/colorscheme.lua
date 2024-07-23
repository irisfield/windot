local success, _ = pcall(function()
    -- vim.api.nvim_command('colorscheme kanagawa')
    require("kanagawa").load("wave")
    -- require("kanagawa").load("dragon")
end)
if not success then
    vim.api.nvim_command('colorscheme default')
end
