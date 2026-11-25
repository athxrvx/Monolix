return function()
    hl.config({
        -- Binary space partitioning.
        dwindle = {
            force_split = 0,
            preserve_split = true,
            smart_split = false,
            smart_resizing = true,
            default_split_ratio = 1.0,
            split_width_multiplier = 1.0,
        },

        -- Horizontally scrolling columns.
        scrolling = {
            fullscreen_on_one_column = true,
            column_width = 0.75,
            direction = "right",
            focus_fit_method = 1,
            follow_focus = 1,
            explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
            wrap_focus = true,
            wrap_swapcol = true,
        },
    })
end
