pragma Singleton

import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Searcher {
    id: root

    property string currentScheme
    property string currentVariant
    // Path to the schemes data JSON file (bundled with the shell)
    readonly property string schemesDataPath: Qt.resolvedUrl("scheme.json")
    // Path to store current scheme state
    readonly property string schemeStatePath: `${Paths.state}/scheme.json`

    // Convert snake_case to camelCase
    function snakeToCamel(str: string): string {
        return str.replace(/_([a-z])/g, (match, letter) => letter.toUpperCase());
    }

    function transformMatugenOutput(data: var, mode: string): var {
        const colours = {};
        const matugenColors = data.colors;

        for (const [name, values] of Object.entries(matugenColors)) {
            const camelName = snakeToCamel(name);
            // Get the color for the specified mode
            let colorObj = values[mode] || values["default"];
            
            // Handle matugen 4.0.0 structure where color is nested in an object
            let hexColor = (typeof colorObj === 'object' && colorObj !== null) ? colorObj.color : colorObj;
            
            if (hexColor && typeof hexColor === 'string') {
                colours[camelName] = hexColor.replace("#", "");
            }
        }

        // Add palette key colors from palettes if available
        if (data.palettes) {
            const palettes = data.palettes;
            const extractPaletteColor = (p) => {
                if (!p || !p["40"]) return "";
                let val = p["40"];
                return (typeof val === 'object' && val !== null ? val.color : val).replace("#", "");
            };

            if (palettes.primary) colours["primary_paletteKeyColor"] = extractPaletteColor(palettes.primary);
            if (palettes.secondary) colours["secondary_paletteKeyColor"] = extractPaletteColor(palettes.secondary);
            if (palettes.tertiary) colours["tertiary_paletteKeyColor"] = extractPaletteColor(palettes.tertiary);
            if (palettes.neutral) colours["neutral_paletteKeyColor"] = extractPaletteColor(palettes.neutral);
            if (palettes.neutral_variant) colours["neutral_variant_paletteKeyColor"] = extractPaletteColor(palettes.neutral_variant);
        }

        // Add success colors (not in matugen)
        if (mode === "light") {
            colours["success"] = "4F6354";
            colours["onSuccess"] = "FFFFFF";
            colours["successContainer"] = "D1E8D5";
            colours["onSuccessContainer"] = "0C1F13";
        } else {
            colours["success"] = "B5CCBA";
            colours["onSuccess"] = "213528";
            colours["successContainer"] = "374B3E";
            colours["onSuccessContainer"] = "D1E9D6";
        }

        return colours;
    }

    function transformSearch(search: string): string {
        return search.slice(`${Config.launcher.actionPrefix}scheme `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.flavour}`;
    }

    function reload(): void {
        schemeStateFile.reload();
    }

    function base16Colours(palette: var): var {
        const light = palette.mode === "light";
        const foreground = palette.base05;
        const background = palette.base00;
        const buttonForeground = light ? palette.base07 : palette.base00;
        const container = light ? palette.base01 : palette.base02;
        const softContainer = light ? palette.base02 : palette.base01;

        return {
            primary_paletteKeyColor: palette.base0D,
            secondary_paletteKeyColor: palette.base0B,
            tertiary_paletteKeyColor: palette.base09,
            neutral_paletteKeyColor: palette.base03,
            neutral_variant_paletteKeyColor: palette.base04,
            background,
            onBackground: foreground,
            surface: background,
            surfaceDim: background,
            surfaceBright: palette.base02,
            surfaceContainerLowest: light ? palette.base07 : background,
            surfaceContainerLow: palette.base01,
            surfaceContainer: palette.base01,
            surfaceContainerHigh: palette.base02,
            surfaceContainerHighest: light ? palette.base02 : palette.base03,
            onSurface: foreground,
            surfaceVariant: palette.base02,
            onSurfaceVariant: palette.base04,
            inverseSurface: foreground,
            inverseOnSurface: background,
            outline: palette.base03,
            outlineVariant: palette.base02,
            shadow: background,
            scrim: background,
            surfaceTint: palette.base0D,
            primary: palette.base0D,
            onPrimary: buttonForeground,
            primaryContainer: container,
            onPrimaryContainer: light ? palette.base07 : foreground,
            inversePrimary: palette.base04,
            secondary: palette.base0B,
            onSecondary: buttonForeground,
            secondaryContainer: container,
            onSecondaryContainer: light ? palette.base07 : foreground,
            tertiary: palette.base09,
            onTertiary: buttonForeground,
            tertiaryContainer: container,
            onTertiaryContainer: light ? palette.base07 : foreground,
            error: palette.base08,
            onError: buttonForeground,
            errorContainer: container,
            onErrorContainer: light ? palette.base07 : foreground,
            primaryFixed: palette.base0D,
            primaryFixedDim: palette.base0D,
            onPrimaryFixed: buttonForeground,
            onPrimaryFixedVariant: buttonForeground,
            secondaryFixed: palette.base0B,
            secondaryFixedDim: palette.base0B,
            onSecondaryFixed: buttonForeground,
            onSecondaryFixedVariant: buttonForeground,
            tertiaryFixed: palette.base09,
            tertiaryFixedDim: palette.base09,
            onTertiaryFixed: buttonForeground,
            onTertiaryFixedVariant: buttonForeground,
            term0: palette.base00,
            term1: palette.base08,
            term2: palette.base0B,
            term3: palette.base09,
            term4: palette.base0D,
            term5: palette.base0E,
            term6: palette.base0C,
            term7: palette.base05,
            term8: palette.base03,
            term9: palette.base08,
            term10: palette.base0B,
            term11: palette.base0A,
            term12: palette.base0D,
            term13: palette.base0E,
            term14: palette.base0C,
            term15: palette.base07,
            rosewater: palette.base0F,
            flamingo: palette.base0F,
            pink: palette.base0E,
            mauve: palette.base0E,
            red: palette.base08,
            maroon: palette.base08,
            peach: palette.base09,
            yellow: palette.base0A,
            green: palette.base0B,
            teal: palette.base0C,
            sky: palette.base0C,
            sapphire: palette.base0D,
            blue: palette.base0D,
            lavender: palette.base0E,
            klink: palette.base0D,
            klinkSelection: palette.base0D,
            kvisited: palette.base0E,
            kvisitedSelection: palette.base0E,
            knegative: palette.base08,
            knegativeSelection: palette.base08,
            kneutral: palette.base0A,
            kneutralSelection: palette.base0A,
            kpositive: palette.base0B,
            kpositiveSelection: palette.base0B,
            text: foreground,
            subtext1: palette.base04,
            subtext0: palette.base03,
            overlay2: palette.base04,
            overlay1: palette.base03,
            overlay0: palette.base02,
            surface2: palette.base03,
            surface1: palette.base02,
            surface0: softContainer,
            base: background,
            mantle: palette.base01,
            crust: light ? palette.base07 : palette.base00,
            success: palette.base0B,
            onSuccess: buttonForeground,
            successContainer: container,
            onSuccessContainer: light ? palette.base07 : foreground
        };
    }

    // Regenerate dynamic scheme from current wallpaper
    function regenerateDynamic(): void {
        if (root.currentScheme.startsWith("dynamic")) {
            setScheme("dynamic", "default");
        }
    }

    function setVariant(variant: string): void {
        if (root.currentScheme.startsWith("dynamic")) {
            root.currentVariant = variant;
            regenerateDynamic();
            if (Wallpapers.current)
                Wallpapers.runColorGeneration(Wallpapers.current, variant);
            return;
        }

        const [name, flavour] = root.currentScheme.split(" ");
        const scheme = root.list.find(item => item.name === name && item.flavour === flavour);
        if (!scheme) {
            console.warn("Cannot apply color variant: current scheme is unavailable", root.currentScheme);
            return;
        }

        const mode = name === "aofuji" ? "light" : "dark";
        if (variant === "default") {
            const stateData = {
                name: name,
                flavour: flavour,
                mode: mode,
                variant: "default",
                colours: scheme.colours
            };
            root.currentVariant = "default";
            schemeStateWriter.write(JSON.stringify(stateData, null, 2));
            Colours.load(JSON.stringify(stateData), false);
            return;
        }
        variantSchemeGenerator.generate(name, flavour, variant, mode, scheme.colours.primary_paletteKeyColor, scheme.colours);
    }

    // Set a scheme by name and flavour
    function setScheme(name: string, flavour: string): void {
        // Handle dynamic scheme generation
        if (name === "dynamic") {
            const wallpaper = Wallpapers.current;
            console.log("Dynamic scheme: wallpaper =", wallpaper);
            if (!wallpaper) {
                console.warn("Cannot set dynamic scheme: no wallpaper set");
                return;
            }
            const mode = Colours.light ? "light" : "dark";
            const variant = root.currentVariant || "default";
            console.log("Dynamic scheme: variant =", variant, "mode =", mode);

            // Use matugen for color generation from wallpaper (Quickshell UI)
            dynamicSchemeGenerator.wallpaper = wallpaper;
            dynamicSchemeGenerator.variant = variant;
            dynamicSchemeGenerator.mode = mode;
            dynamicSchemeGenerator.run();

            // Also run external color generation for terminal/GTK/apps
            Wallpapers.runColorGeneration(wallpaper, variant);
            return;
        }

        const schemeData = schemesDataFile.json;
        if (!schemeData || !schemeData[name] || !schemeData[name][flavour]) {
            console.warn(`Scheme not found: ${name} ${flavour}`);
            return;
        }

        const colours = schemeData[name][flavour];
        const mode = name === "aofuji" ? "light" : "dark";

        root.currentScheme = `${name} ${flavour}`;
        const variant = root.currentVariant || "default";
        if (variant !== "default") {
            variantSchemeGenerator.generate(name, flavour, variant, mode, colours.primary_paletteKeyColor, colours);
            return;
        }

        // Save to state file
        const stateData = {
            name: name,
            flavour: flavour,
            mode: mode,
            variant: variant,
            colours: colours
        };

        schemeStateWriter.write(JSON.stringify(stateData, null, 2));

        // Load the colours immediately
        Colours.load(JSON.stringify(stateData), false);
    }

    list: schemes.instances
    useFuzzy: Config.launcher.useFuzzy.schemes
    keys: ["name", "flavour"]
    weights: [0.9, 0.1]

    Variants {
        id: schemes

        Scheme {}
    }

    // Load schemes from local JSON file
    FileView {
        id: schemesDataFile

        property var json: null

        path: Qt.resolvedUrl("scheme.json")

        onLoaded: {
            try {
                json = JSON.parse(text());
                const customPalettes = {
                    aofuji: {
                        mode: "light", base00: "f5f7f8", base01: "e9eef0", base02: "dce5e9", base03: "8b9ba3", base04: "687983", base05: "34434b", base06: "26353d", base07: "17252d", base08: "bd4c57", base09: "bd6b3f", base0A: "9b791e", base0B: "4b7964", base0C: "367e83", base0D: "477a9a", base0E: "78698f", base0F: "a45e74"
                    },
                    nothing: {
                        mode: "dark", base00: "101112", base01: "18191b", base02: "232528", base03: "62666b", base04: "85898e", base05: "d9dadd", base06: "eceef0", base07: "ffffff", base08: "e5484d", base09: "ed6a5a", base0A: "f0b44d", base0B: "9bb477", base0C: "74aeb5", base0D: "7c9db8", base0E: "b095c7", base0F: "c38b72"
                    },
                    oled: {
                        mode: "dark", base00: "000000", base01: "080808", base02: "141414", base03: "555555", base04: "858585", base05: "dedede", base06: "f2f2f2", base07: "ffffff", base08: "ff6b7a", base09: "ff9b62", base0A: "f4d35e", base0B: "9bd576", base0C: "61d6c6", base0D: "83b8ff", base0E: "c4a1ff", base0F: "e89bba"
                    },
                    yoru: {
                        mode: "dark",
                        base00: "0c0e0f", base01: "121415", base02: "161819", base03: "1f2122", base04: "27292a",
                        base05: "edeff0", base06: "e4e6e7", base07: "f2f4f5",
                        base08: "f26e74", base09: "ecd28b", base0A: "e79881", base0B: "82c29c",
                        base0C: "6791C9", base0D: "709ad2", base0E: "c58cec", base0F: "e8646a",
                        monolix: {
                            // Use Yoru's stepped charcoal surfaces explicitly and
                            // lift secondary text so it stays readable on cards.
                            surfaceContainer: "161819",
                            surfaceContainerHigh: "1f2122",
                            surfaceContainerHighest: "27292a",
                            surfaceVariant: "1f2122",
                            onSurfaceVariant: "a5aaac",
                            outline: "343637",
                            outlineVariant: "27292a"
                        }
                    }
                };

                for (const [name, palette] of Object.entries(customPalettes)) {
                    const colours = root.base16Colours(palette);
                    if (palette.monolix)
                        Object.assign(colours, palette.monolix);
                    json[name] = { default: colours };
                }

                const allowedNames = ["jellybeans", "aofuji", "nothing", "oled", "yoru"];
                schemesDataFile.json = json;
                schemes.model = allowedNames.map(name => ({
                    name,
                    flavour: "default",
                    colours: json[name]?.default ?? {}
                }));
            } catch (e) {
                console.error("Failed to parse schemes data:", e);
            }
        }
    }

    // Load current scheme state from state file
    FileView {
        id: schemeStateFile

        path: root.schemeStatePath
        watchChanges: true

        onLoaded: {
            try {
                const state = JSON.parse(text());
                if (!["jellybeans", "aofuji", "nothing", "oled", "yoru"].includes(state.name)) {
                    Qt.callLater(() => root.setScheme("yoru", "default"));
                } else {
                    root.currentScheme = `${state.name} ${state.flavour}`;
                    const savedVariant = state.variant || "default";
                    const allowedVariants = ["default", "neutral", "monochrome", "expressive"];
                    root.currentVariant = allowedVariants.includes(savedVariant) ? savedVariant : "default";
                    if (root.currentVariant !== savedVariant)
                        Qt.callLater(() => root.setScheme(state.name, state.flavour));
                }
            } catch (e) {
                // State file doesn't exist or is invalid, use defaults
                root.currentScheme = "yoru default";
                root.currentVariant = "default";
                Qt.callLater(() => root.setScheme("yoru", "default"));
            }
        }

        onFileChanged: reload()
    }

    // Process for ensuring state directory exists before writing
    Process {
        id: schemeStateWriter

        property string _pendingContent

        command: ["mkdir", "-p", Paths.state]
        running: false

        function write(content: string): void {
            _pendingContent = content;
            schemeStateWriter.running = true;
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && _pendingContent) {
                schemeStateFile.watchChanges = false;
                schemeStateFile.setText(_pendingContent);
                schemeStateFile.watchChanges = true;
            }
        }
    }

    // Process for generating dynamic scheme from wallpaper using matugen
    Process {
        id: dynamicSchemeGenerator

        property string wallpaper
        property string variant
        property string mode
        property string outputBuffer: ""
        property int retryCount: 0

        running: false

        function run(): void {
            outputBuffer = "";
            // Convert variant name to matugen type
            let matugenType = "scheme-tonal-spot";
            const variantMap = {
                "content": "scheme-content",
                "expressive": "scheme-expressive",
                "fidelity": "scheme-fidelity",
                "fruitsalad": "scheme-fruit-salad",
                "monochrome": "scheme-monochrome",
                "neutral": "scheme-neutral",
                "rainbow": "scheme-rainbow",
                "default": "scheme-tonal-spot",
                "tonalspot": "scheme-tonal-spot",
                "vibrant": "scheme-vibrant"
            };
            if (variantMap[variant]) {
                matugenType = variantMap[variant];
            }

            const colorSource = Wallpapers.getColorSource(wallpaper);
            command = ["matugen", "image", colorSource, "--dry-run", "--json", "hex", "--mode", mode, "--type", matugenType, "--source-color-index", "0"];
            
            // If it's a video and the frame might not exist yet, we should check/retry
            if (Wallpapers.isPathVideo(wallpaper)) {
                console.log("Checking for video frame:", colorSource);
                // We'll let matugen try, and if it fails, we use the retry timer
            }
            
            console.log("Running matugen:", JSON.stringify(command));
            running = true;
        }

        stdout: SplitParser {
            onRead: data => {
                dynamicSchemeGenerator.outputBuffer += data;
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.error("Matugen exited with code:", exitCode);
                return;
            }

            console.log("Matugen output length:", outputBuffer.length);
            try {
                const matugenData = JSON.parse(outputBuffer);
                const colours = root.transformMatugenOutput(matugenData, mode);
                const stateData = {
                    name: "dynamic",
                    flavour: "default",
                    mode: mode,
                    variant: variant,
                    colours: colours
                };

                schemeStateWriter.write(JSON.stringify(stateData, null, 2));
                root.currentScheme = "dynamic default";
                Colours.load(JSON.stringify(stateData), false);
            } catch (e) {
                console.error("Failed to parse matugen output:", e);
            }
        }

        stderr: SplitParser {
            onRead: data => {
                console.error("Matugen error:", data);
            }
        }
    }

    Process {
        id: variantSchemeGenerator

        property string outputBuffer: ""
        property string schemeName: ""
        property string schemeFlavour: "default"
        property string variant: "default"
        property string mode: "dark"
        property string seedColor: ""
        property var baseColours: ({})

        function generate(name: string, flavour: string, variantName: string, colorMode: string, seed: string, originalColours: var): void {
            if (running) {
                console.warn("A color variant is already being generated");
                return;
            }

            outputBuffer = "";
            schemeName = name;
            schemeFlavour = flavour;
            variant = variantName;
            mode = colorMode;
            seedColor = seed.startsWith("#") ? seed : `#${seed}`;
            baseColours = originalColours;

            command = [
                "matugen", "color", "hex", seedColor,
                "--dry-run", "--json", "hex", "--mode", mode,
                "--type", Wallpapers.variantToMatugenType(variant)
            ];
            console.log("Generating Material color variant:", variant, "from", seedColor, "for", schemeName);
            running = true;
        }

        stdout: SplitParser {
            onRead: data => variantSchemeGenerator.outputBuffer += data;
        }

        stderr: SplitParser {
            onRead: data => console.error("Matugen variant error:", data);
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.error("Matugen color variant exited with code:", exitCode);
                return;
            }

            try {
                const data = JSON.parse(outputBuffer);
                const generatedColours = root.transformMatugenOutput(data, mode);
                const colours = Object.assign({}, baseColours, generatedColours);

                // Keep the selected theme's primary color as the single accent
                // while Matugen supplies a grayscale base for monochrome.
                if (variant === "monochrome") {
                    const accentRoles = [
                        "primary_paletteKeyColor", "primary", "onPrimary", "primaryContainer",
                        "onPrimaryContainer", "inversePrimary", "surfaceTint", "primaryFixed",
                        "primaryFixedDim", "onPrimaryFixed", "onPrimaryFixedVariant"
                    ];
                    for (const key of accentRoles) {
                        if (baseColours[key] !== undefined)
                            colours[key] = baseColours[key];
                    }
                }
                const stateData = {
                    name: schemeName,
                    flavour: schemeFlavour,
                    mode: mode,
                    variant: variant,
                    colours: colours
                };

                root.currentScheme = `${schemeName} ${schemeFlavour}`;
                root.currentVariant = variant;
                schemeStateWriter.write(JSON.stringify(stateData, null, 2));
                Colours.load(JSON.stringify(stateData), false);
            } catch (e) {
                console.error("Failed to apply Material color variant:", e);
            }
        }
    }

    component Scheme: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string flavour: modelData.flavour
        readonly property var colours: modelData.colours

        function onClicked(list: var): void {
            list.visibilities.launcher = false;
            root.setScheme(name, flavour);
        }
    }
}
