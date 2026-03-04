#pragma once
#include <QObject>
#include <QWindow>

class WaylandRegion : public QObject {
    Q_OBJECT
public:
    explicit WaylandRegion(QObject* parent = nullptr);
    Q_INVOKABLE void apply(QWindow* window, int x, int y, int w, int h);
    Q_INVOKABLE void clear(QWindow* window);
};
