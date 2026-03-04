#include <QQmlExtensionPlugin>
#include <QQmlEngine>
#include "WaylandRegion.h"

class OshiroPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)
public:
    void registerTypes(const char* uri) override {
        qmlRegisterType<WaylandRegion>(uri, 1, 0, "WaylandRegion");
    }
};
#include "Plugin.moc"
