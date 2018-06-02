
Strict

Type TShaderConstant Abstract
	Method SetFloat(Data:Float Ptr, Count:Int) Abstract
EndType

Type TShaderSampler Abstract
	Field _Name:String
EndType

Type TShaderBase Abstract
	Method Compile:Int(Source:String) Abstract
EndType

Type TVertexShader Extends TShaderBase Abstract
EndType

Type TPixelShader Extends TShaderBase Abstract
EndType


Type TShader Abstract
	Method SetVertexShader(VShader:TVertexShader) Abstract
	Method SetPixelShader(PShader:TPixelShader) Abstract
	Method Link:Int() Abstract
	
	Method Set() Abstract
	Method Unset() Abstract

	Method GetShaderConstant:TShaderConstant(Name:String) Abstract
	Method GetShaderSampler:TShaderSampler(Name:String) Abstract
EndType
