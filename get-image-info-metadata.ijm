inputFolder = getDirectory("Choose the folder containing images to process:");
//inputFolder = '/Volumes/ShaoheGtech/2018-3-Shaohe/181017-18-pW131-pW133-SIMS-Fn1-smFISH/';
// Create an output folder based on the inputFolder
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-output" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

run("Close All");
setBatchMode(true);

processFolder(inputFolder, outputFolder);

function processFolder(inputFolder, outputFolder) {
	
	flist = getFileList(inputFolder);
	//for (i=0; i<1; i++) {//for testing
	for (i=0; i<flist.length; i++) {
		filename = inputFolder + flist[i];
		outputPrefix = getFilenamePrefix(flist[i]);
		
		if ( endsWith(flist[i], ".nd2") || endsWith(flist[i], ".czi") || endsWith(flist[i], ".tif") ) {
			open(filename);
			run("Show Info...");
			saveAs("Text", outputFolder + outputPrefix + "-info.txt");
			run("Close All");
			selectWindow("Info for " + flist[i]);
			run("Close");
		}
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