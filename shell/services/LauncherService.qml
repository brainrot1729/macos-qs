pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root

    property bool visible: false
    property string query: ""

    readonly property var allApps: DesktopEntries.applications.values

    function normalize(value) {
        return String(value || "")
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, " ")
            .trim()
    }

    function wordList(value) {
        const normalized = root.normalize(value)

        if (normalized.length === 0)
            return []

        return normalized.split(/\s+/)
    }

    /*
     * Matches characters in order, but not necessarily next to each other.

     * Examples:
     *
     *   "chr"  -> "chromium"
     *   "vsc"  -> "visual studio code"
     *   "term" -> "kitty terminal"
     *
     * Returns -1 when the query cannot be matched.
     */
    function scoreSubsequence(query, text) {
        if (query.length === 0)
            return 0

        if (text.length === 0)
            return -1

        let queryIndex = 0
        let score = 0
        let previousMatchIndex = -1

        for (let textIndex = 0;
             textIndex < text.length && queryIndex < query.length;
             ++textIndex) {

            if (text[textIndex] !== query[queryIndex])
                continue

            const atWordStart =
                textIndex === 0 ||
                text[textIndex - 1] === " " ||
                text[textIndex - 1] === "-" ||
                text[textIndex - 1] === "_" ||
                text[textIndex - 1] === "/" ||
                text[textIndex - 1] === "."

            // Matching the beginning of a word is useful for acronyms
            // such as "vsc" -> "visual studio code".
            if (atWordStart)
                score += 25

            // Consecutive characters are a stronger match.
            if (previousMatchIndex === textIndex - 1)
                score += 30
            else
                score += 3

            // Prefer matches near the beginning of the field.
            score += Math.max(0, 12 - textIndex)

            previousMatchIndex = textIndex
            queryIndex++
        }

        if (queryIndex !== query.length)
            return -1

        return score
    }

    /*
     * Scores one metadata field.

     * Higher weight means that the field is more important.
     */
    function scoreField(query, field, weight) {
        const text = root.normalize(field)

        if (text.length === 0)
            return -1

        // Exact field match.
        if (text === query)
            return 10000 * weight

        // The field starts with the query.
        if (text.indexOf(query) === 0)
            return 6000 * weight

        // A normal substring match.
        const substringIndex = text.indexOf(query)

        if (substringIndex !== -1) {
            return (3500 - substringIndex * 8) * weight
        }

        // Finally try fuzzy subsequence matching.
        const subsequenceScore = root.scoreSubsequence(query, text)

        if (subsequenceScore !== -1)
            return subsequenceScore * weight

        return -1
    }

    function scoreEntry(query, entry) {
        const name = entry.name || ""
        const genericName = entry.genericName || ""
        const comment = entry.comment || ""
        const keywords = (entry.keywords || []).join(" ")

        /*
         * Name is intentionally weighted much more strongly than the
         * description or keywords.
         */
        const fieldScores = [
            root.scoreField(query, name, 10),
            root.scoreField(query, genericName, 5),
            root.scoreField(query, keywords, 4),
            root.scoreField(query, comment, 2)
        ]

        let bestScore = -1

        for (let i = 0; i < fieldScores.length; ++i)
            bestScore = Math.max(bestScore, fieldScores[i])

        if (bestScore < 0)
            return -1

        /*
         * Give an extra bonus when a query starts a word in the
         * application name.
         *
         * For example, "vsc" should rank "Visual Studio Code" highly.
         */
        const nameWords = root.wordList(name)
        const queryWords = root.wordList(query)

        if (queryWords.length === 1) {
            for (let i = 0; i < nameWords.length; ++i) {
                if (nameWords[i].indexOf(queryWords[0]) === 0)
                    bestScore += 800
            }
        }

        /*
         * Prefer shorter names when otherwise equally matched.
         */
        bestScore -= Math.min(name.length, 100) * 0.1

        return bestScore
    }

    readonly property var results: {
        const normalizedQuery = root.normalize(root.query)

        return root.allApps
            .filter(function (entry) {
                return entry && !entry.noDisplay
            })
            .map(function (entry) {
                return {
                    entry: entry,
                    score: normalizedQuery.length === 0
                        ? 0
                        : root.scoreEntry(normalizedQuery, entry)
                }
            })
            .filter(function (item) {
                return normalizedQuery.length === 0 || item.score >= 0
            })
            .sort(function (left, right) {
                if (right.score !== left.score)
                    return right.score - left.score

                return (left.entry.name || "").localeCompare(
                    right.entry.name || ""
                )
            })
            .map(function (item) {
                return item.entry
            })
    }

    function toggle() {
        root.visible = !root.visible

        if (root.visible)
            root.query = ""
    }

    function show() {
        root.query = ""
        root.visible = true
    }

    function hide() {
        root.visible = false
        root.query = ""
    }
}
