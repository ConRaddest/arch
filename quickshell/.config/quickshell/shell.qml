//@ pragma ShellId shell

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "components"

ShellRoot {
    id: root

    Theme { id: theme }

    readonly property string bg: theme.bg
    readonly property string bgDark: theme.bgDark
    readonly property string bgLight: theme.bgLight

    readonly property string fg: theme.fg
    readonly property string fgDark: theme.fgDark
    readonly property string fgLight: theme.fgLight

    readonly property string primary: theme.primary
    readonly property string secondary: theme.secondary
    readonly property string tertiary: theme.tertiary
    readonly property string quaternary: theme.quaternary

    readonly property string black: theme.black
    readonly property string red: theme.red
    readonly property string orange: theme.orange
    readonly property string yellow: theme.yellow
    readonly property string green: theme.green
    readonly property string teal: theme.teal
    readonly property string blue: theme.blue
    readonly property string purple: theme.purple

    readonly property string monoFont: theme.monoFont
    readonly property string homeDir: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    readonly property string configDir: "/home/cdt/.config/quickshell"

    // Bar state
    property string cpuText: "--"
    property string ramText: "--"
    property string wifiText: "󰖪"
    property string bluetoothText: "󰂲"
    property string batteryText: "󰚥 AC"
    property string volumeText: "󰕾"
    property string timeText: Qt.formatDateTime(new Date(), "ddd dd MMM HH:mm:ss")

    // OSD state
    property bool osdVisible: false
    property string osdIcon: ""
    property int osdValue: 0

    // Kept so Bar.qml can assign it when the launcher button is clicked.
    property bool menuOpen: false

    readonly property string terminal: "kitty"

    function launchDesktop(id) {
        const entry = DesktopEntries.byId(id) || (!String(id).endsWith(".desktop") ? DesktopEntries.byId(id + ".desktop") : null);
        if (entry)
            entry.execute();
    }

    function launchTerminal(klass, title, cmd, pause) {
        const shellCmd = pause ? cmd + "; echo; read -rp 'Press Enter to close...'" : cmd;
        launchProcess.running = false;
        launchProcess.command = ["uwsm", "app", "--", terminal, "--class", klass, "--title", title, "-e", "bash", "-lic", shellCmd];
        launchProcess.running = true;
    }

    function runDetached(command) {
        launchProcess.running = false;
        launchProcess.command = ["uwsm", "app", "--", "bash", "-lc", command];
        launchProcess.running = true;
    }

    Process { id: launchProcess }

    Process {
        id: statusProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split("|");
                if (parts.length >= 5) {
                    root.cpuText = parts[0];
                    root.ramText = parts[1];
                    root.wifiText = parts[2];
                    root.bluetoothText = parts[3];
                    root.batteryText = parts[4];
                    if (parts.length >= 6)
                        root.volumeText = parts[5];
                }
            }
        }
    }

    Timer {
        id: osdTimer
        interval: 2000
        onTriggered: root.osdVisible = false
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.timeText = Qt.formatDateTime(new Date(), "ddd dd MMM HH:mm:ss");
            statusProcess.running = false;
            statusProcess.command = [root.configDir + "/scripts/shell/bar.sh"];
            statusProcess.running = true;
        }
    }

    IpcHandler {
        target: "osd"
        function trigger(data: string): void {
            const sep = data.lastIndexOf(":");
            root.osdIcon = data.slice(0, sep);
            root.osdValue = parseInt(data.slice(sep + 1)) || 0;
            root.osdVisible = true;
            osdTimer.restart();
        }
    }

    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
            shell: root
        }
    }

    Variants {
        model: Quickshell.screens
        Osd {
            required property var modelData
            screen: modelData
            shell: root
        }
    }
}
