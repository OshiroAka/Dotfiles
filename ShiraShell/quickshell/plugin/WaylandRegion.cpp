#include "WaylandRegion.h"
#include <QGuiApplication>
#include <qpa/qplatformnativeinterface.h>
#include <wayland-client.h>

WaylandRegion::WaylandRegion(QObject* parent) : QObject(parent) {}

void WaylandRegion::apply(QQuickWindow* window, int x, int y, int w, int h) {
    if (!window) return;
    auto* ni = QGuiApplication::platformNativeInterface();
    if (!ni) return;
    auto* surface = static_cast<wl_surface*>(
        ni->nativeResourceForWindow("surface", window));
    auto* compositor = static_cast<wl_compositor*>(
        ni->nativeResourceForIntegration("compositor"));
    if (!surface || !compositor) return;
    wl_region* region = wl_compositor_create_region(compositor);
    wl_region_add(region, x, y, w, h);
    wl_surface_set_opaque_region(surface, region);
    wl_surface_commit(surface);
    wl_region_destroy(region);
}

void WaylandRegion::clear(QQuickWindow* window) {
    if (!window) return;
    auto* ni = QGuiApplication::platformNativeInterface();
    if (!ni) return;
    auto* surface = static_cast<wl_surface*>(
        ni->nativeResourceForWindow("surface", window));
    if (!surface) return;
    wl_surface_set_opaque_region(surface, nullptr);
    wl_surface_commit(surface);
}
