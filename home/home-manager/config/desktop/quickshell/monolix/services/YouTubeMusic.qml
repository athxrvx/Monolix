pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string query: ""
    property string error: ""
    property list<var> results: []
    property string _searchOutput: ""
    property string selectedTitle: ""
    property string selectedArtist: ""
    property string selectedAlbum: ""
    property string selectedArt: ""

    function search(value: string): void {
        query = value.trim();
        error = "";
        if (!query) {
            results = [];
            return;
        }
        results = [];
        _searchOutput = "";
        if (searchProcess.running)
            searchProcess.running = false;
        searchProcess.command = [
            "yt-dlp", "--no-warnings", "--quiet", "--skip-download",
            "--flat-playlist", "--dump-single-json", "--playlist-end", "12",
            `ytsearch12:${query}`
        ];
        searchProcess.running = true;
    }

    function play(track: var): void {
        if (!track || !track.url)
            return;
        selectedTitle = track.title || qsTr("YouTube Music");
        selectedArtist = track.artist || qsTr("YouTube Music");
        selectedAlbum = "";
        selectedArt = track.art || "";
        Quickshell.execDetached([
            "mpv", "--no-video", "--force-window=no",
            "--ytdl-format=bestaudio/best", "--title=Monolix YouTube Music", track.url
        ]);
    }

    function finishSearch(exitCode: int): void {
        if (exitCode !== 0) {
            error = qsTr("YouTube Music search failed. Check your internet connection and try again.");
            results = [];
            return;
        }
        try {
            const data = JSON.parse(_searchOutput);
            results = (data.entries || []).filter(entry => entry && entry.id).map(entry => ({
                id: entry.id,
                url: entry.webpage_url || entry.url || `https://www.youtube.com/watch?v=${entry.id}`,
                title: entry.title || qsTr("Untitled video"),
                artist: entry.uploader || entry.channel || qsTr("YouTube Music"),
                duration: Number(entry.duration || 0),
                art: entry.thumbnail || entry.thumbnails?.[0]?.url || ""
            }));
            error = "";
        } catch (e) {
            results = [];
            error = qsTr("YouTube Music returned an unreadable search result.");
        }
    }

    Process {
        id: searchProcess
        running: false
        stdout: StdioCollector { onStreamFinished: root._searchOutput = text }
        onExited: (code) => root.finishSearch(code)
    }
}
