fileIn "BinaryRead.ms"
fileIn "function.ms"
global EntryIndexArray
global MDLfname
global type = ""
global MeshSkinArray
global ObjectParentBoneOffset
global imagetypeArray = #(".dds",".png",".tga",".bmp")
global KeyOffset
global Dummysize = 0.1
global platform = "PC"
global MH2MDL_Tool

--注意全局数组或变量在赋值之前需要清空，数组需使用=#（）清空。

struct weight_data
(
	boneids,weights
)
--PS2
struct UVScaleFactor
(
	X,Y
)
fn ReadFaceData f type=
(	
	case type of
	(
		0:()
		1:(return (readbyte f #unsigned))
		2:(return (readbyte f #unsigned))
		3:(return (readBEWord f))
	)
)
-- ps2 read weight
fn ConvertInttoFloat IntValue =
(
	IntValue = bit.and IntValue  0xffff0000
	IntValue  = bit.intasfloat IntValue 
	return IntValue
)
fn skippadding f=
(
	pos = ftell f
	if (mod pos 4)>0 then
	(
		fseek f (4-(mod pos 4)) #seek_cur
	)
)
struct vertexElementArray(
	vertices,boneids_weights,normals,vcolors,uv1,uv2
)
struct mdlMaterialIDInfo(
	numFace,matID,startFaceID
)
fn ReadDummy f BoneArray  type= 
(
	append boneArray[3] (ftell f) --本骨骼偏移
	tag = readInt f
	brotherOffset = readInt f
	parentOffset = readInt f
	append BoneArray[1] parentOffset
	rootOffset = readInt f
	subOffset = readInt f
	boneLinkOffset = readInt f
	boneName = ReadFixedString f 40
	append BoneArray[4] (readmatrix f)		
	tfm = readmatrix f	
	Bne = undefined
	if type == "Dummy" then(
		Bne = dummy boxsize:[.1,.1,.1]
	)
	else if type=="Bone" then(
		Bne = bonesys.createbone	\
		  tfm.row4	\
		  (tfm.row4 + 0.01 * (normalize tfm.row1)) \
		  (normalize tfm.row3)
		Bne.width  = 0.03
		Bne.height = 0.03		
		Bne.setBoneEnable false 0
		Bne.wirecolor = yellow
		Bne.showlinks = true
	)
	Bne.name = boneName		
	Bne.transform = tfm
	Bne.pos.controller      = TCB_position ()
	Bne.rotation.controller = TCB_rotation ()
	append BoneArray[2] Bne
	setUserProp Bne "BoneIndex" (BoneArray[2].count-1)
	setUserProp Bne "FirstInt" ( "0x"+ bit.intashex(tag) )
	if (boneLinkOffset > 0) then( setUserProp Bne "AnimFlag" 1)
	setUserProp bne "OrgPos" bne.pos
	setUserProp bne "OrgRot" [bne.rotation.x,bne.rotation.y,bne.rotation.z]
	setUserProp bne "OrgRotW" bne.rotation.w
	setUserProp bne "Orgscl" bne.scale		
	if(subOffset != 0) then 
	(
		fseek f subOffset #seek_set
		ReadDummy f BoneArray type
	)
	if(brotherOffset!=0)then
	(
		fseek f brotherOffset #seek_set
		ReadDummy f BoneArray type
	)
)

fn findAnimKey f RootBoneOffset =
(
	fseek f RootBoneOffset #seek_set 
	fseek f 4 #seek_cur
	brotherOffset = readUInt f
	parentOffset = readUInt f
	rootOffset = readUInt f
	subOffset = readUInt f
	AnimKeyOffset = readUInt f

	if AnimKeyOffset > 0 then
	(
		KeyOffset = AnimKeyOffset
		return KeyOffset
	)
	if(subOffset != 0) then 
	(
		findAnimKey f subOffset
	)
	if(brotherOffset != 0)then
	(
		findAnimKey f brotherOffset
	)	
)
fn ReadBone f RootBoneOffset bonearray =
(
	KeyOffset = undefined
	findAnimKey f RootBoneOffset	
	--BoneArray[1]是骨骼父级数据地址parentBoneOffset BoneArray[2]是骨骼本身存储bone BoneArray[3]是骨骼自身数据地址boneoffset BoneArray[4]是骨骼局部坐标矩阵
	type = ""
	if KeyOffset != undefined then type = "Bone" else type = "Dummy"
	fseek f RootBoneOffset #seek_set
	ReadDummy f BoneArray type
	if	KeyOffset !=undefined then(
		fseek f KeyOffset #seek_set
		numBone = readUInt f
		unknownFlag = readUInt f
		setUserProp BoneArray[2][1] "unknownFlag" ("0x"+bit.intashex(unknownFlag))
		fseek f 4 #seek_cur
		BoneHierarchyLevelDataOffset = readUInt f
		fseek f BoneHierarchyLevelDataOffset #seek_set
		for i = 1 to numBone do(			
			AnimKey = readUShort f
			BoneType = readUShort f
			offset = readUInt f
			setUserProp BoneArray[2][i] "BoneID" AnimKey
			setUserProp BoneArray[2][i] "BoneType" BoneType
		)
	)
	for i = 1 to BoneArray[1].count do
	(
		if BoneArray[1][i] != 0 then
		(
			for m = 1 to BoneArray[1].count do
			(
				if (BoneArray[1][i] == BoneArray[3][m]) then
				(
					boneArray[2][i].parent = BoneArray[2][m]
					boneArray[2][i].transform =  boneArray[4][i] * boneArray[2][i].parent.transform
					exit
				)
			)
		)
		
	)
)

fn ReadModel f start BoneArray fname imagetype autoskin AutoShowTextures VertexColorOn optimizeModel smoothNormal =
(	
	Vert_array = #()
	Normal_array = #()
	UV1_array = #()
	UV2_array = #()
	Face_array = #()
	materialIDInfo = mdlMaterialIDInfo numface:#() matID:#() startFaceID:#()
	CPV_Array = #()	
	Weight_array = #()
	vertStrList = #()
	vertStrList_welded = #()
	numUV = 0
			
	--WII	
	oldCPV_Array = #()
	vert_Normal_datas = #()		
	UV1Face_Array = #()
	UV2Face_Array = #()
		
	fseek f start #seek_set
	MaterialOffset = readUInt f
	numTexture = readUInt f
	ObjectMatrixFlag = readUInt f
	
	--材质
	MaterialArray =#(#(),#())	--[1] is material [2] is textureName
	fseek f MaterialOffset #seek_set
	for i = 1 to numTexture do
	(
		textureNameOffset = readUInt f
				
		--thanks Majest1c_R3 correct material
		bLoaded = readByte f #unsigned
		diffColor = ReadColorRGBA f		
		fseek f 3 #seek_cur -- skip padding
		
		nextoffset = ftell f
		fseek f textureNameOffset #Seek_set
		TextureName = ReadString f		
		filename = (getFilenamePath fname) + TextureName + imagetype
		mtl = standardmaterial diffuse:diffColor name:TextureName
		mtl.diffusemap = bitmaptexture filename:filename name:TextureName
		append MaterialArray[1] mtl
		append MaterialArray[2] TextureName
		fseek f nextoffset #seek_set
	)
	
	if numTexture > 1 then
	(
		mm = multimaterial numsubs:numTexture
		mm.materialList= MaterialArray[1]
		mm.names = MaterialArray[2]
	)
	if Platform !="WII" then
	(
		--***从这里开始辨别PC,PS2,PSP平台***--
		fseek f (start+32) #seek_set
		platform = ""
		platformFlag = readlong f #unsigned
		if platformFlag == 0x45d454 then platform = "PC"
		else(
			fseek f (start+80) #seek_set
			platformFlag = readlong f #unsigned
			if platformFlag == 0x50533244 then platform = "PS2" --0x50533244= PS2D/D2SP
			else( platform = "PSP" )
		)
	)
	
	--给模型找父级
	--BoneArray[1]是骨骼父级数据地址parentBoneOffset BoneArray[2]是骨骼本身存储bone BoneArray[3]是骨骼自身数据地址boneoffset BoneArray[4]是骨骼局部坐标矩阵
	parentBone = undefined
	for m = 1 to BoneArray[3].count do(
		if ObjectParentBoneOffset == BoneArray[3][m] then( parentBone = BoneArray[2][m]; exit;)
	)
	
	
	--开始PC代码
	if platform == "PC" then
	(		
		fseek f (start+8) #seek_set
		fseek f 36 #seek_cur
		numMaterialID = readlong f #unsigned
		numFaceIndex = readlong f #unsigned
		fseek f 16 #seek_cur--skip boundingSphereXYZ&Radius
		fseek f 12 #seek_cur--skip boundingSphereScale
		numVertex = readlong f #unsigned
		fseek f 12 #seek_cur
		PerVertexElementSize = readlong f
		fseek f 44 #seek_cur
		VertexElementType = readlong f #unsigned
		fseek f 32  #seek_cur
		for i = 1 to numMaterialID do
		(
			fseek f 24 #seek_cur -- skip 6 floats
			partNumFace = (readshort f #unsigned) / 3 -- 需要除以3，因为是索引的数量，而不是面数。
			matID = readshort f #unsigned + 1
			startFaceID = (readshort f #unsigned) / 3
			readshort f --skip unknown
			fseek f 12 #seek_cur --skip 12 bytes zero
			append materialIDInfo.numface partNumFace
			append materialIDInfo.matID matID
			append materialIDInfo.startFaceID startFaceID
		)
		for i = 1 to numFaceIndex / 3 do (
			f1 = (readshort f #unsigned) + 1                   
			f2 = (readshort f #unsigned) + 1
			f3 = (readshort f #unsigned) + 1
			append Face_array [f1,f2,f3]
		)
		VertexElementType = bit.shift VertexElementType -8
		skinDataFlag = bit.get VertexElementType 5
		numUV = bit.and VertexElementType 0xf
		for i = 1 to numVertex do (
			vertStr = stringstream ""

			vx = readfloat f 
			vy = readfloat f
			vz = readfloat f
			transVert =((transMatrix [vx,vy,vz])*parentBone.transform).pos
			append Vert_array [transVert.x,transVert.y,transVert.z]			
			
			format "%,%,%," (transVert.x as string)  (transVert.y as string) (transVert.z as string) to:vertStr

			if(skinDataFlag==true) then
			(
				weight4 = readfloat f; weight3 = readfloat f; weight2 = readfloat f; weight1 = readfloat f;
				Bone4 = readbyte f; Bone3 = readbyte f; Bone2 = readbyte f; Bone1 = readbyte f
				w = (weight_data boneids:#() weights:#())
				if(weight1 > 0) then( append w.boneids (bone1+1); append w.weights weight1;)
				if(weight2 > 0) then( append w.boneids (bone2+1); append w.weights weight2;)
				if(weight3 > 0) then( append w.boneids (bone3+1); append w.weights weight3;)
				if(weight4 > 0) then( append w.boneids (bone4+1); append w.weights weight4;)		
				append Weight_array w
				format "%,%,%,%," (weight4 as string) (weight3 as string)  (weight2 as string) (weight1 as string) to:vertStr
				format "%,%,%,%," (bone4 as string) (bone3 as string)  (bone2 as string) (bone1 as string) to:vertStr
			)

			nx = readshort f / (32768.0)
			ny = readshort f / (32768.0)
			nz = readshort f / (32768.0)
			pad= readshort f
			transNormal =((transMatrix [nx ,ny,nz])*parentBone.transform).pos
			transNormal = normalize transNormal
			append Normal_array transNormal
			format "%,%,%," (transNormal.x as string)  (transNormal.y as string) (transNormal.z as string) to:vertStr
		
			CB = readbyte f #unsigned
			CG = readbyte f	#unsigned	
			CR = readbyte f #unsigned			
			CA = readbyte f #unsigned
			vcolor =(color CR CG CB CA)
			append CPV_Array vcolor --CPV == Color per vertex
			format "%,%,%,%," (CR as string) (CG as string)  (CB as string) (CA as string) to:vertStr

			if numUV > 0 then
			(
				UV1_tu = readfloat f
				UV1_tv = readfloat f
				append UV1_array [UV1_tu,1-UV1_tv,0]
				format "%,%," (UV1_tu as string) (UV1_tv as string) to:vertStr

				if numUV > 1 then
				(
					UV2_tu = readfloat f
					UV2_tv = readfloat f
					append UV2_array [UV2_tu,1-UV2_tv,0]
					format "%,%" (UV2_tu as string) (UV2_tv as string) to:vertStr
				)
			)

			append vertStrList (vertStr as string)
		)

	)--结束 PC 平台代码
	
	--开始PS2代码
	else if platform == "PS2" then(
		fseek f (start+32) #seek_set
		--Print (bit.intashex (ftell f))
		ChunkSize = readshort f #unsigned
		numMaterialID = readshort f #unsigned
		--format"材质ID数量：%\n" (numMaterialID/16)
		ChunkSize =  bit.xor (bit.shift (mod numMaterialID 16) 16) ChunkSize
		endChunkOffset = ChunkSize + Start + 16
		--format "ChunkSize:%\n" chunksize
		VertexElementType = readlong f #unsigned
		fseek f 16 #seek_cur--skip 4 int unknown
		modelScaleFactorX = readfloat f
		modelScaleFactorY = readfloat f
		modelScaleFactorZ = readfloat f
		TranslateFactorX = readfloat f
		TranslateFactorY = readfloat f
		TranslateFactorZ = readfloat f
		modelChunkFlag = readlong f
		fseek f 12 #seek_cur--skip 3 int padding
		realNumMatID = numMaterialID/16
		--fseek f (48*(numMaterialID/16)) #seek_cur

		skinDataFlag = bit.get VertexElementType 5	
			
			
		UVScale_Array = #()
		FaceDir_Array = #()
		for i = 1 to realNumMatID do
		(
			fseek f 16 #seek_cur -- skip 4 float unknown
			UV = UVScaleFactor X:( readfloat f) Y:(readfloat f)
			append UVScale_Array UV
			unknown = readlong f
			TriangleStripOffset = readlong f #unsigned
			MaterialIDFaceCount = readshort f #unsigned
			MatID = readshort f #unsigned + 1--一定要加1 ，因为游戏从0开始读取数组，而MAX是从1开始读取数组
			append FaceDir_Array MaterialIDFaceCount
			fseek f 12 #seek_cur
			append materialIDInfo.matID MatID			
		)
		startindex = 0
		stripNum = 1
		FaceDirection = 1
		do(
			TriangleStripSize = readshort f #unsigned
			readshort f--skip unknown
			fseek f 12 #seek_cur --skip 3 int padding
			endoffset = (Ftell f)+(TriangleStripSize*16)
			UV = UVScale_array[StripNum]
			--用faceCount奇偶数来判断面的起始方向，看运气
			if mod (FaceDir_Array[stripNum]) 2 == 0 then FaceDirection = -1
			else FaceDirection=1
			faceCount = 0
			do(
				HeaderSignature= readlong f
				fseek f 8 #seek_cur --skip 8byte unknown
				numVerts = readlong f #unsigned
				fseek f 32 #seek_cur --skip 8 int unknown
				f1 = startindex+1
				f2 = startindex+2
				VertsBlockHeader=readlong f
				tempVertDatas = #()
				for i = 1 to numVerts do(
					vx = ((readshort f) / 32768.0) * modelScaleFactorX + TranslateFactorX
					vy = ((readshort f) / 32768.0) * modelScaleFactorY + TranslateFactorY
					vz = ((readshort f) / 32768.0) * modelScaleFactorZ + TranslateFactorZ
					--append Vert_Array [vx,vy,vz]
					transVert =((transMatrix [vx,vy,vz])*parentBone.transform).pos
					append Vert_array [transVert.x,transVert.y,transVert.z]
					vertStr = stringstream ""
					format "%,%,%," (transVert.x as string)  (transVert.y as string) (transVert.z as string) to:vertStr
					append vertStrList (vertStr as string)
					if i > 2 then
					(
						FaceDirection *= -1
						f3 = startindex + i
						c =  Vert_Array[vert_array.count]
						a =  Vert_Array[vert_array.count-2]
						b =  Vert_Array[vert_array.count-1]
						
						if(c!=b)AND(c!=a)AND(b!=a) then
						(
							facecount+=1
							if FaceDirection > 0 then append face_array [f1,f2,f3]
							else append face_array [f2,f1,f3]
						)
						f1 = f2
						f2 = f3
						
					)
					
				)
				skippadding f
				fseek f 28 #seek_cur --skip 7 int unknown
				UVBlockHeader=readlong f
				for i = 1 to numVerts do(
					tu = ((readbyte f #unsigned)/255.0) * UV.X
					tv = ((readbyte f #unsigned)/255.0) * UV.Y					
					append UV1_Array [tu,1-tv,0]
					vertStr = stringstream ""
					format "%,%," (tu as string) (tv as string) to:vertStr
					vertStrList[startIndex+i] += vertStr
				)
				skippadding f
				VColBlockHeader=readlong f
				for i = 1 to numVerts do(
					CB = readbyte f #unsigned
					CG = readbyte f #unsigned		
					CR = readbyte f #unsigned			
					CA = readbyte f #unsigned
					CPV=(color CR CG CB CA)--CPV == Color per vertex
					append CPV_Array CPV
					vertStr = stringstream ""
					format "%,%,%,%," (CR as string) (CG as string)  (CB as string) (CA as string) to:vertStr
					vertStrList[startIndex+i] += vertStr
				)
				NormalsBlockHeader =readlong f
				for i = 1 to numVerts do(
					nx = (readbyte f) / 127.0
					ny = (readbyte f) / 127.0
					nz = (readbyte f) / 127.0
					--append Normal_Array [nx,ny,nz]
					transNormal =((transMatrix [nx,ny,nz])*parentBone.transform).pos	
					transNormal = normalize transNormal		
					append Normal_array transNormal
					vertStr = stringstream ""	
					format "%,%,%," (transNormal.x as string)  (transNormal.y as string) (transNormal.z as string) to:vertStr
					vertStrList[startIndex+i] += vertStr

				)
				skippadding f
				if(VertexElementType >0xF)then
				(
					SkinBlockHeader = readlong f
					for i = 1 to numVerts do(
						weight4 = readlong f #unsigned
						Bone4 = (bit.and weight4 0xffff)/4
						weight4 = ConvertInttoFloat weight4
						
						weight3 = readlong f #unsigned
						Bone3 = (bit.and weight3 0xffff)/4
						weight3 =ConvertInttoFloat weight3
						
						weight2 = readlong f #unsigned
						Bone2 = (bit.and weight2 0xffff)/4
						weight2 =ConvertInttoFloat weight2
						
						weight1 = readlong f #unsigned
						Bone1 = (bit.and weight1 0xffff)/4
						weight1=ConvertInttoFloat weight1
						
						w = (weight_data boneids:#() weights:#())
						maxweight = 0
							
						if(weight1 != 0) then maxweight = maxweight + weight1
						if(weight2 != 0) then maxweight = maxweight + weight2
						if(weight3 != 0) then maxweight = maxweight + weight3
						if(weight4 != 0) then maxweight = maxweight + weight4

						if(maxweight != 0) then(
							if(weight1 != 0) then(
								w1 = weight1
								append w.boneids (bone1+1)
								append w.weights w1
							)
							if(weight2 != 0) then(
								w2 = weight2
								append w.boneids (bone2+1)
								append w.weights w2
							)
							if(weight3 != 0) then(
								w3 = weight3
								append w.boneids (bone3+1)
								append w.weights w3
							)
							if(weight4 != 0) then(
								w4 = weight4
								append w.boneids (bone4+1)
								append w.weights w4
							)		
						)	
						append Weight_array w
						vertStr = stringstream ""
						format "%,%,%,%," (weight4 as string) (weight3 as string)  (weight2 as string) (weight1 as string) to:vertStr
						format "%,%,%,%," (bone4 as string) (bone3 as string)  (bone2 as string) (bone1 as string) to:vertStr
						vertStrList[startIndex+i] += vertStr
					)
				)
				BlockEndingFlag = readlong f
				padlen = endoffset - (ftell f)
				if ((padlen < 16)and(padlen > 0))then
				(
					fseek f padlen #seek_cur
				)

				startindex+= numVerts
			)while(ftell f) < endoffset
			append materialIDInfo.numFace faceCount
			stripNum += 1
		)while (Ftell f) < endChunkOffset

		startfaceid = 0
		for m = 1 to materialIDInfo.matID.count do(
			append materialIDInfo.startFaceID startfaceid
			startfaceid += materialIDInfo.numFace[m]
		)		
		numUV = 1
		
	)--结束 PS2 平台代码
	
	--开始PSP代码
	else if platform == "PSP" then(
		fseek f (start+16) #seek_set
		ChunkSize = readlong f #unsigned
		VertexElementType = readlong f #unsigned
		numMaterialID = readlong f #unsigned
		readlong f --skip zero
		fseek f 16 #seek_cur --skip boundingSphere XYZ Radius 4floats
		ScaleFactorX = readfloat f
		ScaleFactorY = readfloat f
		ScaleFactorZ = readfloat f
		VertCount = readlong f #unsigned
		TranslateFactorX = readfloat f
		TranslateFactorY= readfloat f
		TranslateFactorZ = readfloat f
		readlong f --skip zero
		HeaderSize = readlong f #unsigned -- Model Header Size+ All MaterialID Size
		fseek f 12 #seek_cur --skip 12 padding
		startindex = 0
		--fseek f MaterialIDStart #seek_set
		FaceDirection  =-1
		skinDataFlag = bit.get VertexElementType 17
		VertColorType = bit.and VertexElementType 0xff
		PerVertElementSize = (ChunkSize - HeaderSize) / VertCount
		for i = 1 to  numMaterialID do(
			fseek f 16 #seek_cur
			numVerts = readshort f #unsigned
			MatID = readshort f #unsigned + 1

			append materialIDInfo.matID MatID
			readfloat f
			--fseek f 8 #seek_cur
			Bone1 = readbyte f #unsigned
			Bone2 = readbyte f #unsigned
			Bone3 = readbyte f #unsigned
			Bone4 = readbyte f #unsigned
			Bone5 = readbyte f #unsigned
			Bone6 = readbyte f #unsigned
			Bone7 = readbyte f #unsigned
			Bone8 = readbyte f #unsigned
			
			f1 = startindex + 1
			f2 = startindex + 2
			
			next = ftell f
			if mod numVerts 2 == 0 then FaceDirection  =-1
				else FaceDirection  = 1
			
			facecount = 0

			offset = (start + 16 + HeaderSize + startindex*PerVertElementSize)
			fseek f offset #seek_set
			for j = 1  to numVerts do
			(	
				vertStr = stringstream ""
				if skinDataFlag == true then(
					weight1 = (readbyte f #unsigned)/128.0
					weight2 = (readbyte f #unsigned)/128.0
					weight3 = (readbyte f #unsigned)/128.0
					weight4 = (readbyte f #unsigned)/128.0
					weight5 = (readbyte f #unsigned)/128.0
					weight6 = (readbyte f #unsigned)/128.0
					weight7 = (readbyte f #unsigned)/128.0
					weight8 = (readbyte f #unsigned)/128.0
					w = (weight_data boneids:#() weights:#())
					maxweight = 0
					
					if(weight1 != 0) then maxweight = maxweight + weight1
					if(weight2 != 0) then maxweight = maxweight + weight2
					if(weight3 != 0) then maxweight = maxweight + weight3
					if(weight4 != 0) then maxweight = maxweight + weight4
					if(weight5 != 0) then maxweight = maxweight + weight5
					if(weight6 != 0) then maxweight = maxweight + weight6
					if(weight7 != 0) then maxweight = maxweight + weight7
					if(weight8 != 0) then maxweight = maxweight + weight8							
					if(maxweight != 0) then(
						if(weight1 != 0) then(
							w1 = weight1
							append w.boneids (bone1+1)
							append w.weights w1
						)
						if(weight2 != 0) then(
							w2 = weight2
							append w.boneids (bone2+1)
							append w.weights w2
						)
						if(weight3 != 0) then(
							w3 = weight3
							append w.boneids (bone3+1)
							append w.weights w3
						)
						if(weight4 != 0) then(
							w4 = weight4
							append w.boneids (bone4+1)
							append w.weights w4
						)
						if(weight5 != 0) then(
							w5 = weight5
							append w.boneids (bone5+1)
							append w.weights w5
						)
						if(weight6 != 0) then(
							w6 = weight6
							append w.boneids (bone6+1)
							append w.weights w6
						)
						if(weight7 != 0) then(
							w7 = weight7
							append w.boneids (bone7+1)
							append w.weights w7
						)
						if(weight8 != 0) then(
							w8 = weight8
							append w.boneids (bone8+1)
							append w.weights w8
						)							
					)	
					append Weight_array w
					format "%,%,%,%,%,%,%,%," (weight8 as string) (weight7 as string)  (weight6 as string) (weight5 as string) (weight4 as string) (weight3 as string)  (weight2 as string) (weight1 as string) to:vertStr
					format "%,%,%,%,%,%,%,%," (bone8 as string) (bone7 as string)  (bone6 as string) (bone5 as string) (bone4 as string) (bone3 as string)  (bone2 as string) (bone1 as string) to:vertStr
				)
				tu = ((readbyte f #unsigned) / 127.0) 
				tv = ((readbyte f #unsigned) / 127.0)  
				append UV1_Array [tu,1-tv,0]
				format "%,%," (tu as string) (tv as string) to:vertStr
				if (VertColorType == 0x35 ) then
				(
					VertColor = ReadShort f #unsigned               
					CB = (bit.and VertColor 0x001F)*8
					CG = (bit.shift (bit.and VertColor 0x03E0) -5)*8 
					CR = (bit.shift (bit.and VertColor 0x7C00) -10)*8
					CA = (bit.shift (bit.and VertColor 0x8000) -15)*255
					CPV=(color CR CG CB CA)--CPV == Color per vertexB
					append CPV_Array CPV
					format "%,%,%,%," (CB as string) (CG as string)  (CR as string) (CA as string) to:vertStr
				)
				else if (VertColorType == 0x3d) then
				(
					unknown1 = readshort f
					CB = readbyte f #unsigned
					CG = readbyte f #unsigned 	
					CR = readbyte f #unsigned			
					CA = readbyte f #unsigned
					CPV=(color CR CG CB CA)--CPV == Color per vertex
					append CPV_Array CPV
					format "%,%,%,%," (CB as string) (CG as string)  (CR as string) (CA as string) to:vertStr
				)
				nx = (readbyte f) / 127.0
				ny = (readbyte f) / 127.0
				nz = (readbyte f) / 127.0
				readbyte f
				
				transNormal =((transMatrix [nx,ny,nz])*parentBone.transform).pos
				transNormal = normalize transNormal			
				append Normal_array transNormal			
				format "%,%,%," (transNormal.x as string)  (transNormal.y as string) (transNormal.z as string) to:vertStr

				vx = (readshort f) / (32768.0) * ScaleFactorX + TranslateFactorX
				vy = (readshort f) / (32768.0) * ScaleFactorY + TranslateFactorY
				vz = (readshort f) / (32768.0) * ScaleFactorZ + TranslateFactorZ				
				transVert =((transMatrix [vx,vy,vz])*parentBone.transform).pos
				append Vert_array [transVert.x,transVert.y,transVert.z]
				format "%,%,%," (transVert.x as string)  (transVert.y as string) (transVert.z as string) to:vertStr

				append vertStrList (vertStr as string)
				if (VertColorType == 0x3d) then readshort f --unknown2
				if j > 2 then
				(
					FaceDirection  *= -1
					f3 = startindex + j
					c =  Vert_Array[vert_array.count]
					a =  Vert_Array[vert_array.count-2]
					b =  Vert_Array[vert_array.count-1]
					
					if(c!=b)AND(c!=a)AND(b!=a) then
					(
						facecount +=1
						if FaceDirection > 0 then append face_array [f1,f2,f3]
						else append face_array [f2,f1,f3]
					)
					f1 = f2
					f2 = f3
				)			
			)			
			append materialIDInfo.numFace facecount
			startindex+=numVerts			
			fseek f next #seek_set
		)
		startfaceid = 0
		for m = 1 to materialIDInfo.matID.count do(
			append materialIDInfo.startFaceID startfaceid
			startfaceid+=materialIDInfo.numFace[m]
		)		
		numUV = 1

	)--结束 PSP 平台代码
	else if platform == "WII" then(
		fseek f (start+0x6C) #seek_set
		MeshChunkOffset = readbelong f
		fseek f (start+0x74) #seek_set 
		skinChunkOffset = readbelong f
		fseek f MeshChunkOffset #seek_set
		chunkFlag = readbelong f
		fseek f 8 #seek_cur
		modelFlag = readbelong f
		headsize = readbelong f
		if(ModelFlag == 1)then
		(

			haveUV1=false
			haveUV2=false
			haveSkin=false
			haveColor=false
			haveNormal=false
			chunkStart = readbelong f 
			chunkSize = readbelong f
			Start = Ftell f
			vertexInfoOffset = readbelong f
			colorOffset = readbelong f
			UVOffset = readbelong f
			normalOffset = readbelong f
			faceMaterialOffset = readbelong f
			fseek f (Start+NormalOffset) #seek_Set
			normaltype = readbelong f
			if normaltype ==0x2A then haveNormal=true
			
			fseek f (Start+vertexInfoOffset) #seek_set
			vertexOffset = readbelong f
			VertCount = readbeword f
			VertFlag = readbeword f
			--format "顶点数量：%\n" vertcount
			VertDataFormat = bit.shift (bit.and VertFlag 0xF000) -12
			VertPower = bit.shift (bit.and VertFlag 0xF00) -8
			VertPower = pow 2 VertPower
			fseek f (Start+vertexOffset) #seek_set
			for i = 1 to VertCount Do 		
			(
				case VertDataFormat of
				(
					3:
					(
						vx = (readbeshort f)/ VertPower
						vy = (readbeshort f)/ VertPower
						vz = (readbeshort f)/ VertPower
						nx = (readbeshort f)/ VertPower
						ny = (readbeshort f)/ VertPower
						nz = (readbeshort f)/ VertPower
						transVert =((transMatrix [vx,vy,vz])*parentBone.transform).pos	
						transNormal =((transMatrix [nx,ny,nz])*parentBone.transform).pos
						transNormal = normalize transNormal	
						append Vert_array transVert --[vx,vy,vz]				
						append Normal_Array transNormal --[nx,ny,nz]
						if skinChunkOffset > 0 then
						(
							fseek f -12 #seek_cur
							v1 = readlong f
							v2 = readlong f
							v3 = readlong f
							append vert_Normal_datas [v1,v2,v3]
						)
					)
					4:
					(
						vx = readbefloat f / VertPower
						vy = readbefloat f / VertPower
						vz = readbefloat f / VertPower
						transVert =((transMatrix [vx,vy,vz])*parentBone.transform).pos
						
						append Vert_Array transVert --[vx,vy,vz]
						append Normal_Array [0,0,0]
					)
				)
				append CPV_Array (color 0 0 0 255)
				w = (weight_data boneids:#() weights:#())	
				append Weight_Array w
			)	
			fseek f (Start+colorOffset) #seek_set
			colorDataOffset = readbedword f
			colorCount = readbeword f
			colorFlag = readbeword f
			ColorDataFormat =bit.shift (bit.and colorFlag 0xF000) -12
			if colorCount > 0 then
			(
				haveColor = true
				for i = 1 to colorCount do
				(
					case ColorDataFormat of
					(
						2:
						(
							cb = readbyte f #unsigned
							cg = readbyte f #unsigned
							cr = readbyte f #unsigned
							ca = 255
							pad = readbyte f
							
						)
						5:
						(
							cb = readbyte f #unsigned
							cg = readbyte f #unsigned
							cr = readbyte f #unsigned
							ca = readbyte f #unsigned
							
						)
					)
					CPV=(color CR CG CB CA)--CPV Color per vertex
					append oldCPV_Array CPV
				)
			)

			
			fseek f (Start+UVoffset) #seek_set
			UV1Offset = readbedword f
			UV1Count = readbeword f
			UV1Flag = readbeword f
			TplNameOffset1 =readbedword f
			zero1 = readlong f
			UV2Offset = readbedword f
			UV2Count = readbeword f
			UV2Flag = readbeword f
			TplNameOffset2 =readbedword f	
			zero2 = readlong f
			fseek f (Start+UV1Offset) #seek_set
			UV1DataFormat =bit.shift (bit.and UV1Flag 0xF000) -12
			UV1Power = bit.shift (bit.and UV1Flag 0xF00) -8
			UV1Power = pow 2 UV1Power
			if UV1Count>1 then
			(
				haveUV1 = true
				for i = 1 to UV1Count do
				(
					case UV1DataFormat of
					(
						2:
						(
							tu = readbyte f / uv1power
							tv = readbyte f / uv1power
							append UV1_array [tu,1-tv,0]
						)
						
						3:
						(
							tu = readBEWord f / uv1power
							tv = readBEWord f / uv1power
							append UV1_array [tu,1-tv,0]
						)
						4:
						(
							tu = readbefloat f / uv1power
							tv = readbefloat f / uv1power
							append UV1_array [tu,1-tv,0]
						)
					)
				)
			)
			UV2DataFormat =bit.shift (bit.and UV2Flag 0xF000) -12
			UV2Power = bit.shift (bit.and UV2Flag 0xF00) -8
			UV2Power = pow 2 UV2Power	
			if UV2Count>1 then
			(
				haveUV2=true
				for i = 1 to UV2Count do
				(
					case UV2DataFormat of
					(
						2:
						(
							tu = readbyte f / uv2power
							tv = readbyte f / uv2power
							append UV2_array [tu,1-tv,0]
						)
						
						3:
						(
							tu = readBEWord f / uv2power
							tv = readBEWord f / uv2power
							append UV2_array [tu,1-tv,0]
						)
						4:
						(
							tu = readbefloat f / uv2power
							tv = readbefloat f / uv2power
							append UV2_array [tu,1-tv,0]
						)
					)
				)
			)
			fseek f (start+faceMaterialOffset) #seek_set
			FaceDataStart = readbedword f
			IndexOffset = readbedword f
			numIndex = readbeword f
			readshort f
			fseek f (start + IndexOffset) #seek_set
			BoneIDFormat  	=	0
			VertexIDFormat  =	0
			NormalIDFormat  =	0
			ColorIDFormat   =	0
			unk2Format		=	0
			UV1IDFormat 	=	0
			UV2IDFormat 	=	0
			unk3Format  	=	0	
			for i = 1 to numIndex do(
				ID = readbelong f
				u1 = readbyte f
				BoneID = (readbyte f #unsigned) + 1
				matID = readBEWORD f
				DataOffset = readBedword f
				dataSize = readbedword f
				next = ftell f
				if i == 3 then
				(
					boneIDFormat  	=  bit.and matID 0x3
					if boneIDFormat > 0 then haveSkin = true
					VertexIDFormat  =  bit.shift (bit.and matID 0xC)  -2
					NormalIDFormat  =  bit.shift (bit.and matID 0x30) -4
					ColorIDFormat   =  bit.shift (bit.and matID 0xC0) -6
					unk2Format  	=  bit.shift (bit.and matID 0x300) -8
					UV1IDFormat 	=  bit.shift (bit.and matID 0xC00) -10
					UV2IDFormat 	=  bit.shift (bit.and matID 0x3000) -12
					unk3Format  	=  bit.shift (bit.and matID 0xC000) -14
				)		
				if i > 2 then (
					if(dataOffset > 0 )then
					(
						if i == 3 then
						(
							append materialIDInfo.matID 1
						)
						else
						(							
							append materialIDInfo.matID  (MatID+1)
						)
						fseek f (start+DataOffset) #seek_set
						type  = readbyte f #unsigned
						numData = readbeword f						
						append materialIDInfo.numface (numdata/3)
						if type == 0x90 then
						(
							for m = 1 to numdata/3 do
							(
								--format"当前位置:0x%\n" (bit.intashex (ftell f))
								skin1 = readfacedata f BoneIDformat
								VertexID = (readfacedata f VertexIDFormat) + 1
								NormalID = (readfacedata f NormalIDFormat) + 1
								colorID = (readfacedata f colorIDFormat) + 1
								readfacedata f unk2Format
								UV1ID = (readfacedata f UV1IDFormat) + 1
								UV2ID = (readfacedata f UV2IDFormat) + 1
								readfacedata f unk3Format
								skin2 = readfacedata f BoneIDformat
								VertexID2 = (readfacedata f VertexIDFormat) + 1
								NormalID2 = (readfacedata f NormalIDFormat) + 1
								colorID2 = (readfacedata f ColorIDFormat) + 1
								readfacedata f unk2Format
								UV1ID2 = (readfacedata f UV1IDFormat) + 1
								UV2ID2 = (readfacedata f UV2IDFormat)  + 1
								readfacedata f unk3Format
								skin3 = readfacedata f BoneIDformat						
								VertexID3 = (readfacedata f VertexIDFormat) + 1
								NormalID3 = (readfacedata f NormalIDFormat) + 1
								colorID3 = (readfacedata f ColorIDFormat) + 1
								readfacedata f unk2Format
								UV1ID3 = (readfacedata f UV1IDFormat) + 1
								UV2ID3 = (readfacedata f UV2IDFormat) + 1
								readfacedata f unk3Format
								append face_array [vertexid2,vertexid,vertexid3]
								if haveUV1 == true then append UV1Face_array [UV1ID2,UV1ID,UV1ID3]
								if haveUV2 == true then append UV2Face_array [UV2ID2,UV2ID,UV2ID3]
								if haveColor == true then
								(
									CPV_Array[vertexid] = oldCPV_Array[colorID]
									CPV_Array[vertexid2] = oldCPV_Array[colorID2]
									CPV_Array[vertexid3] = oldCPV_Array[colorID3]
								)
								if haveSkin == true then
								(
									w = (weight_data boneids:#() weights:#())						
									append w.boneids BoneID
									append w.weights (1.0)								
									Weight_array [vertexid] = w
									Weight_array [vertexid2] = w
									Weight_array [vertexid3] = w
								)
							)
								
							
						)
					)	
					
				
				)
				fseek f next #seek_set
			)
			if skinChunkOffset > 0 then
			(
				haveSkin = true
				fseek f skinChunkOffset #seek_set
				skinStart = ftell f
				numData1 = readbeword f
				numData2 = readbeword f
				numData3 = readbeword f
				readbeword f
				offset1 = readbelong f
				offset2 = readbelong f
				offset3 = readbelong f
				unk4 = readbelong f
				unk5 = readbelong f
				offset5 = readbelong f
				numData5 = readbelong f
				VertPower = bit.shift (bit.and VertFlag 0xF00) -8
				VertPower = pow 2 VertPower		
				if (numData1 > 0) then
				(
					fseek f (skinStart+offset1) #seek_set
					for i = 1 to numData1 do
					(
						fseek f 48 #seek_cur
						dataOffset = readbelong f
						dataOffset2 = readbelong f
						BoneID = (readbeword f)+1
						numVerts = readbeword f 
						padLen = readbyte f
						fseek f 3 #seek_cur
						data1next = ftell f
						fseek f (skinStart+dataOffset+padLen) #seek_set
						for j = 1 to numVerts do
						(					
							v1 = readlong f
							v2 = readlong f
							v3 = readlong f
							id = finditem vert_Normal_datas [v1,v2,v3]
							w = (weight_data boneids:#() weights:#())	
							append w.boneids BoneID
							append w.weights (1.0)
							Weight_Array[ID] = w
						)
						fseek f data1next #seek_set
					)
				)
				if (numData2>0) then
				(
					fseek f (skinStart+offset2) #seek_set
					for i = 1 to numData2 do
					(
						fseek f 96 #seek_cur
						data1Offset = readbelong f
						data2Offset = readbelong f
						data1Offset2 = readbelong f
						BoneID1 = (readbeword f)+1
						BoneID2 = (readbeword f)+1
						numVerts = readbeword f
						padLen = readbyte f
						readbyte f
						data2next = ftell f
						for j = 1 to numVerts do
						(
							fseek f (skinStart+data1Offset+PadLen) #seek_set
							fseek f ((j-1)*12) #seek_cur
							v1 = readlong f
							v2 = readlong f
							v3 = readlong f
							id = finditem vert_Normal_datas [v1,v2,v3]					
							w = Weight_Array[ID]
							append w.boneids BoneID1
							append w.boneids BoneID2
							fseek f (skinStart+data2Offset) #seek_set
							fseek f ((j-1)*2) #seek_cur
							w1 = (readbyte f #unsigned) / 256.0
							w2 = (readbyte f #unsigned) / 256.0
							append w.weights w1
							append w.weights w2
							Weight_Array[ID] = w
						)
						fseek f data2next #seek_set
					)
				)
				if (numData3 > 0) then
				(
					fseek f (skinStart+offset3) #seek_set
					for i = 1 to numData3 do
					(
						fseek f 48 #seek_cur
						data1Offset = readbelong f
						data2Offset = readbelong f
						readbelong f
						data3Offset = readbelong f
						BoneID = (readbeword f)+1
						numVerts = readbeword f
						data3next = ftell f
						for j = 1 to numVerts do
						(
							fseek f (skinStart+data2offset) #seek_set
							fseek f ((j-1)*2) #seek_cur
							VertID = (readbeword f)+1
							fseek f (skinStart+data3Offset) #seek_set
							fseek f (j-1) #seek_cur
							weight = (readbyte f #unsigned) / 256.0
							w = Weight_Array[VertID]
							append w.boneids BoneID
							append w.weights weight
							Weight_Array[VertID] = w
						)
						fseek f data3next #seek_set
					)
				)
				
			)
			startfaceid = 0
			for m = 1 to materialIDInfo.matID.count do(
				append materialIDInfo.startFaceID startfaceid
				startfaceid+=materialIDInfo.numFace[m]
			)		
			if haveUV1==true then numUV = 1
			if haveUV2==true then numUV = 2	
			if haveSkin == true then skinDataFlag = true

			if (haveSkin == true) then
			(
				for i = 1 to weight_Array.count do
				(					
					w = Weight_Array[i]
					if w.boneids.count == 0 then
					(
						append w.boneids 1
						append w.weights (1.0)
						Weight_Array[i] = w
					)
				)
			)
			--只针对少数没有法线的模型，所以只是简单的计算法线
			if haveNormal == false then
			(
				for j = 1 to Face_Array.count do
				(
					firstVec = Vert_Array[Face_Array[j].y] - Vert_Array[Face_Array[j].x]
					secondVec = Vert_Array[Face_Array[j].z] - Vert_Array[Face_Array[j].x]
					normal = cross firstVec secondVec 
					normal_Array[Face_Array[j].x] = normal_Array[Face_Array[j].x] + Normal
					normal_Array[Face_Array[j].y] = normal_Array[Face_Array[j].y] + Normal
					normal_Array[Face_Array[j].z] = normal_Array[Face_Array[j].z] + Normal
				)
				for j = 1 to Normal_Array.count do
				(
					normal_Array[j] = normalize normal_Array[j]
				)
			)

			--此方法同样适用于导出插件(exporter)关于顶点属性数据和面数据的导出。
			--但是有缺点，重复的顶点太多。文件体积会变大。不如我当前的MDL Exporter的算法好。
			newFaceArray =#()
			vertexElementList = vertexElementArray vertices:#() boneids_weights:#() normals:#() vcolors:#() uv1:#() uv2:#()
			FOR i = 1 to face_array.count do (
				append newFaceArray [0,0,0]
				for j = 1 to 3 do(
					vertStr = stringstream ""

					newID = (i-1) * 3 + j
					newFaceArray[i][j] = newID
					vertID = face_array[i][j]
					append vertexElementList.vertices vert_array[vertID]
					append vertexElementList.normals normal_array[vertID]
					format "%,%,%," (vert_array[vertID].x as string)  (vert_array[vertID].y as string) (vert_array[vertID].z as string) to:vertStr
					format "%,%,%," (normal_array[vertID].x as string)  (normal_array[vertID].y as string) (normal_array[vertID].z as string) to:vertStr

					if haveColor == true then(
						append vertexElementList.vcolors CPV_Array[vertID]
						format "%,%,%,%," (CPV_Array[vertID].r as string) (CPV_Array[vertID].g as string)  (CPV_Array[vertID].b as string) (CPV_Array[vertID].a as string) to:vertStr
					) 
					if haveUV1 == true then(
						uv1ID = UV1Face_Array[i][j]
						append vertexElementList.uv1 UV1_Array[uv1ID]
						format "%,%," (UV1_Array[uv1ID].x as string) (UV1_Array[uv1ID].y as string) to:vertStr
					) 
					if haveUV2 == true then(
						uv2ID = UV2Face_Array[i][j]
						append vertexElementList.uv2 UV2_Array[uv2ID]
						format "%,%," (UV2_Array[uv2ID].x as string) (UV2_Array[uv2ID].y as string) to:vertStr
					) 					
					if haveSkin == true then(
						append vertexElementList.boneids_weights weight_array[vertID]
						w = Weight_Array[vertID]
						for bw = 1 to w.boneids.count do(
							weight = w.weights[bw]
							boneID = w.boneids[bw]
							format "%,%," (weight as string) (boneID as string) to:vertStr
						)
					) 
					append vertStrList (vertStr as string)
				)
			)
			face_array = newFaceArray
			Vert_Array = vertexElementList.vertices		
			Normal_Array = vertexElementList.normals
			if haveColor == true then CPV_Array = vertexElementList.vcolors 
			if skinDataFlag == true then  Weight_Array = vertexElementList.boneids_weights
			if haveUV1 == true then UV1_Array = vertexElementList.uv1
			if haveUV2 == true then UV2_Array = vertexElementList.uv2

		)
	)--end结束 WII 平台代码

		
		
	if optimizeModel == true then(
		vertStrList_welded = deepCopy vertStrList

		--remove duplicates vertex element
		for i in vertStrList_welded.count to 1 by -1 do
		(
			id = findItem vertStrList_welded vertStrList_welded[i]
			if (id != i) do deleteItem vertStrList_welded id
		)

		--get new triangle list
		newFaceArray =#()
		FOR i = 1 to face_array.count do (
			append newFaceArray [0,0,0]
			for j = 1 to 3 do(
				vertStr = vertStrList[face_array[i][j]]
				id = findItem vertStrList_welded vertStr
				newFaceArray[i][j] = id
			)
		)
		Face_array = newFaceArray
		vertexElementList = vertexElementArray vertices:#() boneids_weights:#() normals:#() vcolors:#() uv1:#() uv2:#()
		for i = 1 to vertStrList_welded.count do (
			vertStrElement = vertStrList_welded[i]
			id = findItem vertStrList vertStrElement
			append vertexElementList.vertices Vert_Array[id]			
			append vertexElementList.normals Normal_Array[id]
			append vertexElementList.vcolors CPV_Array[id]
			if skinDataFlag == true then append vertexElementList.boneids_weights Weight_Array[id]
			if numUV > 0 then append vertexElementList.uv1 UV1_Array[id]
			if numUV > 1 then append vertexElementList.uv2 UV2_Array[id]
		)
		Vert_Array = vertexElementList.vertices		
		Normal_Array = vertexElementList.normals
		CPV_Array = vertexElementList.vcolors 
		if skinDataFlag == true then  Weight_Array = vertexElementList.boneids_weights
		if numUV > 0 then UV1_Array = vertexElementList.uv1
		if numUV > 1 then UV2_Array = vertexElementList.uv2
	)
	
	if smoothNormal == true then(
		uniqueVertFaceArr = uniqueVertFaceArray vert_array face_array
		newNormalStruct = calculateNormal uniqueVertFaceArr.weldVertArray uniqueVertFaceArr.weldFaceArray vert_array
		Normal_Array = newNormalStruct.normals
	)


	msh = mesh vertices:Vert_array faces:Face_array
	if numUV > 0 then(			
		msh.numTVerts = UV1_array.count
		buildTVFaces msh
		for j = 1 to UV1_array.count     do setTVert  msh j UV1_array[j]
		for j = 1 to Face_array.count   do setTVFace msh j Face_array[j]
		for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]

		for m = 1 to materialIDInfo.matID.count do(
			for n = 1 to materialIDInfo.numface[m] do(
				setFaceMatID msh (n+materialIDInfo.startFaceID[m]) materialIDInfo.matID[m] --赋予贴图通道，材质ID
			)			
		)			
		if numUV == 2 then
		(
			meshop.setNumMaps msh 3	-- 0 is vertex color, 1+ are textures
			--meshop.setMapSupport msh 2 true			-- enable texturemap channel
			meshop.setNumMapVerts msh 2 UV2_array.count
			meshop.setNumMapFaces msh 2 face_array.count
			for j = 1 to UV2_array.count do meshop.setMapVert msh 2 j UV2_array[j]
			for j = 1 to face_array.count do meshop.setMapFace msh 2 j face_array[j]--UV face
		)			
	)
	--VertexColor顶点颜色
	if (VertexColorOn == true) and (CPV_Array.count > 0) then
	(
		setNumCPVVerts msh CPV_Array.count
		buildVCFaces msh
		for i = 1 to CPV_Array.count do
		(
			setVertColor  msh i CPV_Array[i]
		)
	)

	--设置父级
	msh.parent = ParentBone
	if ObjectMatrixflag > 0 then( setuserprop msh.parent "ObjectMatrix" 1 )
	msh.name = msh.parent.name + "_object"

	
	--赋予模型材质
	if numTexture > 1 then
	(
		msh.material = mm
		for m in msh.material.materialList do
		(
			if AutoShowTextures == true then
			(
				showTextureMap m on
			)
		)
	)
	else
	(
		msh.material = MaterialArray[1][1]
		if AutoShowTextures == true then
		(
			showTextureMap msh.material on
		)		
	)
	/*
	--PS2 and PSP
	select msh
	modPanel.addModToSelection (Normalmodifier ()) ui:on
	$.modifiers[#Normal].flip = off
	$.modifiers[#Normal].unify = on
	clearSelection()			
	*/		
	--蒙皮
	if (autoskin == true)and (skinDataFlag == true) then
	(
			DisableSceneRedraw()
			max modify mode
			select msh
			skinMod = skin ()
			addModifier msh skinMod
			subobjectLevel = 1
			msh.skin.bone_Limit = 4				
			dmy = dummy name:"AnimationData"  ishidden:true
			dmy.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
			--BoneArray[2][1].parent = dmy
			for k = 1 to BoneArray[2].count do
			(
				skinOps.addBone skinMod  BoneArray[2][k] 0
				
			)
			delete dmy
			modPanel.setCurrentObject skinMod		
			for i = 1 to Weight_array.count do (
				w = Weight_array[i]
				skinOps.ReplaceVertexWeights skinMod i w.boneids w.weights
			)
			max select none
			EnableSceneRedraw()	
		
	)

)
struct entryInfoStruct
(
	entryOffsets,entryNames
)
fn readEntry fname =
(
	bool = false 
	if fname != undefined then(
		f2 = fopen fname "rb"
		Idstring = readlong f2
		DecompressSize = readlong f
		fclose f2
		if Idstring == 0x4D48325A or Idstring == 0x5A32484D then
		(			
			exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe"
			DOSCommandName = "-z -s "+"\""+fname+"\""
			ShellLaunch exename DOSCommandName					
			decompressFileName = (getFilenamePath fname) +"\\"+(getFilenameFile  fname)+ "_decompress"+(getFilenameType fname)
			fname = decompressFileName			
			do(
				sleep 1 -- must be wait 1 second  , because maxscript execute very fast, if not wait fname will == undefined,this time mh2tools not done decomporess work!
				bool = doesFileExist fname
				fileSize = getFileSize fname
			)while (bool != true)AND(fileSize != DecompressSize)
			
		)
		else
		(
			bool = true
		)
		
	)

	if ( fname != undefined) AND bool == true then(
		MDLfname = fname
		f = fopen fname "rb"
		if f != undefined then
		(
			MDLFlag = readlong f
			if MDLFlag == 0x504d4c43 then
			(
				platform = "WII"
				bigEndian = true
			)else(
				platform = "PC"
				bigEndian = false
			)
			fseek f 0x20 #seek_set
			firstEntryIndexOffset = readUInt f
			lastEntryIndexOffset = readUInt f
			fseek f firstEntryIndexOffset #seek_set
			EntryNameArray =#()
			EntryIndexArray=#()
			
			
			loop = true
			do
			(
				append EntryIndexArray (ftell f)
				NextEntryIndexOffset = readUInt f
				PrevEntryIndexOffset = readUInt f
				EntryOffset = readUInt f
				fseek f EntryOffset #seek_set
				BoneOffset = readUInt f
				
				fseek f BoneOffset #seek_set
				fseek f 24 #seek_cur
				RootBoneName = readstring f
				if RootBoneName == "" then
				(
					fseek f (boneOffset+16) #seek_set
					suboffset = readUInt f
					fseek f (subOffset+24) #seek_set
					RootBoneName = readstring f
				)
				append EntryNameArray (RootBoneName)					
				if(NextEntryIndexOffset==0x20)then (loop = false)else(fseek f NextEntryIndexOffset #seek_set)
			)while loop
								
			if MDLFlag != 0x504d4c43 and MDLFlag != 0x434C4D50 then 
			(
				Messagebox("Sorry! Don't support this file!")
			)
			fclose f
		)-- end if f != undefined
	)
	--clearlistener()
	return (entryInfoStruct entryOffsets:EntryIndexArray entryNames:EntryNameArray)
)

fn importMDL fname entryIndexOffset imagetype autoskin AutoShowTextures VertexColorOn optimizeModel smoothNormal =
(

	if ( fname != undefined) then(		
		BoneArray=#(#(),#(),#(),#())
		MeshSkinArray = #(#(),#())		     
		f = fopen fname "rb"
		fseek f entryIndexOffset #seek_set
		NextEntryIndexOffset = readUInt f
		PrevEntryIndexOffset = readUInt f
		EntryOffset = readUInt f
		fseek f EntryOffset #seek_set
		RootBoneOffset = readUInt f
		
		curoffset = ftell f
		fseek f RootBoneOffset #seek_set
		fseek f 24 #seek_cur
		RootBoneName = readstring f
		if RootBoneName == "" then
		(
			fseek f (RootboneOffset+16) #seek_set
			RootBoneOffset = readUInt f
		)		
		ReadBone f RootBoneOffset BoneArray--读取骨骼
		fseek f curoffset #seek_set
		
		
		fseek f 16 #seek_cur
		objectInfoIndexOffset = ftell f
		FirstObjectInfoOffset = readUInt f
		lastObjectInfoOffset = readUInt f
		if (FirstObjectInfoOffset != objectInfoIndexOffset) then(
			loop = true
			fseek f FirstObjectInfoOffset #seek_set
			Do
			(
				NextObjectInfoOffset = readUInt f
				PrevObjectInfoOffset = readUInt f
				ObjectParentBoneOffset = readUInt f
				ObjectOffset = readUInt f
				if platform != "WII" then(
					ReadModel f ObjectOffset BoneArray fname imagetype autoskin AutoShowTextures VertexColorOn optimizeModel smoothNormal
				)
				else(
					wiiHaveMeshFlag = 0
					fseek f (ObjectOffset+0x6C) #seek_set
					wiiMeshChunkOffset = readInt f
					fseek f (wiiMeshChunkOffset+0xC) #seek_set
					wiiHaveMeshFlag = readInt f
					if (wiiHaveMeshFlag == 1) then(
						ReadModel f ObjectOffset BoneArray fname imagetype autoskin AutoShowTextures VertexColorOn optimizeModel smoothNormal
					)
				)
				if(NextObjectInfoOffset==objectInfoIndexOffset)then loop = false else fseek f  NextObjectInfoOffset #seek_set					
			)while loop
		)
		
		fclose f

		
	)--end if ( fname != undefined) then(

)
rollout MH2MDLImport "MH2 MDL/DFF Importer"
(
	radioButtons rdo1 "Image Type:" tooltip:"Textures format" labels:#("dds", "png","tga","bmp") align:#left default:2
	listbox lbx1 "Objects:" 
	on lbx1 doubleClicked itm do
	(
		if lbx1.selection > 0 then
		(
		entryIndexOffset = EntryIndexArray[lbx1.selection]
		imagetype = imagetypeArray[rdo1.state]
		autoskin = true
		AutoShowTextures = true
		VertexColorOn = true
		optimizeModel = true
		smoothNormal = false
		importMDL MDLfname entryIndexOffset imagetype autoskin AutoShowTextures VertexColorOn optimizeModel smoothNormal
		)--end if MH2Rollout.lbx1.selection > 0 then
		
	)
)
fn createMDLImportWindow fname =
(
	if MH2MDL_Tool != undefined then (
		closeRolloutFloater MH2MDL_Tool
	)
	MH2MDL_Tool = newRolloutFloater "Importer" 220 310 10 50	
	addRollout MH2MDLImport MH2MDL_Tool rolledup:false
	entryInfo = readEntry fname
	MH2MDLImport.lbx1.items = entryInfo.entryNames
	MH2MDLImport.lbx1.selection = 1
	EntryIndexArray = entryInfo.entryOffsets
)
