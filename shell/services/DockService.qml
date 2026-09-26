pragma Singleton
import QtQuick
import Quickshell

// Edit this to match what you actually run. Matched against desktop
// entry ids via heuristicLookup, not against pretty display names.
//
// VSCode's id depends on how it's installed:
//   - Arch package `code` (OSS build)        -> "code"
//   - AUR `visual-studio-code-bin`           -> "code"
//   - Flatpak com.visualstudio.code          -> "com.visualstudio.code"
//   - Microsoft's own .deb/rpm repo build     -> "com.microsoft.vscode"  (Flatpak-style id baked into its own .desktop file, this is what
//      was actually installed here, hence "com.microsoft.vscode" showing
//      up raw in the dock instead of a pretty name — heuristicLookup
//      couldn't match the pinned id "code" against it.)
QtObject {
	readonly property var pinnedIds:
	[
		"kitty",
		"zen",
		"org.kde.dolphin",
		"com.microsoft.vscode"
	]

    function toplevelsFor(entryId) {
        const toplevels = WindowService.toplevels ? WindowService.toplevels.values : []
        return toplevels.filter(function (tl) {
            const match = DesktopEntries.heuristicLookup(tl.appId)
            return match && match.id === entryId
        })
    }

    // Each item: { entry, pinned, running, toplevel }
    // entry may be null for a running app with no matching desktop
    // file, toplevel is the first running instance if there is one.
    readonly property var items: {
        const result = []
        const seen = new Set()

        for (let i = 0; i < pinnedIds.length; i++) {
            const entry = DesktopEntries.heuristicLookup(pinnedIds[i])
            if (!entry || seen.has(entry.id)) continue
            const running = toplevelsFor(entry.id)
            result.push({
                entry: entry,
                pinned: true,
                running: running.length > 0,
                toplevel: running.length > 0 ? running[0] : null
            })
            seen.add(entry.id)
        }

        const toplevels = WindowService.toplevels ? WindowService.toplevels.values : []
        for (let i = 0; i < toplevels.length; i++) {
            const tl = toplevels[i]
            const entry = DesktopEntries.heuristicLookup(tl.appId)
            const id = entry ? entry.id : tl.appId
            if (seen.has(id)) continue
            seen.add(id)
            result.push({
                entry: entry,
                pinned: false,
                running: true,
                toplevel: tl
            })
        }

        return result
    }
}
