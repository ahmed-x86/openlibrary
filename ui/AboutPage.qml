import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    signal openLink(string url)

    readonly property bool narrow: width < 520
    readonly property int pad: narrow ? 16 : 32

    // مكون القائمة المنسدلة (Accordion) بشكل بطاقة
    component Accordion: Rectangle {
        id: acc

        property string title: ""
        property string content: ""
        property string iconName: "info"
        property bool isOpen: false
        default property alias extraChildren: extraContainer.data

        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight
        radius: 14
        color: Theme.surface
        border.width: 1
        border.color: acc.isOpen ? Theme.accentBorder : Theme.border
        clip: true

        Behavior on border.color { ColorAnimation { duration: 150 } }

        ColumnLayout {
            id: inner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 0

            // ---- الرأس ----
            Item {
                Layout.fillWidth: true
                implicitHeight: 60

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 13
                    color: headerMouse.containsMouse ? Theme.surfaceHi : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 14
                    spacing: 12

                    Icon {
                        name: acc.isOpen ? "chevron-up" : "chevron-down"
                        size: 18
                        color: Theme.textMuted
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: acc.title
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Theme.accentSoft

                        Icon {
                            anchors.centerIn: parent
                            name: acc.iconName
                            size: 18
                            color: Theme.accent
                        }
                    }
                }

                MouseArea {
                    id: headerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: acc.isOpen = !acc.isOpen
                }
            }

            // ---- الجسم (ينفتح بحركة) ----
            Item {
                id: bodyWrap
                Layout.fillWidth: true
                clip: true

                property real animatedHeight: acc.isOpen ? bodyCol.implicitHeight + 37 : 0
                Behavior on animatedHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                implicitHeight: animatedHeight

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.border
                }

                ColumnLayout {
                    id: bodyCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.topMargin: 19
                    spacing: 14

                    Text {
                        Layout.fillWidth: true
                        visible: acc.content !== ""
                        text: acc.content
                        color: Theme.textMuted
                        font.pixelSize: 14
                        lineHeight: 1.5
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignRight
                    }

                    ColumnLayout {
                        id: extraContainer
                        Layout.fillWidth: true
                        spacing: 14
                    }
                }
            }
        }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: pageCol.implicitHeight + root.pad * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: pageCol
            width: Math.min(flickable.width - root.pad * 2, 720)
            x: (flickable.width - width) / 2
            y: root.pad
            spacing: 12

            // ---- بطاقة التعريف ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: heroRow.implicitHeight + 40
                radius: 16
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 15
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0) }
                        GradientStop { position: 1.0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, Theme.isDark ? 0.14 : 0.10) }
                    }
                }

                RowLayout {
                    id: heroRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 20
                    spacing: 14

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: "المكتبة المفتوحة"
                            color: Theme.text
                            font.pixelSize: 20
                            font.weight: Font.ExtraBold
                        }

                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: "OpenLibrary"
                            color: Theme.textMuted
                            font.pixelSize: 13
                        }

                        Tag {
                            Layout.alignment: Qt.AlignRight
                            text: "قيد التطوير"
                            highlighted: true
                        }
                    }

                    LogoMark { size: 56 }
                }
            }

            Accordion {
                title: "عن البرنامج"
                iconName: "book"
                content: "البرنامج هو قارئ كتب إلكترونية مفتوح المصدر صدقة جارية على روح المطور أحمد العمري.\nمازال فى مرحلة التطوير قبل النشر.\nيفتح فقط صيغة epub حتى الآن.\n\nتخليص حق: لم نسرق أي كود من أي برنامج بل بنيناه من الصفر، قد يفتح البرنامج كتباً طورها آخرون، المطور لا عليه شيء إن حمل المستخدم كتاباً عليه حقوق طبع ونشر، هذي مجرد أداة."
            }

            Accordion {
                title: "عن المطور"
                iconName: "user"

                Text {
                    Layout.fillWidth: true
                    text: "المطور الرئيس للمشروع اسمه أحمد العمري."
                    color: Theme.textMuted
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignRight
                }

                // الحسابان جنب بعض؛ ولو الشاشة ضيقة جداً ينزل الثاني تلقائياً
                Flow {
                    Layout.fillWidth: true
                    layoutDirection: Qt.RightToLeft
                    spacing: 8

                    SocialChip {
                        text: "@ahmed-86"
                        iconName: "github"
                        compact: root.narrow
                        onClicked: root.openLink("https://github.com/ahmed-x86")
                    }

                    SocialChip {
                        text: "@arch_gnu_linux_user"
                        iconName: "telegram"
                        compact: root.narrow
                        onClicked: root.openLink("https://t.me/arch_gnu_linux_user")
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "المطور يكره أنظمة التشغيل المغلقة وصعب يرفع البرنامج على google play أو app store دعماً للحرية البرمجية، لكن لأن عدد من الإخوة يستخدمون أنظمة مغلقة (اتركوا ويندوز وحولوا لينكس) يجب دعم البرنامج لكل المنصات مثل windows, mac, ios, android والأفضل طبعاً هو لينكس.\n\nالمطور لا يُصرح إذا كان أعزب أو متزوج ولا يرفع صورته الشخصية حتى لا تُفتتن البنات به."
                    color: Theme.textMuted
                    font.pixelSize: 14
                    lineHeight: 1.5
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignRight
                }
            }

            Accordion {
                title: "الرخصة"
                iconName: "file-text"
                content: "رخصة \"وقف\" العامة\nبسم الله الرّحمن الرّحيم\n\nرخصة وقف العامة الإصدار 2.0، 3 محرم 1435\n\nالتمهيد\n\nهذه الوثيقة هي الاتفاقية الحاكمة لاستخدام المواد التي تغطيها، حيث تُعتبر العقد المُبرم بين الناشر والمستفيد. نحن نرى أن الاتفاقيات الاحتكارية لا تقيد المستفيد فحسب، بل تؤثر على قيمة العمل الفكري، وتحوله من نور إلى مجرد سلعة يُمتلك فيها حق الملكية الفكرية للمودع الفكري الأول. رؤيتنا تقتصر على الشكل المعنوي للعمل الفكري نفسه وفقاً للقواعد أدناه، بخلاف الرخص الاحتكارية التي تضع قيوداً مجحفة.\n\nلدينا رؤية مختلفة، فنحن نقدم عملنا (مثل البرمجيات) ابتغاء مرضاة الله، وهذا هو ركيزة هذه الرخصة التي تميزها عن الرخص الاحتكارية. أي نية أخرى (مثل نشر المعرفة أو تحقيق الأرباح) يجب أن تتحقق بطرق لا تتعارض مع هدفنا الأخلاقي الأساسي.\n\nوفقاً لمعتقداتنا (والتي لا نفرضها على أحد) فإن الإسلام يحرم الاحتكار وكتمان العلم بشكل عام، وهذا ينبع من:\n- الحديث الصحيح: \"مَن سُئِلَ عَن عِلمٍ فَكَتَمَهُ، أُلجِمَ يَومَ القِيامَةِ بِلِجامٍ مِن نارٍ.\"\n- حدد الفقه الإسلامي ما يمكن تملكه، والقواعد لا تنطبق على الأفكار لأنها ليست شيئاً ملموساً ومحدوداً، وتقريباً جميع شروط الاتفاقيات الاحتكارية تندرج تحت حكم \"الغرر\" المحرم.\n- كتمان العلم النافع عمن يحتاجه يلحق ضرراً بالناس مقابل مكاسب دنيوية لأفراد قلائل، وهذا لا يبرره الشرع إذ \"لا ضرر ولا ضرار\".\n- ما يسمى بـ \"الملكية الفكرية\" يتمحور حول إعطاء المُلّاك الحق في منع ما أحله الله لكسب المال، وليس بتقديم خدمة أو سلع.\n\nنحن في \"وقف\" نهتم بمصلحة عامة الناس. ولا نغفل عن مصلحة صاحب العمل في نيل الأجر من الله تعالى. نعتقد أن حقوق النشر والتوزيع \"ممنوحة\" وليست \"محفوظة\".\n- أولاً: فضل وحقوق صاحب العمل الأخلاقية محفوظة ومعترف بها.\n- ثانياً: يحق للمؤلف الأصلي وأي طرف آخر تقاضي أجور على تحسين العمل أو تطويره أو تقديم خدمات مدفوعة... إلخ، ولكن ليس على العمل في شكله غير الملموس.\n\nالتعريفات\n- العمل الفكري: هو أي منتج فكري غير ملموس ونافع يمكن تمريره للآخرين أو نسخه دون تكلفة على المؤلف الأصلي.\n- الحامل (أو المطور): هو المؤلف المبدع أو الجهة التي قامت بتطوير العمل وجعله متاحاً.\n- المرخص له أو المستخدم: أي شخص أو جهة تستخدم العمل.\n- الرخصة: هذه الاتفاقية بين الطرفين وتُطبق بمجرد استخدام المنتج بأي شكل.\n\nالشروط\nكما يوحي الاسم \"وقف\"، يعلن الحامل أن عمله أُنتج وجُعل متاحاً للعامة لوجه الله كصدقة جارية.\nتمنح \"وقف\" المستخدمين الحق في الاستفادة من العمل بالتشغيل والنسخ وإعادة التوزيع وحتى التطوير وفقاً لما يلي:\n\n1. التمهيد والتعريفات تعتبر جزءاً لا يتجزأ من هذه الرخصة.\n2. الاستخدام: يحق للمستخدم استخدام العمل لأي غرض، وينصح الحامل بعدم استخدامه في الإضرار بالآخرين أو مخالفة مبادئ الإسلام، والحامل غير مسؤول عن أي انتهاكات.\n3. التغطية: يمكن أن تغطي رخصة وقف الأعمال المنشورة برخص أخرى لا تتعارض معها.\n4. الحد الزمني: الرخصة غير مقيدة بوقت، وكل استخدام للعمل يعتبر تاريخاً جديداً للموافقة.\n5. إعادة التوزيع: يحق للمستخدم إعادة توزيع العمل غير المعدل بأي كمية، مع الاعتراف بفضل صاحب العمل.\n6. التعديلات: يحق للمستخدم الحصول على المصدر وإجراء تعديلات.\n7. توزيع التعديلات: يمكن للمستخدم توزيع التعديلات تحت هذه الرخصة فقط بشرط الإشارة للعمل الأصلي.\n8. إخلاء المسؤولية: لا يتحمل الحامل أي مسؤولية قانونية أو أخلاقية عن الأضرار. يُقدم هذا العمل \"كما هو\"، والمسؤولية الكاملة تقع على المستخدم."
            }
        }
    }
}
