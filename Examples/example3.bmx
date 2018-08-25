
Strict

Import srs.shaderframework
SetGraphicsDriver GLMax2DDriver()

Local g:TGraphics = Graphics(940,350)
Local max2dg:TMax2DGraphics = TMax2DGraphics(g)

Local vsource:String = GLSLVertexShaderSource()
Local psource:String = GLSLPixelShaderSource()

' Create an instance of the shader framework with the max2d graphics context
Local sf:TShaderFramework = CreateShaderFramework(g)
Local vertexshader:TVertexShader = sf.CreateVertexShader(vsource)
Local pixelshader:TPixelShader = sf.CreatePixelShader(psource)
Local myShader:TShaderProgram = sf.CreateShaderProgram(vertexshader, pixelshader)

Local image_pic0047:TImage = LoadImage("pic0047.png")
DrawImage(image_pic0047, 0, 0) ' this is a crap way to make sure the TImage texture really is created
Local pic0047:TShaderSampler = myShader.GetShaderSampler("pic0047")

Local image_pic0048:TImage = LoadImage("pic0048.png")
DrawImage(image_pic0048, 0, 0) ' this is a crap way to make sure the TImage texture really is created
Local pic0048:TShaderSampler = myShader.GetShaderSampler("pic0048")

pic0047.SetIndex(0, image_pic0047)
pic0048.SetIndex(1, image_pic0048)

While Not KeyDown(KEY_ESCAPE)
	Cls

	DrawText("Multi-texturing in the shader", 0, 0)
	
	DrawImage(image_pic0047, 25, 50)
	DrawImage(image_pic0048, 340, 50)
	
	SetScale(2, 2)
	DrawText("x", 300, 155)
	DrawText("=", 610, 155)
	SetScale(1, 1)
	
	' activate shader
	sf.SetShader(myShader)
	
	DrawImage(image_pic0047, 650, 50)
	
	' turn off the shader and go back to the fixed function pipeline
	sf.SetShader(Null)

	Flip(1)
Wend


Function GLSLVertexShaderSource:String()
	Local source:String
	source :+ "#version 120~n"
	
	source :+ "varying vec4 var_color;~n"
	source :+ "varying vec2 var_uv;~n"
	
	source :+ "void main() {~n"
	source :+ "   gl_Position = ftransform();~n"
	source :+ "   var_color = gl_Color;~n"				' set the var_color varying to the color set in Max2D via SetColor, we can pick this up in the pixel shader if desired
	source :+ "   var_uv = gl_MultiTexCoord0.st;~n"		' pass the uv coord of the vertex through to the pixel shader
	source :+ "}~n"
	Return source
EndFunction

Function GLSLPixelShaderSource:String()
	Local source:String
	source :+ "#version 120~n"
	
	source :+ "uniform sampler2D pic0047;~n"			' set via Max2D in a DrawImage call - can be set via <ShaderSampler>.SetIndex(0, <TImage>) but it will be over-ridden!
	source :+ "uniform sampler2D pic0048;~n"			' set via <ShaderSampler>.SetIndex
	
	source :+ "varying vec4 var_color;~n"
	source :+ "varying vec2 var_uv;~n"
	
	source :+ "const float GAMMA = 2.0;~n"
	
	source :+ "void main() {~n"
	source :+ "   vec3 color_0047 = texture2D(pic0047, var_uv).rgb;~n"
	source :+ "   vec3 color_0048 = texture2D(pic0048, var_uv).rgb;~n"

	source :+ "   vec3 color = clamp(color_0047 * color_0048 * GAMMA, 0.0, 1.0); // '* 2.0' for gamma correction-ish ~n"
	
	source :+ "   gl_FragColor = vec4(color, 1.0);~n"
	source :+ "}~n"
	Return source
EndFunction










