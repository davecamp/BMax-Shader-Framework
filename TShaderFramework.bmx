
Strict

Type TVertexShader Abstract
EndType

Type TPixelShader Abstract
EndType

Type TShaderProgram Abstract
	Method GetShaderUniform:TShaderUniform(Name:String) Abstract
	Method GetShaderSampler:TShaderSampler(Name:String) Abstract
EndType

Type TShaderUniform Abstract
	Method SetFloat(Data:Float) Abstract
	Method SetFloat2(Data1:Float, Data2:Float) Abstract
	Method SetFloat3(Data1:Float, Data2:Float, Data3:Float) Abstract
	Method SetFloat4(Data1:Float, Data2:Float, Data3:Float, Data4:Float) Abstract
	Method SetInt(Data:Int) Abstract
	Method SetInt2(Data1:Int, Data2:Int) Abstract
	Method SetInt3(Data1:Int, Data2:Int, Data3:Int) Abstract
	Method SetInt4(Data1:Int, Data2:Int, Data3:Int, Data4:Int) Abstract
	Method SetMatrix4x4(Data:Float[], IsTranspose:Byte) Abstract
EndType

Type TShaderSampler Abstract
	Method SetIndex(Index:Int) Abstract
EndType

Type TShaderTexture Abstract
EndType

Type TShaderFramework Abstract
	Method CreateShaderProgram:TShaderProgram(VertexShader:TVertexShader, PixelShader:TPixelShader) Abstract
	Method CreateVertexShader:TVertexShader(source:String) Abstract
	Method CreatePixelShader:TPixelShader(source:String) Abstract
	Method SetShader(ShaderProgram:TShaderProgram) Abstract
EndType
