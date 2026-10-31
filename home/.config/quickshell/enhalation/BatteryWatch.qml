import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Low-battery warnings. There is no bar, so nothing else on the desktop shows the charge.
// 15 %: a notification that stays until dismissed. 5 %: critical, which swaync's critical-alert
// script also sounds. The second replaces the first (notify-send -r), and plugging in closes it.
// Each level fires once per discharge: jitter around a threshold must not re-notify, so `warned`
// resets only on AC.
Scope {
    id: root
    readonly property var dev: UPower.displayDevice
    readonly property bool draining: UPower.onBattery && dev.ready && dev.isLaptopBattery
    readonly property int level: !draining ? 0 : dev.percentage <= 0.05 ? 2 : dev.percentage <= 0.15 ? 1 : 0
    property int warned: 0                             // the highest level notified this discharge
    property string notifId: ""                        // what -r replaces and CloseNotification closes

    onLevelChanged: update()
    onDrainingChanged: update()

    function update() {
        if (!UPower.onBattery) { warned = 0; dismiss(); return; }
        if (level > warned) { warned = level; notify(level, dev.percentage, dev.timeToEmpty); }
    }

    function notify(lvl, fraction, secondsLeft) {
        const pct = Math.round(fraction * 100);
        const mins = Math.round(secondsLeft / 60);
        const left = mins > 0 ? " About " + mins + " min left." : "";
        const argv = ["notify-send", "-p", "-a", "swaync", "-t", "0",
                      "-u", lvl === 2 ? "critical" : "normal",
                      "-i", dev.iconName || "battery-caution-symbolic"];
        if (notifId) argv.push("-r", notifId);
        argv.push(lvl === 2 ? "Battery critical: " + pct + "%" : "Battery low: " + pct + "%",
                  (lvl === 2 ? "Plug in now." : "Plug in soon.") + left);
        send.command = argv;
        send.running = true;
    }

    function dismiss() {
        if (!notifId) return;
        Quickshell.execDetached(["gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications",
                                 "--object-path", "/org/freedesktop/Notifications",
                                 "--method", "org.freedesktop.Notifications.CloseNotification", notifId]);
        notifId = "";
    }

    Process {
        id: send
        stdout: StdioCollector {
            onStreamFinished: { const id = text.trim(); if (id) root.notifId = id; }
        }
    }

    IpcHandler {
        target: "battery"
        function state(): string {
            return JSON.stringify({ ready: root.dev.ready, onBattery: UPower.onBattery,
                                    percentage: root.dev.percentage, level: root.level,
                                    warned: root.warned, notifId: root.notifId });
        }
        // Test hook: shows what level 1 or 2 looks like with made-up numbers, 0 closes it.
        // It shares notifId with the real warnings but leaves `warned` alone.
        function preview(lvl: int): void {
            if (lvl === 1 || lvl === 2) root.notify(lvl, lvl === 2 ? 0.04 : 0.14, lvl === 2 ? 600 : 2400);
            else root.dismiss();
        }
    }
}
