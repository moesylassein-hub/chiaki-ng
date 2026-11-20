import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import org.streetpea.chiaking
import "ConnectionRoutes.js" as Routes

Pane {
    id: home
    padding: 0
    readonly property int inset: width < 640 ? 16 : 40
    readonly property color ink: "#f2f5fa"
    readonly property color muted: "#b6c0d0"
    readonly property color accent: "#09dfb9"
    readonly property color focusColor: "#ffdf4a"
    readonly property var cards: Routes.consoleCards(Chiaki.hosts, Chiaki.settings.registeredHosts)
    property string activeId: ""
    readonly property var activeCard: cards.find(c => c.id === activeId) || null
    readonly property bool privateView: Chiaki.settings.streamerMode

    function routeLabel(route) {
        if (route.duid && !route.discovered) return qsTr("Automatic via PSN")
        if (privateView) return route.discovered ? qsTr("Discovered console") : qsTr("Saved address")
        return route.address || route.name
    }
    function openConsole(card) {
        activeId = card.id
        root.remoteHome = !card.local.length && card.remote.length > 0
        actions.open()
    }
    function connectRoute(route) {
        if (!route) return
        const i = Routes.indexOfRoute(Chiaki.hosts, route.routeId)
        if (i < 0) return
        actions.close()
        Chiaki.connectToHost(i, route.discovered ? route.name : "")
    }
    function currentSubtitle(card) {
        if (privateView) return card.ps5 ? "PS5" : "PS4"
        return card.app || card.history[0] || (card.state === "standby" ? qsTr("Rest mode") :
                card.state === "offline" ? qsTr("Saved console") : qsTr("Available on your network"))
    }
    function cardArtwork(card) {
        if (privateView) return ""
        const title = (card.app || card.history[0] || "").toLowerCase()
        const game = Chiaki.gameLibrary.games.find(g => g.title.toLowerCase() === title)
        return game?.image || ""
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


    Keys.onMenuPressed: more.open()
    Keys.onEscapePressed: root.showConfirmDialog(qsTr("Quit"), qsTr("Close chiaki-ng?"), () => Qt.quit())
    Keys.onReturnPressed: {
        if (cards.length) openConsole(cards[0])
        else root.showRegistDialog("255.255.255.255", true)
    }
    Keys.onPressed: event => {
        if (event.modifiers) return
        if (event.key === Qt.Key_F2) { root.showManualHostDialog(); event.accepted = true }
        if (event.key === Qt.Key_PageDown && Chiaki.settings.psnAuthToken) { Chiaki.refreshPsnToken(); event.accepted = true }
        if (event.key === Qt.Key_F1 && typeof Chiaki.createSteamShortcut === "function") { root.showSteamShortcutDialog(false); event.accepted = true }
    }

    background: HomeBackground { styleMode: Chiaki.settings.homeBackground }
    component Pill: Rectangle {
        implicitHeight: 50
        radius: height / 2
        color: "#192d3544"
        border.color: "#55717b90"
    }
    component Tool: ToolButton {
        id: tool
        required property string description
        implicitWidth: 44
        implicitHeight: 42
        Accessible.name: description
        ToolTip.visible: hovered
        ToolTip.text: description
        font.pixelSize: 21
        contentItem: Text { text: tool.text; color: home.ink; font: tool.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        background: Rectangle {
            radius: 20
            color: tool.hovered ? "#334c6179" : "transparent"
            border.color: tool.visualFocus ? home.focusColor : "transparent"
            border.width: 2
        }
    }
    RowLayout {
        id: toolbar
        objectName: "homeToolbar"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: home.inset
        anchors.rightMargin: home.inset
        anchors.topMargin: 15
        spacing: home.width > 640 ? 22 : 7
        Button {
            id: profile
            implicitHeight: 50
            leftPadding: 16
            rightPadding: 16
            Layout.maximumWidth: 215
            Accessible.name: qsTr("Switch profile")
            text: (home.privateView ? qsTr("Profile") : Chiaki.settings.currentProfile || qsTr("Default profile")) + "  ⌄"
            contentItem: RowLayout {
                spacing: 9
                Rectangle {
                    implicitWidth: 25; implicitHeight: 25; radius: 9; color: "#dae4f2"
                    Text { anchors.centerIn: parent; text: "●"; font.pixelSize: 13; color: "#48596e" }
                }
                Label { Layout.fillWidth: true; text: profile.text; textFormat: Text.PlainText; elide: Text.ElideRight; color: home.ink }
            }
            background: Pill { border.color: profile.visualFocus ? home.focusColor : "#55677289" }
            onClicked: root.showProfileDialog()
        }
        Pill {
            implicitWidth: toolsRow.implicitWidth + 10
            RowLayout {
                id: toolsRow
                anchors.centerIn: parent
                spacing: 1
                Tool {
                    text: "?"; description: qsTr("Connection help")
                    onClicked: root.showInfoDialog(qsTr("Remote Play"), qsTr("Enable Remote Play on your console, then choose Link console. Select a saved console to connect on your home network or over the internet."))
                }
                Tool { text: "⇄"; description: qsTr("Internet connection settings"); onClicked: root.showSettingsDialog(7) }
                Tool { text: "⚙"; description: qsTr("Settings"); onClicked: root.showSettingsDialog() }
            }
        }
        Item { Layout.fillWidth: true }
        Pill {
            implicitWidth: 53
            Tool {
                anchors.centerIn: parent
                text: "⋯"; description: qsTr("More actions")
                onClicked: more.open()
                Menu {
                    id: more
                    y: parent.height
                    MenuItem { text: qsTr("Add by address"); onTriggered: root.showManualHostDialog() }
                    MenuItem {
                        text: qsTr("Network discovery"); checkable: true; checked: Chiaki.discoveryEnabled
                        onTriggered: Chiaki.discoveryEnabled = !Chiaki.discoveryEnabled
                    }
                    MenuItem { text: qsTr("Refresh PSN consoles"); enabled: !!Chiaki.settings.psnAuthToken; onTriggered: Chiaki.refreshPsnToken() }
                    MenuItem { text: qsTr("Display settings"); onTriggered: root.showDisplaySettingsDialog() }
                    MenuItem { visible: typeof Chiaki.createSteamShortcut === "function"; height: visible ? implicitHeight : 0; text: qsTr("Steam shortcut"); onTriggered: root.showSteamShortcutDialog(false) }
                    MenuItem { text: qsTr("About chiaki-ng"); onTriggered: root.showInfoDialog("chiaki-ng", qsTr("Open-source Remote Play client. Version %1").arg(Qt.application.version)) }
                }
            }
        }
    }

    ScrollView {
        id: scroll
        anchors.top: toolbar.bottom
        anchors.topMargin: home.height < 520 ? 13 : 38
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: scroll.availableWidth
            spacing: 0
            Label {
                Layout.leftMargin: home.inset
                Layout.bottomMargin: 14
                text: home.cards.some(c => !c.registered) ? qsTr("Your consoles") : qsTr("Registered consoles")
                color: home.ink
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }
            Flow {
                id: tiles
                Layout.fillWidth: true
                Layout.leftMargin: home.inset
                Layout.rightMargin: home.inset
                Layout.preferredHeight: childrenRect.height
                spacing: 14
                Repeater {
                    model: home.cards
                    delegate: Button {
                        id: consoleTile
                        required property var modelData
                        required property int index
                        width: Math.min(370, tiles.width)
                        height: Math.min(205, Math.max(128, width * 0.55))
                        padding: 0
                        Accessible.name: modelData.name + ", " + home.currentSubtitle(modelData)
                        onClicked: home.openConsole(modelData)
                        Keys.onRightPressed: nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
                        Keys.onLeftPressed: nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason)
                        background: Rectangle {
                            radius: 15
                            color: "#101b2b"
                            border.width: consoleTile.visualFocus ? 3 : 1
                            border.color: consoleTile.visualFocus ? home.focusColor : consoleTile.hovered ? "#9bacbf" : "#677385"
                        }
                        contentItem: Item {
                            anchors.margins: 4
                            Image {
                                id: cover
                                anchors.fill: parent; anchors.margins: 5
                                source: home.cardArtwork(consoleTile.modelData)
                                asynchronous: true; fillMode: Image.PreserveAspectCrop; clip: true
                                visible: status === Image.Ready
                            }
                            Image {
                                anchors.right: parent.right; anchors.rightMargin: 23
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.50; height: parent.height * 0.78
                                source: "image://svg/console-ps" + (consoleTile.modelData.ps5 ? "5" : "4") + "#light_on"
                                fillMode: Image.PreserveAspectFit; opacity: 0.48; visible: !cover.visible
                            }
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 3; radius: 12
                                gradient: Gradient {
                                    GradientStop { position: 0; color: "#00080c15" }
                                    GradientStop { position: 0.58; color: "#39070c16" }
                                    GradientStop { position: 1; color: "#ee050811" }
                                }
                            }
                            Column {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                anchors.margins: 18; spacing: 3
                                Label { width: parent.width; text: consoleTile.modelData.name; textFormat: Text.PlainText; elide: Text.ElideRight; color: "white"; font.pixelSize: 18 }
                                Label { width: parent.width; text: home.currentSubtitle(consoleTile.modelData); textFormat: Text.PlainText; elide: Text.ElideRight; color: home.muted; font.pixelSize: 13 }
                            }
                        }
                    }
                }
                Button {
                    id: linkTile
                    objectName: "linkConsoleTile"
                    width: Math.min(216, tiles.width)
                    height: Math.min(205, Math.max(128, Math.min(370, tiles.width)*0.55))
                    visible: !Chiaki.settings.hideLinkTile || !home.cards.length
                    Accessible.name: qsTr("Link console")
                    onClicked: root.showRegistDialog("255.255.255.255", true)
                    background: Rectangle {
                        radius: 17; color: linkTile.hovered ? "#284850" : "#1a3440"
                        border.width: linkTile.visualFocus ? 3 : 1
                        border.color: linkTile.visualFocus ? home.focusColor : "#489a92"
                    }
                    contentItem: ColumnLayout {
                        spacing: 12
                        Item { Layout.fillHeight: true }
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 69; implicitHeight: 69; radius: 35
                            color: "#244c50"; border.color: "#458d86"
                            Label { anchors.centerIn: parent; text: "+"; color: home.accent; font.pixelSize: 34; font.weight: Font.Light }
                        }
                        Label { Layout.alignment: Qt.AlignHCenter; text: qsTr("Link Console"); color: home.accent; font.pixelSize: 17 }
                        Item { Layout.fillHeight: true }
                    }
                }
            }
            GameShelf {
                id: shelf
                Layout.fillWidth: true
                Layout.leftMargin: home.inset
                Layout.rightMargin: home.inset
                Layout.topMargin: home.height < 520 ? 24 : 54
                Layout.bottomMargin: 22
                visible: !home.privateView && Chiaki.settings.showGameShelf
                compact: home.width < 600
                games: Chiaki.gameLibrary.games
                loading: Chiaki.gameLibrary.state === PsnGameLibrary.Loading
                readonly property bool signIn: !Chiaki.settings.psnAuthToken || Chiaki.gameLibrary.state === PsnGameLibrary.SignInRequired
                actionText: signIn ? qsTr("Sign in to PSN") : games.length ? qsTr("Refresh games") : qsTr("Load games")
                message: {
                    switch (Chiaki.gameLibrary.state) {
                    case PsnGameLibrary.SignInRequired: return qsTr("Your PSN session has expired")
                    case PsnGameLibrary.Forbidden: return qsTr("PlayStation declined access to your game history")
                    case PsnGameLibrary.RateLimited: return qsTr("PlayStation is limiting requests. Try again later.")
                    case PsnGameLibrary.Unavailable: return qsTr("Game history is unavailable")
                    case PsnGameLibrary.Ready: return games.length ? "" : qsTr("No recently played PS4 or PS5 games")
                    default: return games.length ? "" : signIn ? qsTr("Sign in to see your recent games") : qsTr("Recent games from your PSN account")
                    }
                }
                onRequested: {
                    if (signIn) root.showPSNTokenDialog(false, Chiaki.gameLibrary.state === PsnGameLibrary.SignInRequired)
                    else Chiaki.refreshRecentGames()
                }
            }
        }
    }

    RowLayout {
        id: footer
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.leftMargin: 24; anchors.rightMargin: 24
        height: 54
        Label { text: "chiaki-ng"; color: home.muted; font.pixelSize: 12 }
        Item { Layout.fillWidth: true }
        Label { visible: home.width > 620; text: qsTr("Exit  Esc     Fullscreen  F11     Confirm  Enter     Back  Esc"); color: "#d7deeb"; font.pixelSize: 12 }
    }

    Dialog {
        id: actions
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: parent ? Math.min(550, parent.width - 24) : 500
        modal: true; focus: true
        title: home.activeCard?.name || qsTr("Console")
        standardButtons: Dialog.Close
        readonly property var routes: (root.remoteHome ? home.activeCard?.remote : home.activeCard?.local) || []
        readonly property var route: routes[address.currentIndex] || null
        onOpened: { address.currentIndex = 0; connectButton.forceActiveFocus() }
        onRoutesChanged: if (address) address.currentIndex = 0
        contentItem: ColumnLayout {
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                ConnectionCard { Layout.fillWidth: true; compact: true; text: qsTr("Local Connect"); detail: qsTr("Home network"); selected: !root.remoteHome; onClicked: root.remoteHome = false }
                ConnectionCard { Layout.fillWidth: true; compact: true; text: qsTr("Remote Connect"); detail: qsTr("Internet"); selected: root.remoteHome; onClicked: root.remoteHome = true }
            }
            ComboBox {
                id: address
                Layout.fillWidth: true
                visible: actions.routes.length > 1
                model: actions.routes.map(r => home.routeLabel(r))
                Accessible.name: qsTr("Connection route")
            }
            Label {
                visible: actions.routes.length <= 1
                text: actions.route ? home.routeLabel(actions.route) : root.remoteHome ? qsTr("No remote route is available.") : qsTr("The console is offline or has no saved address.")
                textFormat: Text.PlainText; wrapMode: Text.Wrap; Layout.fillWidth: true
            }
            ComboBox {
                Layout.fillWidth: true
                Accessible.name: qsTr("Session mode")
                model: [qsTr("Video and audio"), qsTr("Video only"), qsTr("Audio only"), qsTr("Gamepad only")]
                currentIndex: Chiaki.settings.audioVideoDisabled
                onActivated: i => Chiaki.settings.audioVideoDisabled = i
            }
            Button {
                id: connectButton
                Layout.fillWidth: true
                text: actions.route ? (!actions.route.registered ? qsTr("Register") : actions.route.state === "standby" ? qsTr("Wake and connect") : qsTr("Connect")) : qsTr("Add address")
                onClicked: {
                    if (actions.route) home.connectRoute(actions.route)
                    else { const mac = home.activeCard?.mac || ""; actions.close(); root.showManualHostDialog(mac) }
                }
            }
            Flow {
                Layout.fillWidth: true
                Button {
                    visible: actions.route && actions.route.registered && !actions.route.duid && Chiaki.settings.showWakeAction
                    text: qsTr("Wake console"); flat: true
                    onClicked: { const i=Routes.indexOfRoute(Chiaki.hosts, actions.route.routeId); if (i >= 0) Chiaki.wakeUpHost(i) }
                }
                Button { visible: actions.route?.registered === true; text: qsTr("PIN"); flat:true; onClicked: {const id=actions.route.routeId; actions.close(); root.showConsolePinDialog(id)} }
                Button {
                    visible: actions.route?.manual === true || (actions.route?.discovered === true && !actions.route.registered)
                    text: actions.route?.manual ? qsTr("Remove address") : qsTr("Hide console"); flat:true
                    onClicked: {
                        const r=actions.route; actions.close()
                        root.showConfirmDialog(text, r.manual ? qsTr("Remove this saved address?") : qsTr("Hide this discovered console?"), () => {
                            const i=Routes.indexOfRoute(Chiaki.hosts, r.routeId)
                            if (i >= 0) { if (r.manual) Chiaki.deleteHost(i); else Chiaki.hideHost(r.mac, r.name) }
                        })
                    }
                }
                Button {
                    visible: root.remoteHome && !actions.routes.length
                    text: Chiaki.settings.psnAuthToken ? qsTr("Refresh PSN") : qsTr("Sign in to PSN"); flat:true
                    onClicked: {actions.close(); if (Chiaki.settings.psnAuthToken) Chiaki.refreshPsnToken(); else root.showPSNTokenDialog(false,false)}
                }
            }
        }
    }
}
