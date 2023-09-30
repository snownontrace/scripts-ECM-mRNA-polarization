// Clean up workspace
run("Close All"); run("Collect Garbage"); // Release occupied memory
//if ( isOpen("Synchronize Windows") ) { selectWindow("Synchronize Windows"); run("Close"); }
//if ( isOpen("Log") ) { selectWindow("Log"); run("Close"); }
//if ( isOpen("Debug") ) { selectWindow("Debug"); run("Close"); }
//if ( isOpen("Results") ) { selectWindow("Results"); run("Close"); }
//if ( isOpen("ROI Manager") ) { selectWindow("ROI Manager"); run("Close"); }

// Specify control parameters
saturation = 2.5;
color_code_LUT = "glasbey on dark";

// Specify folders
inputFolder = getDirectory("Choose the folder containing images:");
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-temporal_color_code" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

// Turn on the batch mode (not showing images to speed up the processing)
setBatchMode(false);

fList = getFileList(inputFolder);
for (i=0; i<fList.length; i++) {
	f = fList[i];
	filenamePrefix = getPathFilenamePrefix(f);
//	if ( endsWith(f, File.separator) || startsWith(filenamePrefix, ".") || startsWith(filenamePrefix, "~") || startsWith(filenamePrefix, "_") ) { continue; } //skip if f is a folder, or system files
	if ( endsWith(f, ".tif") ) {
		open(inputFolder + f); id0=getImageID();
		run("Enhance Contrast", "saturated="+saturation);
		run("Temporal-Color Code", "lut=["+color_code_LUT+"] start=1 end=120"); id1=getImageID();
		selectImage(id0); run("Close");
		selectImage(id1); saveAs("tiff", outputFolder + filenamePrefix + ".tif");
		run("Close All");
	}
}

function getPathFilenamePrefix(pathFileOrFolder) {
	// this one takes full path of the file
	temp = split(pathFileOrFolder, File.separator);
	temp = temp[temp.length-1];
	temp = split(temp, ".");
	return temp[0];
}

function getFilenamePrefix(filename) {
	// this one takes just the file name without folder path
	temp = split(filename, ".");
	return temp[0];
}

function getPath(pathFileOrFolder) {
	// this one takes full path of the file (input can also be a folder)
	temp = split(pathFileOrFolder, File.separator);
	if ( File.separator == "/" ) {
	// Mac and unix system
		pathTemp = File.separator;
		for (i=0; i<temp.length-1; i++) {pathTemp = pathTemp + temp[i] + File.separator;}
	}
	if ( File.separator == "\\" ) {
	// Windows system
		pathTemp = temp[0] + File.separator;
		for (i=1; i<temp.length-1; i++) {pathTemp = pathTemp + temp[i] + File.separator;}
	}
	return pathTemp;
}