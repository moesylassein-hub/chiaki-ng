import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking

import "controls" as C

DialogView {
    id: dialog
    property string preferredMac: ""
    title: qsTr("Add Manual Console")
    buttonText: qsTr("Add")
    buttonEnabled: hostField.text.trim().length > 0 && consoleCombo.currentValue !== undefined && consoleCombo.currentValue !== "choose"
    onAccepted: {
        const mac = consoleCombo.currentValue
        const hosts = Chiaki.settings.registeredHosts
        const index = mac === "new" ? hosts.length : hosts.findIndex(h => h.mac === mac)
        if (index < 0) return
        Chiaki.addManualHost(index, hostField.text.trim());
        close();
    }

    Item {
        GridLayout {
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 20
            }
            columns: 2
            rowSpacing: 20
            columnSpacing: 20

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Host:")
            }

            C.TextField {
                id: hostField
                echoMode: Chiaki.settings.streamerMode ? TextInput.Password : TextInput.Normal
                Layout.preferredWidth: 400
                firstInFocusChain: true
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Registered Consoles:")
            }

            C.ComboBox {
                id: consoleCombo
                Layout.preferredWidth: 400
                lastInFocusChain: true
                textRole: "name"
                valueRole: "mac"
                Component.onCompleted: if (dialog.preferredMac) currentIndex = indexOfValue(dialog.preferredMac)
                model: {
                    let m = [];
                    if(Chiaki.settings.registeredHosts.length > 0)
                    {
                        m.push({
                            name: qsTr("Select an Option"),
                            mac: "choose",
                        });
                    }
                    let i = 0;
                    for (; i < Chiaki.settings.registeredHosts.length; ++i) {
                        let host = Chiaki.settings.registeredHosts[i];
                        m.push({
                            name: "%1 (%2)".arg(Chiaki.settings.streamerMode ? "hidden" : host.mac).arg(host.name),
                            mac: host.mac,
                        });
                    }
                    m.push({
                        name: qsTr("Register on first Connection"),
                        mac: "new",
                    });
                    return m;
                }
            }
        }
    }
}
