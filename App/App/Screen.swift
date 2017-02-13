//
//  Screen.swift
//  App
//

import Foundation
import GLKit

protocol Screen {
    func resized(_ width: Int, _ height: Int)
    func capture()
    func draw()
}

class DefaultScreen : Screen {

    var width:  Int = 0
    var height: Int = 0
    var shader:  Shader
    var quad:    Quad
    var texture: Texture?
    
    var fbo0:    GLuint = 0
    var fbo:     GLuint = 0
    var rbo:     GLuint = 0 // Currently unused
    
    init() {
        glGenFramebuffers(1, &fbo)
        glGenRenderbuffers(1, &rbo)
        
        // Postprocess shader
        shader = Shader("screen.vert", "screen.frag")!
        quad   = Quad(fill: true, useTexture: true, shader: shader)
        texture = nil
    }
    
    deinit {
        glDeleteFramebuffers(1, &fbo)
        glDeleteRenderbuffers(1, &rbo)
    }
    
    func resized(_ width: Int, _ height: Int) {
        self.width  = width
        self.height = height
        
        // Switch Framebuffer
        self.fbo0 = {
            var i = GLint(0)
            glGetIntegerv(GL_FRAMEBUFFER_BINDING<>, &i)
            return GLuint(i)
        }()
        
        // Texture
        texture = Texture(width, height)!
        
        // Frame buffer
        glBindFramebuffer(GL_FRAMEBUFFER<>, fbo)
        glFramebufferTexture2D(GL_FRAMEBUFFER<>, GL_COLOR_ATTACHMENT0<>,
                               GL_TEXTURE_2D<>, texture!.id, 0)
        
        let status = glCheckFramebufferStatus(GL_FRAMEBUFFER<>)
        if status != GL_FRAMEBUFFER_COMPLETE<> {
            assertionFailure("Incomplete framebuffer: " + String(status))
        }
        glBindFramebuffer(GL_FRAMEBUFFER<>, fbo0)
    }
    
    func capture() {
        glEnable(GL_DEPTH_TEST<>)
        glBindFramebuffer(GL_FRAMEBUFFER<>, fbo)
    }
    
    func draw() {
        glDisable(GL_DEPTH_TEST<>)
        glBindFramebuffer(GL_FRAMEBUFFER<>, fbo0)
        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(GL_COLOR_BUFFER_BIT<>);
        
        guard let texture = self.texture else {
            return
        }
        glActiveTexture(GL_TEXTURE0<> + 0)
        texture.bind()
        shader.enable()
        shader.uniform1i("tex", 0)
        quad.draw()
    }
}


class MultisampleScreen : Screen {
    
    var shader:  Shader
    var quad:    Quad
    var texture: Texture?
    var width:   Int = 0
    var height:  Int = 0

    var fbo0:    GLuint = 0
    var sample:  (fbo: GLuint, color: GLuint) = (0, 0)
    var resolve: (fbo: GLuint, color: GLuint) = (0, 0) // color currently is unused
    
    init() {
        glGenFramebuffers(1, &sample.fbo)
        glGenRenderbuffers(1, &sample.color)
        glGenFramebuffers(1, &resolve.fbo)
        glGenRenderbuffers(1, &resolve.color)
        
        // Postprocess shader
        shader = Shader("screen.vert", "screen.frag")!
        quad   = Quad(fill: true, useTexture: true, shader: shader)
        texture = nil
    }
    
    deinit {
        glDeleteFramebuffers(1, &sample.fbo)
        glDeleteRenderbuffers(1, &sample.color)
        glDeleteFramebuffers(1, &resolve.fbo)
        glDeleteRenderbuffers(1, &resolve.color)
    }
    
    func resized(_ width: Int, _ height: Int) {
        self.width  = width
        self.height = height
        
        // Switch Framebuffer
        self.fbo0 = {
            var i = GLint(0)
            glGetIntegerv(GL_FRAMEBUFFER_BINDING<>, &i)
            return GLuint(i)
        }()
        
        // Texture
        texture = Texture(width, height)!
        
        // "Resolve" frame buffer (Texture attached)
        glBindFramebuffer(GL_FRAMEBUFFER<>, resolve.fbo)
        glFramebufferTexture2D(GL_FRAMEBUFFER<>, GL_COLOR_ATTACHMENT0<>,
                               GL_TEXTURE_2D<>, texture!.id, 0)
        
        // Multisample color render buffer
        glBindFramebuffer(GL_FRAMEBUFFER<>, sample.fbo)
        glBindRenderbuffer(GL_RENDERBUFFER<>, sample.color)
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER<>, 4, GL_RGBA8<>,
                                              width<>, height<>)
        glFramebufferRenderbuffer(GL_FRAMEBUFFER<>, GL_COLOR_ATTACHMENT0<>,
                                  GL_RENDERBUFFER<>, sample.color)
        
        let status = glCheckFramebufferStatus(GL_FRAMEBUFFER<>)
        if status != GL_FRAMEBUFFER_COMPLETE<> {
            assertionFailure("Incomplete framebuffer: " + String(status))
        }
        glBindFramebuffer(GL_FRAMEBUFFER<>, fbo0)
    }
    
    func capture() {
        glEnable(GL_DEPTH_TEST<>)
        glBindFramebuffer(GL_FRAMEBUFFER<>, sample.fbo)
    }
    
    func draw() {
        // "Resolve" : sample -> resolve
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE<>, resolve.fbo)
        glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE<>, sample.fbo)
        // glResolveMultisampleFramebufferAPPLE() is deprecated in ES 3.0
        glBlitFramebuffer(0, 0, width<>, height<>, 0, 0, width<>, height<>,
                          GL_COLOR_BUFFER_BIT<>, GL_NEAREST<>);
        var discards: GLuint = GL_COLOR_ATTACHMENT0<>
        glInvalidateFramebuffer(GL_READ_FRAMEBUFFER_APPLE<>, 1, &discards)
        
        // Draw texture
        glDisable(GL_DEPTH_TEST<>)
        glBindFramebuffer(GL_FRAMEBUFFER<>, fbo0)
        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(GL_COLOR_BUFFER_BIT<>);
        
        guard let texture = self.texture else {
            return
        }
        glActiveTexture(GL_TEXTURE0<> + 0)
        texture.bind()
        shader.enable()
        shader.uniform1i("tex", 0)
        quad.draw()
    }
}
