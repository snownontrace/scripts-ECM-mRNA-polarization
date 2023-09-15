macroName = "/Users/wangs20/Box/Shaohe-Box-Yamada-Lab/_SMG-ECM-mRNA-polarization-secretion-paper/scripts-ECM-mRNA-polarization-secretion-paper/fixed-images-general-for-smFISH-for-folders.ijm";
//macroName = "/Users/wangs20/Github/Imaging/makeMontageFromImageSequence.ijm";
//macroName = "/Users/wangs20/Github/Imaging/spheroids-processing-add-temp-for-batch.ijm";
//macroName = "/Users/wangs20/Github/Imaging/count_cells_get_argument.ijm";
//macroName = "/Users/wangs20/Github/Imaging/fixed-images-general-get-arguments.ijm";
//macroName = "/Users/wangs20/Github/Imaging/bioFormats-Split-Positions-Get-Arguments.ijm";

dir = getDirectory("Choose the parent folder containing folders to process:");
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