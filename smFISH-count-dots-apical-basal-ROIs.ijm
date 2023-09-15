// Clean up workspace
run("Close All"); run("Collect Garbage"); // Release occupied memory
if ( isOpen("Synchronize Windows") ) { selectWindow("Synchronize Windows"); run("Close"); }
if ( isOpen("Log") ) { selectWindow("Log"); run("Close"); }
if ( isOpen("Debug") ) { selectWindow("Debug"); run("Close"); }
if ( isOpen("Results") ) { selectWindow("Results"); run("Close"); }
if ( isOpen("ROI Manager") ) { selectWindow("ROI Manager"); run("Close"); }

inputFolder = getDirectory("Choose the folder containing rotated and cropped images:");
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-output" + File.separator;
if ( !(File.exists(outputFolder)) ) { exit("No existing output folder!"); }
ROIfolder = outputFolder + "ROIs" + File.separator;
if ( !(File.exists(ROIfolder)) ) { exit("No existing ROI folder!"); }

// Turn on the batch mode (not showing images to speed up the processing)
setBatchMode(true);

// Open a text file to record the parameter and the corresponding total dot number
outTextFilename = outputFolder + inputFolderPrefix + "_apical_basal_ROI_dot_count_area.txt";
outFile = File.open(outTextFilename);
print(outFile, "file_name\tapical_dot_number\tapical_area\tbasal_dot_number\tbasal_area"); // "\t" specifies the tab

fList = getFileList(inputFolder);
for (i=0; i<fList.length; i++) {
	f = fList[i];
	filenamePrefix = getPathFilenamePrefix(f);
	if ( endsWith(f, File.separator) || startsWith(filenamePrefix, ".") || startsWith(filenamePrefix, "~") || startsWith(filenamePrefix, "_") ) { continue; } //skip if f is a folder, or system files
	if ( endsWith(f, ".tif") ) {
		dotsFile = outputFolder + filenamePrefix + "-dots.tif";
		open(dotsFile); id = getImageID();

		// get image dimensions
		Stack.getDimensions(w, h, channels, slices, frames);
		
		// set scale: 1 pixel is 0.0774891 micron, z interval 0.5 micron
		Stack.setXUnit("micron");
		run("Properties...", "pixel_width=0.0774891 pixel_height=0.0774891 voxel_depth=0.5");
		// Normally this step is unnecessary, if the voxel calibration of the image is correct.
		// However, some images in this set had to be re-formatted from image sequence exported from ND2 viewer,
		// which inadvertently lost the scaling information.
		
		// load the pre-made ROI file
		ROIfile = ROIfolder + filenamePrefix + "-RoiSet.zip";
		roiManager("open", ROIfile);

		// !!! NOTE !!!
		// Because of the histogram matching step in smFISH-processAll,
		// and the first image is 134 x 269 (w x h) pixels,
		// all dots image were expanded if they are <134 pixels wide or <269 pixels.
		// * Calculate the deltaX and deltaY to re-center the selections
		roiManager("Select", newArray(1,2));
		roiManager("OR");
		getSelectionBounds(x0, y0, w0, h0); // original image w and h
		dx = floor( (w-w0)/2 );
		dy = floor( (h-h0)/2 );

		// compute *apical* ROI parameters
		selectImage(id);
		roiManager("select", 3); // apical cell ROI
		getSelectionBounds(x, y, w1, h1);
		setSelectionLocation(x+dx, y+dy); // shift selection
		run("Duplicate...", "duplicate");
		run("Measure");
		area_apical = getResult("Area", 0);
		setBackgroundColor(0, 0, 0);
		run("Clear Outside", "stack");
		id_apical = getImageID();
		n_apical = countDotByLabeling3D(id_apical);

		// compute *basal* ROI parameters
		selectImage(id);
		roiManager("select", 4); // basal cell ROI
		getSelectionBounds(x, y, w2, h2);
		setSelectionLocation(x+dx, y+dy); // shift selection
		run("Duplicate...", "duplicate");
		run("Measure");
		area_basal = getResult("Area", 1);
		setBackgroundColor(0, 0, 0);
		run("Clear Outside", "stack");
		id_basal = getImageID();
		n_basal = countDotByLabeling3D(id_basal);

		// record results
		print(outFile, filenamePrefix + "\t" + n_apical + "\t" + area_apical + "\t" + n_basal + "\t" + area_basal); // "\t" specifies the tab

		// clean up workspace
		roiManager("Reset");
		run("Close All");
		run("Clear Results");
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