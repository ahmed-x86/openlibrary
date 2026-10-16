import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool isNarrow: false
    property int currentTab: 0

    spacing: 0
    Layout.fillWidth: true

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.border
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 65
        color: Theme.surface

        Item {
            anchors.fill: parent

            RowLayout {
                width: Math.min(parent.width, 500)
                height: parent.height
                anchors.centerIn: parent
                spacing: 12

                Item { width: 4 }

                TabButton {
                    text: "حول"
                    active: root.currentTab === 2
                    onClicked: root.currentTab = 2
                }

                TabButton {
                    text: "الإعدادات"
                    active: root.currentTab === 1
                    onClicked: root.currentTab = 1
                }

                TabButton {
                    text: "الرئيسية"
                    active: root.currentTab === 0
                    onClicked: root.currentTab = 0
                }

                Item { width: 4 }
            }
        }
    }

    // منطقة الحماية السفلية لشاشات الجوال وإيماءات النظام
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: root.isNarrow ? 16 : 0
        color: Theme.surface
    }
}