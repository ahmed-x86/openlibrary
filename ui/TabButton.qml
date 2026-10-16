import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string text: ""
    property bool active: false
    signal clicked()

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: 44
    radius: 8
    color: active ? Theme.border : (mouseArea.containsMouse ? Theme.buttonBg : "transparent")

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: root.text
        color: root.active ? Theme.text : Theme.textMuted
        font.pixelSize: 14
        font.weight: root.active ? Font.Bold : Font.Medium
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}