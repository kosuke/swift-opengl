//
//  Wrapper.c
//  App 
//

#include <memory>
#include "External.hpp"
#include "Wrapper.hpp"

namespace {
    std::unique_ptr<ext::ParticleSystem> system;
}

extern "C" void particle_system_init() {
    system = std::make_unique<ext::ParticleSystem>();
}

extern "C" void particle_system_destroy() {
    system.reset();
}


extern "C" int particle_system_count() {
    return static_cast<int>(system->size());
}

extern "C" PointSet particle_system_add(int size) {
    auto& ps = system->add(size);
    PointSet result{static_cast<int>(ps.size()), &ps.position()[0], &ps.velocity()[0]};
    return result;
}

extern "C" PointSet particle_system_get(int i) {
    auto& ps = system->get(i);
    PointSet result{static_cast<int>(ps.size()), &ps.position()[0], &ps.velocity()[0]};
    return result;
}

extern "C" void particle_system_update(float dt) {
    system->update(dt);
}
