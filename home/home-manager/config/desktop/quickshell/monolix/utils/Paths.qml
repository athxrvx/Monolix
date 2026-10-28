pragma Singleton

import qs.config
import Monolix
import Quickshell

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string pictures: Quickshell.env("XDG_PICTURES_DIR") || `${home}/Pictures`

    readonly property string data: `${Quickshell.env("XDG_DATA_HOME") || `${home}/.local/share`}/monolix`
    readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`}/monolix`
    readonly property string cache: `${Quickshell.env("XDG_CACHE_HOME") || `${home}/.cache`}/monolix`
    readonly property string config: `${Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`}/monolix`

    readonly property string imagecache: `${cache}/imagecache`
    readonly property string notificationsData: `${data}/notifications.json`
    readonly property string wallsdir: Quickshell.env("MONOLIX_WALLPAPERS_DIR") || absolutePath(Config.paths.wallpaperDir)
    readonly property string libdir: Quickshell.env("MONOLIX_LIB_DIR") || "/usr/lib/monolix"

    function toLocalFile(path: url): string {
        path = Qt.resolvedUrl(path);
        return path.toString() ? CUtils.toLocalFile(path) : "";
    }

    function absolutePath(path: string): string {
        return toLocalFile(path.replace("~", home));
    }

    function shortenHome(path: string): string {
        return path.replace(home, "~");
    }
}
