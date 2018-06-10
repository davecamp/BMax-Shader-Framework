
SuperStrict
Import "-lOle32"

Import BRL.D3D9Max2D
Import BRL.Map
Import PUB.Win32
Import "TShaderFramework.bmx"
Import "Max2DShaderVariables.bmx"

Private
Global Device:IDirect3DDevice9
Const D3DXPT_BOOL:Int = 1, D3DXPT_INT:Int = 2, D3DXPT_FLOAT:Int = 3
Const D3DXPT_TEXTURE2D:Int = 7,  D3DXPT_SAMPLER2D:Int = 12
Public

Type TD3D9ShaderReflector
	Field _UniformsAuto:TMap = New TMap
	Field _UniformsUser:TMap = New TMap

	Method Reflect(pBlob:ID3DBlob, ShaderType:Int)
		Local pByteCode:Byte Ptr = pBlob.GetBufferPointer()
		Local pTable:ID3DXConstantTable

		D3DXGetShaderConstantTable(pByteCode, pTable)
		If Not pTable Return
		pTable.SetDefaults(Device)
		
		Local Table:D3DXCONSTANTTABLE_DESC = New D3DXCONSTANTTABLE_DESC
		pTable.GetDesc(Table)

		For Local i:Int = 0 Until Table.ConstantCount
			Local bp:Byte Ptr = pTable.GetConstant(Null, i)
			Local desc:D3DXCONSTANT_DESC = New D3DXCONSTANT_DESC
			Local size:Int = SizeOf(desc)
			If pTable.GetConstantDesc(bp, desc, Varptr size) < 0 Continue
			Local name:String = String.FromCString(desc.Name)

			Select desc.Tipe
			Case D3DXPT_BOOL, D3DXPT_INT, D3DXPT_FLOAT
				Local inAutos:Int = False
				For Local Max2DVariable:String = EachIn Max2DShaderVariables
					If name = Max2DVariable
						_UniformsAuto.Insert(name, New TD3D9ShaderUniform.Create(name, desc.RegisterIndex, desc.RegisterCount, desc.Bytes, desc.Tipe, ShaderType))
						inAutos = True
						Exit
					EndIf
				Next
				If Not inAutos _UniformsUser.Insert(name, New TD3D9ShaderUniform.Create(name, desc.RegisterIndex, desc.RegisterCount, desc.Bytes, desc.Tipe, ShaderType))

			Case D3DXPT_SAMPLER2D
				_UniformsUser.Insert(name, New TD3D9ShaderSampler.Create(name, desc.RegisterIndex))
			
			Default DebugLog("Unsupported D3D9 shader variable type")
			EndSelect
		Next
		
		pTable.Release_()
	EndMethod
EndType

Type TD3D9ShaderProgram Extends TShaderProgram
	Field _Max2DDefaultsNeedUpdating:Int = True
	Field _VShader:IDirect3DVertexShader9
	Field _PShader:IDirect3DPixelShader9
	Field _UniformsAuto:TMap = New TMap
	Field _UniformsUser:TMap = New TMap
	
	Method GetShaderUniform:TShaderUniform(Name:String)
		Local Uniform:Object = _UniformsUser.ValueForKey(Name)
		Return TShaderUniform(Uniform)
	EndMethod

	Method GetShaderSampler:TShaderSampler(Name:String)
		Local Sampler:Object = _UniformsUser.ValueForKey(Name)
		Return TShaderSampler(Sampler)
	EndMethod
	
	Method Set()
		Device.SetVertexShader(_VShader)
		Device.SetPixelShader(_PShader)

		If _Max2DDefaultsNeedUpdating UpdateAutoUniforms()
		SetAutoUniforms()
		SetUserUniforms()
	EndMethod

	Method SetAutoUniforms()
		For Local node:TNode = EachIn _UniformsAuto
			Local constant:TD3D9ShaderUniform = TD3d9ShaderUniform(node._Value)
			If constant
				constant.Set()
				Continue
			EndIf
			Local sampler:TD3D9ShaderSampler = TD3D9ShaderSampler(node._Value)
			If sampler sampler.Set()
		Next		
	EndMethod

	Method SetUserUniforms()
		For Local node:TNode = EachIn _UniformsUser
			Local constant:TD3D9ShaderUniform = TD3D9ShaderUniform(node._Value)
			If constant
				constant.Set()
				Continue
			EndIf
			Local sampler:TD3D9ShaderSampler = TD3D9ShaderSampler(node._Value)
			If sampler sampler.Set()
		Next		
	EndMethod
	
	Method Unset()
		For Local node:TNode = EachIn _UniformsAuto
			Local constant:TD3D9ShaderUniform = TD3D9ShaderUniform(node._Value)
			If constant
				constant.Unset()
				Continue
			EndIf
			Local sampler:TD3D9ShaderSampler = TD3D9ShaderSampler(node._Value)
			If sampler sampler.Unset()
		Next
		For Local node:TNode = EachIn _UniformsUser
			Local constant:TD3D9ShaderUniform = TD3D9ShaderUniform(node._Value)
			If constant
				constant.Unset()
				Continue
			EndIf
			Local sampler:TD3D9ShaderSampler = TD3D9ShaderSampler(node._Value)
			If sampler sampler.Unset()
		Next
	EndMethod

	Method Reflect(VertexShader:TD3D9VertexShader, PixelShader:TD3D9PixelShader)
		_VShader = VertexShader._VShader
		_PShader = PixelShader._PShader
		
		_UniformsAuto.Clear()
		_UniformsUser.Clear()

		' vertex shader uniforms - autos and users
		For Local node:TNode = EachIn VertexShader._UniformsAuto
			Local constant:TD3D9ShaderUniform = TD3D9ShaderUniform(node._Value)
			If constant
				_UniformsAuto.Insert(constant._Name, constant)
				Continue
			EndIf
			Local sampler:TD3D9ShaderSampler = TD3D9ShaderSampler(node._value)
			If sampler _UniformsAuto.Insert(sampler._Name, sampler)
		Next
		For Local node:TNode = EachIn VertexShader._UniformsUser
			Local constant:TD3D9ShaderUniform = TD3D9ShaderUniform(node._Value)
			If constant
				_UniformsUser.Insert(constant._Name, constant)
				Continue
			EndIf
			Local sampler:TD3D9ShaderSampler = TD3D9ShaderSampler(node._value)
			If sampler _UniformsUser.Insert(sampler._Name, sampler)
		Next

		' pixel shader uniforms - autos and users
		For Local node:TNode = EachIn PixelShader._UniformsAuto
			Local constant:TD3D9ShaderUniform = TD3D9ShaderUniform(node._Value)
			If constant
				_UniformsAuto.Insert(constant._Name, constant)
				Continue
			EndIf
			Local sampler:TD3D9ShaderSampler = TD3D9ShaderSampler(node._value)
			If sampler _UniformsAuto.Insert(sampler._Name, sampler)
		Next
		For Local node:TNode = EachIn PixelShader._UniformsUser
			Local constant:TD3D9ShaderUniform = TD3D9ShaderUniform(node._Value)
			If constant
				_UniformsUser.Insert(constant._Name, constant)
				Continue
			EndIf
			Local sampler:TD3D9ShaderSampler = TD3D9ShaderSampler(node._value)
			If sampler _UniformsUser.Insert(sampler._Name, sampler)
		Next
	EndMethod
	
	Method ResetMax2DDefaults()
		_Max2DDefaultsNeedUpdating = True
	EndMethod
	
	Method UpdateAutoUniforms()
		For Local node:TNode = EachIn _UniformsAuto
			Local constant:TD3D9ShaderUniform = TD3d9ShaderUniform(node._Value)
			If constant
				' add more of these as required...
				Select constant._Name
				Case "BMaxProjectionMatrix"
					Local projection:Float[16]
					Device.GetTransform(D3DTS_PROJECTION, projection)
					constant.SetMatrix4x4(projection, False)
					
				'Case "BMaxTargetWidth"
				'Case "BMaxTargetHeight"
				'	DebugStop
				EndSelect
				Continue
			EndIf
		Next
		_Max2DDefaultsNeedUpdating = False
	EndMethod
EndType

Type TD3D9VertexShader Extends TVertexShader
	Field _VShader:IDirect3DVertexShader9
	Field _UniformsAuto:TMap
	Field _UniformsUser:TMap

	Method Compile:Int(source:String)
		Local pByteCode:ID3DBlob = CompileShader(Device, source, "VSMain", "vs_3_0")
		If pByteCode
			Device.CreateVertexShader(pByteCode.GetBufferPointer(), _VShader)
			Reflect(pByteCode)
			pByteCode.Release_()
			Return True
		EndIf
		Return False
	EndMethod
	
	Method Reflect(pBlob:ID3DBlob)
		Local reflector:TD3D9ShaderReflector = New TD3D9ShaderReflector
		reflector.Reflect(pBlob, 0)
		
		_UniformsAuto = reflector._UniformsAuto
		_UniformsUser = reflector._UniformsUser
	EndMethod
EndType

Type TD3D9PixelShader Extends TPixelShader
	Field _PShader:IDirect3DPixelShader9
	Field _UniformsAuto:TMap
	Field _UniformsUser:TMap
	
	Method Compile:Int(source:String)
		Local pByteCode:ID3DBlob = CompileShader(Device, source, "PSMain", "ps_3_0")
		If pByteCode
			Device.CreatePixelShader(pByteCode.GetBufferPointer(), _PShader)
			Reflect(pByteCode)
			pByteCode.Release_()
			Return True
		EndIf
		Return False
	EndMethod
	
	Method Reflect(pBlob:ID3DBlob)
		Local reflector:TD3D9ShaderReflector = New TD3D9ShaderReflector
		reflector.Reflect(pBlob, 1)
		
		_UniformsAuto = reflector._UniformsAuto
		_UniformsUser = reflector._UniformsUser
	EndMethod
EndType

Type TD3D9ShaderUniformBase Extends TShaderUniform
	Field _Name:String
	Field _Register:Int
	Field _Count:Int
	Field _Data:Byte Ptr
	Field _SizeBytes:Int
	Field _Type:Int
	Field _IsRendering:Int
	Field _ShaderType:Int
EndType

Type TD3D9ShaderUniform Extends TD3D9ShaderUniformBase
	Method Create:TD3D9ShaderUniform(Name:String, Register:Int, Count:Int, SizeBytes:Int, Tipe:Int, ShaderType:Int)
		_Name = Name
		_Type = Tipe
		_Register = Register
		_Count = Count
		_SizeBytes = SizeBytes
		_Data = MemAlloc(SizeBytes)
		_ShaderType = ShaderType
		Return Self
	EndMethod
	
	Method Delete()
		MemFree(_Data)
	EndMethod

	Method SetFloat(Data:Float)
?debug
		If DebugData(4) Return
?
		Float Ptr(_Data)[0] = Data
		If _IsRendering Upload()
	EndMethod

	Method SetFloat2(Data1:Float, Data2:Float)
?debug
		If DebugData(8) Return
?
		Float Ptr(_Data)[0] = Data1; Float Ptr(_Data)[1] = Data2
		If _IsRendering Upload()
	EndMethod
	
	Method SetFloat3(Data1:Float, Data2:Float, Data3:Float)
?debug
		If DebugData(12) Return
?
		Float Ptr(_Data)[0] = Data1; Float Ptr(_Data)[1] = Data2; Float Ptr(_Data)[2] = Data3
		If _IsRendering Upload()	
	EndMethod
	
	Method SetFloat4(Data1:Float, Data2:Float, Data3:Float, Data4:Float)
?debug
		If DebugData(16) Return
?
		Float Ptr(_Data)[0] = Data1; Float Ptr(_Data)[1] = Data2
		Float Ptr(_Data)[2] = Data3; Float Ptr(_Data)[3] = Data4
		If _IsRendering Upload()
	EndMethod
	
	Method SetInt(Data:Int)
?debug
		If DebugData(4) Return
?
		Int Ptr(_Data)[0] = Data
	EndMethod
	
	Method SetInt2(Data1:Int, Data2:Int)
?debug
		If DebugData(8) Return
?
		Int Ptr(_Data)[0] = Data1; Int Ptr(_Data)[1] = Data2
		If _IsRendering Upload()
	EndMethod
	
	Method SetInt3(Data1:Int, Data2:Int, Data3:Int)
?debug
		If DebugData(12) Return
?
		Int Ptr(_Data)[0] = Data1; Int Ptr(_Data)[1] = Data2
		Int Ptr(_Data)[2] = Data3
		If _IsRendering Upload()
	EndMethod
	
	Method SetInt4(Data1:Int, Data2:Int, Data3:Int, Data4:Int)
?debug
		If DebugData(16) Return
?
		Int Ptr(_Data)[0] = Data1; Int Ptr(_Data)[1] = Data2
		Int Ptr(_Data)[2] = Data3; Int Ptr(_Data)[3] = Data4
		If _IsRendering Upload()
	EndMethod
	
	Method SetMatrix4x4(Data:Float[], IsTranspose:Byte)
?debug
		If DebugData(SizeOf(Data)) Return
?
		'_IsTranspose = IsTranspose
		MemCopy(_Data, Data, _SizeBytes)
		If _IsRendering Upload()
	EndMethod
	
	Method DebugData:Int(SizeBytes:Int)
		If(SizeBytes = _SizeBytes) Return False
		
		Local debug:String = "ERROR! TD3D9ShaderUniform: '" + _Name + "' requires " + _SizeBytes
		debug :+ " bytes to be set but " + SizeBytes + " are being presented."
		DebugLog(debug)
		Return True
	EndMethod
	
	Method Set()
		Upload()
		_IsRendering = True
	EndMethod
	
	Method Unset()
		_IsRendering = False
	EndMethod
	
	Method Upload()
		If _ShaderType = 0
			Select _Type
			Case D3DXPT_BOOL  Device.SetVertexShaderConstantB(_Register, Int Ptr(_Data), _Count)
			Case D3DXPT_INT   Device.SetVertexShaderConstantI(_Register, Int Ptr(_Data), _Count)
			Case D3DXPT_FLOAT Device.SetVertexShaderConstantF(_Register, Float Ptr(_Data), _Count)
			EndSelect
		Else
			Select _Type
			Case D3DXPT_BOOL  Device.SetPixelShaderConstantB(_Register, Int Ptr(_Data), _Count)
			Case D3DXPT_INT   Device.SetPixelShaderConstantI(_Register, Int Ptr(_Data), _Count)
			Case D3DXPT_FLOAT Device.SetPixelShaderConstantF(_Register, Float Ptr(_Data), _Count)
			EndSelect
		EndIf
	EndMethod

EndType

Type TD3D9ShaderSampler Extends TShaderSampler
	Field _Name:String
	Field _Register:Int
	Field _Index:Int
	Field _IsRendering:Int
	Field _Image:TImage

	Method Create:TD3D9ShaderSampler(Name:String, Register:Int)
		_Name = name
		_Register = Register
		Return Self
	EndMethod
	
	Method SetIndex(Index:Int, Image:Object)
		Local Max2DImage:TImage = TImage(Image)
		If Not Max2DImage Return
		Local frame:TD3D9ImageFrame = TD3D9ImageFrame(Max2DImage.frames[0])
		If Not frame Return
		
		_Image = Max2DImage
		_Index = Index
		If _IsRendering Upload()
	EndMethod
	
	Method Set()
		Upload()
		_IsRendering = True
	EndMethod
	
	Method Unset()
		_IsRendering = False
	EndMethod

	Method Upload()
		Device.SetTexture(_Register, TD3D9ImageFrame(_Image.frames[0])._texture) 
	EndMethod
EndType

Type TD3D9ShaderFramework Extends TShaderFramework
	Field CurrentProgram:TD3D9ShaderProgram
	
	Method Create:TD3D9ShaderFramework(gc:TGraphics)
		Local d3d9g:TD3D9Graphics = TD3D9Graphics(gc)
		Device = d3d9g.GetDirect3DDevice()
		Return Self
	EndMethod
	
	Method CreateShaderProgram:TShaderProgram(VertexShader:TVertexShader, PixelShader:TPixelShader)
?debug
		Assert TD3D9VertexShader(VertexShader) <> Null, "Invalid vertex shader"
		Assert TD3D9PixelShader(PixelShader) <> Null, "Invalid pixel shader"
?	
		Local sp:TD3D9ShaderProgram = New TD3D9ShaderProgram
		sp.Reflect(TD3D9VertexShader(vertexshader), TD3D9PixelShader(pixelshader))
		Return sp
	EndMethod
	
	Method CreateVertexShader:TVertexShader(source:String)
		Local vs:TD3D9VertexShader = New TD3D9VertexShader
		If Not vs.Compile(source) Return Null
		Return vs
	EndMethod
	
	Method CreatePixelShader:TPixelShader(source:String)
		Local ps:TD3D9PixelShader = New TD3D9PixelShader
		If Not ps.Compile(source) Return Null
		Return ps
	EndMethod
	
	Method SetShader(ShaderProgram:TShaderProgram)
		If ShaderProgram <> CurrentProgram And CurrentProgram <> Null CurrentProgram.Unset()

		If ShaderProgram <> Null
?debug
			Assert TD3D9ShaderProgram(ShaderProgram) <> Null, "Invalid shader program"
?
			CurrentProgram = TD3D9ShaderProgram(ShaderProgram)
			TD3D9ShaderProgram(ShaderProgram).Set()
			Return
		EndIf

		CurrentProgram = Null
		Device.SetVertexShader(Null)
		Device.SetPixelShader(Null)
	EndMethod
EndType















Type D3DXCONSTANTTABLE_DESC
	Field Creator:Byte Ptr
	Field Version:Int
	Field ConstantCount:Int
EndType

Type D3DXCONSTANT_DESC
	Field Name:Byte Ptr
	Field RegisterSet:Int	' D3DXREGISTER_SET
	Field RegisterIndex:Int
	Field RegisterCount:Int
	Field Class:Int 		' D3DXPARAMETER_CLASS
	Field Tipe:Int			' D3DXPARAMETER_TYPE
	Field Rows:Int
	Field Columns:Int
	Field Elements:Int
	Field StructMembers:Int
	Field Bytes:Int
	Field DefaultValue:Byte Ptr
EndType

?BmxNG
Extern "Win32"
Interface ID3DBlob Extends IUnknown_
	Method GetBufferPointer:Byte Ptr()
	Method GetBufferSize()
EndInterface

Interface ID3DXConstantTable Extends IUnknown_
	Method GetBufferPointer:Byte Ptr()
	Method GetBufferSize:Int()

	Method GetDesc:Int(pDesc:Byte Ptr)
	Method GetConstantDesc:Int(hConstant:Byte Ptr, pDesc:Byte Ptr, pCount:Int Ptr)
	Method GetSamplerIndex:Int(hConstant:Byte Ptr)
	
	Method GetConstant:Byte Ptr(hConstant:Byte Ptr, Index:Int)
	Method GetConstantByName:Byte Ptr(hConstant:Byte Ptr, pName:Short Ptr)
	Method GetConstantElement:Byte Ptr(hConstant:Byte Ptr, Index:Int)
	
	Method SetDefaults:Int(pDevice:IDirect3DDevice9)
	Method SetValue:Int(pDevice:IDirect3DDevice9, hConstant:Byte Ptr, pData:Byte Ptr, Bytes:Int)
	Method SetBool:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, b:Int)
	Method SetBoolArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pb:Byte Ptr, Count:Int)
	Method SetInt:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, n:Int)
	Method SetIntArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pn:Int Ptr, Count:Int)
	Method SetFloat:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, f:Float)
	Method SetFloatArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pf:Float Ptr, Count:Int)
	Method SetVector:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pVector:Byte Ptr)
	Method SetVectorArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pVector:Byte Ptr, Count:Int)
	Method SetMatrix:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pMatrix:Byte Ptr)
	Method SetMatrixArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pMatrix:Byte Ptr, Count:Int)
	Method SetMatrixPointerArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, ppMatrix:Byte Ptr, Count:Int)
	Method SetMatrixTranspose:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pMatrix:Byte Ptr)
	Method SetMatrixTransposeArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pMatrix:Byte Ptr, Count:Int)
	Method SetMatrixTransposePointerArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, ppMatrix:Byte Ptr, Count:Int)
EndInterface
EndExtern
Global D3DCompilerDll:Byte Ptr = LoadLibraryA("d3dcompiler_47.dll")
If Not D3DCompilerDll D3DCompilerDll = LoadLibraryA("d3dcompiler_43.dll")

Global D3DX9Dll:Byte Ptr = LoadLibraryA("d3dx9_43.dll")
?

?Not BmxNG
Extern "Win32"
Type ID3DBlob Extends IUnknown
	Method GetBufferPointer:Byte Ptr()
	Method GetBufferSize()
EndType

Type ID3DXConstantTable Extends IUnknown
	Method GetBufferPointer:Byte Ptr()
	Method GetBufferSize:Int()

	Method GetDesc:Int(pDesc:Byte Ptr)
	Method GetConstantDesc:Int(hConstant:Byte Ptr, pDesc:Byte Ptr, pCount:Int Ptr)
	Method GetSamplerIndex:Int(hConstant:Byte Ptr)
	
	Method GetConstant:Byte Ptr(hConstant:Byte Ptr, Index:Int)
	Method GetConstantByName:Byte Ptr(hConstant:Byte Ptr, pName:Short Ptr)
	Method GetConstantElement:Byte Ptr(hConstant:Byte Ptr, Index:Int)
	
	Method SetDefaults:Int(pDevice:IDirect3DDevice9)
	Method SetValue:Int(pDevice:IDirect3DDevice9, hConstant:Byte Ptr, pData:Byte Ptr, Bytes:Int)
	Method SetBool:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, b:Int)
	Method SetBoolArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pb:Byte Ptr, Count:Int)
	Method SetInt:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, n:Int)
	Method SetIntArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pn:Int Ptr, Count:Int)
	Method SetFloat:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, f:Float)
	Method SetFloatArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pf:Float Ptr, Count:Int)
	Method SetVector:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pVector:Byte Ptr)
	Method SetVectorArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pVector:Byte Ptr, Count:Int)
	Method SetMatrix:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pMatrix:Byte Ptr)
	Method SetMatrixArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pMatrix:Byte Ptr, Count:Int)
	Method SetMatrixPointerArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, ppMatrix:Byte Ptr, Count:Int)
	Method SetMatrixTranspose:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pMatrix:Byte Ptr)
	Method SetMatrixTransposeArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, pMatrix:Byte Ptr, Count:Int)
	Method SetMatrixTransposePointerArray:Int(pDevice:IDirect3DDevice9, hConsant:Byte Ptr, ppMatrix:Byte Ptr, Count:Int)
EndType
EndExtern
Global D3DCompilerDll:Int = LoadLibraryA("d3dcompiler_47.dll")
If Not D3DCompilerDll D3DCompilerDll = LoadLibraryA("d3dcompiler_43.dll")

Global D3DX9Dll:Int = LoadLibraryA("d3dx9_43.dll")

If Not D3DX9Dll
?bmxng
Return 0
?Not bmxng
Return
?
EndIf

If Not D3DCompilerDll
?bmxng
Return 0
?Not bmxng
Return
?
EndIf

Global D3DCreateBlob:Int(Size:Int ,ppBlob:ID3DBlob Var)"win32" = GetProcAddress(D3DCompilerDll,"D3DCreateBlob")
Global D3DCompile:Int(pSrcData:Byte Ptr, SrcDataSize:Int, pSourceName:Byte Ptr,pDefines:Byte Ptr,pInclude:Byte Ptr,pEntryPoint:Byte Ptr,pTarget:Byte Ptr,Flags1:Int,Flags2:Int,ppCode:ID3DBlob Var,ppErrorMsgs:ID3DBlob Var)"win32" = GetProcAddress(D3DCompilerDll,"D3DCompile")
Global D3DXGetShaderConstantTable:Int(pFunction:Byte Ptr, ppConstantTable:ID3DXConstantTable Var)"Win32" = GetProcAddress(D3DX9Dll, "D3DXGetShaderConstantTable")

Function CompileShader:ID3DBlob(device:IDirect3DDevice9, source:String, entrypoint:String, target:String)
	Const D3DCOMPILE_DEBUG:Int = 1
	Const D3DCOMPILE_OPTIMIZATION_LEVEL3:Int = 1 Shl 15
	
	Local pByteCode:ID3DBlob
	Local pErrors:ID3DBlob

	Local compileFlags:Int = D3DCOMPILE_OPTIMIZATION_LEVEL3
?Debug
    compileFlags = D3DCOMPILE_DEBUG
?

	If Not D3DCompile
		DebugLog("D3DCompile function pointer is invalid - maybe update DirectX?")
		Return Null
	EndIf

	D3DCompile(source, source.Length, "", Null, Null, entrypoint, target, compileFlags, 0, pByteCode, pErrors)
	If pErrors
		DebugLog(String.FromCString(pErrors.GetBufferPointer()))
		pErrors.Release_()
		Return Null	
	EndIf
	
	Return pByteCode
EndFunction









