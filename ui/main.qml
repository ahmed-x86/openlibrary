import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root

    title: "المكتبة المفتوحة - OpenLibrary"
    width: 800
    height: 600
    minimumWidth: 320
    minimumHeight: 400
    visible: true
    color: Theme.bg

    // الإشارات المتصلة بـ C++
    signal openEpubDialog()
    signal goNextChapter()
    signal goPrevChapter()
    signal goBackHome()
    signal goToChapter(int chapter)
    signal openLink(string url)

    // خصائص الحالة والبيانات
    property int currentTab: 0 // 0: الرئيسية | 1: الإعدادات | 2: حول
    property bool readingMode: false
    property bool showInfo: false
    property bool editingChapter: false
    property bool dropdownOpen: false
    readonly property bool isNarrow: root.width < 600
    readonly property int pageMargin: root.isNarrow ? 16 : 32

    property string bookTitle: ""
    property string bookAuthor: ""
    property string chapterContent: ""
    property int currentChapterNum: 1
    property int chapterCount: 0

    property string metaLanguage: ""
    property string metaPublisher: ""
    property string metaDate: ""
    property string metaDescription: ""
    property string metaSubject: ""
    property string metaRights: ""
    property string metaIdentifier: ""
    property string metaSource: ""
    property string metaFormat: ""
    property string metaChapters: ""

    property bool canGoNext: false
    property bool canGoPrev: false

    // إعادة التمرير لأعلى تلقائياً عند تغير الفصل
    onCurrentChapterNumChanged: {
        readingFlickable.contentY = 0
    }

    // ============ التنقل للخلف (زر الرجوع في أندرويد / Escape) ============
    // يرجع خطوة واحدة: القائمة المنسدلة/التحرير ← معلومات الكتاب ← القراءة ← تبويب ≠ الرئيسية.
    // يرجع true إذا تم التعامل مع الرجوع، و false إذا كنا في الرئيسية (فيُغلق التطبيق).
    function handleBack() {
        if (root.dropdownOpen || root.editingChapter) {
            root.dropdownOpen = false
            root.editingChapter = false
            return true
        }
        if (root.showInfo) {
            root.showInfo = false
            return true
        }
        if (root.readingMode) {
            root.goBackHome()
            return true
        }
        if (root.currentTab !== 0) {
            root.currentTab = 0
            return true
        }
        return false
    }

    // زر الرجوع في أندرويد يصل كطلب إغلاق للنافذة: نمنعه ما دمنا لسنا في الرئيسية
    onClosing: function(close) {
        if (Qt.platform.os === "android" && root.handleBack()) {
            close.accepted = false
        }
    }

    // اختصارات لوحة المفاتيح للحواسيب أو الجوالات المتصلة بكيبورد
    Shortcut {
        sequence: "Left"
        enabled: root.readingMode && !root.showInfo && !root.editingChapter && root.canGoNext
        onActivated: root.goNextChapter()
    }
    Shortcut {
        sequence: "Right"
        enabled: root.readingMode && !root.showInfo && !root.editingChapter && root.canGoPrev
        onActivated: root.goPrevChapter()
    }
    Shortcut {
        sequence: "Escape"
        onActivated: root.handleBack()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ================= شريط التنقل العلوي =================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 60
            color: Theme.bg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.isNarrow ? 10 : 20
                anchors.rightMargin: root.isNarrow ? 14 : 24
                spacing: 12

                // الجهة اليسرى (فتح كتاب / أيقونة معلومات)
                RowLayout {
                    spacing: 8

                    ShadcnButton {
                        visible: !root.readingMode && !root.showInfo && root.currentTab === 0
                        text: "فتح كتاب"
                        iconName: "book"
                        Layout.preferredWidth: 120
                        onClicked: root.openEpubDialog()
                    }

                    IconButton {
                        visible: root.readingMode && !root.showInfo
                        iconName: "info"
                        onClicked: root.showInfo = true
                    }
                }

                // العنوان
                Text {
                    Layout.fillWidth: true
                    text: root.showInfo ? "معلومات الكتاب"
                        : (root.readingMode ? root.bookTitle
                        : (root.currentTab === 1 ? "الإعدادات"
                        : (root.currentTab === 2 ? "حول" : "OpenLibrary")))
                    color: Theme.text
                    font.pixelSize: root.isNarrow ? 16 : 18
                    font.weight: Font.Bold
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }

                // أقصى اليمين: سهم الرجوع داخل الكتاب، أو الشعار في باقي الصفحات
                IconButton {
                    visible: root.readingMode || root.showInfo
                    iconName: "arrow-right"
                    iconColor: Theme.text
                    onClicked: {
                        if (root.showInfo) {
                            root.showInfo = false
                        } else {
                            root.goBackHome()
                        }
                    }
                }

                LogoMark {
                    visible: !(root.readingMode || root.showInfo)
                    size: 32
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.border
            }
        }

        // ================= منطقة المحتوى الرئيسية =================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // 1. الصفحة الرئيسية
            Item {
                anchors.fill: parent
                visible: !root.readingMode && !root.showInfo && root.currentTab === 0

                ColumnLayout {
                    width: Math.min(parent.width - 32, 520)
                    anchors.centerIn: parent
                    spacing: 16

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 132
                        Layout.preferredHeight: 132

                        Rectangle {
                            anchors.fill: parent
                            radius: 66
                            color: Theme.accentSoft
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 106
                            height: 106
                            radius: 53
                            color: "transparent"
                            border.width: 1
                            border.color: Theme.accentBorder
                        }

                        LogoMark {
                            anchors.centerIn: parent
                            size: 72
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "مكتبتك الرقمية مفتوحة المصدر"
                        color: Theme.text
                        font.pixelSize: root.isNarrow ? 24 : 28
                        font.weight: Font.ExtraBold
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "قارئ ملفات EPUB سريع، خفيف، ومصمم ليكون مريحاً للعين."
                        color: Theme.textMuted
                        font.pixelSize: 14
                        lineHeight: 1.4
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Item { Layout.preferredHeight: 4 }

                    ShadcnButton {
                        Layout.alignment: Qt.AlignHCenter
                        text: "فتح كتاب EPUB"
                        iconName: "book"
                        Layout.preferredWidth: 210
                        Layout.preferredHeight: 46
                        onClicked: root.openEpubDialog()
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 6
                        spacing: 8

                        Tag { text: "EPUB" }
                        Tag { text: "مفتوح المصدر"; highlighted: true }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "متاح على لينكس وويندوز وأندرويد"
                        color: Theme.textMuted
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // 2. صفحة الإعدادات
            Item {
                anchors.fill: parent
                visible: !root.readingMode && !root.showInfo && root.currentTab === 1

                ColumnLayout {
                    width: Math.min(parent.width - root.pageMargin * 2, 640)
                    anchors.top: parent.top
                    anchors.topMargin: root.pageMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: settingsCol.implicitHeight + 48
                        color: Theme.surface
                        border.color: Theme.border
                        border.width: 1
                        radius: 16

                        ColumnLayout {
                            id: settingsCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 24
                            spacing: 14

                            Text {
                                Layout.fillWidth: true
                                text: "المظهر واللون"
                                color: Theme.text
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "اختر الوضع الأريح لعينيك."
                                color: Theme.textMuted
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignRight
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                ChoiceCard {
                                    text: "الغامق"
                                    iconName: "moon"
                                    selected: Theme.isDark
                                    onClicked: Theme.isDark = true
                                }

                                ChoiceCard {
                                    text: "الفاتح"
                                    iconName: "sun"
                                    selected: !Theme.isDark
                                    onClicked: Theme.isDark = false
                                }
                            }
                        }
                    }
                }
            }

            // 3. صفحة حول
            AboutPage {
                anchors.fill: parent
                visible: !root.readingMode && !root.showInfo && root.currentTab === 2
                onOpenLink: function(url) { root.openLink(url) }
            }

            // 4. صفحة معلومات الكتاب
            Flickable {
                id: infoFlickable
                anchors.fill: parent
                visible: root.showInfo
                contentWidth: width
                contentHeight: infoLayout.implicitHeight + root.pageMargin * 2
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: infoLayout
                    width: Math.min(infoFlickable.width - root.pageMargin * 2, 720)
                    x: (infoFlickable.width - width) / 2
                    y: root.pageMargin
                    spacing: 16

                    // بطاقة عنوان الكتاب والمؤلف
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: headerInfoCol.implicitHeight + 48
                        color: Theme.surface
                        border.color: Theme.border
                        border.width: 1
                        radius: 16

                        ColumnLayout {
                            id: headerInfoCol
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 10

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 56
                                Layout.preferredHeight: 72
                                radius: 8
                                color: Theme.accentSoft
                                border.width: 1
                                border.color: Theme.accentBorder

                                Icon {
                                    anchors.centerIn: parent
                                    name: "book"
                                    size: 26
                                    color: Theme.accent
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.bookTitle
                                color: Theme.text
                                font.pixelSize: root.isNarrow ? 20 : 24
                                font.weight: Font.ExtraBold
                                lineHeight: 1.25
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: root.bookAuthor !== ""
                                text: root.bookAuthor
                                color: Theme.textMuted
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    // جدول البيانات الوصفية
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: metaCol.implicitHeight + 16
                        color: Theme.surface
                        border.color: Theme.border
                        border.width: 1
                        radius: 16
                        clip: true

                        ColumnLayout {
                            id: metaCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.topMargin: 16
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                rightPadding: 20
                                bottomPadding: 12
                                text: "البيانات الوصفية"
                                color: Theme.text
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignRight
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.border
                            }

                            MetadataRow { label: "العنوان";       value: root.bookTitle }
                            MetadataRow { label: "المؤلف";        value: root.bookAuthor }
                            MetadataRow { label: "اللغة";         value: root.metaLanguage }
                            MetadataRow { label: "الناشر";        value: root.metaPublisher; mono: true }
                            MetadataRow { label: "تاريخ النشر";   value: root.metaDate }
                            MetadataRow { label: "الوصف";         value: root.metaDescription }
                            MetadataRow { label: "الموضوع";       value: root.metaSubject }
                            MetadataRow { label: "المعرف (ISBN)"; value: root.metaIdentifier; mono: true }
                            MetadataRow { label: "المصدر";        value: root.metaSource; mono: true }
                            MetadataRow { label: "الحقوق";        value: root.metaRights }
                            MetadataRow { label: "الصيغة";        value: root.metaFormat }
                            MetadataRow { label: "عدد الفصول";    value: root.metaChapters; last: true }
                        }
                    }

                    ShadcnButton {
                        Layout.alignment: Qt.AlignHCenter
                        text: "العودة للقراءة"
                        iconName: "arrow-right"
                        iconOnRight: true
                        primary: false
                        Layout.preferredWidth: 170
                        Layout.preferredHeight: 42
                        onClicked: root.showInfo = false
                    }
                }
            }

            // 5. وضع القراءة
            ColumnLayout {
                anchors.fill: parent
                visible: root.readingMode && !root.showInfo
                spacing: 0

                // شريط اسم المؤلف الفرعي
                Rectangle {
                    Layout.fillWidth: true
                    visible: root.bookAuthor !== ""
                    implicitHeight: authorLabel.implicitHeight + 18
                    color: Theme.bg

                    Text {
                        id: authorLabel
                        anchors.centerIn: parent
                        width: parent.width - 32
                        text: root.bookAuthor
                        color: Theme.textMuted
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }

                // شريط تقدّم القراءة (يمتلئ من اليمين)
                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: Theme.border

                    Rectangle {
                        anchors.right: parent.right
                        height: parent.height
                        width: root.chapterCount > 0 ? parent.width * root.currentChapterNum / root.chapterCount : 0
                        color: Theme.accent

                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }
                }

                // منطقة نص الفصل القابلة للتمرير
                Flickable {
                    id: readingFlickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: chapterTextItem.implicitHeight + (root.isNarrow ? 48 : 80)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    Text {
                        id: chapterTextItem
                        width: Math.min(readingFlickable.width - (root.isNarrow ? 32 : 96), 860)
                        x: (readingFlickable.width - width) / 2
                        y: root.isNarrow ? 20 : 32
                        text: root.chapterContent
                        color: Theme.text
                        font.pixelSize: root.isNarrow ? 16 : 18
                        lineHeight: 1.6
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                // شريط التنقل بين الفصول
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 56
                    color: Theme.bg

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.isNarrow ? 12 : 24
                        anchors.rightMargin: root.isNarrow ? 12 : 24
                        spacing: 8

                        ShadcnButton {
                            text: "التالي"
                            iconName: "chevron-left"
                            primary: false
                            disabled: !root.canGoNext
                            Layout.preferredWidth: root.isNarrow ? 92 : 104
                            Layout.preferredHeight: 36
                            onClicked: root.goNextChapter()
                        }

                        Item { Layout.fillWidth: true }

                        // مؤشر ومحدد رقم الفصل
                        RowLayout {
                            spacing: 6

                            // الوضع العادي (عرض الفصل الحالي)
                            Rectangle {
                                visible: !root.editingChapter
                                implicitWidth: chapterIndicatorText.implicitWidth + 24
                                implicitHeight: 34
                                radius: 17
                                color: chHover.containsMouse ? Theme.surfaceHi : Theme.surface
                                border.color: chHover.containsMouse ? Theme.accentBorder : Theme.border
                                border.width: 1

                                Text {
                                    id: chapterIndicatorText
                                    anchors.centerIn: parent
                                    text: "الفصل " + root.currentChapterNum + " من " + root.chapterCount
                                    color: Theme.textMuted
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: chHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.editingChapter = true
                                        chapterInput.text = String(root.currentChapterNum)
                                        chapterInput.forceActiveFocus()
                                        chapterInput.selectAll()
                                    }
                                }
                            }

                            // وضع إدخال رقم الفصل مباشرة
                            Rectangle {
                                visible: root.editingChapter
                                Layout.preferredWidth: 56
                                Layout.preferredHeight: 32
                                color: Theme.buttonBg
                                border.color: Theme.accent
                                border.width: 1
                                radius: 8

                                TextInput {
                                    id: chapterInput
                                    anchors.fill: parent
                                    color: Theme.text
                                    font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    validator: IntValidator { bottom: 1; top: Math.max(1, root.chapterCount) }
                                    selectByMouse: true
                                    onAccepted: {
                                        var target = parseInt(text)
                                        if (!isNaN(target) && target >= 1 && target <= root.chapterCount) {
                                            root.goToChapter(target)
                                        }
                                        root.editingChapter = false
                                        root.dropdownOpen = false
                                    }
                                }
                            }

                            Text {
                                visible: root.editingChapter
                                text: "من " + root.chapterCount
                                color: Theme.textMuted
                                font.pixelSize: 12
                                verticalAlignment: Text.AlignVCenter
                            }

                            // زر فتح القائمة المنسدلة للفصول
                            Rectangle {
                                visible: root.editingChapter
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                color: ddMouse.containsMouse ? Theme.border : Theme.buttonBg
                                border.color: Theme.border
                                border.width: 1
                                radius: 8

                                Icon {
                                    anchors.centerIn: parent
                                    name: root.dropdownOpen ? "chevron-down" : "chevron-up"
                                    size: 16
                                    color: Theme.textMuted
                                }

                                MouseArea {
                                    id: ddMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.dropdownOpen = !root.dropdownOpen
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ShadcnButton {
                            text: "السابق"
                            iconName: "chevron-right"
                            iconOnRight: true
                            primary: false
                            disabled: !root.canGoPrev
                            Layout.preferredWidth: root.isNarrow ? 92 : 104
                            Layout.preferredHeight: 36
                            onClicked: root.goPrevChapter()
                        }
                    }
                }

                // المنطقة الآمنة السفلية لوضع القراءة على الجوال
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: root.isNarrow ? 16 : 0
                    color: Theme.bg
                }
            }
        }

        // ================= شريط التنقل السفلي =================
        BottomNavigation {
            visible: !root.readingMode && !root.showInfo
            isNarrow: root.isNarrow
            currentTab: root.currentTab
            onCurrentTabChanged: root.currentTab = currentTab
        }
    }

    // طبقة شفافة لإغلاق تحرير الفصل عند النقر في أي مكان خارج الشريط السفلي
    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height - (root.isNarrow ? 72 : 56)
        visible: root.editingChapter && !root.dropdownOpen
        onClicked: root.editingChapter = false
    }

    // نافذة قائمة الفصول المنسدلة
    Rectangle {
        anchors.fill: parent
        visible: root.dropdownOpen
        color: Theme.overlayBg

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.dropdownOpen = false
                root.editingChapter = false
            }
        }

        Rectangle {
            id: dropdownBox
            width: 150
            height: Math.min(Math.max(root.chapterCount, 1) * 38 + 8, Math.min(340, parent.height - 90))
            x: (parent.width - width) / 2
            y: parent.height - (root.isNarrow ? 76 : 60) - height
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
            radius: 12
            clip: true

            ListView {
                id: chapterListView
                anchors.fill: parent
                anchors.margins: 4
                model: root.chapterCount
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    required property int index
                    readonly property int chapterNum: index + 1
                    readonly property bool isCurrent: chapterNum === root.currentChapterNum

                    width: chapterListView.width
                    height: 38
                    radius: 8
                    color: isCurrent ? Theme.accentSoft : (itemMouse.containsMouse ? Theme.surfaceHi : "transparent")

                    Text {
                        anchors.centerIn: parent
                        text: "الفصل " + parent.chapterNum
                        color: parent.isCurrent ? Theme.accent : Theme.textMuted
                        font.pixelSize: 13
                        font.weight: parent.isCurrent ? Font.Bold : Font.Normal
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.goToChapter(parent.chapterNum)
                            root.dropdownOpen = false
                            root.editingChapter = false
                        }
                    }
                }
            }
        }
    }
}
