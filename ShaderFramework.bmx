
Strict

Module SRS.ShaderFramework
Import "TGLShaderFramework.bmx"


Private
Global _ShaderFramework:TShaderFramework
Public

Function CreateShaderFramework:TShaderFramework(gc:TGraphics)
	Local max2d:TMax2DGraphics = TMax2DGraphics(gc)

	' sanity check
	?debug
	Assert max2d <> Null
	?

	?win32
	'If TD3D9Graphics(max2d._graphics) Return New TD3D9ShaderFrameworkt.Create(max2d._graphics)
	'If TD3D11Graphics(max2d._graphics) Return New TD3D11ShaderFramework.Create(max2d._graphics)
	?
	If TGLGraphics(max2d._graphics) Return New TGLShaderFramework
	
	Return Null
EndFunction
