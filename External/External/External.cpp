//
//  external.cpp
//


#include <cassert>
#include <cmath>
#include <memory>
#include "External.hpp"

namespace ext {
    
    PointSet::PointSet(std::size_t size)
    : size_(size)
    , position_(size * 3)
    , velocity_(size * 3) {
    }
    
    ParticleSystem::ParticleSystem() {
    }
    
    PointSet& ParticleSystem::add(size_t size) {
        auto&& ps = std::make_unique<PointSet>(size);
        auto& result = *ps;
        sets_.emplace_back(std::move(ps));
        return result;
    }
    
    bool ParticleSystem::remove(size_t i) {
        if (i < sets_.size()) {
            sets_.erase(sets_.begin() + i);
            return true;
        }
        return false;
    }
    
    template<typename T>
    inline static T dot(T x, T y) {
        return x * x + y * y;
    }

    template<typename T>
    inline static void euler(T k, T dt, T& x, T& y, T& vx, T& vy) {
        auto r2 = x * x + y * y;
        auto r = sqrt(r2);
        auto f = k / r2;
        auto impulse = f * dt;
        vx -= impulse * (x / r);
        vy -= impulse * (y / r);
        x += vx * dt;
        y += vy * dt;
    }

    template<typename T>
    inline static void rk2(T k, T dt, T dt2, T& x, T& y, T& vx, T& vy) {
        // 0
        auto r20   = dot(x, y);
        auto r0    = sqrt(r20);
        auto f0    = k / r20;
        auto imp0  = f0 * dt2;
        auto vy0   = vy - imp0 * (y / r0);
        auto y0    = y + dt2 * vy0;
        auto vx0   = vx - imp0 * (x / r0);
        auto x0    = x + dt2 * vx0;
        // 1
        auto r21   = dot(x0, y0);
        auto r1    = sqrt(r21);
        auto f1    = k / r21;
        auto imp1  = f1 * dt2;
        vx -= imp1 * (x0/r1);
        vy -= imp1 * (y0/r1);
        x += vx * dt;
        y += vy * dt;
    }

    
    void ParticleSystem::update(float dt) {
        const float G = 1.0e-4f; // Nonsense
        const float M = 1.0f;
        const float K = G * M;
        //const float dt2 = dt/2;
        for (auto& ps : sets_) {
            auto& pp = ps->position();
            auto& vv = ps->velocity();
            for(auto i = 0; i < ps->size(); ++i) {
                auto& x  = pp[i * 3 + 0];
                auto& y  = pp[i * 3 + 1];
                auto& vx = vv[i * 3 + 0];
                auto& vy = vv[i * 3 + 1];
                euler(K, dt, x, y, vx, vy);
                //rk2(K, dt, dt2, x, y, vx, vy);
            }
        }
    }
}
