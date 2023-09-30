// Clean up workspace
run("Close All"); run("Collect Garbage"); // Release occupied memory
//if ( isOpen("Synchronize Windows") ) { selectWindow("Synchronize Windows"); run("Close"); }
//if ( isOpen("Log") ) { selectWindow("Log"); run("Close"); }
//if ( isOpen("Debug") ) { selectWindow("Debug"); run("Close"); }
//if ( isOpen("Results") ) { selectWindow("Results"); run("Close"); }
//if ( isOpen("ROI Manager") ) { selectWindow("ROI Manager"); run("Close"); }

// Specify control parameters
saturation = 0.5;
color_code_LUT = "glasbey on dark";

// Specify folders
inputFolder = getDirectory("Choose the folder containing images:");
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-output" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

// Turn on the batch mode (not showing images to speed up the processing)
setBatchMode(false);

// Open a text file to record the parameters and results
outTextFilename = outputFolder + inputFolderPrefix + "_dynamic_vesicle_signal_summary.txt";
outFile = File.open(outTextFilename);
print(outFile, "file_name"+","+"mean_intensity_Golgi"+","+"total_dynamic_vesicle_signal"+","+"normed_dynamic_vesicle_signal");

fList = getFileList(inputFolder);
for (i=0; i<fList.length; i++) {
	f = fList[i];
	filenamePrefix = getPathFilenamePrefix(f);
//	if ( endsWith(f, File.separator) || startsWith(filenamePrefix, ".") || startsWith(filenamePrefix, "~") || startsWith(filenamePrefix, "_") ) { continue; } //skip if f is a folder, or system files
	if ( endsWith(f, ".tif") ) {
		open(inputFolder + f); id0=getImageID();
		run("Enhance Contrast", "saturated="+saturation);
		
		selectImage(id0);
		run("Z Project...", "projection=[Max Intensity]"); rename("max_intensity_projection");
		setTool("polygon");
		selectImage("max_intensity_projection"); run("In [+]"); run("In [+]");
		waitForUser("Draw around the Golgi:");
		getStatistics(area, mean_intensity_Golgi);
//		selectImage("max_intensity_projection"); run("Close");
		
		selectImage(id0);
		run("Duplicate...", "duplicate range=1-119");
		rename("1-119");
		selectImage(id0);
		run("Duplicate...", "duplicate range=2-120");
		rename("2-120");
		
		imageCalculator("Subtract create stack", "2-120","1-119");
		rename("difference");
		selectImage("difference");
		run("Z Project...", "projection=[Max Intensity]");
		rename("diff_max");
		
		setTool("polygon");
		selectImage("diff_max"); run("In [+]"); run("In [+]");
		waitForUser("Draw around the basal cell body:");
		getRawStatistics(nPixels, mean_dynamic_vesicle_signal);
		total_dynamic_vesicle_signal = nPixels * mean_dynamic_vesicle_signal;
		normed_dynamic_vesicle_signal = total_dynamic_vesicle_signal / mean_intensity_Golgi;
		
		print(outFile, f+","+mean_intensity_Golgi+","+total_dynamic_vesicle_signal+","+normed_dynamic_vesicle_signal);
		
		run("Merge Channels...", "c2=1-119 c6=2-120 create keep"); id_merged=getImageID();
		selectImage(id_merged); saveAs("tiff", outputFolder + filenamePrefix + "-diff-merged.tif");
		
		run("Close All");
		setTool("rectangle");
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