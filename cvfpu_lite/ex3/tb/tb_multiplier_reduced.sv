`timescale 1ns/1ps

module tb_wallace_tree;

	import constants::*;

	localparam int AW = NBITS;
	localparam int BW = NBITS;
	localparam int G  = (BW + 1) / 2;
	//localparam int PPW = AW + BW + 1;
	localparam int PW = AW + BW;

	logic unsigned [AW-2:0] A;
	logic unsigned [BW-2:0] B;
	logic unsigned [PW-3:0] product;
	logic signed   [PW+1:0] pp_matrix [G-1:0];														// EXTENDED
	logic unsigned [15:0] in1, in2, out;

	wallace_tree #(
		.AW(AW),
		.BW(BW)
	) dut (
		.A_fma		(A),		// .port_name	(signal_name)
		.B_fma		(B),
		.product	(product),
		.pp_matrix	(pp_matrix)
	);

	task print_pp;
		int i;
		begin 
			$display("------------------------------------------");
			$display(" Input = (%h) | Mantissa (A) = %0d (%b)", in1, $unsigned(A), A);	// mantissa input A is unsigned (it's a decimal part)
			$display(" Input = (%h) | Mantissa (B) = %0d (%b)", in2, $unsigned(B), B);	// mantissa input B is unsigned (it's a decimal part)
			$display(" Partial Products:");
			for (i = 0; i < G; i++) begin
				$display(" PP[%0d] = %0d (%b)", i, pp_matrix[i], pp_matrix[i]); // partial products are signed due to MBE behavior
			end
			$display(" Mantissa Product: %0d (%b)", product, product); // the product is unsigned (it's the product of two unsigned values)
			$display("------------------------------------------");
		end
	endtask

	initial begin
	
		A = 8'b11100000;
		B = 8'b11001000;
		#1; print_pp();

		in1 = 16'h40E0; 
		in2 = 16'h41C8;
		A = {1'b1, in1[6:0]}; 					// 16'h40E0, 16'h41C8 7.0    25.0
		B = {1'b1, in2[6:0]};
		#1; print_pp(); 

		in1 = 16'h3F00; 
		in2 = 16'h3F00;
		A = {1'b1, in1[6:0]}; 					// 16'h40E0, 16'h41C8 7.0    25.0
		B = {1'b1, in2[6:0]};
		#1; print_pp(); 

		in1 = 16'h41A0; 
		in2 = 16'h4248;
		A = {1'b1, in1[6:0]}; 					// 16'h40E0, 16'h41C8 7.0    25.0
		B = {1'b1, in2[6:0]};
		#1; print_pp(); 

		in1 = 16'h4180; 
		in2 = 16'h3E80;
		A = {1'b1, in1[6:0]}; 					// 16'h40E0, 16'h41C8 7.0    25.0
		B = {1'b1, in2[6:0]};
		#1; print_pp(); 

		in1 = 16'h4158; 
		in2 = 16'h4040;
		A = {1'b1, in1[6:0]}; 					// 16'h4158, 16'h4040 
		B = {1'b1, in2[6:0]};
		#1; print_pp(); 

		in1 = 16'h4000; 
		in2 = 16'h42A6;
		A = {1'b1, in1[6:0]}; 					
		B = {1'b1, in2[6:0]};
		#1; print_pp(); 

		in1 = 16'h4100; 
		in2 = 16'h40E0;
		A = {1'b1, in1[6:0]}; 					
		B = {1'b1, in2[6:0]};
		#1; print_pp(); 

		in1 = 16'h40E0; 
		in2 = 16'h40C0;
		A = {1'b1, in1[6:0]}; 					
		B = {1'b1, in2[6:0]};
		#1; print_pp(); 

		in1 = 16'h4110; 
		in2 = 16'h4100;
		A = {1'b1, in1[6:0]}; 					
		B = {1'b1, in2[6:0]};
		#1; print_pp(); 

		in1 = 16'h4130; 
		in2 = 16'h4130;
		A = {1'b1, in1[6:0]}; 					
		B = {1'b1, in2[6:0]};
		#1; print_pp(); 

		in1 = 16'hC130;		// -11.0
		in2 = 16'h4130;		// +11.0
		A = {1'b1, in1[6:0]};
		B = {1'b1, in2[6:0]};
		#1; print_pp();

		$stop();
	end
endmodule
