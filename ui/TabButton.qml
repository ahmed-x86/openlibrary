import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string text: ""
    property string iconName: ""
    property bool active: false
    signal clicked()

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: 52
    radius: 12
    color: active ? Theme.accentSoft : (mouseArea.containsMouse ? Theme.surfaceHi : "transparent")

    Behavior on color { ColorAnimation { duration: 140 } }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 3

        Icon {
            Layout.alignment: Qt.AlignHCenter
            name: root.iconName
            size: 20
            color: root.active ? Theme.accent : Theme.textMuted
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.text
            color: root.active ? Theme.accent : Theme.textMuted
            font.pixelSize: 11
            font.weight: root.active ? Font.Bold : Font.Medium
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
