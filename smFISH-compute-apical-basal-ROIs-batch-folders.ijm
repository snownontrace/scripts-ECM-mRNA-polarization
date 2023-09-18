macroName = "/Volumes/wangs6/_PRFS-SMG-ECM-mRNA-polarization-secretion-paper/scripts-ECM-mRNA-polarization-secretion-paper/smFISH-compute-apical-basal-ROIs-for-batch.ijm";

dir = getDirectory("Choose the parent folder containing folders to process:");
fList = getFileList(dir);

// For processing folders ending with "output"
for (i=0; i<fList.length; i++) {
	if ( File.isDirectory(dir + fList[i]) ) {
//	if ( File.isDirectory(fList[i]) ) {
		if ( endsWith(fList[i], "output" + File.separator) ) {
			ROI_folder = dir + fList[i] + "ROIs" + File.separator;
			if ( File.isDirectory(ROI_folder) ) {
				print(fList[i]);
				runMacro(macroName, ROI_folder);
			}
		}
	}
}