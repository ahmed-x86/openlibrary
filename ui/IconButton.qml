import QtQuick

Rectangle {
    id: root

    property string iconName: ""
    property real iconSize: 20
    property color iconColor: Theme.textMuted
    signal clicked()

    implicitWidth: 40
    implicitHeight: 40
    radius: 10
    color: area.pressed ? Theme.border : (area.containsMouse ? Theme.surfaceHi : "transparent")

    Behavior on color { ColorAnimation { duration: 120 } }

    Icon {
        anchors.centerIn: parent
        name: root.iconName
        size: root.iconSize
        color: (area.containsMouse || area.pressed) ? Theme.text : root.iconColor
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
