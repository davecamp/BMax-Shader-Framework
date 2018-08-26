
SuperStrict
Import "-lOle32"

Import brl.map
Import pub.win32
Import srs.d3d11max2d
Import "d3dcompiler.bmx"
Import "tshaderframework.bmx"
Import "max2dshadervariables.bmx"
Import "d3d11shaderreflector.cpp"

Private

Extern"C"
Function ConstantBuffer_GetDesc:Int(pConstantBuffer:Byte Ptr, pDesc:Byte Ptr)
Function ConstantBuffer_GetVariableByIndex:Byte Ptr(pConstantBuffer:Byte Ptr, Index:Int)
Function Variable_GetDesc:Int(pShaderVariable:Byte Ptr, pDesc:Byte Ptr)
Function Variable_GetType:Byte Ptr(pVariable:Byte Ptr)
Function Type_GetDesc(pType:Byte Ptr, pDesc:Byte Ptr)
EndExtern

Global Device:ID3D11Device
Global DeviceContext:ID3D11DeviceContext

Const D3D_SIT_CBUFFER:Int = 0
Const D3D_SIT_TEXTURE:Int = 2
Const D3D_SIT_SAMPLER:Int = 3

Extern"Win32"
Type ID3D11ShaderReflection Extends IUnknown   
	Method GetDesc:Int(pDesc:Byte Ptr)
	
	Method GetConstantBufferByIndex:Byte Ptr(Index:Int)
	Method GetConstantBufferByName:Byte Ptr(Name:Byte Ptr)
	Method GetResourceBindingDesc:Int(ResourceIndex:Int, pDesc:Byte Ptr)
	Method GetInputParameterDesc:Int(ParameterIndex:Int, pDesc:Byte Ptr)
	Method GetOutputParameterDesc:Int(ParameterIndex:Int, pDesc:Byte Ptr)
	Method GetPatchConstantParameterDesc:Int(ParameterIndex:Int, pDesc:Byte Ptr)
	
	Method GetVariableByName:Byte Ptr(Name:Byte Ptr)
	
	Method GetResourceBindingDescByName(Name:Byte Ptr, pDesc:Byte Ptr)
	
	Method GetMovInstructionCount:Int()
	Method GetMovcInstructionCount:Int()
	Method GetConversionInstructionCount:Int()
	Method GetBitwiseInstructionCount:Int()
	
	Method GetGSInputPrimitive:Int()
	Method IsSampleFrequencyShader:Int()
	
	Method GetNumInterfaceSlots:Int()
	Method GetMinFeatureLevel:Int(pLevel:Int Ptr)
	
	Method GetThreadGroupSize:Int(pSizeX:Int Ptr, pSizeY:Int Ptr, pSizeZ:Int Ptr)
	
	Method GetRequiresFlags:Long()
EndType
EndExtern

Type D3D_SHADER_DESC
	Field Version:Int
	Field Creator:Byte Ptr
	Field Flags:Int
	
	Field ConstantBuffers:Int
	Field BoundResources:Int
	Field InputParameters:Int
	Field OutputParameters:Int

	Field InstructionCount:Int
	Field TempRegisterCount:Int
	Field TempArrayCount:Int
	Field DefCount:Int
	Field DclCount:Int
	Field TextureNormalInstructions:Int
	Field TextureLoadInstructions:Int
	Field TextureCompInstructions:Int
	Field TextureBiasInstructions:Int
	Field TextureGradientInstructions:Int
	Field FloatInstructionCount:Int
	Field IntInstructionCount:Int
	Field UintInstructionCount:Int
	Field StaticFlowControlCount:Int
	Field DynamicFlowControlCount:Int
	Field MacroInstructionCount:Int
	Field ArrayInstructionCount:Int
	Field CutInstructionCount:Int
	Field EmitInstructionCount:Int
	Field GSOutputTopology:Int ' D3D_PRIMITIVE_TOPOLGY
	Field GSMaxOutputVertexCount:Int
	Field InputPrimitive:Int ' D3D_PRIMITIVE
	Field PatchConstantParameters:Int
	Field cGSInstanceCount:Int
	Field cControlPoints:Int
	Field HSOutputPrimitive:Int ' D3D_TESSELLATOR_OUTPUT_PRIMITIVE
	Field HSPartitioning:Int ' D3D_TESSELLATOR_PARTITIONING
	Field TessellatorDomain:Int ' D3D_TESSELLATOR_DOMAIN
	Field cBarrierInstructions:Int
	Field cInterlockedInstructions:Int
	Field cTextureStoreInstructions:Int
EndType

Type D3D11_SHADER_BUFFER_DESC
	Field Name:Byte Ptr
	Field Tipe:Int ' D3D_CBUFFER_TYPE
	Field Variables:Int
	Field Size:Int
	Field uFlags:Int
EndType

Type D3D11_SHADER_INPUT_BIND_DESC
	Field Name:Byte Ptr
	Field Tipe:Int ' D3D_SHADER_INPUT_TYPE
	Field BindPoint:Int
	Field BindCount:Int
	Field uFlags:Int
	Field ReturnType:Int ' D3D_RESOURCE_RETURN_TYPE
	Field Dimension:Int ' D3D_SRV_DIMENSION
	Field NumSamples:Int
EndType

Type D3D11_SHADER_TYPE_DESC
	Field Class:Int
	Field Tipe:Int
	Field Rows:Int
	Field Columns:Int
	Field Members:Int
	Field Offset:Int
	Field Name:Byte Ptr
EndType

Type TD3D11ShaderReflector
	Field _UniformsAuto:TMap = New TMap
	Field _UniformsUser:TMap = New TMap

	Method Reflect(pBlob:ID3DBlob, ShaderType:Int)
		Local pByteCode:Byte Ptr = pBlob.GetBufferPointer()
		Local pReflector:ID3D11ShaderReflection
		D3DReflect(pBlob.GetBufferPointer(), pBlob.GetBufferSize(), IID_ID3D11ShaderReflection, Varptr pReflector)

		Local ShaderDesc:D3D11_SHADER_DESC = New D3D11_SHADER_DESC
		pReflector.GetDesc(ShaderDesc)

		For Local i:Int = 0 Until ShaderDesc.BoundResources
			Local BindDesc:D3D11_SHADER_INPUT_BIND_DESC = New D3D11_SHADER_INPUT_BIND_DESC
			pReflector.GetResourceBindingDesc(i, BindDesc)
			
			Select BindDesc.Tipe
			Case D3D_SIT_CBUFFER
				Local pConstantBuffer:Byte Ptr = pReflector.GetConstantBufferByName(BindDesc.Name)
				ReflectConstantBuffer(pConstantBuffer, BindDesc.Name)
			
			Case D3D_SIT_TEXTURE
				Local name:String = String.FromCString(BindDesc.Name)
				DebugStop
				
			Case D3D_SIT_SAMPLER
				Local name:String = String.FromCString(BindDesc.Name)
				DebugStop

			EndSelect
		Next
		
		pReflector.Release_()
	EndMethod
	
	Method ReflectConstantBuffer(pConstantBuffer:Byte Ptr, Name:Byte Ptr)
		Local BufferDesc:D3D11_SHADER_BUFFER_DESC = New D3D11_SHADER_BUFFER_DESC
		ConstantBuffer_GetDesc(pConstantBuffer, BufferDesc)
		
		Local BufferName:String = String.FromCString(BufferDesc.Name)
		Local Buffer:ConstantBuffer = New ConstantBuffer.Create(BufferName, BufferDesc.Size)
		If Not Buffer Return

		For Local i:Int = 0 Until BufferDesc.Variables
			' Get variable within constant buffer
			Local pVariable:Byte Ptr = ConstantBuffer_GetVariableByIndex(pConstantBuffer, i)
			
			Local VariableDesc:D3D11_SHADER_VARIABLE_DESC = New D3D11_SHADER_VARIABLE_DESC
			Variable_GetDesc(pVariable, VariableDesc)
			Local Name:String = String.FromCString(VariableDesc.Name)
			
			' get variable type
			Local pType:Byte Ptr = Variable_GetType(pVariable)
			Local TypeDesc:D3D11_SHADER_TYPE_DESC = New D3D11_SHADER_TYPE_DESC
			Type_GetDesc(pType, TypeDesc)
			
			If BufferName = "Max2D"
				_UniformsAuto.Insert(Name, New TD3D11ShaderUniform.Create(Buffer, Name, VariableDesc.StartOffset, VariableDesc.Size, 0))
				Continue
			EndIf
			_UniformsUser.Insert(Name, New TD3D11ShaderUniform.Create(Buffer, Name, VariableDesc.StartOffset, VariableDesc.Size, 0))
		Next
	EndMethod
EndType

Type ConstantBuffer
	Field _Name:String
	Field _Buffer:ID3D11Buffer
	Field _Data:Byte Ptr
	Field _Size:Int
	
	Method Delete()
		MemFree(_Data)
	EndMethod

	Method Create:ConstantBuffer(Name:String, Size:Int)
		Local desc:D3D11_BUFFER_DESC = New D3D11_BUFFER_DESC
		desc.ByteWidth = Size
		desc.Usage = D3D11_USAGE_DYNAMIC
		desc.BindFlags = D3D11_BIND_CONSTANT_BUFFER
		desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE
		desc.MiscFlags = 0
		desc.StructureByteStride = 0
		
		If Device.CreateBuffer(desc, Null, _Buffer) < 0
			DebugLog "Could not create '" + Name + "' constant buffer"
			Return Null
		EndIf
		
		_Size = Size
		_Name = Name
		_Data = MemAlloc(Size)
		Return Self
	EndMethod
	
	Method Upload()
		Local map:D3D11_MAPPED_SUBRESOURCE = New D3D11_MAPPED_SUBRESOURCE
		If DeviceContext.Map(_Buffer, 0, D3D11_MAP_WRITE_DISCARD, 0, map) < 0
			DebugLog("Unable to map constant buffer '" + _Name + "'")
			Return
		EndIf
		
		MemCopy(map.pData, _Data, _Size)
		DeviceContext.Unmap(_Buffer, 0)
	EndMethod
EndType

Public

Type TD3D11ShaderProgram Extends TShaderProgram
	Field _Max2DDefaultsNeedUpdating:Int = True
	Field _Max2DProjMatrix:Float[16]

	Field _VShader:ID3D11VertexShader
	Field _PShader:ID3D11PixelShader
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
		DeviceContext.VSSetShader(_VShader, Null, 0)
		DeviceContext.PSSetShader(_PShader, Null, 0)
		
		If _Max2DDefaultsNeedUpdating UpdateAutoUniforms()
		For Local node:TNode = EachIn _UniformsAuto
			Local constant:TD3D11ShaderUniform = TD3D11ShaderUniform(node._Value)
			If constant
				constant.Set()
				Continue
			EndIf
			Local sampler:TD3D11ShaderSampler = TD3D11ShaderSampler(node._Value)
			'If sampler sampler.Set()
		Next
		For Local node:TNode = EachIn _UniformsUser
			Local constant:TD3D11ShaderUniform = TD3D11ShaderUniform(node._Value)
			If constant
				constant.Set()
				Continue
			EndIf
			Local sampler:TD3D11ShaderSampler = TD3D11ShaderSampler(node._Value)
			'If sampler sampler.Set()
		Next
	EndMethod
	
	Method Unset()
		For Local node:TNode = EachIn _UniformsAuto
			Local constant:TD3D11ShaderUniform = TD3D11ShaderUniform(node._Value)
			If constant
				constant.Unset()
				Continue
			EndIf
			Local sampler:TD3D11ShaderSampler = TD3D11ShaderSampler(node._Value)
			'If sampler sampler.Unset()
		Next
		For Local node:TNode = EachIn _UniformsUser
			Local constant:TD3D11ShaderUniform = TD3D11ShaderUniform(node._Value)
			If constant
				constant.Unset()
				Continue
			EndIf
			Local sampler:TD3D11ShaderSampler = TD3D11ShaderSampler(node._Value)
			'If sampler sampler.Unset()
		Next
	EndMethod
	
	Method ResetMax2DDefaults()
		_Max2DDefaultsNeedUpdating = True
	EndMethod
	
	Method Reflect(VertexShader:TD3D11VertexShader, PixelShader:TD3D11PixelShader)
		_VShader = VertexShader._VShader
		_PShader = PixelShader._PShader

		_UniformsAuto.Clear()
		_UniformsUser.Clear()

		GetMax2DProjectionMatrix()

		' vertex shader uniforms - autos and users
		For Local node:TNode = EachIn VertexShader._UniformsAuto
			Local constant:TD3D11ShaderUniform = TD3D11ShaderUniform(node._Value)
			If constant
				_UniformsAuto.Insert(constant._Name, constant)
				Continue
			EndIf
			Local sampler:TD3D11ShaderSampler = TD3D11ShaderSampler(node._value)
			If sampler _UniformsAuto.Insert(sampler._Name, sampler)
		Next
		For Local node:TNode = EachIn VertexShader._UniformsUser
			Local constant:TD3D11ShaderUniform = TD3D11ShaderUniform(node._Value)
			If constant
				_UniformsUser.Insert(constant._Name, constant)
				Continue
			EndIf
			Local sampler:TD3D11ShaderSampler = TD3D11ShaderSampler(node._value)
			If sampler _UniformsUser.Insert(sampler._Name, sampler)
		Next

		' pixel shader uniforms - autos and users
		For Local node:TNode = EachIn PixelShader._UniformsAuto
			Local constant:TD3D11ShaderUniform = TD3D11ShaderUniform(node._Value)
			If constant
				_UniformsAuto.Insert(constant._Name, constant)
				Continue
			EndIf
			Local sampler:TD3D11ShaderSampler = TD3D11ShaderSampler(node._value)
			If sampler _UniformsAuto.Insert(sampler._Name, sampler)
		Next
		For Local node:TNode = EachIn PixelShader._UniformsUser
			Local constant:TD3D11ShaderUniform = TD3D11ShaderUniform(node._Value)
			If constant
				_UniformsUser.Insert(constant._Name, constant)
				Continue
			EndIf
			Local sampler:TD3D11ShaderSampler = TD3D11ShaderSampler(node._value)
			If sampler _UniformsUser.Insert(sampler._Name, sampler)
		Next
	EndMethod
	
	Method GetMax2DProjectionMatrix()
		Local Buffer:ID3D11Buffer
		If DeviceContext.VSGetConstantBuffers(0, 1, Varptr Buffer) >= 0
			Local desc:D3D11_BUFFER_DESC = New D3D11_BUFFER_DESC
			If Buffer.GetDesc(desc) >= 0
				desc.Usage = D3D11_USAGE_STAGING
				desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ
				desc.BindFlags = 0

				Local Staging:ID3D11Buffer
				If Device.CreateBuffer(desc, Null, Staging) >= 0
					DeviceContext.CopyResource(Staging, Buffer)
					
					Local map:D3D11_MAPPED_SUBRESOURCE = New D3D11_MAPPED_SUBRESOURCE
					DeviceContext.Map(Staging, 0, D3D11_MAP_READ, 0, map)
					MemCopy(_Max2DProjMatrix, map.pData, 64)
					
					DeviceContext.Unmap(Staging, 0)
					Staging.Release_()
				EndIf
			EndIf
			Buffer.Release_()
		EndIf
	EndMethod
	
	Method UpdateAutoUniforms()
		GetMax2DProjectionMatrix()

		For Local node:TNode = EachIn _UniformsAuto
			Local constant:TD3D11ShaderUniform = TD3D11ShaderUniform(node._Value)
			If constant
				' add more of these as required...
				Select constant._Name
				Case BMAX_PROJECTION_MATRIX
					constant.SetMatrix4x4(_Max2DProjMatrix, False)
					
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

Type TD3D11VertexShader Extends TVertexShader
	Field _VShader:ID3D11VertexShader
	Field _UniformsAuto:TMap
	Field _UniformsUser:TMap

	Method Compile:Int(source:String)
		Local pByteCode:ID3DBlob = CompileShader(Device, source, "VSMain", "vs_5_0")
		If pByteCode
			Device.CreateVertexShader(pByteCode.GetBufferPointer(), pByteCode.GetBufferSize(), Null, _VShader)
			Reflect(pByteCode)
			pByteCode.Release_()
			Return True
		EndIf
		Return False
	EndMethod
	
	Method Reflect(pBlob:ID3DBlob)
		Local reflector:TD3D11ShaderReflector = New TD3D11ShaderReflector
		reflector.Reflect(pBlob, 0)
		
		_UniformsAuto = reflector._UniformsAuto
		_UniformsUser = reflector._UniformsUser
	EndMethod
EndType

Type TD3D11PixelShader Extends TPixelShader
	Field _PShader:ID3D11PixelShader
	Field _UniformsAuto:TMap
	Field _UniformsUser:TMap
	
	Method Compile:Int(source:String)
		Local pByteCode:ID3DBlob = CompileShader(Device, source, "PSMain", "ps_5_0")
		If pByteCode
			Device.CreatePixelShader(pByteCode.GetBufferPointer(), pByteCode.GetBufferSize(), Null, _PShader)
			Reflect(pByteCode)
			pByteCode.Release_()
			Return True
		EndIf
		Return False
	EndMethod
	
	Method Reflect(pBlob:ID3DBlob)
		Local reflector:TD3D11ShaderReflector = New TD3D11ShaderReflector
		reflector.Reflect(pBlob, 1)
		
		_UniformsAuto = reflector._UniformsAuto
		_UniformsUser = reflector._UniformsUser
	EndMethod
EndType

Type TD3D11ShaderUniform Extends TShaderUniform
	Field _Owner:ConstantBuffer
	Field _Name:String
	Field _Offset:Int
	Field _SizeBytes:Int
	Field _Type:Int
	Field _IsRendering:Int
	
	Method Create:TShaderUniform(Owner:ConstantBuffer, Name:String, Offset:Int, SizeBytes:Int, Tipe:Int)
		_Owner = Owner
		_Name = Name
		_Offset = Offset
		_SizeBytes = SizeBytes
		_Type = Tipe	
		Return Self
	EndMethod
	
	Method SetFloat(Data:Float)
		?debug
		If DebugData(4) Return
?
		Float Ptr(_Owner._Data)[0] = Data
		If _IsRendering Upload()
	EndMethod
	
	Method SetFloat2(Data1:Float, Data2:Float)
?debug
		If DebugData(8) Return
?
		Float Ptr(_Owner._Data)[0] = Data1; Float Ptr(_Owner._Data)[1] = Data2
		If _IsRendering Upload()
	EndMethod

	Method SetFloat3(Data1:Float, Data2:Float, Data3:Float)
?debug
		If DebugData(12) Return
?
		Float Ptr(_Owner._Data)[0] = Data1; Float Ptr(_Owner._Data)[1] = Data2; Float Ptr(_Owner._Data)[2] = Data3
		If _IsRendering Upload()
	EndMethod

	Method SetFloat4(Data1:Float, Data2:Float, Data3:Float, Data4:Float)
?debug
		If DebugData(16) Return
?
		Float Ptr(_Owner._Data)[0] = Data1; Float Ptr(_Owner._Data)[1] = Data2
		Float Ptr(_Owner._Data)[2] = Data3; Float Ptr(_Owner._Data)[3] = Data4
		If _IsRendering Upload()
	EndMethod

	Method SetInt(Data:Int)
?debug
		If DebugData(4) Return
?
		Int Ptr(_Owner._Data)[0] = Data
	EndMethod

	Method SetInt2(Data1:Int, Data2:Int)
?debug
		If DebugData(8) Return
?
		Int Ptr(_Owner._Data)[0] = Data1; Int Ptr(_Owner._Data)[1] = Data2
		If _IsRendering Upload()
	EndMethod

	Method SetInt3(Data1:Int, Data2:Int, Data3:Int)
?debug
		If DebugData(12) Return
?
		Int Ptr(_Owner._Data)[0] = Data1; Int Ptr(_Owner._Data)[1] = Data2
		Int Ptr(_Owner._Data)[2] = Data3
		If _IsRendering Upload()
	EndMethod

	Method SetInt4(Data1:Int, Data2:Int, Data3:Int, Data4:Int)
?debug
		If DebugData(16) Return
?
		Int Ptr(_Owner._Data)[0] = Data1; Int Ptr(_Owner._Data)[1] = Data2
		Int Ptr(_Owner._Data)[2] = Data3; Int Ptr(_Owner._Data)[3] = Data4
		If _IsRendering Upload()
	EndMethod

	Method SetMatrix4x4(Data:Float[], IsTranspose:Byte)
?debug
		If DebugData(SizeOf(Data)) Return
?
		'_IsTranspose = IsTranspose
		MemCopy(_Owner._Data, Data, _SizeBytes)
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
		_Owner.Upload()
	EndMethod
EndType

Type TD3D11ShaderSampler Extends TShaderSampler
	Field _Name:String

	Method SetIndex(Index:Int, Image:Object)
		DebugStop
	EndMethod
EndType

Type TD3D11ShaderFramework Extends TShaderFramework
	Field CurrentProgram:TD3D11ShaderProgram
	Field DefaultVertexShader:ID3D11VertexShader
	Field DefaultPixelShader:ID3D11PixelShader

	Method Create:TD3D11ShaderFramework(gc:TGraphics)
		Local d3d11g:TD3D11Graphics = TD3D11Graphics(gc)
		Device = d3d11g.GetDirect3DDevice()
		DeviceContext = d3d11g.GetDirect3DDeviceContext()
		
		Local nullInt:Int
		DeviceContext.VSGetShader(DefaultVertexShader, Null, nullInt)
		DeviceContext.PSGetShader(DefaultPixelShader, Null, nullInt)
		Return Self
	EndMethod

	Method CreateShaderProgram:TShaderProgram(VertexShader:TVertexShader, PixelShader:TPixelShader)
?debug
		Assert TD3D11VertexShader(VertexShader) <> Null, "Invalid vertex shader"
		Assert TD3D11PixelShader(PixelShader) <> Null, "Invalid pixel shader"
?	
		Local sp:TD3D11ShaderProgram = New TD3D11ShaderProgram
		sp.Reflect(TD3D11VertexShader(vertexshader), TD3D11PixelShader(pixelshader))
		Return sp
	EndMethod
	
	Method CreateVertexShader:TVertexShader(source:String)
		Local vs:TD3D11VertexShader = New TD3D11VertexShader
		If Not vs.Compile(source) Return Null
		Return vs
	EndMethod
	
	Method CreatePixelShader:TPixelShader(source:String)
		Local ps:TD3D11PixelShader = New TD3D11PixelShader
		If Not ps.Compile(source) Return Null
		Return ps
	EndMethod
	
	Method SetShader(ShaderProgram:TShaderProgram)
		If ShaderProgram <> CurrentProgram And CurrentProgram <> Null CurrentProgram.Unset()

		If ShaderProgram <> Null
?debug
			Assert TD3D11ShaderProgram(ShaderProgram) <> Null, "Invalid shader program"
?
			CurrentProgram = TD3D11ShaderProgram(ShaderProgram)
			TD3D11ShaderProgram(ShaderProgram).Set()
			Return
		EndIf

		CurrentProgram = Null
		DeviceContext.VSSetShader(DefaultVertexShader, Null, 0)
		DeviceContext.PSSetShader(DefaultPixelShader, Null, 0)
	EndMethod
EndType



















