import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import ShiraOS

PanelWindow {


    id: win

    WlrLayershell.namespace: "shiraos-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: AppState.wallpaperOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    color: "transparent"
    focusable: true

    Region { id: emptyMask }
    mask: AppState.wallpaperOpen ? null : emptyMask

    property bool settingsOpen: false
    property string lastEngineShotKey: ""
    property bool captureHideUi: false
    property bool isVertical: panelPosition === "right" || panelPosition === "left"

    property real panelThick: 200
    property real panelSpan: 0.82
    property bool fillEdges: false
    property real edgeGap: fillEdges ? 0 : 20
    property int thumbRadius: 14
    property real pillOpacity: 0.60
    property int cfgTab: 0
    property int settingsSidebarWidth: 256
    property real settingsTabAnim: 1.0
    property real settingsBackdropOpacity: 0.22
    property real settingsPanelOpacity: 0.97
    property real settingsPanelScale: 1.0
    property string settingsPlace: "center" // center | bottom

    property string swwwTransition: "grow"
    property string engineShotScript: "/home/shira/.config/quickshell/shiraos/scripts/wp-engine-cache-shot"
    property string panelPosition: "bottom"
    property string selectorBg: ""
    property bool useSelectorBg: false
    property string openStyle: "slide"
    property string moveStyle: "shooter"
    property string selectorStyle: "cards"
   property string colorBarPosition: "top" // top | bottom

property real skewHeight: 0.62
    property real skewShapeHeight: 1.00
    property real skewPictureHeight: 0.96
    property real skewWidth: 1.45
    property real skewOverlap: 0.10
    property real skewItemSpacing: -38
    property real skewCardScale: 1.0

    property bool varalShowPegs: true
    property string varalLineColor: "#cc4444"
    property int varalCount: 5
    property real varalScale: 1.0
    property real varalDrop: 84
    property real varalPhotoWidth: 118
    property real varalPhotoHeight: 168
    property string varalPaperColor: "#f6f6f4"
    property string varalStringColor: "#cfcfcf"
    property bool varalSwing: true
    property real varalSwingAngle: 3.6

    property bool _loaded: false
    property bool _scanning: false

    // SHIRA_STATIC_RAM_CACHE_V34_BEGIN
    property bool shiraStaticRamCacheEnabled: true
    property bool shiraStaticRamCacheReady: false
    property bool shiraForceScanOnce: false
    property int shiraStaticRamCacheCount: 0
    // SHIRA_STATIC_RAM_CACHE_V34_END

    onCfgTabChanged: {
        settingsTabAnim = 0.0
        settingsTabAnimRunner.restart()
    }

    NumberAnimation {
        id: settingsTabAnimRunner
        target: win
        property: "settingsTabAnim"
        from: 0.0
        to: 1.0
        duration: 320
        easing.type: Easing.OutCubic
    }


    property real sw: screen ? screen.width : 1920
    property real sh: screen ? screen.height : 1080

    property real pillW: {
        if (selectorStyle === "skew") return sw
        if (isVertical) return panelThick
        if (fillEdges) return sw
        return sw * panelSpan
    }

    property real pillH: {
        if (selectorStyle === "skew") return Math.round(sh * skewHeight)
        if (selectorStyle === "varal") return Math.round(sh * 0.46)
        if (isVertical) return sh * panelSpan
        return panelThick
    }

    property real pillX: {
        if (selectorStyle === "skew") return 0
        if (panelPosition === "right") return sw - pillW - edgeGap
        if (panelPosition === "left") return edgeGap
        return fillEdges ? 0 : (sw - pillW) / 2
    }

    property real pillY: {
        if (selectorStyle === "skew") return (sh - pillH) / 2
        if (panelPosition === "top") return edgeGap
        if (panelPosition === "bottom") return sh - pillH - edgeGap
        return (sh - pillH) / 2
    }

    property int activeCategory: 2
    readonly property var catNames: ["♥", "Engine", "Static", "MPV"]

    property bool engineShowPreview: true
    property bool engineApplyPreview: true
    property bool enginePreviewTheme: true
    property bool caelestiaPywalEnabled: false
    property bool caelestiaPywalAutoApply: true

    property var staticWalls: []
    property var engineWalls: []
    property var liveWalls: []
    property var favorites: []
    property var hiddenWalls: ({ static: [], live: [], engine: [] })
    property var firstSeenWalls: ({})
    property int exclusionTab: 0
    readonly property var exclusionNames: ["Static", "MPV", "Engine"]
    property var selectorBgList: []
    property var favSet: ({})

    property int staticHl: 0
    property int engineHl: 0
    property int liveHl: 0
    property int favHl: 0

    property var sourceWalls: {
       if (activeCategory === 0) return favorites
       if (activeCategory === 1) return engineWalls
       if (activeCategory === 2) return staticWalls
       return liveWalls
   }
   property var currentWalls: {
       return filterHidden(sourceWalls || [], activeCategory)
   }

property int highlightIdx: {
        if (activeCategory === 0) return favHl
        if (activeCategory === 1) return engineHl
        if (activeCategory === 2) return staticHl
        return liveHl
    }

    onFavoritesChanged: rebuildFavSet()

    
    function hiddenTypeOfCat(cat) {
        if (cat === 1) return "engine"
        if (cat === 3) return "live"
        return "static"
    }

    function pathOfAny(item, cat) {
        if (cat === 1) return item.path || ""
        if (cat === 0) return item.applyPath || ""
        return typeof item === "string" ? item : (item.path || "")
    }

    function isHiddenWall(item, cat) {
        var type = hiddenTypeOfCat(cat)
        var p = pathOfAny(item, cat)
        var list = hiddenWalls[type] || []
        return list.indexOf(p) >= 0
    }

    function filterHidden(list, cat) {
        var out = []
        for (var i = 0; i < list.length; i++) {
            if (!isHiddenWall(list[i], cat))
                out.push(list[i])
        }
        return out
    }

    function toggleHiddenWall(type, path) {
        if (!path) return

        var h = {
            static: (hiddenWalls.static || []).slice(),
            live: (hiddenWalls.live || []).slice(),
            engine: (hiddenWalls.engine || []).slice()
        }

        var arr = h[type] || []
        var idx = arr.indexOf(path)

        if (idx >= 0)
            arr.splice(idx, 1)
        else
            arr.push(path)

        h[type] = arr
        hiddenWalls = h
        scheduleSave()
            clampHighlights()
        scheduleSave()
    }

    function dedupeWalls(list, cat) {
        var out = []
        var seen = {}

        for (var i = 0; i < list.length; i++) {
            var p = pathOfAny(list[i], cat)
            if (!p || seen[p])
                continue

            seen[p] = true
            out.push(list[i])
        }

        return out
    }

    function sortByFirstSeen(list, cat) {
        var arr = dedupeWalls(list, cat)
        arr.sort(function(a, b) {
            var pa = pathOfAny(a, cat)
            var pb = pathOfAny(b, cat)
            var ta = firstSeenWalls[pa] || 0
            var tb = firstSeenWalls[pb] || 0
            return tb - ta
        })
        return arr
    }

    function markFirstSeen(path) {
        if (!path) return
        if (firstSeenWalls[path]) return

        var s = {}
        for (var k in firstSeenWalls)
            s[k] = firstSeenWalls[k]

        s[path] = Date.now()
        firstSeenWalls = s
    }

function rebuildFavSet() {
        var s = {}
        for (var i = 0; i < favorites.length; i++)
            s[favorites[i].applyPath] = true
        favSet = s
    }

    function applyPathOf(item, cat) {
        if (cat === 0) return item.applyPath || ""
        if (cat === 1) return item.path || ""
        return typeof item === "string" ? item : (item.path || "")
    }

    function previewPathOf(item, cat) {
        if (cat === 0) return item.dispPath || item.previewPath || item.applyPath || ""
        if (cat === 1) return engineShowPreview ? (item.preview || "") : ""
        return typeof item === "string" ? item : (item.path || "")
    }

    function applyTypeOf(cat) {
        if (cat === 1) return "engine"
        if (cat === 3) return "live"
        return "static"
    }

    function isFav(item) {
        var p = applyPathOf(item, activeCategory)
        return !!favSet[p]
    }

    function engineShotKey(item){
        var raw = "" + (item.id || item.applyPath || item.path || item.previewPath || item.preview || "engine")
        var leaf = raw.split("/").pop()
        leaf = leaf.replace(/\\.[^.]+$/, "")
        return leaf.replace(/[^A-Za-z0-9._-]+/g, "_")
    }
    function requestEngineShot(item){
        return
    }

    function shellQuotePath(path){
        return "'" + ("" + path).replace(/'/g, "'\\''") + "'"
    }
    function startEngineWallpaper(path, item){
        if (!path) return
        applyEngine.command = [
            "bash", "-lc",
            "pkill -f '[l]inux-wallpaperengine' 2>/dev/null || true; sleep 0.20; nohup linux-wallpaperengine --screen-root eDP-1 --bg \"$1\" >/dev/null 2>&1 &",
            "sh",
            path
        ]
        applyEngine.running = false
        applyEngine.running = true
    }
    function thumbSrc(item, cat){
        var lowVideoPath = (typeof item === "string" ? item : (item.path || ""))
        var lowVideo = ("" + lowVideoPath).toLowerCase()
        if (lowVideo.endsWith(".mp4") || lowVideo.endsWith(".webm") || lowVideo.endsWith(".mkv") || lowVideo.endsWith(".mov"))
            return "file://" + win.mpvThumbPath(lowVideoPath)

        var p = previewPathOf(item, cat)
        if (!p) return ""

        var low = ("" + p).toLowerCase()
        if (low.endsWith(".mp4") || low.endsWith(".webm") || low.endsWith(".mkv") || low.endsWith(".mov")) {
            var file = ("" + p).split("/").pop()
            var base = file.replace(/\.[^.]+$/, "")
            return "file:///home/shira/.cache/qs_mpv_thumb_" + base + ".jpg"
        }

        return "file://" + p
    }
    function thumbIsAnimated(item, cat) {
        var p = previewPathOf(item, cat)
        if (!p) return false
        var low = ("" + p).toLowerCase()
        return low.endsWith(".gif")
    }


    function thumbLabel(item, cat) {
        var p = applyPathOf(item, cat)
        if (!p) return ""
        return p.replace(/.*\//, "").replace(/\.[^.]+$/, "")
    }

    function clampHighlights() {
        staticHl = Math.max(0, Math.min(staticHl, Math.max(0, staticWalls.length - 1)))
        engineHl = Math.max(0, Math.min(engineHl, Math.max(0, engineWalls.length - 1)))
        liveHl = Math.max(0, Math.min(liveHl, Math.max(0, liveWalls.length - 1)))
        favHl = Math.max(0, Math.min(favHl, Math.max(0, favorites.length - 1)))
    }

    function setHighlight(cat, idx) {
        var old = highlightIdx
        if (idx > old) navDir = 1
        else if (idx < old) navDir = -1
        if (cat === 0) favHl = idx
        else if (cat === 1) engineHl = idx
        else if (cat === 2) staticHl = idx
        else liveHl = idx
    }

    property color gc1: AppState.accentPill || Qt.rgba(0.05, 0.07, 0.15, 0.70)
    property color gc2: AppState.accentDark || Qt.rgba(0.02, 0.03, 0.10, 0.96)
    property color cAc: AppState.accentColor || Qt.rgba(0.50, 0.70, 1.00, 1.00)
    property color cRm: AppState.accentBorder || Qt.rgba(0.35, 0.52, 0.95, 0.20)

    Behavior on gc1 { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on gc2 { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on cAc { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on cRm { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

    property real animProg: 0
    property real shimmerProg: -0.5
    property real shootProg: 0
    property bool shootActive: false
    property real shootFX: 0
    property real shootFY: 0
    property real shootTX: 0
    property real shootTY: 0
    property real navProg: 1
    property int navDir: 0
    property bool navActive: false

    // SHIRA_MAX_ANIM_V29_BEGIN
    property bool shiraCardIntroEnabled: true
    property real shiraCardIntroStagger: 0.055
    property real shiraCardIntroSpan: 0.42
    property real shiraAnimStrength: 1.0

    function shiraClamp01V29(v) {
        return Math.max(0, Math.min(1, v))
    }

    function shiraEaseSmoothV29(v) {
        v = shiraClamp01V29(v)
        return v * v * (3 - 2 * v)
    }

    function openBaseDuration(style) {
        if (style === "cinema") return 620
        if (style === "bloom") return 580
        if (style === "iris") return 560
        if (style === "bounce") return 560
        if (style === "wave") return 590
        if (style === "flip") return 560
        if (style === "float") return 520
        if (style === "ritual") return 880
        if (style === "portal") return 820
        if (style === "cascade") return 760
        if (style === "zoom") return 540
        if (style === "unfold") return 500
        if (style === "rise") return 460
        if (style === "scale") return 430
        if (style === "slide") return 410
        if (style === "soft") return 390
        if (style === "fade") return 360
        return 420
    }

    function openEasing(style) {
        if (style === "cinema" || style === "bloom" || style === "bounce" || style === "zoom" || style === "wave" || style === "flip" || style === "ritual" || style === "portal")
            return Easing.OutBack
        if (style === "float" || style === "cascade")
            return Easing.OutExpo
        return Easing.OutCubic
    }

    function moveDuration(style) {
        if (style === "snap") return 210
        if (style === "fichas") return 860
        if (style === "elastic") return 520
        if (style === "trail" || style === "shooter") return 430
        if (style === "fade") return 300
        if (style === "none") return 1
        return 360
    }

    function moveEasing(style) {
        if (style === "fichas") return Easing.InOutCubic
        if (style === "elastic") return Easing.OutBack
        if (style === "snap") return Easing.OutCubic
        if (style === "trail" || style === "shooter") return Easing.OutExpo
        return Easing.InOutCubic
    }

    function tightCardSpacingMode() {
        return moveStyle === "fichas"
            || openStyle === "portal"
            || openStyle === "ritual"
            || openStyle === "cascade"
    }

    function replayOpenAnimation() {
        if (!AppState.wallpaperOpen) return

        shootActive = false
        navActive = false
        closeAnim.stop()
        openAnim.stop()
        shimmerAnim.stop()
        shootProg = 0
        navProg = 0
        shimmerProg = -0.5
        animProg = 0
        openAnim.restart()
        shimmerAnim.restart()
    }

    function returnToPreview() {
        settingsOpen = false
        Qt.callLater(function() {
            replayOpenAnimation()
            smoothCenterIndex(highlightIdx)
        })
    }
    // SHIRA_MAX_ANIM_V29_END

    NumberAnimation {
        id: openAnim
        target: win
        property: "animProg"
        from: 0
        to: 1
        duration: Math.round(openBaseDuration(openStyle) * shiraAnimStrength)
        easing.type: openEasing(openStyle)
    }

    NumberAnimation {
        id: closeAnim
        target: win
        property: "animProg"
        from: 1
        to: 0
        duration: Math.round(240 * shiraAnimStrength)
        easing.type: Easing.InCubic
    }

    SequentialAnimation {
        id: shimmerAnim
        NumberAnimation {
            target: win
            property: "shimmerProg"
            from: -0.5
            to: 1.5
            duration: 760
            easing.type: Easing.InOutSine
        }
        ScriptAction { script: win.shimmerProg = -0.5 }
    }

    Timer {
        id: delayedCenterTimer
        interval: 720
        repeat: false
        onTriggered: centerIndexAfterLayout(highlightIdx)
    }

    SequentialAnimation {
        id: shootAnim
        NumberAnimation {
            target: win
            property: "shootProg"
            from: 0
            to: 1
            duration: 420
            easing.type: Easing.OutCubic
        }
        ScriptAction { script: win.shootActive = false }
    }

    SequentialAnimation {
        id: navAnim
        ScriptAction {
            script: {
                win.navActive = true
                win.navProg = 0
            }
        }
        NumberAnimation {
            target: win
            property: "navProg"
            from: 0
            to: 1
            duration: Math.round(moveDuration(moveStyle) * shiraAnimStrength)
            easing.type: moveEasing(moveStyle)
        }
        ScriptAction {
            script: {
                win.navProg = 1
                win.navActive = false
            }
        }
    }

    onPanelPositionChanged: {
        if (moveStyle === "none") return
        shootFX = pillX + pillW / 2
        shootFY = pillY + pillH / 2
        Qt.callLater(function() {
            shootTX = pillX + pillW / 2
            shootTY = pillY + pillH / 2
            shootProg = 0
            shootActive = moveStyle === "shooter" || moveStyle === "trail"
            if (shootActive) shootAnim.restart()
        })
    }

    property var pendingEngineCommand: []
    property var pendingEngineItem: null

    Timer{
        id: startEngineLater
        interval: 180
        repeat: false
        onTriggered: {
            if (win.pendingEngineCommand.length > 0) {
                applyEngine.command = win.pendingEngineCommand
                applyEngine.running = false
                applyEngine.running = true
                // disabled: // disabled: // disabled: // disabled old-engine-restore: win.requestEngineShot(win.pendingEngineItem)
            }
        }
    }

    Process {
        id: loadProc
        running: false
        command: ["bash", "-lc", "cat ~/.config/quickshell/shiraos/wp_settings.json 2>/dev/null || echo '{}' "]
        stdout: SplitParser {
            onRead: function(raw) {
                var d = raw.trim()
                if (!d || d === "{}") return
                try {
                    var s = JSON.parse(d)
                    var keys = [
                        "panelThick", "panelSpan", "fillEdges", "thumbRadius", "pillOpacity",
                        "swwwTransition", "panelPosition", "settingsPlace", "useSelectorBg", "selectorBg",
                        "engineShowPreview", "engineApplyPreview", "enginePreviewTheme", "caelestiaPywalEnabled", "caelestiaPywalAutoApply",
                        "openStyle", "moveStyle", "selectorStyle", "shiraCardIntroEnabled", "shiraCardIntroStagger", "shiraCardIntroSpan", "shiraAnimStrength",
                        "skewHeight", "skewShapeHeight", "skewPictureHeight", "skewWidth", "skewOverlap", "skewItemSpacing", "skewCardScale",
                        "varalShowPegs", "varalLineColor", "varalCount", "varalScale",
                        "varalPaperColor", "varalStringColor", "varalSwing", "varalSwingAngle", "varalDrop"
                    ]
                    for (var i = 0; i < keys.length; i++)
                        if (typeof s[keys[i]] !== "undefined")
                            win[keys[i]] = s[keys[i]]
                    if (s.favorites && s.favorites.length)
                        win.favorites = s.favorites

                    if (s.hiddenWalls)
                        win.hiddenWalls = s.hiddenWalls

                    if (s.firstSeenWalls)
                        win.firstSeenWalls = s.firstSeenWalls

                    rebuildFavSet()
                } catch(e) {
                    console.log("wp settings parse error", e)
                }
            }
        }
        onExited: running = false
    }

    Process { id: saveProc; running: false; onExited: running = false }

    Timer {
        id: saveDebounce
        interval: 220
        repeat: false
        onTriggered: saveSettingsNow()
    }

    function scheduleSave() { saveDebounce.restart() }

    function saveSettingsNow() {
        var data = {
            panelThick: panelThick,
            panelSpan: panelSpan,
            fillEdges: fillEdges,
            thumbRadius: thumbRadius,
            pillOpacity: pillOpacity,
            swwwTransition: swwwTransition,
            engineShowPreview: engineShowPreview,
            engineApplyPreview: engineApplyPreview,
            enginePreviewTheme: enginePreviewTheme,
            caelestiaPywalEnabled: caelestiaPywalEnabled,
            caelestiaPywalAutoApply: caelestiaPywalAutoApply,
            panelPosition: panelPosition,
           settingsPlace: settingsPlace,
            useSelectorBg: useSelectorBg,
            selectorBg: selectorBg,
            openStyle: openStyle,
            moveStyle: moveStyle,
            shiraCardIntroEnabled: shiraCardIntroEnabled,
            shiraCardIntroStagger: shiraCardIntroStagger,
            shiraCardIntroSpan: shiraCardIntroSpan,
            shiraAnimStrength: shiraAnimStrength,
            selectorStyle: selectorStyle,
            skewHeight: skewHeight,
            skewShapeHeight: skewShapeHeight,
            skewPictureHeight: skewPictureHeight,
            skewWidth: skewWidth,
            skewOverlap: skewOverlap,
            skewItemSpacing: skewItemSpacing,
            skewCardScale: skewCardScale,
            varalShowPegs: varalShowPegs,
            varalLineColor: varalLineColor,
            varalCount: varalCount,
            varalScale: varalScale,
            varalPaperColor: varalPaperColor,
            varalStringColor: varalStringColor,
            varalSwing: varalSwing,
            varalSwingAngle: varalSwingAngle,
            varalDrop: varalDrop,
            favorites: favorites,
            hiddenWalls: hiddenWalls,
            firstSeenWalls: firstSeenWalls
        }
        saveProc.command = [
            "python3", "-c",
            "import sys,os; p=os.path.expanduser('~/.config/quickshell/shiraos/wp_settings.json'); os.makedirs(os.path.dirname(p), exist_ok=True); open(p,'w').write(sys.argv[1])",
            JSON.stringify(data)
        ]
        saveProc.running = false
        saveProc.running = true
    }


    onCAcChanged: {
        if (caelestiaPywalEnabled && caelestiaPywalAutoApply)
            caelestiaPywalTimer.restart()
    }

    Timer {
        id: caelestiaPywalTimer
        interval: 1200
        repeat: false
        onTriggered: applyCaelestiaPywalScheme(true)
    }

    function applyCaelestiaPywalScheme(forceApply) {
        if (!caelestiaPywalEnabled)
            return
        console.log("SHIRA_CAELESTIA_PYWAL_APPLY force=" + forceApply)
        Quickshell.execDetached([
            "bash",
            "-lc",
            "$HOME/.local/bin/shiraos-caelestia-pywal-scheme --apply --force --no-terminal --attempts 3 --no-terminal" + forceArg + " >> /tmp/shiraos-caelestia-pywal.log 2>&1"
        ])
    }

    Process {
        id: scanProc
        running: false
        command: ["bash", "-lc", "~/.config/quickshell/shiraos/scripts/wp-scan"]
        onStarted: {
            _scanning = true

            // SHIRA_STATIC_RAM_CACHE_V34_BEGIN
            // Não limpa os estáticos se já temos cache em RAM.
            // Isso evita reconstruir a lista toda vez que o seletor abre.
            if (!shiraStaticRamCacheEnabled || !shiraStaticRamCacheReady || shiraForceScanOnce)
                staticWalls = []

            engineWalls = []
            liveWalls = []
            selectorBgList = []
            // SHIRA_STATIC_RAM_CACHE_V34_END
        }
        stdout: SplitParser {
            onRead: function(lineRaw) {
                var line = lineRaw.trim()
                if (!line || line === "BEGIN" || line === "END") return
                var p = line.split("|")
                var kind = p[0]
                if (kind === "STATIC") {
                    // SHIRA_STATIC_RAM_CACHE_V34_BEGIN
                    if (shiraStaticRamCacheEnabled && shiraStaticRamCacheReady && !shiraForceScanOnce)
                        return
                    // SHIRA_STATIC_RAM_CACHE_V34_END

                    var spath = p.slice(1).join("|")
                    markFirstSeen(spath)
                    var a = staticWalls.slice()
                    a.push(spath)
                    staticWalls = sortByFirstSeen(a, 2)
                } else if (kind === "LIVE") {
                    var lpath = p.slice(1).join("|")
                    markFirstSeen(lpath)
                    var b = liveWalls.slice()
                    b.push(lpath)
                    liveWalls = sortByFirstSeen(b, 3)
                } else if (kind === "BG") {
                    var c = selectorBgList.slice(); c.push(p.slice(1).join("|")); selectorBgList = c
                } else if (kind === "ENGINE") {
                    var obj = { path: p[1] || "", preview: p.slice(2).join("|") || "" }
                    markFirstSeen(obj.path)
                    var e = engineWalls.slice()
                    e.push(obj)
                    engineWalls = sortByFirstSeen(e, 1)
                }
            }
        }
        onExited: {
            _scanning = false
            running = false

            // SHIRA_STATIC_RAM_CACHE_V34_BEGIN
            if (staticWalls && staticWalls.length > 0) {
                shiraStaticRamCacheReady = true
                shiraStaticRamCacheCount = staticWalls.length
            }

            shiraForceScanOnce = false
            // SHIRA_STATIC_RAM_CACHE_V34_END

            clampHighlights()
        }
    }

    function scanWallpapers(force) {
        // SHIRA_STATIC_RAM_CACHE_V34_BEGIN
        force = force === true

        if (force) {
            shiraForceScanOnce = true
            shiraStaticRamCacheReady = false
        }

        // Se já temos cache estático em RAM, não reescaneia ao abrir.
        if (shiraStaticRamCacheEnabled && shiraStaticRamCacheReady && !force) {
            console.log("SHIRA_STATIC_RAM_CACHE_V34_HIT", shiraStaticRamCacheCount)
            clampHighlights()
            return
        }

        console.log("SHIRA_STATIC_RAM_CACHE_V34_SCAN", "force=" + force)
        // SHIRA_STATIC_RAM_CACHE_V34_END

        if (!scanProc.running)
            scanProc.running = true
    }

    Process { id: applyStatic; running: false; onExited: running = false }
    Process { id: applyEngine; running: false; onExited: running = false }
    Process{id:captureEngineShot;running:false}
    Process { id: applyLive; running: false; onExited: running = false }
    Process { id: killEngine; running: false; command: ["bash", "-lc", "pkill -f linux-wallpaperengine 2>/dev/null; true"]; onExited: running = false }
    Process { id: killLive; running: false; command: ["bash", "-lc", "pkill -f mpvpaper 2>/dev/null; true"]; onExited: running = false }

    function shellQuote(s) { return "'" + ("" + s).replace(/'/g, "'\\''") + "'" }

    Process {
        id: walProc
        running: false
        property string wallPath: ""
        command: [
            "bash", "-lc",
            "WALL=" + shellQuote(walProc.wallPath) + "; " +
            "[ -z \"$WALL\" ] && exit 0; " +
            "mkdir -p ~/.cache/shiraos; echo \"$WALL\" > ~/.cache/shiraos/current_wallpaper; " +
            "wal -i \"$WALL\" -n -q 2>/dev/null || true; " +
            "python3 - <<'PY'\n" +
            "import json, os\n" +
            "p=os.path.expanduser('~/.cache/wal/colors.json')\n" +
            "try:\n" +
            " d=json.load(open(p))\n" +
            " sp=d.get('special',{})\n" +
            " co=d.get('colors',{})\n" +
            " print('PRIMARY='+co.get('color4','#88aaff'))\n" +
            " print('BG='+sp.get('background','#101010'))\n" +
            "except Exception:\n" +
            " pass\n" +
            "PY"
        ]
        stdout: SplitParser {
            onRead: function(lineRaw) {
                var t = lineRaw.trim()
                if (!t) return
                function parseHex(h) {
                    h = h.replace("#", "")
                    if (h.length !== 6) return null
                    return { r: parseInt(h.substr(0, 2), 16) / 255, g: parseInt(h.substr(2, 2), 16) / 255, b: parseInt(h.substr(4, 2), 16) / 255 }
                }
                if (t.startsWith("PRIMARY=")) {
                    var cc = parseHex(t.replace("PRIMARY=", ""))
                    if (!cc) return
                    cAc = Qt.rgba(cc.r, cc.g, cc.b, 1.0)
                    cRm = Qt.rgba(cc.r, cc.g, cc.b, 0.22)
                    AppState.accentColor = cAc
                    AppState.accentPill = Qt.rgba(cc.r, cc.g, cc.b, 0.28)
                    AppState.accentBorder = cRm
                } else if (t.startsWith("BG=")) {
                    var cb = parseHex(t.replace("BG=", ""))
                    if (!cb) return
                    gc2 = Qt.rgba(cb.r, cb.g, cb.b, 0.96)
                    gc1 = Qt.rgba(Math.min(cb.r * 1.75, 1), Math.min(cb.g * 1.75, 1), Math.min(cb.b * 1.75, 1), 0.58)
                    AppState.accentDark = gc2
                    hyprBorderProc.col = t.replace("BG=", "").replace("#", "")
                    hyprBorderProc.running = false
                    hyprBorderProc.running = true
                }
            }
        }
        onExited: running = false
    }

    Timer {
        id: walCacheInit
        interval: 260
        repeat: false
        running: true
        onTriggered: {
            walProc.wallPath = "__CACHE_ONLY__"
            walProc.running = false
            walProc.running = true
        }
    }

    Process {
        id: hyprBorderProc
        running: false
        property string col: ""
        command: ["bash", "-lc", "hyprctl keyword general:col.active_border 'rgb(" + hyprBorderProc.col + ")' 2>/dev/null || true"]
        onExited: running = false
    }

    function runTheme(wallPath) {
        if (!wallPath) return
        walProc.wallPath = wallPath
        walProc.running = false
        walProc.running = true
    }

    function applyEngineWallpaper(item){
        if (!item) return
        var p = item.path || item.applyPath || ""
        if (!p) return
        var preview = item.preview || item.previewPath || item.dispPath || ""
        if (preview) {
            applyStatic.command = ["awww", "img", preview, "--transition-type", "fade", "--transition-duration", "0.25", "--transition-fps", "60"]
            applyStatic.running = false
            applyStatic.running = true
            win.runTheme(preview)
        }
        win.startEngineWallpaper(p, item)
    }
    function forceStartEngine(item){
        // disabled old-engine-restore: win.applyEngineWallpaper(item)
        return true
    }
    function mpvThumbPath(videoPath) {
        if (!videoPath) return ""
        var file = ("" + videoPath).split("/").pop()
        var base = file.replace(/\.[^.]+$/, "")
        return "/home/shira/.cache/qs_mpv_thumb_" + base + ".jpg"
    }
   function startLiveWallpaper(videoPath) {
       if (!videoPath) return

       var thumb = win.mpvThumbPath(videoPath)
       if (thumb) win.runTheme(thumb)

       killEngine.running = false
       killEngine.running = true

       applyLive.command = [
           "bash", "-lc",
           "pkill -f '[m]pvpaper' 2>/dev/null || true; sleep 0.10; " +
           "nohup mpvpaper -o 'no-audio loop-file=inf panscan=1.0 video-unscaled=no hwdec=auto-safe scale=bilinear cscale=bilinear dscale=bilinear interpolation=no deband=no' eDP-1 \"$1\" >/dev/null 2>&1 &",
           "sh",
           videoPath
       ]
       applyLive.running = false
       applyLive.running = true
   }

function doApply(item, cat) {
        if (cat === 0) {
            var tp = item.applyType || "static"

            if (tp === "static") {
                killEngine.running = false; killEngine.running = true
                killLive.running = false; killLive.running = true

                applyStatic.command = ["awww", "img", item.applyPath, "--transition-type", win.swwwTransition, "--transition-duration", "1", "--transition-fps", "60"]
                applyStatic.running = false; applyStatic.running = true

                win.runTheme(item.applyPath)

            } else if (tp === "engine") {
                killLive.running = false; killLive.running = true

                if (item.previewPath) {
                    applyStatic.command = ["awww", "img", item.previewPath, "--transition-type", "fade", "--transition-duration", "0.4"]
                    applyStatic.running = false; applyStatic.running = true
                    win.runTheme(item.previewPath)
                }

                applyEngine.command = ["linux-wallpaperengine", "--screen-root", "eDP-1", "--bg", item.applyPath]
                applyEngine.running = false; applyEngine.running = true

            } else {
                killEngine.running = false; killEngine.running = true

                win.startLiveWallpaper(item.applyPath)
            }

        } else if (cat === 2) {
            var sp = typeof item === "string" ? item : (item.path || "")

            killEngine.running = false; killEngine.running = true
            killLive.running = false; killLive.running = true

            applyStatic.command = ["awww", "img", sp, "--transition-type", win.swwwTransition, "--transition-duration", "1", "--transition-fps", "60"]
            applyStatic.running = false; applyStatic.running = true

            win.runTheme(sp)

        } else if (cat === 1) {
            killLive.running = false; killLive.running = true

            if (item.preview) {
                applyStatic.command = ["awww", "img", item.preview, "--transition-type", "fade", "--transition-duration", "0.4"]
                applyStatic.running = false; applyStatic.running = true
                win.runTheme(item.preview)
            }

            applyEngine.command = ["linux-wallpaperengine", "--screen-root", "eDP-1", "--bg", item.path]
            applyEngine.running = false; applyEngine.running = true

        } else {
            var lp = typeof item === "string" ? item : (item.path || "")

            killEngine.running = false; killEngine.running = true

            win.startLiveWallpaper(lp)
        }

        shimmerAnim.restart()
    }

    function applyCurrentWall() {
        var walls = win.currentWalls
        var idx = win.highlightIdx

        if (idx < 0 || idx >= walls.length) return

        doApply(walls[idx], win.activeCategory)

        if (activeCategory === 0)      win.favHl = idx
        else if (activeCategory === 1) win.engineHl = idx
        else if (activeCategory === 2) win.staticHl = idx
        else                           win.liveHl = idx
    }

    function applyModelPreset(name) {
        selectorStyle = name

        if (name === "pill") {
            panelThick = 200
            panelSpan = 0.82
            thumbRadius = 18
            fillEdges = false
            openStyle = "slide"
        } else if (name === "cards") {
            panelThick = 235
            panelSpan = 0.88
            thumbRadius = 16
            fillEdges = false
            openStyle = "rise"
        } else if (name === "skew") {
            skewHeight = 0.62
            skewWidth = 1.45
            panelSpan = 1.0
            fillEdges = true
            openStyle = "unfold"
        } else if (name === "spotlight") {
            panelThick = 270
            panelSpan = 0.92
            thumbRadius = 20
            fillEdges = false
            openStyle = "zoom"
        } else if (name === "varal") {
            panelThick = 285
            panelSpan = 1.0
            fillEdges = true
            thumbRadius = 8
            openStyle = "rise"
            varalDrop = Math.max(varalDrop, 84)
            varalScale = Math.max(varalScale, 0.95)
        }

        scheduleSave()
        Qt.callLater(function() { smoothCenterIndex(highlightIdx) })
    }

    function smoothCenterIndex(idx, oldIdxOverride) {
        if (idx < 0) return
        if (!wallList || wallList.count <= 0) return

        var oldX = wallList.contentX
        var oldY = wallList.contentY
        var oldIdx = oldIdxOverride === undefined ? highlightIdx : oldIdxOverride
        var targetX = oldX
        var targetY = oldY

        if (moveStyle === "fichas") {
            var item = wallList.itemAtIndex(idx)
            if (item && wallList.orientation === ListView.Horizontal) {
                targetX = Math.max(0, Math.min(wallList.contentWidth - wallList.width, item.x + item.width / 2 - wallList.width / 2))
            } else if (item) {
                targetY = Math.max(0, Math.min(wallList.contentHeight - wallList.height, item.y + item.height / 2 - wallList.height / 2))
            }
        } else {
            // Calcula o destino usando o método nativo, mas volta imediatamente
            // para a posição antiga e anima manualmente até o destino.
            wallList.positionViewAtIndex(idx, ListView.Center)

            targetX = wallList.contentX
            targetY = wallList.contentY

            wallList.contentX = oldX
            wallList.contentY = oldY
        }

        if (idx > oldIdx) navDir = 1
        else if (idx < oldIdx) navDir = -1
        if (moveStyle !== "none") {
            navProg = 0
            if (moveStyle === "shooter" || moveStyle === "trail") {
                var cx = pillX + pillW / 2
                var cy = pillY + pillH / 2
                var dist = isVertical ? Math.min(170, pillH * 0.32) : Math.min(220, pillW * 0.28)
                shootFX = cx - (isVertical ? 0 : navDir * dist)
                shootFY = cy - (isVertical ? navDir * dist : 0)
                shootTX = cx + (isVertical ? 0 : navDir * dist)
                shootTY = cy + (isVertical ? navDir * dist : 0)
                shootProg = 0
                shootActive = true
                shootAnim.restart()
            }
            navAnim.restart()
        }

        if (wallList.orientation === ListView.Horizontal) {
            scrollXAnim.stop()
            scrollXAnim.duration = Math.round((moveStyle === "fichas" ? 920 : moveDuration(moveStyle)) * shiraAnimStrength)
            scrollXAnim.easing.type = moveEasing(moveStyle)
            scrollXAnim.from = oldX
            scrollXAnim.to = targetX
            scrollXAnim.restart()
        } else {
            scrollYAnim.stop()
            scrollYAnim.duration = Math.round((moveStyle === "fichas" ? 920 : moveDuration(moveStyle)) * shiraAnimStrength)
            scrollYAnim.easing.type = moveEasing(moveStyle)
            scrollYAnim.from = oldY
            scrollYAnim.to = targetY
            scrollYAnim.restart()
        }

    }

    function centerIndexAfterLayout(idx) {
        if (idx < 0) return
        if (!wallList || wallList.count <= 0) return

        var oldX = wallList.contentX
        var oldY = wallList.contentY
        var targetX = oldX
        var targetY = oldY
        var item = wallList.itemAtIndex(idx)

        if (item && wallList.orientation === ListView.Horizontal) {
            targetX = Math.max(0, Math.min(wallList.contentWidth - wallList.width, item.x + item.width / 2 - wallList.width / 2))
        } else if (item) {
            targetY = Math.max(0, Math.min(wallList.contentHeight - wallList.height, item.y + item.height / 2 - wallList.height / 2))
        } else {
            wallList.positionViewAtIndex(idx, ListView.Center)
            targetX = wallList.contentX
            targetY = wallList.contentY
            wallList.contentX = oldX
            wallList.contentY = oldY
        }

        if (wallList.orientation === ListView.Horizontal) {
            if (Math.abs(targetX - oldX) < 2) return
            scrollXAnim.stop()
            scrollXAnim.duration = Math.round(620 * shiraAnimStrength)
            scrollXAnim.easing.type = Easing.InOutCubic
            scrollXAnim.from = oldX
            scrollXAnim.to = targetX
            scrollXAnim.restart()
        } else {
            if (Math.abs(targetY - oldY) < 2) return
            scrollYAnim.stop()
            scrollYAnim.duration = Math.round(620 * shiraAnimStrength)
            scrollYAnim.easing.type = Easing.InOutCubic
            scrollYAnim.from = oldY
            scrollYAnim.to = targetY
            scrollYAnim.restart()
        }
    }

    function navigate(dir) {
        var walls = currentWalls
        if (!walls.length) return
        var old = highlightIdx
        var n = Math.max(0, Math.min(highlightIdx + dir, walls.length - 1))
        setHighlight(activeCategory, n)
        smoothCenterIndex(n, old)
    }

    function toggleFav() {
        var walls = currentWalls
        var idx = highlightIdx
        if (idx < 0 || idx >= walls.length) return

        if (activeCategory === 0) {
            var f0 = favorites.slice()
            f0.splice(idx, 1)
            favorites = f0
            scheduleSave()
            return
        }

        var item = walls[idx]
        var path = applyPathOf(item, activeCategory)
        var preview = previewPathOf(item, activeCategory)
        var obj = { dispPath: preview, applyType: applyTypeOf(activeCategory), applyPath: path, previewPath: preview }

        var f = favorites.slice()
        var removed = false
        for (var i = 0; i < f.length; i++) {
            if (f[i].applyPath === obj.applyPath) { f.splice(i, 1); removed = true; break }
        }
        if (!removed) f.push(obj)
        favorites = f
        rebuildFavSet()
        scheduleSave()
    }

    Connections {
        target: AppState
        function onWallpaperOpenChanged() {
            if (AppState.wallpaperOpen) {
                if (!_loaded) { _loaded = true; loadProc.running = true }
                settingsOpen = false
                replayOpenAnimation()
                scanWallpapers()
                Qt.callLater(function() { keyItem.forceActiveFocus() })
            } else {
                settingsOpen = false
                scheduleSave()
                closeAnim.restart()
            }
        }
    }

    Item {
        anchors.fill: parent

        Item {
            id: pill
            z: settingsOpen ? -100000 : 0
            x: pillX
            y: pillY
            width: pillW
            height: pillH
            visible: !settingsOpen && (AppState.wallpaperOpen || closeAnim.running || animProg > 0.01)
            enabled: !settingsOpen
            opacity: settingsOpen ? 0 : (openStyle === "fade" ? Math.min(1, animProg * 1.15) : animProg)
            Behavior on x { NumberAnimation { duration: 310; easing.type: Easing.InOutCubic } }
            Behavior on y { NumberAnimation { duration: 310; easing.type: Easing.InOutCubic } }
            Behavior on width { NumberAnimation { duration: 310; easing.type: Easing.InOutCubic } }
            Behavior on height { NumberAnimation { duration: 310; easing.type: Easing.InOutCubic } }

            transform: [
                Translate {
                    x: openStyle === "slide" ? (panelPosition === "right" ? (1 - animProg) * 54 : panelPosition === "left" ? -(1 - animProg) * 54 : 0)
                        : openStyle === "unfold" ? -(1 - animProg) * pill.width * 0.18
                        : openStyle === "wave" ? Math.sin((1 - animProg) * 3.14159) * (panelPosition === "left" ? -24 : panelPosition === "right" ? 24 : 0)
                        : openStyle === "flip" ? (1 - animProg) * (panelPosition === "left" ? -36 : panelPosition === "right" ? 36 : 0)
                        : openStyle === "float" ? 0
                        : openStyle === "ritual" ? Math.sin(animProg * 9.42477) * (1 - animProg) * 18
                        : openStyle === "portal" ? Math.sin(animProg * 6.28318) * (1 - animProg) * 12
                        : openStyle === "cascade" ? -(1 - animProg) * pill.width * 0.10
                        : openStyle === "cinema" ? 0
                        : openStyle === "bloom" ? 0
                        : openStyle === "iris" ? 0
                        : 0
                    y: openStyle === "slide" || openStyle === "rise" ? (panelPosition === "bottom" ? (1 - animProg) * 54 : panelPosition === "top" ? -(1 - animProg) * 54 : (1 - animProg) * 28)
                        : openStyle === "soft" ? (1 - animProg) * 16
                        : openStyle === "dock" ? (1 - animProg) * 18
                        : openStyle === "wave" ? (1 - animProg) * (panelPosition === "top" ? -42 : 42) + Math.sin(animProg * 6.28318) * 7
                        : openStyle === "flip" ? (1 - animProg) * 18
                        : openStyle === "float" ? (1 - animProg) * 38
                        : openStyle === "ritual" ? (1 - animProg) * 34 + Math.sin(animProg * 12.56636) * (1 - animProg) * 8
                        : openStyle === "portal" ? (1 - animProg) * 20
                        : openStyle === "cascade" ? (1 - animProg) * 48
                        : openStyle === "cinema" ? (1 - animProg) * 22
                        : openStyle === "bloom" ? (1 - animProg) * 14
                        : openStyle === "iris" ? 0
                        : 0
                },
                Scale {
                    xScale: openStyle === "iris" ? Math.max(0.03, animProg)
                        : openStyle === "cinema" ? (0.18 + 0.82 * animProg)
                        : openStyle === "bloom" ? (0.12 + 0.88 * animProg)
                        : openStyle === "wave" ? (0.76 + 0.24 * animProg + Math.sin(animProg * 3.14159) * 0.05)
                        : openStyle === "flip" ? (0.72 + 0.28 * animProg)
                        : openStyle === "float" ? (0.94 + 0.06 * animProg)
                        : openStyle === "ritual" ? (0.52 + 0.48 * animProg + Math.sin(animProg * 9.42477) * 0.035)
                        : openStyle === "portal" ? Math.max(0.10, 0.24 + 0.76 * animProg)
                        : openStyle === "cascade" ? (0.72 + 0.28 * animProg)
                        : openStyle === "unfold" ? Math.max(0.08, animProg)
                        : (openStyle === "scale" || openStyle === "bounce" || openStyle === "zoom" ? 0.88 + 0.12 * animProg : 1)
                    yScale: openStyle === "iris" ? Math.max(0.10, 0.22 + 0.78 * animProg)
                        : openStyle === "cinema" ? Math.max(0.04, 0.08 + 0.92 * animProg)
                        : openStyle === "bloom" ? Math.max(0.08, 0.16 + 0.84 * animProg)
                        : openStyle === "wave" ? (0.82 + 0.18 * animProg - Math.sin(animProg * 3.14159) * 0.04)
                        : openStyle === "flip" ? (0.90 + 0.10 * animProg)
                        : openStyle === "float" ? (0.92 + 0.08 * animProg)
                        : openStyle === "ritual" ? (0.42 + 0.58 * animProg)
                        : openStyle === "portal" ? Math.max(0.05, 0.10 + 0.90 * animProg)
                        : openStyle === "cascade" ? (0.62 + 0.38 * animProg)
                        : openStyle === "unfold" ? 0.92 + 0.08 * animProg
                        : xScale
                    origin.x: pill.width / 2
                    origin.y: pill.height / 2
                }
            ]
            rotation: openStyle === "flip" ? (1 - animProg) * (panelPosition === "left" ? -5 : 5)
                : openStyle === "wave" ? Math.sin((1 - animProg) * 3.14159) * 2.4
                : openStyle === "ritual" ? Math.sin((1 - animProg) * 12.56636) * 3.2
                : openStyle === "cascade" ? (1 - animProg) * -2.0
                : 0
            Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }


            Item {
                id: openDramaFx
                anchors.fill: parent
                visible: AppState.wallpaperOpen && (openStyle === "bloom" || openStyle === "cinema" || openStyle === "iris" || openStyle === "zoom" || openStyle === "bounce" || openStyle === "unfold" || openStyle === "wave" || openStyle === "flip" || openStyle === "float" || openStyle === "ritual" || openStyle === "portal" || openStyle === "cascade")
                opacity: openStyle === "ritual" || openStyle === "portal" || openStyle === "cascade" ? Math.max(0, 1 - Math.abs(animProg - 0.48) * 1.65) : Math.max(0, 1 - Math.abs(animProg - 0.42) * 2.3)
                z: 20
                clip: true

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * (0.08 + animProg * 1.20)
                    height: parent.height * (0.18 + animProg * 1.10)
                    radius: Math.min(width, height) / 2
                    color: Qt.rgba(cAc.r, cAc.g, cAc.b, openStyle === "cinema" ? 0.12 : 0.18)
                    border.color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.32)
                    border.width: 1
                    antialiasing: true
                }

                Repeater {
                    model: openStyle === "ritual" || openStyle === "portal" ? 3 : 0

                    delegate: Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * (0.16 + animProg * (0.50 + index * 0.18))
                        height: parent.height * (0.24 + animProg * (0.30 + index * 0.14))
                        radius: Math.min(width, height) / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(cAc.r, cAc.g, cAc.b, Math.max(0, 0.32 - index * 0.07) * Math.max(0, 1 - animProg * 0.55))
                        rotation: (animProg * 26) * (index % 2 === 0 ? 1 : -1)
                        opacity: Math.max(0, 1 - Math.abs(animProg - 0.48) * 1.55)
                        antialiasing: true
                    }
                }

                Repeater {
                    model: openStyle === "cascade" || openStyle === "ritual" ? 5 : 0

                    delegate: Rectangle {
                        width: parent.width * (0.10 + index * 0.10)
                        height: 2
                        radius: 1
                        x: parent.width * (0.10 + index * 0.16) - width / 2
                        y: parent.height * (0.18 + index * 0.14) + Math.sin(animProg * 6.28318 + index) * 8
                        color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.26 - index * 0.025)
                        opacity: Math.max(0, Math.sin(animProg * 3.14159)) * 0.85
                    }
                }

                Repeater {
                    model: openStyle === "ritual" ? 10 : openStyle === "portal" ? 8 : 0

                    delegate: Rectangle {
                        property real angle: (index / Math.max(1, parent.children.length)) * 6.28318 + animProg * 1.7
                        property real rad: Math.min(parent.width, parent.height) * (0.12 + animProg * 0.36 + (index % 3) * 0.018)
                        width: 4 + (index % 3)
                        height: width
                        radius: width / 2
                        x: parent.width / 2 + Math.cos(angle) * rad - width / 2
                        y: parent.height / 2 + Math.sin(angle) * rad * 0.42 - height / 2
                        color: cAc
                        opacity: Math.max(0, 1 - animProg) * (0.50 + (index % 4) * 0.08)
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * (0.02 + animProg * 0.98)
                    height: 2
                    radius: 1
                    color: Qt.rgba(1, 1, 1, 0.24)
                    visible: openStyle === "cinema" || openStyle === "cascade"
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: selectorStyle === "pill" ? Math.min(width, height) / 2 : 18
                antialiasing: true
                clip: true
                color: selectorStyle === "skew" || selectorStyle === "varal" ? "transparent" : Qt.rgba(gc1.r, gc1.g, gc1.b, pillOpacity)

                Image {
                    anchors.fill: parent
                    source: useSelectorBg && selectorBg ? "file://" + selectorBg : ""
                    visible: status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    opacity: 0.56
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: selectorStyle === "skew" || selectorStyle === "varal" ? "transparent" : cRm
                    border.width: 1
                }
            }

            Item {
                id: keyItem
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: AppState.toggleWallpaper()
                Keys.onReturnPressed: applyCurrentWall()
                Keys.onEnterPressed: applyCurrentWall()
                Keys.onUpPressed: {
                    if (!isVertical) { activeCategory = (activeCategory + catNames.length - 1) % catNames.length; smoothCenterIndex(highlightIdx) }
                    else navigate(-1)
                }
                Keys.onDownPressed: {
                    if (!isVertical) { activeCategory = (activeCategory + 1) % catNames.length; smoothCenterIndex(highlightIdx) }
                    else navigate(1)
                }
                Keys.onLeftPressed: {
                    if (!isVertical) navigate(-1)
                    else { activeCategory = (activeCategory + catNames.length - 1) % catNames.length; smoothCenterIndex(highlightIdx) }
                }
                Keys.onRightPressed: {
                    if (!isVertical) navigate(1)
                    else { activeCategory = (activeCategory + 1) % catNames.length; smoothCenterIndex(highlightIdx) }
                }
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Space) { toggleFav(); event.accepted = true }
                }
            }

            Column {
                visible: !isVertical
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Repeater {
                    model: catNames
                    delegate: Item {
                        width: 32
                        height: 28
                        property bool act: index === activeCategory
                        Text { visible: index === 0; anchors.centerIn: parent; text: "♥"; font.pixelSize: act ? 17 : 11; color: act ? cAc : Qt.rgba(1, 1, 1, 0.24) }
                        Rectangle {
                            visible: index !== 0
                            anchors.centerIn: parent
                            width: act ? 20 : 7
                            height: 7
                            radius: 4
                            color: act ? cAc : Qt.rgba(1, 1, 1, 0.22)
                            Behavior on width { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { activeCategory = index; smoothCenterIndex(highlightIdx) } }
                    }
                }
            }

            Row {
                visible: isVertical
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                Repeater {
                    model: catNames
                    delegate: Item {
                        width: 30
                        height: 30
                        property bool act: index === activeCategory
                        Text { visible: index === 0; anchors.centerIn: parent; text: "♥"; font.pixelSize: act ? 17 : 11; color: act ? cAc : Qt.rgba(1, 1, 1, 0.24) }
                        Rectangle {
                            visible: index !== 0
                            anchors.centerIn: parent
                            width: 7
                            height: act ? 20 : 7
                            radius: 4
                            color: act ? cAc : Qt.rgba(1, 1, 1, 0.22)
                            Behavior on height { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { activeCategory = index; smoothCenterIndex(highlightIdx) } }
                    }
                }
            }

            Item {
                anchors.fill: parent
                anchors.leftMargin: isVertical ? 8 : (selectorStyle === "skew" ? -72 : (fillEdges ? 38 : 52))
                anchors.rightMargin: isVertical ? 8 : (selectorStyle === "skew" ? -36 : (fillEdges ? 8 : 46))
                anchors.topMargin: isVertical ? 56 : 8
                anchors.bottomMargin: 10
                clip: selectorStyle === "skew" ? false : true

                ListView {
                    id: wallList
                    property real gluedOverlap: selectorStyle === "skew" ? Math.round(sw * 0.145) : 128
                    anchors.fill: parent
                    orientation: isVertical ? ListView.Vertical : ListView.Horizontal
                    spacing: !isVertical && tightCardSpacingMode() ? (moveStyle === "fichas" ? -gluedOverlap : selectorStyle === "skew" ? Math.min(skewItemSpacing, -24) : 2)
                        : selectorStyle === "skew" ? skewItemSpacing
                        : selectorStyle === "varal" ? 8
                        : 10
                    clip: selectorStyle === "skew" ? false : true
                    cacheBuffer: moveStyle === "fichas" ? 2200 : 640
                    model: currentWalls
                    currentIndex: highlightIdx
                    snapMode: ListView.NoSnap
                    boundsBehavior: Flickable.StopAtBounds

                    NumberAnimation {
                        id: scrollXAnim
                        target: wallList
                        property: "contentX"
                        duration: 360
                        easing.type: Easing.InOutCubic
                    }

                    NumberAnimation {
                        id: scrollYAnim
                        target: wallList
                        property: "contentY"
                        duration: 360
                        easing.type: Easing.InOutCubic
                    }

                    delegate: Item {
                        id: card
                        property bool selected: index === highlightIdx
                        property bool fav: isFav(modelData)
                        property real navWave: navActive ? Math.max(0, 1 - Math.abs(index - highlightIdx) * 0.22) * (1 - navProg) : 0
                        property real selectDist: Math.abs(index - highlightIdx)
                        property bool chipMode: moveStyle === "fichas" && !isVertical && selectorStyle !== "varal"
                        property real chipEdgeBoost: chipMode && selected && currentWalls.length < 10 ? (10 - currentWalls.length) * 0.06 : 0
                        property real chipRatio: selected ? ((selectorStyle === "skew" ? 2.04 : 1.74) + chipEdgeBoost) : selectorStyle === "skew" ? 0.92 : 0.72
                        property real chipSide: index < highlightIdx ? 1 : index > highlightIdx ? -1 : 0
                        property real chipPullToFocus: selectorStyle === "skew" ? Math.round(sw * 0.205) : 150
                        property real chipGroupTighten: selectorStyle === "skew" ? Math.round(sw * 0.042) : 34
                        property real chipCloseShift: chipMode && !selected ? chipSide * (chipPullToFocus + Math.max(0, selectDist - 1) * chipGroupTighten) : 0
                        z: chipMode ? (selected ? 1000 : 1) : 0

                        // SHIRA_MAX_ANIM_CARD_V29_BEGIN
                        property real shiraIntroOrderV29: Math.min(index, 8)
                        property real shiraIntroRawV29: shiraCardIntroEnabled && AppState.wallpaperOpen
                            ? shiraClamp01V29((animProg - shiraIntroOrderV29 * shiraCardIntroStagger) / shiraCardIntroSpan)
                            : 1
                        property real shiraIntroEaseV29: shiraEaseSmoothV29(shiraIntroRawV29)
                        property real picIntro: shiraCardIntroEnabled ? (1 - shiraIntroEaseV29) : 0
                        property real picWave: Math.sin(shiraIntroEaseV29 * 3.14159)
                        property real picIntroX: openStyle === "cascade" ? -picIntro * (90 + index * 10)
                            : openStyle === "ritual" ? Math.sin(index * 1.7 + animProg * 8.0) * picIntro * 34
                            : openStyle === "portal" ? (index % 2 === 0 ? -1 : 1) * picIntro * 62
                            : openStyle === "wave" ? Math.sin(index * 0.9 + animProg * 6.28318) * picIntro * 24
                            : openStyle === "flip" ? (index % 2 === 0 ? -1 : 1) * picIntro * 32
                            : 0
                        property real picIntroY: openStyle === "cascade" ? picIntro * (70 + index * 8)
                            : openStyle === "ritual" ? Math.cos(index * 1.4 + animProg * 7.0) * picIntro * 28
                            : openStyle === "portal" ? picIntro * 46
                            : openStyle === "float" ? picIntro * 54
                            : openStyle === "wave" ? Math.cos(index * 0.8 + animProg * 6.28318) * picIntro * 14
                            : 0
                        property real picIntroRot: openStyle === "ritual" ? Math.sin(index + animProg * 10.0) * picIntro * 9
                            : openStyle === "portal" ? (index % 2 === 0 ? -1 : 1) * picIntro * 10
                            : openStyle === "cascade" ? -picIntro * 5
                            : openStyle === "flip" ? (index % 2 === 0 ? -1 : 1) * picIntro * 14
                            : openStyle === "wave" ? Math.sin(index + animProg * 5.0) * picIntro * 5
                            : 0
                        property real picIntroScale: openStyle === "portal" ? 0.70 + shiraIntroEaseV29 * 0.30
                            : openStyle === "ritual" ? 0.78 + shiraIntroEaseV29 * 0.22 + picWave * 0.035
                            : openStyle === "cascade" ? 0.76 + shiraIntroEaseV29 * 0.24
                            : openStyle === "float" ? 0.90 + shiraIntroEaseV29 * 0.10
                            : openStyle === "flip" ? 0.82 + shiraIntroEaseV29 * 0.18
                            : 1
                        // SHIRA_MAX_ANIM_CARD_V29_END
                        property real baseW: {
                            if (isVertical) return wallList.width - 12
                            if (selectorStyle === "skew") return Math.round(sw * 0.255)
                            if (selectorStyle === "spotlight") return Math.round(wallList.height * (selected ? 1.34 : 0.96))
                            if (selectorStyle === "varal") return Math.min(170, Math.round(wallList.height * 0.56))
                            return Math.round(wallList.height * 1.56)
                        }
                        property real baseH: {
                            if (isVertical) return Math.round(panelThick * 0.54)
                            if (selectorStyle === "varal") return wallList.height - 42
                            if (selectorStyle === "skew") return Math.max(160, Math.round(sh * 0.34))
                            return wallList.height - 14
                        }

                        width: isVertical ? wallList.width : (chipMode ? Math.round(baseW * chipRatio) + 8 : baseW + 12)
                        height: isVertical ? baseH + 12 : (selectorStyle === "skew" ? Math.max(wallList.height, Math.round(baseH * skewShapeHeight) + 32) : wallList.height)
                        scale: (selectorStyle === "skew" ? skewCardScale : 1.0)
                            * (chipMode ? (selected ? 1.0 : 0.965) : (selected ? (selectorStyle === "skew" ? 1.025 : 1.0) : 0.92))
                            * (shiraCardIntroEnabled ? (0.82 + shiraIntroEaseV29 * 0.18) : 1)
                            * picIntroScale
                            * (moveStyle === "elastic" ? (1 + navWave * 0.075) : moveStyle === "snap" && selected && navActive ? 1 + (1 - navProg) * 0.045 : 1)
                        opacity: (selected ? 1.0 : (chipMode ? 0.86 : 0.56))
                            * (shiraCardIntroEnabled ? shiraIntroEaseV29 : 1)
                            * (moveStyle === "fade" && navActive && !selected ? 0.72 + navProg * 0.28 : 1)

                        Behavior on width { NumberAnimation { duration: Math.round((moveStyle === "fichas" ? 900 : 360) * shiraAnimStrength); easing.type: moveStyle === "fichas" ? Easing.InOutCubic : Easing.OutBack } }
                        Behavior on scale { NumberAnimation { duration: moveStyle === "fichas" ? 520 : 140; easing.type: Easing.InOutCubic } }
                        Behavior on opacity { NumberAnimation { duration: moveStyle === "fichas" ? 260 : 140; easing.type: Easing.OutCubic } }

                        Item {
                            id: holder
                            property real swingBase: selectorStyle === "varal" ? ((index % 2 === 0 ? -2.4 : 2.4) + (selected ? 0 : (index % 3 - 1) * 1.0)) : 0
                            property real swingOffset: 0
                            property real frameW: selectorStyle === "varal" ? Math.round(varalPhotoWidth * varalScale) : (card.chipMode ? Math.max(64, card.width - 8) : baseW)
                            property real frameH: selectorStyle === "varal" ? Math.round(varalPhotoHeight * varalScale) : (selectorStyle === "skew" ? Math.round(baseH * skewShapeHeight) : (card.chipMode && !card.selected ? Math.round(baseH * 0.94) : baseH))
                            width: frameW
                            height: frameH + (selectorStyle === "varal" ? (Math.round(varalDrop) + 24) : 0)
                            anchors.centerIn: parent
                            // SHIRA_SKEW_GROW_UP_FIXED
                            anchors.verticalCenterOffset: (selectorStyle === "skew" ? -Math.max(0, (holder.frameH - baseH) / 2) : 0)
                                + (moveStyle === "elastic" && navActive ? Math.sin((1 - navProg) * 3.14159) * 8 * (selected ? 1 : 0.45) : 0)
                                + (moveStyle === "snap" && navActive && selected ? (1 - navProg) * -4 : 0)
                            transformOrigin: Item.Top
                            rotation: selectorStyle === "varal" ? swingBase
                                : (shiraCardIntroEnabled ? (1 - card.shiraIntroEaseV29) * (index % 2 === 0 ? -2.8 : 2.8) : 0)
                                  + card.picIntroRot
                                  + (moveStyle === "elastic" && navActive ? navDir * card.navWave * 4.5 : 0)
                                  + ((moveStyle === "trail" || moveStyle === "shooter") && navActive ? navDir * card.navWave * 2.2 : 0)
                            transform: Translate {
                                x: card.picIntroX + card.chipCloseShift
                                   + (moveStyle === "elastic" && navActive ? -navDir * card.navWave * 18
                                   : (moveStyle === "trail" || moveStyle === "shooter") && navActive ? -navDir * card.navWave * 28
                                   : moveStyle === "snap" && navActive ? -navDir * card.navWave * 8
                                   : 0)
                                y: card.picIntroY
                                   + ((moveStyle === "trail" || moveStyle === "shooter") && navActive ? Math.sin((1 - navProg) * 3.14159) * 6 * card.navWave : 0)
                            }
                            Behavior on rotation { NumberAnimation { duration: 120; easing.type: Easing.InOutSine } }

                            SequentialAnimation {
                                id: swingLoop
                                running: selectorStyle === "varal" && varalSwing && AppState.wallpaperOpen
                                loops: Animation.Infinite
                                alwaysRunToEnd: true
                                NumberAnimation {
                                    target: holder
                                    property: "rotation"
                                    from: holder.swingBase - varalSwingAngle
                                    to: holder.swingBase + varalSwingAngle
                                    duration: 1900 + index * 110
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    target: holder
                                    property: "rotation"
                                    from: holder.swingBase + varalSwingAngle
                                    to: holder.swingBase - varalSwingAngle
                                    duration: 1900 + index * 110
                                    easing.type: Easing.InOutSine
                                }
                            }

                            Rectangle {
                                visible: selectorStyle === "varal"
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 2
                                height: Math.max(22, varalDrop - 18)
                                radius: 1
                                color: varalStringColor
                                opacity: 0.95
                            }

                            Rectangle {
                                visible: selectorStyle === "varal" && varalShowPegs
                                width: 16
                                height: 10
                                radius: 4
                                color: "#bdb5ab"
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.topMargin: Math.max(14, varalDrop - 12)
                                border.width: 1
                                border.color: Qt.rgba(0, 0, 0, 0.12)
                            }

                            Rectangle {
                                visible: selectorStyle === "varal" && varalShowPegs
                                width: 28
                                height: 2
                                radius: 1
                                color: varalStringColor
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.topMargin: Math.max(18, varalDrop - 7)
                            }

                            Rectangle {
                                id: frame
                               anchors.alignWhenCentered: false
                                width: holder.frameW
                                height: holder.frameH
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: selectorStyle === "varal" ? varalDrop : 0
                                radius: selectorStyle === "cards" || selectorStyle === "skew" ? 8 : selectorStyle === "varal" ? 6 : thumbRadius
                                antialiasing: true
                                clip: true
                                color: selectorStyle === "varal" ? varalPaperColor : Qt.rgba(0, 0, 0, 0.30)
                                border.width: selected ? 2 : 1
                                border.color: selected ? cAc : (selectorStyle === "varal" ? Qt.rgba(1, 1, 1, 0.34) : Qt.rgba(1, 1, 1, 0.08))
                                layer.enabled: selectorStyle === "varal"
                               layer.smooth: true
                               layer.mipmap: true
                               layer.samples: 4
                               layer.textureSize: selectorStyle === "varal" ? Qt.size(Math.ceil(width * 2.5), Math.ceil(height * 2.5)) : Qt.size(width, height)
                                transform: Matrix4x4 { matrix: selectorStyle === "skew" ? Qt.matrix4x4(1, -0.18, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) : Qt.matrix4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }

                                // SHIRA_SKEW_BORDER_INSIDE_V27_BEGIN
                                Rectangle {
                                    visible: selectorStyle === "skew" && selected
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "transparent"
                                    border.width: 5
                                    border.color: cAc
                                    opacity: 0.18
                                    z: 900
                                    antialiasing: true
                                }

                                Rectangle {
                                    visible: selectorStyle === "skew" && selected
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    radius: Math.max(0, parent.radius - 2)
                                    color: "transparent"
                                    border.width: 3
                                    border.color: Qt.rgba(1, 1, 1, 0.75)
                                    opacity: 0.16
                                    z: 901
                                    antialiasing: true
                                }

                                Rectangle {
                                    visible: selectorStyle === "skew" && selected
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    radius: Math.max(0, parent.radius - 5)
                                    color: "transparent"
                                    border.width: 1
                                    border.color: cAc
                                    opacity: 0.78
                                    z: 902
                                    antialiasing: true
                                }
                                // SHIRA_SKEW_BORDER_INSIDE_V27_END


                                Rectangle {
                                    visible: selectorStyle === "varal"
                                    anchors.fill: parent
                                    color: varalPaperColor
                                }

                                AnimatedImage {
                                    id: engineGifThumb
                                    anchors.fill: parent
                                    anchors.margins: selectorStyle === "varal" ? 5 : 0
                                    source: thumbIsAnimated(modelData, activeCategory) ? thumbSrc(modelData, activeCategory) : ""
                                    visible: thumbIsAnimated(modelData, activeCategory)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    playing: visible
                                    paused: !visible
                                    smooth: true
                                    transformOrigin: Item.Center
                                    scale: openStyle === "ritual" ? 1.10 - card.shiraIntroEaseV29 * 0.10 + card.picWave * 0.025
                                        : openStyle === "portal" ? 1.22 - card.shiraIntroEaseV29 * 0.22
                                        : openStyle === "cascade" ? 1.16 - card.shiraIntroEaseV29 * 0.16
                                        : openStyle === "float" ? 1.06 - card.shiraIntroEaseV29 * 0.06
                                        : 1
                                    rotation: openStyle === "ritual" ? Math.sin(animProg * 10.0 + index) * card.picIntro * 3.5
                                        : openStyle === "portal" ? (index % 2 === 0 ? -1 : 1) * card.picIntro * 4.5
                                        : openStyle === "cascade" ? -card.picIntro * 2.5
                                        : 0
                                }

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: selectorStyle === "varal" ? 5 : 0
                                    anchors.bottomMargin: selectorStyle === "varal" ? 22 : 0
                                    fillMode: Image.PreserveAspectCrop
                                    source: thumbSrc(modelData, activeCategory)
                                    visible: !thumbIsAnimated(modelData, activeCategory)
                                    asynchronous: true
                                    cache: true
                                    smooth: true
                                    mipmap: true
                                    sourceSize.width: moveStyle === "fichas" ? 1800 : Math.max(1200, Math.round(parent.width * 3.0))
                                    sourceSize.height: moveStyle === "fichas" ? 1100 : Math.max(800, Math.round(parent.height * 3.0))
                                    opacity: status === Image.Ready ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                    transformOrigin: Item.Center
                                    scale: openStyle === "ritual" ? 1.10 - card.shiraIntroEaseV29 * 0.10 + card.picWave * 0.025
                                        : openStyle === "portal" ? 1.22 - card.shiraIntroEaseV29 * 0.22
                                        : openStyle === "cascade" ? 1.16 - card.shiraIntroEaseV29 * 0.16
                                        : openStyle === "float" ? 1.06 - card.shiraIntroEaseV29 * 0.06
                                        : openStyle === "wave" ? 1.04 + Math.sin(animProg * 6.28318 + index) * card.picIntro * 0.025
                                        : 1
                                    rotation: openStyle === "ritual" ? Math.sin(animProg * 10.0 + index) * card.picIntro * 3.5
                                        : openStyle === "portal" ? (index % 2 === 0 ? -1 : 1) * card.picIntro * 4.5
                                        : openStyle === "cascade" ? -card.picIntro * 2.5
                                        : openStyle === "flip" ? card.picIntro * (index % 2 === 0 ? -3 : 3)
                                        : 0
                                }

                                Rectangle {
                                    visible: openStyle === "ritual" || openStyle === "portal" || openStyle === "cascade" || openStyle === "wave"
                                    anchors.fill: parent
                                    color: Qt.rgba(cAc.r, cAc.g, cAc.b, openStyle === "portal" ? 0.12 : 0.07)
                                    opacity: card.picIntro * (openStyle === "cascade" ? 0.42 : 0.28)
                                }

                                Rectangle {
                                    visible: openStyle === "cascade" || openStyle === "ritual"
                                    width: parent.width * 0.34
                                    height: parent.height * 1.8
                                    radius: 10
                                    rotation: -32
                                    x: -width + card.shiraIntroEaseV29 * (parent.width + width * 1.6) + index * 5
                                    y: -parent.height * 0.40
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, 0.24) }
                                        GradientStop { position: 1.0; color: "transparent" }
                                    }
                                    opacity: Math.sin(card.shiraIntroEaseV29 * 3.14159) * 0.90
                                }

                                Repeater {
                                    model: openStyle === "portal" ? 2 : openStyle === "ritual" ? 3 : 0

                                    delegate: Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width * (0.32 + index * 0.24 + card.shiraIntroEaseV29 * 0.50)
                                        height: parent.height * (0.36 + index * 0.18 + card.shiraIntroEaseV29 * 0.34)
                                        radius: Math.min(width, height) / 2
                                        color: "transparent"
                                        border.width: 1
                                        border.color: Qt.rgba(cAc.r, cAc.g, cAc.b, Math.max(0, 0.34 - index * 0.08) * card.picIntro)
                                        rotation: animProg * 28 * (index % 2 === 0 ? 1 : -1)
                                        opacity: card.picIntro
                                        antialiasing: true
                                    }
                                }

                                Text {
                                    visible: activeCategory === 3 && thumbSrc(modelData, activeCategory) === ""
                                    anchors.centerIn: parent
                                    text: "MPV\nvideo"
                                    color: Qt.rgba(1, 1, 1, 0.42)
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    visible: activeCategory === 1 && thumbSrc(modelData, activeCategory) === ""
                                    anchors.centerIn: parent
                                    text: "ENGINE\npreview"
                                    color: Qt.rgba(1, 1, 1, 0.42)
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Rectangle {
                                    visible: selectorStyle === "varal"
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 30
                                    color: varalPaperColor
                                }

                                Rectangle {
                                    visible: selectorStyle !== "varal"
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 34
                                    gradient: Gradient {
                                        orientation: Gradient.Vertical
                                        GradientStop { position: 0; color: "transparent" }
                                        GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.78) }
                                    }
                                    Text {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.margins: 7
                                        text: thumbLabel(modelData, activeCategory)
                                        font.pixelSize: 9
                                        color: Qt.rgba(1, 1, 1, 0.78)
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    visible: selectorStyle === "varal"
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 8
                                    text: thumbLabel(modelData, activeCategory)
                                    font.pixelSize: 9
                                    color: Qt.rgba(0, 0, 0, 0.62)
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    visible: fav
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 6
                                    text: "♥"
                                    font.pixelSize: 12
                                    color: cAc
                                }

                                Rectangle {
                                    visible: selected && shimmerAnim.running
                                    anchors.fill: parent
                                    color: "transparent"
                                    clip: true
                                    Rectangle {
                                        width: parent.width * 0.55
                                        height: parent.height * 3
                                        rotation: -42
                                        x: shimmerProg * parent.width * 2.2 - width * 0.5
                                        y: -parent.height * 0.9
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: "transparent" }
                                            GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, 0.26) }
                                            GradientStop { position: 1.0; color: "transparent" }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var old = highlightIdx
                                setHighlight(activeCategory, index)
                                smoothCenterIndex(index, old)
                                doApply(modelData, activeCategory)
                            }
                        }
                    }

                    Text {
                        visible: wallList.count === 0
                        anchors.centerIn: parent
                        width: 260
                        text: _scanning ? "Carregando wallpapers..." : activeCategory === 0 ? "Nenhum favorito\nSpace para adicionar ♥" : "Nenhum wallpaper encontrado"
                        color: Qt.rgba(1, 1, 1, 0.26)
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }
                }
            }
        }


        Rectangle {
            id: cfgBtn
            z: 999
            width: 58
            height: 58
            radius: 22
            antialiasing: true
            visible: AppState.wallpaperOpen && !settingsOpen
            x: sw - width - 24
            y: sh - height - 24
            color: settingsOpen ? Qt.rgba(cAc.r, cAc.g, cAc.b, 0.18) : Qt.rgba(0.04, 0.06, 0.12, 0.86)
            border.color: settingsOpen ? cAc : Qt.rgba(cAc.r, cAc.g, cAc.b, 0.26)
            border.width: 1
            scale: settingsOpen ? 1.03 : (cfgBtnMouse.containsMouse ? 1.015 : 1.0)

            Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 170; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 170; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -5
                radius: 27
                color: Qt.rgba(cAc.r, cAc.g, cAc.b, settingsOpen ? 0.09 : 0.04)
                border.width: 1
                border.color: Qt.rgba(cAc.r, cAc.g, cAc.b, settingsOpen ? 0.22 : 0.08)
            }

            Column {
                anchors.centerIn: parent
                spacing: 0
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "S"; font.pixelSize: 16; font.bold: true; color: settingsOpen ? cAc : Qt.rgba(1,1,1,0.88) }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "SET"; font.pixelSize: 8; font.bold: true; color: settingsOpen ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.86) : Qt.rgba(1,1,1,0.42) }
            }

            MouseArea {
                id: cfgBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    shootActive = false
                    navActive = false
                    animProg = 0
                    settingsOpen = !settingsOpen
                }
            }
        }

        Item {
            z: 10000
            anchors.fill: parent
            visible: AppState.wallpaperOpen && (settingsOpen || opacity > 0.01)
            opacity: settingsOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, settingsBackdropOpacity)
                MouseArea { anchors.fill: parent; onClicked: returnToPreview() }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.010, 0.012, 0.022, 0.62)
                visible: settingsOpen
            }

            Rectangle {
                id: settingsPanel
                x: settingsPlace === "center" ? Math.round((parent.width - width) / 2) : parent.width - width - 24
                y: settingsPlace === "center" ? Math.round((parent.height - height) / 2) : parent.height - height - 24
                width: Math.min(sw - 96, 1160)
                height: Math.min(sh - 96, 820)
                radius: 24
                antialiasing: true
                clip: true
                color: Qt.rgba(0.018, 0.021, 0.036, settingsPanelOpacity)
                border.color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.18)
                border.width: 1
                scale: settingsOpen ? settingsPanelScale : 0.985
                opacity: settingsOpen ? 1 : 0
                transformOrigin: settingsPlace === "center" ? Item.Center : Item.BottomRight
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                MouseArea { anchors.fill: parent }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 23
                    color: Qt.rgba(1, 1, 1, 0.018)
                    border.width: 0
                }

                Rectangle {
                    id: settingsCloseBtnV3
                    z: 5000
                    width: 34
                    height: 34
                    radius: 17
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 14
                    anchors.rightMargin: 14
                    color: closeMouseV3.containsMouse ? Qt.rgba(cAc.r, cAc.g, cAc.b, 0.20) : Qt.rgba(1, 1, 1, 0.055)
                    border.width: 1
                    border.color: closeMouseV3.containsMouse ? cAc : Qt.rgba(1, 1, 1, 0.10)
                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.pixelSize: 17
                        font.bold: true
                        color: closeMouseV3.containsMouse ? cAc : Qt.rgba(1, 1, 1, 0.58)
                    }

                    MouseArea {
                        id: closeMouseV3
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: returnToPreview()
                    }
                }

                Rectangle {
                    id: epicOpenLine
                    z: 9999
                    width: Math.max(64, settingsPanel.width * 0.54)
                    height: 2
                    radius: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.95)
                    opacity: settingsOpen ? 0.0 : 0.95
                    visible: opacity > 0.01
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Row {
                    anchors.fill: parent

                    Rectangle {
                        width: settingsSidebarWidth
                        height: parent.height
                        radius: 0
                        color: Qt.rgba(0.026, 0.030, 0.052, 0.96)
                        border.width: 0

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8
                            Rectangle {
                                width: parent.width
                                height: 82
                                radius: 16
                                color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.085)
                                border.width: 1
                                border.color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.20)
                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 4
                                    Text { text: "ShiraOS"; font.pixelSize: 22; font.bold: true; color: Qt.rgba(1,1,1,0.94) }
                                    Text { text: "Wallpaper Studio"; font.pixelSize: 11; color: cAc; font.bold: true }
                                    Text { text: "Organizacao do seletor"; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.42) }
                                }
                            }
                            Item { height: 8 }

                            Text { text: "Essencial"; font.pixelSize: 9; font.bold: true; color: Qt.rgba(1,1,1,0.30) }
                            CatButton { label: "Layout"; tab: 0 }
                            CatButton { label: "Aparência"; tab: 2 }
                            CatButton { label: "Modelos"; tab: 3 }

                            Item { height: 4 }
                            Text { text: "Movimento"; font.pixelSize: 9; font.bold: true; color: Qt.rgba(1,1,1,0.30) }
                            CatButton { label: "Animações"; tab: 1 }
                            CatButton { label: "Entrada"; tab: 5 }
                            CatButton { label: "Presets visuais"; tab: 6 }

                            Item { height: 4 }
                            Text { text: "Sistema"; font.pixelSize: 9; font.bold: true; color: Qt.rgba(1,1,1,0.30) }
                            CatButton { label: "Tema & Pywal"; tab: 4 }
                            CatButton { label: "Adaptações"; tab: 8 }
                            CatButton { label: "Engine / MPV"; tab: 7 }

                            Item { height: 4 }
                            Text { text: "Biblioteca"; font.pixelSize: 9; font.bold: true; color: Qt.rgba(1,1,1,0.30) }
                            CatButton { label: "Ocultar wallpapers"; tab: 9 }

                            Item { height: 8 }
                            MiniButton { label: "Voltar ao preview"
                                onPress: returnToPreview() }
                            MiniButton { label: "Recarregar lista"
                                onPress: scanWallpapers(true) }
                            MiniButton { label: "Salvar agora"
                                onPress: saveSettingsNow() }
                            Item { height: 8 }
                            Text {
                                text: "wp_settings.json"
                                width: parent.width
                                wrapMode: Text.WordWrap
                                font.pixelSize: 9
                                color: Qt.rgba(1, 1, 1, 0.24)
                            }

                        }
                    }

                    Rectangle {
                        width: 1
                        height: parent.height
                        color: Qt.rgba(1, 1, 1, 0.07)
                    }

                    Flickable {
                        id: settingsFlick
                        width: parent.width - settingsSidebarWidth - 1
                        height: parent.height
                        clip: true
                        opacity: 0.55 + settingsTabAnim * 0.45
                        scale: 0.975 + settingsTabAnim * 0.025
                        contentHeight: cfgTab === 9 ? shiraExclusionPageV3.implicitHeight + 64 : settingsContent.implicitHeight + 64
                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                                
Column {
    id: shiraExclusionPageV3
    visible: cfgTab === 9
    opacity: cfgTab === 9 ? 1 : 0
    y: 0
    x: 28
    width: settingsFlick.width - 56
    spacing: 14

    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Text {
        text: "Ocultar wallpapers"
        font.pixelSize: 20
        font.bold: true
        color: cAc
    }

    Text {
        text: "Clique em um wallpaper para ocultar ou mostrar no seletor. O arquivo não será apagado."
        width: parent.width - 42
        wrapMode: Text.WordWrap
        font.pixelSize: 10
        color: Qt.rgba(1,1,1,0.42)
    }

    Row {
        spacing: 8

        Repeater {
            model: exclusionNames

            Rectangle {
                width: 116
                height: 36
                radius: 14
                color: exclusionTab === index ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.20) : Qt.rgba(1,1,1,0.055)
                border.width: 1
                border.color: exclusionTab === index ? cAc : Qt.rgba(1,1,1,0.08)

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    color: exclusionTab === index ? cAc : Qt.rgba(1,1,1,0.62)
                    font.pixelSize: 11
                    font.bold: exclusionTab === index
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: exclusionTab = index
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 10

        Repeater {
            model: exclusionTab === 0 ? staticWalls : exclusionTab === 1 ? liveWalls : engineWalls

            Rectangle {
                width: parent.width - 42
                height: 92
                radius: 20

                property int exCat: exclusionTab === 0 ? 2 : exclusionTab === 1 ? 3 : 1
                property string pth: exclusionTab === 2 ? modelData.path : modelData
                property string typ: exclusionTab === 0 ? "static" : exclusionTab === 1 ? "live" : "engine"
                property bool hidden: (hiddenWalls[typ] || []).indexOf(pth) >= 0

                color: hidden ? Qt.rgba(1,0.08,0.08,0.18) : Qt.rgba(1,1,1,0.055)
                border.width: 1
                border.color: hidden ? Qt.rgba(1,0.20,0.20,0.55) : Qt.rgba(1,1,1,0.08)

                Image {
                    width: 118
                    height: 72
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    source: thumbSrc(modelData, exCat)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                    mipmap: true
                    opacity: hidden ? 0.38 : 1.0
                }

                Rectangle {
                    width: 118
                    height: 72
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 14
                    color: "transparent"
                    border.width: hidden ? 2 : 1
                    border.color: hidden ? Qt.rgba(1,0.25,0.25,0.75) : Qt.rgba(1,1,1,0.12)
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 144
                    anchors.right: parent.right
                    anchors.rightMargin: 118
                    anchors.verticalCenter: parent.verticalCenter
                    text: pth.replace(/.*\//, "")
                    elide: Text.ElideRight
                    color: hidden ? Qt.rgba(1,0.55,0.55,0.95) : Qt.rgba(1,1,1,0.76)
                    font.pixelSize: 12
                    font.bold: hidden
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: hidden ? "OCULTO" : "VISÍVEL"
                    color: hidden ? Qt.rgba(1,0.42,0.42,1) : cAc
                    font.pixelSize: 10
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: toggleHiddenWall(typ, pth)
                }
            }
        }

        Text {
            visible: (exclusionTab === 0 ? staticWalls.length : exclusionTab === 1 ? liveWalls.length : engineWalls.length) === 0
            text: "Nenhum wallpaper nessa categoria. Clique em Recarregar lista."
            color: Qt.rgba(1,1,1,0.35)
            font.pixelSize: 11
        }
    }
}



Column {
                                    id: settingsContent
                                    visible: cfgTab !== 9
                                    opacity: cfgTab === 9 ? 0 : 1
                transform: Scale {
                    id: epicSettingsScale
                    origin.x: width / 2
                    origin.y: settingsPlace === "bottom" ? height : height / 2
                    xScale: 1.0
                    yScale: settingsOpen ? 1.0 : 0.035
                    Behavior on yScale {
                        NumberAnimation {
                            duration: 320
                            easing.type: Easing.OutExpo
                        }
                    }
                }
                                    y: 0
                                    x: 28
                                    width: parent.width - 56
                                    spacing: 14

                                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                                    

Column {
    id: motionSettingsTab
    visible: cfgTab === 1
    width: parent.width
    spacing: 14

Text { text: "Animações dos cards"; font.pixelSize: 18; font.bold: true; color: cAc }
                                    Text {
                                        text: "Controle a cascata, velocidade e intensidade das animações internas do seletor."
                                        font.pixelSize: 10
                                        color: Qt.rgba(1,1,1,0.42)
                                        wrapMode: Text.Wrap
                                        width: parent.width
                                    }

                                    Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.08) }
                                    
                                    // SHIRA_MAX_ANIM_SETTINGS_V29_BEGIN
                                    Rectangle {
                                        width: parent.width
                                        height: 148
                                        radius: 18
                                        color: Qt.rgba(1, 1, 1, 0.045)
                                        border.width: 1
                                        border.color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.16)

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 10

                                            Text {
                                                text: "Animações reais dos cards"
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: cAc
                                            }

                                            Row {
                                                height: 32
                                                spacing: 10

                                                Rectangle {
                                                    width: 122
                                                    height: 30
                                                    radius: 15
                                                    color: shiraCardIntroEnabled ? Qt.rgba(cAc.r, cAc.g, cAc.b, 0.22) : Qt.rgba(1, 1, 1, 0.07)
                                                    border.width: 1
                                                    border.color: shiraCardIntroEnabled ? cAc : Qt.rgba(1, 1, 1, 0.12)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: shiraCardIntroEnabled ? "Cards: ON" : "Cards: OFF"
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                        color: shiraCardIntroEnabled ? cAc : Qt.rgba(1, 1, 1, 0.50)
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: {
                                                            shiraCardIntroEnabled = !shiraCardIntroEnabled
                                                            scheduleSave()
                                                        }
                                                    }
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "Abertura em cascata compatível com todos os modelos."
                                                    font.pixelSize: 10
                                                    color: Qt.rgba(1, 1, 1, 0.42)
                                                }
                                            }

                                            Row {
                                                height: 32
                                                spacing: 10

                                                Text {
                                                    width: 120
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "Velocidade geral"
                                                    font.pixelSize: 10
                                                    color: Qt.rgba(1, 1, 1, 0.62)
                                                }

                                                Rectangle {
                                                    width: 32; height: 28; radius: 12
                                                    color: Qt.rgba(1,1,1,0.07)
                                                    Text { anchors.centerIn: parent; text: "-"; color: cAc; font.pixelSize: 15 }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: {
                                                            shiraAnimStrength = Math.max(0.65, shiraAnimStrength - 0.10)
                                                            scheduleSave()
                                                        }
                                                    }
                                                }

                                                Text {
                                                    width: 54
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    horizontalAlignment: Text.AlignHCenter
                                                    text: Math.round(shiraAnimStrength * 100) + "%"
                                                    color: cAc
                                                    font.pixelSize: 10
                                                }

                                                Rectangle {
                                                    width: 32; height: 28; radius: 12
                                                    color: Qt.rgba(1,1,1,0.07)
                                                    Text { anchors.centerIn: parent; text: "+"; color: cAc; font.pixelSize: 15 }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: {
                                                            shiraAnimStrength = Math.min(1.75, shiraAnimStrength + 0.10)
                                                            scheduleSave()
                                                        }
                                                    }
                                                }
                                            }

                                            Row {
                                                height: 32
                                                spacing: 10

                                                Text {
                                                    width: 120
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "Cascata"
                                                    font.pixelSize: 10
                                                    color: Qt.rgba(1, 1, 1, 0.62)
                                                }

                                                Rectangle {
                                                    width: 32; height: 28; radius: 12
                                                    color: Qt.rgba(1,1,1,0.07)
                                                    Text { anchors.centerIn: parent; text: "-"; color: cAc; font.pixelSize: 15 }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: {
                                                            shiraCardIntroStagger = Math.max(0.015, shiraCardIntroStagger - 0.010)
                                                            scheduleSave()
                                                        }
                                                    }
                                                }

                                                Text {
                                                    width: 54
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    horizontalAlignment: Text.AlignHCenter
                                                    text: Math.round(shiraCardIntroStagger * 1000) + "ms"
                                                    color: cAc
                                                    font.pixelSize: 10
                                                }

                                                Rectangle {
                                                    width: 32; height: 28; radius: 12
                                                    color: Qt.rgba(1,1,1,0.07)
                                                    Text { anchors.centerIn: parent; text: "+"; color: cAc; font.pixelSize: 15 }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: {
                                                            shiraCardIntroStagger = Math.min(0.14, shiraCardIntroStagger + 0.010)
                                                            scheduleSave()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    // SHIRA_MAX_ANIM_SETTINGS_V29_END

                                    Text { text: "A abertura do painel agora fica na aba Entrada. Aqui ficam apenas as animações dos cards para evitar opções repetidas."; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.38); wrapMode: Text.Wrap; width: parent.width }
                                    Text {
                                        text: "Use valores menores para um seletor mais discreto, ou aumente a força para um movimento mais vivo."
                                        font.pixelSize: 10
                                        color: Qt.rgba(1,1,1,0.34)
                                        wrapMode: Text.Wrap
                                        width: parent.width
                                    }

                                    Item { height: 4 }
                                }


                                // RESTORED SETTINGS TABS v6
                                Column {
                                    id: positionSettingsTab
                                    visible: cfgTab === 0
                                    width: parent.width
                                    spacing: 12

                                    Text { text: "Layout"; font.pixelSize: 13; font.bold: true; color: cAc }
                                    Text { text: "Controle onde o seletor e a janela de settings aparecem."; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.42); wrapMode: Text.Wrap; width: parent.width }

                                    Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.08) }

                                    Text { text: "Janela de settings"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1,1,1,0.72) }
                                    Row {
                                        spacing: 8
                                        Repeater {
                                            model: [{k:"center",l:"Meio"}, {k:"bottom",l:"Abaixo"}]
                                            delegate: Rectangle {
                                                property bool act: settingsPlace === modelData.k
                                                width: 112
                                                height: 36
                                                radius: 18
                                                antialiasing: true
                                                color: act ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.22) : Qt.rgba(1,1,1,0.055)
                                                border.color: act ? cAc : Qt.rgba(1,1,1,0.08)
                                                border.width: 1
                                                Text { anchors.centerIn: parent; text: modelData.l; font.pixelSize: 11; color: act ? cAc : Qt.rgba(1,1,1,0.58) }
                                                MouseArea { anchors.fill: parent; onClicked: { settingsPlace = modelData.k; scheduleSave() } }
                                            }
                                        }
                                    }

                                    Text { text: "Posição do seletor"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1,1,1,0.72); topPadding: 8 }
                                    Flow {
                                        width: parent.width
                                        spacing: 8

                                        Repeater {
                                            model: [
                                                {k:"bottom", l:"Baixo"},
                                                {k:"top",    l:"Cima"},
                                                {k:"left",   l:"Esquerda"},
                                                {k:"right",  l:"Direita"}
                                            ]

                                            delegate: Rectangle {
                                                property bool act: panelPosition === modelData.k
                                                width: 116
                                                height: 36
                                                radius: 18
                                                antialiasing: true
                                                color: act ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.22) : Qt.rgba(1,1,1,0.055)
                                                border.color: act ? cAc : Qt.rgba(1,1,1,0.08)
                                                border.width: 1
                                                Text { anchors.centerIn: parent; text: modelData.l; font.pixelSize: 11; color: act ? cAc : Qt.rgba(1,1,1,0.58) }
                                                MouseArea { anchors.fill: parent; onClicked: { panelPosition = modelData.k; scheduleSave() } }
                                            }
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.08) }

                                    Row {
                                        width: parent.width
                                        height: 44
                                        spacing: 10
                                        Text { width: 160; anchors.verticalCenter: parent.verticalCenter; text: "Tamanho da barra"; color: Qt.rgba(1,1,1,0.62); font.pixelSize: 11 }
                                        Rectangle { width: 36; height: 30; radius: 12; color: Qt.rgba(1,1,1,0.07); Text { anchors.centerIn: parent; text: "-"; color: cAc; font.pixelSize: 16 } MouseArea { anchors.fill: parent; onClicked: { panelThick = Math.max(120, panelThick - 10); scheduleSave() } } }
                                        Text { width: 70; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: Math.round(panelThick) + "px"; color: cAc; font.pixelSize: 11 }
                                        Rectangle { width: 36; height: 30; radius: 12; color: Qt.rgba(1,1,1,0.07); Text { anchors.centerIn: parent; text: "+"; color: cAc; font.pixelSize: 16 } MouseArea { anchors.fill: parent; onClicked: { panelThick = Math.min(420, panelThick + 10); scheduleSave() } } }
                                    }

                                    Row {
                                        width: parent.width
                                        height: 44
                                        spacing: 10
                                        Text { width: 160; anchors.verticalCenter: parent.verticalCenter; text: "Largura/alcance"; color: Qt.rgba(1,1,1,0.62); font.pixelSize: 11 }
                                        Rectangle { width: 36; height: 30; radius: 12; color: Qt.rgba(1,1,1,0.07); Text { anchors.centerIn: parent; text: "-"; color: cAc; font.pixelSize: 16 } MouseArea { anchors.fill: parent; onClicked: { panelSpan = Math.max(0.35, panelSpan - 0.04); scheduleSave() } } }
                                        Text { width: 70; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: Math.round(panelSpan * 100) + "%"; color: cAc; font.pixelSize: 11 }
                                        Rectangle { width: 36; height: 30; radius: 12; color: Qt.rgba(1,1,1,0.07); Text { anchors.centerIn: parent; text: "+"; color: cAc; font.pixelSize: 16 } MouseArea { anchors.fill: parent; onClicked: { panelSpan = Math.min(1.0, panelSpan + 0.04); scheduleSave() } } }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 46
                                        radius: 16
                                        color: fillEdges ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.18) : Qt.rgba(1,1,1,0.05)
                                        border.color: fillEdges ? cAc : Qt.rgba(1,1,1,0.07)
                                        border.width: 1
                                        Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "Preencher até as bordas"; color: Qt.rgba(1,1,1,0.65); font.pixelSize: 11 }
                                        Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: fillEdges ? "ON" : "OFF"; color: fillEdges ? cAc : Qt.rgba(1,1,1,0.35); font.pixelSize: 11; font.bold: true }
                                        MouseArea { anchors.fill: parent; onClicked: { fillEdges = !fillEdges; scheduleSave() } }
                                    }
                                }

                                Column {
                                    id: openingSettingsTab
                                    visible: cfgTab === 5
                                    width: parent.width
                                    spacing: 14

                                    Text { text: "Entrada do seletor"; font.pixelSize: 18; font.bold: true; color: cAc }
                                    Text { text: "Escolha apenas como o painel aparece ao abrir. As animações internas dos cards ficam na aba Animações."; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.42); wrapMode: Text.Wrap; width: parent.width }

                                    Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.08) }

                                    Grid {
                                        id: openPresetGrid
                                        columns: 3
                                        columnSpacing: 8
                                        rowSpacing: 8
                                        width: parent.width

                                        Repeater {
                                            model: [
                                                {k:"slide",  l:"Slide",  d:"entra da borda"},
                                                {k:"soft",   l:"Soft",   d:"leve e limpo"},
                                                {k:"scale",  l:"Scale",  d:"cresce suave"},
                                                {k:"bounce", l:"Bounce", d:"elástico"},
                                                {k:"wave",   l:"Wave",   d:"onda suave"},
                                                {k:"flip",   l:"Flip",   d:"giro curto"},
                                                {k:"float",  l:"Float",  d:"flutua"},
                                                {k:"ritual", l:"Ritual", d:"círculos e pulso"},
                                                {k:"portal", l:"Portal", d:"anel radial"},
                                                {k:"cascade",l:"Cascade",d:"varredura lenta"},
                                                {k:"cinema", l:"Cinema", d:"dramático"},
                                                {k:"bloom",  l:"Bloom",  d:"abre com brilho"},
                                                {k:"iris",   l:"Iris",   d:"abre do centro"},
                                                {k:"unfold", l:"Unfold", d:"desdobra"}
                                            ]

                                            delegate: Rectangle {
                                                property bool act: openStyle === modelData.k
                                                property real p: 0

                                                width: (openPresetGrid.width - 16) / 3
                                                height: 98
                                                radius: 14
                                                antialiasing: true
                                                color: act ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.18) : Qt.rgba(1,1,1,0.040)
                                                border.color: act ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.88) : Qt.rgba(1,1,1,0.070)
                                                border.width: 1

                                                SequentialAnimation on p {
                                                    loops: Animation.Infinite
                                                    NumberAnimation { from: 0; to: 1; duration: 980; easing.type: Easing.InOutCubic }
                                                    PauseAnimation { duration: 220 }
                                                }

                                                Rectangle {
                                                    id: miniStage
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.top: parent.top
                                                    anchors.margins: 9
                                                    height: 48
                                                    radius: 12
                                                    clip: true
                                                    color: Qt.rgba(0.02,0.03,0.07,0.48)

                                                    Rectangle {
                                                        width: modelData.k === "cinema" ? 46 : 42
                                                        height: 14
                                                        radius: 7
                                                        color: cAc
                                                        opacity: modelData.k === "fade" ? (0.18 + Math.sin(p*3.14159)*0.80) : 0.88
                                                        x: modelData.k === "slide" ? (-45 + p*(miniStage.width+6))
                                                           : modelData.k === "unfold" ? (miniStage.width/2 - width/2 - (1-p)*22)
                                                           : miniStage.width/2 - width/2
                                                        y: modelData.k === "cinema" ? 25 - (1-p)*16 : 24 - height/2
                                                        scale: modelData.k === "scale" || modelData.k === "bounce" ? (0.65 + p*0.35)
                                                            : modelData.k === "bloom" ? (0.45 + p*0.55)
                                                            : modelData.k === "iris" ? Math.max(0.12, p)
                                                            : modelData.k === "wave" ? (0.76 + p*0.24 + Math.sin(p*3.14159)*0.05)
                                                            : modelData.k === "flip" ? (0.72 + p*0.28)
                                                            : modelData.k === "float" ? (0.90 + p*0.10)
                                                            : modelData.k === "ritual" ? (0.54 + p*0.46 + Math.sin(p*9.42477)*0.03)
                                                            : modelData.k === "portal" ? (0.24 + p*0.76)
                                                            : modelData.k === "cascade" ? (0.68 + p*0.32)
                                                            : 1.0
                                                        rotation: modelData.k === "bounce" ? Math.sin(p*6.28318)*3.0
                                                            : modelData.k === "wave" ? Math.sin(p*6.28318)*4.0
                                                            : modelData.k === "flip" ? (1-p)*-12
                                                            : modelData.k === "ritual" ? Math.sin((1-p)*12.56636)*6
                                                            : modelData.k === "cascade" ? (1-p)*-5
                                                            : 0
                                                        antialiasing: true
                                                    }

                                                    Repeater {
                                                        model: modelData.k === "ritual" || modelData.k === "portal" ? 2 : 0

                                                        delegate: Rectangle {
                                                            anchors.centerIn: parent
                                                            width: parent.width * (0.22 + p * (0.56 + index * 0.18))
                                                            height: parent.height * (0.24 + p * (0.42 + index * 0.14))
                                                            radius: Math.min(width, height) / 2
                                                            color: "transparent"
                                                            border.width: 1
                                                            border.color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.26 - index * 0.08)
                                                            opacity: Math.max(0, 1 - p * 0.48)
                                                        }
                                                    }

                                                    Repeater {
                                                        model: modelData.k === "cascade" ? 3 : 0

                                                        delegate: Rectangle {
                                                            width: parent.width * (0.22 + index * 0.16)
                                                            height: 2
                                                            radius: 1
                                                            x: parent.width * (0.18 + index * 0.22) - width / 2
                                                            y: parent.height * (0.24 + index * 0.18)
                                                            color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.26 - index * 0.04)
                                                            opacity: Math.sin(p * 3.14159)
                                                        }
                                                    }

                                                    Rectangle {
                                                        visible: modelData.k === "bloom" || modelData.k === "iris" || modelData.k === "cinema"
                                                        anchors.centerIn: parent
                                                        width: parent.width * (0.15 + p*0.85)
                                                        height: parent.height * (0.20 + p*0.80)
                                                        radius: Math.min(width,height)/2
                                                        color: Qt.rgba(cAc.r,cAc.g,cAc.b,0.10)
                                                        border.color: Qt.rgba(cAc.r,cAc.g,cAc.b,0.20)
                                                        border.width: 1
                                                    }
                                                }

                                                Text { anchors.left: parent.left; anchors.leftMargin: 10; anchors.bottom: parent.bottom; anchors.bottomMargin: 25; text: modelData.l; color: act ? cAc : Qt.rgba(1,1,1,0.74); font.pixelSize: 11; font.bold: act }
                                                Text { anchors.left: parent.left; anchors.leftMargin: 10; anchors.right: parent.right; anchors.rightMargin: 10; anchors.bottom: parent.bottom; anchors.bottomMargin: 9; text: modelData.d; color: Qt.rgba(1,1,1,0.36); font.pixelSize: 9; elide: Text.ElideRight }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        openStyle = modelData.k
                                                        scheduleSave()
                                                        Qt.callLater(function() { replayOpenAnimation() })
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.08) }

                                    Text { text: "Navegação lateral"; font.pixelSize: 12; font.bold: true; color: Qt.rgba(1,1,1,0.76) }
                                    Text { text: "Define a sensação ao mudar de wallpaper com setas, clique ou categorias."; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.40); wrapMode: Text.Wrap; width: parent.width }

                                    Flow {
                                        width: parent.width
                                        spacing: 8

                                        Repeater {
                                            model: [
                                                {k:"glide",   l:"Glide",   d:"desliza suave"},
                                                {k:"elastic", l:"Elastic", d:"puxa e solta"},
                                                {k:"fichas",  l:"Fichas",  d:"gruda e comprime"},
                                                {k:"trail",   l:"Trail",   d:"rastro lateral"},
                                                {k:"shooter", l:"Shooter", d:"partículas"},
                                                {k:"snap",    l:"Snap",    d:"rápido"},
                                                {k:"fade",    l:"Fade",    d:"discreto"},
                                                {k:"none",    l:"None",    d:"sem efeito"}
                                            ]

                                            delegate: Rectangle {
                                                property bool act: moveStyle === modelData.k
                                                width: 128
                                                height: 54
                                                radius: 14
                                                antialiasing: true
                                                color: act ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.18) : Qt.rgba(1,1,1,0.040)
                                                border.color: act ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.86) : Qt.rgba(1,1,1,0.070)
                                                border.width: 1

                                                Column {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 12
                                                    anchors.rightMargin: 12
                                                    anchors.topMargin: 9
                                                    spacing: 4
                                                    Text { text: modelData.l; color: act ? cAc : Qt.rgba(1,1,1,0.74); font.pixelSize: 11; font.bold: act }
                                                    Text { text: modelData.d; color: Qt.rgba(1,1,1,0.36); font.pixelSize: 9; elide: Text.ElideRight; width: parent.width }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        moveStyle = modelData.k
                                                        scheduleSave()
                                                        Qt.callLater(function() { smoothCenterIndex(highlightIdx) })
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.08) }
                                    Text { text: "Dica: Wave, Float e Bloom são mais satisfatórios; Soft e Fade são mais leves."; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.42); wrapMode: Text.Wrap; width: parent.width }
                                }

                                Column {
                                    id: appearanceSettingsTab
                                    visible: cfgTab === 2
                                    width: parent.width
                                    spacing: 12

                                    Text { text: "Aparência"; font.pixelSize: 12; font.bold: true; color: cAc }

                                    Row {
                                        width: parent.width
                                        height: 42
                                        spacing: 10
                                        Text { width: 160; anchors.verticalCenter: parent.verticalCenter; text: "Raio dos cards"; color: Qt.rgba(1,1,1,0.62); font.pixelSize: 11 }
                                        Rectangle { width: 36; height: 30; radius: 12; color: Qt.rgba(1,1,1,0.07); Text { anchors.centerIn: parent; text: "-"; color: cAc; font.pixelSize: 16 } MouseArea { anchors.fill: parent; onClicked: { thumbRadius = Math.max(0, thumbRadius - 2); scheduleSave() } } }
                                        Text { width: 70; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: thumbRadius + "px"; color: cAc; font.pixelSize: 11 }
                                        Rectangle { width: 36; height: 30; radius: 12; color: Qt.rgba(1,1,1,0.07); Text { anchors.centerIn: parent; text: "+"; color: cAc; font.pixelSize: 16 } MouseArea { anchors.fill: parent; onClicked: { thumbRadius = Math.min(40, thumbRadius + 2); scheduleSave() } } }
                                    }

                                    Row {
                                        width: parent.width
                                        height: 42
                                        spacing: 10
                                        Text { width: 160; anchors.verticalCenter: parent.verticalCenter; text: "Opacidade"; color: Qt.rgba(1,1,1,0.62); font.pixelSize: 11 }
                                        Rectangle { width: 36; height: 30; radius: 12; color: Qt.rgba(1,1,1,0.07); Text { anchors.centerIn: parent; text: "-"; color: cAc; font.pixelSize: 16 } MouseArea { anchors.fill: parent; onClicked: { pillOpacity = Math.max(0.15, pillOpacity - 0.05); scheduleSave() } } }
                                        Text { width: 70; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: Math.round(pillOpacity * 100) + "%"; color: cAc; font.pixelSize: 11 }
                                        Rectangle { width: 36; height: 30; radius: 12; color: Qt.rgba(1,1,1,0.07); Text { anchors.centerIn: parent; text: "+"; color: cAc; font.pixelSize: 16 } MouseArea { anchors.fill: parent; onClicked: { pillOpacity = Math.min(1, pillOpacity + 0.05); scheduleSave() } } }
                                    }

                                    Text { text: "Transição do wallpaper estático"; font.pixelSize: 11; color: Qt.rgba(1,1,1,0.62) }
                                    Flow {
                                        width: parent.width
                                        spacing: 8
                                        Repeater {
                                            model: ["grow", "fade", "wipe", "outer", "simple"]
                                            delegate: Rectangle {
                                                width: 96
                                                height: 34
                                                radius: 17
                                                color: swwwTransition === modelData ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.20) : Qt.rgba(1,1,1,0.055)
                                                border.color: swwwTransition === modelData ? cAc : Qt.rgba(1,1,1,0.07)
                                                border.width: 1
                                                Text { anchors.centerIn: parent; text: modelData; color: swwwTransition === modelData ? cAc : Qt.rgba(1,1,1,0.58); font.pixelSize: 10 }
                                                MouseArea { anchors.fill: parent; onClicked: { swwwTransition = modelData; scheduleSave() } }
                                            }
                                        }
                                    }
                                }

                                Column {
                                    id: modelSettingsTab
                                    visible: cfgTab === 3
                                    width: parent.width
                                    spacing: 12

                                    Text { text: "Modelo do seletor"; font.pixelSize: 12; font.bold: true; color: cAc }

                                    Flow {
                                        width: parent.width
                                        spacing: 8
                                        Repeater {
                                            model: [
                                                {k:"pill", l:"Pill"},
                                                {k:"cards", l:"Cards"},
                                                {k:"skew", l:"Inclinado"},
                                                {k:"spotlight", l:"Spotlight"},
                                                {k:"varal", l:"Varal"}
                                            ]
                                            delegate: Rectangle {
                                                width: 112
                                                height: 36
                                                radius: 18
                                                color: selectorStyle === modelData.k ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.22) : Qt.rgba(1,1,1,0.055)
                                                border.color: selectorStyle === modelData.k ? cAc : Qt.rgba(1,1,1,0.07)
                                                border.width: 1
                                                Text { anchors.centerIn: parent; text: modelData.l; color: selectorStyle === modelData.k ? cAc : Qt.rgba(1,1,1,0.58); font.pixelSize: 10 }
                                                MouseArea { anchors.fill: parent; onClicked: applyModelPreset(modelData.k) }
                                            }
                                        }
                                    }

                                    Text { text: "Inclinado"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1,1,1,0.70) }


                                    // SHIRA_SKEW_REAL_CONTROLS_V7_BEGIN
                                    Rectangle {
                                        width: parent.width
                                        height: 246
                                        radius: 18
                                        color: Qt.rgba(1, 1, 1, 0.045)
                                        border.width: 1
                                        border.color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.18)

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 10

                                            Text {
                                                text: "Inclinado: forma real"
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: cAc
                                            }

                                            SliderRow {
                                                title: "Altura"
                                                value: skewShapeHeight
                                                from: 0.40
                                                to: 3.20
                                                step: 0.01
                                                valueText: Math.round(skewShapeHeight * 100) + "%"
                                                onSetValue: function(v) {
                                                    skewShapeHeight = v
                                                    scheduleSave()
                                                    Qt.callLater(function() { smoothCenterIndex(highlightIdx) })
                                                }
                                            }

                                            SliderRow {
                                                title: "Separação dos wallpapers"
                                                value: skewItemSpacing
                                                from: -320
                                                to: 240
                                                step: 1
                                                valueText: Math.round(skewItemSpacing) + "px"
                                                onSetValue: function(v) {
                                                    skewItemSpacing = v
                                                    scheduleSave()
                                                    Qt.callLater(function() { smoothCenterIndex(highlightIdx) })
                                                }
                                            }

                                            

                                            // SHIRA_SKEW_SEPARATOR_MANUAL_V8_BEGIN
                                            Rectangle {
                                                width: parent.width
                                                height: 46
                                                radius: 14
                                                color: Qt.rgba(1, 1, 1, 0.045)
                                                border.width: 1
                                                border.color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.14)

                                                Row {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 12
                                                    anchors.rightMargin: 12
                                                    spacing: 10

                                                    Text {
                                                        width: parent.width - 150
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "Separação manual"
                                                        color: Qt.rgba(1, 1, 1, 0.68)
                                                        font.pixelSize: 11
                                                        elide: Text.ElideRight
                                                    }

                                                    Rectangle {
                                                        width: 96
                                                        height: 30
                                                        radius: 11
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        color: Qt.rgba(0, 0, 0, 0.22)
                                                        border.width: 1
                                                        border.color: sepInput.activeFocus ? cAc : Qt.rgba(1, 1, 1, 0.12)

                                                        TextInput {
                                                            id: sepInput
                                                            anchors.fill: parent
                                                            anchors.leftMargin: 10
                                                            anchors.rightMargin: 10
                                                            verticalAlignment: TextInput.AlignVCenter
                                                            horizontalAlignment: TextInput.AlignHCenter
                                                            color: cAc
                                                            selectedTextColor: "black"
                                                            selectionColor: cAc
                                                            font.pixelSize: 12
                                                            font.bold: true
                                                            inputMethodHints: Qt.ImhFormattedNumbersOnly

                                                            Component.onCompleted: text = Math.round(skewItemSpacing).toString()

                                                            function commitManual() {
                                                                var n = Number(text)
                                                                if (!isNaN(n)) {
                                                                    n = Math.max(-500, Math.min(300, Math.round(n)))
                                                                    skewItemSpacing = n
                                                                    text = Math.round(skewItemSpacing).toString()
                                                                    scheduleSave()
                                                                    Qt.callLater(function() { smoothCenterIndex(highlightIdx) })
                                                                } else {
                                                                    text = Math.round(skewItemSpacing).toString()
                                                                }
                                                            }

                                                            onAccepted: {
                                                                commitManual()
                                                                focus = false
                                                            }

                                                            onActiveFocusChanged: {
                                                                if (activeFocus) {
                                                                    selectAll()
                                                                } else {
                                                                    commitManual()
                                                                }
                                                            }

                                                            Connections {
                                                                target: win
                                                                function onSkewItemSpacingChanged() {
                                                                    if (!sepInput.activeFocus)
                                                                        sepInput.text = Math.round(skewItemSpacing).toString()
                                                                }
                                                            }
                                                        }
                                                    }

                                                    Text {
                                                        width: 24
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "px"
                                                        color: Qt.rgba(1, 1, 1, 0.42)
                                                        font.pixelSize: 10
                                                    }
                                                }
                                            }
                                            // SHIRA_SKEW_SEPARATOR_MANUAL_V8_END
SliderRow {
                                                title: "Escala"
                                                value: skewCardScale
                                                from: 0.35
                                                to: 2.30
                                                step: 0.01
                                                valueText: Math.round(skewCardScale * 100) + "%"
                                                onSetValue: function(v) {
                                                    skewCardScale = v
                                                    scheduleSave()
                                                    Qt.callLater(function() { smoothCenterIndex(highlightIdx) })
                                                }
                                            }
                                        }
                                    }
                                    // SHIRA_SKEW_REAL_CONTROLS_V7_END

                                    Text { text: "Varal"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1,1,1,0.70) }
                                    Row { width: parent.width; height: 38; spacing: 10
                                        Text { width: 160; anchors.verticalCenter: parent.verticalCenter; text: "Fotos visíveis"; color: Qt.rgba(1,1,1,0.55); font.pixelSize: 11 }
                                        Rectangle { width: 34; height: 28; radius: 11; color: Qt.rgba(1,1,1,0.07); Text { anchors.centerIn: parent; text: "-"; color: cAc } MouseArea { anchors.fill: parent; onClicked: { varalCount = Math.max(3, varalCount - 1); scheduleSave() } } }
                                        Text { width: 70; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: ""+varalCount; color: cAc; font.pixelSize: 11 }
                                        Rectangle { width: 34; height: 28; radius: 11; color: Qt.rgba(1,1,1,0.07); Text { anchors.centerIn: parent; text: "+"; color: cAc } MouseArea { anchors.fill: parent; onClicked: { varalCount = Math.min(12, varalCount + 1); scheduleSave() } } }
                                    }
                                    Row { width: parent.width; height: 38; spacing: 10
                                        Text { width: 160; anchors.verticalCenter: parent.verticalCenter; text: "Balanço"; color: Qt.rgba(1,1,1,0.55); font.pixelSize: 11 }
                                        Rectangle { width: 34; height: 28; radius: 11; color: Qt.rgba(1,1,1,0.07); Text { anchors.centerIn: parent; text: "-"; color: cAc } MouseArea { anchors.fill: parent; onClicked: { varalSwingAngle = Math.max(0, varalSwingAngle - 0.4); scheduleSave() } } }
                                        Text { width: 70; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: varalSwingAngle.toFixed(1)+"°"; color: cAc; font.pixelSize: 11 }
                                        Rectangle { width: 34; height: 28; radius: 11; color: Qt.rgba(1,1,1,0.07); Text { anchors.centerIn: parent; text: "+"; color: cAc } MouseArea { anchors.fill: parent; onClicked: { varalSwingAngle = Math.min(10, varalSwingAngle + 0.4); scheduleSave() } } }
                                    }
                                }

                                Column {
                                    id: presetsSettingsTab
                                    visible: cfgTab === 6
                                    width: parent.width
                                    spacing: 12

                                    Text { text: "Presets rápidos"; font.pixelSize: 12; font.bold: true; color: cAc }
                                    Text { text: "Atalhos para testar estilos sem mexer controle por controle."; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.40); wrapMode: Text.Wrap; width: parent.width }

                                    Flow {
                                        width: parent.width
                                        spacing: 10

                                        Rectangle {
                                            width: 150; height: 76; radius: 18; color: Qt.rgba(1,1,1,0.055); border.color: Qt.rgba(1,1,1,0.08); border.width: 1
                                            Column { anchors.centerIn: parent; spacing: 4; Text { text: "Clean"; color: cAc; font.bold: true; font.pixelSize: 12 } Text { text: "pill + fade"; color: Qt.rgba(1,1,1,0.45); font.pixelSize: 10 } }
                                            MouseArea { anchors.fill: parent; onClicked: { selectorStyle="pill"; openStyle="soft"; moveStyle="fade"; fillEdges=false; scheduleSave() } }
                                        }
                                        Rectangle {
                                            width: 150; height: 76; radius: 18; color: Qt.rgba(1,1,1,0.055); border.color: Qt.rgba(1,1,1,0.08); border.width: 1
                                            Column { anchors.centerIn: parent; spacing: 4; Text { text: "Cinema"; color: cAc; font.bold: true; font.pixelSize: 12 } Text { text: "skew + bloom"; color: Qt.rgba(1,1,1,0.45); font.pixelSize: 10 } }
                                            MouseArea { anchors.fill: parent; onClicked: { selectorStyle="skew"; openStyle="bloom"; moveStyle="shooter"; fillEdges=true; skewHeight=0.62; skewPictureHeight=1.0; scheduleSave() } }
                                        }
                                        Rectangle {
                                            width: 150; height: 76; radius: 18; color: Qt.rgba(1,1,1,0.055); border.color: Qt.rgba(1,1,1,0.08); border.width: 1
                                            Column { anchors.centerIn: parent; spacing: 4; Text { text: "Varal"; color: cAc; font.bold: true; font.pixelSize: 12 } Text { text: "pendurado"; color: Qt.rgba(1,1,1,0.45); font.pixelSize: 10 } }
                                            MouseArea { anchors.fill: parent; onClicked: { selectorStyle="varal"; openStyle="bounce"; moveStyle="shooter"; varalCount=6; varalSwing=true; scheduleSave() } }
                                        }
                                    }
                                }

                                Column {
                                    id: themeSettingsTab
                                    visible: cfgTab === 4
                                    width: parent.width
                                    spacing: 12

                                    Text { text: "Tema e pywal"; font.pixelSize: 12; font.bold: true; color: cAc }
                                    Text { text: "A cor atual é salva pelo cache do pywal. Use 'Salvar agora' para persistir suas configurações do seletor."; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.42); wrapMode: Text.Wrap; width: parent.width }

                                    Rectangle {
                                        width: parent.width
                                        height: 70
                                        radius: 18
                                        color: Qt.rgba(cAc.r,cAc.g,cAc.b,0.16)
                                        border.color: cAc
                                        border.width: 1

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 14

                                            Rectangle { width: 42; height: 42; radius: 14; color: cAc; anchors.verticalCenter: parent.verticalCenter }
                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 3
                                                Text { text: "Accent atual"; color: Qt.rgba(1,1,1,0.75); font.pixelSize: 12; font.bold: true }
                                                Text { text: "Extraído pelo wal/matugen e reaplicado na UI"; color: Qt.rgba(1,1,1,0.38); font.pixelSize: 10 }
                                            }
                                        }
                                    }
                                }


                                Column {
                                    id: engineSettingsTab
                                    visible: cfgTab === 7
                                    width: parent.width
                                    spacing: 12

                                    Text { text: "Wallpaper Engine"; font.pixelSize: 12; font.bold: true; color: cAc }
                                    Text { text: "Controle como o seletor lida com preview e tema dos wallpapers do Engine."; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.42); wrapMode: Text.Wrap; width: parent.width }

                                    Rectangle {
                                        width: parent.width; height: 46; radius: 16
                                        color: engineShowPreview ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.18) : Qt.rgba(1,1,1,0.05)
                                        border.color: engineShowPreview ? cAc : Qt.rgba(1,1,1,0.07); border.width: 1
                                        Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "Mostrar previews"; color: Qt.rgba(1,1,1,0.65); font.pixelSize: 11 }
                                        Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: engineShowPreview ? "ON" : "OFF"; color: engineShowPreview ? cAc : Qt.rgba(1,1,1,0.35); font.pixelSize: 11; font.bold: true }
                                        MouseArea { anchors.fill: parent; onClicked: { engineShowPreview = !engineShowPreview; scheduleSave() } }
                                    }
                                    Rectangle {
                                        width: parent.width; height: 46; radius: 16
                                        color: engineApplyPreview ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.18) : Qt.rgba(1,1,1,0.05)
                                        border.color: engineApplyPreview ? cAc : Qt.rgba(1,1,1,0.07); border.width: 1
                                        Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "Aplicar preview antes de carregar"; color: Qt.rgba(1,1,1,0.65); font.pixelSize: 11 }
                                        Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: engineApplyPreview ? "ON" : "OFF"; color: engineApplyPreview ? cAc : Qt.rgba(1,1,1,0.35); font.pixelSize: 11; font.bold: true }
                                        MouseArea { anchors.fill: parent; onClicked: { engineApplyPreview = !engineApplyPreview; scheduleSave() } }
                                    }
                                    Rectangle {
                                        width: parent.width; height: 46; radius: 16
                                        color: enginePreviewTheme ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.18) : Qt.rgba(1,1,1,0.05)
                                        border.color: enginePreviewTheme ? cAc : Qt.rgba(1,1,1,0.07); border.width: 1
                                        Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "Pywal pelo preview"; color: Qt.rgba(1,1,1,0.65); font.pixelSize: 11 }
                                        Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: enginePreviewTheme ? "ON" : "OFF"; color: enginePreviewTheme ? cAc : Qt.rgba(1,1,1,0.35); font.pixelSize: 11; font.bold: true }
                                        MouseArea { anchors.fill: parent; onClicked: { enginePreviewTheme = !enginePreviewTheme; scheduleSave() } }
                                    }
                                }


                                // SHIRA_ADAPTACOES_TAB_V2_BEGIN
                                Column {
                                    visible: opacity > 0.01
                                    opacity: cfgTab === 8 ? 1 : 0
                                    y: cfgTab === 8 ? 0 : 16
                                    width: parent.width
                                    spacing: 12

                                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                                    Text { text: "Adaptações"; font.pixelSize: 18; font.bold: true; color: cAc }
                                    Text {
                                        text: "Integrações extras para adaptar outros shells e temas ao ShiraOS."
                                        font.pixelSize: 10
                                        color: Qt.rgba(1,1,1,0.42)
                                        wrapMode: Text.Wrap
                                        width: parent.width
                                    }

                                    Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.08) }

                                    Rectangle {
                                        width: parent.width
                                        height: 176
                                        radius: 18
                                        color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.08)
                                        border.width: 1
                                        border.color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.22)

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 10

                                            Text {
                                                text: "Caelestia Shell"
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: cAc
                                            }

                                            Text {
                                                text: "Cria e aplica um scheme shiraos-pywal usando o cache do pywal/pywal16. Auto aplicar tenta reaplicar quando o accent muda."
                                                width: parent.width
                                                wrapMode: Text.Wrap
                                                font.pixelSize: 10
                                                color: Qt.rgba(1, 1, 1, 0.42)
                                            }

                                            ToggleRow {
                                                title: "Ativar integração"
                                                active: caelestiaPywalEnabled
                                                onToggle: {
                                                    caelestiaPywalEnabled = !caelestiaPywalEnabled
                                                    scheduleSave()
                                                    if (caelestiaPywalEnabled)
                                                        applyCaelestiaPywalScheme(true)
                                                }
                                            }

                                            ToggleRow {
                                                title: "Auto aplicar ao mudar accent"
                                                active: caelestiaPywalAutoApply
                                                onToggle: {
                                                    caelestiaPywalAutoApply = !caelestiaPywalAutoApply
                                                    scheduleSave()
                                                }
                                            }

                                            Row {
                                                width: parent.width
                                                height: 34
                                                spacing: 8

                                                SelectButton {
                                                    label: "Aplicar agora"
                                                    active: false
                                                    onPress: applyCaelestiaPywalScheme(true)
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "log: /tmp/shiraos-caelestia-pywal.log"
                                                    color: Qt.rgba(1,1,1,0.32)
                                                    font.pixelSize: 9
                                                }
                                            }
                                        }
                                    }
                                }
                                // SHIRA_ADAPTACOES_TAB_V2_END


component CatButton: Rectangle {
                    property string label: "Tab"
                    property int tab: 0
                    property bool active: cfgTab === tab
                    property bool hovered: area.containsMouse

                    width: parent ? parent.width : (settingsSidebarWidth - 28)
                    height: 40
                    radius: 12
                    antialiasing: true
                    color: active ? Qt.rgba(cAc.r, cAc.g, cAc.b, 0.20) : hovered ? Qt.rgba(1,1,1,0.070) : Qt.rgba(1,1,1,0.030)
                    border.color: active ? Qt.rgba(cAc.r, cAc.g, cAc.b, 0.82) : hovered ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.055)
                    border.width: 1
                    scale: active ? 1.0 : (hovered ? 1.006 : 0.992)

                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Rectangle {
                        visible: active
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4
                        height: 24
                        radius: 2
                        color: cAc
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: label
                        color: active ? Qt.rgba(1,1,1,0.96) : Qt.rgba(1,1,1,0.62)
                        font.pixelSize: 11
                        font.bold: active
                    }

                    Rectangle {
                        visible: active
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: cAc
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (tab < 0) {
                                returnToPreview()
                            } else {
                                cfgTab = tab
                            }
                        }
                    }
                }

                component SliderRow: Rectangle {
                    id: sliderRoot
                    property string title: "Setting"
                    property real value: 0.5
                    property real from: 0.0
                    property real to: 1.0
                    property real step: 0.01
                    property string valueText: ""
                    signal setValue(real v)

                    width: parent ? parent.width : 420
                    height: 58
                    radius: 14
                    color: Qt.rgba(1,1,1,0.055)
                    border.color: Qt.rgba(1,1,1,0.09)
                    border.width: 1

                    function clamp(v) {
                        return Math.max(from, Math.min(to, v))
                    }

                    function snapped(v) {
                        var safeStep = Math.max(step, 0.0001)
                        return from + Math.round((clamp(v) - from) / safeStep) * safeStep
                    }

                    property real progress: (to - from) <= 0.0001 ? 0 : (clamp(value) - from) / (to - from)

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 7

                        Row {
                            width: parent.width
                            height: 16

                            Text {
                                width: parent.width - 92
                                anchors.verticalCenter: parent.verticalCenter
                                text: title
                                color: Qt.rgba(1,1,1,0.72)
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            Text {
                                width: 84
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                text: valueText
                                color: cAc
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        Rectangle {
                            id: sliderTrack
                            width: parent.width
                            height: 14
                            radius: 7
                            color: Qt.rgba(1,1,1,0.09)
                            border.color: Qt.rgba(1,1,1,0.06)
                            border.width: 1

                            Rectangle {
                                width: Math.max(12, sliderRoot.progress * sliderTrack.width)
                                height: parent.height
                                radius: parent.radius
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.34) }
                                    GradientStop { position: 1.0; color: Qt.rgba(cAc.r, cAc.g, cAc.b, 0.82) }
                                }
                            }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                y: -2
                                x: Math.max(0, Math.min(sliderTrack.width - width, sliderRoot.progress * (sliderTrack.width - width)))
                                color: Qt.rgba(0.98,0.99,1.0,0.98)
                                border.color: cAc
                                border.width: 1
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true

                                function commit(mx) {
                                    var pct = Math.max(0, Math.min(1, mx / Math.max(1, width)))
                                    var nv = sliderRoot.from + (sliderRoot.to - sliderRoot.from) * pct
                                    sliderRoot.setValue(sliderRoot.snapped(nv))
                                }

                                onPressed: commit(mouseX)
                                onPositionChanged: if (pressed) commit(mouseX)
                            }
                        }
                    }
                }

component SelectButton: Rectangle {
                    property string label: ""
                    property bool active: false
                    signal press()
                    width: Math.max(82, txt.implicitWidth + 22)
                    height: 34
                    radius: 17
                    color: active ? Qt.rgba(cAc.r, cAc.g, cAc.b, 0.24) : mouse.containsMouse ? Qt.rgba(cAc.r, cAc.g, cAc.b, 0.12) : Qt.rgba(1,1,1,0.055)
                    border.color: active ? cAc : Qt.rgba(1,1,1,0.08)
                    border.width: 1
                    Text { id: txt; anchors.centerIn: parent; text: label; color: active ? cAc : Qt.rgba(1,1,1,0.62); font.pixelSize: 10 }
                    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: press() }
                }

                component StepRow: Rectangle {
                    property string title: "Setting"
                    property string valueText: ""
                    signal minus()
                    signal plus()
                    width: settingsContent.width
                    height: 44
                    radius: 13
                    color: Qt.rgba(1,1,1,0.045)
                    border.color: Qt.rgba(1,1,1,0.07)
                    border.width: 1
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8
                        Text { width: parent.width - 158; anchors.verticalCenter: parent.verticalCenter; text: title; color: Qt.rgba(1,1,1,0.68); font.pixelSize: 11; elide: Text.ElideRight }
                        Text { width: 72; anchors.verticalCenter: parent.verticalCenter; text: valueText; color: cAc; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                        MiniRound { label: "-"
                                onPress: minus() }
                        MiniRound { label: "+"
                                onPress: plus() }
                    }
                }

                component ToggleRow: Rectangle {
                    property string title: "Toggle"
                    property bool active: false
                    signal toggle()
                    width: settingsContent.width
                    height: 44
                    radius: 13
                    color: Qt.rgba(1,1,1,0.045)
                    border.color: Qt.rgba(1,1,1,0.07)
                    border.width: 1
                    Text { anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: title; color: Qt.rgba(1,1,1,0.68); font.pixelSize: 11 }
                    Rectangle {
                        width: 52
                        height: 24
                        radius: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: active ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.26) : Qt.rgba(1,1,1,0.10)
                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            x: active ? 30 : 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: active ? cAc : Qt.rgba(1,1,1,0.45)
                            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                        MouseArea { anchors.fill: parent; onClicked: toggle() }
                    }
                }

                component MiniRound: Rectangle {
                    property string label: "+"
                    signal press()
                    width: 30
                    height: 26
                    radius: 9
                    color: marea.containsMouse ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.20) : Qt.rgba(1,1,1,0.08)
                    Text { anchors.centerIn: parent; text: label; color: Qt.rgba(1,1,1,0.78); font.pixelSize: 12 }
                    MouseArea { id: marea; anchors.fill: parent; hoverEnabled: true; onClicked: press() }
                }

                component MiniButton: Rectangle {
                    property string label: "Button"
                    signal press()
                    width: parent ? parent.width : 180
                    height: 30
                    radius: 11
                    color: ma.containsMouse ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.16) : Qt.rgba(1,1,1,0.045)
                    border.color: ma.containsMouse ? Qt.rgba(cAc.r,cAc.g,cAc.b,0.22) : Qt.rgba(1,1,1,0.07)
                    border.width: 1
                    Text { anchors.centerIn: parent; text: label; color: Qt.rgba(1,1,1,0.62); font.pixelSize: 10 }
                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: press() }
                }
            }
        }

        Repeater {
            model: (!settingsOpen && (moveStyle === "shooter" || moveStyle === "trail") && shootActive) ? 14 : 0
            delegate: Rectangle {
                property real prog: Math.max(0, Math.min(1, shootProg - index * 0.055))
                property real fade: Math.pow(1 - prog, 2.0)
                width: 5 + 5 * (1 - prog)
                height: width
                radius: width / 2
                color: cAc
                opacity: fade * 0.75
                x: shootFX + (shootTX - shootFX) * prog - width / 2 + (index % 4 - 1.5) * 10 * (1 - prog)
                y: shootFY + (shootTY - shootFY) * prog - height / 2 + (Math.floor(index / 4) - 1) * 10 * (1 - prog)
            }
        }
    }
}
}


}

}
