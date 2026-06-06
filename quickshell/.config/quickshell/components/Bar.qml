import QtQuick
import Quickshell
import Quickshell.Hyprland

// ─── Bar window ──────────────────────────────────────────────────────────────
// Anchored full-width panel at the top of each monitor.
PanelWindow {
    id: bar

    required property var shell

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 30
    color: "transparent"

    // ─── Inline component: StatusPill ────────────────────────────────────────
    // Small clickable status indicator used in the right section of the bar.
    component StatusPill: Rectangle {
        id: pill

        required property var shell
        property string text: ""
        property bool clickable: false
        signal clicked

        width: label.implicitWidth + 14
        height: 24
        radius: 6
        color: pill.clickable && mouse.containsMouse ? pill.shell.bgLight : "transparent"

        Text {
            id: label
            anchors.centerIn: parent
            text: pill.text
            color: pill.shell.fg
            font.family: pill.shell.monoFont
            font.pixelSize: 13
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            enabled: pill.clickable
            hoverEnabled: pill.clickable
            cursorShape: pill.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: pill.clicked()
        }
    }

    // ─── Monitor binding ─────────────────────────────────────────────────────
    // Find the Hyprland monitor whose name matches this bar's screen.
    readonly property HyprlandMonitor hyprMonitor: {
        for (const m of Hyprland.monitors.values) {
            if (m.name === bar.screen.name)
                return m;
        }
        return null;
    }

    // Collect normal workspace IDs visible on this monitor (occupied + active).
    // Hyprland exposes special/scratchpad workspaces as negative IDs; hide those
    // from the bar instead of rendering values like -98.
    readonly property var monitorWorkspaceIds: {
        const ids = [];
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 0 && ws.monitor?.name === bar.screen.name && !ids.includes(ws.id))
                ids.push(ws.id);
        }
        const active = bar.hyprMonitor?.activeWorkspace?.id;
        if (active > 0 && !ids.includes(active))
            ids.push(active);
        return ids.sort((a, b) => a - b);
    }

    readonly property int monitorActiveWorkspace: {
        const active = bar.hyprMonitor?.activeWorkspace?.id || 0;
        return active > 0 ? active : 0;
    }

    // ─── Background ──────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: bar.shell.bg
        opacity: 0.90

        // ─── Left: launcher icon + workspace indicators ───────────────────────
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Rectangle {
                width: 22
                height: 22
                radius: 6
                color: launcherMouse.containsMouse ? bar.shell.bgLight : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰍜"
                    color: bar.shell.fgDark
                    font.family: bar.shell.monoFont
                    font.pixelSize: 13
                }

                MouseArea {
                    id: launcherMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.shell.menuOpen = true
                }
            }

            Repeater {
                model: bar.monitorWorkspaceIds

                Rectangle {
                    required property int modelData

                    readonly property bool active: (Hyprland.focusedWorkspace?.id || 0) === modelData
                    readonly property bool monitorActive: !active && bar.monitorActiveWorkspace === modelData

                    width: 22
                    height: 22
                    radius: 6
                    color: active ? bar.shell.bgLight : "transparent"
                    border.color: active ? bar.shell.fg : (monitorActive ? bar.shell.fgDark : "transparent")
                    border.width: (active || monitorActive) ? 1 : 0

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData
                        color: parent.active ? bar.shell.fg : bar.shell.fgDark
                        font.family: bar.shell.monoFont
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("hl.dsp.focus({workspace=\"" + parent.modelData + "\"})")
                    }
                }
            }
        }

        // ─── Center: clock ────────────────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width: clockText.implicitWidth + 14
            height: 24
            radius: 6
            color: clockMouse.containsMouse ? bar.shell.bgLight : "transparent"

            Text {
                id: clockText
                anchors.centerIn: parent
                text: bar.shell.timeText
                color: bar.shell.fg
                font.family: bar.shell.monoFont
                font.pixelSize: 13
            }

            MouseArea {
                id: clockMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.shell.launchDesktop("calendar-pwa")
            }
        }

        // ─── Right: system status pills ───────────────────────────────────────
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            StatusPill {
                shell: bar.shell
                text: bar.shell.wifiText
                clickable: true
                onClicked: bar.shell.launchTerminal("wifi-manager", "wifi-manager", "impala")
            }
            StatusPill {
                shell: bar.shell
                text: bar.shell.bluetoothText
                clickable: true
                onClicked: bar.shell.launchTerminal("bluetooth-manager", "bluetooth-manager", "bluetui")
            }
            StatusPill {
                shell: bar.shell
                text: bar.shell.volumeText
                clickable: true
                onClicked: bar.shell.launchTerminal("audio-manager", "audio-manager", "wiremix")
            }
            StatusPill {
                shell: bar.shell
                text: bar.shell.batteryText
                clickable: true
                onClicked: bar.shell.launchTerminal("power-profile-menu", "power-profile-menu", "~/.config/quickshell/scripts/shell/power-profile.sh", false)
            }
            StatusPill {
                shell: bar.shell
                text: "  " + bar.shell.cpuText + "    " + bar.shell.ramText
                clickable: true
                onClicked: bar.shell.launchTerminal("performance-monitor", "performance-monitor", "btop")
            }
        }
    }
}
