gc()
fileIn "MDLimp.ms"
fileIn "MDLexp.ms"
global EntryArray
global EntryIndexArray
global fname
global MeshArray
global MeshParentArray
global type = ""
global MeshSkinArray
global ObjectParentBoneOffset
global autoskin = false
global imagetypeArray = #(".dds",".png",".tga",".bmp")
global imagetype
global AutoShowTextures
global VertexColorOn
global KeyOffset
Global Dummysize = 0.1
global optimizeModel
global smoothNormal

rollout MH2Rollout "Manhunt 2 MDL/DFF Importer" width:220 --height:550
(	
	button btn1 "Select MDL/DFF" --pos:[33,18] width:123 height:23
	--checkbox onlyDFF "OnlySelectDFF" align:#Center
	radioButtons rdo1 "Image Type:" tooltip:"Textures format" labels:#("dds", "png","tga","bmp")  align:#left columns:4 default:2
	
	listBox lbx1 "Objects:" --pos:[10,49] width:168 height:12
	label lab1 "Count:"align:#left--pos:[10,230] width:85 height:19
	button btn4 "Imp All"  across:2 --align:#left
	button btn3 "Imp Selected"  tooltip:"Double-Click also can import" --align:#right
	checkbox AutoSkinCheck "Auto Skin" align:#left  tooltip:"Auto Skin after import mdl model" checked:true
	checkBox auto_show_texture "Auto Show Textures" align:#left checked:true
	checkbox vertexcolor_on "Vertex Color" align:#left checked:true
	checkbox optimizeCheck "Optimize" align:#left checked:true  tooltip:"Remove duplicate vertices with the same attributes and unify elements (welding vertex)."
	checkbox smoothNormalCheck "Smooth Normals"  checked:false  tooltip:"Recalculate normals, Smooth Normal."
	/*
	on  onlyDFF changed theState do
	(
		if theState  == true then rdo1.state = 4
	)*/
	
	on lbx1 doubleClicked sel do--双击选中项目
	(
		if MH2Rollout.lbx1.selection > 0 then(
			if ( fname != undefined) then(
				
				MeshParentArray = #()
				MeshArray = #()
				BoneArray=#(#(),#(),#(),#())
				MeshSkinArray = #(#(),#())
				
				imagetype = imagetypeArray[rdo1.state]
				f = fopen fname "rb"
				fseek f EntryIndexArray[lbx1.selection] #seek_set
				NextEntryIndexOffset = readUInt f
				PrevEntryIndexOffset = readUInt f
				EntryOffset = readUInt f
				fseek f EntryOffset #seek_set
				RootBoneOffset = readUInt f
				
				curoffset = ftell f
				fseek f RootBoneOffset #seek_set
				fseek f 24 #seek_cur
				RootBoneName = readstring f
				if RootBoneName == "" then(
					fseek f (RootboneOffset+16) #seek_set
					RootBoneOffset = readUInt f
				)		
				ReadBone f RootBoneOffset BoneArray--读取骨骼
				--format "RootBoneOffset:0x%\n" (bit.intAsHex RootBoneOffset)
				fseek f curoffset #seek_set
				fseek f 16 #seek_cur
				objectInfoIndexOffset = ftell f
				FirstObjectInfoOffset = readUInt f
				lastObjectInfoOffset = readUInt f
								
				if (autoskincheck.checked == true) then autoskin = true else autoskin = false				
				if (auto_show_texture.checked == true) then AutoShowTextures = true else AutoShowTextures = false
				if (VertexColor_On.checked == true) then VertexColorOn = true else VertexColorOn = false
				if (optimizeCheck.checked == true) then optimizeModel = true else optimizeModel = false
				if (smoothNormalCheck.checked == true) then smoothNormal = true else smoothNormal = false			
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
						append MeshParentArray ObjectParentBoneOffset
						if(NextObjectInfoOffset==objectInfoIndexOffset)then loop = false else fseek f  NextObjectInfoOffset #seek_set
					)while loop
				)
				else
				(
					messageBox "This Entry is not have Object，just a dummy!"
				)
				
				fclose f
				

			)--end if ( fname != undefined) then(
		)--end if MH2Rollout.lbx1.selection > 0 then
	)
	on btn3 pressed  do --导入选中项目
	(
		MH2Rollout.lbx1.doubleClicked MH2Rollout.lbx1.selection
	)
	on btn1 pressed  do --选择文件
	(		
			/*
			if (onlyDFF.checked == true) then
			(
				fname = getOpenFileName \ 
				caption:"Manhunt 2 Model File" \
				types:"Manhunt 2 PS2/PSP/WII Model File(*.DFF)|*.DFF" 
			)
			else
			(
				fname = getOpenFileName \ 
				caption:"Manhunt 2 Model File" \
				types:"Manhunt 2 PC Model File(*.mdl);Manhunt 2 PS2/PSP/WII Model File(*.dff)|*.mdl;*.dff" 
			)
			*/
			fname = getOpenFileName \ 
			caption:"Manhunt 2 Model File" \
			types:"Manhunt 2 PC Model File(*.mdl);Manhunt 2 PS2/PSP/WII Model File(*.dff)|*.mdl;*.dff" 
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
				f = fopen fname "rb"
				if f != undefined then
				(
					MDLFlag = readlong f
					if MDLFlag == 0x504d4c43 or MDLFlag == 0x434C4D50 then(
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
						EntryArray =#()
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
							append EntryArray (RootBoneName)						
							if(NextEntryIndexOffset==0x20)then( loop = false) else (fseek f NextEntryIndexOffset #seek_set)						
						)while loop
						lbx1.items = EntryArray
						lab1.caption= "Count:"+EntryArray.count as string
						lbx1.selection = 1
						if EntryArray.count == 1 then MH2Rollout.lbx1.doubleClicked MH2Rollout.lbx1.selection
					)
					else(Messagebox("Sorry! Don't support this file!"))
					fclose f
				)-- end if f != undefined
			)
			--clearlistener()
	)

	on btn4 pressed  do--导入全部项目
	(
		if ( fname != undefined) then(			
			f = fopen fname "rb"			
			MeshArray = #()		
			emptyEntry = "Import All Done!\n"			
			imagetype = imagetypeArray[rdo1.state]
			for i = 1 to EntryIndexArray.count do(
				BoneArray=#(#(),#(),#(),#())
				MeshSkinArray = #(#(),#())
				MeshParentArray = #()
				fseek f EntryIndexArray[i] #seek_set
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

				if (autoskincheck.checked == true) then autoskin = true else autoskin = false				
				if (auto_show_texture.checked == true) then AutoShowTextures = true else AutoShowTextures = false
				if (VertexColor_On.checked == true) then VertexColorOn = true else VertexColorOn = false
				if (optimizeCheck.checked == true) then optimizeModel = true else optimizeModel = false
				if (smoothNormalCheck.checked == true) then smoothNormal = true else smoothNormal = false	

				if (FirstObjectInfoOffset != objectInfoIndexOffset) then(
					loop = true
					fseek f FirstObjectInfoOffset #seek_set
					Do
					(
						NextObjectInfoOffset = readUInt f
						PrevObjectInfoOffset = readUInt f
						ObjectParentBoneOffset = readUInt f
						ObjectOffset = readUInt f
						if Platform != "WII" then(
							ReadModel f ObjectOffset BoneArray fname imagetype autoskin AutoShowTextures VertexColorOn optimizeModel smoothNormal
						)else(							
							wiiHaveMeshFlag = 0
							fseek f (ObjectOffset+0x6C) #seek_set
							wiiMeshChunkOffset = readUInt f
							fseek f (wiiMeshChunkOffset+0xC) #seek_set
							wiiHaveMeshFlag = readUInt f
							if (wiiHaveMeshFlag == 1) then (
								ReadModel f ObjectOffset BoneArray fname imagetype autoskin AutoShowTextures VertexColorOn optimizeModel smoothNormal
							)	
						)
						append MeshParentArray ObjectParentBoneOffset
						if(NextObjectInfoOffset==objectInfoIndexOffset)then (loop = false) else (fseek f  NextObjectInfoOffset #seek_set)
					)while loop
				)
				else
				(
					emptyEntry += i as string
					emptyEntry += "."
					emptyEntry += EntryArray[i]
					emptyEntry += " is Empty Entry,not have Object!\n"					
				)
					
			)
			
			messagebox emptyEntry
			fclose f
		)
	)

)


fn CollectionBone bne BNArray =
(
	append  BNArray bne
	subArraytemp = bne.children
	subArray=#()
	if subarraytemp.count > 0 then
	(
		for i = 1 to subarraytemp.count do(
			if ((classof subarraytemp[i])==BoneGeometry or (classof subarraytemp[i])== Dummy) then
			(
				append subarray subarraytemp[i]
			)
		)
	)
	if subarray.count > 0 then
	(
		for b = 1 to subarray.count do
		(
			CollectionBone subArray[b] BNArray
		)
	)
)
fn find_dummy obj = (classof obj)==BoneGeometry or (classof obj)== Dummy
fn find_root obj = ((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneIndex" == 0)
fn SelectRoot =
(
	Root =selectByName title:"Please Select Root Bone" buttonText:"OK" showHidden:true single:true filter:find_dummy 
	return Root
)
fn SelectRootBone =
(
	Root =selectByName title:"Please Select Root Bone" buttonText:"OK" showHidden:true single:true filter:find_root 
	return Root
)
fn mutilSelectRootBone =
(
	Root =selectByName title:"Please Select Root Bone" buttonText:"OK" showHidden:true single:false filter:find_root 
	return Root
)
fn WriteBoneProp d f BonePropArray=
(
	--writestring f d.name
	--writestring f (getUserPropBuffer d)
	format "[Start]\r\nBoneName =[%]\r\n"d.name to:f
	format "%" (getUserPropBuffer d) to:f
	format "[END]\r\n" to:f 
	--writestring f (getUserPropBuffer d)
	append BonePropArray d.name
	local children = d.children
	if children.count > 0 then
	(
		for c in children do
		(
			if (classof c)==BoneGeometry or (classof c)== Dummy then WriteBoneProp c f BonePropArray
		)
	)
)

rollout MH2OutRollout "Manhunt 2 MDL Exporter" --width:190 height:550
(
	button exportbtn "Export" align:#center  width:80 height:35 across:2
	button batchExportBtn "Batch Export" width:80 height:35 
	button okselectroot "Select Root Bone" width:120  height:25

    --label padlabl "\n"
	on exportbtn pressed do
	(
		if ($!=undefined) then
		(

			outfname = getSaveFileName \ 
				caption:"Manhunt 2 PC Model File" \
				types:"Manhunt 2 PC Model File(*.mdl)|*.mdl" 
			--outfname = "E:\Program Files (x86)\Manhunt2\global\danny_ingame-dasy_pc.mdl"
			outVertexColor=MH2OutRollout.exportVC.checked
			compressFlag=MH2OutRollout.compflag.checked 
			outUV2=MH2OutRollout.exportUV2.checked
			recalNormal=MH2OutRollout.recalNormal.checked
			outRootBone = $
			WriteMDLFile f outRootBone outfname compressFlag outVertexColor outUV2 recalNormal
		)--end if ($!=undefined)
		else
		(
			messagebox "Can't export! Didn't choose anything! Please select root bone export!" title:"Export error"
		)
	)--end exportbtn pressed

	on batchExportBtn pressed do(
		outVertexColor=MH2OutRollout.exportVC.checked
		compressFlag=MH2OutRollout.compflag.checked 
		outUV2 = MH2OutRollout.exportUV2.checked
		recalNormal = MH2OutRollout.recalNormal.checked
		Root = mutilSelectRootBone()
		if root != undefined then
		(	
			select root
			rootBoneArray=getCurrentSelection()
			inputPath = getSavePath caption:"Please Selcet Export Folder"
			if (inputPath!=undefined)then(
				for i = 1 to rootBoneArray.count do(
					outfName = inputPath + "\\"+rootBoneArray[i].name +".mdl"
					outRootBone = rootBoneArray[i]		
					WriteMDLFile f outRootBone outfname compressFlag outVertexColor outUV2 recalNormal
				)
			)
		)
	)
	on okselectroot pressed do
	(
		Root = SelectRootBone()
		if root != undefined then select root
	)	
	--put it here no rollout error
	group "Export Options"
	(
		checkbox compflag "Compress" align:#left  tooltip:"Export and Comporess Data (Z2HM Resources)" 
		checkbox recalNormal "Recalculate / Smooth Normals" align:#left checked:false -- tooltip:"Smooth normals." 
		checkbox exportVC "Vertex Color" align:#left checked:true
		checkbox exportUV2 "2nd UV Map" align:#left checked:true tooltip:"Only for the have UV2's model valid."		
	)

	group "Custom Bone Properties"
	(
		button  resortbtn "Reorder BoneID"
		button  expBonepropbtn "Export Bone User-Prop"
		button  impBonepropbtn "Import Bone User-Prop"
	)
		on resortbtn pressed do
		(
			BNArray = #()
			Root = SelectRoot()
			if root != undefined then
			(
				CollectionBone root BNArray
				for i =  1 to BNArray.count do
				(
					setUserProp BNArray[i] "BoneIndex" (i-1)
				)
				messagebox "Reorder BoneID Done!"
			)
		)
		on expBonepropbtn pressed do
		(
			BoneProp=#()
			outfname = getSaveFileName caption:"Export BoneProp a txt File:" \
			filename:"BoneProp.txt"\
			types:" BoneUserProperties text(*.txt)|*.txt" \
			if(outfname!=undefined)then
			(
				f = createfile outfname
				format "Number Bones=    \r\n" to:f
				root = SelectRoot()
				if root != undefined then
				(
					WriteBoneProp root f BoneProp
					seek f 0
					format "Number Bones=%" BoneProp.count to:f
					close f
					messagebox "Export Done!"
				)
			)
		)
		on impBonepropbtn pressed do
		(
			inputfname = getOpenFileName caption:"Import BoneProp from txt File:" \
			filename:"BoneProp.txt"\
			types:"BoneUserProperties text(*.txt)|*.txt" \
			if(inputfname!=undefined)then
			(			
				f = openfile inputfname
				numBones = ((filterString (readLine f)  "=, ")[3]) as float
				for i = 1 to numBones do
				(
					readline f
					bonename = (filterString (readline f) "[,]")[2]
					propstr = ""
					do
					(
						tempstr = readline f
						if tempstr != "[END]" then
						(
							propstr +=tempstr
							propstr +="\r\n"							
						)
					)while tempstr != "[END]"
					
					for b in (getnodebyname bonename all:true) do
					(
						setUserPropBuffer b propstr
					)
					--print bonename
					--print propstr
				)
				CLOSE f
				messagebox "Import Done!"
			)
		)		
	
)-- end MH2OutRollout
rollout MH2TXDTEXRollout "Manhunt 2 TEX TXD Extract"
(
	Group "single" (button btn1 "PC" across:4;button btn2 "PS2";button btn3 "PSP";button btn4 "WII";)
	Group "batch" (button btn5 "PC" across:4;button btn6 "PS2";button btn7 "PSP";button btn8 "WII";)
	on btn1 pressed do(inputfname = getOpenFileName caption:"Please Selcet Manhunt 2 .tex Textures File" types:"Manhunt 2 Textures File(*.tex)|*.tex" ; if inputfname != undefined then (exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-pctex -s "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))	
	on btn2 pressed do(inputfname = getOpenFileName caption:"Please Selcet Manhunt 2 .txd Textures File" types:"Manhunt 2 Textures File(*.txd)|*.txd" ; if inputfname != undefined then (exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-ps2txd -s "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))	
	on btn3 pressed do(inputfname = getOpenFileName caption:"Please Selcet Manhunt 2 .txd Textures File" types:"Manhunt 2 Textures File(*.txd)|*.txd" ; if inputfname != undefined then (exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-psptxd -s "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))	
	on btn4 pressed do(inputfname = getOpenFileName caption:"Please Selcet Manhunt 2 .txd Textures File" types:"Manhunt 2 Textures File(*.txd)|*.txd" ; if inputfname != undefined then (exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-wiitxd -s "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))	
	on btn5 pressed do(inputfname = getSavePath caption:"Please Selcet .tex Textures Folder";if inputfname != undefined then(exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-pctex -all "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))
	on btn6 pressed do(inputfname = getSavePath caption:"Please Selcet .txd Textures Folder";if inputfname != undefined then(exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-ps2txd -all "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))
	on btn7 pressed do(inputfname = getSavePath caption:"Please Selcet .txd Textures Folder";if inputfname != undefined then(exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-psptxd -all "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))
	on btn8 pressed do(inputfname = getSavePath caption:"Please Selcet .txd Textures Folder";if inputfname != undefined then(exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-wiitxd -all "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))
)


rollout MH2TEXRollout "Manhunt 2 .TEX (DDS) Unpacker" --width:190 height:550
(
	button btn6 "single" across:2 ;button btn7 "batch";
	on btn6 pressed do(inputfname = getOpenFileName caption:"Please Selcet Manhunt 2 .tex Textures File" types:"Manhunt 2 Textures File(*.tex)|*.tex" ;if inputfname != undefined then(exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-t -s "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))
	on btn7 pressed do(inputfname = getSavePath caption:"Please Selcet .tex Textures Folder";if inputfname != undefined then(exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-t -all "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;)		)
)
rollout aboutRoll "About"
( 
	label lbl6 "Manhunt 2  MDL  IO"align:#center	
	label lbl12 "\n"align:#center	
	label lbl13 "Support:"align:#left	
	label lbl14 "Import PC MDL,PSP/PS2/WII DFF"align:#left
	label lbl15 "Export PC MDL"align:#left
	label lbl16 "Unpack PC TEX texture"align:#left		
	label lbl23 "Z2HM Resources Manager"align:#left			
	label lbl21 "\n"align:#center		
	label lbl20 "Features:"align:#left	
	label lbl17 "-Bones/Skin" align:#left
	label lbl19 "-Welding vertices Smooth model" align:#left	
	label lbl18 "-2nd UV Map IO" align:#left

	
	label lbl22 "\n"align:#center	
	label lbl9 "Revision Version Sep 12, 2021 "align:#left
	label lbl7 "First Version Sep2013"align:#left
	label lbl10 "by Allen      "align:#right
	label lbl8 "leeao@live.com"align:#right
)
rollout MH2ZRollout "Z2HM / MH2Z Resources Manager" 
(

	group "Decompress" (button btn10 "single" across:2 button btn11 "batch";)
	on btn10 pressed do(inputfname = getOpenFileName caption:"Please Selcet Manhunt 2 PC PS2 PSP Z2HM WII MH2Z Resources File" types:"Manhunt 2 Z2HM/MH2Z File(*.*)|*.*" ;if inputfname != undefined then(exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-z -s "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))
	on btn11 pressed do(inputfname = getSavePath caption:"Please Selcet Manhunt 2 PC PS2 PSP Z2HM WII MH2Z Resources Folder";if inputfname != undefined then(exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-z -all "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))
	
	group "Compress as" (button btn12 "Z2HM"  tooltip:"PC PSP PS2" across:2;button btn13 "MH2Z" tooltip:"WII";)
	on btn12 pressed do(inputfname = getOpenFileName caption:"Please Selcet Manhunt 2 PC PS2 PSP Z2HM Resources File" types:"Manhunt 2 Z2HM/MH2Z File(*.*)|*.*" ;if inputfname != undefined then(exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-back z2hm "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))
	on btn13 pressed do(inputfname = getOpenFileName caption:"Please Selcet Manhunt 2 WII Z2HM Resources File" types:"Manhunt 2 Z2HM/MH2Z File(*.*)|*.*" ;if inputfname != undefined then(exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe";DOSCommandName = "-back mh2z "+"\""+inputfname+"\"";ShellLaunch exename DOSCommandName;))		
		
	label labl40 "Z2HM : PC PS2 PSP Platform" align:#left
	label labl41 "MH2Z : WII Platform" align:#left
	label labl42 "Decompress support Z2HM, MH2Z"align:#left
	label lbal43 "Compress only support single file"align:#left
)
function convertDummyToBone d =
(
	if (classof d)==Dummy then
	(
		tfm = d.transform
		b = bonesys.createbone	\
		  tfm.row4	\
		  (tfm.row4 + 0.01 * (normalize tfm.row1)) \
		  (normalize tfm.row3)
		b.name = d.name
		b.width  = 0.03
		b.height = 0.03
		b.transform = tfm
		b.setBoneEnable false 0
		b.wirecolor = yellow
		b.showlinks = true
		b.pos.controller      = TCB_position ()
		b.rotation.controller = TCB_rotation ()			  
		setUserPropBuffer b (getuserpropbuffer d)
		if d.parent != undefined then b.parent = d.parent
		local children = d.children
		b.showlinks = true
		if children.count > 0 then
		(
		for c in children do
		(
			c.parent = b
			convertDummyToBone c 
		)
		)
		delete d
		return b
	)
)
function convertBoneToDummy B =
(
	if (classof B)==BoneGeometry then
	(
		local D = dummy boxsize:[.1,.1,.1] 
		D.transform = B.transform
		D.name = B.name
		setUserPropBuffer D (getuserpropbuffer B)
		if B.parent != undefined then D.parent = B.parent

		local children = B.children
		if children.count > 0 then
		(
		for c in children do
		(
			c.parent = D
			convertBoneToDummy c 
		)
		)
		delete B
		return D
	)
)

rollout DummyHelper "Dummies/Bones Helper"
(
	button selectBones "Select All Dummies"
	spinner dmyboxsize "Dummy Box Size: " range:[0.00000001,100000,dummysize]
	button dmyasBox "Box" width:40 tooltip:"Show Bones as box" align:#left across:3
	button dmynLink "Link" width:40 tooltip:"Show Dummies as box with Links" align:#center	
	button dmyasBone "Bone" width:40 tooltip:"Show Dummies as bone" align:#right
    on selectbones pressed do
	(
		BNArray=#()
		Root = SelectRootBone()
		if root != undefined then(
			CollectionBone root BNArray
			select BNArray
		)
	)
	on dmyboxsize changed val do (
		for dmy in $selection where (classof dmy)== Dummy do (
			dmy.boxsize = [val,val,val]
		)
	)

	on dmyasBox pressed do (
		root = selectrootbone()
		if root != undefined then
		(
			convertBoneToDummy root
		)
		forceCompleteRedraw()
	)
	on dmynLink pressed do (
		BNArray=#()
		root = selectrootbone()
		if root != undefined then
		(
			CollectionBone root BNArray
			for dmy in BNArray where (classof dmy)==BoneGeometry or (classof dmy)== Dummy do (
				dmy.showLinksOnly = false
				dmy.showLinks = true
			)
		)
		forceCompleteRedraw()
	)
	
	on dmyasBone pressed do (
		root = selectrootbone()
		if root != undefined then
		(
			convertDummyToBone root
		)
		forceCompleteRedraw()
	)
)
rollout ShowVertexColorRollout "Show Vertex Color"
(
	group "Show vertex color" (
		button showNightVertColor "Night" tooltip:"Show Night Vertex Color" across:3
		button showDayVertColor "Day" tooltip:"Show Day Vertex Color"
		button offVertColor "OFF" tooltip:"Off Vertex Color"
		)
		on showNightVertColor pressed do
		(
			for o in objects where (superclassof o  == GeometryClass ) do (
			o.showVertexColors = true
			o.vertexColorType = #illum
			)
			completeRedraw()
		)
		on showDayVertColor pressed do
		(
			for o in objects where (superclassof o  == GeometryClass ) do (
			o.showVertexColors = true
			o.vertexColorType = #color
			)
			completeRedraw()
		)
		on offVertColor pressed do
		(
			for o in objects where (superclassof o  == GeometryClass ) do (
			o.showVertexColors = false
			)
			completeRedraw()
		)
)

fn find_HeadBone obj = ((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneID" == 1001) -- head 1001 neck 1040
rollout HuntHelper "Hunt Helper"
(
	button linkHeadBone "Link Hunt Head to Bone"
	button unlinkHeadBone "Unlink Hunt head to Bone"
	
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
)
if Allen_Tool != undefined then 
(
	closeRolloutFloater Allen_Tool 
	gc() 
)
Allen_Tool = newRolloutFloater "MH2 Scripts" 250 1000 10 50
addRollout MH2Rollout Allen_Tool rolledup:false
addRollout MH2OutRollout Allen_Tool rolledup:false
addRollout MH2TXDTEXRollout Allen_Tool rolledup:false
addRollout HuntHelper Allen_Tool rolledup:false
addRollout ShowVertexColorRollout Allen_Tool rolledup:true
addRollout MH2ZRollout Allen_Tool rolledup:true
addRollout MH2TEXRollout Allen_Tool rolledup:true
addRollout DummyHelper Allen_Tool rolledup:true
addRollout aboutRoll Allen_Tool  rolledup:true 