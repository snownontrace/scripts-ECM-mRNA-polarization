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

initialFolder = '/Volumes/ShaoheGtech2'
# initialFolder = '/Volumes/ShaoheGtech2/2019-spheroids-fixed'# Mac style
# initialFolder = '/Users/wangs20/Desktop/test1'# Mac style
# initialFolder = 'C:\\Users\\mehlferbermm\\Desktop\\test1'# Windows style

#shows the dialog box
root = tk.Tk()
root.withdraw()
inputFolder = askdirectory(parent=root, initialdir=initialFolder, \
                         title='Please select the folder containing the files to rename')

fList = glob.glob( inputFolder + os.path.sep + filesToRename )
# print(fList)

for f in fList:
	print(f)
	os.rename( f, os.path.dirname(inputFolder) + os.path.sep + \
				os.path.basename(inputFolder) + "-" +\
				os.path.basename(f) )

os.removedirs(inputFolder)
