//
//  ViewController.swift
//  App
//

import UIKit
import GLKit

postfix operator <>

// MARK: Type conversion operators for GL constants

postfix func <>(value: Int32) -> GLenum {
    return GLuint(value)
}

postfix func <>(value: Int32) -> GLboolean {
    return GLboolean(UInt8(value))
}

postfix func <>(value: Int) -> GLubyte {
    return GLubyte(value)
}

postfix func <>(value: Int32) -> Int {
    return Int(value)
}

postfix func <>(value: Int) -> Int32 {
    return Int32(value)
}

postfix func <>(value: Bool) -> GLboolean {
    return GLboolean(value ? 1 : 0)
}

// MARK: -

class ViewController: GLKViewController, GLKViewControllerDelegate {
    
    var program:      GLuint = 0
    var vertexArray:  GLuint = 0
    var vertexBuffer: GLuint = 0
    var projection = GLKMatrix4()
    var projectionLocation: GLint = 0
    
    struct Slot {
        static let position:  GLuint = 0
        static let velocity:  GLuint = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.delegate = self
        let view = super.view as! GLKView
        view.context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(view.context)
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
    
    
    func prepare() {
        // Particles
        particle_system_init()
        let N = 96
        let points   = particle_system_add((N * N)<>)
        let position = points.position!
        let velocity = points.velocity!
        let size     = Int(points.size)
        for i in 0 ..< size {
            let x = Float(i % (N))
            let y = Float(i / N)
            position[i * 3 + 0] = x / Float(N) - 0.5
            position[i * 3 + 1] = y / Float(N) - 0.5
            position[i * 3 + 2] = 0
            velocity[i * 3 + 0] = 0
            velocity[i * 3 + 1] = 0
            velocity[i * 3 + 2] = 0
        }
        // Shader
        guard let p = loadProgram("plain.vert", "plain.frag") else {
           return
        }
        program = p
        projectionLocation = glGetUniformLocation(program, "projection")
        // Vertex objects
        guard let v = loadVertexBuffer(size) else {
           return
        }
        (vertexArray, vertexBuffer) = v
        // Projecton Matrix
        let w = view.frame.size.width;
        let h = view.frame.size.height;
        let aspect = Float(w / h)
        glViewport(0, 0, GLsizei(w), GLsizei(h))
        projection = GLKMatrix4MakeOrtho(-aspect, aspect, -1, 1, -1, 1)
        // View
        glEnable(GL_BLEND<>)
        glBlendFunc(GL_SRC_ALPHA<>, GL_ONE_MINUS_SRC_ALPHA<>)
    }
    
    func dispose() {
        glDeleteProgram(program)
        glDeleteVertexArrays(1, &vertexArray)
        glDeleteBuffers(1, &vertexBuffer)
        particle_system_destroy();
    }
    
    // MARK: Shader
    
    func loadProgram(_ vertex: String, _ fragment: String) -> GLuint? {
        guard let vert = compileShader(vertex, "", type: GL_VERTEX_SHADER<>) else {
            NSLog("Failed to complie vertex shader")
            return nil
        }
        defer {
            glDeleteShader(vert)
        }
        guard let frag = compileShader(fragment, "", type: GL_FRAGMENT_SHADER<>) else {
            NSLog("Failed to complie fragment shader")
            return nil
        }
        defer {
            glDeleteShader(frag)
        }
        let program: GLuint = glCreateProgram()
        glAttachShader(program, vert)
        glAttachShader(program, frag)
        glLinkProgram(program)
        var error: GLint = 0
        var log = [GLchar](repeating: 0, count: 1024)
        glGetProgramiv(program, GL_LINK_STATUS<>, &error)
        if error == GL_FALSE {
            NSLog("Failed to link shader program")
            glGetShaderInfoLog(program, 1024, nil, &log)
            NSLog(String(cString: log))
            return nil
        }
        return program
    }
    
    func compileShader(_ name: String, _ ext: String, type: GLenum) -> GLuint? {
        let path = Bundle.main.path(forResource: name, ofType: ext)!
        let source = try! String(contentsOfFile: path, encoding: String.Encoding.utf8)
        let shader: GLuint = glCreateShader(type)
        guard shader != 0 else {
            NSLog("Failed to create shader")
            return nil
        }
        source.withCString {
            var s: UnsafePointer<GLchar>? = $0
            glShaderSource(shader, 1, &s, nil)
        }
        glCompileShader(shader)
        var error: GLint = 0
        var log = [GLchar](repeating: 0, count: 1024)
        glGetShaderiv(shader, GL_COMPILE_STATUS<>, &error)
        guard error == GL_TRUE else {
            glGetShaderInfoLog(shader, 1024, nil, &log)
            NSLog("Failed to compile shader")
            NSLog(String(cString: log))
            glDeleteShader(shader)
            return nil
        }
        return shader
    }
    
    // MARK: Vertex
    
    func loadVertexBuffer(_ count: Int) -> (vao: GLuint, vb: GLuint)? {
        var vao: GLuint = 0
        var vb:  GLuint = 0
        let stride  = MemoryLayout<GLfloat>.stride * 3
        let size    = stride * count * 2 //(pos, vel)
        glGenVertexArrays(1, &vao)
        glBindVertexArray(vao)
        glGenBuffers(1, &vb)
        glBindBuffer(GL_ARRAY_BUFFER<>, vb)
        glBufferData(GL_ARRAY_BUFFER<>, size, nil, GL_STREAM_DRAW<>)
        glVertexAttribPointer(Slot.position, 3, GL_FLOAT<>, false<>, stride<>,
                              nil)
        glVertexAttribPointer(Slot.velocity, 3, GL_FLOAT<>, false<>, stride<>,
                              UnsafeRawPointer(bitPattern: stride * count))
        glEnableVertexAttribArray(Slot.position)
        glEnableVertexAttribArray(Slot.velocity)
        glBindVertexArray(0)
        glBindBuffer(GL_ARRAY_BUFFER<>, 0)
        return (vao, vb)
    }
    
    // MARK: - Loop functions
    
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        // Update
        let dt = self.timeSinceLastUpdate
        particle_system_update(Float(dt))
        let ps       = particle_system_get(0)
        // Update buffers
        let count     = Int(ps.size)
        let position = ps.position!
        let velocity = ps.velocity!
        let stride   = MemoryLayout<GLfloat>.stride * 3
        glBindVertexArray(vertexArray)
        glBindBuffer(GL_ARRAY_BUFFER<>, vertexBuffer)
        glBufferSubData(GL_ARRAY_BUFFER<>, 0,
                        stride * count, position)
        glBufferSubData(GL_ARRAY_BUFFER<>, stride * count,
                        stride * count, velocity)
        glBindBuffer(GL_ARRAY_BUFFER<>, 0)
        glBindVertexArray(0)
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        // Clear
        glClearColor(0.0, 0.0, 0.0, 0.0)
        glClear((GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)<>);
        // Draw
        glUseProgram(program)
        withUnsafePointer(to: &projection.m) {
            let m = UnsafeRawPointer($0)
            glUniformMatrix4fv(projectionLocation, 1, false<>,
                               m.assumingMemoryBound(to: GLfloat.self))
        }
        // Points
        let ps   = particle_system_get(0)
        let size = Int(ps.size)
        glBindVertexArray(vertexArray)
        glDrawArrays(GL_POINTS<>, 0, (size)<>)
        glBindVertexArray(0)
        glUseProgram(0)
    }
}
