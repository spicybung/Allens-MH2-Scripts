utility Allen_Scripts "Allen's Manhunt 2 Scripts" 
(
	button script01 "MDL IO" width:140 align:#center 
	button script02 "IFP IO" width:140 align:#center 
	button script03 "COL IO" width:140 align:#center
	on script01 pressed do (
		try ( fileIn (scriptspath+"\\Manhunt2_Tools\\MDL_IO.ms") quiet:true   )
		catch messagebox "Please re-install my MDL IO script!" title:"Can't find MDL IO script"
	)
	on script02 pressed do(
		try (filein  (scriptspath+"\\Manhunt2_Tools\\IFP_IO.ms") quiet:true)
		catch messagebox "Please re-install my IFO IO script!" title:"Can't find IFO IO script"
	)
	on script03 pressed do (
		try ( fileIn (scriptspath+"\\Manhunt2_Tools\\COL_IO.ms") quiet:true   )
		catch messagebox "Please re-install my COL script!" title:"Can't find COL IO script"
	)
	group "Manhunt 1"(
	button script05 "DFF Import" width:140 align:#center
	)	
	on script05 pressed do (
		try ( fileIn (scriptspath+"\\Manhunt2_Tools\\DFFUI.ms") quiet:true   )
		catch messagebox "Please re-install my DFF script!" title:"Can't find DFF script"		
	)
)
openUtility Allen_Scripts