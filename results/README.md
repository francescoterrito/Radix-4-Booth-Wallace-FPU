# Result evidence

`verified_results.csv` reconciles six saved Design Compiler runs. `clock_constraint_ns` is taken from the capture-clock edge in each timing report; `critical_data_arrival_ns` is the reported path arrival time. `max_clock_mhz` is calculated as `1000 / clock_constraint_ns`.

The baseline run set is stored under `cvfpu_lite/syn/reports/`. The custom multiplier run is stored under `cvfpu_lite/ex3/syn/reports/`.

The simulation files are extracts from the final successful sections of the saved Questa transcripts and are matched with `cvfpu_lite/fp_test/results.txt` and the directed test vectors.
