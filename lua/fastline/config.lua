-- config
local M = {}

local modules = require "fastline.modules"

M.default_options = {
    shorting_target = 0,
    scroll_bar = 'normal',
    separator_style = "default",
    components = {
        modules.mode,
        modules.cwd,
        "%=",
        modules.lsp_diagnostics,
        modules.lsp_clients,
        "%=",
        modules.cursor_position,
        modules.scroll_bar,
    }
}

return M
