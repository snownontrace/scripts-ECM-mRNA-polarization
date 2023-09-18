// Select a square ROI of SMG epithelial region, where the lower left corner 
// of the ROI is around the center of an epithelial bud, and the curved surface
// is facing upper right

clean_up_workspace();

inputFolder = getDirectory("Choose the folder containing images to process:");
// Create an output folder based on the inputFolder
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-preprocessed" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

setBatchMode(false);
fList = getFileList(inputFolder);
for (i=0; i<fList.length; i++) {
	f = fList[i];
	if ( endsWith(f, File.separator) || startsWith(f, ".") || startsWith(f, "~") || startsWith(f, "_") ) { continue; } //skip if f is a folder, or system files
	open(inputFolder+f);
	run("Duplicate...", "duplicate");
	filenamePrefix = getPathFilenamePrefix(f);
	outputFilename = outputFolder + filenamePrefix + "-pp.tif";
	saveAs("tiff", outputFilename);
	run("Close All");
}
//setTool("rectangle");

//showMessage("Preprocessing finished.");

function clean_up_workspace() {
	// Clean up workspace
	run("Close All"); run("Collect Garbage"); // Release occupied memory
	if ( isOpen("Synchronize Windows") ) { selectWindow("Synchronize Windows"); run("Close"); }
	if ( isOpen("Log") ) { selectWindow("Log"); run("Close"); }
	if ( isOpen("Debug") ) { selectWindow("Debug"); run("Close"); }
	if ( isOpen("Results") ) { selectWindow("Results"); run("Close"); }
	if ( isOpen("ROI Manager") ) { selectWindow("ROI Manager"); run("Close"); }
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