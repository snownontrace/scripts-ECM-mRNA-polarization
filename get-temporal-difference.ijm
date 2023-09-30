id0 = getImageID();

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

// close iamges
//selectImage("1-119"); run("Close");
//selectImage("2-120"); run("Close");
//selectImage("difference"); run("Close");