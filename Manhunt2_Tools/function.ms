/*
Calculating / Smoothing Normal 
Code by Allen (leeao@lvie.com)

Reference paper:
Research of Calculating Method for Surface Normal Line of 3D-EntityModel ,CHENGLei, LIUHai-yan,( Shenyang Ligong University, Shenyang,110168, China)
一种三维实体模型表面法线计算方法研究,程　磊, 刘海艳,(沈阳理工大学信息科学与工程学院, 辽宁沈阳110168)
*/

struct uniqueVertFace (
	weldVertArray,weldFaceArray
)
struct recalNormals(
	weldNormals,normals
)
fn uniqueVertFaceArray originalVertArray originalFaceArray =(
	--Unique vertex array , weld vertex
	--To calculate the vertex normals to prepare, if we do not weld vertices, normal calculation is not accurate
	weldVertArray = deepCopy originalVertArray
	weldFaceArray = #()
	for i in weldVertArray.count to 1 by -1 do
	(
		id = findItem weldVertArray weldVertArray[i]
		if (id != i) do deleteItem weldVertArray id
	)
	for i = 1 to originalFaceArray.count do (
		append weldFaceArray [0,0,0]
		for j = 1 to 3 do(
			vert = originalVertArray[originalFaceArray[i][j]]
			ID = findItem weldVertArray Vert
			weldFaceArray[i][j] = ID
		)
	)
	backData = uniqueVertFace()
	backData.weldVertArray = weldVertArray
	backData.weldFaceArray = weldFaceArray
	backData
)
fn calculateNormal weldVertArray weldFaceArray originalVertArray = (
	--calculate normal--		
	faceNormalArr = #()
	faceAreaArr = #()
	vertNormalFaceIDArr = #() -- get bind vertex face id
	for i = 1 to weldVertArray.count do (
		temp = #()
		append vertNormalFaceIDArr temp
	)
	for j = 1 to weldFaceArray.count do(
		--calculate face normal
		firstVec = weldVertArray[weldFaceArray[j].y]-weldVertArray[weldFaceArray[j].x]
		secondVec = weldVertArray[weldFaceArray[j].z]-weldVertArray[weldFaceArray[j].x]
		normal = cross firstVec secondVec
		normal = normalize normal
		append faceNormalArr normal
		
		--Get all face ID data used by this vertex.
		append vertNormalFaceIDArr[weldFaceArray[j].x] j
		append vertNormalFaceIDArr[weldFaceArray[j].y] j
		append vertNormalFaceIDArr[weldFaceArray[j].z] j
		
		--calculate triangle area(S),Helen formula
		a = distance weldVertArray[weldFaceArray[j].y] weldVertArray[weldFaceArray[j].x]
		b = distance weldVertArray[weldFaceArray[j].z] weldVertArray[weldFaceArray[j].x]
		c = distance weldVertArray[weldFaceArray[j].y] weldVertArray[weldFaceArray[j].z]
		p = (a + b + c) / 2
		S = sqrt (p * (p - a)*(p - b)*(p - c))
		append faceAreaArr S
	)	
	
	--Area weighted average method-calculation normal
	weldNormalArray = #()
	for i = 1 to vertNormalFaceIDArr.count do (
		if vertNormalFaceIDArr[i].count == 0 then normal =normalize [0,0,0] else(
			normal = faceNormalArr[vertNormalFaceIDArr[i][1]] * faceAreaArr[vertNormalFaceIDArr[i][1]]
			
			for j = 2 to vertNormalFaceIDArr[i].count do(
				normal += faceNormalArr[vertNormalFaceIDArr[i][j]] * faceAreaArr[vertNormalFaceIDArr[i][j]]				
			)			
			normal = normal / vertNormalFaceIDArr[i].count							
			normal = normalize normal
		)
		--append weldNormalArray normal
		weldNormalArray[i] = normal
	)
	
	finalNormalArray = #()
	for i = 1 to originalVertArray.count do(
		vert = originalVertArray[i]
		weld_vertID = findItem weldVertArray vert
		append finalNormalArray weldNormalArray[weld_vertID]
	)
	--finalNormalArray
	backData = recalNormals()
	backData.weldNormals = weldNormalArray
	backData.normals = finalNormalArray
	backData
)