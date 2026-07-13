Allen_Manhunt2_Scripts: README
==================================================
This tool is a model file, animation file, collision file, 3dsMAX import and export script for Manhunt2.
Support:
  Import:
         Manhunt 2    MDL (PC)，DFF (PSP/PS2/WII) model file
         Manhunt 1/2 IFP Animation file
         Manhunt 2    BIN Animation file
         Manhunt 1/2 COL collision file
         Manhunt 1    DFF model file
  Export:
         Manhunt 2 MDL
         Manhunt 1/2 IFP binary animation file / json text file
         Manhunt 1/2 COL collision file

Welcome Feedback & Bug Reports. Thanks!

Allen_Manhunt2_Scripts Requirement:
------------
3dsMax 8  or Higher
.NET framework 4.0 or Higher

Information
-----------
Program Name: Allen_Manhunt2_Scripts
Revision Version Release Date: Sep 21, 2021
First Version  Release Date:9/26/2013

Author information
------------------
 Author: Allen
 E-mail: Leeao@live.com

How to Install & Run:
-----------
Place all files into: your %Max%\scripts\ folder.
When you start MAX, The script will auto run at Utility Panel.

Known issue:
-----------
PSP/PS2 some models of the face direction is reversed. You need to manually flip the face normal to fix it.

Thanks
-----------
Fatduck
MAJEST1C_R3
41hc1

Changelogs
-----------
2021-09-21
           Added support for converting between Manhunt1 and Manhunt2 animations.
           Add new model optimization/vertex welding algorithm.
           Add a new smoothing normal algorithm.
           The mh2tools.exe adds support for Manhunt1 TXD (PC, PS2) and Manhunt2 TXD/TEX (PC, WII, PSP, PS2) image extraction.
           Fixed some bugs

2019-11-02
           Add IFP Animation importer/exporter. Support binary animation file / json text file
           Add Col collision file importer/exporter.
           Add Manhunt 1 DFF model Importer.
           Add Manhunt 2 MDL file batch export.

2018-09-15 
           Fixed some bugs

2015-10-26 Release v1.3
           Add a new welding vertex algorithms.
           Improved algorithm to recalculate normals.
           Fixed a model transparent BUG.
           Fixed some minor issues.

2015-10-1  Release v1.2
           Added WII DFF Importer.
           Optimize the normal data input and output.

           Added welding uv data feature, remove redundant data.

2015-9-10  Release v1.1
           Fixed UV2 export errors, major updates.
           Fixed material problem, automatically remove unwanted materials.
           Fixed export invalid skin weight problems.

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