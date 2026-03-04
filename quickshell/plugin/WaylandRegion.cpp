#include "WaylandRegion.h"
#include <QGuiApplication>
#include <qpa/qplatformnativeinterface.h>
#include <wayland-client.h>

WaylandRegion::WaylandRegion(QObject* parent) : QObject(parent) {}

static wl_surface* getSurface(QWindow* w) {
    return static_cast<wl_surface*>(
        QGuiApplication::platformNativeInterface()
            ->nativeResourceForWindow("surface", w));
}

static wl_compositor* getCompositor() {
    return static_cast<wl_compositor*>(
        QGuiApplication::platformNativeInterface()
            ->nativeResourceForIntegration("compositor"));
}

void WaylandRegion::apply(QWindow* window, int x, int y, int w, int h) {
    if (!window) return;
    auto* surface    = getSurface(window);
    auto* compositor = getCompositor();
    if (!surface || !compositor) return;
    wl_region* region = wl_compositor_create_region(compositor);
    wl_region_add(region, x, y, w, h);
    wl_surface_set_opaque_region(surface, region);
    wl_surface_commit(surface);
    wl_region_destroy(region);
}

void WaylandRegion::clear(QWindow* window) {
    if (!window) return;
    auto* surface = getSurface(window);
    if (!surface) return;
    wl_surface_set_opaque_region(surface, nullptr);
    wl_surface_commit(surface);
}
