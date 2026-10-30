import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string text: ""
    property string iconSource: "" // إضافة خاصية الأيقونة
    property bool primary: true
    property bool disabled: false
    signal clicked()

    implicitWidth: Math.max(80, contentRow.implicitWidth + 28)
    implicitHeight: 36

    radius: 6
    border.width: 1
    border.color: disabled ? Theme.border : (primary ? Theme.primaryBg : Theme.border)
    color: {
        if (disabled) return Theme.isDark ? "#1a1a1d" : "#e4e4e7"
        if (primary) return mouseArea.pressed ? Qt.darker(Theme.primaryBg, 1.15) : (mouseArea.containsMouse ? Qt.darker(Theme.primaryBg, 1.06) : Theme.primaryBg)
        return mouseArea.pressed ? Theme.border : (mouseArea.containsMouse ? Theme.surface : Theme.buttonBg)
    }
    opacity: disabled ? 0.5 : 1.0

    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8

        Image {
            visible: root.iconSource !== ""
            source: root.iconSource
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            sourceSize: Qt.size(16, 16)
        }

        Text {
            id: label
            visible: root.text !== ""
            text: root.text
            color: root.disabled ? Theme.textMuted : (root.primary ? Theme.primaryText : Theme.text)
            font.pixelSize: 13
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: !root.disabled
        hoverEnabled: true
        cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}