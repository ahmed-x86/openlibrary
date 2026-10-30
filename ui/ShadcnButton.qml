import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string text: ""
    property string iconName: ""          // اسم أيقونة من Icon.qml
    property bool iconOnRight: false      // الأيقونة على يمين النص (للأسهم الراجعة في الواجهة العربية)
    property bool primary: true
    property bool disabled: false
    signal clicked()

    readonly property color fg: disabled ? Theme.textMuted : (primary ? Theme.primaryText : Theme.text)

    implicitWidth: Math.max(80, contentRow.implicitWidth + 28)
    implicitHeight: 38

    radius: 10
    border.width: 1
    border.color: disabled ? Theme.border : (primary ? Theme.primaryBg : (mouseArea.containsMouse ? Theme.accentBorder : Theme.border))
    color: {
        if (disabled) return Theme.isDark ? "#1a1a1d" : "#e4e4e7"
        if (primary) return mouseArea.pressed ? Qt.darker(Theme.primaryBg, 1.15) : (mouseArea.containsMouse ? Qt.darker(Theme.primaryBg, 1.06) : Theme.primaryBg)
        return mouseArea.pressed ? Theme.border : (mouseArea.containsMouse ? Theme.surfaceHi : Theme.buttonBg)
    }
    opacity: disabled ? 0.5 : 1.0
    scale: mouseArea.pressed ? 0.97 : 1.0

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 90 } }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8
        layoutDirection: root.iconOnRight ? Qt.RightToLeft : Qt.LeftToRight

        Icon {
            visible: root.iconName !== ""
            name: root.iconName
            size: 16
            color: root.fg
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: root.text !== ""
            text: root.text
            color: root.fg
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
