import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: card
    required property bool selected
    required property string detail
    property bool compact: false
    Accessible.role: Accessible.RadioButton
    Accessible.checked: selected
    Accessible.description: detail
    hoverEnabled: true
    implicitHeight: compact ? 46 : 66
    leftPadding: compact ? 10 : 16
    rightPadding: leftPadding

    background: Rectangle {
        radius: 12
        color: card.selected ? "#153754" : card.hovered ? "#1a2b3e" : "#131e2b"
        border.color: card.visualFocus ? "#ffffff" : card.selected ? "#56bfff" : "#324255"
        border.width: card.visualFocus || card.selected ? 2 : 1
    }
    contentItem: ColumnLayout {
        spacing: 1
        Label {
            Layout.fillWidth: true
            text: card.text
            textFormat: Text.PlainText
            color: card.selected ? "#a9dfff" : "#eef5ff"
            font.pixelSize: card.compact ? 14 : 17
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Label {
            Layout.fillWidth: true
            visible: !card.compact
            text: card.detail
            color: "#acbed1"
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }
}
