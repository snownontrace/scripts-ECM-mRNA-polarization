inputFolder = getDirectory("Choose the folder containing images to process:");
// Create an output folder based on the inputFolder
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-output" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

run("Close All");
setBatchMode(true);

Dialog.create("Specify parameters:");
Dialog.addString("Channel 1 name", "DAPI");
Dialog.addString("Channel 2 name", "Col4a1-TMR");
Dialog.addString("Channel 3 name", "NA");
Dialog.addString("Channel 4 name", "NA");
//Dialog.addChoice("Process MIP, middle slice or specified slice?", newArray("Max Intensity Projection", "Middle Slice", "Specify Slice Number"));
//Dialog.addChoice("Process MIP, middle slice or specified slice?", newArray("Middle Slice", "Specify Slice Number", "Max Intensity Projection"));
Dialog.addChoice("Process MIP, middle slice or specified slice?", newArray("Specify Slice Number", "Max Intensity Projection", "Middle Slice"));
Dialog.addNumber("Which slice?", 1)
Dialog.addChoice("Keep temp files to accelerate re-processing?", newArray("Yes", "No"));
Dialog.show();
c1name = Dialog.getString();
c2name = Dialog.getString();
c3name = Dialog.getString();
c4name = Dialog.getString();
type = Dialog.getChoice();
specifiedSliceNumber = Dialog.getNumber();
keepTemp = Dialog.getChoice();

processIFfolder(inputFolder, outputFolder);

//MIPoutputFolder = parentFolder + inputFolderPrefix + "-MIP-output" + File.separator;
//if ( !(File.exists(MIPoutputFolder)) ) { File.makeDirectory(MIPoutputFolder); }
//makeMIPfolder(inputFolder, MIPoutputFolder);

function processSingleSlice(id, typePrefix, outputFolder, outputPrefix) {

	idC1 = getChannel(id, 1);
	idC2 = getChannel(id, 2);
//	idC3 = getChannel(id, 3);
//	idC4 = getChannel(id, 4);

	saturation = 1.0; idC1_8bit = to8bitSatu( idC1, typePrefix + "-" + c1name, saturation, outputFolder, outputPrefix );
//	c1min = 50; c1max = 1500; idC1_8bit = to8bitMinMax( idC1, typePrefix + "-" + c1name, c1min, c1max, outputFolder, outputPrefix );
	//saturation = 0.5; idC2_8bit = to8bitSatu( idC2, typePrefix + "-" + c2name, saturation, outputFolder, outputPrefix );
	c2min = 15; c2max = 600; idC2_8bit = to8bitMinMax( idC2, typePrefix + "-" + c2name, c2min, c2max, outputFolder, outputPrefix );
	//saturation = 0.5; idC3_8bit = to8bitSatu( idC3, typePrefix + "-" + c3name, saturation, outputFolder, outputPrefix );
	//c3min = 20; c3max = 1200; idC3_8bit = to8bitMinMax( idC3, typePrefix + "-" + c3name, c3min, c3max, outputFolder, outputPrefix );
	//saturation = 0.3; idC4_8bit = to8bitSatu( idC4, typePrefix + "-" + c4name, saturation, outputFolder, outputPrefix );
	//c4min = 20; c4max = 1200; idC4_8bit = to8bitMinMax( idC4, typePrefix + "-" + c4name, c4min, c4max, outputFolder, outputPrefix );

//	mergeBGMY( idC4_8bit, c4name, idC2_8bit, c2name, idC3_8bit, c3name, idC1_8bit, c1name, outputFolder, outputPrefix );
//	mergeBGMY( idC1_8bit, c1name, idC2_8bit, c2name, idC3_8bit, c3name, idC4_8bit, c4name, outputFolder, outputPrefix );
//	mergeCGMY( idC4_8bit, c4name, idC2_8bit, c2name, idC3_8bit, c3name, idC1_8bit, c1name, outputFolder, outputPrefix );
	
	// merge c1 as blue, c2 as green, c3 as magenta
	//BGM = mergeBGM( idC1_8bit, c1name, idC2_8bit, c2name, idC3_8bit, c3name, outputFolder, outputPrefix + "-" + typePrefix );
	//montage2( BGM, idC2_8bit, outputFolder, outputPrefix + "-" + typePrefix );
	//montage3( BGM, idC2_8bit, idC3_8bit, outputFolder, outputPrefix + "-" + typePrefix );
	
	// merge c1 as blue and c2 as gray
	BGr = mergeBGr( idC1_8bit, c1name, idC2_8bit, c2name, outputFolder, outputPrefix + "-" + typePrefix );
	montage2( BGr, idC2_8bit, outputFolder, outputPrefix + "-" + typePrefix );

	// merge c1 as green and c2 as magenta
	//GM = mergeGM(idC1_8bit, c1name, idC2_8bit, c2name, outputFolder, outputPrefix + "-" + typePrefix);
	//montage2( GM, idC2_8bit, outputFolder, outputPrefix + "-" + typePrefix );
	//montage3( GM, idC1_8bit, idC2_8bit, outputFolder, outputPrefix + "-" + typePrefix );

	// merge c2 as green and c3 or c4 as magenta
	//GM1 = mergeGM(idC2_8bit, c2name, idC3_8bit, c3name, outputFolder, outputPrefix + "-" + typePrefix);
	//GM2 = mergeGM(idC2_8bit, c2name, idC4_8bit, c4name, outputFolder, outputPrefix + "-" + typePrefix);
	//montage3( GM1, GM2, idC2_8bit, outputFolder, outputPrefix + "-" + typePrefix );
	
	return 1;
}

function processIFfolder(inputFolder, outputFolder) {
	
	tempFolder = outputFolder + inputFolderPrefix + "-temp" + File.separator;
	if ( !(File.exists(tempFolder)) ) { File.makeDirectory(tempFolder); }
	
	flist = getFileList(inputFolder);
	//for (i=0; i<1; i++) {//for testing
	for (i=0; i<flist.length; i++) {
		filename = inputFolder + flist[i];
		outputPrefix = getFilenamePrefix(flist[i]);
		
		if ( endsWith(filename, ".nd2") || endsWith(filename, ".czi") || endsWith(filename, ".tif") ) {
			
			if ( type == "Max Intensity Projection" ) {
				tempFile = tempFolder + outputPrefix + "-MIP" + ".tif";
				if ( File.exists(tempFile) ) { open(tempFile); idMIP = getImageID(); }
				else { open(filename); id0 = getImageID(); idMIP = getMIP(id0, tempFile); }
				processSingleSlice(idMIP, "MIP", outputFolder, outputPrefix);
			}
			if ( type == "Middle Slice" ) {
				tempFile = tempFolder + outputPrefix + "-midZ" + ".tif";
				if ( File.exists(tempFile) ) { open(tempFile); idMidZ = getImageID(); }
				else { open(filename); id0 = getImageID(); idMidZ = getMidZ(id0, tempFile); }
				processSingleSlice(idMidZ, "midZ", outputFolder, outputPrefix);
			}
			if ( type == "Specify Slice Number" ) {
				tempFile = tempFolder + outputPrefix + "-z-"+specifiedSliceNumber + ".tif";
				if ( File.exists(tempFile) ) { open(tempFile); idZ = getImageID(); }
				else { open(filename); id0 = getImageID(); idZ = getZslice(id0, specifiedSliceNumber, tempFile); }
				processSingleSlice(idZ, "z-"+specifiedSliceNumber, outputFolder, outputPrefix);
			}
			run("Close All");
		}
	}
	
	if ( keepTemp == "No" ) deleteFolder(tempFolder);
}

function getChannel(id, c) {
	selectImage(id); run("Duplicate...", "duplicate channels="+c); idC = getImageID(); return idC;
}

function getMidZ(id, tempFile) {
	selectImage(id);
	if ( nSlices > 1 ) { Stack.getDimensions(w, h, c, s, f); } //width, height, channels, slices, frames
	if ( f == 1 ) { idf1 = id; }
	if ( f > 1 && c*s == 1 ) {
		// when only f > 1, in duplicate it has to be called "range"
		selectImage(id); run("Duplicate...", "duplicate range=1-1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( f > 1 && c*s > 1 ) {
		selectImage(id); run("Duplicate...", "duplicate frames=1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( s == 1 ) { selectImage(idf1); save(tempFile); return idf1; }
	if ( s > 1 ) {
		sMid = floor( s/2 );
		// when only f > 1, in duplicate it has to be called "range"
		if ( c == 1 ) { selectImage(idf1); run("Duplicate...", "duplicate range="+sMid+"-"+sMid); idMidZ = getImageID(); }
		if ( c > 1 ) { selectImage(idf1); run("Duplicate...", "duplicate slices="+sMid); idMidZ = getImageID(); }
		selectImage(idMidZ); save(tempFile); return idMidZ;
	}
}

function getZslice(id, zN, tempFile) {
	selectImage(id);
	if ( nSlices > 1 ) { Stack.getDimensions(w, h, c, s, f); } //width, height, channels, slices, frames
	if ( f == 1 ) { idf1 = id; }
	if ( f > 1 && c*s == 1 ) {
		// when only f > 1, in duplicate it has to be called "range"
		selectImage(id); run("Duplicate...", "duplicate range=1-1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( f > 1 && c*s > 1 ) {
		selectImage(id); run("Duplicate...", "duplicate frames=1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( s == 1 ) { selectImage(idf1); save(tempFile); return idf1; }
	if ( s > 1 ) {
		// when only f > 1, in duplicate it has to be called "range"
		if ( c == 1 ) { selectImage(idf1); run("Duplicate...", "duplicate range="+zN+"-"+zN); idzN = getImageID(); }
		if ( c > 1 ) { selectImage(idf1); run("Duplicate...", "duplicate slices="+zN); idzN = getImageID(); }
		selectImage(idzN); save(tempFile); return idzN;
	}
}

function getMIP(id, tempFile) {
	selectImage(id);
	//if ( nSlices > 1 ) { Stack.getDimensions(w, h, c, s, f); } //width, height, channels, slices, frames
	Stack.getDimensions(w, h, c, s, f); //width, height, channels, slices, frames
	if ( f == 1 ) { idf1 = id; }
	if ( f > 1 && c*s == 1 ) {
		// when only f > 1, in duplicate it has to be called "range"
		selectImage(id); run("Duplicate...", "duplicate range=1-1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( f > 1 && c*s > 1 ) {
		selectImage(id); run("Duplicate...", "duplicate frames=1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( s == 1 ) { selectImage(idf1); save(tempFile); return idf1; }
	if ( s > 1 ) { selectImage(idf1); run("Z Project...", "projection=[Max Intensity]"); idMIP = getImageID(); save(tempFile); return idMIP;}
}

function makeMIPfolder(inputFolder, outputFolder) {
	flist = getFileList(inputFolder);
	for (i=0; i<flist.length; i++) {
		filename = inputFolder + flist[i];
		outputPrefix = getFilenamePrefix(flist[i]);
		if ( endsWith(filename, ".nd2") || endsWith(filename, ".czi") || endsWith(filename, ".tif") ) {
			open(filename); id0 = getImageID();
			idMIP = getMIP(id0);
			save(outputFolder + outputPrefix + "-MIP.tif");
			run("Close All");
		}
}

// scale the image using saturation, change to 8-bit and save it
function to8bitSatu( id, cName, satu, outputFolder, outputPrefix ){
	selectImage(id); run("Grays"); run("Enhance Contrast", "saturated="+satu); run("8-bit");
	outputFilename = outputPrefix + "-" + cName + "-8bit.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
	//id8bit = getImageID(); return id8bit;
}

// scale the image using specified min and max, change to 8-bit and save it
function to8bitMinMax( id, cName, imgMin, imgMax, outputFolder, outputPrefix ){
	selectImage(id); run("Grays"); setMinAndMax(imgMin, imgMax); run("8-bit");
	outputFilename = outputPrefix + "-" + cName + "-8bit.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
	//id8bit = getImageID(); return id8bit;
}

// open 2 images, make a 2 x 1 montage from them
function montage2( f1, f2, outputFolder, outputPrefix ){
	open(outputFolder + f1); rename("montage-1");
	open(outputFolder + f2); rename("montage-2");
	run("Images to Stack", "name=Stack title=[montage] use");
	run("Make Montage...", "columns=2 rows=1 scale=0.50");
	outputFilename = outputPrefix + "-2Montage.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

// open 3 images, make a 3 x 1 montage from them
function montage3( f1, f2, f3, outputFolder, outputPrefix ){
	open(outputFolder + f1); rename("montage-1");
	open(outputFolder + f2); rename("montage-2");
	open(outputFolder + f3); rename("montage-3");
	run("Images to Stack", "name=Stack title=[montage] use");
	run("Make Montage...", "columns=3 rows=1 scale=0.50");
	outputFilename = outputPrefix + "-3Montage.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

function montage4( f1, f2, f3, f4, outputFolder, outputPrefix ){
	// open 4 images, make a 4 x 1 montage from them
	open(outputFolder + f1); rename("montage-1");
	open(outputFolder + f2); rename("montage-2");
	open(outputFolder + f3); rename("montage-3");
	open(outputFolder + f4); rename("montage-4");
	run("Images to Stack", "name=Stack title=[montage] use");
	run("Make Montage...", "columns=4 rows=1 scale=0.50");
	outputFilename = outputPrefix + "-4Montage.tif";
	saveAs("Tiff", outputFolder +  outputFilename);
	return outputFilename;
}

function mergeGM( cGreen, greenName, cMagenta, magentaname, outputFolder, outputPrefix ){
	// merge channels in order in green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c2=["+cGreen+"] c6=["+cMagenta+"] keep");
	outputFilename = outputPrefix + "-" + greenName + "_inGreen-" + magentaname + "_inMagenta.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

function mergeBGr( cBlue, blueName, cGray, grayName, outputFolder, outputPrefix ){
	// merge channels in order in blue and gray colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c3=["+cBlue+"] c4=["+cGray+"] keep");
	outputFilename = outputPrefix + "-" + blueName + "_inBlue-" + grayName + "_inGray.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

function mergeBGM( cBlue, blueName, cGreen, greenName, cMagenta, magentaName, outputFolder, outputPrefix ){
	// merge channels in order in blue, green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c2=["+cGreen+"] c3=["+cBlue+"] c6=["+cMagenta+"] keep");
	outputFilename = outputPrefix + "-" + blueName + "_inBlue-" + greenName + "_inGreen-" + magentaName + "_inMagenta.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

function mergeGMY( cGreen, greenName, cMagenta, magentaName, cYellow, yellowName, outputFolder, outputPrefix ){
	// merge channels in order in blue, green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c2=["+cGreen+"] c6=["+cMagenta+"] c7=["+cYellow+"] keep");
	outputFilename = outputPrefix + "-" + greenName + "_inGreen-" + magentaName + "_inMagenta-" + yellowName + "_inYellow" + ".tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

function mergeBGMY( cBlue, blueName, cGreen, greenName, cMagenta, magentaName, cYellow, yellowName, outputFolder, outputPrefix ){
	// merge channels in order in blue, green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c2=["+cGreen+"] c3=["+cBlue+"] c6=["+cMagenta+"] c7=["+cYellow+"] keep");
	outputFilename = outputPrefix + "-" + blueName + "_inBlue-" + greenName + "_inGreen-" + magentaName + "_inMagenta-" + yellowName + "_inYellow.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

function mergeCGMY( cCyan, cyanName, cGreen, greenName, cMagenta, magentaName, cYellow, yellowName, outputFolder, outputPrefix ){
	// merge channels in order in blue, green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c2=["+cGreen+"] c5=["+cCyan+"] c6=["+cMagenta+"] c7=["+cYellow+"] keep");
	outputFilename = outputPrefix + "-" + cyanName + "_inCyan-" + greenName + "_inGreen-" + magentaName + "_inMagenta-" + yellowName + "_inYellow.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
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