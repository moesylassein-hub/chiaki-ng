import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: shelf
    required property var games
    required property string message
    required property string actionText
    property bool loading: false
    property bool compact: false
    property var selectedGame: null
    signal requested()
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        Label {
            Layout.fillWidth: true
            text: qsTr("Recently played on PlayStation")
            font.pixelSize: shelf.compact ? 15 : 18
            font.weight: Font.DemiBold
            color: "#eef4ff"
            elide: Text.ElideRight
        }
        BusyIndicator {
            Layout.preferredHeight: 20
            Layout.preferredWidth: 20
            running: shelf.loading
            visible: running
        }
        Button {
            text: shelf.actionText
            flat: true
            visible: shelf.games.length > 0
            enabled: !shelf.loading
            onClicked: shelf.requested()
        }
    }
    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Math.min(440, shelf.width)
        implicitHeight: shelf.compact ? 125 : 155
        visible: !shelf.games.length
        radius: 21
        color: "#64323c4b"
        border.color: "#424e6073"
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 3
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: shelf.compact ? 34 : 45
                implicitHeight: implicitWidth
                radius: width/2; color: "#334254"
                Label { anchors.centerIn: parent; text: "●"; color: "#ffbf26"; font.pixelSize: 24 }
            }
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: shelf.message
                wrapMode: Text.Wrap
                color: "#f2f5fa"
                font.weight: Font.DemiBold
            }
            Button {
                Layout.alignment: Qt.AlignHCenter
                enabled: !shelf.loading
                text: shelf.actionText
                flat: true
                onClicked: shelf.requested()
            }
        }
    }
    Label {
        Layout.fillWidth: true
        visible: !!shelf.games.length && !!shelf.message
        text: shelf.message
        wrapMode: Text.Wrap
    }
    ListView {
        id: covers
        objectName: "gameCards"
        Layout.fillWidth: true
        Layout.preferredHeight: shelf.compact ? 52 : 88
        visible: count > 0
        orientation: ListView.Horizontal
        spacing: 8
        clip: true
        model: shelf.games
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.horizontal: ScrollBar { }
        delegate: ItemDelegate {
            id: tile
            required property var modelData
            required property int index
            width: shelf.compact ? 162 : 216
            height: covers.height - 6
            highlighted: activeFocus
            Accessible.name: modelData.title + ", " + modelData.platform
            onActiveFocusChanged: if (activeFocus) covers.positionViewAtIndex(index, ListView.Contain)
            onClicked: { shelf.selectedGame = modelData; details.open() }
            background: Rectangle {
                radius: 10
                color: tile.hovered || tile.visualFocus ? "#263e56" : "#182739"
                border.color: tile.visualFocus ? "#87d7ff" : "#2c4056"
            }
            contentItem: RowLayout {
                spacing: 10
                Rectangle {
                    Layout.preferredWidth: 54
                    Layout.preferredHeight: 54
                    visible: !shelf.compact
                    color: "#253b52"
                    radius: 4
                    Label {
                        anchors.centerIn: parent
                        text: tile.modelData.platform
                        color: "#a8c9e8"
                    }
                    Image {
                        anchors.fill: parent
                        source: tile.modelData.image || ""
                        sourceSize: Qt.size(120, 120)
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        Layout.fillWidth: true
                        text: tile.modelData.title
                        textFormat: Text.PlainText
                        maximumLineCount: shelf.compact ? 1 : 2
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        color: "white"
                    }
                    Label { text: tile.modelData.platform; color: "#92acc7"; font.pixelSize: 11 }
                }
            }
        }
    }
    onGamesChanged: {
        if (details && details.visible) details.close()
        selectedGame = null
    }
    Dialog {
        id: details
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: parent ? Math.min(420, parent.width - 24) : 320
        modal: true
        focus: true
        title: qsTr("Game details")
        standardButtons: Dialog.Close
        contentItem: ColumnLayout {
            Label {
                Layout.fillWidth: true
                text: shelf.selectedGame?.title || ""
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                font.pixelSize: 20
            }
            Label { text: shelf.selectedGame?.platform || "" }
            Label {
                readonly property string played: shelf.selectedGame?.lastPlayed ? Qt.formatDateTime(shelf.selectedGame.lastPlayed, Qt.locale().dateTimeFormat(Locale.ShortFormat)) : ""
                visible: !!played
                text: qsTr("Last played %1").arg(played)
            }
        }
    }
}
