fileIn "function.ms"
global AnimFlagBoneID=0;AnimFlagOffset=0

fn WriteBone f bne boneArray MeshArray =
(
	append boneArray[1] bne
	append boneArray[2] (ftell f)
	--$.children]
	--format "名称：%\n" bne.name
	subArraytemp = bne.children
	subArray=#()
	if subarraytemp.count > 0 then
	(
		for i = 1 to subarraytemp.count do(
			if (classof subarraytemp[i])==BoneGeometry or (classof subarraytemp[i])== Dummy then append subarray subarraytemp[i]
			else if (classof subarraytemp[i])==Editable_mesh then append MeshArray subarraytemp[i]
		)
	)
	--format "%\n" subarray
	boneid = getUserProp bne "BoneIndex"
	firstInt = getUserProp bne "FirstInt"
	if firstInt != undefined then writelong f firstint #unsigned
	else writelong f 0
	writelong f 0--sibling offset
	writelong f 0--parent offset
	writelong f 0x60--root bone offset
	writelong f 0-- first subbone offset
	
	Animflag = getuserprop bne "AnimFlag"
	if Animflag == 1 then
	(
		AnimFlagBoneID = (getuserprop bne "BoneIndex")+1
		AnimFlagOffset = ftell f
	)
	writelong f 0 -- hierarchy offfset
	if(bne.name.count < 40)then
	(
		writestring f bne.name
		for i = 1 to (40-bne.name.count-1) do writebyte f 0
		if (bne.name.count<32) then
		(
			curofs = ftell f
			fseek f -8 #seek_cur
			writebyte f 1
			fseek f curofs #seek_set
		)
	)
	else
	(
		messagebox("Export error!BoneName is too long, please do not more than 39 letters!\nBone:"+bne.name)
		fclose f
		--deleteFile fname
		EXIT
	)
	if(bne.parent!=undefined)then
	(
		ParentCoordBoneMatrix= bne.transform * (inverse bne.parent.transform)--父系坐标矩阵
	)
	else
	(
		ParentCoordBoneMatrix = bne.transform
	)
	WorldCoordBoneMatrix = bne.transform--世界坐标矩阵
	
	writefloat f ParentCoordBoneMatrix.row1.x
	writefloat f ParentCoordBoneMatrix.row1.y
	writefloat f ParentCoordBoneMatrix.row1.z
	writelong f 0
	writefloat f ParentCoordBoneMatrix.row2.x
	writefloat f ParentCoordBoneMatrix.row2.y
	writefloat f ParentCoordBoneMatrix.row2.z
	writelong f 0
	writefloat f ParentCoordBoneMatrix.row3.x
	writefloat f ParentCoordBoneMatrix.row3.y
	writefloat f ParentCoordBoneMatrix.row3.z
	writelong f 0
	writefloat f ParentCoordBoneMatrix.row4.x
	writefloat f ParentCoordBoneMatrix.row4.y
	writefloat f ParentCoordBoneMatrix.row4.z
	writefloat f 1.0
	
	writefloat f WorldCoordBoneMatrix .row1.x
	writefloat f WorldCoordBoneMatrix .row1.y
	writefloat f WorldCoordBoneMatrix .row1.z
	writelong f 0
	writefloat f WorldCoordBoneMatrix .row2.x
	writefloat f WorldCoordBoneMatrix .row2.y
	writefloat f WorldCoordBoneMatrix .row2.z
	writelong f 0
	writefloat f WorldCoordBoneMatrix .row3.x
	writefloat f WorldCoordBoneMatrix .row3.y
	writefloat f WorldCoordBoneMatrix .row3.z
	writelong f 0
	writefloat f WorldCoordBoneMatrix .row4.x
	writefloat f WorldCoordBoneMatrix .row4.y
	writefloat f WorldCoordBoneMatrix .row4.z
	writefloat f 1.0
	

	if subarray.count > 0 then
	(
		for b = 1 to subarray.count do
		(
			WriteBone f subArray[b] BoneArray MeshArray
		)
	)
)---end writebone
fn WriteMDLFile f outRootBone outfname compressFlag outVertexColor outUV2 recalNormal=
(
	if outfname != undefined then
	(
		
		if (outRootBone!=undefined)and((getUserProp outRootBone "BoneIndex")==0) then
		(
		gc()	
		OFSArr=#()
		BoneArray=#(#(),#())--1=bone 2= offset
		MeshArray=#()					
			debugmode = false
			if debugmode == true then debugname = "C:\\Users\\" +sysInfo.username+"\\Desktop\debug_mdl_exporter.txt"
			if debugmode == true then outdebug = createFile debugname
			f = fopen outfname "wb"
			--f1 = fopen outfname "rb"
			writestring f "PMLC"
			fseek f 4 #seek_set
			writelong f 1
			writelong f 0--0x8  filesize
			writelong f 0--0xC  OffsetTable
			writelong f 0--0x10 OffsetTable 
			writelong f 0--0x14 numTables
			writelong f 0--0x18 zero
			writelong f 0--0x1C zero
			append OFSArr (ftell f)
			writelong f 0x30 -- 0x20  first entry index offset
			append OFSArr (ftell f)
			writelong f 0x30 -- 0x24  last entry  index offset
			writelong f 0 --0x28 zero
			writelong f 0 --0x2C zero
			append OFSArr (ftell f)
			writelong f 0x20 --0x30 next entry index offset

			append OFSArr (ftell f)
			writelong f 0x20 --0x34 last entry  index offset

			append OFSArr (ftell f)
			writelong f 0x40 --0x38 entry offset
			writelong f 0 -- 0x3C zero

			append OFSArr (ftell f)
			writelong f 0x60 --0x40  rootBoneOffset  ,same time this position is entry offset
			writelong f 0;writelong f 0;writelong f 0;--0x44-0x50  3 zeros

			writelong f 0 -- 0x50 rootbone flag; unknown role
			append OFSArr (ftell f)--0x54 objectmeshInfoIndexOffset
			writelong f 0x54 --0x54 first objectMeshInfoOffset
			append OFSArr (ftell f)
			writelong f 0x54 --0x58 last objectMeshInfoOffset
			writelong f 0 --0x5C-0x60 zero					
			--全局变量注意初始化为空
			AnimFlagBoneID=0;AnimFlagOffset=0
			
			WriteBone f outRootBone BoneArray MeshArray
			BoneEndOffset = Ftell f
			--fseek f 0x60 #seek_set
			--fseek f1 0x60 #seek_set
			
			for b = 1 to boneArray[1].count do(
				fseek f boneArray[2][b] #seek_set
				fseek f 4 #seek_cur--first int skip
				bne = boneArray[1][b]
				--append OFSArr (ftell f)
				if (b !=1)then
				(
					subArraytemp = bne.parent.children
					subArray=#()
					if subarraytemp.count > 0 then
					(
						for i = 1 to subarraytemp.count do(
							if (classof subarraytemp[i])==BoneGeometry or (classof subarraytemp[i])== Dummy then append subarray subarraytemp[i]					
						)
					)
					if (subarray.count > 1)then
					(
						bid = (getuserprop bne "BoneIndex")+1
						sibid = 0
						for i = 1 to subarray.count do(
							if (((getuserprop subarray[i] "BoneIndex")+1) == bid) then 
							(
								if i < subarray.count then
								(
									sibid = i+1
									append OFSArr (ftell f)
									writelong f (bonearray[2][(getuserprop subarray[sibid] "BoneIndex")+1]) #unsigned
								)
								else (
									fseek f 4 #Seek_cur-- is last one. so no sibling offset
								)	
							)
						)
						
					)
					else
					(
						fseek f 4 #Seek_cur-- no sibling bone
					)

					parentid = getuserprop bne.parent "BoneIndex"
					append OFSArr (ftell f)--parent offset
					writelong f (bonearray[2][parentid+1]) #unsigned
					
				)
				else(
					fseek f 8 #Seek_cur
				)
				append OFSArr (ftell f) -- root bone offset
				fseek f 4 #seek_cur
				subArraytemp = bne.children
				subArray=#()
				if subarraytemp.count > 0 then
				(
					for i = 1 to subarraytemp.count do(
						if (classof subarraytemp[i])==BoneGeometry or (classof subarraytemp[i])== Dummy then append subarray subarraytemp[i]
					)
				)
				if (subarray.count > 0 ) then
				(
					subid = getuserprop subarray[1] "BoneIndex"
					suboffset = bonearray[2][subid+1]
					append OFSArr (ftell f) -- first subbone offset
					writelong f suboffset #unsigned
				)
				else fseek f 4 #seek_cur
				if b == animflagboneid then append OFSArr (ftell f)-- hierarchy offfset
			)--end write bone hierarchy
			--format"AnimFlagOffset:0x%\tanimflagboneid:%\n" (bit.intashex AnimFlagOffset) animflagboneid
			if AnimFlagOffset> 0 then
			(
				fseek f  animFlagOffset #seek_set
				writelong f BoneEndOffset #unsigned
				fseek f BoneEndOffset #seek_set
				numBone =  bonearray[1].count
				writelong f numBone #unsigned
				unknownFlag = getuserprop boneArray[1][1] "unknownFlag"
				if unknownFlag != undefined then writelong f unknownFlag #unsigned --unknownFlag
				else writelong f 0
				append OFSArr (ftell f)
				writelong f 0x60 -- root bone offset
				append OFSArr (ftell f)
				writelong f (BoneEndOffset+0x20) #unsigned -- frame list dataoffset 
				append OFSArr (ftell f)
				boneTransDataIndexOffset = ftell f
				writelong f (BoneEndOffset+0x20+numBone*8) #unsigned--bone transform info offset 0,0,0,1.0,0,0,0
				writelong f 0 -- zero
				writelong f 0 -- padding
				writelong f 0 -- padding
				for i = 1 to numBone do
				(
					animKey = getuserprop bonearray[1][i] "BoneID"
					boneType = getuserprop bonearray[1][i] "BoneType"
					writeshort f animKey #unsigned
					writeshort f BoneType #unsigned
					append OFSArr (ftell f)--bone offset
					writelong f bonearray[2][i] #unsigned-- bone offset
				)
				padlen = 16-(mod (ftell f) 16)
				if padLen>0 and padlen < 16 then 
				(
					for i = 1 to padLen do writebyte f 0
				)
				boneTransDataOffset = ftell f
				fseek f boneTransDataIndexOffset #seek_set
				writelong f boneTransDataOffset #unsigned
				fseek f boneTransDataOffset #seek_set
				

				for i = 1 to numBone do
				(
					writefloat f 0;writefloat f 0;writefloat f 0;writefloat f 1.0;
					writefloat f 0;writefloat f 0;writefloat f 0;writefloat f 0;
				)
				--padding

				
			)--end if have animflag
			
			fseek f 0 #seek_end
			if MeshArray.count > 0 then
			(
				objectIndexOffset = #()
				objectOffsetArray = #()
				
				for i=1 to MeshArray.count do
				(
					append objectIndexOffset (ftell f)
					append OFSArr (ftell f)--next object mesh
					writelong f 0 --next object mesh
					append OFSArr (ftell f)--prev object mesh
					writelong f 0 --next objcet mesh
					parentBoneID = getuserprop mesharray[i].parent "BoneIndex"
					parentBoneOffset = bonearray[2][parentBoneID+1]
					append OFSArr (ftell f)--parent bone offset
					writelong f parentBoneOffset #unsigned
					append OFSArr (ftell f)-- object mesh offset
					writelong f 0 -- object mesh offset
					append OFSArr (ftell f)--entry offset
					writelong f 0x40----entry offset
					writelong f 0--zero
					writelong f 3--unknown
					writelong f 0--padding
				)

				
				for i=1 to MeshArray.count do
				(
					
					---以下获取模型数据
					num_verts = meshArray[i].numverts
					num_faces = meshArray[i].numfaces
					num_colors = getNumCPVVerts meshArray[i]
					num_uvs = meshArray[i].numTVerts
					num_maps = meshop.getNumMaps meshArray[i]
					face_array =#()
					UVFace_array=#()
					UV2Face_array=#()
					MatID_array=#()
					vert_array =#()
					normal_array =#()
					uv_array=#()
					UV2_Array=#()
					Color_array = #()
					OldSkin_Array=#()
					Skin_Array = #()
					--Skin_array =#(#(),#())--1 weight 2 boneID
					MatIDs = 0
					
					skinFlag = 0
					meshmod = mesharray[i].modifiers
					if meshmod.count > 0 then
					(
						for o = 1 to meshmod.count do
						(
							if (classof meshmod[o] == Skin) then skinFlag = 1
						)
			
					)							
					--以下是获得蒙皮数据
					--******************
					if (skinflag==1)then
					(
						if classof meshmod[1] == Skin then
						(
							max modify mode
							select meshArray[i]
							subobjectLevel = 1
							modPanel.setCurrentObject MeshArray[i].skin
							--subobjectLevel = 1
							--MeshArray[i].skin.bone_Limit = 4
							--$.modifiers[#Skin].bone_Limit = 4
							--skinOps.GetVertexWeightCount $.skin 1 获取指定顶点的骨骼数量
							--skinOps.GetVertexWeightBoneID <Skin> <vertex_integer> <vertex_bone_integer>  Returns the system bone index of the Nth bone affecting the specified vertex. 
							--skinOps.GetVertexWeight <Skin> <vertex_integer> <vertex_bone_integer> Returns the influence of the Nth bone affecting the specified vertex. 
							--skinOps.GetVertexWeight 获取指定的骨骼1,2,3,4权重
							--skinOps.GetVertexWeightBoneID 获取权重1,2,3,4的对应的骨骼ID
							DisableSceneRedraw()
							for v = 1 to num_verts do
							(
								w = (weight_data boneids:#() weights:#())
								count = skinOps.GetVertexWeightCount MeshArray[i].skin v
								if count == 0 then
								(
									Messagebox("Export error! VertexID:"+(v as string)+" Weights missing, Can't export!")
									EXIT	
								)
								if count < 5  then
								(

									for b = 1 to count do
									(
										weight = skinOps.GetVertexWeight  MeshArray[i].skin v b
										if weight > 0 then
										(
											UI_BoneID = skinOps.GetVertexWeightBoneID  MeshArray[i].skin v b																							
											BoneName = skinOps.GetBoneName  MeshArray[i].skin UI_BoneID 1
											maxVer = maxVersion()--#(16000,42) is max2014 	
											if maxVer[1] == 16000 then
											(
												BoneName = skinOps.GetBoneNameByListID MeshArray[i].skin UI_BoneID 1
											)
																						
											Bone = getnodebyname BoneName  --all:true
											BoneID = (getuserprop bone "BoneIndex")---1
											append w.weights weight	
											append w.boneids BoneID
										)
									)
									
								)
								else
								(
									Messagebox("Export error! VertexID:"+(v as string)+" Bone quantity more than 4, Can't export!\nPlease set skin modifier bone affect limit to 4!")
									EXIT							
								)

								append OldSkin_Array w
							)
							EnableSceneRedraw()
							max select none
						)							
						else
						(
							messagebox("Export error! Skin modifier in the stack must be the first one!")
							EXIT
						)								
						if debugmode == true then format"获取SKIN完成！\n" to:outdebug
					)--end skin
					--******************结束蒙皮
				
					--以下为获取模型面数据
					--********************
					
					--模型MatID 数量和材质数量必须一样。
					--模型MatID数据 每个数据里面对应的材质ID可以更改。可以不按顺序排列！
					/*
					for mf =  1 to num_faces do
					(
						FaceMatID = getFaceMatID MeshArray[i] mf 
						if debugmode == true then format"% MATID:%\n" mf FaceMatID to:outdebug
						
					)					
					*/
					
					
					UV2Flag = false
					
					if (num_maps > 2)do
					(
						if ((meshop.getMapSupport MeshArray[i] 2) == true) then
						(
							UV2Flag = true
						)
					)
					UsedMatIDArray =#()
					select MeshArray[i]
					numMatIDs = 0		-- original used matrials count include unused materials			
					for mf =  1 to num_faces do
					(
						FaceMatID = getFaceMatID MeshArray[i] mf
						if FaceMatID > numMatIDs then numMatIDs = FaceMatID
						append UsedMatIDArray facematid
					)
					--获取实际使用的材质数量
					for u in UsedMatIDArray.count to 1 by -1 do
					(
						id = findItem UsedMatIDArray UsedMatIDArray[u]
						if (id != u) do deleteItem UsedMatIDArray id
					)
					sort UsedMatIDArray					
					MaterialCount = 0 -- is real used materials count
					if(MeshArray[i].material != undefined) then
					(
						if (classof MeshArray[i].material)== Multimaterial then
						(
							--MaterialCount = MeshArray[i].material.count			
							MaterialCount = UsedMatIDArray.count
						)
						else if(classof MeshArray[i].material)==Standardmaterial then
						(
							MaterialCount = 1
						)
					)
					else
					(
							MaterialCount = 1
					)
					if (MaterialCount == 1) then
					(
						tempFaceArray = #()
						TempUVFaceArray =#()
						TempUV2FaceArray=#()
						for fa = 1 to num_faces do
						(
							FaceIndex = getFace MeshArray[i] fa								
							append tempFaceArray FaceIndex
							if (num_uvs > 0) then
							(
								UVFaceIndex =  getTVFace Mesharray[i] fa
								append TempUVFaceArray UVFaceIndex
								if UV2Flag == true then
								(
									UV2FaceIndex = meshop.getMapFace Mesharray[i] 2 fa										
									append TempUV2FaceArray UV2FaceIndex
								)
							)
						)
						append MatID_array 1
						matIds += 1
						append  Face_array tempFaceArray
						if (num_uvs > 0) then
						(
							append  UVFace_array TempUVFaceArray
							append  UV2Face_array TempUV2FaceArray
						)
					)							
					else if (MaterialCount > 1) And (MaterialCount <= numMatIDs) then
					--else if (MaterialCount > 1) then
					(
						for mi = 1 to numMatIDs do								
						--for mi = 1 to MaterialCount do
						(
							tempFaceArray = #()
							TempUVFaceArray =#()
							TempUV2FaceArray=#()									
							for fa = 1 to num_faces do
							(
								FaceMatID = getFaceMatID MeshArray[i] fa
								if FaceMatID == mi then
								(
									FaceIndex = getFace MeshArray[i] fa								
									append tempFaceArray FaceIndex
									if (num_uvs > 0) then
									(
										UVFaceIndex =  getTVFace Mesharray[i] fa
										
										append TempUVFaceArray UVFaceIndex
										if UV2Flag == true then
										(
											UV2FaceIndex = meshop.getMapFace Mesharray[i] 2 fa
											append TempUV2FaceArray UV2FaceIndex
										)
									)
								)
							)
							if tempFaceArray.count > 0 then
							(
								
								--append MatID_array mi --2015-9-8这里面有问题，未剔除未使用的材质，因为mi还是可能实际材质总数小于材质总数。所以还有多余的未使用材质未剔除。所以未采用此方案，会产生冗余材质。														
								matIds += 1	
								append MatID_array MatIDS
								
								append  Face_array tempFaceArray
								if (num_uvs > 0) then
								(
									append  UVFace_array TempUVFaceArray
									if UV2Flag == true then
									(
										append  UV2Face_array TempUV2FaceArray
									)
								)	
								/*
								if debugmode == true then format"ORI MATEARIL ID：%\n" mi to:outdebug
								for m = 1 to tempFaceArray.count do
								(				
									if debugmode == true then format"%\n"  tempFaceArray[m] to:outdebug							
								)*/								
							)								
						)	
					)
					else
					(
						messagebox Mesharray[i].name+" Model material count less than model number of MatIDs . can't export!\nThe game requires must be same count!\n Please try merge face MatID or add material!" title:"Export error"
					)

					max select none							
					--********************结束获取面数据代码
					if debugmode == true then format"获取面数据完成！\n" to:outdebug
					
					--导出时，所见即所得，导入时，顶点坐标直接做好变换工作,蒙皮数据导出env则不受影响。
					--以下获取模型UV,UV2,Vert,Normal,Color
					
					tmesh = copy MeshArray[i]
					tmesh.transform *= inverse meshArray[i].parent.transform

					for v = 1 to num_verts do
					(
						append vert_array (getVert tmesh v)
						append normal_array (getnormal tmesh v)								
						if num_colors > 0 then append Color_array (getVertColor tmesh v)
					)							
					--此方法以模型面Face_Array为基准，补充新顶点，而不是以模型UV面UVFace_array为基准
					oldFace_Array = deepCopy Face_array
					for c = 1 to face_array.count do
					(
						for x  = 1 to face_array[c].count do
						(
							Face = face_array[c][x]--获取模型的面索引
							if num_uvs > 0 then
							(
								UVFace = UVFace_array[c][x]--获取模型的UV面索引
								if UV2Flag == true then
								(
									UV2Face = UV2Face_Array[c][x]--获取模型的UV2面索引
								)
							)
							for j = 1 to 3 do--遍历面的3个顶点ID
							(										
								if num_uvs > 0 then --如果含有UV
								(
									--此时，UV面中的ID和模型面中的ID是对应的
									
									uv = gettvert tmesh UVFace[j]--获取当前UV面ID的UV
									if UV_Array[ Face[j] ]== undefined then--如果UV面中序列为模型面ID的数值等于未定义,这个用来创建UV_Array，因为当前是空的
									(
										UV_Array[ Face[j] ] = uv	--那么赋予UV面中的序列为模型面ID的数值为 当前UV面ID的UV
									)
									else --如果UV面中序列为模型面ID的数值不等于未定义
									(
										if UV_Array[ Face[j] ] != uv then--判断是否不相等，不相等就要添加新的顶点和UV作为新的顶点ID
										(													
											append Vert_Array (getvert tmesh Face[j])
											append Normal_Array (getnormal tmesh Face[j])
											if num_colors > 0 then Append Color_Array (getVertColor tmesh Face[j])
											if skinFlag == 1 then append oldSkin_Array  oldSkin_Array[ Face[j] ]
											newNumVerts = Vert_array.count
											Face_array[c][x][j] = newNumVerts--赋予模型面ID等于新顶点数组的总数为ID
											UV_Array[newNumVerts] = uv --UV面中序列为新顶点总数的ID数值为当前UV
										)
									)											
								)
								
								
							)
						)
					)
					NewFace_Array = deepcopy Face_Array
					for c = 1 to face_array.count do
					(
						for x  = 1 to face_array[c].count do
						(
							Face = Face_array[c][x]--获取模型的面索引
							oldFace = OldFace_array[c][x]
							if num_uvs > 0 then
							(
								UVFace = UVFace_array[c][x]--获取模型的UV面索引
								if UV2Flag == true then
								(
									UV2Face = UV2Face_Array[c][x]--获取模型的UV2面索引
								)
							)
							
							for j = 1 to 3 do--遍历面的3个顶点ID
							(										
								if num_uvs > 0 then --如果含有UV
								(
									--此时，UV面中的ID和模型面中的ID是对应的
									uv = gettvert tmesh UVFace[j]
									if UV2Flag == true then
									(
										UV2 = meshop.getMapVert tmesh 2 UV2Face[j]
										if UV2_Array[ Face[j] ] == undefined then
										(
											UV2_Array[ Face[j] ] = UV2
										)
										else
										(
											if UV2_Array[ Face[j] ] != UV2 then
											(
												append Vert_Array (getvert tmesh oldFace[j])
												append Normal_Array (getnormal tmesh oldFace[j])
												if num_colors > 0 then Append Color_Array (getVertColor tmesh  oldFace[j])
												if skinFlag == 1 then append oldSkin_Array  oldSkin_Array[ oldFace[j] ]
												newNumVerts = Vert_array.count
												
												NewFace_array[c][x][j] = newNumVerts--赋予模型面ID等于新顶点数组的总数为ID
												UV_Array[newNumVerts] = UV
												UV2_Array[newNumVerts] = UV2	--UV2面中序列为新顶点总数的ID数值为当前UV2												
											)
										)
									)
									
									
								)
								
								
							)
						)
					)
					newNumFace = 0;
					for c = 1 to newFace_array.count do
					(
						newNumFace+=newFace_array[c].count
					)
					
					
					
					
					
					
					Skin_Array = deepcopy oldSkin_Array
					--Padding unused vertex data
					for v = 1 to Vert_Array.count do
					(
						if UV_Array[v] == undefined then
						(
							UV_Array[v] = [0,0,0]
							if UV2Flag == true then UV2_Array[v] = [0,0,0]
						)
					)
					boundRadius= 0.5*(distance tmesh.min tmesh.max)
					boundCenter= 0.5*(tmesh.min+tmesh.max)
					boundMin= tmesh.min
					boundMax= tmesh.max

					delete tmesh

					--计算法线
					if (recalNormal == true) then(
						originalFaceArray = #()
						for c = 1 to newFace_array.count do
						(
							for s = 1 to newFace_array[c].count do (
								append originalFaceArray newFace_array[c][s]
							)
							
						)					
						uniqueVertFaceArr = uniqueVertFaceArray vert_array originalFaceArray
						newNormalStruct = calculateNormal uniqueVertFaceArr.weldVertArray uniqueVertFaceArr.weldFaceArray vert_array
						Normal_Array = newNormalStruct.normals

					)
					--结束计算法线

					if debugmode == true then format"获取模型数据完成！\n" to:outdebug
					
					
					MaterialOffset = Ftell f
					--id = finditem usedmatidarray matid 和usedmatidarray对应的写入文件的材质ID顺序。以便用来写后面的面的MatID做准备。
					if(MeshArray[i].material != undefined) then
					(
						
						if (classof MeshArray[i].material)== Multimaterial then
						(
							TextureNameIndexOffset=#()
							TextureNameOffset = #()
							for mm = 1 to MaterialCount do
							(
								m = UsedMatIDArray[mm]--获取模型使用的材质ID，没有使用的材质自动抛弃。
								--m = mm
								append TextureNameIndexOffset (ftell f)
								append OFSArr (ftell f)--texture name offset
								writelong f 0 
								writebyte f 0 --bLoaded
								writebyte f MeshArray[i].material[m].diffuse.r #unsigned
								writebyte f MeshArray[i].material[m].diffuse.g #unsigned
								writebyte f MeshArray[i].material[m].diffuse.b #unsigned
								writebyte f MeshArray[i].material[m].diffuse.a #unsigned
								writebyte f 0 --padding
								writebyte f 0
								writebyte f 0
							)
							for mm = 1 to MaterialCount do
							(
								append TextureNameOffset (ftell f)
								m = UsedMatIDArray[mm]--获取模型使用的材质ID，没有使用的材质自动抛弃。
								--m =mm
								if (classof MeshArray[i].material[m].diffusemap == Bitmaptexture) AND (MeshArray[i].material[m].diffuseMapEnable == true) then
								(
									textureName = getFilenameFile MeshArray[i].material[m].diffusemap.filename
									writestring f textureName
								)
								else
								(
									writestring f "NULL"
								)
							)
							for m = 1 to MaterialCount do
							(
								fseek f TextureNameIndexOffset[m] #seek_set
								writelong f TextureNameOffset[m] #unsigned
							)
						)
						else if(classof MeshArray[i].material)==Standardmaterial then
						(
								append OFSArr (ftell f)--texture name offset
								writelong f ((ftell f)+12) #unsigned
								writebyte f 0 --bLoaded
								writebyte f MeshArray[i].material.diffuse.r #unsigned
								writebyte f MeshArray[i].material.diffuse.g #unsigned
								writebyte f MeshArray[i].material.diffuse.b #unsigned
								writebyte f MeshArray[i].material.diffuse.a #unsigned
								writebyte f 0 --padding
								writebyte f 0
								writebyte f 0
								if (classof MeshArray[i].material.diffusemap == Bitmaptexture) AND (MeshArray[i].material.diffuseMapEnable == true)then
								(
									textureName = getFilenameFile MeshArray[i].material.diffusemap.filename
									writestring f textureName
								)										
								else
								(
									writestring f "NULL"
								)
								
						)
						else
						(
							Messagebox("Export materials error! Only support Multimaterial and Standardmaterial ! ")
							EXIT
						)

					)-- end if have material
					else
					(
						append OFSArr (ftell f)--texture name offset
						writelong f ((ftell f)+12) #unsigned
						writebyte f 0
						writebyte f 0x96
						writebyte f 0x96
						writebyte f 0x96
						writebyte f 255 #unsigned
						writebyte f 0
						writebyte f 0
						writebyte f 0
						writestring f  "NULL"
					)--end not have matrial
					
					--以下写模型区块头
					--****************
					fseek f 0 #seek_end
					padlen = 16-(mod (ftell f) 16)
					if padLen>0 and padlen < 16 then 
					(
						for i = 1 to padLen do writebyte f 0
					)

					
					ObjectMatrixFlag = getuserprop MeshArray[i].parent "ObjectMatrix"
					if ObjectMatrixFlag == 1 then
					(
						--inverseMat = (inverse ((angleaxis -90 [0,1,0])as matrix3))
						ObjectBoneMatrixOffset = Ftell f
						writelong f bonearray[1].count #unsigned
						append OFSArr (ftell f) -- object matrix data offset
						writelong f (objectBonematrixOffset+16) #unsigned
						writelong f 0; writelong f 0;--padding
						for b = 1 to bonearray[1].count do
						(
							---****重要
							boneMatrix =inverse ( bonearray[1][b].transform * (inverse MeshArray[i].parent.transform))
							writefloat f BoneMatrix.row1.x
							writefloat f BoneMatrix.row1.y
							writefloat f BoneMatrix.row1.z
							writefloat f 0
							writefloat f BoneMatrix.row2.x
							writefloat f BoneMatrix.row2.y
							writefloat f BoneMatrix.row2.z
							writefloat f 0
							writefloat f BoneMatrix.row3.x
							writefloat f BoneMatrix.row3.y
							writefloat f BoneMatrix.row3.z
							writefloat f 0
							writefloat f BoneMatrix.row4.x
							writefloat f BoneMatrix.row4.y
							writefloat f BoneMatrix.row4.z
							writefloat f 1.0
						)
					)--end have object matrix
					if debugmode == true then format"写ObjectMatrix完成！\n" to:outdebug
					ObjectOffset = Ftell f
					append objectoffsetarray objectoffset
					append OFSArr (ftell f)--material offset
					writelong f materialoffset #unsigned
					if(MeshArray[i].material != undefined) then
					(
						if (classof MeshArray[i].material)== Multimaterial then
						(
							writelong f MaterialCount #unsigned
							--writelong f MeshArray[i].material.count #unsigned -- for full materials version include unused
							
						)
						else if(classof MeshArray[i].material)==Standardmaterial then
						(
							writelong f 1
						)
					)
					else
					(
							writelong f 1
					)
					if ObjectMatrixFlag == 1 then
					(
						append OFSArr (ftell f)--object bone matrix offset
						writelong f ObjectBoneMatrixOffset #unsigned
					)
					else
					(
						writelong f 0
					)
					writefloat f  0
					writelong f 1
					--writefloat f mesharray[i].pos.x;writefloat f mesharray[i].pos.y;writefloat f mesharray[i].pos.z;
					writefloat f 0;writefloat f 0;writefloat f 0;
					MeshChunkStart = Ftell f
					writelong f 0x45d454 #unsigned --chunk flag
					writelong f 0 ---chunk size
					writelong f 0 --zero
					--****************结束写模型区块头
					writelong f MaterialCount #unsigned
					--writelong f (num_faces*3) #unsigned
					writelong f (newNumFace*3) #unsigned
					writefloat f (MeshArray[i].center.x);writefloat f (MeshArray[i].center.y);writefloat f (MeshArray[i].center.z);
					boundingsum = MeshArray[i].max - MeshArray[i].center
					boudingxyz = #(boundingsum.x,boundingsum.y,boundingsum.z)
					bbmax = 0
					for bb = 1 to 3 do
					(
						if boudingxyz[bb] > bbmax then bbmax = boudingxyz[bb]
					)
					writefloat f bbmax
					--writefloat f (boundCenter.x);writefloat f (boundCenter.y);writefloat f (boundCenter.z);
					--writefloat f boundRadius
					writefloat f (MeshArray[i].scale.x);writefloat f (MeshArray[i].scale.y);writefloat f (MeshArray[i].scale.z);
					--writelong f num_verts #unsigned
					writelong f vert_array.count #unsigned
					writelong f 0 ;writelong f 0 ;writelong f 0 ;---3 zeros
					VertexElementSize = 0
					VertexElementType = 0
					if num_uvs > 0 then
					(
						VertexElementSize = 0x20
						VertexElementType = 0x152
						if num_maps > 2 then
						(
							VertexElementSize = 0x28
							VertexElementType = 0x252
						)
					)
					else
					(
						VertexElementSize = 0x18
						VertexElementType = 0x52
					)
					if skinFlag == 1 then
					(
						VertexElementSize = 0x34
						VertexElementType = 0x115E
						if (num_maps >2) AND (outUV2 == true) then
						(
							VertexElementSize = 0x3C
							VertexElementType = 0x125E
						)
					)
					if (skinFlag == 1 ) AND (num_uvs< 0) then
					(
						messagebox("SkinMesh not have UV, don't support this type of export, after giving UV, retry!")
						EXIT
					)
					writelong f VertexElementSize #unsigned
					writelong f 0x65
					writelong f 7
					writelong f 0
					writelong f 1
					writelong f 0
					writelong f 0x7C9106AB
					writelong f 0x64
					writelong f 6
					writelong f 0
					writelong f 1
					writelong f 0
					writelong f VertexElementType #unsigned
					writelong f 0x14050e4
					writelong f 0x1408624
					writelong f 0
					writelong f 0
					writelong f 0x12f594
					writelong f 0x330000
					writelong f 0x7c91732
					writelong f 5
					

					--下面写面索引ID数据
					--******************
					startFaceID = 0
					for n = 1 to MaterialCount do
					(
						tempmsh = mesh vertices:Vert_array faces:Face_array[n]
						meshop.deleteIsoVerts  tempmsh
						writefloat f tempmsh.min.x
						writefloat f tempmsh.min.y
						writefloat f tempmsh.min.z
						writefloat f tempmsh.max.x
						writefloat f tempmsh.max.y
						writefloat f tempmsh.max.z
						delete tempmsh
						--writeshort f (face_array[n].count*3) #unsigned--have face
						writeshort f (NewFace_array[n].count*3) #unsigned--have face
						writeshort f (MatID_array[n]-1) #unsigned--mat id 
						writeshort f startFaceID #unsigned
						--startFaceID += (face_array[n].count*3)
						startFaceID += (Newface_array[n].count*3)
						writeshort f 0x7C91 #unsigned
						writelong f 0;writelong f 0;writelong f 0;----3zeros
					)
					
					--write face index
					curFaceIndex = 0
					for n = 1 to MaterialCount do
					(
						--if debugmode == true then format"MOD MATEARIL ID：%\n" MatID_array[n] to:outdebug
						for m = 1 to NewFace_array[n].count do
						(
							writeshort f (Newface_array[n][m].x-1) #unsigned
							writeshort f (Newface_array[n][m].y-1) #unsigned
							writeshort f (Newface_array[n][m].z-1) #unsigned
							if debugmode == true then format"faceIndex:% matid:% triangle:%\n" (curFaceIndex+m) MatID_array[n] Newface_array[n][m] to:outdebug							
						)
						curFaceIndex += NewFace_array[n].count
					)
											
					--******************结束写面索引ID数据
					if Vert_array.count < 65536 then
					(
						for v = 1 to Vert_Array.count do
						(
							Vert = Vert_Array[v]
							--Vert = Vert_Array[v] * inverse meshArray[i].parent.transform
							writefloat f Vert.x
							writefloat f Vert.y
							writefloat f Vert.z
							
							if skinFlag == 1 then(
								w = Skin_Array[v]
								count = w.boneids.count
								padding = 4-count
								if padding > 0 then
								(
									for p = 1 to padding do
									(
										writelong f 0
									)
								)
								for b = 1 to count do
								(
									writefloat f w.weights[b]
								)
								if padding > 0 then
								(
									for p = 1 to padding do
									(
										writebyte f 0
									)
								)
								for b = 1 to count do
								(
									writebyte f w.boneids[b] #unsigned
								)
							)
							
							writeshort f (Normal_Array[v].x*32768.0)
							writeshort f (Normal_Array[v].y*32768.0)
							writeshort f (Normal_Array[v].z*32768.0)
							--normal = normalize (Normal_Array[v] * inverse meshArray[i].parent.transform)
							
							--writeshort f (normal.x*32768.0)
							--writeshort f (normal.y*32768.0)
							--writeshort f (normal.z*32768.0)
							writeshort f 0
							
							if (num_colors > 0) AND (outVertexColor == true)then(
								writebyte  f color_array[v].b #unsigned
								writebyte  f color_array[v].g #unsigned
								writebyte  f color_array[v].r #unsigned
								writebyte  f color_array[v].a #unsigned
							)
							else
							(
								writebyte f 0;writebyte f 0;writebyte f 0;writebyte f 255;
							)
							if num_uvs > 0 then
							(
								uv = UV_array[v]
								--if uv == "no" then uv = [0,0,0]
								writefloat f UV.x
								writefloat f (1-UV.y)
								if (UV2Flag == true) AND (outUV2 == true) then
								(
									UV2 = UV2_Array[v]
									writefloat f UV2.x
									writefloat f (1-UV2.y)
								)
							)				
						)--end write boneid weight verts normal color uv1 uv2 data
					)
					else
					(
						messagebox "Can't export, out of vertex count max range : 65535 !" title:"Export error"
					)
					MeshChunkEnd = Ftell f
					MeshChunkSize = MeshChunkEnd - MeshChunkStart
					padlen = 16-(mod (ftell f) 16)
					if padLen>0 and padlen < 16 then 
					(
						for i = 1 to padLen do writebyte f 0
					)
					fseek f (MeshChunkStart+4) #seek_set
					writelong f MeshChunkSize #unsigned
					fseek f 0 #seek_end
					if debugmode == true then close outdebug
				)--end for i = 1 to mesharray.count
				fseek f 0x54 #seek_set
				writelong f objectIndexOffset[1] #unsigned
				writelong f objectIndexOffset[objectIndexOffset.count] #unsigned
				for o = 1 to objectOffsetArray.count do
				(
					fseek f objectIndexOffset[o] #seek_set
					if objectOffsetArray.count > 1 then
					(
						if ( o == objectOffsetArray.count ) then--如果是最后一个
						(
							writelong f 0x54 #unsigned
						)
						else--如果没有达到最后一个
						(
							writelong f objectIndexOffset[o+1] #unsigned
						)
					)
					else --如果等于1
					(
						writelong f 0x54 #unsigned
					)
					if (o == 1) then-- write prev object info offset
					(
						writelong f 0x54 #unsigned
					)
					else--如果不等于 1 则如实写上级
					(
						writelong f objectIndexOffset[o-1] #unsigned
					)
					fseek f 4 #seek_cur
					writelong f objectOffsetArray[o] #unsigned
				)

			)--if have mesh object
			fseek f 0 #seek_end
			TableOffset = Ftell f
			for o = 1 to OFSArr.count do
			(
				writelong f OFSArr[o] #unsigned
			)
			FileSize = ftell f
			fseek f 8 #seek_set
			writelong f FileSize #unsigned
			writelong f TableOffset #unsigned
			writelong f TableOffset #unsigned
			writelong f OFSArr.count #unsigned
			fclose f
			if (compressFlag == true) then 
			(
				exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe"
				DOSCommandName = "-back z2hm "+"\""+outfname+"\""
				ShellLaunch exename DOSCommandName
			)
		)--end $!=undefined
		else
		(
			messagebox "Can't export,Please select root bone export!" title:"Export error"
		)

	)--end if outfname!= undefined	
)