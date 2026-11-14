pragma Singleton

import qs.config
import qs.utils
import QtQuick

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${Config.launcher.actionPrefix}variant `.length);
    }

    function setVariant(variantName: string): void {
        Schemes.setVariant(variantName);
    }

    list: [
        Variant {
            variant: "default"
            icon: "palette"
            name: qsTr("Original")
            description: qsTr("Use the selected color scheme without changes.")
        },
        Variant {
            variant: "neutral"
            icon: "contrast"
            name: qsTr("Neutral")
            description: qsTr("A muted version of the selected color scheme.")
        },
        Variant {
            variant: "monochrome"
            icon: "filter_b_and_w"
            name: qsTr("Monochrome")
            description: qsTr("A muted grayscale palette with one accent from the selected scheme.")
        },
        Variant {
            variant: "expressive"
            icon: "tonality"
            name: qsTr("Expressive")
            description: qsTr("A more saturated, expressive version of the selected color scheme.")
        }
    ]
    useFuzzy: Config.launcher.useFuzzy.variants

    component Variant: QtObject {
        required property string variant
        required property string icon
        required property string name
        required property string description

        function onClicked(list: var): void {
            list.visibilities.launcher = false;
            root.setVariant(variant);
        }
    }
}
