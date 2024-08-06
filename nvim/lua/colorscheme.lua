local success, _ = pcall(function()
    require("kanagawa").load("wave")
    -- require("kanagawa").load("dragon")
end)

if not success then
    vim.api.nvim_command("colorscheme habamax")
end
