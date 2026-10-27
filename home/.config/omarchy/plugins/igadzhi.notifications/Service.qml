import QtQuick
import "file:///usr/share/omarchy/shell/plugins/notifications" as Upstream

// Omarchy's notification service with one change: every popup, whatever its
// urgency or requested timeout, leaves the screen after 5 s. Upstream keeps
// low 5 s / normal 8 s (up to 30 s on request) and never expires critical, so
// a crash toast sat there until clicked. Everything else — DND, history,
// restore across restarts — is the stock service, loaded from /usr/share so
// it keeps tracking upstream. Dismissed toasts stay in the history.
Upstream.Service {
  readonly property int popupDuration: 5000

  function durationFor(urgency, expireTimeout) {
    return popupDuration
  }
}
