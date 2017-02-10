//
//  ViewController.swift
//  App
//

import UIKit
import GLKit


// MARK: -

class ViewController: GLKViewController, GLKViewControllerDelegate {
    
    var context = RenderContext()
    var shapes  = [Shape]()
    weak var quad:      Quad?
    weak var particles: ParticleSet?
    var needsResize: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.delegate = self
        
        // View
        let view = super.view as! GLKView
        view.context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(view.context)
        view.drawableMultisample = .multisample4X
        
        // Gesture
        view.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(
            target: self,
            action: #selector(ViewController.tapped))
        view.addGestureRecognizer(gesture)
    }
    
    func tapped(_ sender: UITapGestureRecognizer) {
        // Reset particles
        if let index = shapes.index(where: { ($0 as? ParticleSet) != nil }) {
            shapes.remove(at: index)
            let particles = ParticleSet()
            self.particles = particles
            shapes.append(particles)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepare()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dispose()
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        print("Trans")
        needsResize = true
    }
    
    func prepare() {
        // Quad
        let quad = Quad()
        quad.scale = 0.1
        quad.position = (0.0, 0.0)
        self.quad = quad
        shapes.append(quad)
        
        // Shapes
        let N = 30
        for i in 0..<N {
            let shape: SimpleShape = {
                switch(i % 4) {
                case 0:  return Circle()
                case 1:  return Circle(fill: false)
                case 2:  return Quad()
                default: return Quad(fill: false)
                }
            }()
            let theta = Float(i) / Float(N)  * 2.0 * Float(M_PI)
            let x = 0.5 * cosf(theta)
            let y = 0.5 * sinf(theta)
            shape.position = (x, y)
            shape.scale = 0.05
            shape.color = UIColor(red:   CGFloat(2.0 * x),
                                  green: CGFloat(2.0 * y),
                                  blue:  0.8,
                                  alpha: 0.8)
            shapes.append(shape)
        }
        
        // Particle
        let particles = ParticleSet()
        self.particles = particles
        shapes.append(particles)
        
        // Projecton Matrix
        let w = view.frame.size.width;
        let h = view.frame.size.height;
        let aspect = Float(w / h)
        glViewport(0, 0, GLsizei(w), GLsizei(h))
        context.projection = GLKMatrix4MakeOrtho(-aspect, aspect,
                                                 -1, 1, -1, 1)
        // View
        glEnable(GL_BLEND<>)
        glBlendFunc(GL_SRC_ALPHA<>, GL_ONE_MINUS_SRC_ALPHA<>)
    }
    
    func dispose() {
        shapes.removeAll(keepingCapacity: true)
    }
    
    // MARK: - Loop functions
    
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        // Update
        let dt = Float(self.timeSinceLastUpdate)
        
        // Particle
        particles?.update(dt)
        
        // Fake random walk
        let rand = { (Float(arc4random() % 65536) / 65536.0 - 0.5) }
        guard let quad = self.quad else {
            return
        }
        quad.position.x += 0.005 * rand()
        quad.position.y += 0.005 * rand()
        
        // Circles are subtler
        for shape in shapes {
            if let circle = shape as? Circle {
                circle.position.x += 0.001 * rand()
                circle.position.y += 0.001 * rand()
            }
        }
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        // Clear
        glClearColor(0.1, 0.1, 0.1, 0.0)
        glClear((GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)<>);
        
        // Resize
        if needsResize {
            needsResize = false
            // Projecton Matrix
            let w = view.frame.size.width;
            let h = view.frame.size.height;
            let aspect = Float(w / h)
            glViewport(0, 0, GLsizei(w), GLsizei(h))
            context.projection = GLKMatrix4MakeOrtho(-aspect, aspect,
                                                     -1, 1, -1, 1)
        }
        
        // Draw
        for shape in shapes {
            shape.draw(context)
        }
        glBindVertexArray(0)
        glUseProgram(0)
    }
}
