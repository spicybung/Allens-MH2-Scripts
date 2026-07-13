Allen_Manhunt2_Scripts 说明
==================================================
本工具是一款针对侠盗猎魔2(Manhunt2) 的模型，动画，碰撞文件，3dsMAX导入导出脚本。
具有以下功能:
  导入:
         Manhunt 2 PC平台 MDL模型，侠盗猎魔2(Manhunt2) PSP/PS2/WII平台 DFF模型。
         Manhunt 1/2 动画文件IFP/BIN。
         Manhunt 1/2 碰撞模型文件COL。
         Manhunt 1 PC平台DFF文件模型。
  导出:
         Manhunt 2 PC平台 MDL模型。
         Manhunt 1/2 动画文件IFP二进制和json文本格式。
         Manhunt 1/2 碰撞模型文件COL。

欢迎反馈和举报BUG。谢谢！

Allen_Manhunt2_Scripts  运行环境
------------
3dsMax8及以上版本
.NET framework 4.0 或更高版本

信息
-----------
软件名称: Allen_Manhunt2_Scripts
最新版本发布日期: 2021年09月21日
最初版本发布日期: 2013年9月26日

作者信息
------------------
 作者  : Allen
 E-mail: Leeao@live.com

如何安装并运行:
-----------
把所有文件放到你的3dsMAX目录下的scripts文件夹内。
当你启动MAX，脚本将自动运行在工具（Utility）面板。

已知问题：
-----------
PSP/PS2平台有些模型，面的方向是反的。你需要手工翻转面的法线去修复模型。

感谢
-----------
Fatduck
MAJEST1C_R3
41hc1

更新记录
-----------
2021-09-21
           添加支持Manhunt1和Manhunt2的动画互相转换。
           添加新的模型优化/顶点焊接算法。
           添加新的平滑法线算法。
           mh2tools.exe 小工具添加对Manhunt1 TXD（PC，PS2）和Manhunt2 TXD/TEX (PC,WII,PSP,PS2)的图像提取支持。
           修复一些BUG。

2019-11-02
           添加IFP动画文件导入导出
           添加COL碰撞模型导入导出
           添加侠盗猎魔1(Manhunt)模型DFF导入，支持骨骼蒙皮
           添加MDL模型文件批量导出功能。

2018-09-15
           修复一些BUG。

2015-10-26 发布 v1.3
           添加了一个新的焊接顶点算法。
           改进重新计算法线算法。
           修复一个模型透明BUG。
           修复一些小错误。

2015-10-1  发布 v1.2
           添加WII平台DFF版本模型导入脚本。
           优化了法线数据输入输出。
           添加焊接UV功能，去除冗余数据。

2015-9-10  发布 v1.1
           修复UV2导出错误，主要更新。
           修复材质问题，自动剔除无用材质。
           修复导出无效蒙皮权重问题。

2014-10-25 Release v1.0
           Add MDL Exporter.
           Add Z2HM/MH2Z Resources Manager. You can freedom decompress/compress manhunt2 Z2HM Resources(for example: *.mdl,*tex,*.ifp..etc).           
           Importer Add Welding vertices smooth model feature.
           Add 2nd UV Map import/export.
           Add support custom bone type export(For example: Custom animation,specify animkey ID. Add new custom weapon and ped etc..).
           Change unpack .tex to dds textures ways.
           Change importer decompress ZLIB/Z2HM  Resources ways. All MAX versions can be used.

2014-7-28  Release v0.9
           Thanks 41hc1 Bug Reports.
           Fixed import crash. Changed the way the bones import.
 
2014-7-27  Release v0.8
           Add PS2/PSP *.DFF Model File Support! Mesh,UV,Bone,Skin,Texture,VertColor!
           Optimized PC MDL version code!
           Thanks MAJEST1C_R3 provided  PS2 format information.

2014-2-18  Release v0.6
           Fixed Skin Info Error, Thanks Majestic Report bug!

2014-2-17  Release v0.5
           Add older version 3dsmax support, older version don't need .net *.dll file.single run. 
           Note: need decompress MDL file.Can use Manthun2MDLEditor Decompress.

           fixed VertexColor error
           Add Model Normal support

2013-10-4  Release v0.2
           Fixed Import All Model Error. Add one type model support.
           Add support VertexColor and On/Off Auto show textures.

2013-9-26  Release v0.1
           Support for multiple material
           Supports auto show texture
           The default is automatically applied *.MDL file in the same directory textures,support. DDS. PNG. TGA or .BMP format.
           Support Bones/Skin
           Support multiple Mesh import
           Support .TEX format image batch unpack (DDS format)