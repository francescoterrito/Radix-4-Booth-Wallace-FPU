-- SIMULATE THE STANDALONE MULTIPLIER
-- Source QuestaSim initialization script via "source /eda/scripts/init_questa_core_prime"
-- (1) in Linux terminal start QuestaSim via "vsim &"
-- (2) in QuestaSim terminal run compilation script via "do compile.do"

-- compile source files
vlog -sv -work ./work ../src/constants.sv
vlog -sv -work ./work ../src/multiplier_reduced.sv

-- compile testbench files
vlog -sv -work ./work ../tb/tb_multiplier_reduced.sv

-- compile for presynthesis RTL simulation (modified for manual data input)
-- vlog -sv -work ./work ../tb/tb_fpnew_top_rtl_modified.sv

-- start the simulation
vsim work.tb_wallace_tree -voptargs=+acc
add wave -r sim:/tb_wallace_tree/A
add wave -r sim:/tb_wallace_tree/B
add wave -r sim:/tb_wallace_tree/product
run -all

