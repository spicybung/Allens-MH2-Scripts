This is my Manhunt2 MDL Importer/Exporter script for 3dsMax.

How to Import:
==============
- This script support manhunt2 pc mdl, psp/ps2 dff format
- select the type of texture if you want to show/render it in MAX
- press 'Import Selected' button or on Objects list :double-click you want to import one.
  support import all clamps model.

How to Export:
==============
For example:

  If you want to replace a model in game.
  You first should be import you want to replace one.

  Check "Auto Skin". then press 'Import Selected' button.
  If model is a Skin object . importer will auto load skin info.
  If not auto load skin, this model is a non-skin object.
  You can use this way distinction Skin and Non-Skin objects.

  When import done!

  You should be go to "Schematic View(open)" , view and remember that you need to replace's(original) 
  parent bone/dummy.

  For Skin objcet:
    Align your model to original model.
    Match Bones Pos to your model!
    Go to Hierarchy Panel. click "Affect Pivot Only".
    Reset your model pivot as : Move(pos): [0,0,0] , Rotate:[0,0,0] ,Scale :[100,100,100];
    Or copy of the original model pivot.

    Delete old/original model.
    **Finish your skin work.
    Go to "Schematic View(open)" ,link your model to parent bone/dummy.

  For Non-Skin Object:
    Align your model to original model.
    Go to Hierarchy Panel. click "Affect Pivot Only".
    Reset your model pivot as : Move(pos): [0,0,0] , Rotate:[0,0,0] ,Scale :[100,100,100];
    Or copy of the original model pivot.

    Delete old/original model.
    Go to "Schematic View(open)" ,link your model to parent bone/dummy.

Please select root bone/dummy, then press "Export" button.

Exporter support ps2/psp dff model direct export to mdl.


About Custom Bone Properties
============================
Custom Bone Properties is for Advance User.

If you want make custom animation and add new custom weapon and ped etc... You can be use it.
Support import/export bone user-prop.you can freedom edit.
Support Reorder BoneID. If you add/delete some bones, BoneID must be need reorder.

MDL Format Description:
Please check the zip file "format" directory.

Boneprop.txt Parameter :

*******************
Number Bones=51
[Start]
BoneName =[Danny_Ingame-DAsy]
BoneIndex = 1
FirstInt = 0x3303a8
ObjectMatrix = 1
AnimFlag = 1
unknownFlag = 0xb9f800
BoneID = 65535
BoneType = 0x0
[END]
*******************

Description:

Note:***Do not change the uppercase and lowercase letters!!!

Number Bones=51                --- Number of bones , can't change
[Start]                        --- start mark
BoneName =[Danny_Ingame-DAsy]  --- Bone Name ,can't change
BoneIndex = 0                     --- BoneID,can't change. ID start at 0.If you add/delete bones and  want to modify, 
				   Please use "Reorder BoneID" Function and will auto add/reset "BoneIndex" properties.
                                   Per Bones/dummy have this properties. 

FirstInt = 0x3303a8            --- HEX Decimal.Int32. Per Bones/dummy have this properties. 
                                   Bone Struct first 4bytes(Int32) data.
                                   I don't know this what role, you can fill 0 or custom. 
                                   If not have this prop, exporter default fill 0.
                                   See MDL Format Description: Bone.unknown;
ObjectMatrix = 1               --- Object Bone Matrix flag; if == 1 is have .if not have,don't fill out.
                                   Only mesh's parent bone/dummy have this properties.
                                   Skin-Object general have this properties.***                                      
                                   See MDL Format Description: Object.BoneTransDataIndexOffset.

AnimFlag = 1                   --- Animation Data flag; if == 1 ,is have. if not have,don't fill out.
				   Skin-Object general have this properties.*** 
                                   Usually in the second bone(example: Bip01), but also have in other bones!!!
                                   See MDL Format Description:  Bone.AnimBoneDataIndexOffset;
                                                    AnimBoneDataIndex;
                                                    AnimBoneData;
                                   Data Include : BoneID, BoneType;

=====If AinmFlag != 1 ,The following property does not exist!=====

unknownFlag = 0xb9f800         --- HEX Decimal.Int32. If is AnimFlag == 1,then Only Root Bones/Dummy have this Properties. ***
                                   I don't know this what role, you can fill 0 or custom. 
                                   If not have this prop, exporter default fill 0.
                                   See MDL Format Description: AnimBoneDataIndex.unknown;

BoneID = 65535          --- HEX Decimal.Int16(2bytes). If is AnimFlag == 1, per bones have BoneID Properties.
                                   When AnimFlag ==1 ,if bone not have this prop, exporter can't export.
                                   model's parent bone/dummy and root bone have 65535（0xFFFF） key. other bones you can custom or see original bones.
                                   See MDL Format Description: AnimBoneData;

BoneType = 0x0                 --- HEX Decimal.Byte. If is AnimFlag == 1, per bones have BoneType Properties.
                                   When AnimFlag ==1 ,if bone not have this prop, exporter can't export.
                                   Modify you can reference: original bones.
                                   See MDL Format Description: AnimBoneData;

[END]                          --- end mark


How to use Max's Material:
============================
Only support Multimaterial and Standardmaterial.

Diffuse Color                           -> ingame color 
DiffuseMap                              -> ingame texture


How to use 2nd UV Map
=====================
UV2 channel is used to make blood flower splash area.
2nd UV Map is for Advance Max User. Go and get more tutorial on how to do UV Mapping with Max.

To enable 2nd UV Map. Simply place a Unwarp UVW modifier in Modifier Stack.
Select Map channel 2. if model not have UV2 ,you can copy UV1 to UV2. if have, In the pop-up window,select "abandon".
2nd UV will export form the modifier, don't collapse stack.
If have skin modifier. Should drag it to the "Skin modifier" the below.


Limitation:
- Number of Faces cannot change after "2nd UV Map" (Verts can). 
- If you collapse the Stack, you will lost 1st UV Map.
