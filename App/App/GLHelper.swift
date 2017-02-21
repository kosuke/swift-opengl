//
//  GLHelper.swift
//  App
//

import Foundation
import GLKit

// MARK: Type conversion operators for GL constants

postfix operator <>

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

// MARK: Other extensions for easier conversions

extension CGColor {
    var comp: (r: Float, g: Float, b: Float, a: Float) {
        get {
            switch (self.numberOfComponents) {
            case 2:
                let c = Float(self.components![0])
                return (c, c, c, Float(self.alpha))
            case 4:
                if let c = self.components {
                    return (Float(c[0]), Float(c[1]), Float(c[2]), Float(c[3]))
                }
            default: break
            }
            assertionFailure("Could not extract RGB value")
            return (0.0, 0.0, 0.0, 1.0)
        }
    }
}

// MARK: -

struct Slot {
    static let position:  GLuint = 0
    static let velocity:  GLuint = 1
    static let texture:   GLuint = 1
}

class Shader {

    struct Uniform {
        let name:     String
        let location: GLint
        let size:     GLint
        let type:     GLenum
    }
    
    let program: GLuint
    var uniforms = [String: Uniform]()
    
    deinit { glDeleteProgram(program) }
    
    init?(_ vertex: String, _ fragment: String) {
        guard let vert = Shader.compile(vertex, "", type: GL_VERTEX_SHADER<>) else {
            NSLog("Failed to complie vertex shader")
            return nil
        }
        defer {
            glDeleteShader(vert)
        }
        guard let frag = Shader.compile(fragment, "", type: GL_FRAGMENT_SHADER<>) else {
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
        var success: GLint = 0
        var log = [GLchar](repeating: 0, count: 1024)
        glGetProgramiv(program, GL_LINK_STATUS<>, &success)
        guard success == GL_TRUE else {
            NSLog("Failed to link shader program")
            glGetShaderInfoLog(program, 1024, nil, &log)
            NSLog(String(cString: log))
            return nil
        }
        
        // Uniforms
        var active: GLint = 0;
        glGetProgramiv(program, GL_ACTIVE_UNIFORMS<>, &active)
        for i in 0..<active {
            var length: GLint  = 0
            var size:   GLint  = 0
            var type:   GLenum = 0
            var name = [GLchar](repeating: 0, count: 1024)
            glGetActiveUniform(program, GLuint(i), 1024, &length,
                               &size, &type, &name);
            let location = glGetUniformLocation(program, name)
            let key = String(cString: name)
            uniforms[key] = Uniform(name: key, location: location,
                                    size: size, type: type)
        }
        self.program = program
    }
    
    class func compile(_ name: String, _ ext: String, type: GLenum) -> GLuint? {
        let path = Bundle.main.path(forResource: name, ofType: ext)!
        let source = try! String(contentsOfFile: path, encoding: String.Encoding.utf8)
        let shader: GLuint = glCreateShader(type)
        guard shader != 0 else {
            NSLog("Failed to create shader: " + name)
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
            NSLog("Failed to compile shader: ")
            NSLog(String(cString: log))
            glDeleteShader(shader)
            return nil
        }
        return shader
    }

    func enable() {
        glUseProgram(program)
    }
    
    func getUniform(_ name: String) -> Uniform? {
        guard let uniform =  uniforms[name] else {
            assertionFailure("Uniform not found: " + name)
            return nil
        }
        return uniform
    }
    
    func uniform1i(_ name: String, _ i: Int) {
        guard let uniform = getUniform(name) else {
            return
        }
        glUniform1i(uniform.location, i<>)
    }

    func uniform1f(_ name: String, _ f: Float) {
        guard let uniform = getUniform(name) else {
            return
        }
        glUniform1f(uniform.location, f)
    }

    func uniform4f(_ name: String, _ x: Float, _ y: Float, _ z: Float, _ w: Float) {
        guard let uniform = getUniform(name) else {
            return
        }
        glUniform4f(uniform.location, x, y, z, w)
    }
    
    func matrix4fv(_ name: String, _ matrix: GLKMatrix4) {
        guard let uniform = getUniform(name) else {
            return
        }
        var temp = ( // Because Swift 3...
            matrix.m00, matrix.m01, matrix.m02, matrix.m03,
            matrix.m10, matrix.m11, matrix.m12, matrix.m13,
            matrix.m20, matrix.m21, matrix.m22, matrix.m23,
            matrix.m30, matrix.m31, matrix.m32, matrix.m33
        )
        withUnsafePointer(to: &temp) {
            let m = UnsafeRawPointer($0)
            glUniformMatrix4fv(uniform.location, 1, false<>,
                               m.assumingMemoryBound(
                                to: GLfloat.self))
        }
    }
}


// MARK: -

enum VertexType {
    case float(Int)
    case int  (Int)
    case ubyte (Int)
    
    var gl: GLenum {
        switch self {
        case .float: return GL_FLOAT<>
        case .int:   return GL_INT<>
        case .ubyte: return GL_UNSIGNED_BYTE<>
        }
    }
    
    var comp: Int {
        switch self {
        case let .float(c): return c
        case let .int  (c): return c
        case let .ubyte(c): return c
        }
    }
    
    var stride: Int {
        switch self {
        case let .float(c): return c * MemoryLayout<GLfloat>.stride
        case let .int  (c): return c * MemoryLayout<GLint>.stride
        case let .ubyte(c): return c * MemoryLayout<GLubyte>.stride
        }
    }
    
    var norm: GLboolean { // Requires normalization
        switch self {
        case .float: return false<>
        case .int:   return false<>
        case .ubyte: return true<>
        }
    }
}

class VertexArray {
    
    typealias Subdata = (slot: GLuint, type: VertexType, size: Int, offset: Int)
    
    var vao: GLuint = 0
    var vb:  GLuint = 0
    let type = GLfloat.self
    let subs: [Subdata]
    
    
    deinit {
        glDeleteVertexArrays(1, &vao)
        glDeleteBuffers(1, &vb)
    }
    
    init? (_ subdata: [(slot: GLuint, type: VertexType, size: Int)],
           dynamic: Bool = true) {
        var vao: GLuint = 0
        var vb:  GLuint = 0
        let size = subdata.reduce(0) { $0 + $1.size * $1.type.stride }
        glGenVertexArrays(1, &vao)
        glBindVertexArray(vao)
        glGenBuffers(1, &vb)
        glBindBuffer(GL_ARRAY_BUFFER<>, vb)
        glBufferData(GL_ARRAY_BUFFER<>, size, nil,
                     dynamic ? GL_DYNAMIC_DRAW<> : GL_STREAM_DRAW<>)
        
        // Subdata
        var offset = 0
        var subs   = [Subdata]()
        for s in subdata {
            let pointer = offset == 0 ? nil : UnsafeRawPointer(bitPattern: offset)
            glVertexAttribPointer(s.slot, s.type.comp<>, s.type.gl, s.type.norm,
                                  s.type.stride<>, pointer)
            glEnableVertexAttribArray(s.slot)
            subs.append((s.slot, s.type, s.size, offset))
            offset += s.type.stride * s.size
        }
        glBindVertexArray(0)
        glBindBuffer(GL_ARRAY_BUFFER<>, 0)
        self.vao = vao
        self.vb  = vb
        self.subs = subs
    }
    
    func bind() {
        glBindVertexArray(vao)
    }
    
    func updateSubdata(_ index: Int, _ data: UnsafeRawPointer) {
        updateSubdata(index, data, subs[index].size)
    }
    
    func updateSubdata(_ index: Int, _ data: UnsafeRawPointer, _ size: Int) {
        let sub = subs[index]
        glBindBuffer(GL_ARRAY_BUFFER<>, vb)
        glBufferSubData(GL_ARRAY_BUFFER<>, sub.offset,
                        sub.type.stride * size, data)
        glBindBuffer(GL_ARRAY_BUFFER<>, 0)
    }
}

class Texture {
    
    var tex: GLuint = 0
    
    var id: GLuint { get { return tex } }
    
    deinit {
        glDeleteTextures(1, &tex)
    }
    
    init? (_ width: Int, _ height: Int) {
        var tex: GLuint = 0
        glGenTextures(1, &tex)
        glBindTexture(GL_TEXTURE_2D<>, tex)
        glTexImage2D(GL_TEXTURE_2D<>, 0, GL_RGBA8, width<>, height<>,
                     0, GL_RGBA<>, GL_UNSIGNED_BYTE<>, nil)
        glTexParameteri(GL_TEXTURE_2D<>, GL_TEXTURE_MIN_FILTER<>, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D<>, GL_TEXTURE_MAG_FILTER<>, GL_LINEAR)
        glBindTexture(GL_TEXTURE_2D<>, 0)
        self.tex = tex
    }
    
    func bind() {
        glBindTexture(GL_TEXTURE_2D<>, tex)
    }
}
