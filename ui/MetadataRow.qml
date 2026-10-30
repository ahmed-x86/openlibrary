import QtQuick
import QtQuick.Layouts

// صف بيانات وصفية: العنوان فوق والقيمة تحته بعرض كامل،
// والقيم الطويلة (مثل المعرّف urn:uuid:...) تُكسر على أكثر من سطر ولا تخرج عن البطاقة.
Item {
    id: root

    property string label: ""
    property string value: ""
    property bool mono: false     // خط ثابت العرض للمعرّفات والروابط
    property bool last: false     // آخر صف: بدون فاصل سفلي

    visible: root.value !== ""
    Layout.fillWidth: true
    implicitHeight: visible ? col.implicitHeight + 28 : 0

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 14
        spacing: 4

        Text {
            Layout.fillWidth: true
            text: root.label
            color: Theme.textMuted
            font.pixelSize: 12
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignRight
        }

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.value
            color: Theme.text
            font.pixelSize: root.mono ? 13 : 14
            font.family: root.mono ? "monospace" : Qt.application.font.family
            wrapMode: Text.Wrap            // يكسر الكلمات الطويلة بدون مسافات
            lineHeight: 1.3
            horizontalAlignment: Text.AlignRight
        }
    }

    Rectangle {
        visible: !root.last
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        height: 1
        color: Theme.border
    }
}
