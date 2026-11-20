import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking
import "ConnectionRoutes.js" as Routes

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

    property string selectedRoute: ""
    readonly property var routes: Routes.visibleHosts(Chiaki.hosts, root.remoteHome)

    function moveSelection(delta) {
        if (!routes.length)
            return
        const next = (hostsView.currentIndex + delta + routes.length) % routes.length
        selectedRoute = routes[next].routeId
        hostsView.positionViewAtIndex(next, ListView.Contain)
    }

    function remoteAction() {
        if (Chiaki.settings.psnAuthToken)
            Chiaki.refreshPsnToken()
        else
            root.showPSNTokenDialog(false, false)
    }

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

    Keys.onUpPressed: moveSelection(-1)
    Keys.onDownPressed: moveSelection(1)
    Keys.onLeftPressed: root.remoteHome = false
    Keys.onRightPressed: root.remoteHome = true
    Keys.onMenuPressed: navigation.open()
    Keys.onReturnPressed: {
        if (hostsView.currentItem)
            hostsView.currentItem.connectToHost()
        else if (root.remoteHome)
            remoteAction()
        else
            root.showManualHostDialog()
    }
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
        height: consolePane.width < 740 ? 64 : 80
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

            ToolButton {
                id: menuButton
                text: "☰"
                font.pixelSize: 24
                Accessible.name: qsTr("Navigation")
                onClicked: navigation.open()
            }
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
                    text: Chiaki.settings.currentProfile || qsTr("Default profile")
                    font.pixelSize: 14
                    color: consolePane.secondaryTextColor
                }
            }

            Button {
                visible: consolePane.width > 850 && typeof Chiaki.createSteamShortcut === "function"
                text: qsTr("Steam Shortcut")
                flat: true
                focusPolicy: Qt.NoFocus
                onClicked: root.showSteamShortcutDialog(false)
                Material.roundedScale: Material.MediumScale
            }

            Button {
                visible: consolePane.width >= 700
                text: qsTr("Profiles")
                Accessible.name: qsTr("Switch profile")
                Layout.maximumWidth: 170
                flat: true
                onClicked: root.showProfileDialog()
            }

            Button {
                visible: consolePane.width >= 580
                text: qsTr("Add Console")
                focusPolicy: Qt.NoFocus
                onClicked: root.showManualHostDialog()
                Material.roundedScale: Material.MediumScale
            }

            Button {
                id: settingsButton
                visible: consolePane.width >= 500
                text: qsTr("Settings")
                flat: true
                focusPolicy: Qt.NoFocus
                icon.source: "qrc:/icons/settings-20px.svg"
                onClicked: root.showSettingsDialog()
                Material.roundedScale: Material.MediumScale
            }
        }
    }

    RowLayout {
        id: connectionBar
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 12

        ConnectionCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 240
            compact: consolePane.width < 700 || consolePane.height < 480
            text: qsTr("Local Connect")
            detail: qsTr("On your home network")
            selected: !root.remoteHome
            onClicked: root.remoteHome = false
        }
        ConnectionCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 240
            compact: consolePane.width < 700 || consolePane.height < 480
            text: qsTr("Remote Connect")
            detail: qsTr("Over the internet")
            selected: root.remoteHome
            onClicked: root.remoteHome = true
        }
        ComboBox {
            id: playMode
            visible: consolePane.width > 550
            Accessible.name: qsTr("Session mode")
            implicitContentWidthPolicy: ComboBox.WidestText
            model: [qsTr("Video and audio"), qsTr("Video only"), qsTr("Audio only"), qsTr("Gamepad only")]
            currentIndex: Chiaki.settings.audioVideoDisabled
            onActivated: (index) => Chiaki.settings.audioVideoDisabled = index
        }
    }

    ListView {
        id: hostsView
        anchors {
            top: connectionBar.bottom
            left: parent.left
            right: parent.right
            bottom: recentGames.visible ? recentGames.top : footer.top
            margins: 24
            topMargin: 20
            bottomMargin: 16
        }
        spacing: 14
        clip: true
        keyNavigationWraps: true
        model: consolePane.routes
        currentIndex: count ? Math.max(0, Routes.indexOfRoute(consolePane.routes, consolePane.selectedRoute)) : -1

        delegate: ItemDelegate {
            id: delegate
            width: ListView.view ? ListView.view.width : 0
            height: 156
            highlighted: ListView.isCurrentItem
            hoverEnabled: true
            onClicked: connectToHost()

            function connectToHost() {
                const idx = Routes.indexOfRoute(Chiaki.hosts, modelData.routeId)
                if (idx >= 0) {
                    consolePane.selectedRoute = modelData.routeId
                    Chiaki.connectToHost(idx, modelData.discovered ? modelData.name : "")
                }
            }

            function wakeUpHost() {
                if (modelData.registered && !modelData.duid)
                    Chiaki.wakeUpHost(Routes.indexOfRoute(Chiaki.hosts, modelData.routeId))
            }

            function deleteHost() {
                const host = modelData
                if (host.manual) {
                    root.showConfirmDialog(qsTr("Delete Console"), qsTr("Remove this saved address?"),
                        () => Chiaki.deleteHost(Routes.indexOfRoute(Chiaki.hosts, host.routeId)))
                } else if (host.discovered && !host.registered) {
                    root.showConfirmDialog(qsTr("Hide Console"), qsTr("Hide this console from local discovery?"),
                        () => Chiaki.hideHost(host.mac, host.name))
                }
            }

            function setConsolePin() {
                if (modelData.registered)
                    root.showConsolePinDialog(modelData.routeId)
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
                        visible: !Chiaki.settings.streamerMode && (!!modelData.app || (!!modelData.titleId && !modelData.duid))
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
                        text: !modelData.registered ? qsTr("Register") :
                              modelData.state === "standby" ? qsTr("Wake and connect") : qsTr("Connect")
                        focusPolicy: Qt.NoFocus
                        onClicked: delegate.connectToHost()
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
        width: Math.min(520, hostsView.width)
        visible: hostsView.count === 0
        spacing: 10

        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 116
            visible: hostsView.height > 235
            Layout.preferredHeight: 116
            source: "qrc:/icons/chiaking-logo-white.svg"
            opacity: 0.35
            sourceSize: Qt.size(width, height)
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.remoteHome ? qsTr("No remote consoles") : qsTr("No local consoles")
            color: "white"
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.remoteHome
                ? (Chiaki.settings.psnAuthToken ? qsTr("Register your console locally, then refresh PSN. You can also add a remote address.") : qsTr("Sign in to PSN or add a remote address."))
                : (Chiaki.discoveryEnabled ? qsTr("Enable Remote Play on your PlayStation and connect it to this network.") : qsTr("Turn on network discovery or add your console by address."))
            color: consolePane.secondaryTextColor
            font.pixelSize: 14
        }
        Button {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Add by address")
            onClicked: root.showManualHostDialog()
        }
    }

    ColumnLayout {
        id: recentGames
        readonly property var selectedHost: consolePane.routes[hostsView.currentIndex]
        readonly property var titles: selectedHost && selectedHost.recentGames ? selectedHost.recentGames : []
        visible: titles.length > 0 && !Chiaki.settings.streamerMode
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footer.top
        anchors.margins: 20
        spacing: 4
        Label {
            text: qsTr("Recent games on %1").arg(recentGames.selectedHost ? recentGames.selectedHost.name : "")
            font.weight: Font.DemiBold
        }
        Label {
            Layout.fillWidth: true
            text: recentGames.titles.join("  ·  ")
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: consolePane.secondaryTextColor
        }
    }

    Drawer {
        id: navigation
        width: Math.min(310, consolePane.width * 0.85)
        height: consolePane.height
        modal: true
        onOpened: localNav.forceActiveFocus()
        onClosed: if (consolePane.StackView.status === StackView.Active) menuButton.forceActiveFocus()
        background: Rectangle { color: "#111c29" }
        contentItem: ScrollView {
            clip: true
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                spacing: 4
                Label {
                    Layout.margins: 16
                    text: qsTr("Remote Play")
                    color: "#f0f7ff"
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                }
                ItemDelegate {
                    id: localNav
                    Layout.fillWidth: true
                    text: qsTr("Local Connect")
                    highlighted: !root.remoteHome
                    onClicked: { root.remoteHome = false; navigation.close() }
                }
                ItemDelegate {
                    Layout.fillWidth: true
                    text: qsTr("Remote Connect")
                    highlighted: root.remoteHome
                    onClicked: { root.remoteHome = true; navigation.close() }
                }
                ItemDelegate {
                    Layout.fillWidth: true
                    text: qsTr("Add console")
                    onClicked: { navigation.close(); root.showManualHostDialog() }
                }
                ItemDelegate {
                    Layout.fillWidth: true
                    text: qsTr("Profiles")
                    onClicked: { navigation.close(); root.showProfileDialog() }
                }
                ItemDelegate {
                    Layout.fillWidth: true
                    text: qsTr("Display settings")
                    onClicked: { navigation.close(); root.showDisplaySettingsDialog() }
                }
                ItemDelegate {
                    Layout.fillWidth: true
                    text: qsTr("Settings")
                    onClicked: { navigation.close(); root.showSettingsDialog() }
                }
                ComboBox {
                    Layout.fillWidth: true
                    Layout.margins: 12
                    visible: !playMode.visible
                    Accessible.name: qsTr("Session mode")
                    model: playMode.model
                    currentIndex: Chiaki.settings.audioVideoDisabled
                    onActivated: index => Chiaki.settings.audioVideoDisabled = index
                }
            }
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
                visible: !root.remoteHome
                text: qsTr("Network discovery")
                checked: Chiaki.discoveryEnabled
                focusPolicy: Qt.NoFocus
                onToggled: Chiaki.discoveryEnabled = checked
            }

            Label {
                visible: !root.remoteHome && consolePane.width > 680
                text: Chiaki.discoveryEnabled ? qsTr("Scanning for local consoles") : qsTr("Discovery paused")
                color: consolePane.secondaryTextColor
                font.pixelSize: 12
            }

            Button {
                visible: root.remoteHome
                text: Chiaki.settings.psnAuthToken ? qsTr("Refresh PSN consoles") : qsTr("Sign in to PSN")
                onClicked: consolePane.remoteAction()
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
