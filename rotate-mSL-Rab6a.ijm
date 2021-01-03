Saturation = 2.0;
w= 220; h = 220;// selection size

inputFolder = getDirectory("Choose the folder containing images to process:");
// Create an output folder based on the inputFolder
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-rotated" + File.separator;
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

		setBackgroundColor(0, 0, 0);//fill with black
		run("Enhance Contrast", "saturated="+Saturation);

		setTool("line");
		waitForUser("Draw a line apical to basal:");
		run("Clear Results");
		run("Measure");
		lineAngle = getResult("Angle", 0) + 90;
		run("Select None");
		run("Rotate...", "angle="+lineAngle+" interpolation=Bilinear enlarge stack");
		
		filenameParts = split(flist[i],".");
		makeRectangle(0, 0, w, h);
		waitForUser("Now move around the rectangular selection");
		run("Duplicate...", "duplicate");
		saveAs("Tiff", outputFolder+filenameParts[0]+".tif");
		
		run ("Close All");
		run("Clear Results");
		setBackgroundColor(0, 0, 0);//reset black background color
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