clean_up_workspace();

//inputFolder = getDirectory("Choose the folder containing images to process:");
inputFolder = getArgument();// for batch processing of multiple folders

// Create an output folder based on the inputFolder
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-output" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }
ROIfolder = outputFolder + "ROIs" + File.separator;
if ( !(File.exists(ROIfolder)) ) { File.makeDirectory(ROIfolder); }

setBatchMode(true);

// Open a text file to record the parameter and the corresponding total dot number
outTextFilename = outputFolder + inputFolderPrefix + "_polarization_summary.txt";
outFile = File.open(outTextFilename);
print(outFile, "file_name"+","+"apical_dot_number"+","+"basal_dot_number"+","+"apical_area"+","+"basal_area"+","+"polarization_index");

fList = getFileList(inputFolder);
for (i=0; i<fList.length; i++) {
	f = fList[i];
	if ( startsWith(f, "00_ref") || endsWith(f, File.separator) || startsWith(f, ".") || startsWith(f, "~") || startsWith(f, "_") ) { continue; } //skip if f is a folder, or system files
	filenamePrefix = getPathFilenamePrefix(f);
	dotsImg = outputFolder + filenamePrefix + "-dots.tif";
	apicalMask = ROIfolder + filenamePrefix + "-epiMask-apicalMask.tif";
	basalMask = ROIfolder + filenamePrefix + "-epiMask-basalMask.tif";
	
	open(dotsImg); rename("dots"); id_dots = getImageID();
	open(apicalMask); rename("apical"); id_apical = getImageID();
	open(basalMask); rename("basal"); id_basal = getImageID();
		
	imageCalculator("AND create", "dots", "apical"); id_apical_dots = getImageID();
	imageCalculator("AND create", "dots", "basal"); id_basal_dots = getImageID();
	
	selectImage(id_apical); getStatistics(area, mean, min, max, std, histogram); areaA = histogram[255];
	selectImage(id_basal); getStatistics(area, mean, min, max, std, histogram); areaB = histogram[255];
	selectImage(id_apical_dots); getStatistics(area, mean, min, max, std, histogram); nDotsA = histogram[255];
	selectImage(id_basal_dots); getStatistics(area, mean, min, max, std, histogram); nDotsB = histogram[255];
	
	densityA = nDotsA * 100 / areaA; // number of dots per 100 pixels
	densityB = nDotsB * 100 / areaB; // number of dots per 100 pixels
	
	polarization_index = (densityA - densityB) / (densityA + densityB);
	print(outFile, filenamePrefix+","+nDotsA+","+nDotsB+","+areaA+","+areaB+","+polarization_index);
	
	run("Close All"); run("Collect Garbage"); // Release occupied memory
	roiManager("reset");
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