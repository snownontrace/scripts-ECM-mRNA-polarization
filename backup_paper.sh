#!/bin/sh
# rsync.sh

# - It can be executed by user (no need for sudo/root access)
#

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "Backing up data for the paper ..."
echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*"

############ backup work in Box to the Gtech drive ############
rsync -vurt --progress /Users/wangs20/Box/Shaohe-Box-Yamada-Lab/_SMG-ECM-mRNA-polarization-secretion-paper/data/ /Volumes/ShaoheGtech2/_Gtech-SMG-ECM-mRNA-polarization-secretion-paper/data/
rsync -vurt --progress /Users/wangs20/Box/Shaohe-Box-Yamada-Lab/_SMG-ECM-mRNA-polarization-secretion-paper/docs/ /Volumes/ShaoheGtech2/_Gtech-SMG-ECM-mRNA-polarization-secretion-paper/docs/
rsync -vurt --progress /Users/wangs20/Box/Shaohe-Box-Yamada-Lab/_SMG-ECM-mRNA-polarization-secretion-paper/figures/ /Volumes/ShaoheGtech2/_Gtech-SMG-ECM-mRNA-polarization-secretion-paper/figures/
rsync -vurt --progress /Users/wangs20/Box/Shaohe-Box-Yamada-Lab/_SMG-ECM-mRNA-polarization-secretion-paper/videos/ /Volumes/ShaoheGtech2/_Gtech-SMG-ECM-mRNA-polarization-secretion-paper/videos/

############ backup work on the Gtech drive to Box ############
rsync -vurt --progress /Volumes/ShaoheGtech2/_Gtech-SMG-ECM-mRNA-polarization-secretion-paper/data/ /Users/wangs20/Box/Shaohe-Box-Yamada-Lab/_SMG-ECM-mRNA-polarization-secretion-paper/data/
rsync -vurt --progress /Volumes/ShaoheGtech2/_Gtech-SMG-ECM-mRNA-polarization-secretion-paper/docs/ /Users/wangs20/Box/Shaohe-Box-Yamada-Lab/_SMG-ECM-mRNA-polarization-secretion-paper/docs/
rsync -vurt --progress /Volumes/ShaoheGtech2/_Gtech-SMG-ECM-mRNA-polarization-secretion-paper/figures/ /Users/wangs20/Box/Shaohe-Box-Yamada-Lab/_SMG-ECM-mRNA-polarization-secretion-paper/figures/
rsync -vurt --progress /Volumes/ShaoheGtech2/_Gtech-SMG-ECM-mRNA-polarization-secretion-paper/videos/ /Users/wangs20/Box/Shaohe-Box-Yamada-Lab/_SMG-ECM-mRNA-polarization-secretion-paper/videos/

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "All done!"
