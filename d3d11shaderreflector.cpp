
#include <windows.h>

typedef struct _D3D11_SHADER_TYPE_DESC
{
/*
    D3D_SHADER_VARIABLE_CLASS   Class;          // Variable class (e.g. object, matrix, etc.)
    D3D_SHADER_VARIABLE_TYPE    Type;           // Variable type (e.g. float, sampler, etc.)
    UINT                        Rows;           // Number of rows (for matrices, 1 for other numeric, 0 if not applicable)
    UINT                        Columns;        // Number of columns (for vectors & matrices, 1 for other numeric, 0 if not applicable)
    UINT                        Elements;       // Number of elements (0 if not an array)
    UINT                        Members;        // Number of members (0 if not a structure)
    UINT                        Offset;         // Offset from the start of structure (0 if not a structure member)
    LPCSTR                      Name;           // Name of type, can be NULL
*/
} D3D11_SHADER_TYPE_DESC;

typedef struct _D3D11_SHADER_BUFFER_DESC
{
/*    LPCSTR                  Name;           // Name of the constant buffer
    D3D_CBUFFER_TYPE        Type;           // Indicates type of buffer content
    UINT                    Variables;      // Number of member variables
    UINT                    Size;           // Size of CB (in bytes)
    UINT                    uFlags;         // Buffer description flags
*/
} D3D11_SHADER_BUFFER_DESC;

typedef struct _D3D11_SHADER_VARIABLE_DESC
{
/*
    LPCSTR                  Name;           // Name of the variable
    UINT                    StartOffset;    // Offset in constant buffer's backing store
    UINT                    Size;           // Size of variable (in bytes)
    UINT                    uFlags;         // Variable flags
    LPVOID                  DefaultValue;   // Raw pointer to default value
    UINT                    StartTexture;   // First texture index (or -1 if no textures used)
    UINT                    TextureSize;    // Number of texture slots possibly used.
    UINT                    StartSampler;   // First sampler index (or -1 if no textures used)
    UINT                    SamplerSize;    // Number of sampler slots possibly used.
*/
} D3D11_SHADER_VARIABLE_DESC;

typedef struct _D3D11_SIGNATURE_PARAMETER_DESC
{
/*
    LPCSTR                      SemanticName;   // Name of the semantic
    UINT                        SemanticIndex;  // Index of the semantic
    UINT                        Register;       // Number of member variables
    D3D_NAME                    SystemValueType;// A predefined system value, or D3D_NAME_UNDEFINED if not applicable
    D3D_REGISTER_COMPONENT_TYPE ComponentType;  // Scalar type (e.g. uint, float, etc.)
    BYTE                        Mask;           // Mask to indicate which components of the register
                                                // are used (combination of D3D10_COMPONENT_MASK values)
    BYTE                        ReadWriteMask;  // Mask to indicate whether a given component is 
                                                // never written (if this is an output signature) or
                                                // always read (if this is an input signature).
                                                // (combination of D3D_MASK_* values)
    UINT                        Stream;         // Stream index
    D3D_MIN_PRECISION           MinPrecision;   // Minimum desired interpolation precision
*/
} D3D11_SIGNATURE_PARAMETER_DESC;

typedef struct _D3D11_SHADER_INPUT_BIND_DESC
{
/*
    LPCSTR                      Name;           // Name of the resource
    D3D_SHADER_INPUT_TYPE       Type;           // Type of resource (e.g. texture, cbuffer, etc.)
    UINT                        BindPoint;      // Starting bind point
    UINT                        BindCount;      // Number of contiguous bind points (for arrays)
    
    UINT                        uFlags;         // Input binding flags
    D3D_RESOURCE_RETURN_TYPE    ReturnType;     // Return type (if texture)
    D3D_SRV_DIMENSION           Dimension;      // Dimension (if texture)
    UINT                        NumSamples;     // Number of samples (0 if not MS texture)
*/
} D3D11_SHADER_INPUT_BIND_DESC;


typedef struct _D3D11_SHADER_DESC
{
/*
    UINT                    Version;                     // Shader version
    LPCSTR                  Creator;                     // Creator string
    UINT                    Flags;                       // Shader compilation/parse flags
    
    UINT                    ConstantBuffers;             // Number of constant buffers
    UINT                    BoundResources;              // Number of bound resources
    UINT                    InputParameters;             // Number of parameters in the input signature
    UINT                    OutputParameters;            // Number of parameters in the output signature

    UINT                    InstructionCount;            // Number of emitted instructions
    UINT                    TempRegisterCount;           // Number of temporary registers used 
    UINT                    TempArrayCount;              // Number of temporary arrays used
    UINT                    DefCount;                    // Number of constant defines 
    UINT                    DclCount;                    // Number of declarations (input + output)
    UINT                    TextureNormalInstructions;   // Number of non-categorized texture instructions
    UINT                    TextureLoadInstructions;     // Number of texture load instructions
    UINT                    TextureCompInstructions;     // Number of texture comparison instructions
    UINT                    TextureBiasInstructions;     // Number of texture bias instructions
    UINT                    TextureGradientInstructions; // Number of texture gradient instructions
    UINT                    FloatInstructionCount;       // Number of floating point arithmetic instructions used
    UINT                    IntInstructionCount;         // Number of signed integer arithmetic instructions used
    UINT                    UintInstructionCount;        // Number of unsigned integer arithmetic instructions used
    UINT                    StaticFlowControlCount;      // Number of static flow control instructions used
    UINT                    DynamicFlowControlCount;     // Number of dynamic flow control instructions used
    UINT                    MacroInstructionCount;       // Number of macro instructions used
    UINT                    ArrayInstructionCount;       // Number of array instructions used
    UINT                    CutInstructionCount;         // Number of cut instructions used
    UINT                    EmitInstructionCount;        // Number of emit instructions used
    D3D_PRIMITIVE_TOPOLOGY  GSOutputTopology;            // Geometry shader output topology
    UINT                    GSMaxOutputVertexCount;      // Geometry shader maximum output vertex count
    D3D_PRIMITIVE           InputPrimitive;              // GS/HS input primitive
    UINT                    PatchConstantParameters;     // Number of parameters in the patch constant signature
    UINT                    cGSInstanceCount;            // Number of Geometry shader instances
    UINT                    cControlPoints;              // Number of control points in the HS->DS stage
    D3D_TESSELLATOR_OUTPUT_PRIMITIVE HSOutputPrimitive;  // Primitive output by the tessellator
    D3D_TESSELLATOR_PARTITIONING HSPartitioning;         // Partitioning mode of the tessellator
    D3D_TESSELLATOR_DOMAIN  TessellatorDomain;           // Domain of the tessellator (quad, tri, isoline)
    // instruction counts
    UINT cBarrierInstructions;                           // Number of barrier instructions in a compute shader
    UINT cInterlockedInstructions;                       // Number of interlocked instructions
    UINT cTextureStoreInstructions;                      // Number of texture writes
*/
} D3D11_SHADER_DESC;

struct ID3D11ShaderReflectionType;
struct ID3D11ShaderReflectionVariable;
struct ID3D11ShaderReflectionConstantBuffer;
struct ID3D11ShaderReflection;

struct ID3D11ShaderReflectionType
{
    virtual __stdcall long GetDesc(D3D11_SHADER_TYPE_DESC * pDesc) = 0;
    
	virtual __stdcall ID3D11ShaderReflectionType * GetMemberTypeByIndex(unsigned int) = 0;
    virtual __stdcall ID3D11ShaderReflectionType * GetMemberTypeByName(const char * Name) = 0;
    virtual __stdcall const char * GetMemberTypeName(unsigned int Index) = 0;

    virtual __stdcall long IsEqual(ID3D11ShaderReflectionType * pType) = 0;
    virtual __stdcall ID3D11ShaderReflectionType * GetSubType() = 0;
	virtual __stdcall ID3D11ShaderReflectionType * GetBaseClas() = 0;
    virtual __stdcall unsigned int GetNumInterfaces() = 0;
    virtual __stdcall ID3D11ShaderReflectionType * GetInterfaceByIndex(unsigned int uIndex) = 0;
    virtual __stdcall long IsOfType(ID3D11ShaderReflectionType * pType) = 0;
    virtual __stdcall long ImplementsInterface(ID3D11ShaderReflectionType * pBase) = 0;
};

struct ID3D11ShaderReflectionVariable
{
    virtual __stdcall long GetDesc(D3D11_SHADER_VARIABLE_DESC * pDesc) = 0;
    
    virtual __stdcall ID3D11ShaderReflectionType * GetType() = 0;
	virtual __stdcall ID3D11ShaderReflectionConstantBuffer * GetBuffer() = 0;

	virtual __stdcall unsigned int GetInterfaceSlot (unsigned int uArrayIndex) = 0;
};

struct ID3D11ShaderReflectionConstantBuffer
{
    virtual __stdcall long GetDesc(D3D11_SHADER_BUFFER_DESC * pDesc) = 0;
    
	virtual __stdcall ID3D11ShaderReflectionVariable * GetVariableByIndex(unsigned int Index) = 0;
	virtual __stdcall ID3D11ShaderReflectionVariable * GetVariableByName(const char * Name) = 0;
};

struct ID3D11ShaderReflection
{
    virtual __stdcall long QueryInterface(const GUID & iid, void ** ppv) = 0;
	virtual __stdcall unsigned long AddRef() = 0;
	virtual __stdcall unsigned long Release() = 0; 
    
	virtual __stdcall long GetDesc(D3D11_SHADER_DESC * pDesc) = 0;

    virtual __stdcall ID3D11ShaderReflectionConstantBuffer * GetConstantBufferByIndex(unsigned int Index) = 0;
    virtual __stdcall ID3D11ShaderReflectionConstantBuffer * GetConstantBufferByName(const char * Name) = 0;
    
   	virtual __stdcall long GetResourceBindingDesc(unsigned int ResourceIndex, D3D11_SHADER_INPUT_BIND_DESC * pDesc) = 0;
    virtual __stdcall long GetInputParameterDesc(unsigned int ParameterIndex, D3D11_SIGNATURE_PARAMETER_DESC * pDesc) = 0;
    virtual __stdcall long GetOutputParameterDesc(unsigned int ParameterIndex, D3D11_SIGNATURE_PARAMETER_DESC * pDesc) = 0;
    virtual __stdcall long GetPatchConstantParameterDesc(unsigned int ParameterIndex, D3D11_SIGNATURE_PARAMETER_DESC * pDesc) = 0;

    virtual __stdcall ID3D11ShaderReflectionVariable * GetVariableByName(const char * Name) = 0;

    virtual __stdcall long GetResourceBindingDescByName(const char * Name, D3D11_SHADER_INPUT_BIND_DESC * pDesc) = 0;

    virtual __stdcall unsigned int GetMovInstructionCount() = 0;
    virtual __stdcall unsigned int GetMovcInstructionCount() = 0;
    virtual __stdcall unsigned int GetConversionInstructionCount() = 0;
    virtual __stdcall unsigned int GetBitwiseInstructionCount() = 0;
    
    virtual __stdcall unsigned int GetGSInputPrimitive() = 0;
    virtual __stdcall int IsSampleFrequencyShader() = 0;

    virtual __stdcall unsigned int GetNumInterfaceSlots() = 0;
    virtual __stdcall long GetMinFeatureLevel(unsigned int * pLevel) = 0;

    virtual __stdcall unsigned int GetThreadGroupSize(unsigned int * pSizeX, unsigned int * pSizeY, unsigned int * pSizeZ) = 0;

    virtual __stdcall unsigned long long GetRequiresFlags() = 0;
};


extern"C"{
	
	/*
	 * Constant buffer
	 */
	
	long ConstantBuffer_GetDesc(ID3D11ShaderReflectionConstantBuffer* pConstantBuffer, D3D11_SHADER_BUFFER_DESC * pDesc) {
		return pConstantBuffer->GetDesc(pDesc);
	}
	
	ID3D11ShaderReflectionVariable * ConstantBuffer_GetVariableByIndex(ID3D11ShaderReflectionConstantBuffer* pConstantBuffer, unsigned int Index){
		return pConstantBuffer->GetVariableByIndex(Index);
	}
	
	
	/*
	 * Buffer variable
	 */
	
	long Variable_GetDesc(ID3D11ShaderReflectionVariable * pVariable, D3D11_SHADER_VARIABLE_DESC * pDesc) {
		return pVariable->GetDesc(pDesc);
	}
	
	ID3D11ShaderReflectionType * Variable_GetType(ID3D11ShaderReflectionVariable * pVariable) {
		return pVariable->GetType();
	}
	
	/*
	 * Variable type
	 */
	
	long Type_GetDesc(ID3D11ShaderReflectionType * pVariableType, D3D11_SHADER_TYPE_DESC * pDesc) {
		return pVariableType->GetDesc(pDesc);
	}
}
















