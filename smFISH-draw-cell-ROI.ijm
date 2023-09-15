// Clean up workspace
run("Close All"); run("Collect Garbage"); // Release occupied memory
if ( isOpen("Synchronize Windows") ) { selectWindow("Synchronize Windows"); run("Close"); }
if ( isOpen("Log") ) { selectWindow("Log"); run("Close"); }
if ( isOpen("Debug") ) { selectWindow("Debug"); run("Close"); }
if ( isOpen("Results") ) { selectWindow("Results"); run("Close"); }
if ( isOpen("ROI Manager") ) { selectWindow("ROI Manager"); run("Close"); }

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
//for (i=0; i<1; i++) { // for testing 1 image
	f = fList[i];
	if ( endsWith(f, File.separator) || startsWith(f, ".") || startsWith(f, "~") || startsWith(f, "_") ) { continue; } //skip if f is a folder, or system files
	filenamePrefix = getFilenamePrefix(f);
	ROIfile = ROIfolder + filenamePrefix + "-RoiSet.zip";
	if ( File.exists(ROIfile) ) { continue; } // skip if an ROI is already found

	// Make max intensity projection to draw cell ROI on
	open(f); id = getImageID();
	selectImage(id); run("In [+]"); run("In [+]");
	run("Z Project...", "projection=[Max Intensity]"); idMIP = getImageID();
	selectImage(idMIP); run("In [+]"); run("In [+]");
	run("Tile");
	
	// Draw polygon ROI around the cell
	selectImage(idMIP); Stack.setChannel(1);
	setTool("polygon");
	waitForUser("Draw a polygon around the cell.");
	roiManager("Add"); // ROI 0: whole cell ROI
	
	// Generate the apical and basal half ROIs
	selectImage(idMIP); Stack.getDimensions(width, height, channels, slices, frames);
	h1 = floor(height/2);
	h2 = height - h1;
	selectImage(idMIP); makeRectangle(0, 0, width, h1);
	roiManager("Add"); // ROI 1: apical half ROI
	selectImage(idMIP); makeRectangle(0, h1+1, width, h2);
	roiManager("Add"); // ROI 2: basal half ROI

	// Compute the apical and basal half of cell ROIs by intersection
	roiManager("Select", newArray(0,1));
	roiManager("AND");
	roiManager("Add"); // ROI 3: apical half of cell ROI
	roiManager("Select", newArray(0,2));
	roiManager("AND");
	roiManager("Add"); // ROI 4: basal half of cell ROI
	
	// Save the list of ROIs
	roiManager("Deselect");
	roiManager("Save", ROIfile);

	// Clean workspace
	roiManager("Reset");
	run("Close All");
}
setTool("rectangle");

showMessage("Find saved ROIs in the \"ROIs\" folder inside the output folder.");

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