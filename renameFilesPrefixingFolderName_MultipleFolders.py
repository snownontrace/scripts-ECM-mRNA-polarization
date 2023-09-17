import os, glob
import tkinter as tk
from tkinter.filedialog import askdirectory
# from pathlib import Path
# from datetime import datetime

# This script renames the split files from Nikon by concatenate
# the folder name and file name (usually just numbers)

# filesToRename = "*.nd2"
filesToRename = "*.tif"
# filesToRename = "*.txt"
# filesToRename = "*.png"

initialFolder = '/Volumes/wangs6'
# initialFolder = '/Users/wangs6/Desktop'# Mac style
# initialFolder = 'C:\\Users\\mehlferbermm\\Desktop'# Windows style

#shows the dialog box
root = tk.Tk()
root.withdraw()
inputFolder = askdirectory(parent=root, initialdir=initialFolder, \
						 title='Please select the folder containing the files to rename')

folderList = glob.glob(inputFolder + os.path.sep + "*" + os.path.sep)

for folder in folderList:
	folder = folder[:-1]# remove the trailing separator to properly use os.path.basename
	fList = glob.glob( folder + os.path.sep + filesToRename )
	# print(fList)
	for f in fList:
		# print(f)
		newFilename = os.path.dirname(folder) + os.path.sep + os.path.basename(folder) + "-" + os.path.basename(f)
		# print(newFilename)
		os.rename( f, newFilename )

	os.removedirs(folder)
