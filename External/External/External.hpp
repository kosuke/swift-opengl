//
//  external.hpp
//

#ifndef external_hpp
#define external_hpp

#include <stdio.h>
#include <vector>

namespace ext {
 
class PointSet {
public:
    PointSet(size_t size);
    size_t size() const { return size_; }
    std::vector<float>& position() { return position_; }
    std::vector<float>& velocity() { return velocity_; }
    void update(float dt);

private:
    size_t size_;
    std::vector<float> position_;
    std::vector<float> velocity_;
};

class ParticleSystem {
public:
    ParticleSystem();
    void update(float dt);
    size_t    size() const  { return sets_.size(); }
    PointSet& get(size_t i) { return *sets_[i];    }
    PointSet& add(size_t size);
    bool remove(size_t i);
    
private:
    std::vector<std::unique_ptr<PointSet>> sets_;
};
    
}

#endif /* external_hpp */
