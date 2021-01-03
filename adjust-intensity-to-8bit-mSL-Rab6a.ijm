Saturation = 5.0;

inputFolder = getDirectory("Choose the folder containing images to process:");
// Create an output folder based on the inputFolder
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-8bit" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

flist = getFileList(inputFolder);

//setBatchMode(true);

run ("Close All");
run("Clear Results");

for (i=0; i<flist.length; i++) {
	showProgress(i+1, flist.length);
	filename = inputFolder+flist[i];
	if ( endsWith(filename, ".tif") || endsWith(filename, ".nd2") ) {
		open(filename);

		run("Enhance Contrast", "saturated="+Saturation);
		waitForUser("Adjust intensity");
		
		run("8-bit");
		filenameParts = split(flist[i],".");
		saveAs("Tiff", outputFolder+filenameParts[0]+"-8bit.tif");
		
		run ("Close All");
		run("Clear Results");
	}
}

function getPath(pathFileOrFolder) {
	// this one takes full path of the file (input can also be a folder) and returns the parent folder path
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