
Strict

Import srs.shaderframework

'SetGraphicsDriver GLMax2DDriver()
SetGraphicsDriver D3D9Max2DDriver()
Local g:TGraphics = Graphics(800,600)
Local max2dg:TMax2DGraphics = TMax2DGraphics(g)

Local vsource:String
Local psource:String

If TGLGraphics(max2dg._graphics)
	vsource = GLSLVertexShaderSource()
	psource = GLSLPixelShaderSource()
EndIf
?Win32
If TD3D9Graphics(max2dg._graphics) ' Or TD3D11Graphics(max2dg._graphics)
	vsource = HLSLVertexShaderSource()
	psource = HLSLPixelShaderSource()
EndIf
?


' Create an instance of the shader framework with the max2d graphics context
Local sf:TShaderFramework = CreateShaderFramework(g)
Local vertexshader:TVertexShader = sf.CreateVertexShader(vsource)
Local pixelshader:TPixelShader = sf.CreatePixelShader(psource)
Local myShader:TShaderProgram = sf.CreateShaderProgram(vertexshader, pixelshader)

?win32
' d3d9?
Local d3d9g:TD3D9Graphics = TD3D9Graphics(max2dg._graphics)
If d3d9g
	' set the projection matrix that max2d is currently using
	Local projmatrix:TShaderUniform = myShader.getShaderUniform("ProjMatrix")

	Local device:IDirect3DDevice9 = d3d9g.getdirect3ddevice()
	Local proj:Float[16]
	device.GetTransform(D3DTS_PROJECTION, proj)
	projmatrix.SetMatrix4x4(proj, False)
EndIf
?

Local rt_size:TShaderUniform = myShader.getShaderUniform("rt_size")
Local radius:TShaderUniform = myShader.getShaderUniform("radius")
Local angle:TShaderUniform = myShader.getShaderUniform("angle")
Local centre:TShaderUniform = myShader.getShaderUniform("centre")

Local image:TImage = LoadImage("BlitzMaxLogo.png")

' set the uniform datas
rt_size.SetFloat2(ImageWidth(image), ImageHeight(image))
radius.SetFloat(80.0)
centre.SetFloat2(ImageWidth(image)/2, ImageHeight(image)/2)


Local ang:Float
While Not KeyDown(KEY_ESCAPE)
	Cls

	' activate shader
	sf.SetShader(myShader)
	
	' update the uniform data for a swirly effect
	If KeyDown(KEY_LEFT) ang :+ 0.01
	If KeyDown(KEY_RIGHT) ang :- 0.01
	angle.SetFloat(ang)
	
	SetScale 2,2
	DrawImage(image, 10, 10)
	SetScale 1,1
	
	' turn off the shader and go back to the fixed function pipeline
	sf.SetShader(Null)

	' draw the image as a regular image
	DrawImage(image, 60, 60)

	Flip(1)
Wend



' some basic glsl vertex shader code
Function GLSLVertexShaderSource:String()
	Local source:String
	source :+ "#version 120~n"
	source :+ "void main() {~n"
	source :+ "   gl_Position = ftransform();~n"
	source :+ "   gl_TexCoord[0] = gl_MultiTexCoord0;~n"
	source :+ "   gl_FrontColor = gl_Color;~n"
	source :+ "}~n"
	Return source
EndFunction

' some basic glsl fragment shader source
Function GLSLPixelShaderSource:String()
	 ' for an explanation of the effect go to 'http://adrianboeing.blogspot.com/2011/01/twist-effect-in-webgl.html'
	Local source:String
	source :+ "#version 120~n"
	source :+ "uniform vec2 rt_size;~n"
	source :+ "uniform vec2 centre;~n"
	source :+ "uniform float radius;~n"
	source :+ "uniform float angle;~n"
	source :+ "uniform sampler2D tex;~n"
	
	source :+ "void main() {~n"
	source :+ "   vec2 uv = gl_TexCoord[0].st;~n"
	source :+ "   vec2 tc = uv * rt_size;~n"
	source :+ "   tc -= centre;~n"
	source :+ "   float dist = length(tc);~n"
	source :+ "   if(dist < radius) {~n"
	source :+ "      float percent = (radius - dist) / radius;~n"
	source :+ "      float theta = percent * percent * angle * 8.0;~n"
	source :+ "      float s = sin(theta), c = cos(theta);~n"
	source :+ "      tc = vec2(dot(tc, vec2(c, -s)), dot(tc, vec2(s, c)));~n"
	source :+ "   }~n"
	source :+ "   tc += centre;~n"
	source :+ "   vec3 color = texture2D(tex, tc / rt_size).rgb;~n"
	
	source :+ "   gl_FragColor = vec4(color, 1.0);~n"
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

	source :+ "float4x4 ProjMatrix : register(c0);~n"
		
	source :+ "VS_OUT VSMain(VS_IN vsIn) {~n"
	source :+ "   VS_OUT vsOut;~n"		
	source :+ "   vsOut.pos = mul(ProjMatrix, float4(vsIn.pos, 1.0f));~n"
	source :+ "   vsOut.col = vsIn.col;~n"
	source :+ "   vsOut.uv = vsIn.uv;~n"
	source :+ "   return vsOut;~n"
	source :+ "}~n"
	Return source
EndFunction

Function HLSLPixelShaderSource:String()
	Local source:String
	source :+ "struct PS_IN~n"
	source :+ "{~n"
	source :+ "   float4 pos : SV_Position;~n"
	source :+ "   float4 col : COLOR0;~n"
	source :+ "   float2 uv : TEXCOORD0;~n"
	source :+ "};~n"

	source :+ "float2 rt_size;~n"
	source :+ "float2 centre;~n"
	source :+ "float radius;~n"
	source :+ "float angle;~n"
	source :+ "sampler tex : register(s0);~n"
	
	source :+ "float4 PSMain(PS_IN psIn) : COLOR {~n"
	source :+ "   float2 uv = psIn.uv;~n"
	source :+ "   float2 tc = uv * rt_size;~n"
	source :+ "   tc -= centre;~n"
	source :+ "   float dist = length(tc);~n"
	source :+ "   if(dist < radius) {~n"
	source :+ "      float percent = (radius - dist) / radius;~n"
	source :+ "      float theta = percent * percent * angle * 8.0;~n"
	source :+ "      float s = sin(theta), c = cos(theta);~n"
	source :+ "      tc = float2(dot(tc, float2(c, -s)), dot(tc, float2(s, c)));~n"
	source :+ "   }~n"
	source :+ "   tc += centre;~n"
	source :+ "   float3 color = tex2D(tex, tc / rt_size).rgb;~n"
	
	source :+ "   return float4(color, 1.0);~n"
	source :+ "}~n"
	Return source
EndFunction

















