macroName = "/Users/wangs20/Box/Shaohe-Box-Yamada-Lab/_SMG-ECM-mRNA-polarization-secretion-paper/scripts-ECM-mRNA-polarization-secretion-paper/smFISH-compute-polarization-index.ijm";

dir = getDirectory("Choose the parent folder containing folders to process:");
fList = getFileList(dir);

// For processing folders ending with "preprocessed"
for (i=0; i<fList.length; i++) {
	if ( File.isDirectory(dir + fList[i]) ) {
//	if ( File.isDirectory(fList[i]) ) {
		if ( endsWith(fList[i], "preprocessed" + File.separator) ) {
			runMacro(macroName, dir + fList[i]);
		}
	}
}