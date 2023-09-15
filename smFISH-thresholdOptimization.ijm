// Clean up workspace
run("Close All"); run("Collect Garbage"); // release occupied memory
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
// Create a log_files folder
logFolder = outputFolder + "log_files" + File.separator;
if ( !(File.exists(logFolder)) ) { File.makeDirectory(logFolder); }

// number of files to process using manual optimization
optimizationN = 100;
// rGB is the radius for Gaussian filter -- 1 is good to filter out camera noise
rGB = 1;
rGB_z = 1;// use 0 to force slice-by-slice processing
// rTophat is the radius of morphological element (disk or ball for 2d or 3d) used for Morphological Top Hat filter,
// a typical good value is the average radius of the dot you care about.
rTophat = 2;
rTophat_z = 2;// use 0 to force slice-by-slice processing
// this is the channel number for smFISH -- used in preProcessing step if there is more than 1 channel
targetChannel = 2;
// Toggle this setting true or false to keep or delete the temporary files after processing each image
KEEP_TEMP_FILES = true;
// Toggle this setting true or false to display the results files one by one after processing all images
SHOW_RESULTS = false;
// Create a dialog to allow user to modify the parameters
Dialog.create("Modify Parameters");
Dialog.addNumber("How many files do you want to use for threshold optimization?", optimizationN);
Dialog.addMessage("Required parameters:\n");
Dialog.addNumber("Gaussian Blur Radius (xy) in pixels:", rGB);
Dialog.addNumber("Morphological Top-hat Radius (xy) in pixels:", rTophat);
Dialog.addMessage("For multi-channel images (ignore for 1-channel)\n");
Dialog.addNumber("Which channel to process?", targetChannel);
Dialog.addMessage("For 3D images (ignore for 2D)\n");
Dialog.addNumber("Gaussian Blur Radius (z) in voxels:", rGB_z);
Dialog.addNumber("Morphological Top-hat Radius (z) in voxels:", rTophat_z);
Dialog.addCheckbox("Keep intermediate files", KEEP_TEMP_FILES);
Dialog.addCheckbox("Show results one-by-one after processing all", SHOW_RESULTS);
Dialog.show();
optimizationN = Dialog.getNumber();
rGB = Dialog.getNumber();
rTophat = Dialog.getNumber();
targetChannel = Dialog.getNumber();
rGB_z = Dialog.getNumber();
rTophat_z = Dialog.getNumber();
KEEP_TEMP_FILES = Dialog.getCheckbox();
SHOW_RESULTS = Dialog.getCheckbox();
// The rDot controls the diamond radius used to enlarge dots for visualization
rDot = rTophat;
//rDot = rTophat-1;
// rDot_z controls how many z-slices (+- from center) to project for inspection
rDot_z = rTophat_z;

print(getTimeString("Started at: "));
// Print out used parameters
print("############################################################################################################################################################");
print("Input folder: " + inputFolder);
print("---------------------------------------------------------");
print("Number of files for threshold optimization: " + optimizationN);
print("---------------------------------------------------------");
print("Gaussian Blur Radius (xy) in pixels: " + rGB);
print("Morphological Tophat Radius (xy) in pixels: " + rTophat);
print("---------------------------------------------------------");
print("For multi-channel images (ignore for 1-channel):");
print("Which channel to process? " + targetChannel);
print("---------------------------------------------------------");
print("For 3D images (ignore for 2D):");
print("Gaussian Blur Radius (z) in voxels: " + rGB_z);
print("Morphological Tophat Radius (z) in voxels: " + rTophat_z);
print("---------------------------------------------------------");
print("Keep intermediate files after processing each file? " + KEEP_TEMP_FILES);
print("Show results after processing each file? " + SHOW_RESULTS);
print("############################################################################################################################################################");

// This is the main function that handles the user interface
optimizeThresholdFolder(inputFolder, outputFolder, rGB, rTophat, rGB_z, rTophat_z, targetChannel, optimizationN);
print(getTimeString("Finished at: "));
// Save the log file, Activate the log window that has the recorded number
timeFinish = getTime(); timeStamp = timeFinish % 10000;// time stamp for saving log and summary text files
selectWindow("Log"); saveAs("txt", logFolder + "threholdOptimization-log-" + timeStamp + ".txt");
showMessage("Check the Log window for a list and summary of your selected thresholds.\n"+
			"Also saved in the summary text file and the log file int he output folder.");
selectWindow("Log");

// -------------------------------------------------------------------------------------------------------
// This macro performs threshold parameter optimization for all smFISH images from the input folder.
// -------------------------------------------------------------------------------------------------------
// *** (1) Image pre-processing and filtering ***
//         The pre-processing routes the images to the corresponding processing workflow, depending on
// whether it is 2D or 3D, whether multiple channels are present (if so, process only the specified target
// channel), and whether multiple time points are present (if so, process only the 1st time point; gives a
// WARNING message since smFISH images are not supposed to contain multiple time points).
//         For each image, it will first smoothen the image by Gaussian blur, enhance the contrast of
// specified size of elegment and flatten the background using the morphological top hat filter from
// MorphoLibJ.  If you want to learn more about it, read:
//         https://imagej.net/MorphoLibJ#Top-hats
//         The filtered image will be used for dot segmentation based on a combination of local maxima
// finding and thresholding.
// -------------------------------------------------------------------------------------------------------
// *** (2) Maxima finding and thresholding on filtered image ***
//         Dot identification here is achieved by a combination of maxima finding and thresholding. When
// the image is 2D, the Fiji native "Find Maxima..." is used. When the image is 3D, a "Regional Maxima"
// function from the MorphoLibJ library is used.
//         When the dots are clearly beyond background, the plot curve of "Dot Number vs. Threshold Level"
// should have a kink point followed by a partial plateau.  Somewhere near the middle point of this partial
// plateau is usually the best thresholding level.
// -------------------------------------------------------------------------------------------------------
// *** (3) Output items ***
//         For each image:
//         (3-1) A pre-processed image (or stack for 3D) with the processed channel/frame isolated,
// if multiple z slices, perform "histogram matching" bleach correction to help 3D segmentation
//         (3-2) A filtered image (or stack for 3D) that had been Gaussian and Tophat filtered
//         (3-3) A dot image with maxima at the selected level
//         (3-4) A plot of "Dot Nubmer vs. Threshold Level" in both linear and log scales
//         (3-5) A plot of "Dot Nubmer vs. Threshold Level" in linear scale, where the selected threshold 
// level is marked by a red cross.
//         (3-6) A plot of "Dot Nubmer vs. Threshold Level" in log scale, where the selected threshold 
// level is marked by a red cross.
//         For the entire image set:
//         (3-7) A summary text file with a list of image name, selected threshold level and dot number
//         (3-8) A log file with parameters and outer intermediate outputs (helpful for troubleshooting)
// -------------------------------------------------------------------------------------------------------

//---------------------
// Main Functions
//---------------------

function optimizeThresholdFolder(inputFolder, outputFolder, rGB, rTophat, rGB_z, rTophat_z, targetChannel, optimizationN) {
// This function handles the user interface for selecting threshold.
// The images must have been processed by "processImageFolder" to generate intermediate files for this step.
	setBatchMode(true);
	// Before starting, check whether the outputFolder contains the expected files
	fList = getFileList(outputFolder);
	checkTxt = 0;
	for (i=0; i<fList.length; i++) {
		if ( endsWith(fList[i], "thresholdOptimization.txt") ) { checkTxt++; }
	}
	if ( checkTxt < optimizationN ) { processImageFolder(inputFolder, outputFolder, rGB, rTophat, rGB_z, rTophat_z, targetChannel, optimizationN); }
	
	// Create a text window to record the summary of dot counting information
	sumTextWindow = "thresholdOptimization-Summary";
	if ( isOpen(sumTextWindow) ) { print("["+sumTextWindow+"]", "\\Update:"); } // clears the window
	else { run("Text Window...", "name=["+sumTextWindow+"]"); }
	print("["+sumTextWindow+"]", "file_name\tselected_threshold\ttotal_dot_number");

	// Loop through the files in inputFolder for threshold parameter optimization.
	fList = getFileList(inputFolder);
	optimizationCounter = 0;
	time0 = getTime(); //Get starting time of waiting
	timeStart = -1; 
	for (i=0; i<fList.length; i++) {
		f = fList[i];
		if ( endsWith(f, File.separator) || startsWith(f, ".") || startsWith(f, "~") || startsWith(f, "_") ) { continue; } //skip if f is a folder, or system files
		if ( optimizationCounter == optimizationN ) { break; }// stop when the specified number of files have been processed
		optimizationCounter++;
		// Define a few file names and folder names derived from the file name prefix
		filenamePrefix = getFilenamePrefix(f);
		preProcessedFile = outputFolder + filenamePrefix + "-preProcessed.tif";
		filteredFile = outputFolder + filenamePrefix + "-filtered.tif";
		outTextFilename = outputFolder + filenamePrefix + "-thresholdOptimization.txt";
		tempFolder = outputFolder + filenamePrefix + "-temp" + File.separator;
		preProcessedTemp = tempFolder + filenamePrefix + "-preProcessed-temp.tif";
		filteredImgTemp = tempFolder + filenamePrefix + "-filtered-temp.tif";
		dotVSthresholdTemp = tempFolder + filenamePrefix + "-dotsVSthreshold-temp.tif";
		// Process the current image
		print("============================================================================================================================================================");
		print("Optimizing threshold for: " + filenamePrefix);
		timeStart = optimizeThreshold(outTextFilename, preProcessedTemp, filteredImgTemp, dotVSthresholdTemp, outputFolder, tempFolder, sumTextWindow, filenamePrefix, optimizationCounter, timeStart);
		print("Finished threshold optimization for: " + filenamePrefix);
		print("============================================================================================================================================================");
	}
	
	// Print out the time cost of optimization (when user intervention is involved)
	time1 = getTime();//time in milliseconds
	timeStamp = time1 % 10000;//for adding to log and other text output files
	duration = floor( (timeStart-time0)/1000 );//time in seconds
	print("Idle time: " + duration + " seconds.");
	duration = floor( (time1-timeStart)/1000 );//time in seconds
	print("User-involved optimization took: " + duration + " seconds.");
	
	// Save and the summary text window
	selectWindow(sumTextWindow);
	inputFolderPrefix = getPathFilenamePrefix(inputFolder);
	sumOutFile = outputFolder + inputFolderPrefix + "-" + sumTextWindow + "-" + timeStamp + ".txt";
	saveAs("txt", sumOutFile); run("Close");
	
	// Print out a summary of the selected threshold
	print("############################################################################################################################################################");
	print("List of the selected threshold levels: ");
	filestring=File.openAsString(sumOutFile);
	rows=split(filestring, "\n");
	y=newArray(rows.length-1); // "-1" because there is header
	for(i=1; i<rows.length; i++){
		// i starts from 1 to skip the header row
		columns=split(rows[i],"\t");
		y[i-1]=parseInt(columns[1]); //this is the 2nd column
		print(y[i-1]);
	}
	Array.getStatistics(y, yMin, yMax, yMean, yStd);
	print("Mean and Standard Deviation: ");
	print(yMean + ", " + yStd);
	print("############################################################################################################################################################");
	
	// Post processing
	fList = getFileList(inputFolder); optimizationCounter = 0;
	for (i=0; i<fList.length; i++) {
		f = fList[i];
		if ( endsWith(f, File.separator) || startsWith(f, ".") || startsWith(f, "~") || startsWith(f, "_") ) { continue; } //skip if f is a folder, or system files
		if ( optimizationCounter == optimizationN ) { break; }// stop when the specified number of files have been processed
		optimizationCounter++;
		filenamePrefix = getFilenamePrefix(f);
		dotFile = outputFolder + filenamePrefix + "-dots.tif";		
		if ( (File.exists(dotFile)) ) {
			open(dotFile); imgDots = getImageID();
			if ( nSlices == 1 ) { selectImage(imgDots); run("Morphological Filters", "operation=Dilation element=Disk radius="+rDot); imgEnlargedDots = getImageID(); }
			else { selectImage(imgDots); run("Morphological Filters (3D)", "operation=Dilation element=Ball x-radius="+rDot+" y-radius="+rDot+" z-radius="+rDot_z); imgEnlargedDots = getImageID(); }
			selectImage(imgEnlargedDots); save(outputFolder + filenamePrefix + "-enlargedDots.tif");
			run("Close All"); run("Collect Garbage"); // release occupied memory
		}
	}
	fList = getFileList(inputFolder); optimizationCounter = 0;
	for (i=0; i<fList.length; i++) {
		f = fList[i];
		if ( endsWith(f, File.separator) || startsWith(f, ".") || startsWith(f, "~") || startsWith(f, "_") ) { continue; } //skip if f is a folder, or system files
		if ( optimizationCounter == optimizationN ) { break; }// stop when the specified number of files have been processed
		optimizationCounter++;
		filenamePrefix = getFilenamePrefix(f);
		if ( SHOW_RESULTS ) {
			showResults(outputFolder, filenamePrefix+"-", "-preProcessed.tif", "-filtered.tif", "-enlargedDots.tif");
			waitForUser("Inspect the output images at selected threshold.\n"+
						"   Click OK to continue processing the next.");
		}
	}
	fList = getFileList(inputFolder);
	for (i=0; i<fList.length; i++) {
		f = fList[i];
		if ( endsWith(f, File.separator) || startsWith(f, ".") || startsWith(f, "~") || startsWith(f, "_") ) { continue; } //skip if f is a folder, or system files
		filenamePrefix = getFilenamePrefix(f);
		tempFolder = outputFolder + filenamePrefix + "-temp" + File.separator;
		if ( !KEEP_TEMP_FILES ) { deleteFolder(tempFolder); }
	}
	// Reset measurement settings
	run("Set Measurements...", "area mean standard min");
	if ( isOpen("Synchronize Windows") ) { selectWindow("Synchronize Windows"); run("Close"); }
	if ( isOpen("Results") ) { selectWindow("Results"); run("Close"); }
	if ( isOpen("ROI Manager") ) { selectWindow("ROI Manager"); run("Close"); }
	run("Close All"); run("Collect Garbage"); // release occupied memory
	return 1;
}

function showResults(resulstsFolder, filenamePrefix, Postfix1, Postfix2, Postfix3) {
	setBatchMode(false); run("Close All");
	resultsList = getFileList(resulstsFolder);
	for (i=0; i<resultsList.length; i++) {
		f = resultsList[i];
		if ( startsWith(f, filenamePrefix) ) {
			if ( endsWith(f, Postfix1) || endsWith(f, Postfix2) || endsWith(f, Postfix3) ) {
				open(resulstsFolder + f);
				if (nSlices > 1) { setSlice(nSlices); }
			}
		}
	}
	run("Tile"); run("Synchronize Windows");
	return 1;
}

function processImageFolder(inputFolder, outputFolder, rGB, rTophat, rGB_z, rTophat_z, targetChannel, optimizationN) {
// This function processes all files in the inputFolder
	time0 = getTime();//starting time in milliseconds
	setBatchMode(true);
	fList = getFileList(inputFolder);
	optimizationCounter = 0;
	refMedian = -1; refRange = -1; // Initialize with impossible values to ensure the 1st pass of processing computes these values from the 1st image
	for (i=0; i<fList.length; i++) {
		f = fList[i];
		if ( endsWith(f, File.separator) || startsWith(f, ".") || startsWith(f, "~") || startsWith(f, "_") ) { continue; } //skip if f is a folder, or system files
		if ( optimizationCounter == optimizationN ) { break; }// stop when the specified number of files have been processed
		optimizationCounter++;
		refValues = processImage(inputFolder+f, outputFolder, rGB, rTophat, rGB_z, rTophat_z, targetChannel, refMedian, refRange);
		refMedian = refValues[0]; refRange = refValues[1];
	}
	// Print out the time cost of hands-free processing time
	time1 = getTime();//ending time in milliseconds
	duration = floor( (time1-time0)/1000 );//time lapse in seconds
	print("Hands-free processing took: " + duration + " seconds.");
	return 1;
}

function processImage(filePath, outputFolder, rGB, rTophat, rGB_z, rTophat_z, targetChannel, refMedian, refRange) {
// This function routes the image through the intended flow of processing to get ready for parameter optimization.
	setBatchMode(true);
	filenamePrefix = getPathFilenamePrefix(filePath);
	preProcessedFile = outputFolder + filenamePrefix + "-preProcessed.tif";
	filteredFile = outputFolder + filenamePrefix + "-filtered.tif";
	tempFolder = outputFolder + filenamePrefix + "-temp" + File.separator;
	outTextFilename = outputFolder + filenamePrefix + "-thresholdOptimization.txt";
	preProcessedTemp = tempFolder + filenamePrefix + "-preProcessed-temp.tif";
	filteredImgTemp = tempFolder + filenamePrefix + "-filtered-temp.tif";
	dotVSthresholdTemp = tempFolder + filenamePrefix + "-dotsVSthreshold-temp.tif";
	refImgFile = logFolder + "refImage.tif";
	refValues = newArray(-1, -1);
	print("************************************************************************************************************************************************************");
	print("Processing: " + filenamePrefix);
	// Create an empty temp folder inside output folder to hold intermediate results
	if ( File.exists(preProcessedTemp) && File.exists(filteredImgTemp) && File.exists(dotVSthresholdTemp) ) {
		print("Processed intermediate files found.");
		print("Finished processing: " + filenamePrefix);
		print("************************************************************************************************************************************************************");
		return refValues;
	}
	else {
		if ( File.exists(tempFolder) ) { deleteFolder(tempFolder); File.makeDirectory(tempFolder); }
		else { File.makeDirectory(tempFolder); }
	}
	// The following if-else statements assess whether a filtered image exists, and starts from filtered if it does
	if ( File.exists(filteredFile) ) {
		print("Filtered image found. Processing from filtered.");
		thresholdAll(preProcessedFile, filteredFile, outTextFilename, outputFolder, tempFolder, filenamePrefix, rDot, rDot_z);
		print("Finished processing: " + filenamePrefix);
		print("************************************************************************************************************************************************************");
		return refValues;
	}
	// The following if-else statements assess whether a pre-processed image exists, and starts from it if it does
	if ( File.exists(preProcessedFile) ) {
		print("Pre-processed but unfiltered image found. Processing from pre-processed.");
		filterImg(preProcessedFile, filteredFile, rGB, rTophat, rGB_z, rTophat_z);
		thresholdAll(preProcessedFile, filteredFile, outTextFilename, outputFolder, tempFolder, filenamePrefix, rDot, rDot_z);
		print("Finished processing: " + filenamePrefix);
		print("************************************************************************************************************************************************************");
		return refValues;
	}
	else {
		refValues = preProcessImg(inputFolder+f, preProcessedFile, targetChannel, tempFolder, filenamePrefix, refMedian, refRange, refImgFile);
		filterImg(preProcessedFile, filteredFile, rGB, rTophat, rGB_z, rTophat_z);
		thresholdAll(preProcessedFile, filteredFile, outTextFilename, outputFolder, tempFolder, filenamePrefix, rDot, rDot_z);
		print("Finished processing: " + filenamePrefix);
		print("************************************************************************************************************************************************************");
		return refValues;
	}
}

function preProcessImg(imgFile, preProcessedFile, targetChannel, tempFolder, filenamePrefix, refMedian, refRange, refImgFile) {
// This function pre-process the image so that a single channel, single frame, 8-bit image
// is saved as preProcessedFile for filtering and downstream analysis.
// If multiple channels exist, a target channel will be extracted for analysis.
// If multiple frames are present, only the first frame will be processed.
// If multiple z-slices exist, a "HIstogram Matching" algorithm is applied to equalize the brightness across the z-stack.
	setBatchMode(true);
	satuLevel = 0.1; // satuLevel is used by several functions for obtaining min max range or convert to 8-bit
	open(imgFile); run("Select None"); id = getImageID(); getDimensions(w, h, c, s, f); // w, h, c, s, f => width, height, channels, slices, frames
	print("Image width, height, channel#, slice#, frame#: ", w, h, c, s, f);
	//print(refMedian, refRange);
	if ( f == 1 && c == 1 ) {
		selectImage(id); run("Grays"); idSelected = getImageID();
		print("This is a 1-channel, 1-frame simple case.");
	}
	if ( f == 1 && c > 1 ) {
		selectImage(id); run("Duplicate...", "duplicate channels=" + targetChannel); run("Grays"); idSelected = getImageID();
		print("There are multiple channels. Processing the specified channel " + targetChannel);
	}
	if ( f > 1 && c == 1 ) {
		// when only f > 1, in duplicate it has to be called "range"
		if ( s == 1 ) { selectImage(id); run("Duplicate...", "duplicate range=1-1"); run("Grays"); idSelected = getImageID(); }
		else { selectImage(id); run("Duplicate...", "duplicate frames=1"); run("Grays"); idSelected = getImageID(); }
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for smFISH images, please check your images.");
	}
	if ( f > 1 && c > 1 ) {
		selectImage(id); run("Duplicate...", "duplicate frames=1"); idFrame1 = getImageID();
		selectImage(idFrame1); run("Duplicate...", "duplicate channels=" + targetChannel); run("Grays"); idSelected = getImageID();
		print("There are multiple channels and time frames. Processing the specified channel #" + targetChannel + ", and only the first time point.");
		print("WARNING: It is unusual to have multiple frames for smFISH images, please check your images.");
	}
	// if there are multiple z-slices, perform a simple ratio based intensity match and convert to 8-bit
	if ( s > 1 ) { idTemp = ratioCorrection(idSelected); selectImage(idSelected); run("Close"); idSelected = idTemp; id8bit = convertTo8bit(idSelected, satuLevel); }
	if ( !(File.exists(refImgFile)) ) {
		if ( s == 1 ) { selectImage(idSelected); save(refImgFile); }
		else { selectImage(id8bit); midS = floor(s/2); Stack.setSlice(midS); run("Duplicate...", " "); save(refImgFile); }
	}
	if ( s == 1 ) {
		// if not initiated yet, use the reference file to calculate reference scaling values
		if ( refMedian == -1 ) {
			open(refImgFile); refID = getImageID();
			selectImage(refID); run("Enhance Contrast", "saturated=" + satuLevel); getMinAndMax(min, max);
			refMedian = getMedian(refID, 1) - min; refRange = max - min;
		}
		imgReady = matchMedianTo8bit(idSelected, refMedian, refRange, 1, satuLevel);
	}
	else { imgReady = matchHistogram(id8bit, refImgFile, filenamePrefix); }
	// Set the saturation level of the saved image.  Note that this only changes the default display scaling but not the image data
	selectImage(imgReady); satuLevel = 0.3; run("Enhance Contrast", "saturated=" + satuLevel); save(preProcessedFile);
	// Release occupied memory
	run("Close All"); run("Collect Garbage");
	// Construct the return values
	refValues = newArray(refMedian, refRange);
	return refValues;
}

function filterImg(preProcessedFile, filteredFile, rGB, rTophat, rGB_z, rTophat_z) {
// This function takes the pre-processed 2D or 3D images and apply Gaussian and white top-hat filter
// The output is saved in the filtered file in specified filteredFile path
	setBatchMode(true);
	open(preProcessedFile); imgPreProcessed = getImageID(); getDimensions(w, h, c, s, f); // w, h, c, s, f => width, height, channels, slices, frames
	// Apply Gaussian filter to smoothen the image
	selectImage(imgPreProcessed);
	if (s == 1) { run("Gaussian Blur...", "sigma=" + rGB); imgGB = getImageID(); }
	else { run("Gaussian Blur 3D...", "x=" + rGB + " y=" + rGB + " z=" + rGB_z); imgGB = getImageID(); }
	// Apply a "White Top Hat" filter to enhance dot contrast and flatten the background to facilitate segmentation
	selectImage(imgGB);
	if (s == 1) { run("Morphological Filters", "operation=[White Top Hat] element=Disk radius=" + rTophat); imgTophat = getImageID(); }
	else { run("Morphological Filters (3D)", "operation=[White Top Hat] element=Ball x-radius=" + rTophat + " y-radius=" + rTophat + " z-radius=" + rTophat_z); imgTophat = getImageID(); }
	// Set the saturation level of the saved image.  Note that this only changes the default scaling but not the data in the image.
	selectImage(imgTophat); satuLevel = 0.3; run("Enhance Contrast", "saturated=" + satuLevel); save(filteredFile);
	// release occupied memory
	run("Close All"); run("Collect Garbage");
	return 1;
}

function thresholdAll(preProcessedFile, filteredFile, outTextFilename, outputFolder, tempFolder, filenamePrefix, rDot, rDot_z) {
	open(preProcessedFile); idPrePed = getImageID();
	getDimensions(w, h, c, s, f); // w, h, c, s, f => width, height, channels, slices, frames
	if (s == 1) {
		thresholdAll2D(preProcessedFile, filteredFile, outTextFilename, outputFolder, tempFolder, filenamePrefix, rDot);
		return 1;
	}
	else {
		thresholdAll3D(preProcessedFile, filteredFile, outTextFilename, outputFolder, tempFolder, filenamePrefix, rDot, rDot_z);
		return 1;
	}
}

function thresholdAll2D(preProcessedFile, filteredFile, outTextFilename, outputFolder, tempFolder, filenamePrefix, rDot) {
// This function takes the filtered 2D images, go through all threshold levels, present the image, and let the user chooose the level
	setBatchMode(true);
	// Saturation level for output images when converting 16-bit to 8-bit for dispay
	satuLevel = 0.3;
	
	// Open a text file to record the parameter and the corresponding total dot number
	outFile = File.open(outTextFilename);
	print(outFile, "threshold_level\ttotal_dot_number"); // "\t" specifies the tab
	
	// For 2D images, save the same preProcessed image to temp folder
	preProcessedTemp = tempFolder + filenamePrefix + "-preProcessed-temp.tif";
	open(preProcessedFile); imgPreProcessed = getImageID(); save(preProcessedTemp);
	selectImage(imgPreProcessed); run("Close");

	// For 2D images, save the same filtered image to temp folder
	filteredImgTemp = tempFolder + filenamePrefix + "-filtered-temp.tif";
	open(filteredFile); imgTophat = getImageID(); save(filteredImgTemp);

	// Find maxima points and output single-pixel points selection
	noiseLevel = getMedian(imgTophat, 1);
	selectImage(imgTophat); run("Find Maxima...", "noise=" + noiseLevel + " output=[Single Points] exclude"); imgMaxima = getImageID();
	//run("Find Maxima...", "noise=1 output=[Single Points] exclude"); imgMaxima = getImageID();
	
	// Determine the range of gray values, and go through all possible threshold levels
	selectImage(imgTophat); getStatistics(areaTophat, meanTophat, minTophat, maxTophat);
	// To save time, adjust the step size of thresholding to process up to 100
	step = floor( (maxTophat-1)/100 ) + 1;
	for (i=0; i<maxTophat+1; i+=step) {
		lowerThreshold = i;
		
		// Duplicate the White Top Hat filtered image, threshold it at current fold of median
		selectImage(imgTophat); run("Duplicate...", "duplicate");
		setThreshold(lowerThreshold, 65535); // 65535 is the max possible for 16-bit image
		run("Convert to Mask"); imgThreshold = getImageID();
	
		// Filter out the initial maxima points below the threshold value
		imageCalculator("AND create", imgMaxima, imgThreshold); run("Grays"); imgDots = getImageID();	
		selectImage(imgDots); save(tempFolder + "dots-at-threshold-" + lowerThreshold + ".tif");
		
		// Generate a dots as same radius diamonds image for presentation
		selectImage(imgDots); run("Morphological Filters", "operation=Dilation element=Diamond radius="+rDot); imgDiamonds = getImageID();
		selectImage(imgDiamonds); save(tempFolder + "diamonds-at-threshold-" + lowerThreshold + ".tif");
	
		// Count the number of dots by counting the number of pixels with gray value 255 in "imgDots"
		selectImage(imgDots); getStatistics(area, mean, min, max, std, histogram); nDots = histogram[255];
		// record the total number of dots in the recording text file
		print(outFile, lowerThreshold + "\t" + nDots);

		// release occupied memory
		selectImage(imgThreshold); run("Close");
		selectImage(imgDots); run("Close");
		selectImage(imgDiamonds); run("Close");
		run("Collect Garbage");
		if ( nDots <= 1 ) { break; } // stop the loop when the number of dots are approaching 0
	}
	File.close(outFile);
	
	// Record the dot vs. threshold image stack for inspection
	dotVSthresholdTemp = tempFolder + filenamePrefix + "-dotsVSthreshold-temp.tif";
	run("Image Sequence...", "open=["+tempFolder+"] file=diamonds-at-threshold- sort use");
	save(dotVSthresholdTemp);

	// Release occupied memory
	run("Close All"); run("Collect Garbage");
	return 1;
}

function thresholdAll3D(preProcessedFile, filteredFile, outTextFilename, outputFolder, tempFolder, filenamePrefix, rDot, rDot_z) {
// This function takes the filtered 3D images, go through all threshold levels, save to intermediate temp folder,
// which can be used for presenting to the user to chooose the optimal threshold level
// This step is the time-consuming part
	setBatchMode(true);
	outFile = File.open(outTextFilename);
	print(outFile, "threshold_level\ttotal_dot_number"); // "\t" specifies the tab

	// For 3D images, create maximum intensity projection to facilitate the manual inspection and threhold selection
	preProcessedTemp = tempFolder + filenamePrefix + "-preProcessed-temp.tif";
	open(preProcessedFile); imgPreProcessed = getImageID();
	tiledTemp = getTiled(imgPreProcessed, rDot_z); selectImage(tiledTemp); save(preProcessedTemp);
	selectImage(imgPreProcessed); run("Close");
	selectImage(tiledTemp); run("Close");

	// For 3D images, create maximum intensity projection to facilitate the manual inspection and threhold selection
	filteredImgTemp = tempFolder + filenamePrefix + "-filtered-temp.tif";
	open(filteredFile); imgTophat = getImageID();
	run("Z Project...", "projection=[Max Intensity]"); imgTophatMIP = getImageID();
	tiledTemp = getTiled(imgTophat, rDot_z); selectImage(tiledTemp); save(filteredImgTemp);
	selectImage(tiledTemp); getStatistics(areaTophatMIP, meanTophatMIP, minTophatMIP, maxTophatMIP); run("Close");
	
	// Find maxima points and output single-pixel points selection, then go through all possible threshold levels
	noiseLevel = getMedian(imgTophat, 1);
	//selectImage(imgTophat); run("Regional Min & Max 3D", "operation=[Regional Maxima] connectivity=26"); imgMaxima = getImageID();
	selectImage(imgTophat); run("Extended Min & Max 3D", "operation=[Extended Maxima] dynamic="+noiseLevel+" connectivity=26"); imgMaxima = getImageID();
	
	// To save time, adjust the step size of thresholding to process up to 100
	step = floor( (maxTophatMIP-1)/100 ) + 1;
	for (i=0; i<maxTophatMIP+1; i+=step) {
		lowerThreshold = i;
		
		selectImage(imgTophat); run("Duplicate...", "duplicate");
		setThreshold(lowerThreshold, 65535); // 65535 is the max possible for 16-bit image
		run("Convert to Mask", "method=Default background=dark"); imgThreshold = getImageID();
		
		imageCalculator("AND create stack", imgMaxima, imgThreshold); run("Grays"); imgDots = getImageID();	
		selectImage(imgDots); save(tempFolder + "dots-at-threshold-" + lowerThreshold + ".tif");

		// Create a tile of individual slices and MIP, then dialte for inspection
		// The 1.5-fold is to account fo the fact that off-focus dots on preProcessed and filtered image stack can be clearly visualized after projecting, but not the centered spots
		rZ = floor(rDot_z*1.5)+1; tiledTemp = getTiled(imgDots, rZ);
		selectImage(tiledTemp); run("Morphological Filters", "operation=Dilation element=Diamond radius="+rDot); imgDiamonds = getImageID();
		selectImage(imgDiamonds); save(tempFolder + "diamonds-tiled-at-threshold-" + lowerThreshold + ".tif");
		
		// Calculate and record the total number of dots in the recording text file
		nDots = countDotByLabeling3D(imgDots);
		print(outFile, lowerThreshold + "\t" + nDots);

		// Release occupied memory
		selectImage(imgThreshold); run("Close");
		selectImage(imgDots); run("Close");
		selectImage(tiledTemp); run("Close");
		selectImage(imgDiamonds); run("Close");
		run("Collect Garbage");
		if ( nDots <= 1 ) { break; } // stop the loop when the number of dots are approaching 0
	}
	File.close(outFile);

	// Record the dot vs. threshold image stack for inspection
	dotVSthresholdTemp = tempFolder + filenamePrefix + "-dotsVSthreshold-temp.tif";
	run("Image Sequence...", "open=["+tempFolder+"] file=diamonds-tiled-at-threshold- sort use");
	save(dotVSthresholdTemp);

	// Release occupied memory
	run("Close All"); run("Collect Garbage");
	return 1;
}

function optimizeThreshold(outTextFilename, preProcessedFile, filteredFile, dotVSthresholdFile, outputFolder, tempFolder, sumTextWindow, filenamePrefix, optimizationCounter, timeStart) {
	setBatchMode(true);
	
	// Create a helpful plot to help the threshold choosing (nDots vs threshold)
	// Get the original x and y arrays from the output text file
	filestring=File.openAsString(outTextFilename);
	rows=split(filestring, "\n");
	x=newArray(rows.length-1); // "-1" because there is header
	y=newArray(rows.length-1); // "-1" because there is header
	for(i=1; i<rows.length; i++){
		// i starts from 1 to skip the header row
		columns=split(rows[i],"\t");
		x[i-1]=parseInt(columns[0]); //this is the 1st column
		y[i-1]=parseInt(columns[1]); //this is the 2nd column
	}
	
	// Normalization and transformation of arrays
	yNorm = normArray(y);
	yLog = logArrayPlus1(y);
	yLogNorm = normArray(yLog);
	xInterval = x[1] - x[0];

	// Plot the distributions in linear and log-transformed scales for inspection
	plotTitle = "Normalized Dot Number vs. Threshold";
	xTitle = "Threshold Level";
	yTitle = "nDots (gray) and log(nDots) (blue)";
	//plotOutputPath = outputFolder + filenamePrefix + "-" + plotTitle + ".tif";
	plotOutputPath = tempFolder + "plot-1-" + plotTitle + ".tif";
	makeHighRes = false;
	plot1X2Y(x, yNorm, yLogNorm, plotTitle, xTitle, yTitle, plotOutputPath, makeHighRes);

	setBatchMode(false);
	//open(plotOutputPath);
	plotID = getImageID();
	xCoordinate0 = -100;
	xCoordinate = getInitialX(plotID, xCoordinate0);
	while( xCoordinate == xCoordinate0) { xCoordinate = getInitialX(plotID, xCoordinate0); }
	if ( optimizationCounter == 1 ) { timeClicking0 = getTime(); }
	else { timeClicking0 = -1; }
	initPos = floor(xCoordinate/xInterval) + 1;
	run("Close All");
	
	// Open preProcessed, filtered and dotVSthreshold images (or MIP if 3D) for user to determine the best threshold
	satuLevel = 0.3;
	open(preProcessedFile); run("Enhance Contrast", "saturated=" + satuLevel); w1 = getTitle(); imageWidth = getWidth(); imageHeight = getHeight();
	open(filteredFile); run("Enhance Contrast", "saturated=" + satuLevel); w2 = getTitle();
	open(dotVSthresholdFile); imgDvsT = getImageID(); Stack.setSlice(initPos); w3 = getTitle();
	run("Synchronize Windows");
	//run("Tile");
	if ( imageWidth/imageHeight > 0.9 ) {
		iw = floor(screenWidth/3); zoomFactor = floor(100*iw/imageWidth)-5;
		if ( zoomFactor < 30 ) { zoomFactor = 30; }
		selectWindow(w1); setLocation(0, 120, iw, iw); run("Set... ", "zoom="+zoomFactor+" x=0 y=0"); getLocationAndSize(w1X, w1Y, w1Width, w1Height);
		selectWindow(w2); setLocation(iw, 120, iw, iw); run("Set... ", "zoom="+zoomFactor+" x=0 y=0"); getLocationAndSize(w2X, w2Y, w2Width, w2Height);
		selectWindow(w3); setLocation(2*iw, 120, iw, iw); run("Set... ", "zoom="+zoomFactor+" x=0 y=0"); getLocationAndSize(w3X, w3Y, w3Width, w3Height);
		selectWindow("Synchronize Windows");  setLocation(w1X, w1Y+w1Height);
		selectWindow(sumTextWindow); setLocation(w2X, w2Y+w1Height);
		selectWindow("Log"); setLocation(w3X, w3Y+w3Height);
	}
	else {
		ih = screenHeight-120; iw = floor(ih/3); zoomFactor = floor(100*iw/imageWidth)-5;
		if ( zoomFactor < 30 ) { zoomFactor = 30; }
		selectWindow(w1); setLocation(0, 120, iw, ih); run("Set... ", "zoom="+zoomFactor+" x=0 y=0"); getLocationAndSize(w1X, w1Y, w1Width, w1Height);
		selectWindow(w2); setLocation(iw, 120, iw, ih); run("Set... ", "zoom="+zoomFactor+" x=0 y=0"); getLocationAndSize(w2X, w2Y, w2Width, w2Height);
		selectWindow(w3); setLocation(2*iw, 120, iw, ih); run("Set... ", "zoom="+zoomFactor+" x=0 y=0"); getLocationAndSize(w3X, w3Y, w3Width, w3Height);
		selectWindow("Synchronize Windows");  setLocation(3*iw, 120);
		selectWindow(sumTextWindow); setLocation(3*iw, iw+120);
		selectWindow("Log"); setLocation(3*iw, 2*iw+120);
	}
	
	// Let the user choose the best threhold level
	waitForUser("1. (Optional, but very helpful for cross-reference windows.)\n"+
				"     In \"Synchronize Windows,\" make sure \"Sync Cursor,\" \"Sync z-Slices,\"\n"+
				"     \"Sync Channels\" and \"Image Coordinates\" are checked.\n"+
				"     Then click the \"Synchronize All\" button.\n"+
				" \n"+
				"2. Go through the dot vs. threshold image stack,\n"+
				"     and stop at where you think is the best segmentation.\n\n"+
				" \n"+
				"3. Click \"OK\" to continue.");
	selectImage(imgDvsT);
	selectedPos = getSliceNumber() - 1; // "-1" because image slice number starts from 1 instead of 0
	
	run("Close All");
	setBatchMode(true);

	//--------------
	// Record a few key parameters in the "Summary" text window
	//--------------
	nDots = y[selectedPos];
	selectedThreshold = selectedPos * xInterval;
	print("["+sumTextWindow+"]", "\n" + filenamePrefix + "\t" + selectedThreshold + "\t" + nDots);

	//--------------
	// Record segmented dots image stack
	//--------------
	open(tempFolder + "dots-at-threshold-" + selectedThreshold + ".tif"); imgDots = getImageID();
	save(outputFolder + filenamePrefix + "-dots.tif");
	
	//--------------
	// High Resolution Plots
	//--------------

	// Plot the distributions in linear and log-transformed scales for inspection
	plotTitle = "Normalized Dot Number vs. Threshold";
	xTitle = "Threshold Level";
	yTitle = "nDots (gray) and log(nDots) (blue)";
	//plotOutputPath = outputFolder + filenamePrefix + "-" + plotTitle + ".tif";
	plotOutputPath = outputFolder + filenamePrefix + "-plot1-" + plotTitle + ".tif";
	makeHighRes = 2.0;
	plot1X2Y(x, yNorm, yLogNorm, plotTitle, xTitle, yTitle, plotOutputPath, makeHighRes);

	// Plot the selected threshold graph in log scale
	xMark = x[selectedPos];
	yMark = yLog[selectedPos];
	plotTitle = "Dot Number vs. Threshold";
	xTitle = "Threshold Level";
	yTitle = "Log(Dot Number)";
	//plotOutputPath = outputFolder + filenamePrefix + "-" + plotTitle + ".tif";
	plotOutputPath = outputFolder + filenamePrefix + "-plot2-" + plotTitle + ".tif";
	makeHighRes = 2.0;
	plotXYmarkCross(x, yLog, xMark, yMark, nDots, plotTitle, xTitle, yTitle, plotOutputPath, makeHighRes);
	
	// Plot the selected threshold graph in linear scale
	xMark = x[selectedPos];
	yMark = y[selectedPos];
	plotTitle = "Dot Number vs. Threshold";
	xTitle = "Threshold Level";
	yTitle = "Dot Number";
	//plotOutputPath = outputFolder + filenamePrefix + "-" + plotTitle + ".tif";
	plotOutputPath = outputFolder + filenamePrefix + "-plot3-" + plotTitle + ".tif";
	makeHighRes = 2.0;
	plotXYmarkCross(x, y, xMark, yMark, nDots, plotTitle, xTitle, yTitle, plotOutputPath, makeHighRes);

	// release occupied memory
	run("Close All"); run("Collect Garbage");
	if ( timeStart == -1 ) { timeStart = timeClicking0; }// Get the time of clicking on the 1st image for optimization
	return timeStart;
}

//---------------------
// Supporting Functions (Image handling)
//---------------------

function getMedian(imgID, indexS) {
// Returns median for 2D; returns the median of the 1st slice for 3D; when median is 0, make it 1
	selectImage(imgID); getDimensions(w, h, c, s, f);
	if ( s == 1 ) { run("Set Measurements...", "median"); List.setMeasurements(); m = List.getValue("Median"); }
	else { Stack.setSlice(indexS); run("Set Measurements...", "median"); List.setMeasurements(); m = List.getValue("Median"); }
	if ( m == 0 ) { m = 1; }
	run("Set Measurements...", "area mean standard min");//reset the measurements to default
	return m;
}

function convertTo8bit(imgID, satuLevel) {
// Convert image to 8-bit with specified saturation; small amount saturation helps to make it insensitive to rare spike noise
// For 3D image, the min and max is determined by projecting the z-stack as "Max Intensity" or "Min Intensity", then apply the specified display saturation
	selectImage(imgID);
	if ( bitDepth() == 8 ) { return imgID; }
	if ( nSlices == 1 ) {
		selectImage(imgID); run("Enhance Contrast", "saturated=" + satuLevel); run("8-bit"); img8bit = getImageID();
		return img8bit;
	}
	else {
		selectImage(imgID); run("Z Project...", "projection=[Max Intensity]"); imgMax = getImageID();
		selectImage(imgID); run("Z Project...", "projection=[Min Intensity]"); imgMin = getImageID();
		selectImage(imgMax); run("Enhance Contrast", "saturated=" + satuLevel); getMinAndMax(min0, max);
		selectImage(imgMin); run("Enhance Contrast", "saturated=" + satuLevel); getMinAndMax(min, max0);
		selectImage(imgMax); run("Close"); selectImage(imgMin); run("Close"); run("Collect Garbage"); // release occupied memory
		selectImage(imgID); setMinAndMax(min, max); run("8-bit"); img8bit = getImageID();
		return img8bit;
	}
}

function ratioCorrection(imgID) {
// imgID has to be a stack; return the original if it is single slice
	selectImage(imgID);
	if ( nSlices == 1 ) { run("Duplicate...", " "); ratioCorrID = getImageID(); }
	else {
		selectImage(imgID); setSlice(1); getStatistics(area, mean1); setSlice(nSlices); getStatistics(area, meanN);
		selectImage(imgID); run("Z Project...", "projection=[Min Intensity]"); minID = getImageID(); getStatistics(area, mean, BG);
		if ( mean1 >= meanN ) { selectImage(imgID); run("Bleach Correction", "correction=[Simple Ratio] background="+BG); ratioCorrID = getImageID(); }
		else {
			selectImage(imgID); run("Reverse"); run("Bleach Correction", "correction=[Simple Ratio] background="+BG); ratioCorrID = getImageID();
			selectImage(ratioCorrID); run("Reverse"); selectImage(imgID); run("Reverse");
		}
		selectImage(minID); run("Close"); run("Collect Garbage"); // release occupied memory
	}
	return ratioCorrID;
}

function matchHistogram(imgID, refImgFile, filenamePrefix) {
// Attach the reference image to the beginning of an image (or stack), perform histogram matching, and return it after removing the reference slice
// Note that the histogram matching algorithm performs way faster when feeding 8-bit images than higher bit-depth images
	open(refImgFile); refID = getImageID(); rename("Reference Image for Histogram Matching"); refTitle = getTitle();
	selectImage(imgID); rename(filenamePrefix); imgTitle = getTitle();
	run("Concatenate...", "open image1=["+refTitle+"] image2=["+imgTitle+"] image3=[-- None --]"); refNimgID = getImageID();
	selectImage(refNimgID); run("Bleach Correction", "correction=[Histogram Matching]"); refNimgID_HM = getImageID();
	selectImage(refNimgID_HM); setSlice(1); run("Delete Slice");
	return refNimgID_HM;
}

function matchMedianTo8bit(imgID, refMedian0, refRange0, s, satuLevel) {
// Use image median as reference to match the intensity of imgID to the refMedian and refRange values; process the specified slice for stacks
	selectImage(imgID);
	if ( nSlices == 1 ) { run("Duplicate...", " "); idMedianMatched = getImageID(); }
	else { setSlice(s); run("Duplicate...", " "); idMedianMatched = getImageID(); }
	selectImage(idMedianMatched); satuLevel = 0.1; run("Enhance Contrast", "saturated=" + satuLevel); getMinAndMax(min0, max0);
	median0 = getMedian(idMedianMatched, 1) - min0; ratioMedian0 = refMedian0 / median0;
	selectImage(idMedianMatched); run("Subtract...", "value="+min0); run("Multiply...", "value="+ratioMedian0); 
	if ( bitDepth() == 8 ) { selectImage(idMedianMatched); run("16-bit"); }
	selectImage(idMedianMatched); setMinAndMax(0, refRange0); run("8-bit");
	return idMedianMatched;
}

function getTiled(imgID, rZ) {
	if ( rZ <= 0 ) {
		selectImage(imgID); getDimensions(w, h, c, s, f); // w, h, c, s, f => width, height, channels, slices, frames
		// Take the slice at 1/3 and 2/3 for presentation
		s1 = floor( s/3 ) + 1; s2 = floor( s*2/3 ) + 1;
		selectImage(imgID); Stack.setSlice(s1); run("Duplicate...", " "); rename("s1");
		selectImage(imgID); Stack.setSlice(s2); run("Duplicate...", " "); rename("s2");
		// Combine s1, s2, then MIP for presentation
		run("Combine...", "stack1=s1 stack2=s2 combine"); rename("s12");
		selectImage(imgID); run("Z Project...", "projection=[Max Intensity]"); rename("MIP");
		run("Combine...", "stack1=s12 stack2=MIP combine"); rename("s12MIP"); idS12MIP = getImageID();
		return idS12MIP;
	}
	else {
		selectImage(imgID); getDimensions(w, h, c, s, f); // w, h, c, s, f => width, height, channels, slices, frames
		// Take the slice at 1/3 as slice 1 for presentation
		s1 = floor( s/3 ) + 1; zStart = s1 - rZ; zEnd = s1 + rZ;
		selectImage(imgID); run("Duplicate...", "duplicate range="+zStart+"-"+zEnd); idS1z = getImageID();
		selectImage(idS1z); run("Z Project...", "projection=[Max Intensity]"); rename("s1");
		// Take the slice at 2/3 as slice 1 for presentation
		s2 = floor( s*2/3 ) + 1; zStart = s2 - rZ; zEnd = s2 + rZ;
		selectImage(imgID); run("Duplicate...", "duplicate range="+zStart+"-"+zEnd); idS2z = getImageID();
		selectImage(idS2z); run("Z Project...", "projection=[Max Intensity]"); rename("s2");
		// Combine s1, s2 and then MIP for presentation
		run("Combine...", "stack1=s1 stack2=s2 combine"); rename("s12");
		selectImage(imgID); run("Z Project...", "projection=[Max Intensity]"); rename("MIP");
		run("Combine...", "stack1=s12 stack2=MIP combine"); rename("s12MIP"); idS12MIP = getImageID();
		// Release occupied memory
		selectImage(idS1z); run("Close");
		selectImage(idS2z); run("Close");
		run("Collect Garbage");
		return idS12MIP;
	}
}

function countDotByLabeling3D(imgID) {
	selectImage(imgID); run("Connected Components Labeling", "connectivity=26 type=float"); imgLbl = getImageID();
	selectImage(imgLbl); run("Z Project...", "projection=[Max Intensity]"); imgLblMIP = getImageID();
	selectImage(imgLblMIP); getStatistics(area, mean, min, max); nDots = max;
	selectImage(imgLbl); run("Close");
	selectImage(imgLblMIP); run("Close");
	run("Collect Garbage");
	return nDots;
}

function countVoxel3D(imgID, grayValue) {
	selectImage(imgID);
	getDimensions(w, h, c, s, f);
	nVoxel = 0;
	for (i=1; i<s+1; i++) {
		selectImage(imgID); Stack.setSlice(i); getStatistics(area, mean, min, max, std, histogram);
		temp = histogram[grayValue]; nVoxel = nVoxel + temp;
	}
	return nVoxel;
}

//---------------------
// Supporting Functions (Interaction with users)
//---------------------

function getInitialX(imgID, xCoordinate0) {
	// Set an initial x coordinate value
	xCoordinate=xCoordinate0;
	xCoordinate2=-1; yCoordinate2=-1; zCoordinate2=-1; flags2=-1;
	leftButton=16;
	while( isOpen(imgID) ) {
		selectImage(imgID);
		getCursorLoc(xTemp, yCoordinate, zCoordinate, flags);
		if (xCoordinate!=xCoordinate2 || yCoordinate!=yCoordinate2 || zCoordinate!=zCoordinate2) {
			if (flags==leftButton){
				toScaled(xTemp); xCoordinate = xTemp;
				xCoordinate2=xCoordinate; yCoordinate2=yCoordinate; zCoordinate2=zCoordinate; flags2=flags; wait(10);
			}
		}
		if (xCoordinate!=xCoordinate0) { selectImage(imgID); run("Close"); }
	}
	return xCoordinate;
}

//---------------------
// Supporting Functions (Filename handling, get time, formatting numbers etc)
//---------------------

function matchDigit(i, n) {
// A string of i with leading 0's matching the digit number of n will be returned.  Only the integer part will be considered.
	if ( i > n ) { print("WARNING, the query number is larger than the upper limit.  Returning itself."); return toString(i, 0); }
	nDigits = floor(log(n)/log(10)) + 1; iDigits = floor(log(i)/log(10)) + 1;
	if ( iDigits == nDigits ) { return toString(i, 0); }
	iString = toString(i, 0);
	for ( d=0; d<nDigits-iDigits; d++ ) { iString = "0" + iString; }
	return iString;
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

function deleteFolder(folder) {
	// Delete all the files inside the folder, then the folder itself
	list = getFileList(folder);
	// Delete the files and the folder
	for (i=0; i<list.length; i++){
		ok = File.delete(folder+list[i]);
	}
	ok = File.delete(folder);
	if (File.exists(folder))
		exit("Unable to delete the folder: " + folder);
	else
		print("Successfully deleted: " + folder);
}

function getTimeString(message) {
	MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
	DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	TimeString = message+MonthNames[month]+" ";
	if (dayOfMonth<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+dayOfMonth+", "+year+" "+DayNames[dayOfWeek]+" ";
	if (hour<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+hour+":";
	if (minute<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+minute+":";
	if (second<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+second;
	//showMessage(TimeString);
	return TimeString;
}

//---------------------
// Plotting functions
//---------------------

function plot1X2Y(x, y1, y2, plotTitle, xTitle, yTitle, plotOutputPath, makeHighRes) {
	// Create an empty plot
	Plot.create(plotTitle, xTitle, yTitle);
	//Plot.create(plotTitle, xTitle, yTitle, x, y);
	
	// Get the basic stats of the two arrays for plotting
	Array.getStatistics(x, xMin, xMax);
	Array.getStatistics(y1, y1Min, y1Max);
	Array.getStatistics(y2, y2Min, y2Max);
	yMinMaxes = newArray(y1Min, y2Min, y1Max, y2Max);
	Array.getStatistics(yMinMaxes, yMin, yMax);
	
	// Expand the limit of plot
	xL = xMin - 0.1*(xMax-xMin);
	xR = xMax + 0.1*(xMax-xMin);
	yL = yMin - 0.1*(yMax-yMin);
	yR = yMax + 0.1*(yMax-yMin);
	Plot.setLimits(xL, xR, yL, yR);
	//Plot.setFrameSize(500, 500);

	// Draw the 1st line in black
	Plot.setLineWidth(2);
	Plot.setColor("black");
	Plot.add("line", x, y1);
	// Draw the 2nd line in blue
	Plot.setColor("blue");
	Plot.add("line", x, y2);
	Plot.show();
	
	if ( makeHighRes > 0 )
		Plot.makeHighResolution(plotTitle, makeHighRes);
	saveAs("tiff", plotOutputPath);
}

function plotXYmarkCross(x, y, xMark, yMark, nDotsFinal, plotTitle, xTitle, yTitle, plotOutputPath, makeHighRes) {
	// Create an empty plot
	Plot.create(plotTitle, xTitle, yTitle);
	//Plot.create(plotTitle, xTitle, yTitle, x, y);
	
	// Get the basic stats of the two arrays for plotting
	Array.getStatistics(x, xMin, xMax);
	Array.getStatistics(y, yMin, yMax);
	
	// Expand the limit of plot
	xL = xMin - 0.1*(xMax-xMin);
	xR = xMax + 0.1*(xMax-xMin);
	yL = yMin - 0.1*(yMax-yMin);
	yR = yMax + 0.1*(yMax-yMin);
	Plot.setLimits(xL, xR, yL, yR);
	//Plot.setFrameSize(500, 500);

	// Draw the original data in a series of dots
	Plot.setLineWidth(6.0);
	Plot.setColor("lightGray");
	Plot.add("dots", x, y);
	// Draw the original line on top of the dots
	Plot.setLineWidth(2);
	Plot.setColor("blue");
	Plot.add("line", x, y);
	// Use a red cross to highlight (xMark, yMark)
	Plot.setColor("red");
	Plot.add("line", newArray(xL, xR), newArray(yMark, yMark));
	Plot.add("line", newArray(xMark, xMark), newArray(yL, yR));
	
	// Add some annotation to the plot
	setJustification("right");
	Plot.addText("Selected threshold value: " + xMark, 0.99, 0.1);
	Plot.addText("The total dot number: " + nDotsFinal, 0.99, 0.15);
	Plot.show();

	if ( makeHighRes > 0 )
		Plot.makeHighResolution(plotTitle, makeHighRes);
	saveAs("tiff", plotOutputPath);
}

//---------------------
// Array Functions
//---------------------

function arange(N) {
	x = newArray(N);
	for (i=0; i<N; i++) {
		x[i] = i;
	}
	return x;
}

function divideArray(y, N) {
	yFold = newArray(y.length);
	for (i=0; i<yFold.length; i++) {
		yFold[i] = y[i] / N;
	}
	return yFold;
}

function sqrArray(y) {
	ySqr = newArray(y.length);
	for (i=0; i<ySqr.length; i++) {
		ySqr[i] = y[i] * y[i];
	}
	return ySqr;
}

function normArray(y) {
	Array.getStatistics(y, yMin, yMax);
	yNorm = newArray(y.length);
	if ( yMax-yMin == 0 ) {
		for(i=0; i<y.length; i++){
			yNorm[i] = 1;
		}
	}
	for(i=0; i<y.length; i++){
		yNorm[i] = ( y[i]-yMin ) / ( yMax-yMin );
	}
	return yNorm;
}

function logArray(y) {
	// y must be an array with more than 1 elements
	yLog = newArray(y.length);
	for (i=0; i<yLog.length; i++) {
		yLog[i] = log(y[i]);
	}
	return yLog;
}

function logArrayPlus1(y) {
	// y must be an array with more than 1 elements
	yLog = newArray(y.length);
	for (i=0; i<yLog.length; i++) {
		yLog[i] = log(y[i]+1);
	}
	return yLog;
}

function expArray(y) {
	// y must be an array with more than 1 elements
	yExp = newArray(y.length);
	for (i=0; i<yExp.length; i++) {
		yExp[i] = exp(y[i]);
	}
	return yExp;
}

function expArrayMinus1(y) {
	// y must be an array with more than 1 elements
	yExp = newArray(y.length);
	for (i=0; i<yExp.length; i++) {
		yExp[i] = exp(y[i]-1);
	}
	return yExp;
}

function diff(y) {
	// y must be an array with more than 1 elements
	if (y.length < 2) {
		exit("This array has less than 2 elements, so differential makes NO sense!");
	}
	
	yDiff = newArray(y.length-1);
	for (i=0; i<yDiff.length; i++) {
		yDiff[i] = y[i+1] - y[i];
	}
	return yDiff;
}

function diff2(y) {
	// y must be an array with more than 2 elements
	yDiff1 = diff(y);
	yDiff2 = diff(yDiff1);
	return yDiff2;
}

function getMinIndex(x) {
	ranks = Array.rankPositions(x);
	return ranks[0];
}

function getMaxIndex(x) {
	ranks = Array.rankPositions(x);
	return ranks[x.length-1];
}