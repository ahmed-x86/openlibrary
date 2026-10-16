import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: ""
    property string value: ""

    visible: root.value !== ""
    Layout.fillWidth: true
    implicitHeight: visible ? Math.max(48, rowLayout.implicitHeight + 20) : 0
    color: "transparent"

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 16

        Text {
            Layout.fillWidth: true
            text: root.value
            color: Theme.text
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
        }

        Text {
            Layout.preferredWidth: 110
            Layout.minimumWidth: 95
            Layout.maximumWidth: 120
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            topPadding: 4
            text: root.label
            color: Theme.textMuted
            font.pixelSize: 13
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
        }
    }
}