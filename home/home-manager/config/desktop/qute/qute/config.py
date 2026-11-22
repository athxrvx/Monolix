import kuro

# Load existing settings made via :set
config.load_autoconfig()

# Apply Kuro Jellybeans theme
kuro.apply(c, {
    'spacing': {
        'vertical': 6,
        'horizontal': 8
    }
})

