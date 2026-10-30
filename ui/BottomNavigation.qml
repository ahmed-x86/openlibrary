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
        implicitHeight: 64
        color: Theme.surface

        Item {
            anchors.fill: parent

            RowLayout {
                width: Math.min(parent.width - 16, 480)
                height: parent.height - 12
                anchors.centerIn: parent
                spacing: 6

                TabButton {
                    text: "حول"
                    iconName: "info"
                    active: root.currentTab === 2
                    onClicked: root.currentTab = 2
                }

                TabButton {
                    text: "الإعدادات"
                    iconName: "settings"
                    active: root.currentTab === 1
                    onClicked: root.currentTab = 1
                }

                TabButton {
                    text: "الرئيسية"
                    iconName: "home"
                    active: root.currentTab === 0
                    onClicked: root.currentTab = 0
                }
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
