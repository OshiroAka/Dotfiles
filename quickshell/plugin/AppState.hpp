#pragma once
#include <QObject>
#include <QtQml/qqml.h>

class AppState : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool wallpaperOpen  READ wallpaperOpen  WRITE setWallpaperOpen  NOTIFY wallpaperOpenChanged)
    Q_PROPERTY(bool islandOpen     READ islandOpen     WRITE setIslandOpen     NOTIFY islandOpenChanged)
    Q_PROPERTY(int  activeWallRow  READ activeWallRow  WRITE setActiveWallRow  NOTIFY activeWallRowChanged)
    Q_PROPERTY(int  staticWallIdx  READ staticWallIdx  WRITE setStaticWallIdx  NOTIFY staticWallIdxChanged)
    Q_PROPERTY(int  liveWallIdx    READ liveWallIdx    WRITE setLiveWallIdx    NOTIFY liveWallIdxChanged)

public:
    explicit AppState(QObject* parent = nullptr) : QObject(parent) {}

    static AppState* create(QQmlEngine*, QJSEngine*) {
        static AppState instance;
        return &instance;
    }

    bool wallpaperOpen() const { return m_wallpaperOpen; }
    bool islandOpen()    const { return m_islandOpen;    }
    int  activeWallRow() const { return m_activeWallRow; }
    int  staticWallIdx() const { return m_staticWallIdx; }
    int  liveWallIdx()   const { return m_liveWallIdx;   }

    void setWallpaperOpen(bool v)  { if(m_wallpaperOpen==v) return; m_wallpaperOpen=v; emit wallpaperOpenChanged(); }
    void setIslandOpen(bool v)     { if(m_islandOpen==v)    return; m_islandOpen=v;    emit islandOpenChanged();    }
    void setActiveWallRow(int v)   { if(m_activeWallRow==v) return; m_activeWallRow=v; emit activeWallRowChanged(); }
    void setStaticWallIdx(int v)   { if(m_staticWallIdx==v) return; m_staticWallIdx=v; emit staticWallIdxChanged(); }
    void setLiveWallIdx(int v)     { if(m_liveWallIdx==v)   return; m_liveWallIdx=v;   emit liveWallIdxChanged();   }

public slots:
    void toggleWallpaper() { setWallpaperOpen(!m_wallpaperOpen); }
    void toggleIsland()    { setIslandOpen(!m_islandOpen);       }

signals:
    void wallpaperOpenChanged();
    void islandOpenChanged();
    void activeWallRowChanged();
    void staticWallIdxChanged();
    void liveWallIdxChanged();

private:
    bool m_wallpaperOpen  = false;
    bool m_islandOpen     = false;
    int  m_activeWallRow  = 0;
    int  m_staticWallIdx  = 0;
    int  m_liveWallIdx    = 0;
};
