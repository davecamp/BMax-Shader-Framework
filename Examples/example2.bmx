
' 3d light via normal map

Strict

Import srs.shaderframework
'SetGraphicsDriver GLMax2DDriver()
?Win32
SetGraphicsDriver D3D9Max2DDriver()
?
Local g:TGraphics = Graphics(800, 600)
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

Local image:TImage = LoadImage("177.jpg") ' or 176.jpg
Local sw:Float = Float(GraphicsWidth()) / ImageWidth(image)
Local sh:Float = Float(GraphicsHeight()) / ImageHeight(image)
SetScale(sw, sh)

' temp kludge to get Max2D to create the textures on the gpu by 'Draw'ing it first 
' - this is why we will need a separate TTexture for creating textures!
Local normal:TImage = LoadImage("177_norm.jpg") ' or 176_norm.jpg
DrawImage(normal, 0, 0)
DrawImage(image, 0, 0)

' another part of the kludge - this could also be cleanly handled within a TTexture!
' bind the normal texture to texture unit 1
If TGLGraphics(max2dg._graphics)
	glActiveTexture(GL_TEXTURE1)
	glBindTexture(GL_TEXTURE_2D, TGLImageFrame(normal.frames[0]).name)
EndIf

' get the uniforms
Local Resolution:TShaderUniform = myShader.GetShaderUniform("Resolution")
Local LightPos:TShaderUniform = myShader.GetShaderUniform("LightPos")
Local LightColor:TShaderUniform = myShader.GetShaderUniform("LightColor")
Local AmbientColor:TShaderUniform = myShader.GetShaderUniform("AmbientColor")
Local FallOff:TShaderUniform = myShader.GetShaderUniform("FallOff")

myShader.GetShaderSampler("textureDiff").SetIndex(0, image)
myShader.GetShaderSampler("textureNorm").SetIndex(1, normal)

Resolution.SetFloat2(GraphicsWidth(), GraphicsHeight())
FallOff.SetFloat3(0.4, 3.0, 10.0)
AmbientColor.SetFloat4(0.6, 0.6, 1.0, 0.2)
LightColor.SetFloat4(1.0, 0.8, 0.6, 1.0)
Local LightPosZ:Float = 0.05

While Not KeyDown(KEY_ESCAPE)
	Cls
	SetScale(sw, sh)
		
	' activate shader
	sf.SetShader(myShader)
	
	If KeyDown(KEY_A) And LightPosZ > 0.01 LightPosZ :- 0.0025
	If KeyDown(KEY_Z) And LightPosZ < 4.0 LightPosZ :+ 0.0025
	
	' position the 'light' at the normalized mouse position
	Local LightPosX:Float = Float(MouseX()) / GraphicsWidth()
	Local LightPosY:Float = Float(MouseY()) / GraphicsHeight()
	LightPos.SetFloat3(LightPosX, LightPosY, LightPosZ)
	
	' draw the image as a regular image
	DrawImage(image, 0, 0)

	sf.SetShader(Null)

	' WTF is going on here with GL? TODO: calling Max2D drawimage now screws everything up :( Dx is ok.
	'SetScale(1, 1)
	'DrawText "Example2 - 3D Lighting in 2D", 0, 0

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
	Local source:String
	source :+ "#version 120~n"
	
	' these come from the vertex shader
	source :+ "varying vec4 var_color;~n"
	source :+ "varying vec2 var_uv;~n"

	' textures
	source :+ "uniform sampler2D textureDiff;~n"
	source :+ "uniform sampler2D textureNorm;~n"
	
	' variables
	source :+ "uniform vec2 Resolution;~n"
	source :+ "uniform vec3 LightPos;~n"
	source :+ "uniform vec4 LightColor;~n"
	source :+ "uniform vec4 AmbientColor;~n"
	source :+ "uniform vec3 FallOff;~n"
	
	source :+ "void main() {~n"
	' sample the color ( dffuse ) texture
	source :+ "   vec4 color = texture2D(textureDiff, var_uv);~n"
	
	' sample the normal texture
	source :+ "   vec3 normal = texture2D(textureNorm, var_uv).rgb;~n"
	' scale the normal from '0 to 1' to '-1 to +1' for all 3 axis (XYZ is encoded as RGB)
	source :+ "   vec3 N = normalize(normal * 2.0 - 1.0);~n"
	
	' calculate the delta position of the light in relation to the texture [0.0 -> 1.0]
	source :+ "   vec3 LightDir = vec3(vec2(LightPos.x, 1-LightPos.y) - (gl_FragCoord.xy / Resolution), LightPos.z);~n"
	
	' calculate 'distance' for light attenuation
	source :+ "   float dist = length(LightDir);~n"
	
	' normalize the light direction
	source :+ "   vec3 L = normalize(LightDir);~n"
	
	' aspect ratio correction
	source :+ "   LightDir.x *= Resolution.x / Resolution.y;~n"
	
	' caculate the light intensity using the alpha channel for the intensity term then multiply 'N dot L'
	source :+ "   vec3 Diffuse = (LightColor.rgb * LightColor.a) * max(dot(N, L), 0.0);~n"
	
	' calulate ambient color intensity too
	source :+ "   vec3 Ambient = AmbientColor.rgb * AmbientColor.a;~n"
	
	' calculate the light attenuation
	source :+ "   float Attenuation = 1.0 / (FallOff.x + (FallOff.y * dist) + (FallOff.z * dist * dist));~n"
	
	' now add and multiply all the terms up using our color texture
	source :+ "   vec3 Intensity = Ambient + Diffuse * Attenuation;~n"
	source :+ "   vec3 OutputColor = color.rgb * Intensity;~n"	
	source :+ "   gl_FragColor = var_color * vec4(OutputColor, color.a);~n"
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

Function HLSLPixelShaderSource:String()
	Local source:String
	source :+ "struct PS_IN~n"
	source :+ "{~n"
	source :+ "   float4 pos : SV_Position;~n"
	source :+ "   float4 col : COLOR0;~n"
	source :+ "   float2 uv : TEXCOORD0;~n"
	source :+ "};~n"

	source :+ "sampler textureDiff : register(s0);~n"
	source :+" sampler textureNorm : register(s1);~n"
	
	' variables
	source :+ "float2 Resolution;~n"
	source :+ "float3 LightPos;~n"
	source :+ "float4 LightColor;~n"
	source :+ "float4 AmbientColor;~n"
	source :+ "float3 FallOff;~n"

	
	source :+ "float4 PSMain(PS_IN psIn) : COLOR {~n"
	source :+ "   float4 color = tex2D(textureDiff, psIn.uv);~n"
	
	source :+ "   float3 normal = tex2D(textureNorm, psIn.uv).rgb;~n"
	source :+ "   float3 N = normalize(normal * 2.0 - 1.0);~n"
	
	source :+ "   float3 LightDir = float3(LightPos.xy - (psIn.pos.xy / Resolution), LightPos.z);~n"
	source :+ "   float dist = length(LightDir);~n"
	source :+ "   float3 L = normalize(LightDir);~n"
	
	source :+ "   LightDir.x *= Resolution.x / Resolution.y;~n"
	
	source :+ "   float3 Diffuse = (LightColor.rgb * LightColor.a) * max(dot(N, L), 0.0);~n"
	source :+ "   float3 Ambient = AmbientColor.rgb * AmbientColor.a;~n"
	source :+ "   float Attenuation = 1.0 / (FallOff.x + (FallOff.y * dist) + (FallOff.z * dist * dist));~n"
	
	source :+ "   float3 Intensity = Ambient + Diffuse * Attenuation;~n"
	source :+ "   float3 OutColor = color.rgb * Intensity;~n"
	
	source :+ "   return psIn.col * float4(OutColor, color.a);~n"
	source :+ "}~n"
	Return source
EndFunction




















