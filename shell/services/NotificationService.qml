pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

// Wraps NotificationServer the same way AudioService/WindowService wrap
// their own system state: UI never touches Quickshell.Services.Notifications
// directly, only this singleton.
//
// Two lists are kept deliberately separate:
//  - activeToasts: live popups currently on screen. Each entry keeps a
//    reference to the real Notification object so its actions (and
//    dismiss()) still work while it's showing.
//  - history: what Notification Center shows. Plain JS snapshots, not
//    Notification objects, because those get destroyed once closed and
//    Notification Center still needs to display them after that happens.
QtObject {
    id: root

    property bool dndEnabled: false
    property var activeToasts: []
    property var history: []

    // Freedesktop expireTimeout: -1 (or unset) means "server default",
    // 0 means "never expire until dismissed", >0 is an explicit seconds
    // value. We supply the default ourselves per urgency.
    readonly property int defaultTimeoutMs: 5000
    readonly property int criticalTimeoutMs: 10000

    function clearHistory() {
        root.history = []
    }

    function dismissToast(toastId) {
        const toast = root.activeToasts.find(t => t.toastId === toastId)
        if (toast && toast.notification) {
            try {
                toast.notification.dismiss()
            } catch (e) {
                // Already destroyed server-side; nothing left to do.
            }
        }
        root.activeToasts = root.activeToasts.filter(t => t.toastId !== toastId)
    }

    property NotificationServer server: NotificationServer {
        actionsSupported: true
        actionIconsSupported: false
        bodySupported: true
        bodyImagesSupported: true
        imageSupported: true
        // We snapshot everything we need into `history` ourselves, so
        // carrying raw server objects across a shell reload adds nothing.
        keepOnReload: false

        onNotification: (notification) => {
            // Must be set or the server discards the notification
            // immediately after this handler returns.
            notification.tracked = true

            let timeoutMs = root.defaultTimeoutMs
            if (notification.urgency === NotificationUrgency.Critical) {
                timeoutMs = root.criticalTimeoutMs
            }
            if (notification.expireTimeout === 0) {
                timeoutMs = 0 // explicit "never auto-expire"
            } else if (notification.expireTimeout > 0) {
                timeoutMs = notification.expireTimeout * 1000
            }

            const toastId = notification.id + "-" + Date.now()

            const entry = {
                toastId: toastId,
                id: notification.id,
                appName: notification.appName || "Notification",
                icon: notification.image || notification.appIcon,
                summary: notification.summary,
                body: notification.body,
                time: new Date(),
                timeoutMs: timeoutMs,
                notification: notification
            }

            root.history = [entry].concat(root.history)

            if (!root.dndEnabled) {
                root.activeToasts = [entry].concat(root.activeToasts)
            } else {
                // DND: log it, never surface a toast for it.
                notification.tracked = false
            }

            // Covers the app cancelling its own notification, or the
            // user dismissing it some other way, before our timer fires.
            notification.closed.connect(function () {
                root.activeToasts = root.activeToasts.filter(t => t.toastId !== toastId)
            })
        }
    }
}
