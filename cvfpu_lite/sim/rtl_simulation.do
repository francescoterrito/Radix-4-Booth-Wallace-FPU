-- (0) source QuestaSim initialization script via "source /eda/scripts/init_questa_core_prime"
-- (1) in Linux terminal start QuestaSim via "vsim &"
-- (2) in QuestaSim terminal run compilation script via "do rtl_simulation.do"

quit -sim
vdel -all -lib work
vlib work
vmap work work

-- compile source files
vlog -sv -work ./work ../src/cf_math_pkg.sv
vlog -sv -work ./work ../src/lzc.sv
vlog -sv -work ./work ../src/rr_arb_tree.sv
vlog -sv -work ./work ../src/fpnew_pkg.sv
vlog -sv -work ./work ../src/fpnew_classifier.sv
vlog -sv -work ./work ../src/fpnew_rounding.sv
vlog -sv -work ./work ../src/fpnew_fma.sv
vlog -sv -work ./work ../src/fpnew_opgroup_fmt_slice.sv
vlog -sv -work ./work ../src/fpnew_opgroup_block.sv
vlog -sv -work ./work ../src/fpnew_top.sv

-- compile testbench files
vcom -work ./work ../tb/clk_gen.vhd

-- not needed if data is fed manually
-- vcom -work ./work ../tb/data_gen16.vhd

-- compile for presynthesis RTL simulation (modified for manual data input)
vlog -sv -work ./work ../tb/tb_fpnew_top_rtl_modified.sv

-- start the simulation
vsim work.tb_fpnew_top -voptargs=+acc
add wave *
run -all
