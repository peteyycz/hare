import QtQuick
import QtQuick.Layouts
import "../Theme"

// A labelled slider tile — the design's `.cc-row`: a fill tile holding a small
// uppercase-ish heading above a Slider. Forwards the slider's value/glyph/moved.
Rectangle {
    id: root

    property string heading: ""
    property alias glyph: slider.glyph
    property alias value: slider.value
    signal moved(real v)

    Layout.fillWidth: true
    implicitHeight: inner.implicitHeight + 26 // 13px top + bottom padding
    radius: Theme.rMd
    color: Theme.fill
    border.width: 1
    border.color: Theme.hairline

    ColumnLayout {
        id: inner
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        anchors.topMargin: 13
        anchors.bottomMargin: 13
        spacing: 9

        Text {
            Layout.fillWidth: true
            text: root.heading
            font.family: Theme.fonts.sans
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Theme.textDim
            elide: Text.ElideRight
        }

        Slider {
            id: slider
            Layout.fillWidth: true
            onMoved: v => root.moved(v)
        }
    }
}
