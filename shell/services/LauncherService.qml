pragma Singleton
import QtQuick
import Quickshell

// Same pattern as WindowService/DockService: UI never touches
// DesktopEntries or does its own matching, it only ever reads
// `results` and writes `query`.
//
// Fuzzy match is a plain subsequence scorer (not a full Levenshtein/
// Smith-Waterman implementation) — "chr" matches "Chromium" and
// "krm" matches "Kitty Terminal" is NOT a goal, this only needs to
// beat a substring search for typo tolerance and partial typing,
// which a subsequence match with a contiguity bonus does well enough.
QtObject {
    id: root

    property bool visible: false
    property string query: ""
    readonly property int maxResults: 8

    function toggle() {
        root.visible = !root.visible
        if (root.visible) root.query = ""
    }
    function show() {
        root.query = ""
        root.visible = true
    }
    function hide() {
        root.visible = false
    }

    // DesktopEntries.applications is a Quickshell ObjectModel; .values
    // is the reactive array view, same reason Bar.qml reads
    // Networking.devices.values instead of iterating the model directly.
    readonly property var allApps: DesktopEntries.applications.values

    // Returns -1 for "not a match", otherwise a positive score where
    // higher is better. Case-insensitive subsequence match: every
    // character of `q`, in order, must appear somewhere in `name`.
    function score(name, q) {
        if (!name) return -1
        const n = name.toLowerCase()
        const query = q.toLowerCase()
        if (query.length === 0) return 0

        let ni = 0
        let qi = 0
        let total = 0
        let streak = 0

        while (ni < n.length && qi < query.length) {
            if (n[ni] === query[qi]) {
                streak += 1
                total += 10 + streak * 5 // reward consecutive matches
                qi += 1
            } else {
                streak = 0
            }
            ni += 1
        }

        if (qi < query.length) return -1 // ran out of name before matching all of q

        if (n.indexOf(query) === 0) total += 50 // prefix bonus, e.g. "fire" -> "Firefox"
        return total
    }

    // Empty query: alphabetical, capped list (so the launcher isn't
    // empty the instant it opens). Non-empty query: ranked by score,
    // best first.
    readonly property var results: {
        const apps = root.allApps
        if (root.query.length === 0) {
            return apps.slice()
                .sort((a, b) => (a.name || "").localeCompare(b.name || ""))
                .slice(0, root.maxResults)
        }

        const scored = []
        for (let i = 0; i < apps.length; i++) {
            const s = root.score(apps[i].name, root.query)
            if (s >= 0) scored.push({ entry: apps[i], s: s })
        }
        scored.sort((a, b) => b.s - a.s)
        return scored.slice(0, root.maxResults).map(x => x.entry)
    }
}
