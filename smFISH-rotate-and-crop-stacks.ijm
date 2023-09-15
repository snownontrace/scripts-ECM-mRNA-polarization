saturation = 0.3;
//scale_factor = 0.5;
w= 150; h = 300;// selection size

inputFolder = getDirectory("Choose the folder containing images to process:");
// Create an output folder based on the inputFolder
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-rotated-cropped" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

flist = getFileList(inputFolder);

//setBatchMode(true);
run("Close All");
run("Clear Results");

//for (i=0; i<flist.length; i++) {
for (i=95; i<flist.length; i++) {
	showProgress(i+1, flist.length);
	filename = inputFolder+flist[i];
	outputPrefix = getFilenamePrefix(flist[i]);
	if ( endsWith(filename, ".nd2") || endsWith(filename, ".tif") ) {
		open(filename); id0 = getImageID();
		run("Z Project...", "projection=[Max Intensity]"); idMIP = getImageID();

		selectImage(idMIP);
		Stack.setChannel(1); run("Enhance Contrast", "saturated="+saturation);

		// Draw a line to determine the angle to rotate
		setTool("line");
		waitForUser("Draw a line basal to apical:");
		run("Clear Results");
		run("Measure");
		lineAngle = getResult("Angle", 0) - 90;
		
		// Rotate both MIP and original images
		selectImage(id0);run("Select None");
		run("Rotate...", "angle="+lineAngle+" interpolation=Bilinear enlarge stack");
		selectImage(idMIP);run("Select None");
		run("Rotate...", "angle="+lineAngle+" interpolation=Bilinear enlarge stack");

		// Draw a bounding box of the cell to qantify
		setTool(0); // rectangle
		selectImage(idMIP); makeRectangle(0, 0, w, h);
		waitForUser("Adjust the rectangular selection");

		selectImage(id0); run("Restore Selection"); run("Duplicate...", "duplicate"); idDup = getImageID();
		saveAs("Tiff", outputFolder+outputPrefix+'.tif');
		
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