import QtQuick

Rectangle {
    id: root

    property string text: ""
    property bool highlighted: false

    implicitWidth: label.implicitWidth + 22
    implicitHeight: 26
    radius: 13
    color: highlighted ? Theme.accentSoft : Theme.surfaceHi
    border.width: 1
    border.color: highlighted ? Theme.accentBorder : Theme.border

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.highlighted ? Theme.accent : Theme.textMuted
        font.pixelSize: 12
        font.weight: Font.Medium
    }
}
