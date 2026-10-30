import QtQuick
import QtQuick.Layouts

// شريحة حساب تواصل (أيقونة + معرّف). نسخة compact للشاشات الضيقة
// حتى يقف حساب GitHub وTelegram جنب بعض على الجوال.
Rectangle {
    id: root

    property string text: ""
    property string iconName: ""
    property bool compact: false
    signal clicked()

    implicitWidth: row.implicitWidth + (compact ? 22 : 30)
    implicitHeight: compact ? 38 : 42
    radius: 10
    color: area.pressed ? Theme.border : (area.containsMouse ? Theme.surface : Theme.surfaceHi)
    border.width: 1
    border.color: area.containsMouse ? Theme.accentBorder : Theme.border

    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: compact ? 6 : 8
        layoutDirection: Qt.RightToLeft   // الأيقونة على اليمين

        Icon {
            name: root.iconName
            size: root.compact ? 16 : 18
            color: Theme.text
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.text
            color: Theme.text
            font.pixelSize: root.compact ? 12 : 13
            font.weight: Font.Medium
            verticalAlignment: Text.AlignVCenter
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
