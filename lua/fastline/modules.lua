local M = {}

local fn = vim.fn

local sep_style = vim.g.fastline_sep_style or 'default'
local separators = (type(sep_style) == "table" and sep_style) or require("fastline.icons").statusline_separators[sep_style]

local sep_l = separators["left"]
local sep_r = separators["right"]

local sep_elem = separators["elements"]

M.modes = {
    ["n"]   = { "NORMAL",              "St_NormalMode"    },
    ["niI"] = { "NORMAL i",            "St_NormalMode"    },
    ["niR"] = { "NORMAL r",            "St_NormalMode"    },
    ["niV"] = { "NORMAL v",            "St_NormalMode"    },
    ["no"]  = { "N-PENDING",           "St_NormalMode"    },
    ["i"]   = { "INSERT",              "St_InsertMode"    },
    ["ic"]  = { "INSERT (completion)", "St_InsertMode"    },
    ["ix"]  = { "INSERT completion",   "St_InsertMode"    },
    ["t"]   = { "TERMINAL",            "St_TerminalMode"  },
    ["nt"]  = { "NTERMINAL",           "St_NTerminalMode" },
    ["v"]   = { "VISUAL",              "St_VisualMode"    },
    ["V"]   = { "V-LINE",              "St_VisualMode"    },
    ["Vs"]  = { "V-LINE (Ctrl O)",     "St_VisualMode"    },
    [""]  = { "V-BLOCK",             "St_VisualMode"    },
    ["R"]   = { "REPLACE",             "St_ReplaceMode"   },
    ["Rv"]  = { "V-REPLACE",           "St_ReplaceMode"   },
    ["s"]   = { "SELECT",              "St_SelectMode"    },
    ["S"]   = { "S-LINE",              "St_SelectMode"    },
    [""]  = { "S-BLOCK",             "St_SelectMode"    },
    ["c"]   = { "COMMAND",             "St_CommandMode"   },
    ["cv"]  = { "COMMAND",             "St_CommandMode"   },
    ["ce"]  = { "COMMAND",             "St_CommandMode"   },
    ["r"]   = { "PROMPT",              "St_ConfirmMode"   },
    ["rm"]  = { "MORE",                "St_ConfirmMode"   },
    ["r?"]  = { "CONFIRM",             "St_ConfirmMode"   },
    ["!"]   = { "SHELL",               "St_TerminalMode"  },
}

M.mode = function()
    local mode = M.modes[vim.api.nvim_get_mode().mode]

    local mode_name = mode[1]
    local mode_hl_name = mode[2]

    local mode_hl = "%#" .. mode_hl_name .. "#"
    local mode_hl_sep = "%#" .. mode_hl_name .. "_Sep" .. "#"

    local current_mode = mode_hl .. "  " .. mode_name
    local mode_sep = mode_hl_sep .. sep_l
    return current_mode .. mode_sep ..  "%#St_EmptySpace#"
end

M.git = function()
    if not vim.b.gitsigns_head or vim.b.gitsigns_git_status then
        return ""
    end

    local git_status = vim.b.gitsigns_status_dict

    local added = (git_status.added and git_status.added ~= 0) and ("  " .. git_status.added) or ""
    local changed = (git_status.changed and git_status.changed ~= 0) and ("  " .. git_status.changed) or ""
    local removed = (git_status.removed and git_status.removed ~= 0) and ("  " .. git_status.removed) or ""
    local branch_name = "   " .. git_status.head .. " "

    return "%#GitIcons#" .. branch_name .. added .. changed .. removed
end

-- LSP STUFF
M.lsp_progress = function()
    if not rawget(vim, "lsp") then
        return ""
    end

    local Lsp = vim.lsp.util.get_progress_messages()[1]

    if vim.o.columns < 120 or not Lsp then
        return ""
    end

    local msg = Lsp.message or ""
    local percentage = Lsp.percentage or 0
    local title = Lsp.title or ""
    local spinners = { "", "" }
    local ms = vim.loop.hrtime() / 1000000
    local frame = math.floor(ms / 120) % #spinners
    local content = string.format(" %%<%s %s %s (%s%%%%) ", spinners[frame + 1], title, msg, percentage)

    return ("%#St_LspProgress#" .. content .. "%#St_EmptySpace#") or ""
end

M.lsp_diagnostics = function()
    if not rawget(vim, "lsp") then
        return ""
    end

    local errors_count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
    local warnings_count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
    local hints_count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
    local info_count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })

    local errors = (errors_count and errors_count > 0) and ("%#St_lspError#" .. " " .. errors_count .. " ") or ""
    local warnings = (warnings_count and warnings_count > 0) and ("%#St_lspWarning#" .. "  " .. warnings_count .. " ") or ""
    local hints = (hints_count and hints_count > 0) and ("%#St_lspHints#" .. "ﯧ " .. hints_count .. " ") or ""
    local info = (info_count and info_count > 0) and ("%#St_lspInfo#" .. " " .. info_count .. " ") or ""

    return errors .. warnings .. hints .. info
end

M.lsp_clients = function()
    if rawget(vim, "lsp") then
        local buf_ft = vim.bo.filetype
        local buf_client_names = {}

        local full_lsp_line = ""

        local lsp_icons = require("fastline.icons").lsp_icons
        local lspconfig_icon = lsp_icons["lspconfig"]
        local null_ls_icon = lsp_icons["null_ls"]

        local mode_hl_name = M.modes[vim.api.nvim_get_mode().mode][2]
        local mode_hl_sep = "%#" .. mode_hl_name .. "_Sep" .. "#"

        local hl_diag = mode_hl_sep

        for _, lspclient in ipairs(vim.lsp.get_active_clients()) do
            if lspclient.attached_buffers[vim.api.nvim_get_current_buf()] then

                if lspclient.name == 'null-ls' then
                    local formatters = require "plugins.null-ls.formatters"
                    local supported_formatters = formatters.list_registered(buf_ft)

                    if #supported_formatters > 2 then
                        local filtered_table = {}
                        for n, client in pairs(supported_formatters) do
                            if n < 3 then
                                table.insert(filtered_table, client)
                            end
                        end
                        supported_formatters = filtered_table
                    else
                        vim.list_extend(buf_client_names, supported_formatters)
                    end

                    -- add linter
                    local linters = require "plugins.null-ls.linters"
                    local supported_linters = linters.list_registered(buf_ft)
                    if #supported_linters > 2 then
                        local filtered_table = {}
                        for n, client in pairs(supported_linters) do
                            if n < 3 then
                                table.insert(filtered_table, client)
                            end
                        end
                        supported_linters = filtered_table
                    else
                        vim.list_extend(buf_client_names, supported_linters)
                    end

                    -- add hover
                    if #buf_client_names < 3 then
                        local hovers = require "plugins.null-ls.hovers"
                        local supported_hovers = hovers.list_registered(buf_ft)
                        vim.list_extend(buf_client_names, supported_hovers)
                    end

                    -- add code action
                    if #buf_client_names < 3 then
                        local code_actions = require "plugins.null-ls.code_actions"
                        local supported_code_actions = code_actions.list_registered(buf_ft)
                        vim.list_extend(buf_client_names, supported_code_actions)
                    end

                    local hash = {}
                    local client_names = {}
                    for _, v in ipairs(buf_client_names) do
                        if not hash[v] then
                            client_names[#client_names + 1] = v
                            hash[v] = true
                        end
                    end

                    if #client_names == 0 then
                        if vim.tbl_count(buf_client_names) > 0 then
                            full_lsp_line = "[" .. lspconfig_icon .. "]: " .. table.concat(buf_client_names, sep_elem)
                        end
                    else
                        if #supported_formatters > 0 then
                            full_lsp_line = " [" .. null_ls_icon .. "]: " .. table.concat(supported_formatters, sep_elem)
                        end

                        if #supported_linters > 0 then
                            full_lsp_line = full_lsp_line .. ", " .. table.concat(supported_linters, sep_elem)
                        end
                    end
                else
                    full_lsp_line = "[" .. lspconfig_icon .. "]: " .. lspclient.name
                end

                if #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR }) > 0 then
                    hl_diag = "%#St_lspError#"
                elseif #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN }) > 0 then
                    hl_diag = "%#St_lspWarning#"
                elseif #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO }) > 0 then
                    hl_diag = "%#St_lspInfo#"
                elseif #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT }) > 0 then
                    hl_diag = "%#St_lspHints#"
                end

                full_lsp_line = hl_diag .. full_lsp_line
                return (full_lsp_line)
            end
        end
    end
end

M.cwd = function()
    local mode_hl_name = M.modes[vim.api.nvim_get_mode().mode][2]
    local mode_hl_sep = "%#" .. mode_hl_name .. "_Sep" .. "#"

    local icon = " "
    local ftype = vim.opt.filetype:get()

    local filename = (fn.expand "%" == "" and "Empty ") or fn.expand "%:t"
    local dirname = fn.fnamemodify(fn.getcwd(), ":~")
    local data = dirname .. "/" .. filename

    local shorting_target = require('fastline').settings.shorting_target

    local function count(base, pattern)
        return select(2, string.gsub(base, pattern, ''))
    end

    local function shorten_path(path, sep)
        return path:gsub(string.format('([^%s])[^%s]+%%%s', sep, sep, sep), '%1' .. sep, 1)
    end

    if filename ~= "Empty " then
        local devicons_present, devicons = pcall(require, "nvim-web-devicons")

        if devicons_present then
            local ft_icon = devicons.get_icon(filename)
            icon = (ft_icon ~= nil and ft_icon .. " ") or ""
        end
    end

    local filetype = mode_hl_sep .. "[" .. icon .. ftype .. "]" .. " "

    if shorting_target ~= 0 then
        local windwidth = vim.fn.winwidth(0)
        local estimated_space_available = windwidth - shorting_target

        local path_separator = package.config:sub(1, 1)
        for _ = 0, count(data, path_separator) do
            if windwidth <= 84 or #data > estimated_space_available then
                data = shorten_path(data, path_separator)
            end
        end
    end

    local file_info = filetype .. " " .. data .. "%#St_EmptySpace#"

    return file_info or ""
end

M.scroll_bar = function()
    local scroll_bar_blocks = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' }

    local current_line = fn.line "."
    local total_lines = fn.line "$"

    local mode_hl_name = M.modes[vim.api.nvim_get_mode().mode][2]
    local mode_hl_reverse = "%#" .. mode_hl_name .. "_Reverse" .. "#"

    local scroll_bar_element_num = 7
    local scroll_direct = require('fastline').settings.scroll_bar

    if scroll_direct == 'normal' then
        scroll_bar_element_num = 8 - math.floor(current_line / total_lines * scroll_bar_element_num)
    elseif scroll_direct == 'reverse' then
        scroll_bar_element_num = math.floor(current_line / total_lines * scroll_bar_element_num + 1)
    else
        return ""
    end
    local scroll_bar_element = scroll_bar_blocks[scroll_bar_element_num]
    local scroll_bar = string.rep(scroll_bar_element, 2)

    return mode_hl_reverse .. scroll_bar
end

M.cursor_position = function()
    local current_line = fn.line "."
    local total_lines = fn.line "$"
    local ratio_line = current_line .. "/" .. total_lines

    local mode_hl_name = M.modes[vim.api.nvim_get_mode().mode][2]
    local mode_hl = "%#" .. mode_hl_name .. "#"
    local mode_hl_sep = "%#" .. mode_hl_name .. "_Sep" .. "#"

    local percentage = math.modf((current_line / total_lines) * 100) .. tostring "%%"

    return mode_hl_sep .. sep_r .. mode_hl .. " " .. mode_hl .. ratio_line .. " " .. percentage .. " "
end

return M
