local M = {}

local fn = require('utils.functions')

M.settings = {}

M.set = function(default_config, user_config)
    local current = default_config
    for key, value in pairs(user_config) do
        if vim.tbl_contains(vim.tbl_keys(current), key) then
            if type(current[key]) == 'table' then
                current[key] = {}
                fn.merge_list(current[key], value)
            else
                current[key] = value
            end
        end
    end

    return current
end

M.run = function()
    if M.settings.separator_style then
        vim.g.statusline_sep_style = M.settings.separator_style
    else
        vim.g.statusline_sep_style = "defaults"
    end

    local comp_names = M.settings.components
    local components = {}
    if #comp_names > 0 then
        for _, comp_name in ipairs(comp_names) do
            if type(comp_name) == "function" then
                local component = comp_name()
                table.insert(components, component)
            else
                table.insert(components, comp_name)
            end
        end
    end

    return table.concat(components)
end

M.setup = function(opts)
    opts = opts or {}

    local default_config = require("fastline.config").default_options
    M.settings = M.set(default_config, opts)

    vim.opt.statusline = "%!v:lua.require('fastline').run()"
end

return M
