import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string title: ""
    property string author: ""
    property string date: ""
    signal openClicked()

    color: Theme.surface
    border.color: Theme.border
    border.width: 1
    radius: 12
    implicitWidth: 220
    implicitHeight: cardLayout.implicitHeight + 40

    ColumnLayout {
        id: cardLayout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Theme.text
            font.pixelSize: 16
            font.weight: Font.Bold
            elide: Text.ElideLeft
            horizontalAlignment: Text.AlignRight
        }

        Text {
            Layout.fillWidth: true
            text: root.author
            color: Theme.textMuted
            font.pixelSize: 12
            elide: Text.ElideLeft
            horizontalAlignment: Text.AlignRight
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        RowLayout {
            Layout.fillWidth: true

            ShadcnButton {
                text: "فتح"
                primary: false
                Layout.preferredWidth: 64
                Layout.preferredHeight: 30
                onClicked: root.openClicked()
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.date
                color: Theme.textMuted
                font.pixelSize: 11
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}