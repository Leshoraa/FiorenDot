pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 * Optimized to prevent background process spamming and only update when overview is active.
 */
Singleton {
    id: root
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var layers: ({})

    function updateWindowList() {
        if (!getClients.running)
            getClients.running = true;
    }

    function updateMonitors() {
        if (!getMonitors.running)
            getMonitors.running = true;
    }

    function updateAll() {
        updateWindowList();
        updateMonitors();
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = root.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    Component.onCompleted: {
        updateAll();
    }

    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen) {
                updateAll();
            }
        }
    }

    Timer {
        id: eventDebounceTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (GlobalStates.overviewOpen) {
                updateAll();
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            // Do not run any sub-process if overview is closed!
            if (!GlobalStates.overviewOpen)
                return;

            const ev = event.name;
            if (ev === "openwindow" || ev === "closewindow" || ev === "movewindow" ||
                ev === "movewindowv2" || ev === "focusedmon" || ev === "monitoradded" ||
                ev === "monitorremoved" || ev === "windowtitle" || ev === "activewindow" ||
                ev === "activewindowv2" || ev === "changefloatingmode") {
                eventDebounceTimer.restart();
            }
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                if (!clientsCollector.text) return;
                try {
                    root.windowList = JSON.parse(clientsCollector.text);
                    let tempWinByAddress = {};
                    for (var i = 0; i < root.windowList.length; ++i) {
                        var win = root.windowList[i];
                        tempWinByAddress[win.address] = win;
                    }
                    root.windowByAddress = tempWinByAddress;
                    root.addresses = root.windowList.map(win => win.address);
                } catch (e) {
                    console.error("HyprlandData clients parse error:", e);
                }
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                if (!monitorsCollector.text) return;
                try {
                    root.monitors = JSON.parse(monitorsCollector.text);
                } catch (e) {
                    console.error("HyprlandData monitors parse error:", e);
                }
            }
        }
    }
}
