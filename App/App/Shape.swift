//
//  Shape.swift
//  App
//

import Foundation
import GLKit

class RenderContext { // Non-struct because of GLKMatrix4 (inout)
    
    var projection = GLKMatrix4()
}

protocol Shape {
    
    func draw (_ context: RenderContext)
}

class SimpleShape : Shape {

    internal func draw(_ context: RenderContext) {
    }
    
    internal init() {}
    
    var modified: Bool = true
    var position: (x: Float, y: Float) = (0.0, 0.0)
        { didSet { modified = true } }
    var scale:    Float      = 1.0
        { didSet { modified = true } }
    private var modelMatrix_ = GLKMatrix4()
    var modelMatrix: GLKMatrix4 {
        get {
            if modified {
                modified = false
                modelMatrix_ = GLKMatrix4MakeTranslation(position.x, position.y, 0)
                modelMatrix_ = GLKMatrix4Scale(modelMatrix_, scale, scale, 1.0)
            }
            return modelMatrix_
        }
    }
    var color: UIColor = .gray
    
    func prepareDraw(_ context: RenderContext, _ shader: Shader) {
        shader.enable()
        shader.matrix4fv("projection",  context.projection)
        shader.matrix4fv("modelMatrix", modelMatrix)
        let comp = color.cgColor.comp
        shader.uniform4f("color", comp.r, comp.g, comp.b, comp.a)
    }
}

class Quad : SimpleShape {

    var shader:      Shader?
    var vertexArray: VertexArray?
    var fill:        Bool
    
    init(fill: Bool = true) {
        let vertices: [Float] = [
            0, 0,
            1, 0,
            1, 1,
            0, 1].flatMap{ $0 - 0.5 }
        let subdata = [(Slot.position, VertexType.float(2), 4)]
        vertexArray = VertexArray(subdata, dynamic: false)
        vertexArray?.updateSubdata(0, vertices)
        shader = Shader("flat.vert", "flat.frag")
        self.fill = fill
    }
    
    deinit {
        shader = nil
        vertexArray = nil
    }
    
    override func draw(_ context: RenderContext) {
        guard let shader = self.shader,
            let vertexArray = self.vertexArray else {
            return
        }
        prepareDraw(context, shader)
        vertexArray.bind()
        glDrawArrays(fill ? GL_TRIANGLE_FAN<> : GL_LINE_LOOP<>, 0, 4)
    }
}

class Circle : SimpleShape {

    var shader:      Shader?
    var vertexArray: VertexArray?
    var count:       Int
    var fill:        Bool
    
    init(resolution: Int = 64, fill: Bool = true) {
        let vertices: [Float] = {
            var vv = [Float]()
            if fill {
                vv.append(0)
                vv.append(0)
            }
            let r = Float(0.5)
            for i in 0..<resolution {
                let x = r * cosf(Float(i) * Float(2.0 * M_PI) / Float(resolution))
                let y = r * sinf(Float(i) * Float(2.0 * M_PI) / Float(resolution))
                vv.append(x)
                vv.append(y)
            }
            if fill {
                vv.append(r)
                vv.append(0)
            }
            return vv
        }()
        let subdata = [(Slot.position, VertexType.float(2), vertices.count / 2)]
        vertexArray = VertexArray(subdata, dynamic: false)
        vertexArray?.updateSubdata(0, vertices)
        shader = Shader("flat.vert", "flat.frag")
        self.count = fill ? resolution + 2 : resolution
        self.fill  = fill
    }
    
    deinit {
        shader = nil
        vertexArray = nil
    }
    
    override func draw(_ context: RenderContext) {
        guard let shader = self.shader,
            let vertexArray = self.vertexArray else {
                return
        }
        prepareDraw(context, shader)
        vertexArray.bind()
        glDrawArrays(fill ? GL_TRIANGLE_FAN<> : GL_LINE_LOOP<>, 0, count<>)
    }
}

class ParticleSet : Shape {
    
    var shader:      Shader?
    var vertexArray: VertexArray?
    var count:       Int
    
    init() {
        // Particles
        particle_system_init()
        let N = 32
        let points   = particle_system_add((N * N)<>)
        let position = points.position!
        let velocity = points.velocity!
        let count     = Int(points.size)
        for i in 0 ..< count {
            let x = Float(i % (N))
            let y = Float(i / N)
            position[i * 2 + 0] = x / Float(N) - 0.5
            position[i * 2 + 1] = y / Float(N) - 0.5
            velocity[i * 2 + 0] = 0
            velocity[i * 2 + 1] = 0
        }
        
        // Shader
        shader = Shader("plain.vert", "plain.frag")
        
        // Vertex objects
        let subdata = [(Slot.position, VertexType.float(2), count),
                       (Slot.velocity, VertexType.float(2), count)]
        vertexArray = VertexArray(subdata)
        self.count = count
    }
    
    deinit {
        shader = nil
        vertexArray = nil
        particle_system_destroy();
    }
    
    func update(_ dt: Float) {
        particle_system_update(Float(dt))
        let ps       = particle_system_get(0)
        
        // Update buffers
        let position = ps.position!
        let velocity = ps.velocity!
        vertexArray?.updateSubdata(0, position)
        vertexArray?.updateSubdata(1, velocity)
    }
    
    func draw(_ context: RenderContext) {
        shader?.enable()
        shader?.matrix4fv("projection",  context.projection)
        vertexArray?.bind()
        glDrawArrays(GL_POINTS<>, 0, (count)<>)
    }
}

