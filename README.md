# NOTE this is an active WIP

# BMax-Shader-Framework
Blitzmax shader framework

This module should be placed into a 'BLITZMAX_INSTALL/mod/srs.mod/shaderframework.mod/' folder.


# Goals
The end goal of the module is to allow standard shader support for the standard GL, D3D9 and D3D11 graphics contexts while
using a single unified command set.


# Examples
Most examples will be to show how you use the framework to set your uniforms/constants in your shader code. Hopefully they will also be interesting and cool enough to encourage you in to learning the world of shaders. There are many great effects available online that should be easily portable into BMax using this framework.

Example1. shows a swirl effect using a default vertex shader that can be applied to all sprites and a pixel shader for the effect.
    Use the Left and Right arrow keys to create a cool swirly pattern.
    
Example2. shows a technique of using a regular diffuse texture and normal map texture to create a more advanced 3D lighting effect but in 2D. Move the mouse to move the light. There are several parameters that can be changed such as color and attenuation, distance of the light to the 'surface' plus a couple more.


# Reserved variable names
I'm looking into using some reserved words for some shader variables to make interaction with Max2D easier. The idea is that you don't have to worry about them yourself and they will be set automatically when the shader is 'Set' to be used. As the project evolves there may be more of these that get included. Currently there is just one.

BMaxProjectionMatrix
    This shader uniform/constant will be automatically set to the current projection matrix that's being used in Max2D.

When using a shader that has a 'reservered name' as above: If you change resolution, change virtual resolution then use the TShaderFramework member method 'ResetMax2DDefaults()' in order to tell the framework that it will need to update the reserved word values.
