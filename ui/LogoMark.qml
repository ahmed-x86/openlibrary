import QtQuick

// شعار التطبيق: مربع ذهبي بأيقونة كتاب
Rectangle {
    id: root

    property real size: 32

    implicitWidth: size
    implicitHeight: size
    radius: size * 0.3
    color: Theme.accent

    Icon {
        anchors.centerIn: parent
        name: "book"
        size: root.size * 0.52
        strokeWidth: 2.2
        color: Theme.accentText
    }
}
