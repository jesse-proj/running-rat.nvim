local M = {}
M.rats_list = {}
local conf = {character="ᓚᘏᕐᐷ", speed=10, width=4, height=1, color="#a89732", blend=100}

-- TODO: a mode to wreck the current buffer?
local scurry = function(rat, speed)
    local timer = vim.loop.new_timer()
    local new_rat = { name = rat, timer = timer }
    table.insert(M.rats_list, new_rat)

    local scurry_period = 1000 / (speed or conf.speed)
    vim.loop.timer_start(timer, 1000, scurry_period, vim.schedule_wrap(function()
        if vim.api.nvim_win_is_valid(rat) then
            local config = vim.api.nvim_win_get_config(rat)
            local col, row = 0, 0
            if vim.version().minor < 10 then -- Neovim 0.9
                col, row = config["col"][false], config["row"][false]
            else -- Neovim 0.10
                col, row = config["col"], config["row"]
            end

            math.randomseed(os.time() * rat)
            local angle = 2 * math.pi * math.random()
            local s = math.sin(angle)
            local c = math.cos(angle)

            if row < 0 and s < 0 then
              row = vim.o.lines
            end

            if row > vim.o.lines  and s > 0 then
              row = 0
            end

            if col < 0 and c < 0 then
              col = vim.o.columns
            end

            if col > vim.o.columns and c > 0 then
              col = 0
            end

            config["row"] = row + 0.5 * s
            config["col"] = col + 1 * c

            vim.api.nvim_win_set_config(rat, config)
        end
    end))
end

M.hatch = function(character, speed, color)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf , 0, 1, true , {character or conf.character})

    local rat = vim.api.nvim_open_win(buf, false, {
        relative='cursor', style='minimal', row=1, col=1, width=conf.width, height=conf.height
    })
    vim.cmd("hi Rat"..rat.." guifg=" .. (color or conf.color) .. " guibg=none blend=" .. conf.blend)
    vim.api.nvim_win_set_option(rat, 'winhighlight', 'Normal:Rat'..rat)

    scurry(rat, speed)
end

M.cook = function()
    local last_rat = M.rats_list[#M.rats_list]

    if not last_rat then
        vim.notify("No rats to catch!")
        return
    end

    local rat = last_rat['name']
    local timer = last_rat['timer']
    table.remove(M.rats_list, #M.rats_list)
    timer:stop()

    vim.api.nvim_win_close(rat, true)
end

M.cook_all = function()
    if #M.rats_list <= 0 then
        vim.notify("No rats to catch!")
        return
    end

    while (#M.rats_list > 0) do
        M.cook()
    end
end

M.setup = function(opts)
    conf = vim.tbl_deep_extend('force', conf, opts or {})
end

return M
