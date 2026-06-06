import QtQuick
import Quickshell

// ─── OSD overlay ─────────────────────────────────────────────────────────────
// Non-interactive pill at the bottom-center of each screen; shown briefly
// after a volume or brightness change, then auto-dismissed by shell.qml.
PanelWindow {
    id: osd

    required property var shell

    anchors.bottom: true
    margins {
        bottom: 60
    }
    exclusionMode: ExclusionMode.Ignore

    implicitWidth: 215
    implicitHeight: 40
    color: "transparent"

    visible: shell.osdVisible

    readonly property bool isVolumeOsd: shell.osdIcon === "󰕾" || shell.osdIcon === "󰖁" || shell.osdIcon === "󰍬" || shell.osdIcon === "󰍭"
    readonly property int maxValue: isVolumeOsd ? 150 : 100

    Rectangle {
        anchors.fill: parent
        color: osd.shell.bg
        border.color: osd.shell.bgLight
        border.width: 1
        radius: 6

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: parent.right
            spacing: 12

            // ─── Icon ───────────────────────────────────────────────────────────
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: osd.shell.osdIcon
                color: osd.shell.primary
                font.family: osd.shell.monoFont
                font.pixelSize: 16
                width: 16
            }

            // ─── Progress bar ───────────────────────────────────────────────────
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 162
                height: 4
                radius: 2
                color: osd.shell.bgLight

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, osd.shell.osdValue / osd.maxValue))
                    height: parent.height
                    radius: parent.radius
                    color: osd.shell.primary

                    Behavior on width {
                        NumberAnimation {
                            duration: 80
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }
    }
}
