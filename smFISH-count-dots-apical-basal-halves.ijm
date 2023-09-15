// Clean up workspace
run("Close All"); run("Collect Garbage"); // Release occupied memory
if ( isOpen("Synchronize Windows") ) { selectWindow("Synchronize Windows"); run("Close"); }
if ( isOpen("Log") ) { selectWindow("Log"); run("Close"); }
if ( isOpen("Debug") ) { selectWindow("Debug"); run("Close"); }
if ( isOpen("Results") ) { selectWindow("Results"); run("Close"); }
if ( isOpen("ROI Manager") ) { selectWindow("ROI Manager"); run("Close"); }

inputFolder = getDirectory("Choose the folder containing images to process:");
inputFolderPrefix = getPathFilenamePrefix(inputFolder);
// Store the images and record txt files inside the same folder
outputFolder = inputFolder;

setBatchMode(true);

// Open a text file to record the parameter and the corresponding total dot number
outTextFilename = outputFolder + inputFolderPrefix + "_apical_basal_dot_count.txt";
outFile = File.open(outTextFilename);
print(outFile, "file_name\tapical_dot_number\tbasal_dot_number"); // "\t" specifies the tab

fList = getFileList(inputFolder);
for (i=0; i<fList.length; i++) {
	f = fList[i];
	if ( endsWith(f, File.separator) || startsWith(f, ".") || startsWith(f, "~") || startsWith(f, "_") ) { continue; } //skip if f is a folder, or system files
	filenamePrefix = getFilenamePrefix(f);
	if ( endsWith(f, "-dots.tif") ) {
		open(f); id = getImageID();
		Stack.getDimensions(width, height, channels, slices, frames);
		h1 = floor(height/2);
		h2 = height - h1;
		
		selectImage(id);
		makeRectangle(0, 0, width, h1);
		run("Duplicate...", "duplicate");
		id_apical = getImageID();
		n_apical = countDotByLabeling3D(id_apical);

		selectImage(id);
		makeRectangle(0, h1+1, width, h2);
		run("Duplicate...", "duplicate");
		id_basal = getImageID();
		n_basal = countDotByLabeling3D(id_basal);
		
		print(outFile, filenamePrefix + "\t" + n_apical + "\t" + n_basal); // "\t" specifies the tab
		run("Close All");
	}
}
File.close(outFile);

function countDotByLabeling3D(imgID) {
	selectImage(imgID); run("Connected Components Labeling", "connectivity=26 type=float"); imgLbl = getImageID();
	selectImage(imgLbl); run("Z Project...", "projection=[Max Intensity]"); imgLblMIP = getImageID();
	selectImage(imgLblMIP); getStatistics(area, mean, min, max); nDots = max;
	selectImage(imgLbl); run("Close");
	selectImage(imgLblMIP); run("Close");
	run("Collect Garbage");
	return nDots;
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