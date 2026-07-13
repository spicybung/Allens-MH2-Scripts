global AllenMH1DFF_Tool
fileIn ("DFFimp.ms") quiet:true

if AllenMH1DFF_Tool != undefined then (
	closeRolloutFloater AllenMH1DFF_Tool
)
AllenMH1DFF_Tool = newRolloutFloater "DFF Importer" 220 600 10 50	
addRollout DFFImportUI AllenMH1DFF_Tool rolledup:false
addRollout MHTXDRollout AllenMH1DFF_Tool rolledup:false
addRollout DFFAboutRoll AllenMH1DFF_Tool rolledup:false	