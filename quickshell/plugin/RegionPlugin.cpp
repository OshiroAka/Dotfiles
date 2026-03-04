#include <QQmlExtensionPlugin>
#include <QQmlEngine>
#include "WaylandRegion.h"

class RegionPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)
public:
    void registerTypes(const char* uri) override {
        // Disponivel em QML como: import OshiroShell 1.0
        qmlRegisterType<WaylandRegion>(uri, 1, 0, "WaylandRegion");
    }
};

#include "RegionPlugin.moc"
