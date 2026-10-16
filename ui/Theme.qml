pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool isDark: true

    readonly property color bg: isDark ? "#09090b" : "#ffffff"
    readonly property color surface: isDark ? "#121215" : "#f4f4f5"
    readonly property color border: isDark ? "#27272a" : "#e4e4e7"
    readonly property color text: isDark ? "#f4f4f5" : "#09090b"
    readonly property color textMuted: isDark ? "#a1a1aa" : "#71717a"

    readonly property color buttonBg: isDark ? "#18181b" : "#ffffff"
    readonly property color primaryBg: isDark ? "#ffffff" : "#09090b"
    readonly property color primaryText: isDark ? "#000000" : "#ffffff"
    readonly property color linkColor: isDark ? "#60a5fa" : "#3b82f6"
    readonly property color overlayBg: isDark ? "#80000000" : "#30000000"
}