local success, err = pcall(function()
    require("kanagawa").load("wave")
    -- require("kanagawa").load("dragon")
end)

if not success then
    vim.api.nvim_command("colorscheme habamax")
    print("Error setting colorscheme: " .. err)
end
