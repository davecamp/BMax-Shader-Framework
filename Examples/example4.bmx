
Strict

Import srs.shaderframework
Import srs.d3d11max2d

'SetGraphicsDriver GLMax2DDriver()
?win32
'SetGraphicsDriver D3D9Max2DDriver()
SetGraphicsDriver D3D11Max2DDriver()
?

Local g:TGraphics = Graphics(1240,350)
Local max2dg:TMax2DGraphics = TMax2DGraphics(g)

' Create an instance of the shader framework with the max2d graphics context
Global vsource:String, psource:String
Local sf:TShaderFramework = ChooseShaderFrameworkAPI(g)
Local vertexshader:TVertexShader = sf.CreateVertexShader(vsource)
Local pixelshader:TPixelShader = sf.CreatePixelShader(psource)
Local myShader:TShaderProgram = sf.CreateShaderProgram(vertexshader, pixelshader)

Local image_pic0047:TImage = LoadImage("pic0047.png")
image_pic0047.Frame(0) ' this is a crap way to make sure the TImage texture really is created
Local pic0047:TShaderSampler = myShader.GetShaderSampler("pic0047")

Local image_pic0048:TImage = LoadImage("pic0048.png")
image_pic0048.Frame(0)
Local pic0048:TShaderSampler = myShader.GetShaderSampler("pic0048")

Local image_alpha:TImage = LoadImage("pic0057.png")
image_alpha.Frame(0)
Local alpha_sampler:TShaderSampler = myShader.GetShaderSampler("alpha")

pic0047.SetIndex(0, image_pic0047)
pic0048.SetIndex(1, image_pic0048)
alpha_sampler.SetIndex(2, image_alpha)

While Not KeyDown(KEY_ESCAPE)
	Cls

	DrawText("Alpha mapping in the shader", 0, 0)
	
	DrawImage(image_alpha, 15, 50)
	DrawImage(image_pic0047, 350, 50)
	DrawImage(image_pic0048, 630, 50)
	
		
	' activate shader
	sf.SetShader(myShader)
	
	' DrawImage sets image_pic0047 to texture sampler 0 in the pixel shader
	DrawImage(image_pic0047, 950, 50)
	
	' turn off the shader and go back to the fixed function pipeline
	sf.SetShader(Null)

	Flip(1)
Wend

Function ChooseShaderFrameworkAPI:TShaderFramework(g:TGraphics)
	Local max2dg:TMax2DGraphics = TMax2DGraphics(g)

	If TGLGraphics(max2dg._graphics)
		vsource = GLSLVertexShaderSource()
		psource = GLSLPixelShaderSource()
	EndIf
	?Win32
	' d3d9 (vs3.0) and d3d11(vs5.0) source are the same only in this example
	If TD3D9Graphics(max2dg._graphics) Or TD3D11Graphics(max2dg._graphics) vsource = HLSLVertexShaderSource()
	
	' d3d9 (ps3.0)
	If TD3D9Graphics(max2dg._graphics) psource = HLSL9PixelShaderSource()
	' d3d11 (ps5.0)
	If TD3D11Graphics(max2dg._graphics) psource = HLSL11PixelShaderSource()
	?
	
	' Create an instance of the shader framework with the max2d graphics context
	Return CreateShaderFramework(g)
EndFunction

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
	source :+ "uniform sampler2D alpha;~n"
	
	source :+ "varying vec4 var_color;~n"
	source :+ "varying vec2 var_uv;~n"
	
	source :+ "void main() {~n"
	source :+ "   vec4 color_0047 = texture2D(pic0047, var_uv);~n"
	source :+ "   vec4 color_0048 = texture2D(pic0048, var_uv);~n"
	source :+ "   vec4 alphaval = texture2D(alpha, var_uv);~n"

	source :+ "   vec4 final = alphaval * color_0047 + ((1.0 - alphaval) * color_0048);~n"
	source :+ "   gl_FragColor = clamp(final, 0.0, 1.0);~n"
	source :+ "}~n"
	Return source
EndFunction

Function HLSL9VertexShaderSource:String()
	Local source:String
	source :+ "struct VS_IN {"
	source :+ "   float3 pos : POSITION;~n"
	source :+ "   float4 col : COLOR0;~n"
	source :+ "   float2 uv : TEXCOORD0;~n"
	source :+ "};~n"
		
	source :+ "struct VS_OUT {~n"
	source :+ "    float4 pos : SV_Position;~n"
	source :+ "    float4 col : COLOR0;~n"
	source :+ "    float2 uv : TEXCOORD0;~n"
	source :+ "};~n"

	source :+ "float4x4 BMAX_PROJECTION_MATRIX;~n"

	source :+ "VS_OUT VSMain(VS_IN vsIn) {~n"
	source :+ "   VS_OUT vsOut;~n"
	source :+ "   vsOut.pos = mul(BMAX_PROJECTION_MATRIX, float4(vsIn.pos, 1.0f));~n"
	source :+ "   vsOut.col = vsIn.col;~n"
	source :+ "   vsOut.uv = vsIn.uv;~n"
	source :+ "   return vsOut;~n"
	source :+ "}~n"
	Return source
EndFunction

Function HLSL9PixelShaderSource:String()
	Local source:String
	source :+ "struct PS_IN~n"
	source :+ "{~n"
	source :+ "   float4 pos : SV_Position;~n"
	source :+ "   float4 col : COLOR0;~n"
	source :+ "   float2 uv : TEXCOORD0;~n"
	source :+ "};~n"

	source :+ "sampler pic0047 : register(s0);~n"
	source :+ "sampler pic0048 : register(s1);~n"
	source :+ "sampler alpha : register(s2);~n"
	
	source :+ "float4 PSMain(PS_IN psIn) : COLOR {~n"
	source :+ "    float4 color_0047 = tex2D(pic0047, psIn.uv);~n"
	source :+ "    float4 color_0048 = tex2D(pic0048, psIn.uv);~n"
	source :+ "    float4 alphaval = tex2D(alpha, psIn.uv);~n"
	
	source :+ "    float4 final = alphaval * color_0047 + ((1.0 - alphaval) * color_0048);~n"
	source :+ "    return saturate(final);~n"
	source :+ "}~n"
	Return source
EndFunction

Function HLSLVertexShaderSource:String()
	Local source:String
	source :+ "struct VS_IN {"
	source :+ "   float3 pos : POSITION;~n"
	source :+ "   float4 col : COLOR0;~n"
	source :+ "   float2 uv : TEXCOORD0;~n"
	source :+ "};~n"
		
	source :+ "struct VS_OUT {~n"
	source :+ "    float4 pos : SV_Position;~n"
	source :+ "    float4 col : COLOR0;~n"
	source :+ "    float2 uv : TEXCOORD0;~n"
	source :+ "};~n"

	source :+ "cbuffer Max2D {~n"
	source :+ "    float4x4 BMAX_PROJECTION_MATRIX;~n"
	source :+ "};~n"

	source :+ "VS_OUT VSMain(VS_IN vsIn) {~n"
	source :+ "   VS_OUT vsOut;~n"
	source :+ "   vsOut.pos = mul(BMAX_PROJECTION_MATRIX, float4(vsIn.pos, 1.0f));~n"
	source :+ "   vsOut.col = vsIn.col;~n"
	source :+ "   vsOut.uv = vsIn.uv;~n"
	source :+ "   return vsOut;~n"
	source :+ "}~n"
	Return source
EndFunction

Function HLSL11PixelShaderSource:String()
	Local source:String
	source :+ "struct PS_IN~n"
	source :+ "{~n"
	source :+ "   float4 pos : SV_Position;~n"
	source :+ "   float4 col : COLOR0;~n"
	source :+ "   float2 uv : TEXCOORD0;~n"
	source :+ "};~n"

	source :+ "SamplerState	sam_pic0047;~n"
	source :+ "Texture2D	tex_pic0047;~n"
	
	source :+ "SamplerState	sam_pic0048;~n"
	source :+ "Texture2D	tex_pic0048;~n"
	
	source :+ "SamplerState	sam_alpha;~n"
	source :+ "Texture2D	tex_alpha;~n"
	
	source :+ "float4 PSMain(PS_IN psIn) : SV_Target {~n"
	source :+ "    float4 color_0047 = tex_pic0047.Sample(sam_pic0047, psIn.uv);~n"
	source :+ "    float4 color_0048 = tex_pic0048.Sample(sam_pic0048, psIn.uv);~n"
	source :+ "    float4 alphaval = tex_alpha.Sample(sam_alpha, psIn.uv);~n"
	
	source :+ "    float4 final = alphaval * color_0047 + ((1.0 - alphaval) * color_0048);~n"
	source :+ "    return saturate(final);~n"
	source :+ "}~n"
	Return source
EndFunction







