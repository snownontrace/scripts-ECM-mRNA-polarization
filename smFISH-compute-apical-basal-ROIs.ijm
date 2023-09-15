clean_up_workspace();

half_cell_height = 7.5; // in microns; half the height of the outer bud epithelial cells

inputFolder = getDirectory("Choose the folder containing images to process:");
// Create an output folder based on the inputFolder
//parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
//outputFolder = parentFolder + inputFolderPrefix + "-output" + File.separator;
//if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }
//ROIfolder = outputFolder + "ROIs" + File.separator;
//if ( !(File.exists(ROIfolder)) ) { File.makeDirectory(ROIfolder); }

setBatchMode(true);
//setBatchMode(false);

fList = getFileList(inputFolder);
for (i=0; i<fList.length; i++) {
	f = fList[i];
	if ( endsWith(f, File.separator) || startsWith(f, ".") || startsWith(f, "~") || startsWith(f, "_") ) { continue; } //skip if f is a folder, or system files
	filenamePrefix = getFilenamePrefix(f);
	
	open(f); rename("epi"); id0 = getImageID();
//	setThreshold(255, 255); setOption("BlackBackground", false); run("Convert to Mask");
	id_expanded = expand_ROI(id0);// expand image to all directions and fill with mirror images
	
	id_shrunken_1 = shrink_ROI(id_expanded, half_cell_height);
	selectImage(id_shrunken_1); rename("shrunken_1");
	
	cell_height = half_cell_height*2;
	id_shrunken_2 = shrink_ROI(id_expanded, cell_height);
	selectImage(id_shrunken_2); rename("shrunken_2");
	
	imageCalculator("Subtract create", "epi", "shrunken_1"); id_basal = getImageID();
	basalMask = inputFolder + filenamePrefix + "-basalMask.tif";
	selectImage(id_basal); saveAs("tiff", basalMask);
	
	imageCalculator("Subtract create", "shrunken_1", "shrunken_2"); id_apical = getImageID();
	apicalMask = inputFolder + filenamePrefix + "-apicalMask.tif";
	selectImage(id_apical); saveAs("tiff", apicalMask);
	
	run("Close All"); run("Collect Garbage"); // Release occupied memory
	roiManager("reset");
}
setTool("rectangle");

//showMessage("Find saved ROIs in the \"ROIs\" folder inside the output folder.");

function shrink_ROI(id, shrinkWidth) {
	// shrink an mirror-explanded binary image to prevent shrinking of boundary-touching edges
	selectImage(id); run("Duplicate...", " "); id_shrunken = getImageID();
	selectImage(id_shrunken); setThreshold(255, 255); setOption("BlackBackground", false); run("Convert to Mask");
	run("Create Selection"); run("Enlarge...", "enlarge=-"+shrinkWidth);
	setBackgroundColor(255, 255, 255); run("Clear Outside"); run("Select None");
	getDimensions(width, height, channels, slices, frames);
	new_w = width / 3;
	new_h = height / 3;
	run("Canvas Size...", "width="+new_w+" height="+new_h+" position=Center zero");
	
	return id_shrunken;
}

function expand_ROI(id) {
	// expand image to all directions and fill with mirror images
	selectImage(id); run("Duplicate...", " "); rename("center");
	selectWindow("center"); run("Duplicate...", " "); run("Flip Horizontally"); rename("left");
	selectWindow("left"); run("Duplicate...", " "); rename("right");
	run("Combine...", "stack1=left stack2=center"); rename("left_center");
	run("Combine...", "stack1=left_center stack2=right"); rename("middle");
	selectWindow("middle"); run("Duplicate...", " "); run("Flip Vertically"); rename("top");
	selectWindow("top"); run("Duplicate...", " "); rename("bottom");
	run("Combine...", "stack1=top stack2=middle combine"); rename("top_middle");
	run("Combine...", "stack1=top_middle stack2=bottom combine"); rename("expanded"); id_expanded = getImageID();
	
	return id_expanded;
}

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