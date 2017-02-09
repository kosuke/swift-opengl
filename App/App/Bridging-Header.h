//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include "Wrapper.hpp"

void     particle_system_init();
void     particle_system_destroy();
int      particle_system_count();
PointSet particle_system_get(int i);
PointSet particle_system_add(int size);
void     particle_system_update(float dt);
