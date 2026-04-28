import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import ShiraOS

PanelWindow {
    id: win
    WlrLayershell.namespace:     "shiraos-wallpaper"
    WlrLayershell.layer:         WlrLayer.Overlay
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

    // ── Core state ──────────────────────────────────────────────────────────
    property bool   settingsOpen:   false
    property bool   isVertical:     panelPosition==="right"||panelPosition==="left"
    property real   panelThick:     210
    property real   panelSpan:      0.82
    property int    thumbRadius:    14
    property real   pillOpacity:    0.60
    property int    cfgTab:         0
    property string swwwTransition: "grow"
    property string panelPosition:  "bottom"
    property string selectorBg:     ""
    property bool   useSelectorBg:  false
    property string openStyle:      "slide"
    property string moveStyle:      "shooter"
    property bool   _loaded:        false
    property string selectorStyle:  "pill"
    property real   skewHeight:     0.45
    property real   skewWidth:      1.78
    property real   skewOverlap:    0.22
    // varal settings
    property bool   varalShowPegs:  true
    property string varalLineColor: "#cc4444"
    property int    varalCount:     5
    property real   varalScale:     1.0

    // ── Screen geometry ─────────────────────────────────────────────────────
    property real sw: screen ? screen.width  : 1920
    property real sh: screen ? screen.height : 1080
    property real pillW: {
        if(selectorStyle==="skew") return sw
        if(isVertical) return panelThick
        return (screen?screen.width:1920)*panelSpan
    }
    property real pillH: {
        if(selectorStyle==="skew") return Math.round(sh*skewHeight)
        if(selectorStyle==="varal") return Math.round(sh*0.50)
        if(isVertical) return (screen?screen.height:1080)*panelSpan
        return panelThick
    }
    property real pillX: {
        if(selectorStyle==="skew") return 0
        if(panelPosition==="right") return sw-pillW-20
        if(panelPosition==="left") return 20
        return (sw-pillW)/2
    }
    property real pillY: {
        if(selectorStyle==="skew") return (sh-pillH)/2
        if(panelPosition==="top") return 20
        if(panelPosition==="bottom") return sh-pillH-20
        return (sh-pillH)/2
    }

    // ── Categories ──────────────────────────────────────────────────────────
    property int    activeCategory: 2
    readonly property var catNames: ["\u2665","Engine","Static","MPV"]
    property var    staticWalls:    []
    property var    engineWalls:    []
    property var    liveWalls:      []
    property var    favorites:      []
    property var    selectorBgList: []
    property int    staticHl: 0; property int engineHl: 0
    property int    liveHl:   0; property int favHl:    0
    property var    favSet: ({})
    onFavoritesChanged: {
        var s = {}
        for(var i=0;i<favorites.length;i++) s[favorites[i].applyPath]=true
        win.favSet=s
    }
    property var currentWalls: {
        if(activeCategory===0) return favorites
        if(activeCategory===1) return engineWalls
        if(activeCategory===2) return staticWalls
        return liveWalls
    }
    property int highlightIdx: {
        if(activeCategory===0) return favHl
        if(activeCategory===1) return engineHl
        if(activeCategory===2) return staticHl
        return liveHl
    }

    // ── Theme colors ────────────────────────────────────────────────────────
    property color gc1: AppState.accentPill   || Qt.rgba(0.04,0.05,0.15,0.70)
    property color gc2: AppState.accentDark   || Qt.rgba(0.02,0.02,0.10,0.98)
    property color cAc: AppState.accentColor  || Qt.rgba(0.40,0.65,1.00,1.00)
    property color cRm: AppState.accentBorder || Qt.rgba(0.25,0.40,0.80,0.22)

    // ── Open/close animations ────────────────────────────────────────────────
    property real animProg: 0
    NumberAnimation { id:openAnim;  target:win; property:"animProg"; from:0; to:1; duration:340; easing.type:Easing.OutCubic }
    NumberAnimation { id:closeAnim; target:win; property:"animProg"; from:1; to:0; duration:260; easing.type:Easing.InCubic }
    property real shimmerProg: -0.5
    SequentialAnimation {
        id:shimmerAnim
        NumberAnimation{target:win;property:"shimmerProg";from:-0.5;to:1.5;duration:800;easing.type:Easing.InOutSine}
        ScriptAction{script:win.shimmerProg=-0.5}
    }
    property real shootProg: 0; property bool shootActive: false
    property real shootFX: 0; property real shootFY: 0
    property real shootTX: 0; property real shootTY: 0
    SequentialAnimation {
        id:shootAnim
        NumberAnimation{target:win;property:"shootProg";from:0;to:1;duration:600;easing.type:Easing.OutExpo}
        ScriptAction{script:win.shootActive=false}
    }
    onPanelPositionChanged: {
        if(win.moveStyle==="none") return
        win.shootFX=win.pillX+win.pillW/2; win.shootFY=win.pillY+win.pillH/2
        Qt.callLater(function(){
            win.shootTX=win.pillX+win.pillW/2; win.shootTY=win.pillY+win.pillH/2
            win.shootProg=0; win.shootActive=true; shootAnim.restart()
        })
    }

    // ── Persistence ─────────────────────────────────────────────────────────
    Process {
        id:loadProc; running:false
        command:["bash","-c","cat ~/.config/quickshell/shiraos/wp_settings.json 2>/dev/null || echo '{}'"]
        stdout:SplitParser{onRead:function(raw){
            var d=raw.trim(); if(!d||d==="{}") return
            try{
                var s=JSON.parse(d)
                var keys=["panelThick","panelSpan","thumbRadius","pillOpacity","swwwTransition",
                          "panelPosition","useSelectorBg","selectorBg","openStyle","moveStyle",
                          "selectorStyle","skewHeight","skewWidth","skewOverlap",
                          "varalShowPegs","varalLineColor","varalCount","varalScale"]
                for(var i=0;i<keys.length;i++){if(typeof s[keys[i]]!=="undefined") win[keys[i]]=s[keys[i]]}
                if(s.favorites&&s.favorites.length) win.favorites=s.favorites
            }catch(e){}
        }}
    }
    Process{id:saveProc;running:false}
    function saveSettings(){
        var data={
            panelThick:win.panelThick, panelSpan:win.panelSpan,
            thumbRadius:win.thumbRadius, pillOpacity:win.pillOpacity,
            swwwTransition:win.swwwTransition, panelPosition:win.panelPosition,
            useSelectorBg:win.useSelectorBg, selectorBg:win.selectorBg,
            openStyle:win.openStyle, moveStyle:win.moveStyle,
            selectorStyle:win.selectorStyle,
            skewHeight:win.skewHeight, skewWidth:win.skewWidth, skewOverlap:win.skewOverlap,
            varalShowPegs:win.varalShowPegs, varalLineColor:win.varalLineColor,
            varalCount:win.varalCount, varalScale:win.varalScale,
            favorites:win.favorites
        }
        var j=JSON.stringify(data)
        saveProc.command=["python3","-c",
            "import sys,os; p=os.path.expanduser('~/.config/quickshell/shiraos/wp_settings.json'); "+
            "os.makedirs(os.path.dirname(p),exist_ok=True); open(p,'w').write(sys.argv[1])",j]
        saveProc.running=false; saveProc.running=true
    }

    // ── pywal16 theming ──────────────────────────────────────────────────────
    Process {
        id:walProc; running:false
        property string wallPath:""
        command:["bash","-c",
            "WALL=\""+walProc.wallPath+"\"; [ -z \"$WALL\" ] && exit 0; "+
            "mkdir -p ~/.cache/shiraos; echo \"$WALL\" > ~/.cache/shiraos/current_wallpaper; "+
            "wal -i \"$WALL\" -n -q 2>/dev/null; "+
            "python3 /tmp/qs_wal_extract.py; echo _DONE"]
        stdout:SplitParser{onRead:function(line){
            var t=line.trim()
            if(!t||t.length<3) return
            function parseHex(h){
                h=h.replace("#","")
                return{r:parseInt(h.substr(0,2),16)/255,g:parseInt(h.substr(2,2),16)/255,b:parseInt(h.substr(4,2),16)/255}
            }
            if(t.startsWith("PRIMARY=")){
                var cc=parseHex(t.replace("PRIMARY=",""))
                win.cAc=Qt.rgba(cc.r,cc.g,cc.b,1.0)
                win.cRm=Qt.rgba(cc.r,cc.g,cc.b,0.20)
                AppState.accentColor=win.cAc; AppState.accentPill=Qt.rgba(cc.r,cc.g,cc.b,0.28)
                AppState.accentBorder=win.cRm
                kittyProc.primary=t.replace("PRIMARY=","")
            } else if(t.startsWith("BG=")){
                var cb=parseHex(t.replace("BG=",""))
                win.gc2=Qt.rgba(cb.r,cb.g,cb.b,0.95); AppState.accentDark=win.gc2
                win.gc1=Qt.rgba(cb.r*1.8,cb.g*1.8,cb.b*1.8,0.55)
                kittyProc.walBg=t.replace("BG=","")
                hyprBorderProc.col=t.replace("BG=","").replace("#","")
                hyprBorderProc.running=false; hyprBorderProc.running=true
            } else if(t.startsWith("FG=")){
                kittyProc.walFg=t.replace("FG=","")
            } else if(t.startsWith("SURFACE=")){
                kittyProc.walSurface=t.replace("SURFACE=","")
            } else if(t.startsWith("SECONDARY=")){
                kittyProc.walSecondary=t.replace("SECONDARY=","")
            } else if(t==="_DONE"){
                kittyProc.running=false; kittyProc.running=true
            }
        }}
    }
    Process{id:hyprBorderProc;running:false;property string col:""
        command:["bash","-c","hyprctl keyword general:col.active_border \"rgb("+hyprBorderProc.col+")\" 2>/dev/null||true"]}
    Process{
        id:kittyProc;running:false
        property string primary:"8888FF"; property string walBg:"0E1010"
        property string walFg:"E0E0E0"; property string walSurface:"1A1A1A"; property string walSecondary:"88AAFF"
        command:["python3","/tmp/qs_kitty_theme.py",
            kittyProc.primary,kittyProc.walBg,kittyProc.walSurface,kittyProc.walFg,kittyProc.walSecondary]
    }

    function runTheme(wallPath){
        if(!wallPath) return
        walProc.wallPath=wallPath; walProc.running=false; walProc.running=true
    }

    // ── Fallback color extractor (ImageMagick) ───────────────────────────────
    Process {
        id:colorProc; running:false; property int lc:0; property string img:""
        command:["bash","-c",
            "w=\""+colorProc.img+"\"; [ -z \"$w\" ] && exit 0; "+
            "convert \"$w\" -resize 50x50! +dither -colors 2 -format \"%[fx:r] %[fx:g] %[fx:b]\\n\" info: 2>/dev/null|head -2"]
        stdout:SplitParser{onRead:function(data){
            var p=data.trim().split(" "); if(p.length<3) return
            var r=Math.min(parseFloat(p[0])*0.8,0.45),g=Math.min(parseFloat(p[1])*0.8,0.45),b=Math.min(parseFloat(p[2])*0.8,0.45)
            if(colorProc.lc===0){win.gc1=Qt.rgba(r,g,b,0.55);AppState.accentColor=Qt.rgba(r,g,b,1.0);win.cAc=Qt.rgba(r,g,b,1.0)}
            else{win.gc2=Qt.rgba(r,g,b,0.95)}
            colorProc.lc++
        }}
        onRunningChanged:if(running) lc=0
    }

    // ── File discovery (staggered with Timer) ────────────────────────────────
    Process{id:findStatic;running:false
        command:["bash","-c","find ~/Pictures/Wallpapers/static -maxdepth 1 -type f 2>/dev/null|sort"]
        stdout:SplitParser{onRead:function(data){var f=data.trim();if(f){var a=win.staticWalls.slice();a.push(f);win.staticWalls=a}}}}
    Process{id:findEngine;running:false
        command:["bash","-c",
            "BASE=$HOME/.steam/steam/steamapps/workshop/content/431960; [ -d $BASE ]||exit 0; "+
            "for d in $BASE/*/; do id=$(basename $d); prev=$(ls $d/preview.* 2>/dev/null|head -1); printf '%s|%s\\n' $id $prev; done"]
        stdout:SplitParser{onRead:function(data){
            var l=data.trim();if(!l)return
            var p=l.split("|"); if(p.length<1)return
            var a=win.engineWalls.slice(); a.push({path:p[0],preview:p.length>1?p[1]:""})
            win.engineWalls=a
        }}}
    Process{id:findLive;running:false
        command:["bash","-c","find ~/Pictures/Wallpapers/live -maxdepth 1 -type f 2>/dev/null|sort"]
        stdout:SplitParser{onRead:function(data){var f=data.trim();if(f){var a=win.liveWalls.slice();a.push(f);win.liveWalls=a}}}}
    Process{id:findBgList;running:false
        command:["bash","-c","find ~/Pictures/Wallpapers/WallpaperSelector -maxdepth 1 -type f 2>/dev/null|sort"]
        stdout:SplitParser{onRead:function(data){var f=data.trim();if(f){var a=win.selectorBgList.slice();a.push(f);win.selectorBgList=a}}}}
    // stagger timers to avoid lag on open
    Timer{id:t1;interval:80; repeat:false; onTriggered:findStatic.running=true}
    Timer{id:t2;interval:160;repeat:false; onTriggered:findEngine.running=true}
    Timer{id:t3;interval:240;repeat:false; onTriggered:findLive.running=true}
    Timer{id:t4;interval:320;repeat:false; onTriggered:findBgList.running=true}

    // ── Apply wallpaper ──────────────────────────────────────────────────────
    Process{id:applyStatic;running:false}
    Process{id:applyEngine;running:false}
    Process{id:applyLive;  running:false}
    Process{id:killEngine; running:false; command:["bash","-c","pkill -f linux-wallpaperengine 2>/dev/null;true"]}
    Process{id:killLive;   running:false; command:["bash","-c","pkill -f mpvpaper 2>/dev/null;true"]}

    function doApply(item,cat){
        if(cat===2){
            var sp=typeof item==="string"?item:(item.path||"")
            killEngine.running=false;killEngine.running=true;killLive.running=false;killLive.running=true
            applyStatic.command=["awww","img",sp,"--transition-type",win.swwwTransition,"--transition-duration","1","--transition-fps","60"]
            applyStatic.running=false;applyStatic.running=true; win.runTheme(sp)
        } else if(cat===1){
            killLive.running=false;killLive.running=true
            if(item.preview){
                applyStatic.command=["awww","img",item.preview,"--transition-type","fade","--transition-duration","0.4"]
                applyStatic.running=false;applyStatic.running=true
                win.runTheme(item.preview)
            }
            applyEngine.command=["linux-wallpaperengine","--screen-root","eDP-1","--bg",item.path]
            applyEngine.running=false;applyEngine.running=true
        } else if(cat===3){
            var lp=typeof item==="string"?item:(item.path||"")
            killEngine.running=false;killEngine.running=true
            applyLive.command=["mpvpaper","-o","no-audio loop","eDP-1",lp]
            applyLive.running=false;applyLive.running=true
        } else if(cat===0){
            var tp=item.applyType||"static"
            if(tp==="static"){
                killEngine.running=false;killEngine.running=true;killLive.running=false;killLive.running=true
                applyStatic.command=["awww","img",item.applyPath,"--transition-type",win.swwwTransition,"--transition-duration","1","--transition-fps","60"]
                applyStatic.running=false;applyStatic.running=true; win.runTheme(item.applyPath)
            } else if(tp==="engine"){
                killLive.running=false;killLive.running=true
                if(item.previewPath){applyStatic.command=["awww","img",item.previewPath,"--transition-type","fade","--transition-duration","0.4"];applyStatic.running=false;applyStatic.running=true;win.runTheme(item.previewPath)}
                applyEngine.command=["linux-wallpaperengine","--screen-root","eDP-1","--bg",item.applyPath]
                applyEngine.running=false;applyEngine.running=true
            } else{
                killEngine.running=false;killEngine.running=true
                applyLive.command=["mpvpaper","-o","no-audio loop","eDP-1",item.applyPath]
                applyLive.running=false;applyLive.running=true
            }
        }
        shimmerAnim.restart()
    }
    function applyCurrentWall(){
        var walls=win.currentWalls; var idx=win.highlightIdx
        if(idx<0||idx>=walls.length) return
        doApply(walls[idx],win.activeCategory)
    }
    function navigate(dir){
        var n=Math.max(0,Math.min(win.highlightIdx+dir,win.currentWalls.length-1))
        if(activeCategory===0)      win.favHl=n
        else if(activeCategory===1) win.engineHl=n
        else if(activeCategory===2) win.staticHl=n
        else                        win.liveHl=n
        wallList.scrollToIdx(n)
    }
    function toggleFav(){
        var walls=win.currentWalls; var idx=win.highlightIdx
        if(activeCategory===0){var f0=win.favorites.slice();f0.splice(idx,1);win.favorites=f0;return}
        var item=walls[idx]; var obj
        if(activeCategory===2){var sp2=typeof item==="string"?item:(item.path||"");obj={dispPath:sp2,applyType:"static",applyPath:sp2,previewPath:sp2}}
        else if(activeCategory===1){obj={dispPath:item.preview||"",applyType:"engine",applyPath:item.path||"",previewPath:item.preview||""}}
        else{var lp2=typeof item==="string"?item:(item.path||"");obj={dispPath:lp2,applyType:"live",applyPath:lp2,previewPath:lp2}}
        var f2=win.favorites.slice(); var ex=false
        for(var i=0;i<f2.length;i++){if(f2[i].applyPath===obj.applyPath){f2.splice(i,1);ex=true;break}}
        if(!ex) f2.push(obj)
        win.favorites=f2
    }
    function thumbSrc(item,cat){
        if(cat===0){var dp=(item.dispPath||item.previewPath||""); return dp?"file://"+dp:""}
        if(cat===2) return "file://"+(typeof item==="string"?item:(item.path||""))
        if(cat===1) return item.preview?"file://"+item.preview:""
        var b=(typeof item==="string"?item:(item.path||"")).replace(/.*\//,"").replace(/\.[^.]+$/,"")
        return "file:///home/shira/.cache/qs_mpv_thumb_"+b+".jpg"
    }
    function thumbLabel(item,cat){
        if(cat===0){var p=item.applyPath||"";return p.replace(/.*\//,"").replace(/\.[^.]+$/,"")}
        var s=typeof item==="string"?item:(item.path||"");return s.replace(/.*\//,"").replace(/\.[^.]+$/,"")
    }

    Connections{
        target:AppState
        function onWallpaperOpenChanged(){
            if(AppState.wallpaperOpen){
                if(!win._loaded){win._loaded=true;loadProc.running=true}
                win.staticWalls=[]; win.engineWalls=[]; win.liveWalls=[]; win.selectorBgList=[]
                t1.restart(); t2.restart(); t3.restart(); t4.restart()
                win.settingsOpen=false; openAnim.start()
                Qt.callLater(function(){keyItem.forceActiveFocus()})
            } else {
                win.saveSettings(); win.settingsOpen=false; closeAnim.start()
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // UI ROOT
    // ════════════════════════════════════════════════════════════════════════
    Item {
        id: uiRoot
        anchors.fill: parent

        // ── PILL (wallpaper selector) ──────────────────────────────────────
        Item {
            id: pill
            x: win.pillX; y: win.pillY; width: win.pillW; height: win.pillH
            visible: !win.settingsOpen
            opacity: win.animProg
            Behavior on x      { NumberAnimation{duration:420;easing.type:Easing.OutCubic} }
            Behavior on y      { NumberAnimation{duration:420;easing.type:Easing.OutCubic} }
            Behavior on width  { NumberAnimation{duration:420;easing.type:Easing.OutCubic} }
            Behavior on height { NumberAnimation{duration:420;easing.type:Easing.OutCubic} }
            transform: [
                Translate{
                    x:win.openStyle==="slide"?(win.panelPosition==="right"?(1-win.animProg)*70:win.panelPosition==="left"?-(1-win.animProg)*70:0):0
                    y:win.openStyle==="slide"?(win.panelPosition==="bottom"?(1-win.animProg)*70:win.panelPosition==="top"?-(1-win.animProg)*70:0):0
                },
                Scale{
                    xScale:(win.openStyle==="scale"||win.openStyle==="bounce")?(0.82+0.18*win.animProg):1.0
                    yScale:xScale; origin.x:win.pillW/2; origin.y:win.pillH/2
                }
            ]

            // Background
            Rectangle {
                anchors.fill: parent
                radius: (win.selectorStyle==="cards"||win.selectorStyle==="skew"||win.selectorStyle==="varal") ? 12 : Math.min(width,height)/2
                color: "transparent"; antialiasing: true; clip: true
                Rectangle{anchors.fill:parent;radius:parent.radius
                    color:(win.selectorStyle==="skew"||win.selectorStyle==="varal")?"transparent":Qt.rgba(win.gc1.r,win.gc1.g,win.gc1.b,win.pillOpacity)}
                Image{anchors.fill:parent;source:(win.useSelectorBg&&win.selectorBg)?"file://"+win.selectorBg:""
                    fillMode:Image.PreserveAspectCrop;opacity:0.65;visible:status===Image.Ready}
                Rectangle{anchors.fill:parent;radius:parent.radius;color:"transparent"
                    border.color:(win.selectorStyle==="skew"||win.selectorStyle==="varal")?"transparent":win.cRm;border.width:1}
            }

            // Keyboard handler
            Item{id:keyItem;anchors.fill:parent;focus:true
                Keys.onEscapePressed:AppState.toggleWallpaper()
                Keys.onReturnPressed:win.applyCurrentWall()
                Keys.onEnterPressed:win.applyCurrentWall()
                Keys.onUpPressed:{
                    if(!win.isVertical){win.activeCategory=(win.activeCategory+win.catNames.length-1)%win.catNames.length;wallList.scrollToIdx(win.highlightIdx)}
                    else win.navigate(-1)
                }
                Keys.onDownPressed:{
                    if(!win.isVertical){win.activeCategory=(win.activeCategory+1)%win.catNames.length;wallList.scrollToIdx(win.highlightIdx)}
                    else win.navigate(1)
                }
                Keys.onLeftPressed:{
                    if(!win.isVertical) win.navigate(-1)
                    else{win.activeCategory=(win.activeCategory+win.catNames.length-1)%win.catNames.length;wallList.scrollToIdx(win.highlightIdx)}
                }
                Keys.onRightPressed:{
                    if(!win.isVertical) win.navigate(1)
                    else{win.activeCategory=(win.activeCategory+1)%win.catNames.length;wallList.scrollToIdx(win.highlightIdx)}
                }
                Keys.onPressed:function(event){if(event.key===Qt.Key_Space){win.toggleFav();event.accepted=true}}
            }

            // Category dots (vertical)
            Column{visible:!win.isVertical;anchors.left:parent.left;anchors.leftMargin:18
                anchors.verticalCenter:parent.verticalCenter;spacing:10
                Repeater{model:win.catNames;delegate:Item{width:30;height:30
                    property bool act:index===win.activeCategory
                    Text{visible:index===0;anchors.centerIn:parent;text:"\u2665";font.pixelSize:act?17:11
                        color:act?win.cAc:Qt.rgba(1,1,1,0.22);Behavior on color{ColorAnimation{duration:150}}}
                    Rectangle{visible:index!==0;anchors.centerIn:parent;width:act?20:6;height:6;radius:3
                        color:act?win.cAc:Qt.rgba(1,1,1,0.20)
                        Behavior on width{NumberAnimation{duration:160;easing.type:Easing.OutCubic}}
                        Behavior on color{ColorAnimation{duration:160}}}
                    MouseArea{anchors.fill:parent;onClicked:{win.activeCategory=index;wallList.scrollToIdx(win.highlightIdx)}}
                }}
            }
            // Category dots (horizontal)
            Row{visible:win.isVertical;anchors.top:parent.top;anchors.topMargin:18
                anchors.horizontalCenter:parent.horizontalCenter;spacing:10
                Repeater{model:win.catNames;delegate:Item{width:30;height:30
                    property bool act:index===win.activeCategory
                    Text{visible:index===0;anchors.centerIn:parent;text:"\u2665";font.pixelSize:act?17:11
                        color:act?win.cAc:Qt.rgba(1,1,1,0.22);Behavior on color{ColorAnimation{duration:150}}}
                    Rectangle{visible:index!==0;anchors.centerIn:parent;width:6;height:act?20:6;radius:3
                        color:act?win.cAc:Qt.rgba(1,1,1,0.20)
                        Behavior on height{NumberAnimation{duration:160;easing.type:Easing.OutCubic}}
                        Behavior on color{ColorAnimation{duration:160}}}
                    MouseArea{anchors.fill:parent;onClicked:{win.activeCategory=index;wallList.scrollToIdx(win.highlightIdx)}}
                }}
            }

            // ── VARAL MODEL ───────────────────────────────────────────────
            Item {
                id: varalModel
                anchors.fill: parent
                visible: win.selectorStyle === "varal"

                // Rope canvas
                Canvas {
                    id: ropeCanvas
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: parent.top; anchors.topMargin: 42
                    height: 28
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0,0,width,height)
                        ctx.beginPath()
                        ctx.moveTo(0, 8)
                        ctx.bezierCurveTo(width*0.25,14, width*0.75,14, width, 8)
                        ctx.strokeStyle = win.varalLineColor
                        ctx.lineWidth = 3.5
                        ctx.lineCap = "round"
                        ctx.stroke()
                    }
                    // Repaint when color changes
                    onWidthChanged: requestPaint()
                    Connections{target:win;function onVarialLineColorChanged(){ropeCanvas.requestPaint()}}
                }

                // Photos row
                Item {
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: ropeCanvas.bottom; anchors.topMargin: -8
                    anchors.bottom: parent.bottom
                    anchors.margins: 20

                    Repeater {
                        model: Math.min(win.varalCount, Math.max(1, win.currentWalls.length))
                        delegate: Item {
                            id: varalCard
                            property int midIdx: Math.floor(win.varalCount/2)
                            property int offset: index - midIdx
                            property int wallIdx: ((win.highlightIdx + offset) % Math.max(1,win.currentWalls.length) + Math.max(1,win.currentWalls.length)) % Math.max(1,win.currentWalls.length)
                            property bool isCurrent: index === midIdx

                            // Wind sway — each photo has different phase
                            property real windAngle: 0
                            SequentialAnimation on windAngle {
                                running: AppState.wallpaperOpen
                                loops: Animation.Infinite
                                NumberAnimation{to:2.5+index*0.4;duration:1800+index*350;easing.type:Easing.InOutSine}
                                NumberAnimation{to:-2.5-index*0.3;duration:1900+index*280;easing.type:Easing.InOutSine}
                            }

                            property real baseW: Math.min(parent.width/Math.max(1,win.varalCount) - 12, 160) * win.varalScale
                            property real baseH: baseW * 1.35
                            width: baseW; height: baseH + 32
                            // position evenly across the width
                            x: (parent.width - win.varalCount * (baseW + 12)) / 2 + index * (baseW + 12)
                            y: 0
                            transformOrigin: Item.Top
                            rotation: windAngle
                            Behavior on rotation{NumberAnimation{duration:200}}

                            scale: isCurrent ? 1.10 : 0.90
                            Behavior on scale{NumberAnimation{duration:200;easing.type:Easing.OutCubic}}
                            opacity: isCurrent ? 1.0 : 0.72

                            // Clothespin (pregador)
                            Item {
                                id: pegItem
                                visible: win.varalShowPegs
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: -18
                                width: 20; height: 30
                                // Outer peg body
                                Rectangle{x:3;y:0;width:14;height:20;radius:3;color:"#c8a065";antialiasing:true}
                                // Metal spring middle
                                Rectangle{x:0;y:10;width:20;height:4;radius:2;color:"#a07840";antialiasing:true}
                                // Bottom grip
                                Rectangle{x:5;y:20;width:5;height:10;radius:2;color:"#b89050"}
                                Rectangle{x:10;y:20;width:5;height:10;radius:2;color:"#b89050"}
                            }

                            // Polaroid frame
                            Rectangle {
                                anchors.left: parent.left; anchors.right: parent.right
                                anchors.top: parent.top; anchors.topMargin: 14
                                height: parent.baseH
                                color: "white"; radius: 2; antialiasing: true
                                layer.enabled: true
                                layer.effect: null

                                // Photo area
                                Image {
                                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                    anchors.margins: 6; anchors.bottomMargin: 22
                                    height: parent.height - 34
                                    fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                                    source: win.currentWalls.length > 0 ? win.thumbSrc(win.currentWalls[wallIdx], win.activeCategory) : ""
                                    opacity: status===Image.Ready?1:0
                                    Behavior on opacity{NumberAnimation{duration:200}}
                                }
                                // Label area
                                Text {
                                    anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width - 12
                                    font.pixelSize: 8; color: "#555"; horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: win.currentWalls.length > 0 ? win.thumbLabel(win.currentWalls[wallIdx], win.activeCategory) : ""
                                }
                                // Highlight border
                                Rectangle{anchors.fill:parent;radius:parent.radius;color:"transparent"
                                    border.color:varalCard.isCurrent?win.cAc:"transparent";border.width:2}
                            }

                            MouseArea{anchors.fill:parent;onClicked:{
                                if(activeCategory===0)      win.favHl=wallIdx
                                else if(activeCategory===1) win.engineHl=wallIdx
                                else if(activeCategory===2) win.staticHl=wallIdx
                                else                        win.liveHl=wallIdx
                                if(varalCard.isCurrent) win.applyCurrentWall()
                                else wallList.scrollToIdx(wallIdx)
                            }}
                        }
                    }
                }
            }

            // ── STANDARD LIST (pill / cards / skew / spotlight) ───────────
            Item {
                anchors.fill: parent
                anchors.leftMargin:  win.isVertical ? 6  : 50
                anchors.rightMargin: win.isVertical ? 6  : 46
                anchors.topMargin:   win.isVertical ? 56 : 5
                anchors.bottomMargin: 5
                clip: true
                visible: win.selectorStyle !== "varal"

                ListView {
                    id: wallList
                    anchors.fill: parent
                    orientation: win.isVertical ? ListView.Vertical : ListView.Horizontal
                    spacing: win.selectorStyle==="skew" ? -Math.round(wallList.height*win.skewOverlap) : 8
                    clip: true; cacheBuffer: 800
                    model: win.currentWalls; currentIndex: win.highlightIdx

                    function scrollToIdx(idx){
                        var stride=(win.isVertical?(win.panelThick*0.54):(win.pillH*1.56))+spacing
                        var dim=win.isVertical?height:width
                        var t=idx*stride-dim/2+stride/2
                        var maxC=win.isVertical?Math.max(0,contentHeight-height):Math.max(0,contentWidth-width)
                        if(win.isVertical){yA.to=Math.max(0,Math.min(t,maxC));yA.restart()}
                        else{xA.to=Math.max(0,Math.min(t,maxC));xA.restart()}
                    }
                    NumberAnimation on contentX{id:xA;duration:360;easing.type:Easing.OutCubic}
                    NumberAnimation on contentY{id:yA;duration:360;easing.type:Easing.OutCubic}

                    delegate: Item {
                        id: card
                        property bool isHl: index===win.highlightIdx
                        property bool isFav: win.isFav(modelData)
                        property real spotF: win.selectorStyle==="spotlight"?(index===0?1.35:0.80):1.0
                        property real cw: win.isVertical?wallList.width-10:(win.selectorStyle==="skew"?Math.round(wallList.height*win.skewWidth):Math.round(wallList.height*1.56*spotF))
                        property real ch: win.isVertical?Math.round(win.panelThick*0.52):wallList.height-10
                        width:  win.isVertical ? wallList.width : cw + 10
                        height: win.isVertical ? ch + 10 : wallList.height
                        scale:   win.selectorStyle==="skew"?1.0:(isHl?1.0:0.88)
                        opacity: win.selectorStyle==="skew"?1.0:(isHl?1.0:0.50)
                        Behavior on scale  {NumberAnimation{duration:180;easing.type:Easing.OutCubic}}
                        Behavior on opacity{NumberAnimation{duration:180}}
                        transform: win.selectorStyle==="skew" ? skewMatrix : noMatrix
                        Matrix4x4{id:skewMatrix;matrix:Qt.matrix4x4(1,-0.25,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)}
                        Matrix4x4{id:noMatrix; matrix:Qt.matrix4x4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)}

                        Item {
                            id: cardShapeWrap
                            x:(parent.width-cw)/2; y:(parent.height-ch)/2
                            width:cw; height:ch
                            Rectangle{
                                id:cardRect;anchors.fill:parent;antialiasing:true
                                radius:(win.selectorStyle==="cards"||win.selectorStyle==="skew")?0:win.thumbRadius
                                clip:true;color:Qt.rgba(0,0,0,0.30)
                                Image{anchors.fill:parent;fillMode:Image.PreserveAspectCrop;smooth:true;asynchronous:true
                                    source:win.thumbSrc(modelData,win.activeCategory)
                                    opacity:status===Image.Ready?1.0:0;Behavior on opacity{NumberAnimation{duration:200}}}
                                Rectangle{anchors.bottom:parent.bottom;anchors.left:parent.left;anchors.right:parent.right;height:30;color:"transparent"
                                    gradient:Gradient{orientation:Gradient.Vertical
                                        GradientStop{position:0;color:"transparent"}
                                        GradientStop{position:1;color:Qt.rgba(0,0,0,0.80)}}
                                    Text{anchors{bottom:parent.bottom;left:parent.left;right:parent.right;margins:6;bottomMargin:4}
                                        text:win.thumbLabel(modelData,win.activeCategory);font.pixelSize:9;color:Qt.rgba(1,1,1,0.78);elide:Text.ElideRight}}
                                Rectangle{anchors.fill:parent;radius:parent.radius;color:"transparent"
                                    border.color:card.isHl?win.cAc:Qt.rgba(1,1,1,0.05);border.width:card.isHl?2:1
                                    Behavior on border.color{ColorAnimation{duration:180}}}
                                Rectangle{anchors.fill:parent;radius:parent.radius;clip:true;color:"transparent"
                                    visible:card.isHl&&shimmerAnim.running
                                    Rectangle{
                                        width:cardRect.width*0.55;height:cardRect.height*3;rotation:-42
                                        x:win.shimmerProg*cardRect.width*2.2-width*0.5;y:-cardRect.height*0.9
                                        gradient:Gradient{orientation:Gradient.Horizontal
                                            GradientStop{position:0.0;color:"transparent"}
                                            GradientStop{position:0.40;color:Qt.rgba(1,1,1,0.0)}
                                            GradientStop{position:0.50;color:Qt.rgba(1,1,1,0.28)}
                                            GradientStop{position:0.60;color:Qt.rgba(1,1,1,0.0)}
                                            GradientStop{position:1.0;color:"transparent"}}
                                    }}
                                Text{visible:card.isFav;anchors.top:parent.top;anchors.right:parent.right;anchors.margins:5;text:"\u2665";font.pixelSize:11;color:win.cAc}
                            }
                            // Cut-corner overlays for cards style
                            Repeater{
                                model:win.selectorStyle==="cards"?4:0
                                delegate:Rectangle{
                                    property real cut:22;width:cut*1.42;height:cut*1.42
                                    color:Qt.rgba(win.gc1.r,win.gc1.g,win.gc1.b,win.pillOpacity)
                                    rotation:45;antialiasing:true
                                    x:(index===0||index===2)?(index===0?-cut*0.71:cardShapeWrap.width-cut*0.71):(index===1?cardShapeWrap.width-cut*0.71:-cut*0.71)
                                    y:(index===0||index===1)?-cut*0.71:cardShapeWrap.height-cut*0.71
                                }
                            }
                        }
                        MouseArea{anchors.fill:parent;onClicked:{
                            if(activeCategory===0)      win.favHl=index
                            else if(activeCategory===1) win.engineHl=index
                            else if(activeCategory===2) win.staticHl=index
                            else                        win.liveHl=index
                            win.applyCurrentWall(); wallList.scrollToIdx(index)
                        }}
                    }
                    Text{visible:wallList.count===0;anchors.centerIn:parent
                        text:win.activeCategory===0?"Nenhum favorito\nSpace para adicionar \u2665":"Nenhum wallpaper encontrado"
                        color:Qt.rgba(1,1,1,0.20);font.pixelSize:11
                        horizontalAlignment:Text.AlignHCenter;wrapMode:Text.Wrap;width:220}
                }
            }

            // Hints row
            Row{visible:!win.isVertical;anchors.bottom:parent.bottom;anchors.right:parent.right;anchors.margins:10;spacing:12
                Repeater{model:["\u2191\u2193 Cat","\u2190\u2192 Nav","\u23ce Aplicar","Space \u2665","Esc"]
                    delegate:Text{text:modelData;font.pixelSize:9;color:Qt.rgba(1,1,1,0.13)}}}
        }
        // ── END PILL ──────────────────────────────────────────────────────

        // ── CFG BUTTON (outside pill, always on top) ──────────────────────
        Rectangle {
            id: cfgBtn; z: 999
            width: 32; height: 32; radius: 16; antialiasing: true
            color: win.settingsOpen ? Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.35) : Qt.rgba(1,1,1,0.08)
            border.color: win.settingsOpen ? win.cAc : win.cRm; border.width: 1
            visible: AppState.wallpaperOpen
            Behavior on color{ColorAnimation{duration:150}}
            x: win.panelPosition==="right" ? win.pillX-width-8 : win.panelPosition==="left" ? win.pillX+win.pillW+8 : win.pillX+win.pillW-44
            y: (win.panelPosition==="right"||win.panelPosition==="left") ? win.pillY+win.pillH-height-8 : win.panelPosition==="top" ? win.pillY+win.pillH+6 : win.pillY-height-6
            Behavior on x{NumberAnimation{duration:350;easing.type:Easing.OutCubic}}
            Behavior on y{NumberAnimation{duration:350;easing.type:Easing.OutCubic}}
            Text{anchors.centerIn:parent;text:"\u2699";font.pixelSize:14
                color:win.settingsOpen?win.cAc:Qt.rgba(1,1,1,0.55)
                rotation:win.settingsOpen?45:0;Behavior on rotation{NumberAnimation{duration:200;easing.type:Easing.OutBack}}}
            MouseArea{anchors.fill:parent;onClicked:win.settingsOpen=!win.settingsOpen}
        }

        // ── SETTINGS OVERLAY (fullscreen, z:1000) ─────────────────────────
        Item {
            id: settingsOverlay
            z: 1000
            anchors.fill: parent
            visible: win.settingsOpen || settingsOpacAnim.running
            opacity: win.settingsOpen ? 1.0 : 0.0
            Behavior on opacity{NumberAnimation{id:settingsOpacAnim;duration:220;easing.type:Easing.OutCubic}}

            // Dim backdrop
            Rectangle{
                anchors.fill: parent
                color: Qt.rgba(0,0,0,0.58)
                MouseArea{anchors.fill:parent;onClicked:win.settingsOpen=false}
            }

            // Settings card (centered)
            Rectangle {
                id: settingsCard
                anchors.centerIn: parent
                width:  Math.min(win.sw - 80, 900)
                height: Math.min(win.sh - 80, 590)
                radius: 22; antialiasing: true
                color: Qt.rgba(0.04, 0.04, 0.11, 0.96)
                border.color: Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.20); border.width: 1
                scale: win.settingsOpen ? 1.0 : 0.90
                Behavior on scale{NumberAnimation{duration:220;easing.type:Easing.OutCubic}}
                layer.enabled: true

                MouseArea{anchors.fill:parent} // absorb clicks

                Row{
                    anchors.fill: parent

                    // ── LEFT SIDEBAR ──────────────────────────────────────
                    Item {
                        id: cfgSidebar
                        width: 190; height: parent.height

                        Rectangle{anchors.fill:parent;radius:22
                            color:Qt.rgba(win.cAc.r*0.10,win.cAc.g*0.12,win.cAc.b*0.25,0.95)}

                        // Logo area
                        Item{
                            anchors.top:parent.top;anchors.left:parent.left;anchors.right:parent.right
                            height:64
                            Text{anchors.centerIn:parent;text:"ShiraOS";font.pixelSize:18;font.bold:true
                                color:win.cAc;opacity:0.90}
                        }

                        // Category buttons
                        Column{
                            anchors.top:parent.top;anchors.topMargin:70
                            anchors.left:parent.left;anchors.right:parent.right
                            anchors.leftMargin:10;anchors.rightMargin:10
                            spacing:6

                            // [icon, label, tabIndex]
                            Repeater{
                                model:[
                                    {icon:"\uD83D\uDCCD",label:"POSI\u00c7\u00c3O",    tab:0},
                                    {icon:"\u2728",     label:"ANIMA\u00c7\u00c3O",   tab:1},
                                    {icon:"\uD83C\uDFA8",label:"APAR\u00caNCIA",     tab:2},
                                    {icon:"\uD83D\uDDBC",label:"MODELO",            tab:3},
                                    {icon:"\uD83C\uDF19",label:"TEMA",              tab:4}
                                ]
                                delegate:Rectangle{
                                    width:parent.width; height:48; radius:12; antialiasing:true
                                    property bool act:win.cfgTab===modelData.tab
                                    gradient:Gradient{
                                        GradientStop{position:0.0;color:act?Qt.rgba(win.cAc.r*0.9,win.cAc.g*0.9,win.cAc.b*0.9,0.80):Qt.rgba(1,1,1,0.06)}
                                        GradientStop{position:1.0;color:act?Qt.rgba(win.cAc.r*0.5,win.cAc.g*0.7,win.cAc.b*1.0,0.60):Qt.rgba(1,1,1,0.03)}
                                    }
                                    border.color:act?win.cAc:Qt.rgba(1,1,1,0.08);border.width:1
                                    Behavior on gradient{PropertyAnimation{duration:150}}
                                    Row{anchors.left:parent.left;anchors.leftMargin:14;anchors.verticalCenter:parent.verticalCenter;spacing:12
                                        Text{text:modelData.icon;font.pixelSize:16;color:act?"white":Qt.rgba(1,1,1,0.45)}
                                        Text{text:modelData.label;font.pixelSize:11;font.bold:act;
                                            color:act?"white":Qt.rgba(1,1,1,0.50);font.letterSpacing:0.5}
                                    }
                                    // Active indicator bar
                                    Rectangle{visible:act;anchors.right:parent.right;anchors.verticalCenter:parent.verticalCenter;width:3;height:24;radius:1.5;color:"white"}
                                    MouseArea{anchors.fill:parent;onClicked:win.cfgTab=modelData.tab}
                                }
                            }
                        }

                        // Version hint
                        Text{anchors.bottom:parent.bottom;anchors.bottomMargin:14;anchors.horizontalCenter:parent.horizontalCenter
                            text:"v7.0  \u2022  pywal16";font.pixelSize:9;color:Qt.rgba(1,1,1,0.20)}
                    }
                    // ── END SIDEBAR ───────────────────────────────────────

                    // ── RIGHT CONTENT ─────────────────────────────────────
                    Item {
                        id: cfgRight
                        width: parent.width - 190
                        height: parent.height

                        // scrollable tab content
                        Flickable {
                            id:cfgFlick
                            anchors.top:parent.top;anchors.topMargin:16
                            anchors.left:parent.left;anchors.leftMargin:20
                            anchors.right:parent.right;anchors.rightMargin:20
                            anchors.bottom:previewStrip.top;anchors.bottomMargin:8
                            clip:true; contentHeight:cfgTabContent.implicitHeight

                            Column {
                                id:cfgTabContent
                                width:cfgFlick.width
                                spacing:14

                                // ── TAB 0: POSIÇÃO ─────────────────────
                                Column{visible:win.cfgTab===0;width:parent.width;spacing:12
                                    Text{text:"Posi\u00e7\u00e3o do seletor";font.pixelSize:11;font.bold:true;color:win.cAc}
                                    Grid{columns:3;spacing:6;width:parent.width
                                        Repeater{
                                            model:[{i:"top",l:"\u2b06 Topo"},{i:"left",l:"\u2b05 Esq"},{i:"center",l:"\u29bf Centro"},
                                                   {i:"right",l:"Dir \u27a1"},{i:"bottom",l:"\u2b07 Baixo"},{i:"",l:""}]
                                            delegate:Rectangle{
                                                visible:modelData.i!==""; property bool act:win.panelPosition===modelData.i
                                                width:(cfgTabContent.width-12)/3;height:38;radius:10
                                                color:act?Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.28):Qt.rgba(1,1,1,0.06)
                                                border.color:act?win.cAc:"transparent";border.width:1
                                                Behavior on color{ColorAnimation{duration:150}}
                                                Text{anchors.centerIn:parent;text:modelData.l;font.pixelSize:11;color:act?win.cAc:Qt.rgba(1,1,1,0.50)}
                                                MouseArea{anchors.fill:parent;onClicked:win.panelPosition=modelData.i}
                                            }
                                        }
                                    }
                                    Text{text:"Transi\u00e7\u00e3o awww";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45);topPadding:6}
                                    Flow{width:parent.width;spacing:5
                                        Repeater{model:["grow","fade","wave","wipe","slide","outer","any","random","none"]
                                            delegate:Rectangle{
                                                property bool act:win.swwwTransition===modelData
                                                width:tT2.implicitWidth+14;height:26;radius:13
                                                color:act?Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.28):Qt.rgba(1,1,1,0.06)
                                                border.color:act?win.cAc:"transparent";border.width:1
                                                Behavior on color{ColorAnimation{duration:150}}
                                                Text{id:tT2;anchors.centerIn:parent;text:modelData;font.pixelSize:10;color:act?win.cAc:Qt.rgba(1,1,1,0.45)}
                                                MouseArea{anchors.fill:parent;onClicked:win.swwwTransition=modelData}
                                            }
                                        }
                                    }
                                    Item{height:4}
                                }

                                // ── TAB 1: ANIMAÇÃO ────────────────────
                                Column{visible:win.cfgTab===1;width:parent.width;spacing:12
                                    Text{text:"Estilo ao abrir";font.pixelSize:11;font.bold:true;color:win.cAc}
                                    Row{spacing:6
                                        Repeater{model:[{k:"slide",l:"Deslizar"},{k:"fade",l:"Fade"},{k:"scale",l:"Escala"},{k:"bounce",l:"Bounce"}]
                                            delegate:Rectangle{
                                                property bool act:win.openStyle===modelData.k
                                                width:aT2.implicitWidth+16;height:30;radius:15
                                                color:act?Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.28):Qt.rgba(1,1,1,0.06)
                                                border.color:act?win.cAc:"transparent";border.width:1
                                                Behavior on color{ColorAnimation{duration:150}}
                                                Text{id:aT2;anchors.centerIn:parent;text:modelData.l;font.pixelSize:10;color:act?win.cAc:Qt.rgba(1,1,1,0.50)}
                                                MouseArea{anchors.fill:parent;onClicked:win.openStyle=modelData.k}
                                            }
                                        }
                                    }
                                    Text{text:"Ao trocar de lado";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45);topPadding:6}
                                    Row{spacing:6
                                        Repeater{model:[{k:"shooter",l:"Rastro"},{k:"fade",l:"Fade"},{k:"none",l:"Instant\u00e2neo"}]
                                            delegate:Rectangle{
                                                property bool act:win.moveStyle===modelData.k
                                                width:mT2.implicitWidth+16;height:30;radius:15
                                                color:act?Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.28):Qt.rgba(1,1,1,0.06)
                                                border.color:act?win.cAc:"transparent";border.width:1
                                                Behavior on color{ColorAnimation{duration:150}}
                                                Text{id:mT2;anchors.centerIn:parent;text:modelData.l;font.pixelSize:10;color:act?win.cAc:Qt.rgba(1,1,1,0.50)}
                                                MouseArea{anchors.fill:parent;onClicked:win.moveStyle=modelData.k}
                                            }
                                        }
                                    }
                                    Item{height:4}
                                }

                                // ── TAB 2: APARÊNCIA ───────────────────
                                Column{visible:win.cfgTab===2;width:parent.width;spacing:12
                                    Text{text:"Apar\u00eancia do seletor";font.pixelSize:11;font.bold:true;color:win.cAc}

                        Text{text:"Opacidade do painel";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45)}
                        Row{spacing:10;width:parent.width
                            Item {
                                id:sl_Op; width:parent.width-54; height:22
                                property real slFrom:0.1; property real slTo:0.98
                                property real slVal:win.pillOpacity
                                Rectangle {
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:parent.width; height:5; radius:2.5; color:Qt.rgba(1,1,1,0.12)
                                    Rectangle {
                                        width:Math.max(0,Math.min(1,(sl_Op.slVal-sl_Op.slFrom)/(sl_Op.slTo-sl_Op.slFrom)))*parent.width
                                        height:parent.height; radius:parent.radius; color:win.cAc
                                    }
                                }
                                Rectangle {
                                    x:Math.max(0,Math.min(1,(sl_Op.slVal-sl_Op.slFrom)/(sl_Op.slTo-sl_Op.slFrom)))*(sl_Op.width-18)
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:18; height:18; radius:9; color:win.cAc; antialiasing:true
                                    Rectangle{anchors.centerIn:parent;width:8;height:8;radius:4;color:"white";opacity:0.9}
                                }
                                MouseArea{
                                    anchors.fill:parent; anchors.margins:-8
                                    function calc(mx){return sl_Op.slFrom+Math.max(0,Math.min(1,(mx-9)/(sl_Op.width-18)))*(sl_Op.slTo-sl_Op.slFrom)}
                                    onPressed:         {sl_Op.slVal=calc(mouseX);win.pillOpacity=sl_Op.slVal}
                                    onPositionChanged: {if(pressed){sl_Op.slVal=calc(mouseX);win.pillOpacity=sl_Op.slVal}}
                                    onReleased:        {sl_Op.slVal=calc(mouseX);win.pillOpacity=sl_Op.slVal}
                                }
                            }
                            Text{text:Math.round(sl_Op.slVal*100)+"%"+"";font.pixelSize:10;color:win.cAc;anchors.verticalCenter:parent.verticalCenter;width:42}
                        }
                        Text{text:"Espessura da pill";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45)}
                        Row{spacing:10;width:parent.width
                            Item {
                                id:sl_Th; width:parent.width-54; height:22
                                property real slFrom:120; property real slTo:380
                                property real slVal:win.panelThick
                                Rectangle {
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:parent.width; height:5; radius:2.5; color:Qt.rgba(1,1,1,0.12)
                                    Rectangle {
                                        width:Math.max(0,Math.min(1,(sl_Th.slVal-sl_Th.slFrom)/(sl_Th.slTo-sl_Th.slFrom)))*parent.width
                                        height:parent.height; radius:parent.radius; color:win.cAc
                                    }
                                }
                                Rectangle {
                                    x:Math.max(0,Math.min(1,(sl_Th.slVal-sl_Th.slFrom)/(sl_Th.slTo-sl_Th.slFrom)))*(sl_Th.width-18)
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:18; height:18; radius:9; color:win.cAc; antialiasing:true
                                    Rectangle{anchors.centerIn:parent;width:8;height:8;radius:4;color:"white";opacity:0.9}
                                }
                                MouseArea{
                                    anchors.fill:parent; anchors.margins:-8
                                    function calc(mx){return sl_Th.slFrom+Math.max(0,Math.min(1,(mx-9)/(sl_Th.width-18)))*(sl_Th.slTo-sl_Th.slFrom)}
                                    onPressed:         {sl_Th.slVal=calc(mouseX);}
                                    onPositionChanged: {if(pressed){sl_Th.slVal=calc(mouseX);}}
                                    onReleased:        {sl_Th.slVal=calc(mouseX);win.panelThick=Math.round(sl_Th.slVal)}
                                }
                            }
                            Text{text:Math.round(sl_Th.slVal)+"";font.pixelSize:10;color:win.cAc;anchors.verticalCenter:parent.verticalCenter;width:42}
                        }
                        Text{text:"Largura do seletor";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45)}
                        Row{spacing:10;width:parent.width
                            Item {
                                id:sl_Sp; width:parent.width-54; height:22
                                property real slFrom:0.3; property real slTo:0.99
                                property real slVal:win.panelSpan
                                Rectangle {
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:parent.width; height:5; radius:2.5; color:Qt.rgba(1,1,1,0.12)
                                    Rectangle {
                                        width:Math.max(0,Math.min(1,(sl_Sp.slVal-sl_Sp.slFrom)/(sl_Sp.slTo-sl_Sp.slFrom)))*parent.width
                                        height:parent.height; radius:parent.radius; color:win.cAc
                                    }
                                }
                                Rectangle {
                                    x:Math.max(0,Math.min(1,(sl_Sp.slVal-sl_Sp.slFrom)/(sl_Sp.slTo-sl_Sp.slFrom)))*(sl_Sp.width-18)
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:18; height:18; radius:9; color:win.cAc; antialiasing:true
                                    Rectangle{anchors.centerIn:parent;width:8;height:8;radius:4;color:"white";opacity:0.9}
                                }
                                MouseArea{
                                    anchors.fill:parent; anchors.margins:-8
                                    function calc(mx){return sl_Sp.slFrom+Math.max(0,Math.min(1,(mx-9)/(sl_Sp.width-18)))*(sl_Sp.slTo-sl_Sp.slFrom)}
                                    onPressed:         {sl_Sp.slVal=calc(mouseX);}
                                    onPositionChanged: {if(pressed){sl_Sp.slVal=calc(mouseX);}}
                                    onReleased:        {sl_Sp.slVal=calc(mouseX);win.panelSpan=sl_Sp.slVal}
                                }
                            }
                            Text{text:Math.round(sl_Sp.slVal)+"";font.pixelSize:10;color:win.cAc;anchors.verticalCenter:parent.verticalCenter;width:42}
                        }
                        Text{text:"Borda dos thumbs";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45)}
                        Row{spacing:10;width:parent.width
                            Item {
                                id:sl_Ra; width:parent.width-54; height:22
                                property real slFrom:0; property real slTo:80
                                property real slVal:win.thumbRadius
                                Rectangle {
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:parent.width; height:5; radius:2.5; color:Qt.rgba(1,1,1,0.12)
                                    Rectangle {
                                        width:Math.max(0,Math.min(1,(sl_Ra.slVal-sl_Ra.slFrom)/(sl_Ra.slTo-sl_Ra.slFrom)))*parent.width
                                        height:parent.height; radius:parent.radius; color:win.cAc
                                    }
                                }
                                Rectangle {
                                    x:Math.max(0,Math.min(1,(sl_Ra.slVal-sl_Ra.slFrom)/(sl_Ra.slTo-sl_Ra.slFrom)))*(sl_Ra.width-18)
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:18; height:18; radius:9; color:win.cAc; antialiasing:true
                                    Rectangle{anchors.centerIn:parent;width:8;height:8;radius:4;color:"white";opacity:0.9}
                                }
                                MouseArea{
                                    anchors.fill:parent; anchors.margins:-8
                                    function calc(mx){return sl_Ra.slFrom+Math.max(0,Math.min(1,(mx-9)/(sl_Ra.width-18)))*(sl_Ra.slTo-sl_Ra.slFrom)}
                                    onPressed:         {sl_Ra.slVal=calc(mouseX);win.thumbRadius=Math.round(sl_Ra.slVal)}
                                    onPositionChanged: {if(pressed){sl_Ra.slVal=calc(mouseX);win.thumbRadius=Math.round(sl_Ra.slVal)}}
                                    onReleased:        {sl_Ra.slVal=calc(mouseX);win.thumbRadius=Math.round(sl_Ra.slVal)}
                                }
                            }
                            Text{text:Math.round(sl_Ra.slVal)+"";font.pixelSize:10;color:win.cAc;anchors.verticalCenter:parent.verticalCenter;width:42}
                        }
                                    // Fundo do seletor
                                    Rectangle{width:parent.width;height:1;color:Qt.rgba(1,1,1,0.08)}
                                    Text{text:"Imagem de fundo";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45);topPadding:6}
                                    Row{spacing:12;height:34
                                        Text{text:"Ativar fundo personalizado";font.pixelSize:10;color:Qt.rgba(1,1,1,0.60);anchors.verticalCenter:parent.verticalCenter}
                                        Rectangle{anchors.verticalCenter:parent.verticalCenter;width:44;height:24;radius:12
                                            color:win.useSelectorBg?Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.50):Qt.rgba(1,1,1,0.10)
                                            Behavior on color{ColorAnimation{duration:150}}
                                            Rectangle{x:win.useSelectorBg?parent.width-width-3:3;y:4;width:16;height:16;radius:8;color:"white"
                                                Behavior on x{NumberAnimation{duration:150;easing.type:Easing.OutCubic}}}
                                            MouseArea{anchors.fill:parent;onClicked:win.useSelectorBg=!win.useSelectorBg}
                                        }
                                    }
                                    Text{font.pixelSize:9;color:Qt.rgba(1,1,1,0.28);text:"~/Pictures/Wallpapers/WallpaperSelector/"}
                                    Flow{width:parent.width;spacing:6
                                        Repeater{model:win.selectorBgList;delegate:Rectangle{
                                            property bool cur:win.selectorBg===modelData
                                            width:72;height:48;radius:8;clip:true
                                            border.color:cur?win.cAc:"transparent";border.width:2
                                            Image{anchors.fill:parent;source:"file://"+modelData;fillMode:Image.PreserveAspectCrop;smooth:true}
                                            MouseArea{anchors.fill:parent;onClicked:{win.selectorBg=modelData;win.useSelectorBg=true}}
                                        }}
                                        Text{visible:win.selectorBgList.length===0;text:"Nenhuma imagem\nem WallpaperSelector/";font.pixelSize:9;color:Qt.rgba(1,1,1,0.25);wrapMode:Text.Wrap}
                                    }
                                    Item{height:4}
                                }

                                // ── TAB 3: MODELO ──────────────────────
                                Column{visible:win.cfgTab===3;width:parent.width;spacing:12
                                    Text{text:"Modelo do seletor";font.pixelSize:11;font.bold:true;color:win.cAc}
                                    Grid{columns:2;spacing:8;width:parent.width
                                        Repeater{
                                            model:[
                                                {k:"pill",     l:"Pill",     d:"Barra arredondada"},
                                                {k:"cards",    l:"Cards",    d:"Bordas cortadas (oct\u00e1gono)"},
                                                {k:"skew",     l:"Inclinado",d:"Paralelogramo"},
                                                {k:"spotlight",l:"Spotlight",d:"Um grande + pequenos"},
                                                {k:"varal",    l:"Varal",    d:"Fotos com pregadores"}
                                            ]
                                            delegate:Rectangle{
                                                property bool act:win.selectorStyle===modelData.k
                                                width:(cfgTabContent.width-8)/2;height:62;radius:12
                                                color:act?Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.28):Qt.rgba(1,1,1,0.06)
                                                border.color:act?win.cAc:"transparent";border.width:1
                                                Behavior on color{ColorAnimation{duration:150}}
                                                Column{anchors.centerIn:parent;spacing:4
                                                    Text{anchors.horizontalCenter:parent.horizontalCenter;text:modelData.l;font.pixelSize:12;font.bold:true;color:act?win.cAc:Qt.rgba(1,1,1,0.70)}
                                                    Text{anchors.horizontalCenter:parent.horizontalCenter;text:modelData.d;font.pixelSize:9;color:Qt.rgba(1,1,1,0.40)}
                                                }
                                                MouseArea{anchors.fill:parent;onClicked:win.selectorStyle=modelData.k}
                                            }
                                        }
                                    }
                                    // Skew sliders
                                    Column{visible:win.selectorStyle==="skew";width:parent.width;spacing:10
                                        Rectangle{width:parent.width;height:1;color:Qt.rgba(1,1,1,0.08)}
                                        Text{text:"Configura\u00e7\u00f5es Inclinado";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45);topPadding:4}

                        Text{text:"Altura (% da tela)";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45)}
                        Row{spacing:10;width:parent.width
                            Item {
                                id:sl_SkH; width:parent.width-54; height:22
                                property real slFrom:0.2; property real slTo:0.9
                                property real slVal:win.skewHeight
                                Rectangle {
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:parent.width; height:5; radius:2.5; color:Qt.rgba(1,1,1,0.12)
                                    Rectangle {
                                        width:Math.max(0,Math.min(1,(sl_SkH.slVal-sl_SkH.slFrom)/(sl_SkH.slTo-sl_SkH.slFrom)))*parent.width
                                        height:parent.height; radius:parent.radius; color:win.cAc
                                    }
                                }
                                Rectangle {
                                    x:Math.max(0,Math.min(1,(sl_SkH.slVal-sl_SkH.slFrom)/(sl_SkH.slTo-sl_SkH.slFrom)))*(sl_SkH.width-18)
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:18; height:18; radius:9; color:win.cAc; antialiasing:true
                                    Rectangle{anchors.centerIn:parent;width:8;height:8;radius:4;color:"white";opacity:0.9}
                                }
                                MouseArea{
                                    anchors.fill:parent; anchors.margins:-8
                                    function calc(mx){return sl_SkH.slFrom+Math.max(0,Math.min(1,(mx-9)/(sl_SkH.width-18)))*(sl_SkH.slTo-sl_SkH.slFrom)}
                                    onPressed:         {sl_SkH.slVal=calc(mouseX);win.skewHeight=sl_SkH.slVal}
                                    onPositionChanged: {if(pressed){sl_SkH.slVal=calc(mouseX);win.skewHeight=sl_SkH.slVal}}
                                    onReleased:        {sl_SkH.slVal=calc(mouseX);win.skewHeight=sl_SkH.slVal}
                                }
                            }
                            Text{text:Math.round(sl_SkH.slVal*100)+"%"+"";font.pixelSize:10;color:win.cAc;anchors.verticalCenter:parent.verticalCenter;width:42}
                        }
                        Text{text:"Largura dos cards";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45)}
                        Row{spacing:10;width:parent.width
                            Item {
                                id:sl_SkW; width:parent.width-54; height:22
                                property real slFrom:0.8; property real slTo:3.0
                                property real slVal:win.skewWidth
                                Rectangle {
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:parent.width; height:5; radius:2.5; color:Qt.rgba(1,1,1,0.12)
                                    Rectangle {
                                        width:Math.max(0,Math.min(1,(sl_SkW.slVal-sl_SkW.slFrom)/(sl_SkW.slTo-sl_SkW.slFrom)))*parent.width
                                        height:parent.height; radius:parent.radius; color:win.cAc
                                    }
                                }
                                Rectangle {
                                    x:Math.max(0,Math.min(1,(sl_SkW.slVal-sl_SkW.slFrom)/(sl_SkW.slTo-sl_SkW.slFrom)))*(sl_SkW.width-18)
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:18; height:18; radius:9; color:win.cAc; antialiasing:true
                                    Rectangle{anchors.centerIn:parent;width:8;height:8;radius:4;color:"white";opacity:0.9}
                                }
                                MouseArea{
                                    anchors.fill:parent; anchors.margins:-8
                                    function calc(mx){return sl_SkW.slFrom+Math.max(0,Math.min(1,(mx-9)/(sl_SkW.width-18)))*(sl_SkW.slTo-sl_SkW.slFrom)}
                                    onPressed:         {sl_SkW.slVal=calc(mouseX);win.skewWidth=sl_SkW.slVal}
                                    onPositionChanged: {if(pressed){sl_SkW.slVal=calc(mouseX);win.skewWidth=sl_SkW.slVal}}
                                    onReleased:        {sl_SkW.slVal=calc(mouseX);win.skewWidth=sl_SkW.slVal}
                                }
                            }
                            Text{text:Math.round(sl_SkW.slVal*100)+"%"+"";font.pixelSize:10;color:win.cAc;anchors.verticalCenter:parent.verticalCenter;width:42}
                        }
                        Text{text:"Sobreposição";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45)}
                        Row{spacing:10;width:parent.width
                            Item {
                                id:sl_SkO; width:parent.width-54; height:22
                                property real slFrom:0.0; property real slTo:0.6
                                property real slVal:win.skewOverlap
                                Rectangle {
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:parent.width; height:5; radius:2.5; color:Qt.rgba(1,1,1,0.12)
                                    Rectangle {
                                        width:Math.max(0,Math.min(1,(sl_SkO.slVal-sl_SkO.slFrom)/(sl_SkO.slTo-sl_SkO.slFrom)))*parent.width
                                        height:parent.height; radius:parent.radius; color:win.cAc
                                    }
                                }
                                Rectangle {
                                    x:Math.max(0,Math.min(1,(sl_SkO.slVal-sl_SkO.slFrom)/(sl_SkO.slTo-sl_SkO.slFrom)))*(sl_SkO.width-18)
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:18; height:18; radius:9; color:win.cAc; antialiasing:true
                                    Rectangle{anchors.centerIn:parent;width:8;height:8;radius:4;color:"white";opacity:0.9}
                                }
                                MouseArea{
                                    anchors.fill:parent; anchors.margins:-8
                                    function calc(mx){return sl_SkO.slFrom+Math.max(0,Math.min(1,(mx-9)/(sl_SkO.width-18)))*(sl_SkO.slTo-sl_SkO.slFrom)}
                                    onPressed:         {sl_SkO.slVal=calc(mouseX);win.skewOverlap=sl_SkO.slVal}
                                    onPositionChanged: {if(pressed){sl_SkO.slVal=calc(mouseX);win.skewOverlap=sl_SkO.slVal}}
                                    onReleased:        {sl_SkO.slVal=calc(mouseX);win.skewOverlap=sl_SkO.slVal}
                                }
                            }
                            Text{text:Math.round(sl_SkO.slVal*100)+"%"+"";font.pixelSize:10;color:win.cAc;anchors.verticalCenter:parent.verticalCenter;width:42}
                        }
                                    }
                                    // Varal settings
                                    Column{visible:win.selectorStyle==="varal";width:parent.width;spacing:10
                                        Rectangle{width:parent.width;height:1;color:Qt.rgba(1,1,1,0.08)}
                                        Text{text:"Configura\u00e7\u00f5es Varal";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45);topPadding:4}
                                        Row{spacing:12;height:34
                                            Text{text:"Mostrar pregadores";font.pixelSize:10;color:Qt.rgba(1,1,1,0.60);anchors.verticalCenter:parent.verticalCenter}
                                            Rectangle{anchors.verticalCenter:parent.verticalCenter;width:44;height:24;radius:12
                                                color:win.varalShowPegs?Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.50):Qt.rgba(1,1,1,0.10)
                                                Behavior on color{ColorAnimation{duration:150}}
                                                Rectangle{x:win.varalShowPegs?parent.width-width-3:3;y:4;width:16;height:16;radius:8;color:"white"
                                                    Behavior on x{NumberAnimation{duration:150;easing.type:Easing.OutCubic}}}
                                                MouseArea{anchors.fill:parent;onClicked:win.varalShowPegs=!win.varalShowPegs}
                                            }
                                        }

                        Text{text:"Quantidade de fotos";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45)}
                        Row{spacing:10;width:parent.width
                            Item {
                                id:sl_VarN; width:parent.width-54; height:22
                                property real slFrom:2; property real slTo:10
                                property real slVal:win.varalCount
                                Rectangle {
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:parent.width; height:5; radius:2.5; color:Qt.rgba(1,1,1,0.12)
                                    Rectangle {
                                        width:Math.max(0,Math.min(1,(sl_VarN.slVal-sl_VarN.slFrom)/(sl_VarN.slTo-sl_VarN.slFrom)))*parent.width
                                        height:parent.height; radius:parent.radius; color:win.cAc
                                    }
                                }
                                Rectangle {
                                    x:Math.max(0,Math.min(1,(sl_VarN.slVal-sl_VarN.slFrom)/(sl_VarN.slTo-sl_VarN.slFrom)))*(sl_VarN.width-18)
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:18; height:18; radius:9; color:win.cAc; antialiasing:true
                                    Rectangle{anchors.centerIn:parent;width:8;height:8;radius:4;color:"white";opacity:0.9}
                                }
                                MouseArea{
                                    anchors.fill:parent; anchors.margins:-8
                                    function calc(mx){return sl_VarN.slFrom+Math.max(0,Math.min(1,(mx-9)/(sl_VarN.width-18)))*(sl_VarN.slTo-sl_VarN.slFrom)}
                                    onPressed:         {sl_VarN.slVal=calc(mouseX);}
                                    onPositionChanged: {if(pressed){sl_VarN.slVal=calc(mouseX);}}
                                    onReleased:        {sl_VarN.slVal=calc(mouseX);win.varalCount=Math.round(sl_VarN.slVal)}
                                }
                            }
                            Text{text:Math.round(sl_VarN.slVal)+"";font.pixelSize:10;color:win.cAc;anchors.verticalCenter:parent.verticalCenter;width:42}
                        }
                        Text{text:"Escala das fotos";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45)}
                        Row{spacing:10;width:parent.width
                            Item {
                                id:sl_VarS; width:parent.width-54; height:22
                                property real slFrom:0.4; property real slTo:2.0
                                property real slVal:win.varalScale
                                Rectangle {
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:parent.width; height:5; radius:2.5; color:Qt.rgba(1,1,1,0.12)
                                    Rectangle {
                                        width:Math.max(0,Math.min(1,(sl_VarS.slVal-sl_VarS.slFrom)/(sl_VarS.slTo-sl_VarS.slFrom)))*parent.width
                                        height:parent.height; radius:parent.radius; color:win.cAc
                                    }
                                }
                                Rectangle {
                                    x:Math.max(0,Math.min(1,(sl_VarS.slVal-sl_VarS.slFrom)/(sl_VarS.slTo-sl_VarS.slFrom)))*(sl_VarS.width-18)
                                    anchors.verticalCenter:parent.verticalCenter
                                    width:18; height:18; radius:9; color:win.cAc; antialiasing:true
                                    Rectangle{anchors.centerIn:parent;width:8;height:8;radius:4;color:"white";opacity:0.9}
                                }
                                MouseArea{
                                    anchors.fill:parent; anchors.margins:-8
                                    function calc(mx){return sl_VarS.slFrom+Math.max(0,Math.min(1,(mx-9)/(sl_VarS.width-18)))*(sl_VarS.slTo-sl_VarS.slFrom)}
                                    onPressed:         {sl_VarS.slVal=calc(mouseX);win.varalScale=sl_VarS.slVal}
                                    onPositionChanged: {if(pressed){sl_VarS.slVal=calc(mouseX);win.varalScale=sl_VarS.slVal}}
                                    onReleased:        {sl_VarS.slVal=calc(mouseX);win.varalScale=sl_VarS.slVal}
                                }
                            }
                            Text{text:Math.round(sl_VarS.slVal*100)+"%"+"";font.pixelSize:10;color:win.cAc;anchors.verticalCenter:parent.verticalCenter;width:42}
                        }
                                        // Line color picker
                                        Text{text:"Cor da corda";font.pixelSize:10;color:Qt.rgba(1,1,1,0.45);topPadding:4}
                                        Flow{width:parent.width;spacing:8
                                            Repeater{model:["#cc4444","#4488cc","#44aa66","#aa44aa","#cc9933","#888888","#ffffff","#ff8844"]
                                                delegate:Rectangle{
                                                    width:28;height:28;radius:14;color:modelData;antialiasing:true
                                                    border.color:win.varalLineColor===modelData?"white":"transparent";border.width:2
                                                    MouseArea{anchors.fill:parent;onClicked:{win.varalLineColor=modelData;ropeCanvas.requestPaint()}}
                                                }
                                            }
                                        }
                                    }
                                    Item{height:4}
                                }

                                // ── TAB 4: TEMA ─────────────────────────
                                Column{visible:win.cfgTab===4;width:parent.width;spacing:12
                                    Text{text:"Tema autom\u00e1tico  (pywal16)";font.pixelSize:11;font.bold:true;color:win.cAc}
                                    Text{font.pixelSize:10;color:Qt.rgba(1,1,1,0.55);wrapMode:Text.Wrap;width:parent.width
                                        text:"Ao trocar wallpaper, pywal16 gera uma paleta e aplica em:\nKitty  \u2022  Hyprland (bordas)  \u2022  Mako / Dunst"}
                                    Text{font.pixelSize:9;color:Qt.rgba(1,1,1,0.30);wrapMode:Text.Wrap;width:parent.width
                                        text:"Instalar:  yay -S python-pywal16  ou  pip install pywal16"}
                                    Rectangle{
                                        width:parent.width;height:40;radius:12
                                        color:Qt.rgba(win.cAc.r,win.cAc.g,win.cAc.b,0.18)
                                        border.color:win.cAc;border.width:1
                                        Text{anchors.centerIn:parent;text:"\u21bb  Reaplicar tema agora";font.pixelSize:11;color:win.cAc}
                                        MouseArea{anchors.fill:parent;onClicked:{
                                            var cur=""
                                            try{var r=Qt.resolvedUrl("file://"+String(AppState.staticWallPath||"")).toString();cur=r.replace("file://","")}catch(e){}
                                            win.runTheme(cur)
                                        }}
                                    }
                                    // Color preview chips
                                    Text{text:"Cores ativas";font.pixelSize:10;color:Qt.rgba(1,1,1,0.40);topPadding:8}
                                    Row{spacing:8
                                        Repeater{model:[win.cAc,win.gc1,win.gc2,win.cRm]
                                            delegate:Column{spacing:4
                                                Rectangle{width:40;height:26;radius:6;color:modelData;antialiasing:true;border.color:Qt.rgba(1,1,1,0.15);border.width:1}
                                            }
                                        }
                                    }
                                    Item{height:4}
                                }
                            }
                        }

                        // ── WALLPAPER PREVIEW STRIP (bottom) ──────────────
                        Item{
                            id:previewStrip
                            anchors.bottom:parent.bottom;anchors.left:parent.left;anchors.right:parent.right
                            height:90
                            Rectangle{anchors.fill:parent;color:Qt.rgba(0,0,0,0.25);radius:0}
                            Text{anchors.left:parent.left;anchors.leftMargin:16;anchors.top:parent.top;anchors.topMargin:8
                                text:"Preview r\u00e1pido — clique para aplicar";font.pixelSize:9;color:Qt.rgba(1,1,1,0.28)}
                            ListView{
                                anchors.top:parent.top;anchors.topMargin:22
                                anchors.left:parent.left;anchors.leftMargin:12
                                anchors.right:parent.right;anchors.rightMargin:12
                                anchors.bottom:parent.bottom;anchors.bottomMargin:8
                                orientation:ListView.Horizontal;spacing:8;clip:true
                                model:win.staticWalls
                                delegate:Rectangle{
                                    width:96;height:parent.height;radius:8;clip:true;antialiasing:true
                                    color:Qt.rgba(0,0,0,0.30)
                                    Image{anchors.fill:parent;source:"file://"+modelData;fillMode:Image.PreserveAspectCrop;smooth:true;asynchronous:true
                                        opacity:status===Image.Ready?1:0;Behavior on opacity{NumberAnimation{duration:200}}}
                                    Rectangle{anchors.fill:parent;radius:parent.radius;color:"transparent";border.color:Qt.rgba(1,1,1,0.12);border.width:1}
                                    MouseArea{anchors.fill:parent;onClicked:{
                                        killEngine.running=false;killEngine.running=true;killLive.running=false;killLive.running=true
                                        applyStatic.command=["awww","img",modelData,"--transition-type","fade","--transition-duration","0.8","--transition-fps","60"]
                                        applyStatic.running=false;applyStatic.running=true
                                        win.runTheme(modelData); shimmerAnim.restart()
                                    }}
                                }
                            }
                        }
                    }
                    // ── END RIGHT CONTENT ─────────────────────────────────
                }
            }
        }
        // ── END SETTINGS OVERLAY ──────────────────────────────────────────

        // ── Shooter particles ─────────────────────────────────────────────
        Repeater{
            model:(win.moveStyle==="shooter"&&win.shootActive)?16:0
            delegate:Rectangle{
                property real prog:Math.max(0,Math.min(1,win.shootProg-index*0.050))
                property real fade:Math.pow(1-prog,2.0)
                width:5+5*(1-prog);height:width;radius:width/2
                color:win.cAc;opacity:fade*0.85
                x:win.shootFX+(win.shootTX-win.shootFX)*prog-width/2+(index%4-1.5)*10*(1-prog)
                y:win.shootFY+(win.shootTY-win.shootFY)*prog-height/2+(Math.floor(index/4)-1)*10*(1-prog)
            }
        }
    }
}
