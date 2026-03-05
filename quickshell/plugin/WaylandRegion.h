#pragma once
#include <QObject>
#include <QQuickWindow>
#include <wayland-client.h>

class WaylandRegion : public QObject {
    Q_OBJECT
public:
    explicit WaylandRegion(QObject* parent = nullptr);
    // Recebe QQuickWindow que e o tipo real do Quickshell
    Q_INVOKABLE void apply(QQuickWindow* window, int x, int y, int w, int h);
    Q_INVOKABLE void clear(QQuickWindow* window);
};
