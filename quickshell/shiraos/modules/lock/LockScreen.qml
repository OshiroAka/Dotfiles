import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import ShiraOS

// ── ShiraOS Lockscreen ───────────────────────────────────
// Acionado via IPC: qs -c shiraos ipc call shiraos lockScreen
// Suporta: wallpaper estático, mpv (live), blur toggle, temas

WlSessionLock {
    id: sessionLock

    // Temas disponíveis: 0=center, 1=left, 2=clock-big
    property int  theme:       0
    property bool blurEnabled: true

    WlSessionLockSurface {
        id: lockSurface

        // ── Fundo ────────────────────────────────────────
        Item {
            id: root
            anchors.fill: parent

            // Wallpaper estático ou live via mpv
            LockBackground {
                id: bg
                anchors.fill: parent
                blurEnabled: sessionLock.blurEnabled
            }

            // Overlay escuro para legibilidade
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.35)
            }

            // ── Conteúdo por tema ─────────────────────────
            Loader {
                id: themeLoader
                anchors.fill: parent
                sourceComponent: sessionLock.theme === 0 ? themeCenterComp
                               : sessionLock.theme === 1 ? themeLeftComp
                               :                           themeClockComp
            }

            // ── Tema 0: Central (padrão) ──────────────────
            Component {
                id: themeCenterComp
                LockCenter {
                    anchors.fill: parent
                    onUnlock: function(pass) { authProc.tryAuth(pass) }
                    shakeOnFail: authProc.failed
                }
            }

            // ── Tema 1: Esquerda (estilo iOS) ─────────────
            Component {
                id: themeLeftComp
                LockLeft {
                    anchors.fill: parent
                    onUnlock: function(pass) { authProc.tryAuth(pass) }
                    shakeOnFail: authProc.failed
                }
            }

            // ── Tema 2: Relógio grande ────────────────────
            Component {
                id: themeClockComp
                LockClock {
                    anchors.fill: parent
                    onUnlock: function(pass) { authProc.tryAuth(pass) }
                    shakeOnFail: authProc.failed
                }
            }

            // ── Fade in ao abrir ──────────────────────────
            Rectangle {
                id: fadeOverlay
                anchors.fill: parent
                color: "black"
                opacity: 1.0
                z: 100
                NumberAnimation on opacity {
                    id: fadeIn
                    from: 1.0; to: 0.0
                    duration: 1400
                    easing.type: Easing.OutCubic
                    running: true
                }
            }

            // ── Autenticação via PAM ──────────────────────
            QtObject {
                id: authProc
                property bool failed: false

                function tryAuth(password) {
                    pamProc.password = password
                    pamProc.running  = true
                    failed = false
                }
            }

            Process {
                id: pamProc
                property string password: ""
                command: ["bash", "-c",
                    "echo '" + pamProc.password.replace("'", "'\\''") +
                    "' | pamtester login " + Qt.getenv("USER") + " authenticate 2>/dev/null && echo SUCCESS || echo FAIL"
                ]
                running: false
                stdout: SplitParser {
                    onRead: function(line) {
                        if (line.trim() === "SUCCESS") {
                            sessionLock.locked = false
                        } else {
                            authProc.failed = true
                            failTimer.restart()
                        }
                    }
                }
            }

            Timer {
                id: failTimer
                interval: 600
                onTriggered: authProc.failed = false
            }
        }
    }
}
