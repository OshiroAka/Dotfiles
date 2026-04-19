#include <QQmlExtensionPlugin>
#include "AppState.hpp"

class ShiraOSPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)
public:
    void registerTypes(const char* uri) override {
        Q_UNUSED(uri)
    }
};

#include "plugin.moc"
