return function(terminal)
    hl.env("XCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_SIZE", "24")
    hl.env("TERMINAL", terminal)
    -- Let Qt resolve icons and widgets through GTK.
    hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
end
