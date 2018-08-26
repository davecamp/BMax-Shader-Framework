
SuperStrict
Import Pub.Win32

Extern"Win32"
Type ID3DBlob Extends IUnknown
	Method GetBufferPointer:Byte Ptr()
	Method GetBufferSize()
EndType
EndExtern

Global D3DCompilerDll:Int = LoadLibraryA("d3dcompiler_47.dll")
If Not D3DCompilerDll D3DCompilerDll = LoadLibraryA("d3dcompiler_43.dll")

If Not D3DCompilerDll
?bmxng
Return 0
?Not bmxng
Return
?
EndIf

Global D3DCreateBlob:Int(Size:Int ,ppBlob:ID3DBlob Var)"win32" = GetProcAddress(D3DCompilerDll,"D3DCreateBlob")
Global D3DCompile:Int(pSrcData:Byte Ptr, SrcDataSize:Int, pSourceName:Byte Ptr,pDefines:Byte Ptr,pInclude:Byte Ptr,pEntryPoint:Byte Ptr,pTarget:Byte Ptr,Flags1:Int,Flags2:Int,ppCode:ID3DBlob Var,ppErrorMsgs:ID3DBlob Var)"win32" = GetProcAddress(D3DCompilerDll,"D3DCompile")

Function CompileShader:ID3DBlob(device:IUnknown, source:String, entrypoint:String, target:String)
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
