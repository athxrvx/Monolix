def apply(c, options=None):
    if options is None:
        options = {}

    palette = {
        'background': '#0d0d0d',
        'background-alt': '#151515',
        'background-attention': '#151515',
        'border': '#303030',
        'current-line': '#303030',
        'selection': '#fad07a',

        'foreground': '#dedede',
        'foreground-alt': '#888888',
        'foreground-attention': '#ffffff',

        'comment': '#888888',
        'cyan': '#00988e',
        'green': '#94b979',
        'orange': '#ffa560',
        'pink': '#e1c0fa',
        'purple': '#e1c0fa',
        'red': '#e27373',
        'yellow': '#ffba7b',
        'blue': '#97bedc',
        'accent': '#8a694c',
    }

    spacing = options.get('spacing', {
        'vertical': 6,
        'horizontal': 8
    })

    padding = options.get('padding', {
        'top': spacing['vertical'],
        'right': spacing['horizontal'],
        'bottom': spacing['vertical'],
        'left': spacing['horizontal']
    })

    # Fonts
    c.fonts.default_family = 'JetBrainsMono Nerd Font'
    c.fonts.default_size = '10pt'
    c.fonts.completion.entry = '10pt JetBrainsMono Nerd Font'
    c.fonts.completion.category = 'bold 10pt JetBrainsMono Nerd Font'
    c.fonts.statusbar = '10pt JetBrainsMono Nerd Font'
    c.fonts.tabs.selected = '10pt JetBrainsMono Nerd Font'
    c.fonts.tabs.unselected = '10pt JetBrainsMono Nerd Font'
    c.fonts.prompts = '10pt JetBrainsMono Nerd Font'
    c.fonts.hints = 'bold 9pt JetBrainsMono Nerd Font'
    c.fonts.keyhint = '10pt JetBrainsMono Nerd Font'
    c.fonts.messages.error = '10pt JetBrainsMono Nerd Font'
    c.fonts.messages.info = '10pt JetBrainsMono Nerd Font'
    c.fonts.messages.warning = '10pt JetBrainsMono Nerd Font'

    # Completion
    c.colors.completion.category.bg = palette['background-alt']
    c.colors.completion.category.border.bottom = palette['border']
    c.colors.completion.category.border.top = palette['border']
    c.colors.completion.category.fg = palette['orange']

    c.colors.completion.even.bg = palette['background']
    c.colors.completion.odd.bg = palette['background-alt']
    c.colors.completion.fg = palette['foreground']

    c.colors.completion.item.selected.bg = palette['current-line']
    c.colors.completion.item.selected.border.bottom = palette['current-line']
    c.colors.completion.item.selected.border.top = palette['current-line']
    c.colors.completion.item.selected.fg = palette['selection']

    c.colors.completion.match.fg = palette['orange']
    c.colors.completion.scrollbar.bg = palette['background']
    c.colors.completion.scrollbar.fg = palette['foreground-alt']

    # Downloads
    c.colors.downloads.bar.bg = palette['background']
    c.colors.downloads.error.bg = palette['background']
    c.colors.downloads.error.fg = palette['red']
    c.colors.downloads.stop.bg = palette['background']
    c.colors.downloads.system.bg = 'none'

    # Hints
    c.colors.hints.bg = palette['selection']
    c.colors.hints.fg = palette['background']
    c.colors.hints.match.fg = palette['red']
    c.hints.border = '1px solid ' + palette['border']

    # Key hints
    c.colors.keyhint.bg = palette['background']
    c.colors.keyhint.fg = palette['orange']
    c.colors.keyhint.suffix.fg = palette['selection']

    # Messages
    c.colors.messages.error.bg = palette['background']
    c.colors.messages.error.border = palette['border']
    c.colors.messages.error.fg = palette['red']

    c.colors.messages.info.bg = palette['background']
    c.colors.messages.info.border = palette['border']
    c.colors.messages.info.fg = palette['cyan']

    c.colors.messages.warning.bg = palette['background']
    c.colors.messages.warning.border = palette['border']
    c.colors.messages.warning.fg = palette['yellow']

    # Prompts
    c.colors.prompts.bg = palette['background']
    c.colors.prompts.border = '1px solid ' + palette['border']
    c.colors.prompts.fg = palette['foreground']
    c.colors.prompts.selected.bg = palette['current-line']

    # Status bar
    c.colors.statusbar.caret.bg = palette['background-alt']
    c.colors.statusbar.caret.fg = palette['orange']
    c.colors.statusbar.caret.selection.bg = palette['current-line']
    c.colors.statusbar.caret.selection.fg = palette['selection']

    c.colors.statusbar.command.bg = palette['background']
    c.colors.statusbar.command.fg = palette['orange']
    c.colors.statusbar.command.private.bg = palette['background-alt']
    c.colors.statusbar.command.private.fg = palette['pink']

    c.colors.statusbar.insert.bg = palette['selection']
    c.colors.statusbar.insert.fg = palette['background']

    c.colors.statusbar.normal.bg = palette['background']
    c.colors.statusbar.normal.fg = palette['foreground']

    c.colors.statusbar.passthrough.bg = palette['background']
    c.colors.statusbar.passthrough.fg = palette['cyan']

    c.colors.statusbar.private.bg = palette['background-alt']
    c.colors.statusbar.private.fg = palette['pink']

    c.colors.statusbar.progress.bg = palette['accent']

    c.colors.statusbar.url.error.fg = palette['red']
    c.colors.statusbar.url.fg = palette['blue']
    c.colors.statusbar.url.hover.fg = palette['cyan']
    c.colors.statusbar.url.success.http.fg = palette['green']
    c.colors.statusbar.url.success.https.fg = palette['green']
    c.colors.statusbar.url.warn.fg = palette['yellow']

    c.statusbar.padding = padding

    # Tabs
    c.colors.tabs.bar.bg = palette['background']

    c.colors.tabs.even.bg = palette['background-alt']
    c.colors.tabs.even.fg = palette['foreground-alt']

    c.colors.tabs.odd.bg = palette['background-alt']
    c.colors.tabs.odd.fg = palette['foreground-alt']

    c.colors.tabs.selected.even.bg = palette['background']
    c.colors.tabs.selected.even.fg = palette['selection']

    c.colors.tabs.selected.odd.bg = palette['background']
    c.colors.tabs.selected.odd.fg = palette['selection']

    c.colors.tabs.indicator.error = palette['red']
    c.colors.tabs.indicator.start = palette['accent']
    c.colors.tabs.indicator.stop = palette['green']
    c.colors.tabs.indicator.system = 'none'

    # Tab sizing
    c.tabs.padding = padding
    c.tabs.indicator.width = 1
    c.tabs.favicons.scale = 1

