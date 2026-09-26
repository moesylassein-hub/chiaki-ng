import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking

Pane {
    id: consolePane
    padding: 0

    readonly property color pageColor: "#0b1018"
    readonly property color surfaceColor: "#121a25"
    readonly property color surfaceHoverColor: "#182334"
    readonly property color borderColor: "#263244"
    readonly property color secondaryTextColor: "#aab6c5"
    readonly property color successColor: "#55d68b"
    readonly property color standbyColor: "#f2bd62"

    function stateLabel(host) {
        if (host.duid && !host.discovered)
            return qsTr("Remote")
        if (host.state === "standby")
            return qsTr("Rest mode")
        if (host.state)
            return host.state.charAt(0).toUpperCase() + host.state.slice(1)
        return qsTr("Saved")
    }

    function stateColor(host) {
        if (host.state === "standby")
            return standbyColor
        if (host.discovered)
            return successColor
        return secondaryTextColor
    }

    function withAlpha(colorValue, alpha) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, alpha)
    }

    StackView.onActivated: {
        forceActiveFocus(Qt.TabFocusReason)
        if (!Chiaki.autoConnect && !root.initialAsk && !Chiaki.window.directStream) {
            root.initialAsk = true
            if (Chiaki.settings.addSteamShortcutAsk && (typeof Chiaki.createSteamShortcut === "function"))
                root.showRemindDialog(qsTr("Official Steam artwork + controller layout"), qsTr("Would you like to either create a new non-Steam game for chiaki-ng\nor update an existing non-Steam game with the official artwork and controller layout?") + "\n\n" + qsTr("(Note: If you select no now and want to do this later, click the button or press R3 from the main menu.)"), false, () => root.showSteamShortcutDialog(true))
            else if (Chiaki.settings.remotePlayAsk) {
                if (!Chiaki.settings.psnRefreshToken || !Chiaki.settings.psnAuthToken || !Chiaki.settings.psnAuthTokenExpiry || !Chiaki.settings.psnAccountId)
                    root.showRemindDialog(qsTr("Remote Play via PSN"), qsTr("Would you like to connect to PSN?\nThis enables:\n- Automatic registration\n- Playing outside of your home network without port forwarding?") + "\n\n" + qsTr("(Note: If you select no now and want to do this later, go to the Config section of the settings.)"), true, () => root.showPSNTokenDialog(false))
                else
                    Chiaki.settings.remotePlayAsk = false
            }
        }
    }

    Keys.onUpPressed: {
        if (hostsView.currentItem && hostsView.currentItem.visible) {
            hostsView.decrementCurrentIndex()
            let guard = hostsView.count
            while (hostsView.currentItem && !hostsView.currentItem.visible && guard-- > 0)
                hostsView.decrementCurrentIndex()
        }
    }
    Keys.onDownPressed: {
        if (hostsView.currentItem && hostsView.currentItem.visible) {
            hostsView.incrementCurrentIndex()
            let guard = hostsView.count
            while (hostsView.currentItem && !hostsView.currentItem.visible && guard-- > 0)
                hostsView.incrementCurrentIndex()
        }
    }
    Keys.onMenuPressed: settingsButton.clicked()
    Keys.onReturnPressed: if (hostsView.currentItem && hostsView.currentItem.visible) hostsView.currentItem.connectToHost()
    Keys.onYesPressed: if (hostsView.currentItem && hostsView.currentItem.visible) hostsView.currentItem.wakeUpHost()
    Keys.onNoPressed: if (hostsView.currentItem && hostsView.currentItem.visible) hostsView.currentItem.deleteHost()
    Keys.onEscapePressed: root.showConfirmDialog(qsTr("Quit"), qsTr("Are you sure you want to quit?"), () => Qt.quit())
    Keys.onPressed: (event) => {
        if (event.modifiers)
            return
        switch (event.key) {
        case Qt.Key_PageUp:
            if (hostsView.currentItem && hostsView.currentItem.visible) hostsView.currentItem.setConsolePin()
            event.accepted = true
            break
        case Qt.Key_PageDown:
            if (Chiaki.settings.psnAuthToken) Chiaki.refreshPsnToken()
            event.accepted = true
            break
        case Qt.Key_F1:
            if (typeof Chiaki.createSteamShortcut === "function") root.showSteamShortcutDialog(false)
            event.accepted = true
            break
        case Qt.Key_F2:
            root.showManualHostDialog()
            event.accepted = true
            break
        }
    }

    background: Rectangle {
        color: consolePane.pageColor
    }

    Rectangle {
        id: header
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 104
        color: "#0e1621"
        border.color: "#1d2a3a"
        border.width: 1

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 24
                rightMargin: 20
            }
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: qsTr("Remote Play")
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                    color: "white"
                }
                Label {
                    text: qsTr("Choose a console to start streaming")
                    font.pixelSize: 14
                    color: consolePane.secondaryTextColor
                }
            }

            Button {
                visible: typeof Chiaki.createSteamShortcut === "function"
                text: qsTr("Steam Shortcut")
                flat: true
                focusPolicy: Qt.NoFocus
                onClicked: root.showSteamShortcutDialog(false)
                Material.roundedScale: Material.MediumScale
            }

            Button {
                visible: Chiaki.settings.psnAuthToken
                text: qsTr("Refresh PSN")
                flat: true
                focusPolicy: Qt.NoFocus
                onClicked: Chiaki.refreshPsnToken()
                Material.roundedScale: Material.MediumScale
            }

            Button {
                text: qsTr("Add Console")
                focusPolicy: Qt.NoFocus
                onClicked: root.showManualHostDialog()
                Material.roundedScale: Material.MediumScale
            }

            Button {
                id: settingsButton
                text: qsTr("Settings")
                flat: true
                focusPolicy: Qt.NoFocus
                icon.source: "qrc:/icons/settings-20px.svg"
                onClicked: root.showSettingsDialog()
                Material.roundedScale: Material.MediumScale
            }
        }
    }

    ListView {
        id: hostsView
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: footer.top
            margins: 24
            topMargin: 20
            bottomMargin: 16
        }
        spacing: 14
        clip: true
        keyNavigationWraps: true
        model: Chiaki.hosts

        onCountChanged: {
            if (!hostsView.currentItem)
                hostsView.incrementCurrentIndex()
            if (!hostsView.currentItem)
                return
            if (!hostsView.currentItem.visible) {
                for (let i = 0; i < hostsView.count; i++) {
                    hostsView.incrementCurrentIndex()
                    if (hostsView.currentItem && hostsView.currentItem.visible)
                        break
                }
            }
        }

        delegate: ItemDelegate {
            id: delegate
            visible: modelData.display
            width: ListView.view ? ListView.view.width : 0
            height: modelData.display ? 156 : 0
            highlighted: ListView.isCurrentItem
            hoverEnabled: true
            onClicked: connectToHost()

            function connectToHost() {
                if (modelData.discovered)
                    Chiaki.connectToHost(index, modelData.name)
                else
                    Chiaki.connectToHost(index)
            }

            function wakeUpHost() {
                if (!modelData.discovered && !modelData.duid)
                    Chiaki.wakeUpHost(index)
            }

            function deleteHost() {
                if (modelData.manual)
                    root.showConfirmDialog(qsTr("Delete Console"), qsTr("Are you sure you want to delete this console?"), () => Chiaki.deleteHost(index))
                else if (modelData.discovered && !modelData.registered)
                    root.showConfirmDialog(qsTr("Hide Console"), qsTr("Are you sure you want to hide this console?") + "\n\n" + qsTr("Note: You can unhide it from Settings → Consoles → Hidden Consoles."), () => Chiaki.hideHost(modelData.mac, modelData.name))
            }

            function setConsolePin() {
                root.showConsolePinDialog(index)
            }

            background: Rectangle {
                radius: 18
                color: delegate.down || delegate.highlighted ? "#1c2b40" : (delegate.hovered ? consolePane.surfaceHoverColor : consolePane.surfaceColor)
                border.width: delegate.highlighted ? 2 : 1
                border.color: delegate.highlighted ? Material.accent : consolePane.borderColor

                Behavior on color { ColorAnimation { duration: 110 } }
            }

            contentItem: RowLayout {
                spacing: 20

                Rectangle {
                    Layout.preferredWidth: 118
                    Layout.fillHeight: true
                    radius: 14
                    color: "#0d141e"

                    Image {
                        anchors {
                            fill: parent
                            margins: 12
                        }
                        fillMode: Image.PreserveAspectFit
                        source: "image://svg/console-ps" + (modelData.ps5 ? "5" : "4") + (modelData.state === "standby" ? "#light_standby" : "#light_on")
                        sourceSize: Qt.size(width, height)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label {
                            Layout.fillWidth: true
                            text: modelData.name || (modelData.ps5 ? qsTr("PlayStation 5") : qsTr("PlayStation 4"))
                            color: "white"
                            font.pixelSize: 21
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            Layout.preferredWidth: statusLabel.implicitWidth + 22
                            Layout.preferredHeight: 28
                            radius: 14
                            color: consolePane.withAlpha(consolePane.stateColor(modelData), 0.14)
                            border.color: consolePane.withAlpha(consolePane.stateColor(modelData), 0.52)

                            Label {
                                id: statusLabel
                                anchors.centerIn: parent
                                text: consolePane.stateLabel(modelData)
                                color: consolePane.stateColor(modelData)
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: {
                            if (modelData.duid)
                                return modelData.discovered ? qsTr("PSN console • automatic registration available") : qsTr("PSN remote connection")
                            if (modelData.address)
                                return qsTr("%1 • %2").arg(modelData.registered ? qsTr("Registered") : qsTr("Not registered")).arg(Chiaki.settings.streamerMode ? qsTr("address hidden") : modelData.address)
                            return modelData.registered ? qsTr("Registered console") : qsTr("Console discovered on your network")
                        }
                        color: consolePane.secondaryTextColor
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: !!modelData.app || (!!modelData.titleId && !modelData.duid)
                        text: modelData.app ? qsTr("Now playing: %1").arg(modelData.app) : qsTr("Title ID: %1").arg(modelData.titleId)
                        color: "#7f90a5"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    Button {
                        text: modelData.state === "standby" && modelData.registered && !modelData.duid && !modelData.discovered ? qsTr("Wake Up") : qsTr("Connect")
                        focusPolicy: Qt.NoFocus
                        onClicked: {
                            if (modelData.state === "standby" && modelData.registered && !modelData.duid && !modelData.discovered)
                                delegate.wakeUpHost()
                            else
                                delegate.connectToHost()
                        }
                        Material.roundedScale: Material.MediumScale
                    }

                    RowLayout {
                        spacing: 0

                        Button {
                            visible: modelData.registered
                            text: qsTr("PIN")
                            flat: true
                            focusPolicy: Qt.NoFocus
                            onClicked: delegate.setConsolePin()
                        }

                        Button {
                            visible: modelData.manual || (modelData.discovered && !modelData.registered)
                            text: modelData.manual ? qsTr("Delete") : qsTr("Hide")
                            flat: true
                            focusPolicy: Qt.NoFocus
                            onClicked: delegate.deleteHost()
                        }
                    }
                }
            }
        }

        ScrollBar.vertical: ScrollBar { }
    }

    ColumnLayout {
        anchors.centerIn: hostsView
        visible: hostsView.count === 0
        spacing: 10

        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 116
            Layout.preferredHeight: 116
            source: "qrc:/icons/chiaking-logo-white.svg"
            opacity: 0.35
            sourceSize: Qt.size(width, height)
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("No consoles found yet")
            color: "white"
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Chiaki.discoveryEnabled ? qsTr("Keep your PlayStation on the same network, or add it manually.") : qsTr("Network discovery is off. Turn it on below or add a console manually.")
            color: consolePane.secondaryTextColor
            font.pixelSize: 14
        }
        Button {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Add Console")
            onClicked: root.showManualHostDialog()
        }
    }

    Rectangle {
        id: footer
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 58
        color: "#0e1621"
        border.color: "#1d2a3a"
        border.width: 1

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 20
                rightMargin: 20
            }

            Switch {
                id: discoverySwitch
                text: qsTr("Network discovery")
                checked: Chiaki.discoveryEnabled
                focusPolicy: Qt.NoFocus
                onToggled: Chiaki.discoveryEnabled = checked
            }

            Label {
                text: Chiaki.discoveryEnabled ? qsTr("Scanning for local consoles") : qsTr("Discovery paused")
                color: consolePane.secondaryTextColor
                font.pixelSize: 12
            }

            Item { Layout.fillWidth: true }

            Label {
                text: qsTr("chiaki-ng %1").arg(Qt.application.version)
                color: "#738399"
                font.pixelSize: 12
            }

            Button {
                text: qsTr("Quit")
                flat: true
                focusPolicy: Qt.NoFocus
                onClicked: root.showConfirmDialog(qsTr("Quit"), qsTr("Are you sure you want to quit?"), () => Qt.quit())
            }
        }
    }
}
