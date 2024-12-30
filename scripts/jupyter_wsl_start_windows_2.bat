@echo off
if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
wsl -e bash -c "cd; source ~/anaconda3/etc/profile.d/conda.sh; conda activate torch; jupyter lab"
