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
// Create a log_files folder
logFolder = outputFolder + "log_files" + File.separator;
if ( !(File.exists(logFolder)) ) { File.makeDirectory(logFolder); }

// rGB is the radius for Gaussian filter -- 1 is good to filter out camera noise
rGB = 1;
rGB_z = 1;
// rTophat is the radius of morphological element (disk or ball for 2d or 3d) used for Morphological Top Hat filter,
// a typical good value is the average radius of the dot you care about.
rTophat = 4;
rTophat_z = 2;
// thresholdLevel is used for thresholding the filtered image to count dots
thresholdLevel = 40;
// this is the channel number for smFISH -- used in preProcessing step if there is more than 1 channel
targetChannel = 2;
// If APPLY_ROI is true, the macro counts the dot number inside and outside the ROI in addition to a total number
APPLY_ROI = false;
// Toggle this setting true or false to display the results files one by one after processing all images
SHOW_RESULTS = false;
// Create a dialog to allow user to modify the parameters
Dialog.create("Modify Parameters");
Dialog.addNumber("Gaussian Blur Radius (xy) in pixels:", rGB);
Dialog.addNumber("Morphological Top-hat Radius (xy) in pixels:", rTophat);
Dialog.addNumber("Selected Threshold Level:", thresholdLevel);
Dialog.addMessage("For multi-channel images (ignore for 1-channel)\n");
Dialog.addNumber("Which channel to process?", targetChannel);
Dialog.addMessage("For 3D images (ignore for 2D)\n");
Dialog.addNumber("Gaussian Blur Radius (z) in voxels:", rGB_z);
Dialog.addNumber("Morphological Top-hat Radius (z) in voxels:", rTophat_z);
Dialog.addCheckbox("Count dots inside and outside specified ROI?", APPLY_ROI);
Dialog.addCheckbox("Show results one-by-one after processing all", SHOW_RESULTS);
Dialog.show();
rGB = Dialog.getNumber();
rTophat = Dialog.getNumber();
thresholdLevel = Dialog.getNumber();
targetChannel = Dialog.getNumber();
rGB_z = Dialog.getNumber();
rTophat_z = Dialog.getNumber();
APPLY_ROI = Dialog.getCheckbox();
SHOW_RESULTS = Dialog.getCheckbox();
// The rDot controls the diamond radius used to enlarge dots for visualization
//rDot = rTophat;
rDot = rTophat-1;
// rDot_z controls how many z-slices (+- from center) to project for inspection
rDot_z = rTophat_z;

print(getTimeString("Started at: "));
// Print out used parameters
print("############################################################################################################################################################");
print("Input folder: " + inputFolder);
print("---------------------------------------------------------");
print("Gaussian Blur Radius (xy) in pixels: " + rGB);
print("Morphological Tophat Radius (xy) in pixels: " + rTophat);
print("Selected Threshold Level: " + thresholdLevel);
print("---------------------------------------------------------");
print("For multi-channel images (ignore for 1-channel):");
print("Which channel to process? " + targetChannel);
print("---------------------------------------------------------");
print("For 3D images (ignore for 2D):");
print("Gaussian Blur Radius (z) in voxels: " + rGB_z);
print("Morphological Tophat Radius (z) in voxels: " + rTophat_z);
print("---------------------------------------------------------");
print("Count dots inside and outside specified ROI? " + APPLY_ROI);
print("Show results after processing each file? " + SHOW_RESULTS);
print("############################################################################################################################################################");
// This is the main function that handles the user interface
processFolder(inputFolder, outputFolder, logFolder, rGB, rTophat, rGB_z, rTophat_z, targetChannel, thresholdLevel, APPLY_ROI);
print(getTimeString("Finished at: "));
// Save the log file
timeFinish = getTime(); timeStamp = timeFinish % 10000;// time stamp for saving log and summary text files
selectWindow("Log"); saveAs("txt", logFolder + "processingAll-log-" + timeStamp + ".txt");
showMessage("All images processed.  Check the outputfolder for output images and record text files.");
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
// the image is 2D, "Find Maxima..." with a noise level of 1 is used. When the image is 3D, a "Regional
// Maxima" function from the MorphoLibJ library is used.
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
//         (3-4) An enlarged dot image to match the expected dot size
//         (3-5) A plot of "Dot Nubmer vs. Threshold Level" in both linear and log scales
//         (3-6) A plot of "Dot Nubmer vs. Threshold Level" in linear scale, where the selected threshold 
// level is marked by a red cross.
//         (3-7) A plot of "Dot Nubmer vs. Threshold Level" in log scale, where the selected threshold 
// level is marked by a red cross.
//         For the entire image set:
//         (3-8) A summary text file with a list of image name, selected threshold level and dot number
//         (3-9) A log file with parameters and outer intermediate outputs (helpful for troubleshooting)
// -------------------------------------------------------------------------------------------------------

//---------------------
// Main Functions
//---------------------

function processFolder(inputFolder, outputFolder, logFolder, rGB, rTophat, rGB_z, rTophat_z, targetChannel, thresholdLevel, APPLY_ROI) {
// This function processes all files in the inputFolder
	setBatchMode(true);
	
	// Create a text window to record the summary of dot counting information
	sumTextWindow = "processingAll-Summary";
	if ( isOpen(sumTextWindow) ) { print("["+sumTextWindow+"]", "\\Update:"); } // clears the window
	else { run("Text Window...", "name=["+sumTextWindow+"]"); }
	if ( APPLY_ROI == true ) { print("["+sumTextWindow+"]", "file_name\tselected_threshold\ttotal_dot_number\tinside_ROI\toutside_ROI\tarea_ROI"); }
	else { print("["+sumTextWindow+"]", "file_name\tselected_threshold\ttotal_dot_number"); }
	
	time0 = getTime();//time in milliseconds
	fList = getFileList(inputFolder);
	refMedian = -1; refRange = -1; // Initialize with impossible values to ensure the 1st pass of processing computes these values from the 1st image
	for (i=0; i<fList.length; i++) {
		f = fList[i];
		if ( endsWith(f, File.separator) || startsWith(f, ".") || startsWith(f, "~") || startsWith(f, "_") ) { continue; } //skip if f is a folder, or system files
		refValues = processImage(inputFolder+f, outputFolder, logFolder, rGB, rTophat, rGB_z, rTophat_z, targetChannel, thresholdLevel, sumTextWindow, APPLY_ROI, refMedian, refRange);
		refMedian = refValues[0]; refRange = refValues[1];
	}
	// Print out the time cost of hands-free processing time
	time1 = getTime();//time in milliseconds
	duration = floor( (time1-time0)/1000 );//time in seconds
	timeStamp = time1 % 10000;// time stamp for saving log and summary text files
	print("Processing all images with selected threhold level took: " + duration + " seconds.");
	
	// Save and close the summary text window
	selectWindow(sumTextWindow);
	sumOutFile = outputFolder + inputFolderPrefix + "-" + sumTextWindow + "-" + timeStamp + ".txt";
	saveAs("txt", sumOutFile); run("Close");

	time0 = getTime();//time in milliseconds
	fList = getFileList(inputFolder);
	for (i=0; i<fList.length; i++) {
		f = fList[i];
		if ( endsWith(f, File.separator) || startsWith(f, ".") || startsWith(f, "~") || startsWith(f, "_") ) { continue; } //skip if f is a folder, or system files
		filenamePrefix = getFilenamePrefix(f);
		if ( SHOW_RESULTS ) {
			showResults(outputFolder, filenamePrefix+"-", "-preProcessed.tif", "-filtered.tif", "-enlargedDots.tif");
			waitForUser("Inspect the output images at selected threshold.\n"+
						"   Click OK to continue processing the next.");
		}
	}
	// Print out the time cost of hands-free processing time
	time1 = getTime();//time in milliseconds
	duration = floor( (time1-time0)/1000 );//time in seconds
	print("Inspecting processed images took: " + duration + " seconds.");
	
	// Reset measurement settings, clear up workspace
	run("Set Measurements...", "area mean standard min");
	if ( isOpen("Synchronize Windows") ) { selectWindow("Synchronize Windows"); run("Close"); }
	if ( isOpen("Results") ) { selectWindow("Results"); run("Close"); }
	if ( isOpen("ROI Manager") ) { selectWindow("ROI Manager"); run("Close"); }
	run("Close All"); run("Collect Garbage");// Release occupied memory
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

function processImage(imgFile, outputFolder, logFolder, rGB, rTophat, rGB_z, rTophat_z, targetChannel, thresholdLevel, sumTextWindow, APPLY_ROI, refMedian, refRange) {
// This function routes the image through the intended flow of processing
	setBatchMode(true);
	filenamePrefix = getPathFilenamePrefix(imgFile);
	tempFolder = outputFolder + filenamePrefix + "-temp" + File.separator;
	preProcessedFile = outputFolder + filenamePrefix + "-preProcessed.tif";
	filteredFile = outputFolder + filenamePrefix + "-filtered.tif";
	refImgFile = logFolder + "refImage.tif";
	refValues = newArray(-1, -1);
	print("************************************************************************************************************************************************************");
	print("Processing: " + filenamePrefix);
	// The following if-else statements assess whether a filtered image exists, and starts from filtered if it does
	if ( File.exists(filteredFile) ) {
		print("Filtered image found. Processing from filtered.");
		segDotImg(filteredFile, outputFolder, filenamePrefix, thresholdLevel, sumTextWindow, rDot, rDot_z, APPLY_ROI);
		print("Finished processing: " + filenamePrefix);
		print("************************************************************************************************************************************************************");
		return refValues;
	}
	// The following if-else statements assess whether a pre-processed image exists, and starts from it if it does
	if ( File.exists(preProcessedFile) ) {
		print("Pre-processed but unfiltered image found. Processing from pre-processed.");
		filterImg(preProcessedFile, filteredFile, rGB, rTophat, rGB_z, rTophat_z);
		segDotImg(filteredFile, outputFolder, filenamePrefix, thresholdLevel, sumTextWindow, rDot, rDot_z, APPLY_ROI);
		print("Finished processing: " + filenamePrefix);
		print("************************************************************************************************************************************************************");
		return refValues;
	}
	// The following processes the image from the beginning
	else {
		refValues = preProcessImg(inputFolder+f, preProcessedFile, targetChannel, tempFolder, filenamePrefix, refMedian, refRange, refImgFile);
		filterImg(preProcessedFile, filteredFile, rGB, rTophat, rGB_z, rTophat_z);
		segDotImg(filteredFile, outputFolder, filenamePrefix, thresholdLevel, sumTextWindow, rDot, rDot_z, APPLY_ROI);
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
	open(imgFile); id = getImageID(); getDimensions(w, h, c, s, f); // w, h, c, s, f => width, height, channels, slices, frames
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
		if ( s == 1 ) { selectImage(id); run("Duplicate...", "duplicate range=1"); run("Grays"); idSelected = getImageID(); }
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

function countDotROI2D(imgDots, ROIfile, nDots) {
	if ( File.exists(ROIfile) ) {
		roiManager("Reset"); roiManager("Open", ROIfile);
		selectImage(imgDots); roiManager("Select", 0);
		getStatistics(area, mean, min, max, std, histogram); nDotsIn = histogram[255];
		run("Select None");
		return nDotsIn;
	}
	else { return nDots; }
}

function getROIarea2D(imgDots, ROIfile) {
	if ( File.exists(ROIfile) ) {
		roiManager("Reset"); roiManager("Open", ROIfile);
		selectImage(imgDots); roiManager("Select", 0);
		getStatistics(area);// in scale units (usually squared microns)
		run("Select None");
		return area;
	}
	else {
		selectImage(imgDots);
		run("Select None");
		getStatistics(area);// total area in scale units (usually squared microns)
		return area;
		}
}

function countDotROI3D(imgDots, ROIset, nDots) {
	if ( File.exists(ROIset) ) {
		roiManager("Reset"); roiManager("Open", ROIset); roiN = roiManager("count");
		selectImage(imgDots);	getDimensions(w, h, c, s, f);// w, h, c, s, f => width, height, channels, slices, frames
		// Use the smaller value of s and roiN as the loop max
		if ( s <= roiN ) { maxN = s; }
		else  { maxN = roiN; }
		for (i=0; i<maxN; i++) {
			selectImage(imgDots); roiManager("Select", i); setSlice(i);
			run("Clear Outside"); run("Select None");
		}
		nDotsIn = countDotByLabeling3D(imgDots);
		return nDotsIn;
	}
	else { return nDots; }
}

function segDotImg(filteredFile, outputFolder, filenamePrefix, thresholdLevel, sumTextWindow, rDot, rDot_z, APPLY_ROI) {
// This function takes the filtered 2D or 3D images, identify dots at using maxima finding and thresholding, and count the dots
// output the segmented dot image, dilated "diamond" image, and the number of counted dots
	setBatchMode(true);
	ROIfolder = outputFolder + "ROIs" + File.separator;
	ROIfile = ROIfolder + filenamePrefix + ".roi";
	ROIset = ROIfolder + filenamePrefix + "-ROIset.zip";
	open(filteredFile); imgTophat = getImageID();
	selectImage(imgTophat);	getDimensions(w, h, c, s, f);// w, h, c, s, f => width, height, channels, slices, frames
	if (s == 1) {
		// Find maxima points and output single-pixel points selection
		noiseLevel = getMedian(imgTophat, 1);
		selectImage(imgTophat);	run("Find Maxima...", "noise=" + noiseLevel + " output=[Single Points] exclude"); imgMaxima = getImageID();
		// Duplicate the White Top Hat filtered image, threshold it at current fold of median
		selectImage(imgTophat); setThreshold(thresholdLevel, 65535); // 65535 is the max possible for 16-bit image
		run("Convert to Mask"); imgThreshold = getImageID();
		// Filter out the initial maxima points below the threshold value
		imageCalculator("AND create", imgMaxima, imgThreshold); run("Grays"); imgDots = getImageID();
		selectImage(imgDots); save(outputFolder + filenamePrefix + "-dots.tif");
		selectImage(imgDots); run("Morphological Filters", "operation=Dilation element=Disk radius="+rDot); imgEnlargedDots = getImageID();
		selectImage(imgEnlargedDots); save(outputFolder + filenamePrefix + "-enlargedDots.tif");
		// Count the total number of dots by counting the number of pixels with gray value 255 in "imgDots"
		selectImage(imgDots); getStatistics(area, mean, min, max, std, histogram); nDots = histogram[255];
		if ( APPLY_ROI == true ) {
			nDotsIn = countDotROI2D(imgDots, ROIfile, nDots); nDotsOut = nDots - nDotsIn;
			areaROI = getROIarea2D(imgDots, ROIfile);
			// record the total number of dots in the summary text file
			print("["+sumTextWindow+"]", "\n" + filenamePrefix + "\t" + thresholdLevel + "\t" + nDots + "\t" + nDotsIn + "\t" + nDotsOut + "\t" + areaROI);
		}
		else {
			// record the total number of dots in the summary text file
			print("["+sumTextWindow+"]", "\n" + filenamePrefix + "\t" + thresholdLevel + "\t" + nDots);
		}
		run("Close All"); run("Collect Garbage");// Release occupied memory
		return 1;
	}
	else {
		// Find maxima points and output single-pixel points selection
		noiseLevel = getMedian(imgTophat, 1);
		//selectImage(imgTophat); run("Regional Min & Max 3D", "operation=[Regional Maxima] connectivity=26"); imgMaxima = getImageID();
		selectImage(imgTophat); run("Extended Min & Max 3D", "operation=[Extended Maxima] dynamic="+noiseLevel+" connectivity=26"); imgMaxima = getImageID();
		// Duplicate the White Top Hat filtered image, threshold it at current fold of median
		selectImage(imgTophat);	setThreshold(thresholdLevel, 65535); // 65535 is the max possible for 16-bit image
		run("Convert to Mask", "method=Default background=dark"); imgThreshold = getImageID();
		// Filter out the initial maxima points below the threshold value
		imageCalculator("AND create stack", imgMaxima, imgThreshold); run("Grays"); imgDots = getImageID();
		selectImage(imgDots); save(outputFolder + filenamePrefix + "-dots.tif");
		selectImage(imgDots); run("Morphological Filters (3D)", "operation=Dilation element=Ball x-radius="+rDot+" y-radius="+rDot+" z-radius="+rDot_z); imgEnlargedDots = getImageID();
		selectImage(imgEnlargedDots); save(outputFolder + filenamePrefix + "-enlargedDots.tif");
		// Count total dots by connected object labeling (from MorphoLibJ)
		selectImage(imgDots); nDots = countDotByLabeling3D(imgDots);
		if ( APPLY_ROI == true ) {
			nDotsIn = countDotROI3D(imgDots, ROIset, nDots); nDotsOut = nDots - nDotsIn;
			// record the total number of dots in the summary text file
			print("["+sumTextWindow+"]", "\n" + filenamePrefix + "\t" + thresholdLevel + "\t" + nDots + "\t" + nDotsIn + "\t" + nDotsOut);
		}
		else {
			// record the total number of dots in the summary text file
			print("["+sumTextWindow+"]", "\n" + filenamePrefix + "\t" + thresholdLevel + "\t" + nDots);
		}
		run("Close All"); run("Collect Garbage");// Release occupied memory
		return 1;
	}
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
	if ( yMax-yMin == 0 ) {
		for(i=0; i<y.length; i++){
			yNorm[i] = 1;
		}
	}
	yNorm = newArray(y.length);
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