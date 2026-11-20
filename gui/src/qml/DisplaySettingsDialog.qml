import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs

import org.streetpea.chiaking

import "controls" as C

DialogView {
    id: dialog
    property alias gridHeight: displayGrid.height
    title: qsTr("Display Settings")
    header: qsTr("* Defaults in () to right of value or marked with (Default)")
    buttonVisible: false

    ScrollView {
        id: scroll
        clip: true
        contentWidth: availableWidth
        contentHeight: displayGrid.implicitHeight + 40
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        // Stream Display Settings
        GridLayout {
            id: displayGrid
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 20
            }
            columns: 3
            rowSpacing: 10
            columnSpacing: 20

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Screen borders")
            }
            Switch {
                objectName: "ambientBorders"
                text: qsTr("Ambient blur")
                checked: Chiaki.settings.ambientBorder
                enabled: Chiaki.window.ambientBorderAvailable
                onToggled: Chiaki.settings.ambientBorder = checked
                ToolTip.visible: hovered
                ToolTip.text: enabled ? qsTr("Fill the bars around the picture with a blurred copy of the game.") : qsTr("Requires libplacebo API 355 or later.")
            }
            Item {}

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Video shader")
            }
            RowLayout {
                Button {
                    text: qsTr("Load shader…")
                    enabled: !Chiaki.window.videoShaderBusy
                    onClicked: shaderDialog.open()
                }
                Button {
                    text: qsTr("Remove")
                    enabled: !!Chiaki.window.videoShaderName && !Chiaki.window.videoShaderBusy
                    onClicked: Chiaki.window.clearVideoShader()
                }
            }
            Item {}
            Label {
                Layout.columnSpan: 3
                Layout.fillWidth: true
                Layout.maximumWidth: scroll.availableWidth - 32
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                visible: text.length > 0
                text: [Chiaki.window.videoShaderName, Chiaki.window.videoShaderStatus].filter(s => s.length).join("  ·  ")
            }
            FileDialog {
                id: shaderDialog
                title: qsTr("Load an mpv video shader")
                nameFilters: [qsTr("GLSL shaders (*.glsl *.hook)"), qsTr("All files (*)")]
                onAccepted: Chiaki.window.importVideoShader(selectedFile)
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Target Primaries:")
            }

            C.ComboBox {
                firstInFocusChain: true
                Layout.preferredWidth: Math.min(600, scroll.availableWidth * 0.51)
                model: [qsTr("Auto"), qsTr("ITU-R Rec. BT.601 NTSC (Standard Gamut)"), qsTr("ITU-R Rec. BT.601 PAL (Standard Gamut)"), qsTr("ITU-R Rec. BT.709 (Standard Gamut)"), qsTr("ITU-R Rec. BT.470 M (Standard Gamut)"), qsTr("EBU Tech. 3213-E (Standard Gamut)"), qsTr("ITU-R Rec. BT.2020 (Wide Gamut)"), qsTr("Apple RGB (Wide Gamut)"), qsTr("Adobe RGB (Wide Gamut)"), qsTr("ProPhoto RGB (Wide Gamut)"), qsTr("CIE 1931 RGB primaries (Wide Gamut)"), qsTr("DCI-P3 (Wide Gamut)"), qsTr("DCI-P3 with D65 white point (Wide Gamut)"), qsTr("Panasonic V-Gamut (Wide Gamut)"), qsTr("Sony S-Gamut (Wide Gamut)"), qsTr("Traditional film primaries with Illuminant C (Wide Gamut)"), qsTr("ACES Primaries #0 (Wide Gamut)"), qsTr("ACES Primaries #1 (Wide Gamut)")]
                currentIndex: Chiaki.settings.displayTargetPrim
                onActivated: index => Chiaki.settings.displayTargetPrim = index
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("(Auto)")
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Target Transfer Characteristics:")
            }

            C.ComboBox {
                Layout.preferredWidth: Math.min(600, scroll.availableWidth * 0.51)
                model: [qsTr("Auto"), qsTr("ITU-R Rec. BT.1886 (SDR)"), qsTr("IEC 61966-2-4 sRGB (SDR)"), qsTr("Linear light content (SDR)"), qsTr("IPure power gamma 1.8 (SDR)"), qsTr("Pure power gamma 2.0 (SDR)"), qsTr("Pure power gamma 2.2 (SDR)"), qsTr("Pure power gamma 2.4 (SDR)"), qsTr("Pure power gamma 2.6 (SDR)"), qsTr("Pure power gamma 2.8 (SDR)"), qsTr("ProPhoto RGB (SDR)"), qsTr("Digital Cinema Distribution Master (SDR)"), qsTr("ITU-R BT.2100 PQ / SMPTE ST2048 (HDR)"), qsTr("ITU-R BT.2100 HLG / ARIB STD-B67 (HDR)"), qsTr("Panasonic V-Log (HDR)"), qsTr("Sony S-Log1 (HDR)"), qsTr("Sony S-Log2 (HDR)")]
                currentIndex: Chiaki.settings.displayTargetTrc
                onActivated: index => Chiaki.settings.displayTargetTrc = index
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("(Auto)")
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Target Peak:")
            }

            C.ComboBox {
                id: targetPeakChoice
                Layout.preferredWidth: Math.min(400, scroll.availableWidth * 0.51)
                model: [qsTr("Auto"), qsTr("Numeric Value")]
                currentIndex: {
                    if(Chiaki.settings.displayTargetPeak == 0)
                        0;
                    else
                        1;
                }
                onActivated: index => {
                    if(index == 0)
                        Chiaki.settings.displayTargetPeak = 0;
                    else if(index == 1)
                        Chiaki.settings.displayTargetPeak = 1000;
                }
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("(Auto)")
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Target Peak Value:")
                visible: targetPeakChoice.currentIndex == 1
            }
            
            C.Slider {
                id: targetPeakValue
                Layout.preferredWidth: 250
                from: 10
                to: 10000
                stepSize: 10
                value: Chiaki.settings.displayTargetPeak
                onMoved: Chiaki.settings.displayTargetPeak = value

                Label {
                    anchors {
                        left: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    text: parent.value + qsTr(" nits")
                }
                visible: targetPeakChoice.currentIndex == 1
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("(1000 nits)")
                visible: targetPeakChoice.currentIndex == 1
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Target Contrast:")
            }

            C.ComboBox {
                id: targetContrastChoice
                Layout.preferredWidth: Math.min(400, scroll.availableWidth * 0.51)
                lastInFocusChain: currentIndex != 2
                model: [qsTr("Auto"), qsTr("Infinity"), qsTr("Numeric Value")]
                currentIndex: {
                    if(Chiaki.settings.displayTargetContrast == -1)
                        1;
                    else if(Chiaki.settings.displayTargetContrast == 0)
                        0;
                    else
                        2;
                }
                onActivated: index => {
                    if(index == 0)
                        Chiaki.settings.displayTargetContrast = 0;
                    else if(index == 1)
                        Chiaki.settings.displayTargetContrast = -1;
                    else if(index == 2)
                        Chiaki.settings.displayTargetContrast = 1000;
                }
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("(Auto)")
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Target Contrast Value:")
                visible: targetContrastChoice.currentIndex == 2
            }
            
            C.Slider {
                id: targetContrastValue
                Layout.preferredWidth: 250
                from: 10
                to: 1000000
                stepSize: 1000
                value: Chiaki.settings.displayTargetContrast
                onMoved: Chiaki.settings.displayTargetContrast = value

                Label {
                    anchors {
                        left: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    text: parent.value
                }
                visible: targetContrastChoice.currentIndex == 2
                lastInFocusChain: true
            }

            Label {
                Layout.alignment: Qt.AlignRight
                visible: targetContrastChoice.currentIndex == 2
                text: qsTr("(1000)")
            }
        }
    }
}