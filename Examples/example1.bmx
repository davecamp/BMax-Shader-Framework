
Strict

Import srs.shaderframework
SetGraphicsDriver GLMax2DDriver()
?Win32
'SetGraphicsDriver D3D9Max2DDriver()
?
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

Local rt_size:TShaderUniform = myShader.getShaderUniform("rt_size")
Local radius:TShaderUniform = myShader.getShaderUniform("radius")
Local angle:TShaderUniform = myShader.getShaderUniform("angle")
Local centre:TShaderUniform = myShader.getShaderUniform("centre")

Local image:TImage = LoadImage("BlitzMaxLogo.png")
Local normal:TImage = LoadImage("BlitzMaxLogNormal.png")

' set the uniform datas
rt_size.SetFloat2(ImageWidth(image), ImageHeight(image))
radius.SetFloat(ImageWidth(image)/2)
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
	
	source :+ "varying vec4 var_color;~n"
	source :+ "varying vec2 var_uv;~n"
	
	source :+ "void main() {~n"
	source :+ "   gl_Position = ftransform();~n"
	source :+ "   var_color = gl_Color;~n"
	source :+ "   var_uv = gl_MultiTexCoord0.st;~n"
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
	
	source :+ "varying vec4 var_color;~n"
	source :+ "varying vec2 var_uv;~n"
	
	source :+ "void main() {~n"
	source :+ "   vec2 tc = var_uv * rt_size;~n"
	source :+ "   tc -= centre;~n"
	source :+ "   float dist = length(tc);~n"
	source :+ "   if(dist < radius) {~n"
	source :+ "      float percent = (radius - dist) / radius;~n"
	source :+ "      float theta = percent * percent * angle * 8.0;~n"
	source :+ "      float s = sin(theta), c = cos(theta);~n"
	source :+ "      tc = vec2(dot(tc, vec2(c, -s)), dot(tc, vec2(s, c)));~n"
	source :+ "   }~n"
	source :+ "   tc += centre;~n"
	source :+ "   vec3 color = texture2D(tex, tc / rt_size).rgb * var_color.rgb;~n"
	
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

	source :+ "float4x4 BMaxProjectionMatrix;~n" ' uniforms/constants beginning with BMax* will be automatically set

	source :+ "VS_OUT VSMain(VS_IN vsIn) {~n"
	source :+ "   VS_OUT vsOut;~n"
	source :+ "   vsOut.pos = mul(BMaxProjectionMatrix, float4(vsIn.pos, 1.0f));~n"
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

















