import QtQuick
import "../Theme"

// A Nerd Font glyph. `code` is a Unicode codepoint (e.g. 0xf028).
Text {
    property int code: 0
    property int size: 16
    text: String.fromCharCode(code)
    font.family: "Symbols Nerd Font"
    font.pixelSize: size
    color: Theme.text
    verticalAlignment: Text.AlignVCenter
}
