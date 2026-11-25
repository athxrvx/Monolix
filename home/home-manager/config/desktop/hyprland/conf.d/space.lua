
return function()
    -- Use Kuro's Quickshell workspace overview for Super+Tab.
    hl.bind("SUPER + TAB", hl.dsp.exec_cmd("qs -c shell ipc call overview toggle"), {
        description = "Toggle Kuro workspace overview",
    })
end
