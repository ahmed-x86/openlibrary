pragma Singleton
import QtQuick

// هوية بصرية مستوحاة من المخطوطات: حبر أزرق داكن + ذهب نحاسي، وورق دافئ في الوضع الفاتح
QtObject {
    id: root

    property bool isDark: true

    // ---------- الأسطح والنصوص ----------
    readonly property color bg:        isDark ? "#0d0f14" : "#f7f3ea"
    readonly property color surface:   isDark ? "#151922" : "#fffdf8"
    readonly property color surfaceHi: isDark ? "#1d222d" : "#f0eadc"
    readonly property color border:    isDark ? "#2a303c" : "#e3dac6"
    readonly property color text:      isDark ? "#f3efe6" : "#1f1a14"
    readonly property color textMuted: isDark ? "#a29d92" : "#7a6f5f"

    // ---------- اللون المميز (ذهب نحاسي) ----------
    readonly property color accent:       isDark ? "#d6ad5b" : "#8f5f0f"
    readonly property color accentText:   isDark ? "#1a1304" : "#fffaf0"
    readonly property color accentSoft:   isDark ? "#24d6ad5b" : "#188f5f0f"
    readonly property color accentBorder: isDark ? "#66d6ad5b" : "#668f5f0f"

    // ---------- الأزرار ----------
    readonly property color buttonBg:    isDark ? "#181c25" : "#fffdf8"
    readonly property color primaryBg:   accent
    readonly property color primaryText: accentText

    readonly property color linkColor: isDark ? "#7cb1f2" : "#1d4ed8"
    readonly property color overlayBg: isDark ? "#99000000" : "#40000000"
}
