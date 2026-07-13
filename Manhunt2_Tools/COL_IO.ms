/*
Manhunt 1/2 Collision IO
by Allen ,Oct 24, 2019

Thanks for some code reference Seemann's GTA COL IO.
*/
gc()
global ColEntryArray
global ColEntryIndexArray
global ColFname
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

fn ReadPadding f =(
	local padLen = (4 - (mod (ftell f) 4))
    if (padLen < 4) and (padLen > 0) then
	(
		fseek f padLen #seek_cur
	)
)

fn drawLineBetweenTwoPoints pointA pointB =(
  ss = line pos:pointA
  addNewSpline ss
  addKnot ss 1 #corner #line PointA
  addKnot ss 1 #corner #line PointB
  updateShape ss
  ss
)
fn ReadEntryList =
(
	if ( ColFname != undefined) then(
		f = fopen ColFname "rb"	
		ColEntryArray =#()
		ColEntryIndexArray=#()
		numCol = readlong f
		for i = 1 to numCol do(
			append ColEntryIndexArray (ftell f)
			entryName = readstring f
			append ColEntryArray entryName
			readPadding f
			fseek f 40 #seek_cur
			numSpheres = readlong f
			fseek f (numSpheres*20) #seek_cur
			numLines = readlong f
			fseek f (numLines*24) #seek_cur
			numBoxes = readlong f
			fseek f (numBoxes*28) #seek_cur
			numVerts = readlong f
			fseek f (numVerts*12) #seek_cur
			numFace = readlong f
			fseek f (numFace*12) #seek_cur
		)	
		fclose f
	)
)
fn ReadCol f ListID showBound=
(
	fseek f COLEntryIndexArray[ListID] #seek_set
	entryName = readstring f			
	readPadding f
	center = [(readfloat f),(readfloat f),(readfloat f)]
	radius = readfloat f
	boundMin = [(readfloat f),(readfloat f),(readfloat f)]
	boundMax = [(readfloat f),(readfloat f),(readfloat f)]
	if (showBound == true) then(
		BoundSphere = Sphere radius:radius smooth:on  pos:center xray:on name: "Bounding Sphere"
		/*
		BoundBox = Box  width:(boundMax.x-boundMin.x) length:(boundMax.y-boundMin.y) \
		height:(boundMax.z-boundMin.z)  pos:[center.x,center.y,center.z-0.5*(boundMax.z-boundMin.z)] \
		name:"Bounding Box"*/
	)
	numSpheres = readlong f
	--fseek f (numSpheres*20) #seek_cur
	for i = 1 to numSpheres do(
		center = [(readfloat f),(readfloat f),(readfloat f)]
		radius = readfloat f
		materialType = readbyte f #unsigned
		flag = readbyte f #unsigned
		brightness = readbyte f #unsigned
		surfacelight  = readbyte f #unsigned
		Sphere radius:radius smooth:on pos:center
		--format "mat:%\tflag:%\tbrightness:%\tlight:%\n" materialType flag brightness surfacelight
	)
	numLines = readlong f
	
	for i = 1 to numLines do(
		v1 = [(readfloat f),(readfloat f),(readfloat f)]
		v2 = [(readfloat f),(readfloat f),(readfloat f)]
		newSpline = drawLineBetweenTwoPoints v1 v2
	)
	numBoxes = readlong f
	for i = 1 to numBoxes do(
		boxMin = [(readfloat f),(readfloat f),(readfloat f)]
		boxMax = [(readfloat f),(readfloat f),(readfloat f)]
		materialType = readbyte f #unsigned
		flag = readbyte f #unsigned
		brightness = readbyte f #unsigned
		surfacelight  = readbyte f #unsigned
		boxs = Box  width:(boxmax.x-boxmin.x) length:(boxmax.y-boxmin.y) height:(boxmax.z-boxmin.z) \
		pos:[(boxmax.x+(boxmax.x-boxmin.x)/2.0),(boxmax.y+(boxmax.y-boxmin.y)/2.0),(boxmax.z+(boxmax.z-boxmin.z)/2.0)]
	)
	
	Vert_array = #()
	Face_Array = #()
	numVerts = readlong f
	for i = 1 to numVerts do (
		vx = readfloat f 
		vy = readfloat f
		vz = readfloat f
		append Vert_Array [vx,vy,vz]
	)
	numFace = readlong f
	for i = 1 to numFace do (
		f1 = (readlong f #unsigned) + 1                   
		f2 = (readlong f #unsigned) + 1
		f3 = (readlong f #unsigned) + 1
		append Face_array [f1,f2,f3]
	)
	
	if (numVerts > 0) then(
		msh = mesh vertices:Vert_array faces:Face_Array name:entryName
		meshop.flipNormals msh #{1..msh.numfaces}
	)
)
fn ReadSingleCol ListID showBound =
(
	if ( ColFname != undefined) then(
		f = fopen ColFname "rb"
		ReadCol f ListID showBound
		fclose f
	)
)
fn ReadAllCol ShowBound =
(
	if ( ColFname != undefined) then(
		
		f = fopen ColFname "rb"	
		for i = 1 to ColEntryIndexArray.count do(
			ReadCol f i showBound
		)
		fclose f		
	)
)

fn WritePadding f =
(
	padlen =4-( mod (ftell f) 4)
	if (padLen<4)and(padLen>0)then
	(
		for i = 1 to padlen do writebyte f 0x70
	)
)
fn exportColData f ColName colmesh =
(
	writestring f colName
	WritePadding f
	
	objectArray = selection
	boundRadius= 0.5*(distance objectArray.min objectArray.max)
	boundcenter= 0.5*(objectArray.min+objectArray.max)
	boundmin= objectArray.min
	boundmax= objectArray.max
	
	writefloat f boundcenter.x
	writefloat f boundcenter.y
	writefloat f boundcenter.z
	writefloat f boundRadius
	writefloat f boundmin.x
	writefloat f boundmin.y
	writefloat f boundmin.z
	writefloat f boundmax.x
	writefloat f boundmax.y
	writefloat f boundmax.z	
	
	sphereArray= for i in objectArray where (classof i == sphere) collect i
	if (sphereArray.count>0)then(
		writelong f sphereArray.count #unsigned
		for s in sphereArray do
		(
			writefloat f s.center.x
			writefloat f s.center.y
			writefloat f s.center.z
			writefloat f s.radius
			writelong f 0			
		)
	)
	else(writelong f 0)

	
	lineobjArray = for i in objectArray where (classof i == line) collect i
	if (lineobjArray.count>0)then(
		linesOffset = ftell f
		writelong f 0
		linesCount = 0
		for li in lineobjArray do
		(			
			if ((numKnots li)==2)then
			(
				pointa = (getKnotPoint li 1 1)
				pointb = (getKnotPoint li 1 2)
				writefloat f pointa.x
				writefloat f pointa.y
				writefloat f pointa.z
				writefloat f pointb.x
				writefloat f pointb.y
				writefloat f pointb.z
				linesCount+=1
			)
		)
		linesEnd = ftell f		
		if (linesCount > 0) then(
			fseek f linesOffset #seek_set
			writelong f linesCount
			fseek f linesEnd #seek_set
		)
	)else(writelong f 0)
	writelong f 0 --numboxes
	
	vert_Array=#()
	face_Array=#()
	
	if(colmesh!=undefined)then
	(
		meshop.flipNormals colmesh #{1..colmesh.numfaces}
		num_verts = colmesh.numverts
		num_faces = colmesh.numfaces

		writelong f num_verts #unsigned
		for v = 1 to num_verts do
		(
			vertex = (getVert colmesh v)
			writefloat f vertex.x
			writefloat f vertex.y
			writefloat f vertex.z
		)	
		writelong f num_faces #unsigned
		for fa = 1 to num_faces do
		(
			FaceIndex = getFace colmesh fa
			FaceIndex.x = faceIndex.x-1
			FaceIndex.y = faceIndex.y-1
			FaceIndex.z = faceIndex.z-1
			writelong f FaceIndex.x #unsigned
			writelong f FaceIndex.y #unsigned
			writelong f FaceIndex.z #unsigned
		)
		meshop.flipNormals colmesh #{1..colmesh.numfaces}
	)
	else(
		writelong f 0 
		writelong f 0 	
	)
)
fn exportCol f ColName colmesh=
(
	writelong f 1 --write count	
	exportColData f ColName colmesh
)
fn appendcol ColName colmesh backup=
(	
	if backup then(
		backupname = (scriptspath+"\\Manhunt2_Tools\\"+(fileNameFromPath ColFname))	
		if doesFileExist backupname then deletefile backupname
		copyFile ColFname backupname		
	)
	f = fopen ColFname "rb+"	
	numcol = readlong f #unsigned
	fseek f 0 #seek_set
	writelong f (numcol+1)
	fseek f 0 #seek_end
	append ColEntryIndexArray (ftell f)
	append ColEntryArray ColName
	exportColData f ColName colmesh
	fclose f
)
fn delcol ListID backup =
(
	filesize = getFileSize ColFname
	if backup then(
		backupname = (scriptspath+"\\Manhunt2_Tools\\"+(fileNameFromPath ColFname))	
		if doesFileExist backupname then deletefile backupname
		copyFile ColFname backupname		
	)
	f = fopen ColFname "rb"	
	tempname = (scriptspath+"\\Manhunt2_Tools\\"+(fileNameFromPath ColFname))	+".temp"
	numCol = readlong f	
	if (numCol>1)then(
		t = fopen tempname "wb+"
		numCol -= 1
		writelong t numcol #unsigned
		while ((Ftell f)< COLEntryIndexArray[ListID]) do(
			writebyte t (readbyte f)
		)
		
		if (ListID!=COLEntryIndexArray.count) then(
			fseek f COLEntryIndexArray[ListID+1] #seek_set
			while ((Ftell f)< filesize) do(
				writebyte t (readbyte f)
			)
		)
		fclose f

		f = fopen ColFname "wb"
		tempSize = ftell t
		fseek t 0 #seek_set
		while ((ftell f)<tempSize) do(
			writebyte f (readbyte t)
		)		
		fclose t
		fclose f
		deletefile tempname
	)else(
		fclose f
		messagebox"Please keep at least one object!"
	)
	
)
fn exportColJSON f ColName colmesh =
(
	col = MXSJson()
	col.add "name" colName
	objectArray = selection
	boundRadius= 0.5*(distance objectArray.min objectArray.max)
	boundcenter= 0.5*(objectArray.min+objectArray.max)
	boundmin= objectArray.min
	boundmax= objectArray.max
	col.add "center" #(boundcenter.x,boundcenter.y,boundcenter.z)
	col.add "radius" boundRadius
	col.add "min" #(boundmin.x,boundmin.y,boundmin.z)
	col.add "max" #(boundmax.x,boundmax.y,boundmax.z)
	
	spArray = #()
	sphereArray= for i in objectArray where (classof i == sphere) collect i
	for s in sphereArray do
	(
		sp = MXSJson()
		sp.add "center" #(s.center.x,s.center.y,s.center.z)
		sp.add "radius" s.radius
		sp.add "material" 0
		sp.add "flag" 0
		sp.add "brightness" 0
		sp.add "light" 0
		append spArray sp
	)
	col.add "spheres" spArray
	
	lineArray=#()
	lineobjArray = for i in objectArray where (classof i == line) collect i
	for li in lineobjArray do
	(
		
		if ((numKnots li)==2)then
		(
			temp=#()
			pointa = (getKnotPoint li 1 1)
			pointb = (getKnotPoint li 1 2)
			append temp #(pointa.x,pointa.y,pointa.z)
			append temp #(pointb.x,pointb.y,pointb.z)
			append lineArray temp
		)
	)
	col.add "lines" lineArray
	col.add "boxes" #()
	vert_Array=#()
	face_Array=#()
	if(colmesh!=undefined)then
	(
		meshop.flipNormals colmesh #{1..colmesh.numfaces}
		num_verts = colmesh.numverts
		num_faces = colmesh.numfaces
		for v = 1 to num_verts do
		(
			vertex = (getVert colmesh v)
			append vert_array #(vertex.x,vertex.y,vertex.z)
		)		
		for fa = 1 to num_faces do
		(
			FaceIndex = getFace colmesh fa
			FaceIndex.x = faceIndex.x-1
			FaceIndex.y = faceIndex.y-1
			FaceIndex.z = faceIndex.z-1
			append face_array #(FaceIndex.x,FaceIndex.y,FaceIndex.z)
		)
		meshop.flipNormals colmesh #{1..colmesh.numfaces}
	)
	col.add "verticals" vert_Array
	col.add "faces" face_Array
	outtext = col.json()
	format "%" outtext to:f
)

rollout AllenMH2COL "Manhunt 1 & 2 Collision IO"(
	
	fn collmeshfilt obj =
	(
		classof obj == Editable_mesh
	)	
	--group "Import"(
		button btn1 "Open Collision File"
		listBox lbx1 "Entry:"	
		label lab1 "Count:"align:#left across:2
		checkbox showBound "Show Bounding" align:#right
		button btn4 "Import All"  across:2 align:#left
		button btn3 "Import Selected"align:#right
		--label lab3 "Double-Click also can import"
	--)
	group "Export" (
		checkBox checkBack "Backup" checked: false align: #left
		checkBox delConf	"Delete backups after exit" align: #left checked: false
		button delBut "Delete" across: 3 tooltip:"Delete single col from Entry List "
		button appdcolbtn "Append" tooltip:"Append export to current Collision File"
		button undobtn "Undo" tooltip:"Undo Delete/Append. Restore only the last operation, no continuous operation"
		edittext UIcolname "Col Name:" LabelOnTop:true 
		
		button expjsonbtn "Export .json" tooltip:"For MHT(Manhunt Toolkit)" across:2 
		button expcolbtn "Exoprt .col"tooltip:("If you just want export models bouding box/sphere,"+ \ 
		"please only select the model or box (Does not contain anything else)")

	)
	group "Export Setting"(
		pickButton pickCol "Collision mesh" message: "Select collision mesh" \
						autodisplay: true align: #center across: 2 offset: [20,0] width: 98 \
						filter: collmeshfilt tooltip:"If you want export collision mesh please click and select a col mesh"
		button cancelCol "C" align: #center		
	)
	
	on CancelCol pressed do
	(
		pickCol.object = undefined
	)	
	on btn1 pressed  do(	 --选择文件	
		ColFname = undefined

		ColFname = getOpenFileName \ 
		caption:"Manhunt 2 Collision File" \
		types:"Manhunt 2 Collision File(*.col)|*.col" 
		bool = false 
		if ColFname != undefined then(
			f2 = fopen ColFname "rb"
			Idstring = readlong f2
			DecompressSize = readlong f
			fclose f2
			--if Idstring == "Z2HM" then
			if Idstring == 0x4D48325A or Idstring == 0x5A32484D then(
				
				exename = scriptspath+"\\Manhunt2_Tools\\mh2tools.exe"
				DOSCommandName = "-z -s "+"\""+ColFname+"\""
				ShellLaunch exename DOSCommandName					
				decompressFileName = (getFilenamePath ColFname) +"\\"+(getFilenameFile  ColFname)+ "_decompress"+(getFilenameType ColFname)
				ColFname = decompressFileName					
				do(
					sleep 1 -- must be wait 1 second  , because maxscript execute very fast, if not wait fname will == undefined,this time mh2tools not done decomporess work!
					bool = doesFileExist ColFname
					fileSize = getFileSize ColFname
				)while (bool != true)AND(fileSize != DecompressSize)
				
			)
			else(
				bool = true
			)
			
		)
		if ( ColFname != undefined) AND bool == true then(
			--if checkBack.checked then copyfile ColFname (scriptspath+"Manhunt2_Tools\\"+ (fileNameFromPath ColFname))
			ReadEntryList()
			lbx1.items = ColEntryArray
			lab1.caption= "Count:" + ColEntryArray.count as string				
			if (lbx1.items.count == 1)then(
				ReadSingleCol 1 showBound.state
			)
		)
		--clearlistener()
	)
	on lbx1 doubleClicked sel do(--双击选中项目
		ReadSingleCol lbx1.selection showBound.state
	)
	on btn3 pressed  do( --导入选中项目
		AllenMH2COL.lbx1.doubleClicked AllenMH2COL.lbx1.selection
	)	
	on btn4 pressed  do	(--导入全部项目
		ReadAllCol showBound.state
	)
	on expcolbtn pressed do(
		if ($!=undefined)then(
			colOutname = UIcolname.text
			if (colOutname!="")then(
				outcolname = getsaveFileName caption:"Manhunt Collision .col file" types:"(*.col)|*.col" filename:colOutname
				if ( outcolname != undefined) then(		
					f = fopen outcolname "wb"
					exportCol f  colOutname pickCol.object
					fclose f				
				)--end if ( outjsonname != undefined)
			)else(messagebox"Please enter Col Name: !" title:"Export error")
		)else(messagebox"Please select at least one object!" title:"Export error")	
		
		
	)
	on expjsonbtn pressed do(
		if ($!=undefined)then(
			colOutname = UIcolname.text
			if (colOutname!="")then(
				outjsonname = getsaveFileName caption:"Manhunt Collision MHT(Manhunt Toolkit) .json file" types:"(*.json)|*.json" filename:colOutname
				if ( outjsonname != undefined) then(		
					f = createfile outjsonname
					exportColJSON f colOutname pickCol.object
					close f				
				)--end if ( outjsonname != undefined)
			)else(messagebox"Please enter Col Name: !" title:"Export error")
		)else(messagebox"Please select at least one object!" title:"Export error")	
	)
	on delBut pressed do
	(
		if lbx1.selection != 0 then
		(
			delcol lbx1.selection checkBack.checked
			ReadEntryList()
			lbx1.items = ColEntryArray
			lab1.caption= "Count:" + ColEntryArray.count as string
		)
	)	
	on appdcolbtn pressed do(

		if ($!=undefined)then(
			colOutname = UIcolname.text
			if (colOutname!="")then(
				if (ColFname!=undefined)then(
					appendcol colOutname pickCol.object checkBack.checked
					lbx1.items = ColEntryArray
					lab1.caption= "Count:" + ColEntryArray.count as string
					lbx1.selection = lbx1.items.count
				)else(messagebox"Please open the col file you need to append and retry!" title:"Export error")
			)else(messagebox"Please enter Col Name: !" title:"Export error")
		)else(messagebox"Please select at least one object!" title:"Export error")	
	)
	on undobtn pressed do(
		if (ColFname!=undefined)then(
			backupname = (scriptspath+"\\Manhunt2_Tools\\"+(fileNameFromPath ColFname))	
			if doesFileExist backupname then
			(
				ReadEntryList()
				lbx1.items = ColEntryArray
				lab1.caption= "Count:" + ColEntryArray.count as string
			)
		)
	)
	on AllenMH2COL close do
	(
		if delConf.checked then
			HiddenDosCommand ("del "+"\""+scriptspath+"Manhunt2_Tools\\*.col"+"\"") startpath: ""
		gc();
	)	
)
rollout COLAboutRoll "About" (
	label a1 "Manhunt 1/2 COL IO" --align:#left
	label a3 "24 Oct 2019 By Allen" --align:#right
	label a4 "leeao@live.com" --align:#right
)
if AllenCol_Tool != undefined then (
	closeRolloutFloater AllenCol_Tool
	gc() 
)
AllenCol_Tool = newRolloutFloater "Collision IO" 230 500 10 50
addRollout AllenMH2COL AllenCol_Tool rolledup:false 
addRollout COLAboutRoll AllenCol_Tool rolledup:true