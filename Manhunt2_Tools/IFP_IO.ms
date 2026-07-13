gc()
try (fileIn "DFFimp.ms" quiet:true)
catch messagebox "You didn't have the right import function to run this script!\nTry Install it again!" title:"Import Function Error"
try (fileIn "MDLimp.ms" quiet:true)
catch messagebox "You didn't have the right import function to run this script!\nTry Install it again!" title:"Import Function Error"
global IFPEntryArray
global IFPEntryIndexArray
global IFPFname
global BoneArray
struct ANPKStruct(
	anpkName,anpkOffset
)
struct BoneTag(
	BoneID,boneNode
)
fn ReadFixedStr bstream fixedLen =(
   local str = ""
   for i = 1 to fixedLen do(
      str += bit.intAsChar (ReadByte bstream #unsigned)
   )
   str
)
fn applyANPKAnim f boneArray keepAnim keepRange mh1tomh2 =(
	numBones = readlong f
	chunkSize = readlong f
	times = readfloat f
	testSize = 0
	FrameStarttime = animationRange.end - 1
	if (keepAnim!=true)then(
		try(
		if (BoneArray.boneNode.count > 0)then(		
			for i = 1 to bonearray.boneNode.count do (
				sliderTime = 0f			
				deletekeys bonearray.boneNode[i].pos.controller
				deletekeys bonearray.boneNode[i].rotation.controller
				deletekeys bonearray.boneNode[i].scale.controller													
				tp 		= readvalue ((getUserProp bonearray.boneNode[i]  "OrgRot") as stringstream)
				tpW		= getUserProp bonearray.boneNode[i]  "OrgRotW"
				bonearray.boneNode[i].rotation = (quat tp.x tp.y tp.z tpW)
				bonearray.boneNode[i].scale	= readvalue ((getUserProp bonearray.boneNode[i]  "Orgscl") as stringstream)
				bonearray.boneNode[i].pos	= readvalue ((getUserProp bonearray.boneNode[i]  "OrgPos") as stringstream)				
			)--end for i = 1 to bonearray.count
		)
		)catch()	
	)
	if (keepAnim==true)then(
		sliderTime = animationRange.end
		animationRange = interval 0 (animationRange.end+(times*30.0+1))
	)
	else if (keepRange==true)then(
		if  (times*30.0) > animationRange.end then (animationRange = interval 0 (times*30.0))
	)
	else(
		animationRange = interval 0 (times*30.0)
		sliderTime = 0f
	)
	for b = 1 to numBones do(
		ANPKType = readfixedstr f 4
		BoneID = readshort f #unsigned
		frameType = readbyte f
		frames = readshort f #unsigned		
		frameTime = 0.0		
		startTime = (readshort f #unsigned)/2048.0*30.0
		if (keepAnim == true) then(
			frameTime = FrameStarttime + 1
		)
		InitialDirection = undefined	
		if frameType > 2 then(
			rx = (readshort f)/4096.0
			ry = (readshort f)/4096.0
			rz = (readshort f)/4096.0
			rw = (readshort f)/4096.0
			InitialDirection = quat rx ry rz rw
		)
		else if startTime == 0 then fseek f -2 #seek_cur
		ArrayID = findItem boneArray.BoneID BoneID
		if ArrayID > 0 then(
			bne = boneArray.boneNode[ArrayID]
		)
		firstFrame = undefined	
		for i = 1 to frames do(
			bR = undefined
			bT = undefined
			if startTime == 0 then
			(
				if (FrameType == 3) and (i==1)then(
					curtime = 0.0
				)
				else(
					curtime = ((readshort f #unsigned)/2048.0*30.0)
				)				
				frameTime += curtime
			)
			else(
				if startTime < 1 then startTime = 1
				if (keepAnim == true) then
				(
					if (frames==1) and (startTime==(times*30))then frameTime=(i-1)+startTime+FrameStarttime+1 else frameTime=(i-1)+startTime+FrameStarttime
				)else
				(
					if (frames==1) and (startTime==(times*30))then frameTime = (i-1)+startTime else frameTime = (i-1)+startTime-1					
				)
			)
			if (frameType < 3) then(
				
				rx = (readshort f)/4096.0
				ry = (readshort f)/4096.0
				rz = (readshort f)/4096.0
				rw = (readshort f)/4096.0					
				bR = quat rx ry rz rw
			)		
			if (frameType > 1) then(
				tx = (readshort f)/2048.0
				ty = (readshort f)/2048.0
				tz = (readshort f)/2048.0
				bT= [tx,ty,tz]
			)	
			if (bne != undefined) then(
				if i==1 then(
					firstFrame = frameTime
				)
				--In MH1 Bip01_Spine parent Bone is Bip01_Pelvis. Bip01_Pelvis ID = 1045.  Bip01_Spine ID =1094.
				--In MH1 left and right Clavicle parent Bone is Neck. Bip01_Neck ID = 1040. Bip01_L_Clavicle ID = 1003. Bip01_R_Clavicle ID = 1057.
				--In MH1 left and right Thigh parent bone is Bip01 Spine ID =1094. Bip01_L_Thigh BoneID = 1023 and Bip01_R_Thigh BoneID = 1077
				
				
				--In MH2 Bip01_Spine parent Bone is Bip01 BoneID = 1000
				--In MH2 left and right Clavicle parent bone is Bip01_Spine2 BoneID = 1096.
				--In MH2 left and right Thigh parent bone is Bip01_Pelvis BoneID = 1045.
				/*
				skeleton differences
				MH1 to MH2:
					Bip01_Spine
					Quat XYZW
					--MH1 (quat 0.500398 0.500001 -0.4996 0.500001)

					Bip01_L_Clavicle
					Position XYZ
					--MH1 [0.170165,-2.68221e-07,0.0150331]
					--MH2 [0.152684,0,0.00713982]
				
					Bip01_R_Clavicle
					Position XYZ
					--MH1 [0.170165,-2.75671e-07,0.0150331]	
					--MH2 [0.152684,0,0.00713982]
					
				MH2 to MH1:
					Bip01_Spine
					Quat XYZW
					--MH1 (quat -0.500398 -0.500001 0.4996 0.500001)

					Bip01_L_Clavicle
					Position XYZ
					--MH1 [-0.170165,2.68221e-07,-0.0150331]
					--MH2 [-0.152684,0,-0.00713972] 
					
					Bip01_R_Clavicle
					Position XYZ
					--MH1 [-0.170165,2.75671e-07,-0.0150331]	
					--MH2 [-0.152684,0,-0.00713972] 
				*/			
				if (mh1tomh2 == true) then(
					if (frameType < 3) then(
						--Bip01_Spine
						if (ANPKType == "SEQU")and (boneID==1094) then(
							
							--Old code MH1 to MH2
							--ArrayID = findItem boneArray.BoneID 1045
							--if ArrayID > 0 then(
							--	pelvisBone = boneArray.boneNode[ArrayID]
							--)				
							--br = ((br as Matrix3) * pelvisBone.transform * (inverse bne.parent.transform)) as quat
							
							
							br *= (quat 0.500398 0.500001 -0.4996 0.500001) --MH1 and MH2 Same
							
						)else if (ANPKType == "SEQT")and (boneID==1094) then (
							br *= (quat -0.500398 -0.500001 0.4996 0.500001)
						)
						 
						/*
						if (ANPKType == "SEQU")and(boneID==1003) then(
							ArrayID = findItem boneArray.BoneID 1040
							if ArrayID > 0 then(
								neckBone = boneArray.boneNode[ArrayID]
							)				
							--br = ((br as Matrix3) * neckBone.transform * (inverse bne.parent.transform)) as quat
							--br *= (quat -0.162435 -0.0191579 2.68221e-07 0.986533) --MH2
							--br *= (quat -0.299544 -0.0913465 -2.08616e-07 0.949699) --MH1
						)
						if (ANPKType == "SEQU")and (boneID==1057)then(
							ArrayID = findItem boneArray.BoneID 1040
							if ArrayID > 0 then(
								neckBone = boneArray.boneNode[ArrayID]
							)				
							--br = ((br as Matrix3) * neckBone.transform * (inverse bne.parent.transform)) as quat
							--br *= (quat 0.162434 -0.0191588 3.57628e-07 0.986533) --MH2
							--br *= (quat 0.299545 -0.0913468 0 0.949699) --MH1
						)	
						*/
					)
					if (frameType > 1) then (
						/*
						if (ANPKType == "SEQU")and(boneID==1094)then(
							ArrayID = findItem boneArray.BoneID 1045
							if ArrayID > 0 then(
								neckBone = boneArray.boneNode[ArrayID]
							)				
							--bT = (bT * neckBone.transform) * (inverse bne.parent.transform)
							--bT += [-0.119838,0.10787,-8.78217e-05] --MH2
							bt += [-0.135939,0.122361,-9.9102e-05] --MH1
							
						)	
						*/	
						--Bip01_L_Clavicle
						if (ANPKType == "SEQU")and(boneID==1003)then(
							
							--ArrayID = findItem boneArray.BoneID 1040
							--if ArrayID > 0 then(
							--	neckBone = boneArray.boneNode[ArrayID]
							--)				
							--bT = (bT * neckBone.transform) * (inverse bne.parent.transform)
							
							
							bT += [0.152683,0,0.00714159] --MH2
							--bt += [0.170165,-2.68221e-07,0.0150331] --MH1
							
						)else if (ANPKType == "SEQT")and(boneID==1003) then (
							bt += [-0.170165,2.68221e-07,-0.0150331]  --MH1
							--bT += [-0.152684,0,-0.00713982] --MH2
						)
						--Bip01_R_Clavicle
						if (ANPKType == "SEQU")and(boneID==1057)then(
							
							--ArrayID = findItem boneArray.BoneID 1040
							--if ArrayID > 0 then(
							--	neckBone = boneArray.boneNode[ArrayID]
							--)				
							--bT = (bT * neckBone.transform) * (inverse bne.parent.transform)
							
							bT += [0.152683,0,0.00714162] --MH2
							--bT += [0.170165,-2.75671e-07,0.0150331] --MH1
							
						) else if (ANPKType == "SEQT")and(boneID==1057) then (							
							bT += [-0.170165,2.75671e-07,-0.0150331] --MH1
							--bT += [-0.152684,0,-0.00713982] --MH2
						)
							
					)
				)--end "mh1 to mh2" or "mh2 to mh1"
				animate on
				at time (frameTime)(
					if (frameType < 3) then(
						in coordsys parent
						(
							bne.rotation.controller.value =  bR
						)											
					)
					if (frameType > 1) then (
						in coordsys parent(
							bne.position.controller.value = bT
							if (i==1)and (frameType > 2)then(
								bne.rotation.controller.value = InitialDirection
							)
						)
						
					)					
				)
			)--end  (bne != undefined) then(
		)--end for i = 1 to frames 
		
		if (bne != undefined) then(
			--If timeStart != 0, a key will also automatically be created at frame 0. so we need delete it.
			if (keepAnim != true) then(
				if firstFrame != 0 then(
					if (frameType > 1) then deleteKey bne.controller.Position.controller.keys 1
					if (frameType < 3) then deleteKey bne.controller.rotation.controller.keys 1
				)
			)									
		)--end  (bne != undefined)
		--format"结束FrameTime:%\n" frameTime
		if ANPKType == "SEQT" then times = readfloat f
	)
	readlong f
	pecTime = readfloat f
	perEntrySize = readlong f
	numEntry = readlong f #unsigned
	pecSize = perEntrySize * numEntry
	fseek f pecSize #seek_cur
)
fn raedANPKIndex f =(
	anpk_magic = readlong f
	numANPK = readlong f
	ANPK = anpkStruct anpkName:#() anpkOffset:#()
	for j = 1 to numANPK do(
		NAME_magic = readlong f
		AnimNameLen = readlong f
		AnimName = readfixedstr f AnimNameLen
		append ANPK.anpkOffset (ftell f)							
		append ANPK.anpkName ((formattedPrint j format:("0"+((numanpk as string).count as String)+"u"))+" "+animname)
		numBones = readlong f
		chunkSize = readlong f
		times = readfloat f
		ANPKType = readfixedstr f 4
		fseek f -4 #seek_cur
		if(ANPKType=="SEQT")then (fseek f (chunksize+numbones*13) #seek_cur)
		else if (ANPKType=="SEQU") then(fseek f (chunksize+numbones*9) #seek_cur)
		readlong f
		pecTime = readfloat f
		perEntrySize = readlong f
		numEntry = readlong f #unsigned
		pecSize = perEntrySize * numEntry
		fseek f pecSize #seek_cur							
	)
	return ANPK
)
fn readBlockIndex f=(
	IFPEntryArray =#()
	IFPEntryIndexArray=#()
	numBlock = readlong f
	for i = 1 to numBlock do(
		BLOC = readlong f
		bNameLen = readlong f
		blockName = readfixedstr f bNameLen
		append IFPEntryArray blockName
		ANPK = raedANPKIndex f
		append IFPEntryIndexArray ANPK
	)
	fclose f
)
fn readStrmAnimBinIndex f =(
	IFPEntryArray =#()
	IFPEntryIndexArray=#()
	numExec = readlong f #unsigned
	numEnvExec = readlong f #unsigned	
	for i = 1 to numExec do(
		
		ANPK = anpkStruct anpkName:#() anpkOffset:#()
		tempAnpk = #()
		ExecutionID = readlong f #unsigned
		append IFPEntryArray ("Execution"+(formattedPrint i format:("0"+((numExec as string).count as String)+"u"))+" ID:"+ExecutionID as string)
		JumpExectuionOffset = readlong f #unsigned
		JumpExectuionSize = readlong f #unsigned
		WhileLevelExecOffset = readlong f #unsigned
		WhileLevelExecSize = readlong f #unsigned
		YellowLevelExecOffset = readlong f #unsigned
		YellowLevelExecSize = readlong f #unsigned
		RedLevelExecOffset = readlong f #unsigned
		RedLevelExecSize = readlong f #unsigned
		nextoffset = ftell f
		if (JumpExectuionOffset>0)then(
			fseek f JumpExectuionOffset #seek_set
			append tempAnpk (raedANPKIndex f)
		)
		if (WhileLevelExecOffset>0)then(
			fseek f WhileLevelExecOffset #seek_set
			append tempAnpk (raedANPKIndex f)
		)
		if (YellowLevelExecOffset>0)then(
			fseek f YellowLevelExecOffset #seek_set
			append tempAnpk (raedANPKIndex f)
		)
		if (RedLevelExecOffset>0)then(
			fseek f RedLevelExecOffset #seek_set
			append tempAnpk (raedANPKIndex f)
		)
		for j = 1 to tempanpk.count do(
			for jj = 1 to tempanpk[j].AnpkName.count do(
				append ANPK.anpkName tempanpk[j].AnpkName[jj]
				append ANPK.anpkOffset tempanpk[j].AnpkOffset[jj]
			)
		)
		fseek f nextoffset #seek_set
		--print anpk
		append IFPEntryIndexArray ANPK
	)
	for i = 1 to numEnvExec do(
		ANPK = anpkStruct anpkName:#() anpkOffset:#()
		ExecutionID = readlong f #unsigned
		EnvExecOffset = readlong f #unsigned
		EnvExecSize = readlong f #unsigned
		nextoffset = ftell f
		append IFPEntryArray ("Environmental Exec"+(formattedPrint i format:("0"+((numEnvExec as string).count as String)+"u"))+" ID:"+ExecutionID as string)
		if (EnvExecOffset>0)then(
			fseek f EnvExecOffset #seek_set
			ANPK= raedANPKIndex f
		)
		append IFPEntryIndexArray ANPK
		fseek f nextoffset #seek_set
	)
	
	fclose f
	
)
fn CollectionBone bne BNArray =(
	append  BNArray bne
	subArraytemp = bne.children
	subArray=#()
	if subarraytemp.count > 0 then(
		for i = 1 to subarraytemp.count do(
			if ((classof subarraytemp[i])==BoneGeometry or (classof subarraytemp[i])== Dummy) then(
				append subarray subarraytemp[i]
			)
		)
	)
	if subarray.count > 0 then(
		for b = 1 to subarray.count do(
			CollectionBone subArray[b] BNArray
		)
	)
)
fn find_root obj = ((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneIndex" == 0)
fn SelectRootBone =(
	Root =selectByName title:"Please Select Root Bone" buttonText:"OK" showHidden:true single:true filter:find_root 
	return Root
)
rollout AllenMH2IFPimp "Manhunt 1/2 IFP Importer"(
	group "Import" (
	button loaddff "DFF" across:3 tooltip:"Manhunt1 DFF Model" --align:#left
	button loadmdl "MDL"  tooltip:"Manhunt2 MDL/DFF Model" align:#center
	dropdownlist imgtype "" items:#(".png",".dds",".tga",".bmp") width:60  align:#right
	)--end group "Import"
	--group "Animation" 
	button btn1 "Load IFP BIN files" --across:2 --width:100  align:#left
	button btn2 "Convert Json to Anim" --across:2 --width:100  align:#left
	button btn5 "Load Anim files" --across:2 --width:100  align:#left
	checkbox playMultiAnim "Play multiple animations" tooltip:"Play multiple animations at the same time.Keep max animation range, times base on 0. Specify multiple skeletons for multiple animation,For example: Watching 2 execution animation at the same time, you need to import 2 different skeletons." 
	checkbox specifyskeleton "Specify a skeleton" tooltip:"Play single animation,if fxist multiple skeletons, you can specify a skeleton.If not checked, the default auto selects 1 skeleton."
	checkbox KeepAnimation "Keep animation"  tooltip:"Keep the previous animation" 
	checkbox mh1tomh2 "MH1 <--> MH2 Convert" tooltip:"Use MH2 skeleton play MH1 animation or Use MH1 skeleton play MH2 animation"
	dropdownlist AnimBlock "Anim Block:" items:#() 
	listBox lbx1 "List:" height:10 
	
	--dotNetControl lv "System.Windows.Forms.ListView" width:220 height:220 align:#center 
	button btn3 "Apply Animation"   across:2
	button btn4 "Reset Pose"
	--label hit3 "Double-click play Click copy name"
	--label hint "Click copy Anim name to clipboard" 
	--label hint2 "Double-Click apply Anim"
	----end group "Animation"
	
	on loaddff pressed do (
		fname = getopenfilename caption:"Read Manhunt1 DFF File" types:"dff File (*.dff)|*.dff|"
		if fname != undefined then (
			entryInfo = ReadClumpList fname
			texExt = imgtype.items[imgtype.selection]
			if (entryInfo.ClumpNames.count==1)then(
				ReadSingleClumpIFPUI fname 0 texExt
			)else(
				createDFFImportWindow fname
			)				
		)
	)--end on loaddff
	on loadmdl pressed do (
		fname = getOpenFileName caption:"**Manhunt 2 Model File *.mdl *.dff" types:"Manhunt 2 PC Model File(*.mdl);Manhunt 2 PS2/PSP/WII Model File(*.dff)|*.mdl;*.dff" 
		if ( fname != undefined) then(
			entryInfo = readEntry fname
			if (entryInfo.entryNames.count==1)then(
				entryIndexOffset = entryInfo.entryOffsets[1]
				imagetype = imgtype.items[imgtype.selection]
				importMDL MDLfname entryIndexOffset imagetype true true true true false
			)
			else if (entryInfo.entryNames.count>1) then(
				createMDLImportWindow fname
			)
		)--end if ( fname != undefined) then(
	)
	on AnimBlock selected i do(
		if IFPEntryArray.count > 0 then(
			lbx1.items = IFPEntryIndexArray[i].anpkName
		)
	)


	on btn1 pressed  do( --选择文件		
		--IFPFname = undefined

		Fname = getOpenFileName caption:"Manhunt 1/2 IFP File MH2 Strmanim_pc.bin File" types:"Manhunt 1/2 IFP File(*.ifp);MH2 Strmanim_pc.bin File(*.bin)|*.ifp;*.bin" 
		bool = false 
		if fname != undefined then(
			IFPfname = fname
			f2 = fopen Fname "rb"
			Idstring = readlong f2
			DecompressSize = readlong f
			fclose f2
			--if Idstring == "Z2HM" then
			if Idstring == 0x4D48325A or Idstring == 0x5A32484D then(
				
				exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe"
				DOSCommandName = "-z -s "+"\""+IFPFname+"\""
				ShellLaunch exename DOSCommandName					
				decompressFileName = (getFilenamePath IFPFname) +"\\"+(getFilenameFile  IFPFname)+ "_decompress"+(getFilenameType IFPFname)
				IFPFname = decompressFileName					
				do(
					sleep 1 -- must be wait 1 second  , because maxscript execute very fast, if not wait fname will == undefined,this time mh2tools not done decomporess work!
					bool = doesFileExist IFPFname
					fileSize = getFileSize IFPFname
				)while (bool != true)AND(fileSize != DecompressSize)
				
			)
			else(
				bool = true
			)
			
		)
		if ( IFPFname != undefined) AND bool == true then(
			f = fopen IFPFname "rb"
			if f != undefined then(
				idstring = readlong f
				if(idstring != 0x54434e41)AND(idstring != 1)then(
					fclose f
					Messagebox("Sorry! Don't support this file!")					
				)
				--IFP.BLOC
				else if (idstring == 0x54434e41) then(
					readblockIndex f
					lbx1.items = IFPEntryIndexArray[1].anpkName
					AnimBlock.items = IFPEntryArray
					AnimBlock.selection = 1
					lbx1.selection = 1
					
				)
				--strmanim_pc.bin
				else if (idstring == 1)then(
					readStrmAnimBinIndex f
					lbx1.items = IFPEntryIndexArray[1].anpkName
					AnimBlock.items = IFPEntryArray
					AnimBlock.selection = 1
					lbx1.selection = 1
				)
			)-- end if f != undefined
		)
		--clearlistener()
	)
	
	on lbx1 selected sel do( --单击文件
		if lbx1.selection > 0  then(			
			local str =filterString lbx1.items[sel] " "
			setclipboardText str[2]
		)
	)
	on lbx1 doubleClicked sel do (
		boneArray= boneTag BoneID:#() boneNode:#()
		rootArray = #()
		for obj in objects where (((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneIndex" == 0)) do(
			append rootArray obj
		)
		if (rootArray.count ==1 )then(
			for obj in objects where (((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneID" != undefined)) do(
				append bonearray.BoneID  (getuserprop obj "BoneID")
				append boneArray.boneNode obj
			)
		)else if (rootArray.count > 1 ) AND (playMultiAnim.checked == true  or  specifyskeleton.checked == true ) then(
			BNArray=#()
			Root =selectByName title:"Exist multiple skeletons,Please Select 1 Root Bone" buttonText:"OK" showHidden:true single:true filter:find_root 
			if root != undefined then(
				CollectionBone root BNArray
				--select BNArray[1]
				for obj in BNArray where (((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneID" != undefined)) do(
					append bonearray.BoneID  (getuserprop obj "BoneID")
					append boneArray.boneNode obj
				)			
			)
		)else if (rootArray.count > 1 ) then(
			BNArray=#()
			Root = rootArray[1]
			if root != undefined then(
				CollectionBone root BNArray
				--select BNArray[1]
				for obj in BNArray where (((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneID" != undefined)) do(
					append bonearray.BoneID  (getuserprop obj "BoneID")
					append boneArray.boneNode obj
				)			
			)
		)
		startTime = 0
		if (keepAnimation.checked==true)then(
		startTime = animationRange.end +1
		animationRange = interval 0 (animationRange.end+1)
		)
		if(boneArray.bonenode.count > 0) then(
			if ( IFPFname != undefined) then(
				f = fopen IFPFname "rb"
				fseek f IFPEntryIndexArray[AnimBlock.selection].anpkOffset[sel] #seek_set
				applyANPKAnim f boneArray keepAnimation.checked playMultiAnim.checked mh1tomh2.checked
				fclose f
				
			)
		)		
		else(
			messagebox("Please import bones!")
		)
		
	)
	on btn2 pressed do
	(
		maxVer = MaxVersion()
		if (maxVer[1] >= 19000) then
		(
			--if max version is Max 2017 and higher
			Python.ExecuteFile (scriptsPath+"\\Manhunt2_tools\\IFP_json_read.py")
			
		)
		else(
			messagebox("Current 3ds Max Version can't support python pymxs! \nPlease Use 3ds Max 2017 and Higher version!")
		)

		
	)
	on btn5 pressed do
	(
		animFileName = getopenfilename caption:"Anim File" types:"JsonFile (*.anim)|*.anim|"
		boneArray= boneTag BoneID:#() boneNode:#()
		rootArray = #()
		for obj in objects where (((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneIndex" == 0)) do(
			append rootArray obj
		)
		if (rootArray.count ==1 )then(
			for obj in objects where (((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneID" != undefined)) do(
				append bonearray.BoneID  (getuserprop obj "BoneID")
				append boneArray.boneNode obj
			)
		)else if (rootArray.count > 1 ) AND (playMultiAnim.checked == true  or  specifyskeleton.checked == true ) then(
			BNArray=#()
			Root =selectByName title:"Exist multiple skeletons,Please Select 1 Root Bone" buttonText:"OK" showHidden:true single:true filter:find_root 
			if root != undefined then(
				CollectionBone root BNArray
				--select BNArray[1]
				for obj in BNArray where (((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneID" != undefined)) do(
					append bonearray.BoneID  (getuserprop obj "BoneID")
					append boneArray.boneNode obj
				)			
			)
		)else if (rootArray.count > 1 ) then(
			BNArray=#()
			Root = rootArray[1]
			if root != undefined then(
				CollectionBone root BNArray
				--select BNArray[1]
				for obj in BNArray where (((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneID" != undefined)) do(
					append bonearray.BoneID  (getuserprop obj "BoneID")
					append boneArray.boneNode obj
				)			
			)
		)
		startTime = 0
		if (keepAnimation.checked==true)then(
		startTime = animationRange.end +1
		animationRange = interval 0 (animationRange.end+1)
		)
		if(boneArray.bonenode.count > 0) then(
			if ( animFileName != undefined) then(
				f = fopen animFileName "rb"				
				applyANPKAnim f boneArray keepAnimation.checked playMultiAnim.checked mh1tomh2.checked
				fclose f
				
			)
		)		
		else(
			messagebox("Please import bones!")
		)
	)
	on btn3 pressed  do( --导入选中项目
	if lbx1.selection > 0 then lbx1.doubleClicked lbx1.selection
	)
	on btn4 pressed do(
		try(
		if (BoneArray.boneNode.count > 0)then(		
			for i = 1 to bonearray.boneNode.count do (
				sliderTime = 0f			
				deletekeys bonearray.boneNode[i].pos.controller
				deletekeys bonearray.boneNode[i].rotation.controller
				deletekeys bonearray.boneNode[i].scale.controller													
				tp 		= readvalue ((getUserProp bonearray.boneNode[i]  "OrgRot") as stringstream)
				tpW		= getUserProp bonearray.boneNode[i]  "OrgRotW"
				bonearray.boneNode[i].rotation = (quat tp.x tp.y tp.z tpW)
				bonearray.boneNode[i].scale	= readvalue ((getUserProp bonearray.boneNode[i]  "Orgscl") as stringstream)
				bonearray.boneNode[i].pos	= readvalue ((getUserProp bonearray.boneNode[i]  "OrgPos") as stringstream)				
			)--end for i = 1 to bonearray.count
		)
		)catch()
	)

)
fn exportANIMfile f ver boneArray =(
	boneCountPointer = ftell f
	boneCount = 0
	writelong f boneCount
	chunkSizePointer = Ftell f
	chunkSize = 0
	writelong f chunkSize
	FrameCountPointer = Ftell f
	maxTimesCount = 0.0f
	writefloat f maxTimesCount
	for b = 1 to boneArray.boneNode.count do(
		bne = boneArray.boneNode[b]
		for t in bne.controller.Position.controller.keys do(
			if t.time.frame > maxTimesCount then maxTimesCount = t.time.frame
		)
		for t in bne.controller.rotation.controller.keys do(
			if t.time.frame > maxTimesCount then maxTimesCount = t.time.frame
		)
	)		
	for b = 1 to boneArray.boneNode.count do(
		bne = boneArray.boneNode[b]
		boneID = BoneArray.BoneID[b]
		posFrameArray = #()
		rotFrameArray = #()
		quatPosFrameArray = #()
		frameType = undefined
		continuous = undefined
		startTime = 0
		lastFrameTime = 0
		--posFrameArray = bne.controller.Position.controller.keys
		for t in bne.controller.Position.controller.keys do(
			append posFrameArray t.time.frame
		)
		--format"%\n" bne.name
		--format"posKeysCount:%\n" posFrameArray.count
		--rotFrameArray = bne.controller.rotation.controller.keys
		for t in bne.controller.rotation.controller.keys do(
			append rotFrameArray t.time.frame
		)
		--format"rotKeysCount:%\n" rotFrameArray.count

		--if frametype==2 if pos.timescount!= rot.timescount then merge anim
		--below function get frameType and continunos flag (start time == 0 or start time > 0 )
		--in ifp anpk format, start time > 0 express the anim frame data is continuous.
		--if start time == 0 express the anim frame data is non-continunos. Some frame, the time interval between the upper and lower frame exceeds 1 frame.
		--if continunos == false then start time must be == 0.
		--if real frame start index != 0 then copy  frame start index rot and pos value to frame index 0
		--Start write FrameType 1 quat rotation--
		if (rotFrameArray.count > 0) and (posFrameArray.count == 0)then(
			frameType=1
			if rotFrameArray.count > 1 then(
				for i = 1 to (rotFrameArray.count-1) do(
					if ((rotFrameArray[i+1]-rotFrameArray[i])==1)then(
						continuous = true
						startTime = (rotFrameArray[1]+1)/30*2048
					)
					else(
						continuous = false
						startTime = 0
						exit
					)
				)
			)
			else(
				continuous = true
				if rotFrameArray[1] < maxTimesCount then startTime = (rotFrameArray[1]+1)/30*2048 else startTime = rotFrameArray[1]/30*2048 
			)
			if ver == 1 then(writelong f 0x55514553)			--SEQU
			else if ver == 2 then (writelong f 0x54514553) 	--SEQT
			writeshort f boneID			--BoneID
			writebyte f frameType		--FrameType 1=quat 2=quat,translate 3=translate
			writeshort f rotFrameArray.count	--frames count
			startOffset = FTell f					
			if continuous == true then(
				writeshort f startTime	--Start Time
			)
			for i = 1 to rotFrameArray.count do(
				--write time
				if continuous == false then(				
					--if continunos == false then start time must be == 0.
					--if real frame start index != 0 then copy  frame start index rot and pos value to frame index 0
					if(i==1)then(
						if rotFrameArray[1] != 0 then(
							fseek f -2 #seek_cur
							writeshort f (rotFrameArray.count+1)
							writeshort f 0	--Start Time
							at time rotFrameArray[1](
								if bne.parent != undefined then(	
									rot =((bne.transform * (inverse bne.parent.transform)) as quat)								
								)
								else rot = (bne.transform as quat)
							)
							writeshort f (rot.x*4096);writeshort f (rot.y*4096);writeshort f (rot.z*4096);writeshort f (rot.w*4096)
						)--end if rotFrameArray[1] != 0
					)
					--if frame start index not at 0，then need modify 2nd time(index 1 of array).
					--write time
					if i==1 then (
						if rotFrameArray[1] != 0 then(writeshort f (rotFrameArray[i]/30*2048))else(writeshort f 0)								
					)else(writeshort f ((rotFrameArray[i]-rotFrameArray[i-1])/30*2048))
					if i==rotFrameArray.count then lastFrameTime = ((rotFrameArray[i]-rotFrameArray[i-1])/30.0)
				)--end if continuous == false
				--write quat rotation
				at time rotFrameArray[i](
					if bne.parent != undefined then(	
						rot =((bne.transform * (inverse bne.parent.transform)) as quat)								
					)
					else rot = (bne.transform as quat)							
				)
				writeshort f (rot.x*4096);writeshort f (rot.y*4096);writeshort f (rot.z*4096);writeshort f (rot.w*4096)
			)
			chunksize += (FTell f)-startOffset	--Calculation ChunkDataSize
			if ver==2 then(
				if continuous==true then (
					writefloat f (startTime/2048.0)
				)
				else(
					writefloat f lastFrameTime
				)
			)
		)
		--Start write FrameType 2 quat rotation and position--
		else if (posFrameArray.count > 0)and(rotFrameArray.count > 0) then(
			frameType=2
			--if is same time array
			if (posFrameArray as string ) == (rotFrameArray as string ) then(
				if rotFrameArray.count > 1 then(
					for i = 1 to (rotFrameArray.count-1) do(
						if ((rotFrameArray[i+1]-rotFrameArray[i])==1)then(
							continuous = true
							startTime = (rotFrameArray[1]+1)/30*2048
						)
						else(
							continuous = false
							startTime = 0
							exit
						)
					)
				)
				else(
					continuous = true
					if rotFrameArray[1] < maxTimesCount then startTime = (rotFrameArray[1]+1)/30*2048 else startTime = rotFrameArray[1]/30*2048 
				)
				quatPosFrameArray = posFrameArray
			)--end if posFrameArray == rotFrameArray
			else(--if not same time array , need merge time array and recalculation time					
				quatPosFrameArray = posFrameArray						
				for t in rotFrameArray do(
					appendIfUnique quatPosFrameArray t
				)
				quatPosFrameArray = makeUniqueArray quatPosFrameArray						
				for i = 1 to (quatPosFrameArray.count-1) do(
					if ((quatPosFrameArray[i+1]-quatPosFrameArray[i])==1)then(
						continuous = true
						startTime = (quatPosFrameArray[1]+1)/30*2048
					)
					else(
						continuous = false
						startTime = 0
						exit
					)
				)
			)--end if posFrameArray != rotFrameArray
			if ver == 1 then(writelong f 0x55514553)			--SEQU
			else if ver == 2 then (writelong f 0x54514553) 	--SEQT
			writeshort f boneID			--BoneID
			writebyte f frameType		--FrameType 1=quat 2=quat,translate 3=translate
			writeshort f quatPosFrameArray.count	--frames count
			startOffset = FTell f					
			if continuous == true then(
				writeshort f startTime	--Start Time
			)
			for i = 1 to quatPosFrameArray.count do(
				if continuous == false then(
					--if continunos == false then start time must be == 0.
					--if real frame start index != 0 then copy  frame start index rot and pos value to frame index 0
					if (i==1) then(
						if quatPosFrameArray[1] != 0 then(
							fseek f -2 #seek_cur
							writeshort f (quatPosFrameArray.count+1)
							writeshort f 0	--Start Time
							at time quatPosFrameArray[1](
								if bne.parent != undefined then(	
									rot =((bne.transform * (inverse bne.parent.transform)) as quat)
									pos =bne.pos * (inverse bne.parent.transform)
								)
								else (
									rot = (bne.transform as quat)
									pos = bne.pos
								)
							)
							writeshort f (rot.x*4096);writeshort f (rot.y*4096);writeshort f (rot.z*4096);writeshort f (rot.w*4096)
							writeshort f (pos.x*2048);writeshort f (pos.y*2048);writeshort f (pos.z*2048)
						)--end if  quatPosFrameArray[1] != 0 
					)
					--if frame start index not at 0，then need modify 2nd time(index 1 of array).
					--write time
					if i==1 then (
						
							writeshort f (quatPosFrameArray[i]/30*2048)
						
					)else(writeshort f ((quatPosFrameArray[i]-quatPosFrameArray[i-1])/30*2048))
					if i==quatPosFrameArray.count then lastFrameTime = ((quatPosFrameArray[i]-quatPosFrameArray[i-1])/30.0)					
				)--end if continuous == false
					--write quat rotation and position
				at time quatPosFrameArray[i](
					if bne.parent != undefined then(	
						rot =((bne.transform * (inverse bne.parent.transform)) as quat)
						pos =bne.pos * (inverse bne.parent.transform)
					)
					else (
						rot = (bne.transform as quat)
						pos = bne.pos
					)
				)
				writeshort f (rot.x*4096);writeshort f (rot.y*4096);writeshort f (rot.z*4096);writeshort f (rot.w*4096)
				writeshort f (pos.x*2048);writeshort f (pos.y*2048);writeshort f (pos.z*2048)					
			)-- end for i = 1 to quatPosFrameArray.count
			chunksize += (FTell f)-startOffset	--Calculation ChunkDataSize
			if (ver == 2) then(
				if continuous==true then (
					writefloat f (startTime/2048.0)
				)
				else(
					writefloat f lastFrameTime
				)
			)					
		)--end else if (posFrameArray.count > 0)and(rotFrameArray.count > 0)
		--Start write FrameType 3 position--
		else if (posFrameArray.count > 0)and(rotFrameArray.count == 0) then(	
			frameType=3
			if posFrameArray.count > 1 then(
				for i = 1 to (posFrameArray.count-1) do(
					if ((posFrameArray[i+1]-posFrameArray[i])==1)then(
						continuous = true
						startTime = (posFrameArray[1]+1)/30*2048
					)
					else(
						continuous = false
						startTime = 0
						exit
					)
				)
			)
			else(
				continuous = true
				if posFrameArray[1] < maxTimesCount then startTime = (posFrameArray[1]+1)/30*2048 else startTime = posFrameArray[1]/30*2048 
			)
			if ver == 1 then(writelong f 0x55514553)			--SEQU
			else if ver == 2 then (writelong f 0x54514553) 	--SEQT
			writeshort f boneID			--BoneID
			writebyte f frameType		--FrameType 1=quat 2=quat,translate 3=translate
			writeshort f posFrameArray.count	--frames count
			startOffset = FTell f					
			if continuous == true then(
				writeshort f startTime	--Start Time
			)else(writeshort f 0)
			--writeshort f 0;writeshort f 0;writeshort f 0;writeshort f 0		--unknown 4
			at time (startTime/2048.0*30.0)(
				if bne.parent != undefined then(	
					rot =((bne.transform * (inverse bne.parent.transform)) as quat)
				)
				else (
					rot = (bne.transform as quat)
				)				
			)	
			writeshort f (rot.x*4096);writeshort f (rot.y*4096);writeshort f (rot.z*4096);writeshort f (rot.w*4096)			
			for i = 1 to posFrameArray.count do(
				if continuous == false then(
					--if continunos == false then start time must be == 0.
					--if real frame start index != 0 then copy  frame start index rot and pos value to frame index 0
					if (i==1)then(
						if posFrameArray[1] != 0 then(
							fseek f -12 #seek_cur
							writeshort f (posFrameArray.count+1)
							fseek f 10 #seek_cur
							at time posFrameArray[1](
								if bne.parent != undefined then(	
									pos =bne.pos * (inverse bne.parent.transform)
								)
								else (
									pos = bne.pos
								)
							)
							writeshort f (pos.x*2048);writeshort f (pos.y*2048);writeshort f (pos.z*2048)
						)--end if  quatPosFrameArray[1] != 0 
					)
					--if frame start index not at 0，then need modify 2nd time(index 1 of array).
					--write time
					if i==1 then (
						if posFrameArray[1] != 0 then(
							writeshort f (posFrameArray[i]/30*2048)
						)						
					)else(writeshort f ((posFrameArray[i]-posFrameArray[i-1])/30*2048))
					if i==posFrameArray.count then lastFrameTime = ((posFrameArray[i]-posFrameArray[i-1])/30.0)					
				)--end if continuous == false
					--write quat rotation and position
				at time posFrameArray[i](
					if bne.parent != undefined then(	
						pos =bne.pos * (inverse bne.parent.transform)
					)
					else (
						pos = bne.pos
					)
				)
				writeshort f (pos.x*2048);writeshort f (pos.y*2048);writeshort f (pos.z*2048)					
			)-- end for i = 1 to quatPosFrameArray.count
			chunksize += (FTell f)-startOffset	--Calculation ChunkDataSize
			if (ver == 2) then(
				if continuous==true then (
					writefloat f (startTime/2048.0)
				)
				else(
					writefloat f lastFrameTime
				)
			)
			--if posFrameArray[posFrameArray.count] > maxTimesCount then maxTimesCount = posFrameArray[posFrameArray.count]			
		)--end else if posFrameArray.count > 0
		--format"FrameType:%\tContinuous:%\n"	frameType continuous
		if frameType!=undefined then boneCount += 1--calculation have animation data's bone count
		--print boneCount
	)--end for b = 1 to boneArray.boneNode.count do(
	writelong f 0x10	--particle effects section
	if ver==1 then(
		writefloat f 2		--unknown
		writelong f 64  --eachEntrySize
	)
	if ver==2 then(
		writefloat f 3		--unknown
		writelong f 160  --eachEntrySize
	)
	writelong f 0   --numEntry
	--print boneCount
	fseek f boneCountPointer #seek_set
	--print boneCountPointer
	writelong f boneCount
	fseek f chunkSizePointer #seek_set
	writelong f chunkSize
	fseek f FrameCountPointer #seek_set
	writefloat f (maxTimesCount/30.0)	
)
fn exportIFPfile f ver animName boneArray blockName =(
	writelong f 0x54434E41	--ANCT
	writelong f 1			--numBlock
	writelong f 0x434F4C42  --BLOC
	writelong f (blockName.count+1)
	writestring f blockName
	writelong f 0x4B504E41	--ANPK
	writelong f 1			--numANPK
	writelong f 0x454D414E	--NAME
	writelong f (animName.count+1)
	writestring f animName	
	exportANIMfile f ver boneArray	
)
struct MXSJson(
	__keys__ = #(),
	__value__ = #(),
		
	fn format_type value =(
		local f_value = stringstream ""
		
		class_type = classof value

		if superclassof value == StructDef do(
			format "%" ("{\n" +value.__json__()+"}") to:f_value
			return f_value as string
			)

		if class_type == String do(
			format "\"%\"" value to:f_value
			return f_value as string
		)
		
		if class_type == Integer do(
			format "%" value to:f_value
			return f_value as string
		)
		
		if class_type == float do(
			if value ==0.0 then value =0
			if (mod value 1)== 0 then value = value as integer 
			format "%" value to:f_value
			return f_value as string
		)
		
		if class_type == Array do(
			format "["  to:f_value
			index = 1
			for a in value do(
				l_value = this.format_type a				
				format_s = "%,\n"
				if index == value.count do(
					format_s = "%\n"
				)
				format format_s l_value to:f_value
				index+=1
			)

			format "]" to:f_value	
		)

		return f_value as string
	),
	
	fn __json__ = (
		data = ""
		index = 1
		for a in __keys__ do(
			data += "\""+ a + "\":"
			item = __value__[index]
			end_s = ",\n"
			if index == __keys__.count do(
				
				end_s = "\n"
			)					
			data += this.format_type(item)+end_s
			index+=1
		)
		return data
	),
	
	fn json = (
		return "{\n"+ this.__json__()+"}"
	),
		
	fn items = (
		return this.__keys__
	),

	fn add key value= (
		append this.__keys__ key
		append this.__value__ value		
	)
)



--For MHT(manhunt toolkit)--
fn exportJSONfile f ver boneArray =(

	maxTimesCount = 0.0f
	
	for b = 1 to boneArray.boneNode.count do(
		bne = boneArray.boneNode[b]
		for t in bne.controller.Position.controller.keys do(
			if t.time.frame > maxTimesCount then maxTimesCount = t.time.frame
		)
		for t in bne.controller.rotation.controller.keys do(
			if t.time.frame > maxTimesCount then maxTimesCount = t.time.frame
		)
	)
	a = MXSJson()
	
	bonesListArray=#()
	
	for b = 1 to boneArray.boneNode.count do(
		bne = boneArray.boneNode[b]
		boneID = BoneArray.BoneID[b]
		posFrameArray = #()
		rotFrameArray = #()
		quatPosFrameArray = #()
		frameType = undefined
		continuous = undefined
		startTime = 0
		lastFrameTime = 0
		boneStruct = MXSJson()
		boneStruct.add "boneId" boneID --BoneID	
		
		for t in bne.controller.Position.controller.keys do(
			append posFrameArray t.time.frame
		)
		for t in bne.controller.rotation.controller.keys do(
			append rotFrameArray t.time.frame
		)
		--format"rotKeysCount:%\n" rotFrameArray.count

		--if frametype==2 if pos.timescount!= rot.timescount then merge anim
		--below function get frameType and continunos flag (start time == 0 or start time > 0 )
		--in ifp anpk format, start time > 0 express the anim frame data is continuous.
		--if start time == 0 express the anim frame data is non-continunos. Some frame, the time interval between the upper and lower frame exceeds 1 frame.
		--if continunos == false then start time must be == 0.
		--if real frame start index != 0 then copy  frame start index rot and pos value to frame index 0
		--Start write FrameType 1 quat rotation--
		if (rotFrameArray.count > 0) and (posFrameArray.count == 0)then(
			frameType=1
			if rotFrameArray.count > 1 then(
				for i = 1 to (rotFrameArray.count-1) do(
					if ((rotFrameArray[i+1]-rotFrameArray[i])==1)then(
						continuous = true
						startTime = (rotFrameArray[1]+1)
					)
					else(
						continuous = false
						startTime = 0
						exit
					)
				)
			)
			else(
				continuous = true
				if rotFrameArray[1] < maxTimesCount then startTime = (rotFrameArray[1]+1) else startTime = rotFrameArray[1]
			)

			boneStruct.add "frameType" frameType --FrameType 1=quat 2=quat,translate 3=translate	
			boneStruct.add "startTime" startTime
			frames = MXSJson()
			framesArray = #()
			for i = 1 to rotFrameArray.count do(
				--write time
				subframes = MXSJson()
				if continuous == false then(				
					--if continunos == false then start time must be == 0.
					--if real frame start index != 0 then copy  frame start index rot and pos value to frame index 0
					if i==1 then (
						if rotFrameArray[1] != 0 then(
							at time rotFrameArray[1](						
								if bne.parent != undefined then(	
									rot =((bne.transform * (inverse bne.parent.transform)) as quat)								
								)
								else rot = (bne.transform as quat)
							)							
							subframes.add "time" 0 
							subframes.add "quat" #(rot.x,rot.y,rot.z,rot.w)
							
						)--end if rotFrameArray[1] != 0
					)
					--if frame start index not at 0，then need modify 2nd time(index 1 of array).
					--write time
					if i==1 then (
						subframes.add "time" (rotFrameArray[i])							
					)else(
						subframes.add "time" ((rotFrameArray[i]-rotFrameArray[i-1]))
					)
					if i==rotFrameArray.count then lastFrameTime = ((rotFrameArray[i]-rotFrameArray[i-1]))
				)--end if continuous == false
				--write quat rotation
				at time rotFrameArray[i](
					if bne.parent != undefined then(	
						rot =((bne.transform * (inverse bne.parent.transform)) as quat)								
					)
					else rot = (bne.transform as quat)							
				)
				subframes.add "quat" #(rot.x,rot.y,rot.z,rot.w)
				append framesArray subframes
			)
			frames.add "frames" framesArray
			if ver==2 then(
				if continuous==true then (
					--writefloat f startTime
					frames.add "lastFrameTime" startTime
				)
				else(
					
					frames.add "lastFrameTime" lastFrametime
				)
			)
			boneStruct.add "frames" frames
			append bonesListArray boneStruct
		)
		--Start write FrameType 2 quat rotation and position--
		if (posFrameArray.count > 0)and(rotFrameArray.count > 0) then(
			frameType=2
			--if is same time array
			if (posFrameArray as string ) == (rotFrameArray as string ) then(
				if rotFrameArray.count > 1 then(
					for i = 1 to (rotFrameArray.count-1) do(
						if ((rotFrameArray[i+1]-rotFrameArray[i])==1)then(
							continuous = true
							startTime = (rotFrameArray[1]+1)
						)
						else(
							continuous = false
							startTime = 0
							exit
						)
					)
				)
				else(
					continuous = true
					if rotFrameArray[1] < maxTimesCount then startTime = (rotFrameArray[1]+1) else startTime = rotFrameArray[1]
				)
				quatPosFrameArray = posFrameArray
			)--end if posFrameArray == rotFrameArray
			else(--if not same time array , need merge time array and recalculation time					
				quatPosFrameArray = posFrameArray						
				for t in rotFrameArray do(
					appendIfUnique quatPosFrameArray t
				)
				quatPosFrameArray = makeUniqueArray quatPosFrameArray						
				for i = 1 to (quatPosFrameArray.count-1) do(
					if ((quatPosFrameArray[i+1]-quatPosFrameArray[i])==1)then(
						continuous = true
						startTime = (quatPosFrameArray[1]+1)
					)
					else(
						continuous = false
						startTime = 0
						exit
					)
				)
			)--end if posFrameArray != rotFrameArray
			boneStruct.add "frameType" frameType --FrameType 1=quat 2=quat,translate 3=translate	
			boneStruct.add "startTime" startTime
			frames = MXSJson()
			framesArray = #()						
			for i = 1 to quatPosFrameArray.count do(
				subframes = MXSJson()
				if continuous == false then(
					--if continunos == false then start time must be == 0.
					--if real frame start index != 0 then copy  frame start index rot and pos value to frame index 0
					if i==1 then (
						if quatPosFrameArray[1] != 0 then(
							at time quatPosFrameArray[1](
								if bne.parent != undefined then(	
									rot =((bne.transform * (inverse bne.parent.transform)) as quat)
									pos =bne.pos * (inverse bne.parent.transform)
								)
								else (
									rot = (bne.transform as quat)
									pos = bne.pos
								)
							)
							subframes.add "time" 0 
							subframes.add "quat" #(rot.x,rot.y,rot.z,rot.w)							
							subframes.add "position" #(pos.x,pos.y,pos.z)
						)--end if  quatPosFrameArray[1] != 0 
					)
					--if frame start index not at 0，then need modify 2nd time(index 1 of array).
					--write time
					if i==1 then (
						subframes.add "time" (quatPosFrameArray[i])
					)else
					(
						subframes.add "time"  ((quatPosFrameArray[i]-quatPosFrameArray[i-1]))
					)
					if i==quatPosFrameArray.count then lastFrameTime = ((quatPosFrameArray[i]-quatPosFrameArray[i-1]))					
				)--end if continuous == false
					--write quat rotation and position
				at time quatPosFrameArray[i](
					if bne.parent != undefined then(	
						rot =((bne.transform * (inverse bne.parent.transform)) as quat)
						pos =bne.pos * (inverse bne.parent.transform)
					)
					else (
						rot = (bne.transform as quat)
						pos = bne.pos
					)
				)						
				subframes.add "quat" #(rot.x,rot.y,rot.z,rot.w)
				subframes.add "position" #(pos.x,pos.y,pos.z)
				append framesArray subframes
			)
			frames.add "frames" framesArray
			if ver==2 then(
				if continuous==true then (
					--writefloat f startTime
					frames.add "lastFrameTime" startTime
				)
				else(
					
					frames.add "lastFrameTime" lastFrametime
				)
			)
			boneStruct.add "frames" frames
			append bonesListArray boneStruct					
		)--end else if (posFrameArray.count > 0)and(rotFrameArray.count > 0)
		--Start write FrameType 3 position--
		if (posFrameArray.count > 0)and(rotFrameArray.count == 0) then(	
			frameType=3
			if posFrameArray.count > 1 then(
				for i = 1 to (posFrameArray.count-1) do(
					if ((posFrameArray[i+1]-posFrameArray[i])==1)then(
						continuous = true
						startTime = (posFrameArray[1]+1)
					)
					else(
						continuous = false
						startTime = 0
						exit
					)
				)
			)
			else(
				continuous = true
				if posFrameArray[1] < maxTimesCount then startTime = (posFrameArray[1]+1) else startTime = posFrameArray[1]
			)
			boneStruct.add "frameType" frameType --FrameType 1=quat 2=quat,translate 3=translate	
			boneStruct.add "startTime" startTime
			frames = MXSJson()
			framesArray = #()								

			for i = 1 to posFrameArray.count do(
				subframes = MXSJson()
				if continuous == false then(
					--if continunos == false then start time must be == 0.
					--if real frame start index != 0 then copy  frame start index rot and pos value to frame index 0
					if i==1 then (
						if posFrameArray[1] != 0 then(
							at time posFrameArray[1](
								if bne.parent != undefined then(	
									pos =bne.pos * (inverse bne.parent.transform)
								)
								else (
									pos = bne.pos
								)
							)
							--writeshort f (pos.x*2048);writeshort f (pos.y*2048);writeshort f (pos.z*2048)
							subframes.add "position" #(pos.x,pos.y,pos.z)							
						)--end if  quatPosFrameArray[1] != 0 
					)
					--if frame start index not at 0，then need modify 2nd time(index 1 of array).
					--write time
					if i==1 then (
						if posFrameArray[1] != 0 then(
							subframes.add "time"  ((posFrameArray[i]-posFrameArray[i-1]))
						)
					)else(
						subframes.add "time" ((posFrameArray[i]-posFrameArray[i-1]))
					)
					if i==posFrameArray.count then lastFrameTime = ((posFrameArray[i]-posFrameArray[i-1]))					
				)--end if continuous == false
					--write quat rotation and position
				at time posFrameArray[i](
					if bne.parent != undefined then(	
						pos =bne.pos * (inverse bne.parent.transform)
					)
					else (
						pos = bne.pos
					)
				)	
				subframes.add "position" #(pos.x,pos.y,pos.z)						
				append framesArray subframes
			)-- end for i = 1 to quatPosFrameArray.count
			frames.add "frames" framesArray
			if ver==2 then(
				if continuous==true then (
					--writefloat f startTime
					frames.add "lastFrameTime" startTime
				)
				else(
					
					frames.add "lastFrameTime" lastFrametime
				)
			)
			at time (startTime*30) (
				if bne.parent != undefined then(	
					rot =((bne.transform * (inverse bne.parent.transform)) as quat)
				)
				else (
					rot = (bne.transform as quat)
				)
			)			
			boneStruct.add "frames" frames
			boneStruct.add "direction" #(rot.x,rot.y,rot.z,rot.w)	
			append bonesListArray boneStruct
		)--end else if posFrameArray.count > 0
		
	)--end for b = 1 to boneArray.boneNode.count do(
	a.add "frameTimeCount" maxTimesCount
	a.add "bones" bonesListArray
	if ver==1 then(
		a.add "unknown5" "00000040"
	)
	if ver==2 then(
		a.add "unknown5" "00004040"
	)
    
    a.add "entry" #()
	outtext = a.json()
	format "%" outtext to:f
)
rollout AllenMH2IFPexp "Manhunt 1/2 IFP Exporter"(
	--radioButtons expAnpkVer "Animation Version:" labels:#("Manhunt 1", "Manhunt 2") default:2 align:#left
	radioButtons expAnpkVer "" labels:#("Manhunt 1", "Manhunt 2") default:2 
	edittext blockNametxt "Block Name:" LabelOnTop:true --text:"PlayerAnims" 
	edittext animNametxt "Animation Name:" LabelOnTop:true --text:"BAT_Anim" 
	button exportIFPbtn "Export .ifp" Width:65 Height:30 across:2
	button exportANIMbtn "Export .anim" Width:80 Height:30 tooltip:"export single anpk file for easy add to ifp and bin file"
	button exportJsonbtn "Export .json"Width:65 Height:30 tooltip:"For MHT(Manhunt Toolkit)" across:2
	button selectRoot "Sel RootBone" Width:80 Height:30 tooltip:"Select RootBone" 
	on selectRoot pressed do(
		root = SelectRootBone()
		if root != undefined then select root
	)
	on exportIFPbtn pressed do(
		if ($!=undefined)and((getUserProp $ "BoneIndex")==0) and ((getUserProp $ "BoneID")!=undefined)then(
			ver = expAnpkVer.state
			blockName = blockNametxt.text
			animName = animNametxt.text		
			if (blockName != "" )and (animName != "" )then(
				outifpfname = getsaveFileName caption:"Manhunt 1/2 IFP file" types:"(*.ifp)|*.ifp" 
				if ( outifpfname != undefined) then(		
					boneArray= boneTag BoneID:#() boneNode:#()
					BNArray=#()
					CollectionBone $ BNArray
					for obj in BNArray where (((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneID" != undefined)) do(
						BoneID = (getuserprop obj "BoneID")
						if (boneID !=0xFFFF)and(BoneID !=10000)then(
							append bonearray.BoneID  BoneID
							append boneArray.boneNode obj
						)
					)				
					f = fopen outifpfname "wb"
					exportIFPfile f ver animName boneArray blockName
					fclose f
				)--end if ( outifpfname != undefined)
			)else(
				messagebox"Please enter Block Name: and Animation Name:!" title:"Export error"
			)
		)--end if($!=undefined)
		else(
			messagebox "Can't export,Please select root bone export!" title:"Export error"
		)		
	)--end exportIFPbtn pressed
	on exportANIMbtn pressed do(
		if ($!=undefined)and((getUserProp $ "BoneIndex")==0) and ((getUserProp $ "BoneID")!=undefined)then(
			ver = expAnpkVer.state
			animName = animNametxt.text	
			outAnimfname = getsaveFileName caption:"Manhunt 1/2 Animation Pack file" types:"(*.anim)|*.anim" filename:animName
			if ( outAnimfname != undefined) then(		
				boneArray= boneTag BoneID:#() boneNode:#()
				BNArray=#()
				CollectionBone $ BNArray
				for obj in BNArray where (((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneID" != undefined)) do(
					BoneID = (getuserprop obj "BoneID")
					if (boneID !=0xFFFF)and(BoneID !=10000)then(
						append bonearray.BoneID  BoneID
						append boneArray.boneNode obj
					)
				)
				f = fopen outAnimfname "wb"
				exportANIMfile f ver boneArray
				fclose f				
			)--end if ( outAnimfname != undefined)
		)--end if($!=undefined)
		else(
			messagebox "Can't export,Please select root bone export!" title:"Export error"
		)
	)--end exportANPKbtn pressed 
	on exportJsonbtn pressed do(
		if ($!=undefined)and((getUserProp $ "BoneIndex")==0) and ((getUserProp $ "BoneID")!=undefined)then(
			ver = expAnpkVer.state
			animName = animNametxt.text
			outjsonname = getsaveFileName caption:"MHT(Manhunt Toolkit)　json file" types:"(*.json)|*.json" filename:animName
			if ( outjsonname != undefined) then(		
				boneArray= boneTag BoneID:#() boneNode:#()
				BNArray=#()
				CollectionBone $ BNArray
				for obj in BNArray where (((classof obj)==BoneGeometry or (classof obj)== Dummy ) and (getuserprop obj "BoneID" != undefined)) do(
					BoneID = (getuserprop obj "BoneID")
					if (boneID !=0xFFFF)and(BoneID !=10000)then(
						append bonearray.BoneID  BoneID
						append boneArray.boneNode obj
					)
				)

				f = createfile outjsonname
				exportJSONfile f ver boneArray
				close f				
			)--end if ( outjsonname != undefined)

		)--end if($!=undefined)
		else(
			messagebox "Can't export,Please select root bone export!" title:"Export error"
		)
	)
)
rollout IFPAboutRoll "About" (
	label a1 "Manhunt 1/2 IFP IO" --align:#left
	label a2 "Support IFP/BIN Animation" --align:#left
	label a3 "Sep 12 2021 By Allen" --align:#right
	label a4 "leeao@live.com" --align:#right
)
if AllenIFP_Tool != undefined then (
	closeRolloutFloater AllenIFP_Tool
	gc() 
)
--AllenIFP_Tool = newRolloutFloater "MH2 IFP IO" 200 650 10 50
AllenIFP_Tool = newRolloutFloater "MH2 IFP IO" 300 650 10 50
addRollout AllenMH2IFPimp AllenIFP_Tool rolledup:false
addRollout AllenMH2IFPexp AllenIFP_Tool rolledup:false
addRollout IFPAboutRoll AllenIFP_Tool rolledup:false
