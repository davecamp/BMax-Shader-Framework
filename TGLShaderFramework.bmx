
Strict

Import BRL.GLMax2D
Import BRL.Retro
Import BRL.Map
Import PUB.Glew

Import "TShaderFramework.bmx"

Private
Global GlewIsInit

Function GLEnumGlslTypeToString:String(Tipe:Int)
	Select Tipe
	Case GL_INT Return "GL_INT"
	Case GL_INT_VEC2 Return "GL_INT_VEC2"
	Case GL_INT_VEC3 Return "GL_INT_VEC3"
	Case GL_INT_VEC4 Return "GL_INT_VEC4"
	Case GL_FLOAT Return "GL_FLOAT"
	Case GL_FLOAT_VEC2 Return "GL_FLOAT_VEC2"
	Case GL_FLOAT_VEC3 Return "GL_FLOAT_VEC3"
	Case GL_FLOAT_VEC4 Return "GL_FLOAT_VEC4"
	Case GL_FLOAT_MAT4 Return "GL_FLOAT_MAT4"
	Default Return "Unknown: " + Hex(Tipe)
	EndSelect
EndFunction

Public



Type TGLShaderProgram Extends TShaderProgram
	Field _Id:Int
	Field _VShader:TGLVertexShader
	Field _PShader:TGLPixelShader
	Field _Uniforms:TMap = New TMap
	
	Method Link:Int(VertexShader:TGLVertexShader, PixelShader:TGLPixelShader)
		_Id = glCreateProgram()
		If _Id = 0 Return False
		
		glAttachShader(_Id, VertexShader._Id)
		glAttachShader(_Id, PixelShader._Id)
		glLinkProgram(_Id)

		Local status:Int, infoLength:Int
		glGetProgramiv(_id, GL_LINK_STATUS, Varptr status)
		glGetProgramiv(_Id, GL_INFO_LOG_LENGTH, Varptr infoLength)
			
		If infoLength > 0
			Local pInfo:Byte Ptr = MemAlloc(infoLength)
				
			Local returnedLength:Int
			glGetProgramInfoLog(_Id, infoLength, Varptr returnedLength, pInfo)
				
			Print String.FromCString(pInfo)
			MemFree(pInfo)
			Return False
		EndIf
		
		If status = 0 Return False
		_VShader = VertexShader
		_PShader = PixelShader
		Return True
	EndMethod
	
	Method Set()
		glUseProgram(_Id)
		For Local node:TNode = EachIn _Uniforms
			Local constant:TGLShaderUniform = TGLShaderUniform(node._Value)
			If constant
				constant.Set()
				Continue
			EndIf
			Local sampler:TGLShaderSampler = TGLShaderSampler(node._Value)
			If sampler sampler.Set()
		Next		
	EndMethod
	
	Method Unset()
		For Local node:TNode = EachIn _Uniforms
			Local constant:TGLShaderUniform = TGLShaderUniform(node._Value)
			If constant
				constant.Unset()
				Continue
			EndIf
			Local sampler:TGLShaderSampler = TGLShaderSampler(node._Value)
			If sampler sampler.Unset()
		Next
	EndMethod
	
	Method GetShaderUniform:TShaderUniform(Name:String)
		Local Uniform:Object = _Uniforms.ValueForKey(Name)
		Return TShaderUniform(Uniform)
	EndMethod
	
	Method GetShaderSampler:TShaderSampler(Name:String)
		Local Sampler:Object = _Uniforms.ValueForKey(Name)
		Return TShaderSampler(Sampler)
	EndMethod
	
	Method Reflect()
		_Uniforms.Clear()
		Local uniformCount:Int
		glGetProgramiv(_Id, GL_ACTIVE_UNIFORMS, Varptr uniformCount)
		Local cname:Byte[64], length:Int
		Local count:Int, tipe:Int

		For Local i:Int = 0 Until uniformCount
			glGetActiveUniform(_Id, i, SizeOf(cname), Varptr length, Varptr count, Varptr tipe, cname)
			Local name:String = String.FromCString(cname)
			Print name
			CreateUniform(i, name, count, tipe)
		Next
	EndMethod
	
	Method CreateUniform(location:Int, name:String, count:Int, tipe)
		Local uniform:TGLShaderUniform
		
		Select tipe
		Case GL_FLOAT, GL_INT _Uniforms.Insert(name, New TGLShaderUniform.Create(location, name, count * 4, tipe))
		Case GL_FLOAT_VEC2, GL_INT_VEC2 _Uniforms.Insert(name, New TGLShaderUniform.Create(location, name, count * 8, tipe))
		Case GL_FLOAT_VEC3, GL_INT_VEC3 _Uniforms.Insert(name, New TGLShaderUniform.Create(location, name, count * 12, tipe))
		Case GL_FLOAT_VEC4, GL_INT_VEC4 _Uniforms.Insert(name, New TGLShaderUniform.Create(location, name, count * 16, tipe))
		Case GL_FLOAT_MAT4 _Uniforms.Insert(name, New TGLShaderUniform.Create(location, name, count * 64, tipe))
		Case GL_SAMPLER_2D _Uniforms.Insert(name, New TGLShaderSampler.Create(Self, location, name, tipe))
		
		Default DebugLog("Unsupported shader primitive type for Max2D")
		EndSelect
	EndMethod
EndType

Type TGLVertexShader Extends TVertexShader
	Field _Id:Int
	
	Method Compile:Int(Source:String)
		Local Id:Int = glCreateShader(GL_VERTEX_SHADER_ARB)
		If Id = 0 Return False
		
		Local pSource:Byte Ptr = Source.ToCString()
		Local iSourceLength:Int = Source.Length
		glShaderSource(Id, 1, Varptr pSource, Varptr iSourceLength)
		MemFree pSource

		Local status:Int, infoLength:Int
		glCompileShader(Id)
		glGetShaderiv(Id, GL_COMPILE_STATUS, Varptr status)
		glGetShaderiv(Id, GL_INFO_LOG_LENGTH, Varptr infoLength)
			
		If infoLength > 0
			Local pInfo:Byte Ptr = MemAlloc(infoLength)
				
			Local returnedLength:Int
			glGetShaderInfoLog(Id, infoLength, Varptr returnedLength, pInfo)
				
			Print String.FromCString(pInfo)
			MemFree(pInfo)
			Return False
		EndIf

		If status = 0 Return False
		_Id = Id
		Return True
	EndMethod
EndType

Type TGLPixelShader Extends TPixelShader
	Field _Id:Int
	
	Method Delete()
		If _Id glDeleteShader(_Id)
	EndMethod
	
	Method Compile:Int(Source:String)
		Local Id:Int = glCreateShader(GL_FRAGMENT_SHADER_ARB)
		If Id = 0 Return False
		
		Local pSource:Byte Ptr = Source.ToCString()
		Local iSourceLength:Int = Source.Length
		glShaderSource(Id, 1, Varptr pSource, Varptr iSourceLength)
		MemFree pSource
	
		Local status:Int, infoLength:Int
		glCompileShader(Id)
		glGetShaderiv(Id, GL_COMPILE_STATUS, Varptr status)
		glGetShaderiv(Id, GL_INFO_LOG_LENGTH, Varptr infoLength)
			
		If infoLength > 0
			Local pInfo:Byte Ptr = MemAlloc(infoLength)
				
			Local returnedLength:Int
			glGetShaderInfoLog(Id, infoLength, Varptr returnedLength, pInfo)
				
			Print String.FromCString(pInfo)
			MemFree(pInfo)
			Return False
		EndIf

		If status = 0 Return False
		_Id = Id
		Return True
	EndMethod
EndType

Type TGLShaderUniformBase Extends TShaderUniform
	Field _Name:String
	Field _Data:Byte Ptr
	Field _SizeBytes:Int
	Field _Type:Int
	Field _Location:Int
	Field _IsTranspose:Int
	Field _RequiresUpload:Int
	Field _IsRendering:Int
EndType

Type TGLShaderUniform Extends TGLShaderUniformBase
	Method Create:TGLShaderUniform(Location:Int, Name:String, SizeBytes:Int, Tipe:Int)
		_Name = Name
		_Data = MemAlloc(SizeBytes)
		_SizeBytes = SizeBytes
		_Type = tipe
		_Location = Location
		Return Self
	EndMethod
	
	Method Destroy()
		MemFree(_Data)
	EndMethod
	
	Method SetFloat(Data:Float)
?debug
		If DebugData(4) Return
?
		If _IsRendering
			glUniform1f(_Location, Data)
		Else
			Local fptr:Float Ptr = Float Ptr(_Data)
			fptr[0] = Data
			_RequiresUpload = True
		EndIf
	EndMethod
			
	Method SetFloat2(Data1:Float, Data2:Float)
?debug
		If DebugData(8) Return
?
		If _IsRendering
			glUniform2f(_Location, Data1, Data2)
		Else
			Local fptr:Float Ptr = Float Ptr(_Data)
			fptr[0] = Data1; fptr[1] = Data2
			_RequiresUpload = True
		EndIf
	EndMethod

	Method SetFloat3(Data1:Float, Data2:Float, Data3:Float)
?debug
		If DebugData(12) Return
?
		If _IsRendering
			glUniform3f(_Location, Data1, Data2, Data3)
		Else
			Local fptr:Float Ptr = Float Ptr(_Data)
			fptr[0] = Data1; fptr[1] = Data2; fptr[2] = Data3
			_RequiresUpload = True
		EndIf
	EndMethod

	Method SetFloat4(Data1:Float, Data2:Float, Data3:Float, Data4:Float)
?debug
		If DebugData(16) Return
?
		If _IsRendering
			glUniform4f(_Location, Data1, Data2, Data3, Data4)
		Else
			Local fptr:Float Ptr = Float Ptr(_Data)
			fptr[0] = Data1; fptr[1] = Data2; fptr[2] = Data3; fptr[3] = Data4
			_RequiresUpload = True
		EndIf
	EndMethod
	
	Method SetInt(Data:Int)
?debug
		If DebugData(4) Return
?
		If _IsRendering
			glUniform1i(_Location, Data)
		Else
			Local iptr:Int Ptr = Int Ptr(_Data)
			iptr[0] = Data
			_RequiresUpload = True
		EndIf
	EndMethod

	Method SetInt2(Data1:Int, Data2:Int)
?debug
		If DebugData(8) Return
?
		If _IsRendering
			glUniform2i(_Location, Data1, Data2)
		Else
			Local iptr:Int Ptr = Int Ptr(_Data)
			iptr[0] = Data1; iptr[1] = Data2
			_RequiresUpload = True
		EndIf
	EndMethod
	
	Method SetInt3(Data1:Int, Data2:Int, Data3:Int)
?debug
		If DebugData(12) Return
?
		If _IsRendering
			glUniform3i(_Location, Data1, Data2, Data3)
		Else
			Local iptr:Int Ptr = Int Ptr(_Data)
			iptr[0] = Data1; iptr[1] = Data2; iptr[2] = Data3
			_RequiresUpload = True
		EndIf
	EndMethod

	Method SetInt4(Data1:Int, Data2:Int, Data3:Int, Data4:Int)
?debug
		If DebugData(16) Return
?
		If _IsRendering
			glUniform4i(_Location, Data1, Data2, Data3, Data4)
		Else
			Local iptr:Int Ptr = Int Ptr(_Data)
			iptr[0] = Data1; iptr[1] = Data2; iptr[2] = Data3; iptr[3] = Data4
			_RequiresUpload = True
		EndIf
	EndMethod
	
	Method SetMatrix4x4(Data:Float[], IsTranspose:Byte)
?debug
		If DebugData(SizeOf(Data)) Return
?
		If _IsRendering
			glUniformMatrix4fv(_Location, 1, IsTranspose, Data)
		Else
			_IsTranspose = IsTranspose
			MemCopy(_Data, Data, 64)
			_RequiresUpload = True
		EndIf
	EndMethod
	
	Method DebugData:Int(SizeBytes:Int)
		If(SizeBytes = _SizeBytes) Return False
		
		Local debug:String = "ERROR! TGLShaderConstant: '" + _Name + "' requires " + _SizeBytes
		debug :+ " bytes to be set but " + SizeBytes + " are being presented."
		DebugLog(debug)
		Return True
	EndMethod
	
	Method TypeToString:String()
		Return GLEnumGlslTypeToString(_Type)
	EndMethod
	
	Method Set()
		If _RequiresUpload
			Upload(); _RequiresUpload = False
		EndIf
		_IsRendering = True
	EndMethod
	
	Method Unset()
		_IsRendering = False
	EndMethod
	
	Method Upload()
		Select _Type
		Case GL_FLOAT glUniform1fv(_Location, 1, Float Ptr(_Data))
		Case GL_FLOAT_VEC2 glUniform2fv(_Location, 1, Float Ptr(_Data))
		Case GL_FLOAT_VEC3 glUniform3fv(_Location, 1, Float Ptr(_Data))
		Case GL_FLOAT_VEC4 glUniform4fv(_Location, 1, Float Ptr(_Data))
		Case GL_FLOAT_MAT4 glUniformMatrix4fv(_Location, 1, _IsTranspose, Float Ptr(_Data))
		Case GL_INT glUniform1iv(_Location, 1, Int Ptr(_Data))
		Case GL_INT_VEC2 glUniform2iv(_Location, 1, Int Ptr(_Data))
		Case GL_INT_VEC3 glUniform3iv(_Location, 1, Int Ptr(_Data))
		Case GL_INT_VEC4 glUniform4iv(_Location, 1, Int Ptr(_Data))
		EndSelect
	EndMethod
EndType

Type TGLShaderSampler Extends TShaderSampler
	Field _Name:String
	Field _Data:Byte Ptr
	Field _Location:Int
	Field _RequiresUpload:Int
	Field _IsRendering:Int

	Method Create:TGLShaderSampler(Owner:TGLShaderProgram, Location:Int, Name:String, Tipe:Int)
		_Data = MemAlloc(4)
		_Name = Name
		_Location = Location
		Return Self
	EndMethod
	
	Method SetIndex(Index:Int)
		If _IsRendering
			glUniform1i(_Location, Index)
		Else
			Int Ptr(_Data)[0] = Index
			_RequiresUpload = True
		EndIf
	EndMethod
	
	Method Set()
		If _RequiresUpload
			glUniform1i(_Location, Int Ptr(_Data)[0]); _RequiresUpload = False
		EndIf
		_IsRendering = True
	EndMethod
	
	Method Unset()
		_IsRendering = False
	EndMethod
EndType

Type TGLShaderFramework Extends TShaderFramework
	Field CurrentProgram:TGLShaderProgram
	
	Method New()
		If Not GlewIsInit
			GlewInit()
			GlewIsInit = True
		EndIf
	EndMethod

	Method CreateShaderProgram:TShaderProgram(VertexShader:TVertexShader, PixelShader:TPixelShader)
?debug
		Assert TGLVertexShader(VertexShader) <> Null, "Invalid vertex shader"
		Assert TGLPixelShader(PixelShader) <> Null, "Invalid pixel shader"
?	
		Local sp:TGLShaderProgram = New TGLShaderProgram
		If Not sp.Link(TGLVertexShader(vertexshader), TGLPixelShader(pixelshader)) Return Null
		sp.Reflect()
		Return sp
	EndMethod
	
	Method CreateVertexShader:TVertexShader(source:String)
		Local vs:TGLVertexShader = New TGLVertexShader
		If Not vs.Compile(source) Return Null
		Return vs
	EndMethod
	
	Method CreatePixelShader:TPixelShader(source:String)
		Local ps:TGLPixelShader = New TGLPixelShader
		If Not ps.Compile(source) Return Null
		Return ps
	EndMethod
	
	Method SetShader(ShaderProgram:TShaderProgram)
		If ShaderProgram <> CurrentProgram And CurrentProgram <> Null CurrentProgram.Unset()
			
		If ShaderProgram <> Null
?debug
			Assert TGLShaderProgram(ShaderProgram) <> Null, "Invalid shader program"
?
			CurrentProgram = TGLShaderProgram(ShaderProgram)
			TGLShaderProgram(ShaderProgram).Set()
			Return
		EndIf

		CurrentProgram = Null
		glUseProgram(0)
	EndMethod
EndType






