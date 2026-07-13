/*--------------------------------
	RenderWare DFF model Importer
	RenderWare Version 3.7.0.2
	Platform PC
	by Allen
	Last version: 2020-12-13
	First version: 2019-10-21
	Support game:
		Agent Hugo
		Manhunt
*/--------------------------------
gc()
global imageExtArray = #(".png",".tga",".bmp")
Global ClumpListbox
Global EntryIndexArray
Global DFFfileName	
Global imageType
struct rwChunk
(
	ChunkID,ChunkSize,Version
)
struct FrameDataStruct
(
	Matrix,ParentFrameID,MatrixCreationFlags
)
struct HAnimBoneInfo
(
	BoneID,BoneIndex,BoneType,hAnimFlag
)
struct FaceMatStruct
(
	Face,MatID
)
struct RwSphere
(
	position,radius
)
fn ReadMatrix4x3 f =
(
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; 
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; 
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f;
	m41 = readfloat f; m42 = readfloat f; m43 = readfloat f;
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
	tfm
)
fn ReadMatrix4x4 f =
(
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
	m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
	tfm
)
fn ReadFixedString bstream fixedLen =
(
	local start = ftell bstream
	local str = readstring bstream
	local end = ftell bstream
	local len = end - start
	local padding = fixedLen - len
	Fseek bstream padding #seek_cur
	str
)

fn ReadChunk f =
(
	local Chunk = rwChunk ChunkID:(readlong f) \
	ChunkSize:(readlong f #unsigned) \
	Version:(readlong f)
	Chunk
)
fn skipBytes f SkipSize =
(
	fseek f SkipSize #seek_cur
)
fn ReadColor f = (
  colR = (readbyte f #unsigned)
  colG = (readbyte f #unsigned)
  colB = (readbyte f #unsigned)
  colA = (readbyte f #unsigned)	 
  return (color colR colG colB colA)
 )
fn ReadFrameData f =
(
	local frameData = FrameDataStruct Matrix:(ReadMatrix4x3 f) \
	ParentFrameID:(ReadLong f) \
	MatrixCreationFlags:(ReadLong f)
	frameData
)
fn ReadFrameDataList f FrameCount =
(
	local FrameListArray=#()
	for i = 1 to FrameCount do(
		append FrameListArray (readFrameData f)
	)
	FrameListArray
)
fn ReadFrameName f NameLength =
(
	local FrameName =""
	for i = 1 to NameLength do(
		FrameName +=(bit.intaschar (readbyte f #unsigned))
	)
	FrameName
) 
fn ReadPadding f AlignBytes=
(
	padlen = AlignBytes - (mod (Ftell f ) AlignBytes)
	if (padlen > 0) and (padlen < AlignBytes) then fseek f padlen #seek_cur
)
fn ReadrwString f =
(
	local str=""
	header = ReadChunk f
	for i = 1 to header.ChunkSize do(
		str +=(bit.intaschar (readbyte f #unsigned))
	)
	str
)
fn ReadHAnimPLG f BoneIDArray HAnimBoneArray =
(
	hAnimVersion = ReadLong f #unsigned
	AnimationBoneID = ReadLong f #unsigned--Animation Bone ID
	append BoneIDArray AnimationBoneID
	BoneCount = ReadLong f #unsigned
	if (BoneCount>0)then(		
		flags = ReadLong f
		keyFrameSize = Readlong f
		for i = 1 to BoneCount do(
			hAnimFlag = 0
			BoneID = ReadLong f
			BoneIndex = ReadLong f #unsigned
			BoneType = ReadLong f #unsigned
			if BoneID == AnimationBoneID then hAnimFlag = 1
			append HAnimBoneArray (HAnimBoneInfo \
				BoneID:BoneID  \
				BoneIndex:BoneIndex \
				BoneType:BoneType \ 
				hAnimFlag:hAnimFlag )
		)
	)
	
)
fn readUserDataPLG f index =(
	numSet = readlong f
	boneName = "bone" + (index as string)
	for i = 1 to numSet do(
		typeNameLen = readlong f
		fseek f typeNameLen #seek_cur
		u2 = readlong f
		u3 = readlong f 
		nameLen = readlong f 
		if nameLen > 0 then( boneName = readstring f )
	)
	boneName
)
fn ReadFrameExt f FrameCount FrameNameArray BoneIDArray HAnimBoneArray =
(
	
	for i = 1 to FrameCount do(
		frameExtHeader = readchunk f
		local hasName = false
		if (frameExtHeader.ChunkSize > 0) then(	
			endOfs =  (ftell f) + frameExtHeader.ChunkSize
			while (ftell f) < endOfs do(
				Header = readchunk f
				if (Header.ChunkID == 0x253F2FE)then(
					hasName = true
					append FrameNameArray (readFrameName f Header.ChunkSize)
				)else if(Header.ChunkID==0x11E)then(
					readHAnimPLG f BoneIDArray HAnimBoneArray 
				)else if(Header.ChunkID==0x11F)then(
					hasName = true
					append FrameNameArray (readUserDataPLG f i)
				)else(
					skipBytes f Header.ChunkSize
				)				
			)
			if hasName == false then (append FrameNameArray ("bone"+(i as string)))
		)
		else(
			if i == 1 then( append FrameNameArray "RootDummy")
			else(append FrameNameArray ("bone"+(i as string)))
		)
	)
)
fn ReadFrameList f =
(
	frameListHeader = readChunk f
	FrameListStructHeader = readChunk f
	FrameCount = ReadLong f #unsigned
	FrameDataListArray = readFrameDataList f FrameCount
	FrameNameArray =#()
	HAnimBoneArray =#()
	BoneIDArray =#()
	readFrameExt f FrameCount FrameNameArray BoneIDArray HAnimBoneArray
	
	
	boneArray=#()
	skinBoneArray = #()
	HAnimFlag = undefined
	if (HAnimBoneArray.count>0)then HAnimFlag = true
	
	
	for i = 1 to FrameCount do(			
		tfm = FrameDataListArray[i].Matrix
		bne = bonesys.createbone	\
		  tfm.row4	\
		  (tfm.row4 + 0.01 * (normalize tfm.row1)) \
		  (normalize tfm.row3)			
		bne.width  = 0.03
		bne.height = 0.03
		bne.transform = tfm
		bne.setBoneEnable false 0
		bne.wirecolor = yellow
		bne.showlinks = true			
		if i > 1 then setUserProp bne "BoneID" BoneIDArray[i-1] -- this boneid is anim boneid
		bne.name = FrameNameArray[i]				
		bne.pos.controller      = TCB_position ()
		bne.rotation.controller = TCB_rotation ()		
		append boneArray  bne
		/*
		Bne = dummy boxsize:[.1,.1,.1]
		Bne.name = FrameNameArray[i]
		Bne.transform = FrameDataListArray[i].Matrix	
		if i > 1 then setUserProp bne "BoneID" BoneIDArray[i-1] -- this boneid is anim boneid
		bne.name = FrameNameArray[i]				
		append BoneArray Bne
		*/
	)
	for i = 1 to FrameCount do(
		ParentID = FrameDataListArray[i].ParentFrameID
		if (ParentID!=-1)then(
			BoneArray[i].parent = BoneArray[ParentID+1]
			BoneArray[i].transform *= BoneArray[i].parent.transform				
		)		
	)	
	for i = 1 to frameCount do(
		bne = BoneArray[i]		
		boneID = getuserprop bne "BoneID"
		if boneID != undefined then(
			for j = 1 to HAnimBoneArray.count do(
				if (HAnimBoneArray[j].BoneID == boneID) then( 				
					setUserProp bne "BoneIndex"  HAnimBoneArray[j].boneIndex --this boneindex is skin boneindex
					setUserProp bne "BoneType" HAnimBoneArray[j].BoneType
					if HAnimBoneArray[j].hAnimFlag == 1 then setUserProp bne "AnimFlag" 1
				)				
			)
		)
		setUserProp bne "OrgPos" bne.pos
		setUserProp bne "OrgRot" [bne.rotation.x,bne.rotation.y,bne.rotation.z]
		setUserProp bne "OrgRotW" bne.rotation.w
		setUserProp bne "Orgscl" bne.scale			
	)
	for i = 1 to frameCount do(
		for j = 1 to frameCount do(
			bne = boneArray[j]
			boneIndex = (getuserprop bne "BoneIndex") 
			if boneIndex != undefined and (boneIndex+1) == i then(append skinBoneArray bne)
		)
		
	)
	
	#(BoneArray,skinBoneArray)
)
fn ReadGeometryListSturct f =
(
	GeometryListSturctHeader = readchunk f
	GeometryCount = readlong f #unsigned
	GeometryCount
)
fn ReadMaterialListStruct f =
(
	header = ReadChunk f
	MaterialCount = ReadLong f
	skipbytes f (MaterialCount*4)
	
	return MaterialCount
)
struct SufacePropStruct
(
	ambient,specular,diffuse
)
struct TextureStruct
(
	TextureFilter,U_addressing,V_addressing,UseMipLevelFlag,TextureName,AlphaTextureName
)
fn ReadTexture f =
(
	textureHeader = ReadChunk f
	textureStructHeader = ReadChunk f
	
	Tex = TextureStruct()
	
	--ReadTextureStruct
	Tex.TextureFilter = readbyte f
	UVaddressing = readbyte f
	Tex.UseMipLevelFlag = bit.shift (readshort f) -15
	Tex.U_addressing = bit.shift UVaddressing -4
	Tex.V_addressing = bit.and UVaddressing 0xf
	--end ReadTextureStruct
	
	Tex.TextureName = ReadrwString f
	Tex.AlphaTextureName = ReadrwString f
	TextureExtension = ReadChunk f
	if (TextureExtension.chunkSize > 0)then(fseek f TextureExtension.chunkSize #seek_cur)
	Tex
)
fn ReadSufaceProp f =
(
	SufaceProp = SufacePropStruct()
	SufaceProp.ambient = readFloat f
	SufaceProp.specular = readFloat f
	SufaceProp.diffuse = readFloat f
	SufaceProp
)
fn ReadReflectionMaterial f =
(
	EnvironmentMapScaleX = readFloat f 	-- Environment Map Scale X
    EnvironmentMapScaleY = readFloat f	-- Environment Map Scale Y
    EnvironmentMapOffsetX  = readFloat f	-- Environment Map Offset X
	EnvironmentMapOffsetY = readFloat f	-- Environment Map Offset Y
    ReflectionIntensity = readFloat f	-- Reflection Intensity (Shininess, 0.0-1.0)
    EnvironmentTexturePtr = readLong f	-- Environment Texture Ptr, always 0 (zero)
)
fn ReadrwMaterialEffectsPLG f mtl=
(
	EffectType = ReadLong f
	case EffectType of(
		1:(
		    uint32 rwMATFXEFFECTBUMPMAP = ReadLong f #unsigned -- 0x01, rwMATFXEFFECTBUMPMAP
			Intensity = ReadFloat f -- Intensity
			ContainsBumpMap = ReadLong f --bool32 - Contains Bump Map
			if(ContainsBumpMap==1) then (
				BumpMap = ReadTexture f --Bump Map (Only if effect contains a bump map). In Manhunt game unused
			)
			ContainsHeightMap = ReadLong f --bool32 - Contains Height Map    
			if(ContainsHeightMap==1) then(
				Height_Map = ReadTexture f -- Height Map (Only if the effect contains a height map). In Manhunt game unused
			)
			padding = Readlong f	--zero
		)
		2:(
			rwMATFXENVMAP = ReadLong f #unsigned -- 0x02, rwMATFXENVMAP
			ReflectionCoefficient =ReadFloat f -- Reflection Coefficient (default is 1.0)
			UseFrameBufferAlhpa = Readlong f -- bool32 - Use Frame Buffer Alpha Channel
			ContainsEnvironmentMap = Readlong f --- Contains Environment Map
			if(ContainsEnvironmentMap==1)then(
				EnvMap = ReadTexture f
				filename = (getFilenamePath DFFfileName) + EnvMap.TextureName + imagetype
				mtl.ambientMap = bitmaptexture filename:filename name:EnvMap.TextureName
			)
			padding = Readlong f		
		)
		4:(
			rwMATFXEFFECTDUAL = ReadLong f #unsigned --- 0x04, rwMATFXEFFECTDUAL
			srcBlendMode = Readlong f --- src blend mode
			destBlendMode = Readlong f -- dest blend mode
			ContainsTexture = Readlong f -- Contains Texture
			if(ContainsTexture==1) then(
				DualMap = ReadTexture f
				backup = mtl.diffusemap
				mtl.diffusemap = Mix()
				mtl.diffusemap.map1 = backup
				filename = (getFilenamePath DFFfileName) + DualMap.TextureName + imagetype
				mtl.diffusemap.MAP2 = Bitmaptexture filename:filename name:DualMap.TextureName
			)
			padding = ReadLong f
		)
	)
)
fn ReadMaterialExtension f mtl =
(
	mtlExtHeader = ReadChunk f
	endOffset = (ftell f) + mtlExtHeader.ChunkSize
	if (mtlExtHeader.ChunkSize>0) then(
		while((Ftell f)<endOffset) do
		(
			header = ReadChunk f
			case header.ChunkID of
			(
				0x0253F2FC:(
					ReadReflectionMaterial f
				)
				--0x120:(
				--	ReadrwMaterialEffectsPLG f mtl
				--)
				default:(
					skipBytes f header.ChunkSize
				)
			)
		)
	)
)
fn ReadMaterial f =
(
	MaterailHeader = ReadChunk f
	MaterialStructHeader = ReadChunk f
	flag = ReadLong f
	RGBA = ReadColor f
	unused = ReadLong f
	HasTexture = ReadLong f
	SufaceProp = ReadSufaceProp f
	mtl = StandardMaterial diffuse:RGBA
	if (HasTexture==1)then(
		Tex = ReadTexture f 
		filename = (getFilenamePath DFFfileName) + Tex.TextureName + imagetype
		mtl.name = Tex.TextureName
		mtl.diffusemap = bitmaptexture filename:filename name:Tex.TextureName
		if (Tex.AlphaTextureName != "") then mtl.opacitymap = bitmaptexture filename:((getFilenamePath DFFfileName) + Tex.AlphaTextureName + imagetype) name:Tex.AlphaTextureName		
		showTextureMap mtl on		
	)
	ReadMaterialExtension f mtl
	mtl
)
fn ReadMaterialList f =
(	
	Mtl_Array =#()
	MtlCount = ReadMaterialListStruct f
	for i = 1 to MtlCount do(
		append Mtl_array (ReadMaterial f)		
	)
	if MtlCount == 1 then
	(
		return mtl_array[1]
	)
	else (
		
		mm = multimaterial numsubs:MtlCount
		mm.materialList = mtl_array
		return mm
	)
)


fn ReadUV f VertexCount=
(
	local UVArray=#()
	for i = 1 to VertexCount do(
		tu = ReadFloat f
		tv = ReadFloat f
		append UVArray [tu,1-tv,0]
	)
	UVArray
)
fn ReadVector3 f =
(
	x = ReadFloat f
	y = ReadFloat f
	z = ReadFloat f
	([x,y,z])
)
fn ReadBoundingSphere f=
(
	BoundingSphere = rwSphere position:(readVector3 f) radius:(readfloat f)
	BoundingSphere
)
fn ReadVertex f VertexCount =
(
	local VertArray =#()
	for i = 1 to VertexCount do(
		append VertArray (readVector3 f)
	)
	VertArray
)
fn ReadNormal f VertexCount =
(
	local NormalArray =#()
	for i = 1 to VertexCount do(
		append NormalArray (readVector3 f)
	)
	NormalArray
)
fn ReadFace f FaceCount = 
(
	FaceMat = FaceMatStruct Face:#() MatID:#()
	for i = 1 to FaceCount do(
		f2 = (readshort f #unsigned) + 1                   
		f1 = (readshort f #unsigned) + 1
		matID = readshort f #unsigned + 1
		f3 = (readshort f #unsigned) + 1
		append FaceMat.Face [f1,f2,f3]
		append FaceMat.MatID matID
	)
	FaceMat
)

fn ReadVertexColor f VertexCount =
(
	local VCArray =#()
	for i = 1 to VertexCount do(
		append VCArray (ReadColor f)
	)
	VCArray
)

struct SkinPLGStruct
(
	boneids,weights,inverseMatrix
)
fn ReadSkinPLG f VertexCount =
(
	BoneCount = readbyte f #unsigned
	UsedIDCount = readbyte f #unsigned
	maxWeightsPerVertex = Readshort f -- per vetex used max bone number and weights
	skipbytes f UsedIDCount
	
	SkinPLG = SkinPLGStruct boneids:#() weights:#() inverseMatrix:#()
	Matrix_Array = #()
	tempBoneIDArray=#()
	for i = 1 to VertexCount do(
		boneids_Array= #()
		Bone1 = readbyte f #unsigned
		Bone2 = readbyte f #unsigned
		Bone3 = readbyte f #unsigned
		Bone4 = readbyte f #unsigned
		append boneids_Array (bone1+1)		
		append boneids_Array (bone2+1)		
		append boneids_Array (bone3+1)
		append boneids_Array (bone4+1)	
		append tempBoneIDArray boneids_Array
	)
	for i = 1 to VertexCount do(
		weights_Array =#()
		boneids_Array =#()
		weight1 = readfloat f
		weight2 = readfloat f
		weight3 = readfloat f
		weight4 = readfloat f

			if(weight1 != 0) then(
				append weights_Array weight1
				append boneids_Array tempBoneIDArray[i][1]
			)
			if(weight2 != 0) then(
				append weights_Array weight2
				append boneids_Array tempBoneIDArray[i][2]
			)
			if(weight3 != 0) then(
				append weights_Array weight3	
				append boneids_Array tempBoneIDArray[i][3]
			)			
			if(weight4 != 0) then(
				append weights_Array weight4	
				append boneids_Array tempBoneIDArray[i][4]
			)
		
		append SkinPLG.boneids boneids_Array
		append SkinPLG.weights weights_Array
	)

	for i = 1 to BoneCount do(
		append Matrix_Array (ReadMatrix4x4 f)
	)
	skipbytes f 12
	
	SkinPLG.inverseMatrix = matrix_array
	
	SkinPLG
)
fn ReadBinMeshPLG f=
(
	FaceType = ReadLong f
	SplitCount = ReadLong f #unsigned
	FaceCount = ReadLong f #unsigned
	
	FaceMat = FaceMatStruct Face:#() MatID:#()	
	--Triangle strip
	if(FaceType==1)then
	(
		for S = 1 to SplitCount do
		(
			SplitFaceCount = ReadLong f  #unsigned
			MatID = (ReadLong f  #unsigned) + 1
			FaceDirection = -1
			tempIDArray=#()
			for i = 1 to SplitFaceCount do(
				append tempIDArray ((readlong f #unsigned) +1)
				
				if i > 2 then
				(
					FaceDirection *= -1
					F3 =  tempIDArray[tempIDArray.count]
					F1 =  tempIDArray[tempIDArray.count-2]
					F2 =  tempIDArray[tempIDArray.count-1]
					if(f3!=f2)AND(f3!=f1)AND(f1!=f2) then(
						if FaceDirection > 0 then append FaceMat.Face [f1,f2,f3]
						else append FaceMat.Face [f2,f1,f3]
						append FaceMat.MatID MatID
					)
					f1 = f2
					f2 = f3				
				)
			)
		)
	)
	--Triangle List 
	--used for gtasa
	else if (faceType == 0) then 
	(
		for S = 1 to SplitCount do(
			SplitFaceCount = ReadLong f  #unsigned
			MatID = (ReadLong f  #unsigned) + 1
			for i = 1 to (SplitFaceCount/3) do(			
				f2 = (readlong f #unsigned) + 1                   
				f1 = (readlong f #unsigned) + 1
				f3 = (readlong f #unsigned) + 1
				append FaceMat.Face [f1,f2,f3]
				append FaceMat.MatID matID
			)
		)

	)
	FaceMat
)
fn ReadGeometry f BoneArray Atomic skinBoneArray =
(
	Vert_array = #()
	Normal_array = #()
	UV1_array = #()
	UV2_array = #()
	Face_array = #()
	MatID_Array=#()
	FaceAndMatIDArray= #()--FaceArray and MatIDArray is a FaceMatStruct
	VColor_Array = #()
	
	GeometryHeader = ReadChunk f	
	GeometryStructHeader = ReadChunk f
	FormatFlags = readshort f #unsigned
	NumTexCoorsCustom = readbyte f
	GeometryNativeFlags = readbyte f
	FaceCount = ReadLong f #unsigned
	VertexCount = ReadLong f #unsigned
	numMorphTargets = ReadLong f #unsigned
	GeometryTristrip = mod FormatFlags 2
	GeometryMeshes = (bit.shift (bit.and FormatFlags 3) -1)
	GeometryTextured =(bit.shift (bit.and FormatFlags 7) -2)
	GeometryPrelit = (bit.shift (bit.and FormatFlags  0xF) -3)
	GeometryNormals = (bit.shift (bit.and FormatFlags 0x1F) -4)
	GeometryLight = (bit.shift (bit.and FormatFlags 0x3F) -5)
	GeometryModulateMaterialColor = (bit.shift (bit.and FormatFlags 0x7F) -6)
	GeometryTextured_2 = (bit.shift (bit.and FormatFlags 0xFF) -7)
	if (GeometryPrelit==1) then VColor_Array = readVertexColor f VertexCount
	if ((GeometryTextured==1)or(GeometryTextured_2==1)) then UV1_Array = readUV f VertexCount
	if (GeometryTextured_2==1) then UV2_Array = readUV f VertexCount
	if (GeometryMeshes==1) then(
		FaceAndMatIDArray = readFace f FaceCount
		Face_array = deepcopy FaceAndMatIDArray.Face
		MatID_Array = deepcopy FaceAndMatIDArray.MatID
	)
	BoundingSp = readBoundingSphere f
	HasPositionFlag = ReadLong f
	HasNomralFlag = ReadLong f
	if (GeometryMeshes==1) then Vert_Array = ReadVertex f VertexCount
	if (GeometryNormals==1) then Normal_Array = ReadNormal f VertexCount
	

	MaterialListHeader =  ReadChunk f
	mtl = ReadMaterialList f
	

	skinFlag = undefined
	skinPLG = undefined
	FaceMat = undefined
	binMeshFlag = undefined
	GeometryExtensionHeader = ReadChunk f

	if (GeometryExtensionHeader.ChunkSize > 0 ) then(
		endofs = (ftell f)+GeometryExtensionHeader.ChunkSize 
		while((Ftell f )< endofs)do(
		header = ReadChunk f
		case (header.ChunkID) of(
			0x116:(
				skinFlag = true
				--Print " found skin data"
				skinPLG = ReadSkinPLG f VertexCount
			
			)
			0x50E:(
				--Print " found binMesh data"
				FaceMat = ReadBinMeshPLG f
				binMeshFlag = true
			)
			default: (
				skipbytes f header.ChunkSize)
		)
		)
	)
	
	parentFrameID = Atomic.FrameIndex + 1	
	parentBone = boneArray[parentFrameID]
	transMat = parentBone.transform as quat
	transMat = transMat as matrix3
	if (GeometryMeshes==1) then	(
		for i = 1 to VertexCount do (
			Vert_Array[i] = ((transMatrix Vert_Array[i])*parentBone.transform).pos
		)
	) 
	if (GeometryNormals==1) then (
		transNormay_Array = #()
		for i = 1 to VertexCount do(
			transNormal = Normal_Array[i] * transMat
			transNormal = normalize transNormal
			append transNormay_Array transNormal
		)
		Normal_Array = transNormay_Array
	) 
	

	msh = undefined
	if (GeometryMeshes==1) then(
		msh = mesh vertices:Vert_array faces:Face_array--FaceMat.Face
		if (GeometryNormals==1)then for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
		if ((GeometryTextured==1)or(GeometryTextured_2==1)) then(
			msh.numTVerts = UV1_array.count
			buildTVFaces msh
			for j = 1 to UV1_array.count     do setTVert  msh j UV1_array[j]
			
			for j = 1 to Face_array.count   do setTVFace msh j Face_array[j]--UV face	
			for n = 1 to MatID_Array.count do
			(
				setFaceMatID msh n MatID_Array[n]
			)/*		
			for j = 1 to FaceMat.Face.count   do setTVFace msh j FaceMat.Face[j]--UV face				
			for n = 1 to FaceMat.MatID.count do
			(
				setFaceMatID msh n FaceMat.MatID[n]
			)	*/
		)
		if (GeometryPrelit==1) then (
			
			setNumCPVVerts msh VColor_Array.count
			buildVCFaces msh
			for i = 1 to VColor_Array.count do
			(
				setVertColor  msh i VColor_Array[i]
			)
			
		)			
		if (GeometryTextured_2==1) then
		(			
			meshop.setNumMaps msh 3
			meshop.setNumMapVerts msh 2 UV2_array.count
			meshop.setNumMapFaces msh 2 Face_array.count
			for j = 1 to UV2_array.count do meshop.setMapVert msh 2 j UV2_array[j]
			for j = 1 to Face_array.count do meshop.setMapFace msh 2 j Face_array[j]--UV face
		)
	)
	msh.material = mtl

	parentFrameID = Atomic.FrameIndex + 1	
	msh.parent = boneArray[parentFrameID]
	--msh.transform *= BoneArray[parentFrameID].transform
	
	if (skinFlag == true) then
	(	
		setuserprop msh.parent "ObjectMatrix" 1 
		BoneIDs = skinPLG.boneids
		Weights = skinPLG.weights
		--DisableSceneRedraw()
		max modify mode
		select msh
		skinMod = skin ()
		addModifier msh skinMod
		subobjectLevel = 1
		msh.skin.bone_Limit = 4		
		dmy = dummy name:"AnimationData"  ishidden:true
		dmy.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
		for b = 1 to skinBoneArray.count do(
			skinOps.addBone skinMod skinBoneArray[b] 0
		)
		delete dmy
		modPanel.setCurrentObject skinMod
		for i = 1 to msh.numVerts do (
			skinOps.replaceVertexWeights skinMod i BoneIDs[i] Weights[i]
		)
		max select none
		--EnableSceneRedraw()			
	)

	msh
	
)

fn ReadGeometryList f GeometryCount BoneArray AtomicArray skinBoneArray =
(
	GeometryListArray =#()
	for i = 1 to GeometryCount do(
		append GeometryListArray (readGeometry f BoneArray AtomicArray[i] skinBoneArray)
	)
)
struct AtomicStruct
(
	FrameIndex,GeometryIndex,flags
)
fn ReadAtomicExtension f =
(
	Header = ReadChunk f
	case Header.ChunkID of(
		0x120:(
			MatFXenabled = ReadLong f -- bool32- MatFX enabled MaterialEffectsPLG 0x120
		)
		0x1F:(
			RWpluginIdentifier = ReadLong f --(e.g. 0x0116 or 0x0120)
			extraData = ReadLong f	
		)
		default:(
			skipbytes f Header.ChunkSize
		)
	)		
)
fn ReadAtomic f numAtomics =
(
	AtomicArray=#()
	for i = 1 to numAtomics do(
		Atomic = AtomicStruct()
		AtomicHeader = ReadChunk f
		AtomicStructHeader = ReadChunk f
		--ReadAtomicStruct--
		Atomic.FrameIndex = ReadLong f
		Atomic.GeometryIndex = Readlong f
		Atomic.flags = ReadLong f
		unused= Readlong f
		--End ReadAtomicStruct--
		append AtomicArray Atomic
		ReadAtomicExtension f		
	)
	AtomicArray
)
fn ReadClump f offset=
(
	fseek f offset #seek_set
	clumpHeader = readchunk f
	clumpEndOfs = (ftell f)+clumpHeader.ChunkSize
	clumpStruct = readchunk f
	numAtomics = ReadLong f
    numLights = ReadLong f
    numCameras = ReadLong f
	BoneArray = ReadFrameList f
	GeometryListHeader = ReadChunk f
	GeometryListOffset = ftell f
	skipbytes f GeometryListHeader.ChunkSize
	AtomicArray = ReadAtomic f numAtomics
	fseek f GeometryListOffset #seek_set
	GeometryCount = readGeometryListSturct f
	ReadGeometryList f GeometryCount BoneArray[1] AtomicArray BoneArray[2]
)
fn ReadSingleClump fileName offset =
(	
	DFFfileName = fileName
	f = fopen fileName "rb"
	ReadClump f offset
	fclose f
)
fn ReadSingleClumpIFPUI fileName offset texExt=
(
	imagetype = texExt
	DFFfileName = fileName
	f = fopen fileName "rb"
	ReadClump f offset
	fclose f
)
struct ClumpList
(
	ClumpNames,Offset
)
fn ReadClumpList fileName =
(
	DFFfileName = fileName
	ClumpListArray= ClumpList ClumpNames:#() Offset:#()
	fileSize = getfilesize fileName
	f = fopen DFFfileName "rb"
	count = 1
	While((Ftell f)<fileSize)
	do(
		offset = ftell f
		DFFname =""
		checkClump = readlong f
		if (checkClump == 0x10) then(
			fseek f -4 #seek_cur
			clumpChunk = readChunk f
			next = (ftell f) + clumpChunk.ChunkSize
			clumpStruct = readchunk f
			skipBytes f clumpStruct.ChunkSize
			skipBytes f 12
			FrameListStructHeader = readChunk f
			skipBytes f FrameListStructHeader.ChunkSize
			extheader = readChunk f
			header = readChunk f
			if (header.ChunkID==0x11F)then(
				DFFname = readUserDataPLG f 1	
			)else if(header.ChunkID==0x253F2FE)then(	
				DFFname = readFrameName f header.chunkSize
			)else if(header.ChunkID==3)then(
				endOfs = (ftell f) + header.chunkSize
				while (ftell f ) < endOfs do(
					sHeader = readchunk f				
					if (sHeader.ChunkID==0x253F2FE)then(
						DFFname = readFrameName f sHeader.ChunkSize
					)else if(sHeader.ChunkID==0x11F)then(
						DFFname = readUserDataPLG f 1
					)else(
						skipBytes f sHeader.ChunkSize
					)
				)			
			)
			DFFname=((formattedPrint count format:("0"+((100 as string).count as String)+"u"))+" "+DFFname)		
			append ClumpListArray.ClumpNames DFFname
			append ClumpListArray.Offset offset
			fseek f next #seek_set
			count+=1
		)
		else
		(
			exit()
		)

	)
	fclose f
	ClumpListArray
)

fn find_HeadBone obj = ((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneID" == 1001) -- head 1001 neck 1040
fn find_dummy obj = (classof obj)==BoneGeometry or (classof obj)== Dummy
rollout DFFImportUI "DFF Importer"
(
	button loaddff "Select DFF"  tooltip:"DFF Model"
	radioButtons rdo1 "Image Type:" tooltip:"Textures format" labels:#("png","tga","bmp") align:#left
	listbox lbx1 "Objects:" 
	button importAll "Import All"
	label tip "Double Click Import"
	Group "Hunt Helper"
	(
		button linkHeadBone "Link Hunt Head to Bone"
		button unlinkHeadBone "Unlink Hunt head to Bone"
	)
	on linkHeadBone pressed do(
		headBoneArray = #()
		for obj in objects where (((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneID" == 1001)) do(
			append headBoneArray obj
		)
		headDummy = selectByName title:"Please Select Head Model Dummy" buttonText:"OK" showHidden:true single:true filter:find_dummy 	
		--pBone = selectByName title:"Please Select Head Bone" buttonText:"OK" showHidden:true single:true filter:find_HeadBone 
		if headBoneArray.count > 0 then pBone = headBoneArray[1]
		if headDummy != undefined and pBone != undefined then
		(
			headDummy.transform *= pBone.transform
		)
	)
	on unlinkHeadBone pressed do(
		headBoneArray = #()
		for obj in objects where (((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneID" == 1001)) do(
			append headBoneArray obj
		)
		headDummy = selectByName title:"Please Select Head Model Dummy" buttonText:"OK" showHidden:true single:true filter:find_dummy 	
		--pBone = selectByName title:"Please Select Head Bone" buttonText:"OK" showHidden:true single:true filter:find_HeadBone 
		if headBoneArray.count > 0 then pBone = headBoneArray[1]
		if headDummy != undefined and pBone != undefined then
		(
			headDummy.transform *= inverse pBone.transform
		)
	)	
	on loaddff pressed do (
		fname = getopenfilename caption:"Read DFF File" types:"dff File (*.dff)|*.dff|"
		if fname != undefined then (
			lbx1.items = #()
			entryInfo = ReadClumpList fname
			ClumpListbox = ReadClumpList fname
			DFFImportUI.lbx1.items = ClumpListbox.ClumpNames
			DFFImportUI.lbx1.selection = 1
			EntryIndexArray = ClumpListbox.offset
			imagetype = imageExtArray[rdo1.state]
			if (entryInfo.ClumpNames.count==1)then(
				ReadSingleClump fname 0
			)				
		)
	)--end on loaddff	
	on lbx1 doubleClicked itm do
	(
		if lbx1.selection > 0 then
		(
			entryIndexOffset = EntryIndexArray[lbx1.selection]
			imagetype = imageExtArray[rdo1.state]
			ReadSingleClump DFFfileName entryIndexOffset
			
		)
		
	)
	on importAll pressed do(
		f = fopen DFFfileName "rb"
		imagetype = imageExtArray[rdo1.state]
		for i = 1 to ClumpListBox.clumpNames.count do(
			ReadClump f clumpListBox.Offset[i]
		)
		fclose f
	)
)
rollout MHTXDRollout "Manhunt TXD Extract"(
	button btn1 "single" tooltip:"PC PS2 TXD" across:2
	button btn2 "batch" tooltip:"PC PS2 TXD"
	on btn1 pressed do(inputfname = getOpenFileName caption:"Please Selcet Manhunt .txd Textures File" types:"Manhunt Textures File(*.txd)|*.txd" ; if inputfname != undefined then (exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-mh1txd -s "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))	
	on btn2 pressed do(inputfname = getSavePath caption:"Please Selcet .txd Textures Folder";if inputfname != undefined then(exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-mh1txd -all "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))	
)
rollout DFFAboutRoll "About" (
	label a1 "RenderWare DFF Importer" --align:#left
	label a3 "Sep 12 2021, By Allen" --align:#right
	label a4 "leeao@live.com" --align:#right
)
fn createDFFImportWindow fname =
(
	if Allen_DFF_Tool != undefined then (
		closeRolloutFloater Allen_DFF_Tool
	)
	Allen_DFF_Tool = newRolloutFloater "DFF Importer" 180 310 10 50	
	addRollout DFFImportUI Allen_DFF_Tool rolledup:false
	ClumpListbox = ReadClumpList fname
	DFFImportUI.lbx1.items = ClumpListbox.ClumpNames
	DFFImportUI.lbx1.selection = 1
	EntryIndexArray = ClumpListbox.offset	
)