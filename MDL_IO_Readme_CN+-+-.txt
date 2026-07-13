Manhunt2 MDL 模型格式导入导出3dsMAX脚本


如何导入：
==============
- 脚本支持 Manhunt2 PC MDL格式， PSP/PS2 DFF格式。
- 选择你要在MAX里面显示的贴图后缀类型
- 在Object列表点击'Import Selected'按钮导入，双击也可以导入。支持多模型集导入。

如何导出：
==============

举例：

  如果你想替换一个游戏模型。
  你首先需要导入你想替换的这个模型。


  点击“Auto Skin”自动蒙皮。 然后点击'Import Selected'按钮导入。
  如果模型是个带蒙皮的物体，导入脚本将自动加载蒙皮信息。
  如果没有自动加载蒙皮，那么这个模型是个非蒙皮物体。
  你可以使用这个方法区分带蒙皮和非蒙皮物体。

  当导入完成！

  你应该去 “Schematic View(open)”（层级视图），查看并记住你想替换的模型的父级骨骼或虚拟体Dummy。


  对于带蒙皮物体：
    对齐你的模型到原人物模型，然后把原骨骼匹配到你的模型。
    去Hierarchy(层级)面板。点击 “Affect Pivot Only”（只影响轴点）。
    重设你的模型轴点为： Move(pos): [0,0,0] , Rotate:[0,0,0] ,Scale :[100,100,100];
    或者复制原模型轴点。
    删除原模型。
    **完成你的蒙皮工作。
    去“Schematic View(open)”（层级视图），连接你的模型到原人物模型的父级骨骼或虚拟体Dummy。

  对于非蒙皮物体：
    对齐你的模型到原人物模型。
    去Hierarchy(层级)面板。点击 “Affect Pivot Only”（只影响轴点）。
    重设你的模型轴点为： Move(pos): [0,0,0] , Rotate:[0,0,0] ,Scale :[100,100,100];
    或者复制原模型轴点。
    删除原模型。
    去“Schematic View(open)”（层级视图），连接你的模型到原人物模型的父级骨骼或虚拟体Dummy。


然后选择根骨骼/虚拟体Dummy，然后点击“Export”导出按钮，完成导出！

导出脚本支持 PS2/PSP DFF格式模型，导入后，直接导出。（别忘了勾选"Auto Skin"自动蒙皮）

Custom Bone Properties
关于自定义骨骼属性
============================

自定义骨骼属性适用于高级用户。
如果你想制作自定义动画和添加新武器，人物等， 你可以使用这个功能。
支持导入导出骨骼用户自定义属性，你可以自由编辑。
支持重新排序骨骼ID（BoneID)属性，如果你添加/删除一些骨骼，骨骼ID必须重新排序。

MDL 格式说明请查看压缩包format目录里面。


Boneprop.txt 参数 :

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

说明:

注意:***不要改变参数字母的大小写，否则脚本无法获取属性，导致导出失败!!!

Number Bones=51                --- 骨骼数量，无法更改
[Start]                        --- 起始标志
BoneName =[Danny_Ingame-DAsy]  --- 骨骼名称，无法更改
BoneIndex = 0                     --- BoneID,无法更改. ID从0开始。如果你添加/删除骨骼并想修改ID，
				   请使用 "Reorder BoneID" 功能，脚本将自动添加/重设“BoneIndex”属性。 
                                   每个骨骼/虚拟体都必须含有这个属性。

FirstInt = 0x3303a8            --- 十六进制.Int32.  每个骨骼/虚拟体都必须含有这个属性。
                                   骨骼结构首个4字节数据。
                                   我不知道作用，你可以用0填充，或者自定义。 
                                   如果没有这个属性，导出脚本将默认用0填充。
                                   详见MDL格式说明: Bone.unknown;



ObjectMatrix = 1               --- 模型自带矩阵变换标志; 如果等于1代表有，如果没有就不要填写。
                                   如果网格模型含有自带矩阵，那么就赋予模型的父级骨骼或虚拟体含有这个属性。
                                   建议参考原模型修改。基本上每个人物模型都有这个属性。
                                   蒙皮物体一般都有这个属性。***                                      
                                   详见MDL格式说明: Object.BoneTransDataIndexOffset.

AnimFlag = 1                   --- 动画数据标志; 如果等于1代表有，如果没有就不要填写。
				   蒙皮物体一般都有这个属性。***   
                                   通常在第二个骨骼（例如: Bip01）,但是也有在其他骨骼的情况，可以参考原模型修改!!!
                                   详见MDL格式说明: Bone.AnimBoneDataIndexOffset;
                                                    AnimBoneDataIndex;
                                                    AnimBoneData;
                                   数据包括: BoneID, BoneType;

=====如果AinmFlag不等于1 ,下面这些属性将不存在！！！=====


unknownFlag = 0xb9f800         --- 十六进制.Int32.  如果AnimFlag等于1,然后只有根骨骼/根虚拟体含有这个属性。 ***
                                   我不知道这个什么作用，你可以用0填充，或者自定义。 
                                   如果没有这个属性，导出脚本将默认用0填充。
                                   详见MDL格式说明: AnimBoneDataIndex.unknown;

BoneID = 65535          --Int16(2字节).如果AnimFlag等于1,则每个骨骼都含有 BoneID  这个属性。
                                   当AnimFlag等于1 ,如果骨骼没有这个属性，导出脚本将无法导出。
                                   网格模型的父级骨骼/虚拟体和根骨含有65535(0xFFFF) key。其他骨骼你可以参考原骨骼或者自定义。
                                   详见MDL格式说明: AnimBoneData;

BoneType = 0x0                 --- 十六进制.Byte 1字节.如果AnimFlag等于1,则每个骨骼都含有BoneType这个属性。
                                   当AnimFlag等于1 ,如果骨骼没有这个属性，导出脚本将无法导出。
                                   想修改你可以参考原骨骼数据。
                                   详见MDL格式说明: AnimBoneData;

[END]                          --- 结束标志


如何使用MAX材质。
============================
只支持多维材质和标志材质。（Multimaterial 和 Standardmaterial）

Diffuse Color（漫反射颜色）                           -> 在游戏里的颜色
DiffuseMap（漫反射贴图）                              -> 在游戏里的贴图


如果使用UV通道2
=====================
UV2通道是用来制作游戏中模型血花喷溅的区域。
UV通道2适用于高级MAX用户。你可以去网上搜索更多关于MAX使用UV通道2的教程。

启用UV通道2，在堆栈给模型添加一个Unwarp UVW修改器。
选择UV通道2，如果模型没有有UV通道2数据，你可以复制UV1到UV2，如果有，在弹出的窗口中选择放弃移动复制。
UV通道2将通过这个修改器导出数据，不要塌陷堆栈。
如果模型有蒙皮修改，你应该把Unwarp UVW修改器拖到蒙皮修改器下边。


游戏使用UV2是因为需要人物模型上带有血花效果。

限制:
- 添加Unwarp UVW修改器后，不要更改面数。顶点数量可以改。
- 如果你塌陷堆栈，模型将丢失UV1数据。
