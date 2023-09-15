run("Image Sequence...", "dir=/Users/wangs20/Desktop/temp/ sort");
n_slices = nSlices / 2
run("Stack to Hyperstack...", "order=xyctz channels=2 slices="+n_slices+" frames=1 display=Color");
Stack.setChannel(1);
run("Green");
Stack.setChannel(2);
run("Red");
