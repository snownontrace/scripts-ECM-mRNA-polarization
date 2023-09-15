//inputFolder = getArgument();
inputFolder = getDirectory("Choose the folder containing images to process:");
//inputFolder = '/Volumes/ShaoheGtech2/2019-DLD-1-and-L-engineering-and-characterization/191025-D193-D266-D267-Ecad-b1integrin/191025-D193-NLS-mNG-561-Ecad-647-beta1integrin-slide2-output/';
//inputFolder = '/Volumes/ShaoheGtech2/2019-DLD-1-and-L-engineering-and-characterization/191025-D193-D266-D267-Ecad-b1integrin/191025-D266-D267-488-Ecad-NLS-mSL-647-beta1integrin-slide2-output/';
//inputFolder = '/Volumes/ShaoheGtech2/2019-DLD-1-and-L-engineering-and-characterization/191220-IF-DLD-1-cells-E-cadherin-integrin/D193-D301-D304-b1integrin-Ecad-costaining-output/';

outputFolder = getPath(inputFolder); // get the parental folder path

postfix1 = "-montage-merge";
filenameContains1 = "-sfGFP_inGreen-SSG-TMR_inMagenta.tif";//select files

postfix2 = "-montage-SSG-TMR";
filenameContains2 = "-SSG-TMR-8bit.tif";//select files

// Shared parameters
nCol = 10;
nRow = 10;

scaleFactor = 0.5;
//border_width = 10;
//
element_width = scaleFactor * 210;
figure_width = 100;
border_width = element_width * 2 / figure_width;

// specify the starting image number to skip some
startingImage = 1;
incrementStep = 1;

setBatchMode(true);
processFolder(inputFolder, outputFolder, filenameContains1, postfix1);
processFolder(inputFolder, outputFolder, filenameContains2, postfix2);

// If processing multiple folders in a parental folder:
//processFolders(inputFolder, outputFolder);

//make Montage
function processFolder(folder, outputFolder, filenameContains, postfix) {
//	run("Image Sequence...", "dir=["+folder+"] starting="+startingImage+" increment="+incrementStep+" filter="+filenameContains+" sort");
	run("Image Sequence...", "dir=["+folder+"] starting="+startingImage+" increment="+incrementStep+" type=RGB filter="+filenameContains+" sort");
	setForegroundColor(255, 255, 255);
	run("Make Montage...", "columns="+nCol+" rows="+nRow+" scale="+scaleFactor+" border="+border_width+" use");
//	run("Make Montage...", "columns="+nCol+" rows="+nRow+" scale="+scaleFactor+" use");

	folderParts = split(folder,"/");
	outTifName = folderParts[folderParts.length - 1] + postfix + ".tif";
	outJpegName = folderParts[folderParts.length - 1] + postfix + ".jpeg";
	saveAs("Tiff", outputFolder + outTifName);
	saveAs("Jpeg", outputFolder + outJpegName);
	run("Close All");
}

function processFolders(inputFolder, outputFolder) {
	list = getFileList(inputFolder);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/"))
			processFolder(inputFolder+list[i], outputFolder);
	}
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
