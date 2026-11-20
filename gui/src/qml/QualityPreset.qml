import QtQuick
import QtQuick.Controls
import "controls" as C

C.ComboBox {
    id: presets
    required property string scope
    required property var config
    Accessible.name: qsTr("Stream quality preset")
    textRole: "label"
    model: [
        { label: qsTr("Custom"), resolution: 0, fps: 0 },
        { label: qsTr("Data saver · 540p / 30 fps"), resolution: 2, fps: 30 },
        { label: qsTr("Balanced · 720p / 60 fps"), resolution: 3, fps: 60 },
        { label: qsTr("High quality · 1080p / 60 fps"), resolution: 4, fps: 60 }
    ]
    currentIndex: {
        const resolution = config["resolution" + scope]
        const fps = config["fps" + scope]
        const bitrate = config["bitrate" + scope]
        for (let i = 1; i < model.length; ++i) {
            if (!bitrate && model[i].resolution === resolution && model[i].fps === fps)
                return i
        }
        return 0
    }
    onActivated: (index) => {
        if (index === 0)
            return
        const profile = model[index]
        config["resolution" + scope] = profile.resolution
        config["fps" + scope] = profile.fps
        config["bitrate" + scope] = 0
    }
    delegate: ItemDelegate {
        required property int index
        required property var modelData
        width: presets.width
        text: modelData.label
        enabled: index > 0
        highlighted: presets.highlightedIndex === index
    }
}
