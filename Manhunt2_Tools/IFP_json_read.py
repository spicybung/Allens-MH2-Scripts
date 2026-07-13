import json
import os
import struct
from collections import OrderedDict
from pymxs import runtime as rt

def getJsonFileName():

    jsonFileName = rt.execute('''getopenfilename caption:"Json File" types:"JsonFile (*.json)|*.json|"''')

    return jsonFileName



def readJson(jsonFileName):
    jsonStr = None
    if jsonFileName != None:
        with open(jsonFileName) as f:
            jsonStr = f.read()   
    if jsonStr == None:
        return None

    path = os.path.dirname(jsonFileName)
    animName = os.path.basename(jsonFileName).split('.')[0] + ".anim"
    outAnimFileName = os.path.join(path,animName)
    #print(outAnimFileName)
    f = open(outAnimFileName, "wb")


    data = json.loads(jsonStr,object_pairs_hook=OrderedDict)
    frameTimeCount = list(data)[0]

    frameTimeCount = data['frameTimeCount']
    bones =  list(data['bones'])
    #print(data['bones'][0]['frames']['lastFrameTime'])
    
    numBones = len(bones)
    versionStr = data['unknown5']

    if versionStr == "00000040": version = 1
    elif versionStr == "00004040": version = 2
    
    chunkSizePointer = f.tell() + 4
    chunkSize = 0

    f.write(struct.pack('IIf',numBones,0,frameTimeCount/30.0))

    for i in range(numBones):
        boneID = bones[i]['boneId']
        frameType = bones[i]['frameType']
        startTime = bones[i]['startTime']
        frames = bones[i]['frames']
        framesList = list(frames['frames'])
        
        #print(boneID,frameType,startTime,lastFrameTime)
        if version == 1: f.write(struct.pack('I',0x55514553))   #SEQU Manhunt 1
        elif version == 2: f.write(struct.pack('I',0x54514553)) #SEQT Manhunt 2
        f.write(struct.pack('h',boneID))
        f.write(struct.pack('B',frameType))
        f.write(struct.pack('h',len(framesList)))
        #print("framesList Length:",len(framesList))
        chunkStartOfs = f.tell()
        f.write(struct.pack('h',int((startTime / 30.0) * 2048)))
        if frameType > 2 :
            qx,qy,qz,qw =  bones[i]['direction']
            #print(qx,qy,qz,qw)
            f.write(struct.pack('hhhh',int(qx*4096),int(qy*4096),int(qz*4096),int(qw*4096)))
        elif startTime == 0: f.seek(chunkStartOfs)

        for j in range(len(framesList)):
                if startTime == 0:
                    if frameType == 3 and j == 0:() #just skip
                    else:
                        time = framesList[j]['time']
                        f.write(struct.pack('h',int((time / 30.0 )*2048)))
                if frameType < 3:
                    qx,qy,qz,qw =  framesList[j]['quat']
                    #print(qx,qy,qz,qw)
                    f.write(struct.pack('hhhh',int(qx*4096),int(qy*4096),int(qz*4096),int(qw*4096)))
                if frameType > 1:
                    tx,ty,tz = framesList[j]['position']
                    f.write(struct.pack('hhh',int(tx*2048),int(ty*2048),int(tz*2048)))
        chunkSize += f.tell() - chunkStartOfs
        if version == 2: 
            lastFrameTime = frames['lastFrameTime']
            f.write(struct.pack('f',lastFrameTime))
    f.write(struct.pack('i',0x10))
    if version == 1:
        f.write(struct.pack('fi',2,64))
    elif version == 2:
        f.write(struct.pack('fi',3,160))
    entry = list(data['entry'])
    f.write(struct.pack('I',len(entry)))
    for i in range(len(entry)):
        if version == 2:
            f.write(struct.pack('f',entry[i]['time']))
            f.write(bytes.fromhex(entry[i]['unknown']))
            f.write(bytes.fromhex(entry[i]['unknown2']))
            CommandName = entry[i]['CommandName']
            cmdNameBytes = CommandName.encode()
            for s in range(0,64):
                if len(cmdNameBytes):
                    if s < len(cmdNameBytes):
                        f.write(struct.pack('B',cmdNameBytes[s]))                        
                    else:
                        f.write(struct.pack('b',0))                        
                else:
                    f.write(struct.pack('b',0))
            f.write(bytes.fromhex(entry[i]['unknown3']))
            f.write(struct.pack('f',entry[i]['unknown6'])) #BoneID
            particleNameBytes = entry[i]['particleName'].encode()
            #print(entry[i]['particleName'])
            #print(particleNameBytes)
            for s in range(0,8):
                if len(particleNameBytes):
                    if s < len(particleNameBytes):
                        f.write(struct.pack('B',particleNameBytes[s]))                        
                    else:
                        f.write(struct.pack('b',0))
                else:
                    f.write(struct.pack('b',0))
            tx,ty,tz,qx,qy,qz,qw = entry[i]['particlePosition']
            f.write(struct.pack('fffffff',tx,ty,tz,qx,qy,qz,qw))
            f.write(bytes.fromhex(entry[i]['unknown5'])) #40 bytes
        elif version == 1:
            f.write(struct.pack('f',entry[i]['time']))
            f.write(bytes.fromhex(entry[i]['unknown']))
            f.write(bytes.fromhex(entry[i]['unknown2']))
            f.write(bytes.fromhex(entry[i]['unknown3']))
            f.write(bytes.fromhex(entry[i]['unknown4']))
            f.write(struct.pack('f',entry[i]['unknown6'])) #BoneID
            particleNameBytes = entry[i]['particleName'].encode()
            for s in range(0,8):
                if len(particleNameBytes):
                    if s < len(particleNameBytes):
                        f.write(struct.pack('B',particleNameBytes[s]))
                    else:
                        f.write(struct.pack('b',0))                        
                else:
                    f.write(struct.pack('b',0))
            tx,ty,tz,qx,qy,qz,qw = entry[i]['particlePosition']
            f.write(struct.pack('fffffff',tx,ty,tz,qx,qy,qz,qw))
            f.write(bytes.fromhex(entry[i]['unknown5'])) #int


    f.seek(chunkSizePointer)
    f.write(struct.pack('I',chunkSize))


    f.close()
    return outAnimFileName
def getAnimFileName():    
    jsonFileName = getJsonFileName()
    outAnimFileName = readJson(jsonFileName)
    if outAnimFileName != None:
        return outAnimFileName
    else:
        return 0


animFileName = getAnimFileName()
