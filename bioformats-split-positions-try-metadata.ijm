inputFolder = getDirectory("Choose the folder containing images to process:");
// Create an output folder based on the inputFolder
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-splitPositions" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

run("Close All");
setBatchMode(true);

flist = getFileList(inputFolder);

for (i=0; i<flist.length; i++) {
	filename = inputFolder + flist[i];
	filenamePrefix = getFilenamePrefix(flist[i]);

	if ( endsWith(filename, ".nd") || endsWith(filename, ".nd2") || endsWith(filename, ".czi") ) {
		run("Bio-Formats Macro Extensions");
		Ext.setId(filename); Ext.getSeriesCount(seriesCount);
		print(seriesCount);
	
		for(seriesNum = 0; seriesNum < seriesCount; seriesNum++) {
			Ext.setSeries(seriesNum);
			Ext.openImagePlus(filename);
			Ext.getMetadataValue("dXPos", value);
			print("metadata value: " + value);
		}
		
		run("Close All");
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

function zeroPadding(N, N_max) {
	if ( N_max < 10 ) {
		temp = toString(N); return temp;
	}
	if ( N_max < 100 ) {
		temp = zeroPadding2(N); return temp;
	}
	if ( N_max < 1000 ) {
		temp = zeroPadding3(N); return temp;
	}
	if ( N_max < 10000 ) {
		temp = zeroPadding4(N); return temp;
	}
	else {
		print( "Warning! Maximum >= 10000! Change zeroPadding to account for that.");
		temp = toString(N);
		return temp;
	}
}

function zeroPadding4(t) {
	// pad t to 4 digits when t <1000
	if ( t < 10 ) {
		tPadded = "000" + t; return tPadded;
	}
	if ( t < 100 ) {
		tPadded = "00" + t; return tPadded;
	}
	if ( t < 1000 ) {
		tPadded = "0" + t; return tPadded;
	}
	if ( t < 10000 ) {
		temp = toString(t); return temp;
	}
	else {
		print( "Warning! Maximum >= 10000! Change zeroPadding to account for that.");
		temp = toString(t); return temp;
	}
}

function zeroPadding3(t) {
	// pad t to 4 digits when t <1000
	if ( t < 10 ) {
		tPadded = "00" + t; return tPadded;
	}
	if ( t < 100 ) {
		tPadded = "0" + t; return tPadded;
	}
	if ( t < 1000 ) {
		temp = toString(t); return temp;
	}
	else {
		print( "Warning! Maximum >= 1000! Change zeroPadding to account for that.");
		temp = toString(t); return temp;
	}
}

function zeroPadding2(t) {
	// pad t to 4 digits when t <1000
	if ( t < 10 ) {
		tPadded = "0" + t; return tPadded;
	}
	if ( t < 100 ) {
		temp = toString(t); return temp;
	}
	else {
		print( "Warning! Maximum >= 100! Change zeroPadding to account for that.");
		temp = toString(t); return temp;
	}
}