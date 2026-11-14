import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property string alarmStatus: "idle"
    property int remainingSecs: 0
    property int totalSecs: 0
    property string formattedTime: "00:00"

    // Time picker state (target time of day shown on the clock dial)
    property int selHour: 0
    property int selMinute: 0
    property bool editingHours: false
    property string typedBuffer: ""

    // Start the picker at the real current time
    Component.onCompleted: {
        let d = new Date();
        root.selHour = d.getHours();
        root.selMinute = d.getMinutes();
    }

    // ---------------------------------------------------------------------
    // Wallust palette, read from waybar's generated wallust file.
    // Fallback values are only used if the file is missing.
    // ---------------------------------------------------------------------
    readonly property var defaultPalette: ({
        "foreground": "#EFE9EB",
        "background": "#24151A",
        "background-alt": "#24151A",
        "cursor": "#EFE9EB",
        "primary": "#D4658D",
        "secondary": "#D38184",
        "yellow": "#DD88A7",
        "color0": "#2A1C20",
        "color1": "#CE5883",
        "color2": "#813E57",
        "color3": "#D1AE5F",
        "color4": "#C44674",
        "color5": "#C26E70",
        "color6": "#D77D9E",
        "color7": "#EFE9EB",
        "color8": "#744B5A",
        "color9": "#E06C96",
        "color10": "#A14365",
        "color11": "#E2C074",
        "color12": "#D25E88",
        "color13": "#D17B7E",
        "color14": "#DD88A7",
        "color15": "#EFE9EB"
    })
    property var palette: defaultPalette

    function loadPalette(txt) {
        let p = {};
        for (let k in root.defaultPalette)
            p[k] = root.defaultPalette[k];

        let re = /@define-color\s+([A-Za-z0-9_-]+)\s+([^;]+);/g;
        let m;
        while ((m = re.exec(txt)) !== null)
            p[m[1]] = m[2].trim();

        root.palette = p;
    }

    function col(name, fallback) {
        let c = root.palette[name];
        return (c !== undefined && c !== "") ? c : (fallback || "#FFFFFF");
    }

    FileView {
        id: colorFile
        path: Qt.resolvedUrl("/home/fioren/.config/waybar/wallust/colors-waybar.css")
        watchChanges: true
        onLoadedChanged: {
            if (colorFile.loaded)
                root.loadPalette(colorFile.text());
        }
        onFileChanged: colorFile.reload()
    }

    // ---------------------------------------------------------------------
    // Alarm daemon state
    // ---------------------------------------------------------------------
    function runCmd(args) {
        cmdProcess.command = args;
        cmdProcess.running = true;
    }

    function syncState() {
        stateProcess.command = [
            "/home/fioren/.config/hypr/scripts/Alarm.sh",
            "json"
        ];
        stateProcess.running = true;
    }

    Process {
        id: cmdProcess
        running: false
        onExited: root.syncState()
    }

    Process {
        id: stateProcess
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    let obj = JSON.parse(data.trim());
                    root.alarmStatus = obj.status || "idle";
                    root.remainingSecs = obj.remaining || 0;
                    root.totalSecs = obj.total || 0;
                    root.formattedTime = obj.formatted || "00:00";
                } catch (e) {}
            }
        }
    }

    Timer {
        id: syncTimer
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.syncState()
    }

    // ---------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------
    function pad2(n) {
        let v = Math.max(0, Math.floor(n));
        return v < 10 ? "0" + v : String(v);
    }

    function remainMin() {
        return Math.floor(root.remainingSecs / 60);
    }

    function remainSec() {
        return root.remainingSecs % 60;
    }

    // Hours box appears only when more than an hour is left
    readonly property bool showHours: root.alarmStatus === "running" && root.remainingSecs >= 3600

    function remainHours() {
        return Math.floor(root.remainingSecs / 3600);
    }

    // Middle box: total minutes when short, otherwise minutes inside the hour
    function remainMinuteDisplay() {
        return root.showHours
            ? Math.floor((root.remainingSecs % 3600) / 60)
            : root.remainMin();
    }

    // White text on dark colors, black on light ones
    function contrastText(name) {
        let c = root.col(name, "#000000");
        if (c.charAt(0) !== "#" || c.length !== 7)
            return "#FFFFFF";
        let r = parseInt(c.substr(1, 2), 16);
        let g = parseInt(c.substr(3, 2), 16);
        let b = parseInt(c.substr(5, 2), 16);
        let brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
        return brightness > 0.62 ? "#000000" : "#FFFFFF";
    }

    function dispHour() {
        let h = root.selHour % 12;
        return h === 0 ? 12 : h;
    }

    function isPM() {
        return root.selHour >= 12;
    }

    function toggleAmPm() {
        root.selHour = (root.selHour + 12) % 24;
    }

    // Seconds from now until the next occurrence of selHour:selMinute
    function secsUntilTarget() {
        let now = new Date();
        let target = new Date(now.getFullYear(), now.getMonth(), now.getDate(),
                              root.selHour, root.selMinute, 0, 0);
        let diff = Math.floor((target.getTime() - now.getTime()) / 1000);
        if (diff <= 0)
            diff += 86400;
        return diff;
    }

    // 12-hour wall-clock label, e.g. 12:45 AM
    function clockLabel(h, m) {
        let h12 = h % 12;
        if (h12 === 0)
            h12 = 12;
        return root.pad2(h12) + ":" + root.pad2(m) + (h >= 12 ? " PM" : " AM");
    }

    function targetClock() {
        let d = new Date(Date.now() + root.remainingSecs * 1000);
        return root.clockLabel(d.getHours(), d.getMinutes());
    }

    function targetLabel() {
        return root.clockLabel(root.selHour, root.selMinute);
    }

    // Point the picker at (now + secs), used by the quick presets
    function presetTarget(secs) {
        let d = new Date(Date.now() + secs * 1000);
        root.selHour = d.getHours();
        root.selMinute = d.getMinutes();
    }

    // ---------------------------------------------------------------------
    // Direct numeric entry: click a box, then type digits
    // (e.g. box shows 12, type "1" then "0" -> 10)
    // ---------------------------------------------------------------------
    function beginTyping(hours) {
        root.editingHours = hours;
        root.typedBuffer = "";
        typeReset.restart();
    }

    function typeDigit(d) {
        if (root.alarmStatus !== "idle")
            return;

        let value = parseInt(d, 10);

        if (root.editingHours) {
            if (root.typedBuffer === "" && value > 2) {
                root.selHour = value;
                root.typedBuffer = "";
            } else {
                let combined = parseInt(root.typedBuffer + d, 10);
                if (combined <= 23) {
                    root.selHour = combined;
                    root.typedBuffer = root.typedBuffer + d;
                } else {
                    root.selHour = value;
                    root.typedBuffer = d;
                }
            }
        } else {
            if (root.typedBuffer === "" && value > 5) {
                root.selMinute = value;
                root.typedBuffer = "";
            } else {
                let combined = parseInt(root.typedBuffer + d, 10);
                if (combined <= 59) {
                    root.selMinute = combined;
                    root.typedBuffer = root.typedBuffer + d;
                } else {
                    root.selMinute = value;
                    root.typedBuffer = d;
                }
            }
        }
        typeReset.restart();
    }

    Timer {
        id: typeReset
        interval: 1200
        onTriggered: root.typedBuffer = ""
    }

    function dialHoursMode() {
        return root.alarmStatus === "idle" && root.editingHours;
    }

    function dialAngle() {
        if (root.alarmStatus === "running")
            return (root.remainingSecs % 3600) * 0.1;
        if (root.alarmStatus === "ringing")
            return 0;
        if (root.dialHoursMode())
            return (root.selHour % 12) * 30;
        return root.selMinute * 6;
    }

    // ---------------------------------------------------------------------
    // Panel
    // ---------------------------------------------------------------------
    PanelWindow {
        id: win
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:alarm"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
        }
        margins {
            top: 46
        }

        implicitWidth: root.showHours ? 670 : 540
        implicitHeight: 416
        color: "transparent"

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Qt.quit()
            Keys.onPressed: (event) => {
                if (event.text.length === 1 && event.text >= "0" && event.text <= "9") {
                    root.typeDigit(event.text);
                    event.accepted = true;
                }
            }

            Rectangle {
                id: card
                anchors.fill: parent
                radius: 20
                clip: true
                color: root.col("background")
                border.width: 1.2
                border.color: root.alarmStatus === "ringing"
                    ? root.col("color1")
                    : (root.alarmStatus === "running" ? root.col("primary") : root.col("color8"))

                Behavior on color {
                    ColorAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    // -----------------------------------------------------
                    // HEADER
                    // -----------------------------------------------------
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "󰀠"
                            font.pixelSize: 20
                            color: root.alarmStatus === "ringing" ? root.col("color9") : root.col("primary")
                        }

                        Text {
                            text: "Alarm"
                            font.pixelSize: 16
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: root.col("foreground")
                            Layout.fillWidth: true
                        }
                    }

                    // -----------------------------------------------------
                    // BODY: time picker on the left, clock dial on the right
                    // -----------------------------------------------------
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 250
                        spacing: 20

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 0

                            Text {
                                text: root.alarmStatus === "idle"
                                    ? "Set time"
                                    : (root.alarmStatus === "running"
                                        ? "Remaining · rings at " + root.targetClock()
                                        : "Time's up")
                                font.pixelSize: 12
                                font.bold: true
                                color: root.col("color6")
                                Layout.topMargin: 2
                            }

                            Item {
                                Layout.preferredHeight: 6
                            }

                            // Hour / minute boxes
                            RowLayout {
                                spacing: 8

                                Rectangle {
                                    visible: root.alarmStatus === "idle" || root.showHours
                                    Layout.preferredWidth: 100
                                    Layout.preferredHeight: 72
                                    radius: 14
                                    color: root.alarmStatus === "idle" && root.editingHours
                                        ? root.col("color4")
                                        : root.col("color0")
                                    border.width: root.alarmStatus === "idle" && root.editingHours ? 1.4 : 1
                                    border.color: root.alarmStatus === "idle" && root.editingHours
                                        ? root.col("primary")
                                        : root.col("color8")

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 180
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.alarmStatus === "idle"
                                            ? root.pad2(root.dispHour())
                                            : (root.alarmStatus === "running" ? root.pad2(root.remainHours()) : "00")
                                        font.pixelSize: 40
                                        font.bold: true
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: root.alarmStatus === "idle" && root.editingHours
                                            ? root.contrastText("color4")
                                            : root.col("foreground")
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: root.alarmStatus === "idle"
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.beginTyping(true)
                                        onWheel: function(wheel) {
                                            let step = wheel.angleDelta.y > 0 ? 1 : -1;
                                            root.selHour = (root.selHour + step + 24) % 24;
                                        }
                                    }

                                    // AM / PM toggle
                                    Text {
                                        z: 2
                                        visible: root.alarmStatus === "idle"
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.rightMargin: 9
                                        anchors.topMargin: 7
                                        text: root.isPM() ? "PM" : "AM"
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: ampmMouse.containsMouse ? root.col("primary") : root.col("color6")

                                        MouseArea {
                                            id: ampmMouse
                                            anchors.fill: parent
                                            anchors.margins: -5
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.toggleAmPm()
                                        }
                                    }
                                }

                                Text {
                                    visible: root.alarmStatus === "idle" || root.showHours
                                    Layout.preferredWidth: 14
                                    Layout.alignment: Qt.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: ":"
                                    font.pixelSize: 32
                                    font.bold: true
                                    color: root.col("color6")
                                }

                                Rectangle {
                                    Layout.preferredWidth: 100
                                    Layout.preferredHeight: 72
                                    radius: 14
                                    color: root.alarmStatus === "idle" && !root.editingHours
                                        ? root.col("color4")
                                        : root.col("color0")
                                    border.width: root.alarmStatus === "idle" && !root.editingHours ? 1.4 : 1
                                    border.color: root.alarmStatus === "idle" && !root.editingHours
                                        ? root.col("primary")
                                        : root.col("color8")

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 180
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.alarmStatus === "idle"
                                            ? root.pad2(root.selMinute)
                                            : (root.alarmStatus === "running" ? root.pad2(root.remainMinuteDisplay()) : "00")
                                        font.pixelSize: 40
                                        font.bold: true
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: root.alarmStatus === "idle" && !root.editingHours
                                            ? root.contrastText("color4")
                                            : root.col("foreground")
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: root.alarmStatus === "idle"
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.beginTyping(false)
                                        onWheel: function(wheel) {
                                            let step = wheel.angleDelta.y > 0 ? 1 : -1;
                                            root.selMinute = (root.selMinute + step + 60) % 60;
                                        }
                                    }
                                }

                                Text {
                                    visible: root.alarmStatus !== "idle"
                                    Layout.preferredWidth: 14
                                    Layout.alignment: Qt.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: ":"
                                    font.pixelSize: 32
                                    font.bold: true
                                    color: root.col("color6")
                                }

                                Rectangle {
                                    visible: root.alarmStatus !== "idle"
                                    Layout.preferredWidth: 100
                                    Layout.preferredHeight: 72
                                    radius: 14
                                    color: root.col("color0")
                                    border.width: 1
                                    border.color: root.col("color8")

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.alarmStatus === "running" ? root.pad2(root.remainSec()) : "00"
                                        font.pixelSize: 40
                                        font.bold: true
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: root.col("foreground")
                                    }
                                }
                            }

                            // Captions under the boxes
                            RowLayout {
                                spacing: 8

                                Text {
                                    visible: root.alarmStatus === "idle" || root.showHours
                                    Layout.preferredWidth: 100
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "hour"
                                    font.pixelSize: 10
                                    color: root.col("color6")
                                }

                                Item {
                                    visible: root.alarmStatus === "idle" || root.showHours
                                    Layout.preferredWidth: 14
                                }

                                Text {
                                    Layout.preferredWidth: 100
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "min"
                                    font.pixelSize: 10
                                    color: root.col("color6")
                                }

                                Item {
                                    visible: root.alarmStatus !== "idle"
                                    Layout.preferredWidth: 14
                                }

                                Text {
                                    visible: root.alarmStatus !== "idle"
                                    Layout.preferredWidth: 100
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "sec"
                                    font.pixelSize: 10
                                    color: root.col("color6")
                                }
                            }

                            // Progress bar
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 4
                                Layout.topMargin: 8
                                radius: 2
                                color: root.col("color0")

                                Rectangle {
                                    height: parent.height
                                    radius: 2
                                    width: {
                                        if (root.alarmStatus !== "running" || root.totalSecs <= 0)
                                            return 0;
                                        let ratio = (root.totalSecs - root.remainingSecs) / root.totalSecs;
                                        ratio = Math.max(0, Math.min(1, ratio));
                                        return parent.width * ratio;
                                    }
                                    color: root.alarmStatus === "ringing" ? root.col("color1") : root.col("primary")

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 220
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 300
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.preferredHeight: 8
                            }

                            // Unit switch (Hour / Minute)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                radius: 10
                                color: root.col("color0")
                                border.width: 1
                                border.color: root.col("color8")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 3

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 7
                                        color: root.editingHours ? root.col("color4") : root.col("color0")

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 180
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Hour"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.editingHours ? root.contrastText("color4") : root.col("color6")
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: root.alarmStatus === "idle"
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: root.beginTyping(true)
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 7
                                        color: !root.editingHours ? root.col("color4") : root.col("color0")

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 180
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Minute"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: !root.editingHours ? root.contrastText("color4") : root.col("color6")
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: root.alarmStatus === "idle"
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: root.beginTyping(false)
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.preferredHeight: 14
                            }

                            // Presets (chips sit on this shared background)
                            Text {
                                text: "Quick presets"
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 0.4
                                color: root.col("color6")
                            }

                            Item {
                                Layout.preferredHeight: 6
                            }

                            // Presets (chips sit on this shared background)
                            Rectangle {
                                Layout.fillWidth: true
                                radius: 10
                                color: root.col("color0")
                                border.width: 1
                                border.color: root.col("color8")
                                implicitHeight: presetGrid.implicitHeight + 16

                                GridLayout {
                                    id: presetGrid
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    columns: 4
                                    rowSpacing: 6
                                    columnSpacing: 6

                                Repeater {
                                    model: [
                                        {
                                            "label": "5m",
                                            "secs": 300
                                        },
                                        {
                                            "label": "10m",
                                            "secs": 600
                                        },
                                        {
                                            "label": "15m",
                                            "secs": 900
                                        },
                                        {
                                            "label": "25m",
                                            "secs": 1500
                                        },
                                        {
                                            "label": "30m",
                                            "secs": 1800
                                        },
                                        {
                                            "label": "45m",
                                            "secs": 2700
                                        },
                                        {
                                            "label": "1 Hour",
                                            "secs": 3600
                                        },
                                        {
                                            "label": "+5m",
                                            "secs": 300,
                                            "isAdd": true
                                        }
                                    ]

                                    delegate: Rectangle {
                                        property bool isActive: root.alarmStatus === "idle" && !modelData.isAdd
                                            && Math.abs(root.secsUntilTarget() - modelData.secs) < 60

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 28
                                        radius: 8
                                        scale: chipMouse.containsMouse ? 1.04 : 1
                                        color: modelData.isAdd
                                            ? (chipMouse.containsMouse ? root.col("primary") : "transparent")
                                            : (isActive || chipMouse.containsMouse ? root.col("color4") : "transparent")
                                        border.width: modelData.isAdd ? 0 : 1
                                        border.color: modelData.isAdd
                                            ? "transparent"
                                            : (isActive
                                                ? root.col("primary")
                                                : (chipMouse.containsMouse ? root.col("primary") : "transparent"))

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 120
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.pixelSize: 11
                                            font.bold: true
                                            font.family: "JetBrainsMono Nerd Font"
                                            color: modelData.isAdd
                                                ? (chipMouse.containsMouse ? root.contrastText("primary") : root.col("primary"))
                                                : (isActive || chipMouse.containsMouse
                                                    ? root.contrastText("color4")
                                                    : root.col("foreground"))

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 150
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: chipMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.isAdd) {
                                                    root.runCmd(["/home/fioren/.config/hypr/scripts/Alarm.sh", "add", "300"]);
                                                } else {
                                                    root.presetTarget(modelData.secs);
                                                    if (root.alarmStatus === "idle") {
                                                        root.runCmd(["/home/fioren/.config/hypr/scripts/Alarm.sh", "start", String(modelData.secs)]);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                }
                            }
                        }

                        // -------------------------------------------------
                        // CLOCK DIAL
                        // -------------------------------------------------
                        Item {
                            id: dial
                            Layout.preferredWidth: 250
                            Layout.preferredHeight: 250

                            property real faceR: Math.min(width, height) / 2
                            property real numR: faceR - 31
                            property bool isDragging: false
                            property int hoveredIndex: -1

                            Rectangle {
                                anchors.centerIn: parent
                                width: dial.faceR * 2
                                height: dial.faceR * 2
                                radius: width / 2
                                color: root.col("color0")
                                border.width: 1
                                border.color: root.col("color8")

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 220
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            // Numbers around the dial
                            Repeater {
                                model: 12

                                delegate: Item {
                                    width: 34
                                    height: 34
                                    x: dial.width / 2 + Math.sin((index * 30) * Math.PI / 180) * dial.numR - width / 2
                                    y: dial.height / 2 - Math.cos((index * 30) * Math.PI / 180) * dial.numR - height / 2

                                    property bool isSelected: root.alarmStatus === "idle"
                                        && (root.dialHoursMode()
                                            ? (index === (root.selHour % 12))
                                            : (index * 5 === root.selMinute))

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.dialHoursMode()
                                            ? (index === 0 ? "12" : String(index))
                                            : root.pad2(index * 5)
                                        font.pixelSize: 14
                                        font.bold: true
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: (dial.hoveredIndex === index || isSelected) && root.alarmStatus === "idle"
                                            ? root.col("primary")
                                            : root.col("color6")
                                        opacity: isSelected ? 0 : 1

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }
                            }

                            // Hand
                            Rectangle {
                                width: 3
                                height: dial.numR - 16
                                x: dial.width / 2 - width / 2
                                y: dial.height / 2 - height
                                radius: 1.5
                                color: root.alarmStatus === "ringing" ? root.col("color1") : root.col("primary")
                                transformOrigin: Item.Bottom
                                rotation: root.dialAngle()

                                Behavior on rotation {
                                    enabled: !dial.isDragging
                                    NumberAnimation {
                                        duration: 260
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 220
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            // Center dot
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                x: dial.width / 2 - 4
                                y: dial.height / 2 - 4
                                color: root.alarmStatus === "ringing" ? root.col("color1") : root.col("primary")
                            }

                            // Selected value bubble (only visible on 5-minute multiples or hour mode)
                            Rectangle {
                                readonly property bool shouldShow: root.alarmStatus === "idle"
                                    && (root.dialHoursMode() || (root.selMinute % 5 === 0))
                                opacity: shouldShow ? 1 : 0
                                visible: opacity > 0
                                width: 40
                                height: 40
                                radius: 20
                                x: dial.width / 2 + Math.sin(root.dialAngle() * Math.PI / 180) * dial.numR - width / 2
                                y: dial.height / 2 - Math.cos(root.dialAngle() * Math.PI / 180) * dial.numR - height / 2
                                color: root.col("primary")

                                Behavior on x {
                                    enabled: !dial.isDragging
                                    NumberAnimation {
                                        duration: 260
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on y {
                                    enabled: !dial.isDragging
                                    NumberAnimation {
                                        duration: 260
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 220
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.dialHoursMode() ? String(root.dispHour()) : root.pad2(root.selMinute)
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: root.contrastText("primary")
                                }
                            }

                            // Interactive drag & click overlay
                            MouseArea {
                                id: dialMouse
                                anchors.fill: parent
                                enabled: root.alarmStatus === "idle"
                                hoverEnabled: true
                                cursorShape: enabled ? (pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor) : Qt.ArrowCursor

                                function updateFromMouse(mx, my) {
                                    let cx = dial.width / 2;
                                    let cy = dial.height / 2;
                                    let dx = mx - cx;
                                    let dy = my - cy;

                                    let rad = Math.atan2(dx, -dy);
                                    if (rad < 0)
                                        rad += 2 * Math.PI;

                                    let deg = rad * (180 / Math.PI);

                                    if (root.dialHoursMode()) {
                                        let h = Math.round(deg / 30) % 12;
                                        let base = (h === 0 ? 12 : h);
                                        if (root.isPM())
                                            root.selHour = (base === 12 ? 12 : base + 12);
                                        else
                                            root.selHour = (base === 12 ? 0 : base);
                                    } else {
                                        let m = Math.round(deg / 6) % 60;
                                        root.selMinute = m;
                                    }
                                }

                                function updateHover(mx, my) {
                                    let cx = dial.width / 2;
                                    let cy = dial.height / 2;
                                    let dx = mx - cx;
                                    let dy = my - cy;
                                    let dist = Math.sqrt(dx * dx + dy * dy);
                                    if (dist >= dial.numR - 22 && dist <= dial.numR + 22) {
                                        let rad = Math.atan2(dx, -dy);
                                        if (rad < 0)
                                            rad += 2 * Math.PI;
                                        let deg = rad * (180 / Math.PI);
                                        dial.hoveredIndex = Math.round(deg / 30) % 12;
                                    } else {
                                        dial.hoveredIndex = -1;
                                    }
                                }

                                onPressed: function(mouse) {
                                    dial.isDragging = true;
                                    updateFromMouse(mouse.x, mouse.y);
                                }

                                onPositionChanged: function(mouse) {
                                    if (pressed) {
                                        updateFromMouse(mouse.x, mouse.y);
                                    } else {
                                        updateHover(mouse.x, mouse.y);
                                    }
                                }

                                onReleased: function() {
                                    dial.isDragging = false;
                                }

                                onCanceled: function() {
                                    dial.isDragging = false;
                                }

                                onExited: {
                                    dial.hoveredIndex = -1;
                                    if (!pressed)
                                        dial.isDragging = false;
                                }

                                onWheel: function(wheel) {
                                    let step = wheel.angleDelta.y > 0 ? 1 : -1;
                                    if (root.dialHoursMode()) {
                                        root.selHour = (root.selHour + step + 24) % 24;
                                    } else {
                                        root.selMinute = (root.selMinute + step + 60) % 60;
                                    }
                                }
                            }
                        }
                    }

                    // Gap between the dial and the action buttons
                    Item {
                        Layout.preferredHeight: 10
                    }

                    // -----------------------------------------------------
                    // BOTTOM ACTIONS
                    // -----------------------------------------------------
                    Item {
                        id: actions
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42

                        readonly property real gap: 10
                        readonly property real stopTarget: root.alarmStatus === "idle"
                            ? 0
                            : (root.alarmStatus === "ringing" ? width : (width - gap) / 2)

                        // Stop (slides in from the left while running or ringing)
                        Rectangle {
                            id: stopButton
                            x: 0
                            height: 42
                            width: actions.stopTarget
                            radius: 12
                            clip: true
                            opacity: width > 1 ? 1 : 0
                            color: stopMouse.containsMouse ? root.col("color9") : root.col("color1")
                            border.width: 1
                            border.color: root.col("color9")

                            Behavior on width {
                                NumberAnimation {
                                    duration: 280
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 160
                                    easing.type: Easing.OutCubic
                                }
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "󰓛"
                                    font.pixelSize: 14
                                    color: root.contrastText("color1")
                                }

                                Text {
                                    text: "Stop"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.contrastText("color1")
                                }
                            }

                            MouseArea {
                                id: stopMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.runCmd(["/home/fioren/.config/hypr/scripts/Alarm.sh", "stop"]);
                                }
                            }
                        }

                        // Start / +1 min (shrinks as the stop button slides in)
                        Rectangle {
                            id: startButton
                            x: stopButton.width > 0 ? stopButton.width + actions.gap : 0
                            width: Math.max(0, actions.width - stopButton.width - (stopButton.width > 0 ? actions.gap : 0))
                            height: 42
                            radius: 12
                            clip: true
                            opacity: width > 1 ? 1 : 0
                            color: root.alarmStatus === "running"
                                ? (startMouse.containsMouse ? root.col("color10") : root.col("color4"))
                                : (startMouse.containsMouse ? root.col("secondary") : root.col("primary"))
                            border.width: 1
                            border.color: root.alarmStatus === "running" ? root.col("color10") : root.col("primary")

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 160
                                    easing.type: Easing.OutCubic
                                }
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: root.alarmStatus === "running" ? "󰐕" : "󰐊"
                                    font.pixelSize: 14
                                    color: root.alarmStatus === "running" ? root.contrastText("color4") : root.contrastText("primary")
                                }

                                Text {
                                    text: root.alarmStatus === "running"
                                        ? "+1 Min"
                                        : "Start (" + root.targetLabel() + ")"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.alarmStatus === "running" ? root.contrastText("color4") : root.contrastText("primary")
                                }
                            }

                            MouseArea {
                                id: startMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.alarmStatus === "running") {
                                        root.runCmd(["/home/fioren/.config/hypr/scripts/Alarm.sh", "add", "60"]);
                                    } else {
                                        root.runCmd(["/home/fioren/.config/hypr/scripts/Alarm.sh", "start", String(root.secsUntilTarget())]);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
