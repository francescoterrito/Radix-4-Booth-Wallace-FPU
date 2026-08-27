# Source provenance

## Project work

- `cvfpu_lite/ex3/src/multiplier_reduced.sv`: final custom unsigned radix-4 Modified Booth and Wallace-tree significand multiplier.
- `cvfpu_lite/ex3/src/fpnew_fma.sv`: supplied FMA modified to instantiate the custom multiplier.
- Modified directed testbenches under `cvfpu_lite/tb/` and `cvfpu_lite/ex3/tb/`.
- Simulation and synthesis setup, strategy selection, result collection, and technical analysis.

## Supplied course material

- The `cvfpu_lite` FPU subset and its initial testbench/synthesis scaffolding were supplied as the starting design.

## Third-party material

The supplied FPU source is derived from the OpenHW Group CVFPU project. Its file-level copyright, authorship, SPDX, and Solderpad Hardware License 0.51 notices are preserved. The exact upstream revision used to prepare the course subset was not recorded in the supplied package.

The reference outputs were generated with the supplied FlexFloat utility. FlexFloat is an external dependency and its source is not included.

No repository-wide license is added. Existing third-party file-level licensing remains in force for those files.

## Generated evidence

The Design Compiler timing, area, elaboration, and resource reports support the synthesis table. Simulation transcript extracts record the observed bfloat16 products.

Generated netlists, SDF files, Design Compiler databases, analyzed libraries, Questa work libraries, wave databases, executables, and build trees are not included.
