import QtQuick
import QtQuick.Window
import QtTest
import "../../gui/src/qml" as Desktop
import "../../gui/src/qml/ConnectionRoutes.js" as Routes

TestCase {
    id: tests
    name: "DesktopPlay"
    when: windowShown

    Component {
        id: presetComponent
        Desktop.QualityPreset {}
    }
    Component {
        id: editorComponent
        Desktop.ConsoleKeyboardWindow {}
    }
    Window {
        id: streamWindow
        visible: true
        width: 480
        height: 240
        property int grabs: 0
        function grabInput() { ++grabs }
        function releaseInput() { --grabs }
    }
    QtObject {
        id: settings
        property int resolutionLocalPS5: 3
        property int fpsLocalPS5: 60
        property int bitrateLocalPS5: 23500
        property int resolutionRemotePS5: 2
        property int fpsRemotePS5: 30
        property int bitrateRemotePS5: 0
    }
    QtObject {
        id: session
        property bool consoleKeyboardOpen: false
        property string consoleKeyboardText: ""
        property string sent: ""
        property bool accepted: false
        signal consoleKeyboardChanged()
        function finishConsoleKeyboard(value, accept) {
            sent = value
            accepted = accept
            consoleKeyboardOpen = false
            return true
        }
    }

    Component {
        id: connectionCard
        Desktop.ConnectionCard { text: "Remote Connect"; detail: "Over the internet"; selected: false }
    }

    function test_connectionCard() {
        const card = createTemporaryObject(connectionCard, tests)
        verify(card !== null)
        compare(card.Accessible.checked, false)
        card.selected = true
        compare(card.Accessible.checked, true)
        const fullHeight = card.implicitHeight
        card.compact = true
        verify(card.implicitHeight < fullHeight)
        compare(card.Accessible.description, "Over the internet")
    }

    Component {
        id: shelfComponent
        Desktop.GameShelf { games: []; actionText: "Load games"; message: "" }
    }
    function test_shelfWithAndWithoutHistory() {
        const shelf = createTemporaryObject(shelfComponent, tests, {width: 600})
        verify(shelf !== null)
        const cards = findChild(shelf, "gameCards")
        compare(cards.count, 0)
        shelf.games = [{title: "A & B", platform: "PS5", image: "", lastPlayed: null}]
        tryCompare(cards, "count", 1)
        shelf.compact = true
        shelf.games = []
        tryCompare(cards, "count", 0)
    }

    function test_connectionRoutes() {
        const hosts = [
            {routeId: "lan", display: true, discovered: true, duid: "registration"},
            {routeId: "duplicate", display: false, manual: true},
            {routeId: "address", display: true, manual: true},
            {routeId: "psn", display: true, duid: "remote"}
        ]
        compare(Routes.visibleHosts(hosts, false).map(h => h.routeId), ["lan", "address"])
        compare(Routes.visibleHosts(hosts, true).map(h => h.routeId), ["address", "psn"])
        compare(Routes.indexOfRoute(hosts, "psn"), 3)
        compare(Routes.indexOfRoute(hosts.slice(1), "psn"), 2)
        compare(Routes.indexOfRoute(hosts, "duplicate"), -1)
        compare(Routes.indexOfRoute([], "psn"), -1)
    }

    function test_savedConsolesStayVisibleOffline() {
        const saved = [{name:"One", mac:"aa", ps5:true}, {name:"Two", mac:"bb", ps5:false}]
        const routes = [{routeId:"address/1", registered:true, display:true, manual:true, mac:"aa"}]
        const local = Routes.dashboardHosts(routes, saved, false)
        compare(local.map(h => h.routeId), ["address/1", "registered/bb"])
        verify(local[1].offline)
        compare(Routes.dashboardHosts(routes, saved, true).length, 1)
    }

    function test_cardsGroupRoutesAndKeepUnmatchedAccountsSeparate() {
        const saved = [{name:"One", mac:"aa", ps5:true}, {name:"Two", mac:"bb", ps5:false}]
        const routes = [
            {name:"One", mac:"aa", display:true, registered:true, discovered:true, routeId:"lan/aa", state:"ready", app:"Demo"},
            {name:"One", display:true, registered:true, duid:"remote", routeId:"psn/1"},
            {name:"Other", display:true, registered:true, duid:"separate", routeId:"psn/2"}
        ]
        const grouped = Routes.consoleCards(routes, saved)
        compare(grouped.map(c => c.id), ["registered/aa", "registered/bb", "psn/2"])
        compare(grouped[0].local.length, 1)
        compare(grouped[0].remote.length, 1)
        compare(grouped[0].app, "Demo")
        compare(grouped[1].state, "offline")
    }

    function test_presetsAreScoped() {
        const picker = createTemporaryObject(presetComponent, tests, {config: settings, scope: "RemotePS5"})
        verify(picker !== null)
        compare(picker.currentIndex, 1)
        picker.activated(3)
        compare(settings.resolutionRemotePS5, 4)
        compare(settings.fpsRemotePS5, 60)
        compare(settings.bitrateRemotePS5, 0)
        compare(settings.bitrateLocalPS5, 23500)
        picker.scope = "LocalPS5"
        compare(picker.currentIndex, 0)
        picker.activated(2)
        compare(settings.bitrateLocalPS5, 0)
        compare(picker.currentIndex, 2)
        settings.bitrateLocalPS5 = 12000
        compare(picker.currentIndex, 0)
    }

    function test_consoleTextLifecycle() {
        const editor = createTemporaryObject(editorComponent, null, {session: session, streamWindow: streamWindow})
        verify(editor !== null)
        const field = findChild(editor, "consoleTextField")
        verify(field !== null)
        session.consoleKeyboardText = "Console"
        session.consoleKeyboardOpen = true
        tryCompare(editor, "visible", true)
        compare(field.text, "Console")
        compare(streamWindow.grabs, 1)
        field.text = "مرحبا"
        field.textEdited()
        session.consoleKeyboardChanged()
        compare(field.text, "مرحبا")
        editor.finish(true)
        compare(session.sent, "مرحبا")
        verify(session.accepted)
        tryCompare(editor, "visible", false)
        compare(streamWindow.grabs, 0)

        session.consoleKeyboardOpen = true
        editor.finish(false)
        verify(!session.accepted)
        compare(streamWindow.grabs, 0)

        session.consoleKeyboardOpen = true
        session.consoleKeyboardOpen = false
        tryCompare(editor, "visible", false)
        compare(field.text, "")
        compare(streamWindow.grabs, 0)
    }
}
