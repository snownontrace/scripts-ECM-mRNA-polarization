macroName = "/Volumes/ShaoheGtech2/_Gtech-SMG-ECM-mRNA-polarization-secretion-paper/scripts-ECM-mRNA-polarization-secretion-paper/fixed-images-general-for-smFISH-for-folders-201117.ijm";

//dir = getDirectory("Choose the parent folder containing folders to process:");
dir = "/Volumes/ShaoheGtech2/_Gtech-SMG-ECM-mRNA-polarization-secretion-paper/data/Fig3-polarization-cytoskeletal-drugs/201117-smFISH-Col4a1-TMR-cytoskeletal-inhibitors-collagenase/";
fList = getFileList(dir);

// For processing folders NOT ending with "output"
for (i=0; i<fList.length; i++) {
	if ( File.isDirectory(dir + fList[i]) ) {
		if ( !( endsWith(fList[i], "output"+File.separator) ) ) {
				runMacro(macroName, dir + fList[i]);
		}
	}
}

//// For processing folders ending with "output"
//for (i=0; i<fList.length; i++) {
//	if ( File.isDirectory(dir + fList[i]) ) {
//		if ( endsWith(fList[i], "output"+File.separator) ) {
//				runMacro(macroName, dir + fList[i]);
//		}
//	}
//}