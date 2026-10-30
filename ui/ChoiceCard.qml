import QtQuick
import QtQuick.Layouts

// بطاقة اختيار (مثل الوضع الفاتح / الغامق)
Rectangle {
    id: root

    property string text: ""
    property string iconName: ""
    property bool selected: false
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 88
    radius: 12
    color: selected ? Theme.accentSoft : Theme.buttonBg
    border.width: selected ? 2 : 1
    border.color: selected ? Theme.accent : (area.containsMouse ? Theme.accentBorder : Theme.border)

    Behavior on color { ColorAnimation { duration: 140 } }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8

        Icon {
            Layout.alignment: Qt.AlignHCenter
            name: root.iconName
            size: 24
            color: root.selected ? Theme.accent : Theme.textMuted
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.text
            color: root.selected ? Theme.text : Theme.textMuted
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
    }

    Rectangle {
        visible: root.selected
        width: 20
        height: 20
        radius: 10
        color: Theme.accent
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8

        Icon {
            anchors.centerIn: parent
            name: "check"
            size: 12
            strokeWidth: 3
            color: Theme.accentText
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
