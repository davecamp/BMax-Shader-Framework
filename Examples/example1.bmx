
Strict

Import srs.shaderframework

SetGraphicsDriver GLMax2DDriver()
Local g:TGraphics = Graphics(800,600)

' Create an instance of the shader framework with the max2d graphics context
Local sf:TShaderFramework = CreateShaderFramework(g)
Local vertexshader:TVertexShader = sf.CreateVertexShader(GLSLVertexShaderSource())
Local pixelshader:TPixelShader = sf.CreatePixelShader(GLSLPixelShaderSource())
Local myShader:TShaderProgram = sf.CreateShaderProgram(vertexshader, pixelshader)

' get uniforms
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
	
	DrawImage(image, 10, 10)		
	
	' turn off the shader and go back to the fixed function pipeline
	sf.SetShader(Null)

	' draw the image as a regular image
	DrawImage(image, 10, 200)

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













