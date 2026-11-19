import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

Window {
    id: editor
    required property var session
    required property var streamWindow
    transientParent: streamWindow
    modality: Qt.WindowModal
    flags: Qt.Dialog | Qt.WindowTitleHint | Qt.WindowCloseButtonHint
    title: qsTr("PlayStation text entry")
    width: 460
    height: 176
    minimumWidth: 330
    minimumHeight: 176
    color: "#121a25"
    Material.theme: Material.Dark
    visible: !!session && session.consoleKeyboardOpen
    property bool inputGrabbed: false

    function releaseGrab() {
        if (inputGrabbed) {
            streamWindow.releaseInput()
            inputGrabbed = false
        }
    }
    function finish(accept) {
        if (session && session.consoleKeyboardOpen && !session.finishConsoleKeyboard(field.text, accept))
            failure.visible = true
    }
    onClosing: (event) => {
        event.accepted = false
        finish(false)
    }
    onVisibleChanged: {
        if (visible) {
            inputGrabbed = true
            streamWindow.grabInput()
            field.edited = false
            field.text = session.consoleKeyboardText
            field.selectAll()
            failure.visible = false
            requestActivate()
            field.forceActiveFocus()
        } else {
            field.clear()
            releaseGrab()
        }
    }
    Component.onDestruction: releaseGrab()
    Connections {
        target: editor.session
        function onConsoleKeyboardChanged() {
            if (editor.visible && editor.session.consoleKeyboardOpen && !field.edited)
                field.text = editor.session.consoleKeyboardText
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        TextField {
            id: field
            property bool edited: false
            onTextEdited: edited = true
            Layout.fillWidth: true
            Accessible.name: editor.title
            onAccepted: editor.finish(true)
            Keys.onEscapePressed: editor.finish(false)
        }
        Label {
            id: failure
            visible: false
            text: qsTr("The console could not receive the text. Try again.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Item { Layout.fillHeight: true }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            Button { text: qsTr("Cancel"); onClicked: editor.finish(false) }
            Button { text: qsTr("Send"); highlighted: true; onClicked: editor.finish(true) }
        }
    }
}
