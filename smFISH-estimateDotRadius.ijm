// Clear up workspace
run("Close All"); run("Collect Garbage"); // Release occupied memory
if ( isOpen("Synchronize Windows") ) { selectWindow("Synchronize Windows"); run("Close"); }
if ( isOpen("Log") ) { selectWindow("Log"); run("Close"); }
if ( isOpen("Debug") ) { selectWindow("Debug"); run("Close"); }
if ( isOpen("Results") ) { selectWindow("Results"); run("Close"); }
if ( isOpen("ROI Manager") ) { selectWindow("ROI Manager"); run("Close"); }

file=File.openDialog("Select a File");
print("This file was used to estimate the dot radius:\n" + file + "\n");
// Create an output folder based on the inputFolder
inputFolder = getPath(file); parentFolder = getPath(inputFolder); prefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + prefix + "-output" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }
// Create a log_files folder
logFolder = outputFolder + "log_files" + File.separator;
if ( !(File.exists(logFolder)) ) { File.makeDirectory(logFolder); }
// Specify the log file path to save the log file
timeStamp = getTime() % 10000; //4-digit time stamp
outputFile = logFolder + "estimateDotRadius-log" + timeStamp + ".txt";

// Specifiy how many dots you want to measure
N = 5;
Dialog.create("More dots, more time!");
Dialog.addNumber("Number of dots to measure: ", N);
Dialog.show();
N = Dialog.getNumber();

// Open the image and zoom in to help visualization of dots
open(file);
imgID = getImageID();
run("In [+]"); run("In [+]"); run("In [+]");
// w, h, c, s, f => width, height, channels, slices, frames
getDimensions(w, h, c, s, f);
print("Image width, height, channel#, slice#, frame#: ", w, h, c, s, f);
// vw, vh, vd, unit => literally the voxel size.  Most likely unit is in microns
getVoxelSize(vw, vh, vd, unit);
print("Voxel width, height, depth, unit: ", vw, vh, vd, unit);

// Specify the saturation level to display the image
satuLevel = 0.3;
if (s > 1) {
	midS = floor(s/2) + 1;
	Stack.setSlice(midS);
	if (c > 1) {
		for (i=1; i<c+1; i++) {
			Stack.setChannel(i);
			run("Enhance Contrast", "saturated=" + satuLevel);
		}
	}
}

if (c > 1) {
	for (i=1; i<c+1; i++) {
		Stack.setChannel(i);
		run("Enhance Contrast", "saturated=" + satuLevel);
	}
}



if (s==1) {
	dotDxy = getDotDxy(imgID, N);
	rXYpix = floor( (dotDxy/vw + 1) /2 );
	msg = "The average dot radius in XY is: " + rXYpix + " pixels.";
	print("\n" + msg);
	showMessage(msg + "\n" +
				"Also recorded in the Log window.");
	selectWindow("Log");
	saveAs("txt", outputFile);
	// Clear up workspace, leave only Log window open
	selectWindow("Results"); run("Close");
	run("Close All");
	setTool("rectangle");
}
else {
	dotDxyz = getDotDxyz(imgID, N, s);
	rXYpix = floor( (dotDxyz[0]/vw + 1) /2 );
	rZpix = floor( (dotDxyz[1]/vd + 1) /2 );
	msgXY = "The average dot radius in XY is: " + rXYpix + " pixels.";
	msgZ = "The average dot radius in Z is: " + rZpix + " voxels.";
	msg = msgXY + "\n" + msgZ;
	print("\n" + msg);
	showMessage(msg + "\n" +
				"Also recorded in the Log window.");
	selectWindow("Log");
	saveAs("txt", outputFile);
	// Clear up workspace, leave only Log window open
	selectWindow("Results"); run("Close");
	run("Close All");
	setTool("rectangle");
}

function getDotDxyz(id, N, s) {
	// Create 2 empty arrays to hold the dot diameter data
	midS = floor(s/2) + 1;
	dotDxy = newArray(N);
	dotDz = newArray(N);
	run("Clear Results");
	setTool("line");
	// Print a header to record the dot diameter measurements
	print("\nDot#\tDiameter_in_XY\tDiameter_in_Z ("+unit+")");
	for (i=1; i<N+1; i++) {
		selectImage(id);
		Stack.setSlice(midS);
		run("Select None");
		
		waitForUser("This is step 1 of dot #" + i + ".\n"+
					"1. Go to the smFISH channel.\n"+
					"2. Draw a line across a dot (extend beyond).\n"+
					"3. Click OK to continue.");
		run("Reslice [/]...", "output="+vd+" slice_count=1 avoid");
		reslicedID = getImageID();
		run("In [+]");
		run("In [+]");
		run("In [+]");
		run("In [+]");
		run("In [+]");
		run("In [+]");
		
		waitForUser("This is step 2 of dot #" + i + " to get diameter in xy.\n"+
					"1. Go to the resliced image.\n"+
					"2. Hold \"Shift\" to draw a horizontal line across the dot diameter.\n"+
					"3. Click OK to continue.");
		run("Clear Results");
		selectImage(reslicedID);
		run("Measure");
		dotDxy[i-1] = getResult("Length", 0);
		run("Select None");
		
		waitForUser("This is step 3 of dot #" + i + " to get diameter in xy.\n"+
					"1. Go to the resliced image.\n"+
					"2. Hold \"Shift\" to draw a vertical line across the dot diameter.\n"+
					"3. Click OK to continue.");
		
		run("Clear Results");
		selectImage(reslicedID);
		run("Measure");
		dotDz[i-1] = getResult("Length", 0);
		run("Select None");

		// close the resliced image
		selectImage(reslicedID);
		run("Close");
		print(i + "\t" + dotDxy[i-1] + "\t" + dotDz[i-1]);
		
		selectImage(id);
		Stack.getPosition(c, currentSlice, f);
		if ( midS!= currentSlice ) {midS = currentSlice;}
	}
	Array.getStatistics(dotDxy, dotDxyMin, dotDxyMax, dotDxyMean);
	Array.getStatistics(dotDz, dotDzMin, dotDzMax, dotDzMean);
	dotDxyz = newArray(dotDxyMean, dotDzMean);
	return dotDxyz;
}

function getDotDxy(id, N) {
	// Create an empty array to hold the dot diameter data
	dotDxy = newArray(N);
	run("Clear Results");
	setTool("line");
	// Print a header to record the dot diameter measurements
	print("\nDot#\tDiameter_in_XY ("+unit+")");
	for (i=1; i<N+1; i++) {
		selectImage(id);
		waitForUser("Go to the smFISH channel.\n"+
					"Draw a line across a dot.\n"+
					"   This is dot #" + i + ".\n"+
					" Click OK to continue.");
		run("Clear Results");
		run("Measure");
		dotDxy[i-1] = getResult("Length", 0);
		run("Select None");
		print(i + "\t" + dotDxy[i-1]);
	}
	Array.getStatistics(dotDxy, dotDxyMin, dotDxyMax, dotDxyMean);
	return dotDxyMean;
}

function getPathFilenamePrefix(pathFileOrFolder) {
	// this one takes full path of the file (can be a folder)
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