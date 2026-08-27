# This script must be run to complete the synthesis

# Delete the work directory and recreate it from scratch
rm -rf work
mkdir work

# Source the design vision initialization file
source /eda/scripts/init_design_vision

# Run the synthesis script "synthesis.scr", display its output on the terminal and save it in file "mylogfile.log"
#dc_shell-xg-t -f synthesis.scr > mylogfile.log
stdbuf -oL -eL dc_shell-xg-t -f synthesis.scr 2>&1 | tee mylogfile.log
#dc_shell-xg-t -f synthesis.scr
