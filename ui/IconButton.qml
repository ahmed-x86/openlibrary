import QtQuick
import QtQuick.Controls

ToolButton {
    id: root

    property url iconSource: ""

    implicitWidth: 36
    implicitHeight: 36
    padding: 0
    display: AbstractButton.IconOnly

    icon.source: root.iconSource
    icon.width: 20
    icon.height: 20
    icon.color: hovered || pressed ? Theme.text : Theme.textMuted

    background: Rectangle {
        radius: 8
        color: root.pressed || root.hovered ? Theme.border : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}