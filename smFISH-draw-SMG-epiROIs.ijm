clean_up_workspace();

inputFolder = getDirectory("Choose the folder containing images to process:");
// Create an output folder based on the inputFolder
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-output" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }
ROIfolder = outputFolder + "ROIs" + File.separator;
if ( !(File.exists(ROIfolder)) ) { File.makeDirectory(ROIfolder); }

setBatchMode(false);
fList = getFileList(inputFolder);
for (i=0; i<fList.length; i++) {
	f = fList[i];
	if ( endsWith(f, File.separator) || startsWith(f, ".") || startsWith(f, "~") || startsWith(f, "_") ) { continue; } //skip if f is a folder, or system files
	filenamePrefix = getPathFilenamePrefix(f);
	epiMask = ROIfolder + filenamePrefix + "-epiMask.tif";
	if (File.exists(epiMask)) { continue; }
	open(inputFolder + f);
	getPixelSize(unit, pixelWidth, pixelHeight);
	getDimensions(width, height, channels, slices, frames);
	
	for (c=1; c<channels+1; c++) {
		Stack.setChannel(c);
		run("Enhance Contrast", "saturated=0.35");
	}
	
	// expand canvas to facilitate drawing around epithelial ROI
	new_w = width + 200;
	new_h = height + 200;
	run("Canvas Size...", "width="+new_w+" height="+new_h+" position=Center zero");
	
	makeRectangle(100, 100, width, height);
	roiManager("Add"); // original image ROI; # 0
	
	run("Select None");
	
	setTool("polygon");
	waitForUser("Draw a polygon around epithelial ROI.\nExpand beyond the image to get it all.\nClick OK to continue");
	roiManager("Add"); // explanded epithelial ROI; # 1
	
	roiManager("Select", newArray(0,1));
	roiManager("AND");
	roiManager("Add"); // intersected epithelial ROI; # 2
	
	newImage("mask", "8-bit black", new_w, new_h, 1);
	roiManager("Select", 2);
	setForegroundColor(255, 255, 255);
	run("Fill", "slice");
	run("Invert LUT");
	
	roiManager("Select", 0);
	run("Duplicate...", " ");
	epiMaskID = getImageID();
	
	if (unit == "microns") {
		selectImage(epiMaskID);
		run("Set Scale...", "distance=1 known="+pixelWidth+" unit=microns");
	}
	else {
		print("Scaling problem in "+f);
		print("Please check image scaling!");
//		print("WARNING: pixel size is not in microns. Check image scaling.");
	}
	
	
	saveAs("tiff", epiMask);
	
	run("Close All"); run("Collect Garbage"); // Release occupied memory
	roiManager("reset");
}


showMessage("Find saved ROIs in the \"ROIs\" folder inside the output folder.");

function clean_up_workspace() {
	// Clean up workspace
	run("Close All"); run("Collect Garbage"); // Release occupied memory
	if ( isOpen("Synchronize Windows") ) { selectWindow("Synchronize Windows"); run("Close"); }
	if ( isOpen("Log") ) { selectWindow("Log"); run("Close"); }
	if ( isOpen("Debug") ) { selectWindow("Debug"); run("Close"); }
	if ( isOpen("Results") ) { selectWindow("Results"); run("Close"); }
	if ( isOpen("ROI Manager") ) { roiManager("reset"); selectWindow("ROI Manager"); run("Close"); }
	setTool("rectangle");
	setForegroundColor(255, 255, 255);
	setBackgroundColor(0, 0, 0);
}

function getFilenamePrefix(filename) {
	// this one takes just the file name without folder path
	temp = split(filename, ".");
	return temp[0];
}

function getPathFilenamePrefix(pathFileOrFolder) {
	// this one takes full path of the file of folder
	temp = split(pathFileOrFolder, File.separator);
	temp = temp[temp.length-1];
	temp = split(temp, ".");
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