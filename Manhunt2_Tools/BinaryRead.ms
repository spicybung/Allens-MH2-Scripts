global bigEndian = false
--读取 big endian 16bit有符号整数
fn ReadBEShort fstream = (
	val = bit.swapBytes (readshort fstream #unsigned) 1 2
	if val > 0x7FFF then val -= 0x10000
	return val
)
 --读取 big endian 16bit无符号整数
fn ReadBEword fstream = (
	return (bit.swapBytes (readshort fstream #unsigned) 1 2)
)
fn floatSwap2 f = 
(
	i = bit.floatAsInt f
	h = bit.intashex i
	while h.count < 8 do h = "0" + h        
	s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
	bit.intAsFloat (bit.hexasint s)
)   
--读取big endian 32bit有符号整数
fn ReadBElong fstream = (
	long = readlong fstream
	long = bit.swapBytes long 1 4
	long = bit.swapBytes long 2 3
	return long
)

fn ReadBEDword fstream = (
	long = readlong fstream #unsigned
	long = bit.swapBytes long 1 4
	long = bit.swapBytes long 2 3
	return long
)

--读取big endian 浮点数
fn ReadBEfloat fstream = (
	return floatSwap2(readfloat fstream)
)

fn readInt16 bstream = (
	if bigEndian then( return (ReadBEShort bstream))
	else (return (readshort bstream))
)
fn readUShort bstream = (
	if bigEndian then( return (ReadBEWord bstream))
	else (return (readshort bstream #unsigned))
)
fn readUInt16 bstream = (
	return (readUShort bstream)
)
fn readInt bstream = (
	if bigEndian then( return (ReadBELong bstream))
	else(return (readlong bstream))
)
fn readUInt bstream = (
	if bigEndian then( return (ReadBEDword bstream))
	else(return (readlong bstream #unsigned))
)
fn readInt32 bstream = (
	return (readInt bstream)
)
fn readUInt32 bstream = (
	return (readUInt bstream)
)
fn readSingle bstream = (
	if bigEndian then( return (ReadBEfloat fstream))
	else(return (readfloat bstream ))
)
--读取固定长度字符 不带填充类型 no padding type
fn ReadFixedStr bstream fixedLen =
(
   local str = ""
   for i = 1 to fixedLen do
   (
      str += bit.intAsChar (ReadByte bstream #unsigned)
   )
   str
)

--读取固定长度字符 带填充类型 have padding type
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
fn ReadColorARGB f = (
	colA = (readbyte f #unsigned)
	colR = (readbyte f #unsigned)
	colG = (readbyte f #unsigned)
	colB = (readbyte f #unsigned)
	return (color colR colG colB colA)
)
fn ReadColorRGBA f = (
	colR = (readbyte f #unsigned)
	colG = (readbyte f #unsigned)
	colB = (readbyte f #unsigned)
	colA = (readbyte f #unsigned)	
	return (color colR colG colB colA)
)


-- read little endian matrix44 to matrix43
fn readLEMatrix f = (
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
	m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
	tfm 
)

-- read big endian matrix44 to matrix43
fn readBEMatrix f = (
	m11 = readbefloat f; m12 = readbefloat f; m13 = readbefloat f; m14 = readbefloat f
	m21 = readbefloat f; m22 = readbefloat f; m23 = readbefloat f; m24 = readbefloat f
	m31 = readbefloat f; m32 = readbefloat f; m33 = readbefloat f; m34 = readbefloat f
	m41 = readbefloat f; m42 = readbefloat f; m43 = readbefloat f; m44 = readbefloat f
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
	tfm
)
fn ReadMatrix f =
(
	if not bigEndian then tfm = readLEMatrix f else tfm = readBEMatrix f
	tfm
)