import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    signal openLink(string url)

    // مكون القائمة المنسدلة (Accordion)
    component Accordion: ColumnLayout {
        id: accRoot
        property string title: ""
        property string content: ""
        property bool isOpen: false
        default property alias extraChildren: extraContainer.data

        Layout.fillWidth: true
        spacing: 4

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 56
            radius: 8
            color: headerMouse.containsMouse ? Theme.surface : "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Text {
                    text: accRoot.isOpen ? "▲" : "▼"
                    color: Theme.textMuted
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: accRoot.title
                    color: Theme.text
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                }
            }

            MouseArea {
                id: headerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: accRoot.isOpen = !accRoot.isOpen
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: accRoot.isOpen
            implicitHeight: accRoot.isOpen ? bodyColumn.implicitHeight + 40 : 0
            clip: true
            color: Theme.surface
            radius: 8
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                id: bodyColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 14

                Text {
                    Layout.fillWidth: true
                    visible: accRoot.content !== ""
                    text: accRoot.content
                    color: Theme.textMuted
                    font.pixelSize: 14
                    lineHeight: 1.4
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignRight
                }

                ColumnLayout {
                    id: extraContainer
                    Layout.fillWidth: true
                    spacing: 14
                    visible: children.length > 0
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.width < 600 ? 16 : 32
        spacing: 24

        Text {
            Layout.fillWidth: true
            text: "حول"
            color: Theme.text
            font.pixelSize: 28
            font.weight: Font.ExtraBold
            horizontalAlignment: Text.AlignRight
        }

        Flickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: accordionsLayout.implicitHeight + 24
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: accordionsLayout
                width: flickable.width
                spacing: 16

                Accordion {
                    title: "عن البرنامج"
                    content: "البرنامج هو قارئ كتب إلكترونية مفتوح المصدر صدقة جارية على روح المطور أحمد العمري.\nمازال فى مرحلة التطوير قبل النشر.\nيفتح فقط صيغة epub حتى الآن.\n\nتخليص حق: لم نسرق أي كود من أي برنامج بل بنيناه من الصفر، قد يفتح البرنامج كتباً طورها آخرون، المطور لا عليه شيء إن حمل المستخدم كتاباً عليه حقوق طبع ونشر، هذي مجرد أداة."
                }

                Accordion {
                    title: "عن المطور"

                    Text {
                        Layout.fillWidth: true
                        text: "المطور الرئيس للمشروع اسمه أحمد العمري."
                        color: Theme.textMuted
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignRight
                    }

                    Flow {
                        Layout.fillWidth: true
                        layoutDirection: Qt.RightToLeft
                        spacing: 12

                        // زر GitHub
                        Rectangle {
                            implicitWidth: githubRow.implicitWidth + 24
                            implicitHeight: 42
                            radius: 8
                            color: ghMouse.containsMouse ? Theme.border : "transparent"

                            RowLayout {
                                id: githubRow
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "@ahmed-86"
                                    color: Theme.linkColor
                                    font.pixelSize: 14
                                    verticalAlignment: Text.AlignVCenter
                                }

                                IconButton {
                                    implicitWidth: 22
                                    implicitHeight: 22
                                    iconSource: "icons/github.svg"
                                    enabled: false
                                }
                            }

                            MouseArea {
                                id: ghMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openLink("https://github.com/ahmed-x86")
                            }
                        }

                        // زر Telegram
                        Rectangle {
                            implicitWidth: tgRow.implicitWidth + 24
                            implicitHeight: 42
                            radius: 8
                            color: tgMouse.containsMouse ? Theme.border : "transparent"

                            RowLayout {
                                id: tgRow
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "@arch_gnu_linux_user"
                                    color: Theme.linkColor
                                    font.pixelSize: 14
                                    verticalAlignment: Text.AlignVCenter
                                }

                                IconButton {
                                    implicitWidth: 22
                                    implicitHeight: 22
                                    iconSource: "icons/telegram.svg"
                                    enabled: false
                                }
                            }

                            MouseArea {
                                id: tgMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openLink("https://t.me/arch_gnu_linux_user")
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "المطور يكره أنظمة التشغيل المغلقة وصعب يرفع البرنامج على google play أو app store دعماً للحرية البرمجية، لكن لأن عدد من الإخوة يستخدمون أنظمة مغلقة (اتركوا ويندوز وحولوا لينكس) يجب دعم البرنامج لكل المنصات مثل windows, mac, ios, android والأفضل طبعاً هو لينكس.\n\nالمطور لا يُصرح إذا كان أعزب أو متزوج ولا يرفع صورته الشخصية حتى لا تُفتتن البنات به."
                        color: Theme.textMuted
                        font.pixelSize: 14
                        lineHeight: 1.4
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Accordion {
                    title: "الرخصة"
                    content: "رخصة \"وقف\" العامة\nبسم الله الرّحمن الرّحيم\n\nرخصة وقف العامة الإصدار 2.0، 3 محرم 1435\n\nالتمهيد\n\nهذه الوثيقة هي الاتفاقية الحاكمة لاستخدام المواد التي تغطيها، حيث تُعتبر العقد المُبرم بين الناشر والمستفيد. نحن نرى أن الاتفاقيات الاحتكارية لا تقيد المستفيد فحسب، بل تؤثر على قيمة العمل الفكري، وتحوله من نور إلى مجرد سلعة يُمتلك فيها حق الملكية الفكرية للمودع الفكري الأول. رؤيتنا تقتصر على الشكل المعنوي للعمل الفكري نفسه وفقاً للقواعد أدناه، بخلاف الرخص الاحتكارية التي تضع قيوداً مجحفة.\n\nلدينا رؤية مختلفة، فنحن نقدم عملنا (مثل البرمجيات) ابتغاء مرضاة الله، وهذا هو ركيزة هذه الرخصة التي تميزها عن الرخص الاحتكارية. أي نية أخرى (مثل نشر المعرفة أو تحقيق الأرباح) يجب أن تتحقق بطرق لا تتعارض مع هدفنا الأخلاقي الأساسي.\n\nوفقاً لمعتقداتنا (والتي لا نفرضها على أحد) فإن الإسلام يحرم الاحتكار وكتمان العلم بشكل عام، وهذا ينبع من:\n- الحديث الصحيح: \"مَن سُئِلَ عَن عِلمٍ فَكَتَمَهُ، أُلجِمَ يَومَ القِيامَةِ بِلِجامٍ مِن نارٍ.\"\n- حدد الفقه الإسلامي ما يمكن تملكه، والقواعد لا تنطبق على الأفكار لأنها ليست شيئاً ملموساً ومحدوداً، وتقريباً جميع شروط الاتفاقيات الاحتكارية تندرج تحت حكم \"الغرر\" المحرم.\n- كتمان العلم النافع عمن يحتاجه يلحق ضرراً بالناس مقابل مكاسب دنيوية لأفراد قلائل، وهذا لا يبرره الشرع إذ \"لا ضرر ولا ضرار\".\n- ما يسمى بـ \"الملكية الفكرية\" يتمحور حول إعطاء المُلّاك الحق في منع ما أحله الله لكسب المال، وليس بتقديم خدمة أو سلع.\n\nنحن في \"وقف\" نهتم بمصلحة عامة الناس. ولا نغفل عن مصلحة صاحب العمل في نيل الأجر من الله تعالى. نعتقد أن حقوق النشر والتوزيع \"ممنوحة\" وليست \"محفوظة\".\n- أولاً: فضل وحقوق صاحب العمل الأخلاقية محفوظة ومعترف بها.\n- ثانياً: يحق للمؤلف الأصلي وأي طرف آخر تقاضي أجور على تحسين العمل أو تطويره أو تقديم خدمات مدفوعة... إلخ، ولكن ليس على العمل في شكله غير الملموس.\n\nالتعريفات\n- العمل الفكري: هو أي منتج فكري غير ملموس ونافع يمكن تمريره للآخرين أو نسخه دون تكلفة على المؤلف الأصلي.\n- الحامل (أو المطور): هو المؤلف المبدع أو الجهة التي قامت بتطوير العمل وجعله متاحاً.\n- المرخص له أو المستخدم: أي شخص أو جهة تستخدم العمل.\n- الرخصة: هذه الاتفاقية بين الطرفين وتُطبق بمجرد استخدام المنتج بأي شكل.\n\nالشروط\nكما يوحي الاسم \"وقف\"، يعلن الحامل أن عمله أُنتج وجُعل متاحاً للعامة لوجه الله كصدقة جارية.\nتمنح \"وقف\" المستخدمين الحق في الاستفادة من العمل بالتشغيل والنسخ وإعادة التوزيع وحتى التطوير وفقاً لما يلي:\n\n1. التمهيد والتعريفات تعتبر جزءاً لا يتجزأ من هذه الرخصة.\n2. الاستخدام: يحق للمستخدم استخدام العمل لأي غرض، وينصح الحامل بعدم استخدامه في الإضرار بالآخرين أو مخالفة مبادئ الإسلام، والحامل غير مسؤول عن أي انتهاكات.\n3. التغطية: يمكن أن تغطي رخصة وقف الأعمال المنشورة برخص أخرى لا تتعارض معها.\n4. الحد الزمني: الرخصة غير مقيدة بوقت، وكل استخدام للعمل يعتبر تاريخاً جديداً للموافقة.\n5. إعادة التوزيع: يحق للمستخدم إعادة توزيع العمل غير المعدل بأي كمية، مع الاعتراف بفضل صاحب العمل.\n6. التعديلات: يحق للمستخدم الحصول على المصدر وإجراء تعديلات.\n7. توزيع التعديلات: يمكن للمستخدم توزيع التعديلات تحت هذه الرخصة فقط بشرط الإشارة للعمل الأصلي.\n8. إخلاء المسؤولية: لا يتحمل الحامل أي مسؤولية قانونية أو أخلاقية عن الأضرار. يُقدم هذا العمل \"كما هو\"، والمسؤولية الكاملة تقع على المستخدم."
                }
            }
        }
    }
}