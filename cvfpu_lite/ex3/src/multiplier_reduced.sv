/* This SystemVerilog file defines the following hierarchical modules, hereby listed from lower to top module:

	half_adder
	full_adder
	RCA
	booth_recoder
	pp_generator
	pp_matrix_generator
	wallace_tree
*/

//import constants::*;
//`define NBITS 9
//localparam int NBITS = 9;

package my_pkg;
	localparam int NBITS = 9;
endpackage

import my_pkg::*;

module half_adder (input a, b, output s, cout);
	assign s = a ^ b;	// sum bit: a XOR b
	assign cout = a & b;	// carry bit: a AND b
endmodule

module full_adder (input a, b, cin, output s, cout);
	assign s = a ^ b ^ cin;			// sum bit: a XOR b XOR cin
	assign cout = (a & b) | (a & cin) | (b & cin);	// carry bit: (a AND b) or (a AND cin) or (b AND cin)
endmodule

module RCA #(parameter N = NBITS+4) (		// in the RCA there are NBIT + 4 adders
	input logic 	[N-1:0] addend1,
	input logic 	[N-1:0] addend2,
	output logic 	[N-1:0] SUM,
	output logic	COUT
);

	logic [N:0] c;		// carry chain
	assign c[0] = 1'b0;	// no carry-in into the RCA

	genvar i;
	generate
		for (i = 0; i < N; i++) begin : ADD
			full_adder fa (
				.a	(addend1[i]),
				.b	(addend2[i]),
				.cin	(c[i]),
				.s	(SUM[i]),
				.cout	(c[i+1])
			);
		end
	endgenerate

	assign COUT = c[N];

	always @(*) begin
		//$display("RCA: add1=%b add2=%b sum=%b cout=%b", addend1, addend2, SUM, COUT);
	end
endmodule
				
/* ====	MODULE	: Radix-4 Booth Recoder									====
   ====	INPUTS	: b_hi, b_lo, b_prev are 3 adjacent bits from the multiplier				====
   ====	OUTPUTS	: neg is a control signal that is asserted if multiplier B is a negative number		====
   ==== 	: use2 is a control signal that is asserted if multiplicand A must be multiplier by 2	====
   ====		: use1 is a control signal that is asserted if A is multiplied by 1 			==== */
module booth_recoder (input logic b_hi, b_lo, b_prev, output logic neg, use2, use1);
	
	// pack 3 input bits in a single vector
	logic [2:0] x;
	assign x = {b_hi, b_lo, b_prev};

	always_comb begin
    		//$display("Recoder Inputs[]: b_prev=%b b_lo=%b b_hi=%b", b_prev, b_lo, b_hi);
	end

	// combinational logic for control signal assignment
	always_comb begin
		// initialize to default values
		neg 	= 1'b0;
		use2 	= 1'b0;
		use1 	= 1'b0;
		// assign values based on radix-4 Booth table
		case (x)
			3'b000 : begin neg = 0; use1 = 0; use2 = 0; end 	// 000 ->  0A
			3'b001 : begin neg = 0; use1 = 1; use2 = 0; end 	// 001 -> +1A
			3'b010 : begin neg = 0; use1 = 1; use2 = 0; end		// 010 -> +1A
			3'b011 : begin neg = 0; use1 = 0; use2 = 1; end		// 011 -> +2A
			3'b100 : begin neg = 1; use1 = 0; use2 = 1; end		// 100 -> -2A
			3'b101 : begin neg = 1; use1 = 1; use2 = 0; end		// 101 -> -1A
			3'b110 : begin neg = 1; use1 = 1; use2 = 0; end		// 110 -> -1A
			3'b111 : begin neg = 0; use1 = 0; use2 = 0; end		// 111 ->  0A									// MODIFIED
		endcase
		//$display("Booth Recoder: b_hi=%b b_lo=%b b_prev=%b | neg=%b use1=%b use2=%b", b_hi, b_lo, b_prev, neg, use1, use2);
	end
endmodule

/* ====	MODULE	: Radix-4 Partial Product VECTOR Generator					====
   ====	INPUTS	: A is the multiplicand on AW-1 bits						====
   ====		: neg, use2, use1 are the outputs of the boot_recoder module			====
   ====	OUTPUTS	: PP is the partial product, 2 extra bits for 2A output and sign extension bit	==== */
module pp_generator #(

	parameter int AW = NBITS
) (
	input logic unsigned 	[AW-1:0] A,
	input logic 		neg, use2, use1,
	output logic signed 	[AW+1:0] PP
);
	// vectors for intermediate results
	logic signed [AW+1:0] A_ext;
	logic signed [AW+1:0] twoA;
	
	always_comb begin
		// sign extension: repeat sign bit A[AW-1] of A twice and concatenate with A
		A_ext = { 1'b0, A };	
		//A_ext = {2'b00, A};
		// compute 2A: arithmetic left shift of A (sign-extended)
		twoA = A_ext <<< 1;
		// compute partial product as 2A, A or 0
		if (use2) 	PP = twoA;
		else if (use1) 	PP = A_ext;
		else 		PP = '0;
		// check if partial product is negative
		if (neg) 	PP = -PP;
	end
endmodule

/* ====	MODULE	: Radix-4 Partial Product MATRIX Generator							====
   ====	INPUTS	: A is the multiplicand and AW is its width							====
   ====		: B is the multiplier and BW is its width							====
   ====	OUTPUTS	: pp_matrix is the matrix holding all partial products generated via MBE, it has as many rows   
		  as the multiplier slices (G) and as many columns as the width of the product (PW)		==== */
module pp_matrix_generator #(

	parameter int AW = NBITS,	// width of multiplicand A (after adding '0' sign bit and '1' denormalization bit)
	parameter int BW = NBITS,	// width of multiplier B (after adding '0' sign bit and '1' denormalization bit)

	// number of multiplier slices (radix-4) - for a 7 bit multiplier, 4 slices will be present
	localparam int G = (BW + 1) / 2,		

	// partial product width (multiplicand width + multiplier width = 9 + 9 = 18)
	localparam int PW = AW + BW
)  (
	input logic unsigned 	[AW-1:0] A,
	input logic unsigned 	[BW-1:0] B,
	output logic signed 	[PW+1:0] pp_matrix [G-1:0]													// EXTENDED
);

	genvar i;
	generate
		for (i = 0; i < G; i = i + 1) begin : gen_pp
			
			// indices for the 3 multiplier bits in the i-th slice
			localparam int IDX_PREV = 2 * i - 1;
			localparam int IDX_LO	= 2 * i;
			localparam int IDX_HI 	= 2 * i + 1;

			// assign the 3 bits of the multiplier slice for MBE
			logic b_prev, b_lo, b_hi;

			// b_prev
			if (IDX_PREV < 0) begin		// b_prev is 0 when considering the first slice (multiplier[-1] == 0)
				assign b_prev = 1'b0;
			end else begin
				assign b_prev = B[IDX_PREV];
			end	 
			
			// b_lo
			if (IDX_LO < BW) begin
				assign b_lo = B[IDX_LO];
			end else begin
				assign b_lo = B[BW-1];	// sign extension if the last msb slice overflows the size of the multiplier
			end
		
			// b_hi
			if (IDX_HI < BW) begin
				assign b_hi = B[IDX_HI];
			end else begin
				assign b_hi = B[BW-1];	// sign extension if the last msb slice overflows the size of the multiplier 
			end

			// recoder outputs
			logic neg_i, use1_i, use2_i;

			// instantiate MBE recoder
			booth_recoder br (
				.b_hi 		(b_hi),
				.b_lo		(b_lo),
				.b_prev		(b_prev),
				.neg		(neg_i),
				.use1		(use1_i),
				.use2		(use2_i)
			);

			always_comb begin
    				//$display("Slice[%0d]: %0d %0d %0d | B=%b", i, IDX_PREV, IDX_LO, IDX_HI, B);
			end

			// partial product vector to be filled by the generator
			logic unsigned [AW+1:0] pp_generated;													// MODIFIED
			logic unsigned [AW+4:0] pp_unshifted;

			// instantiate partial product generator			
			pp_generator ppgen (
				.A	(A),
				.neg	(neg_i),
				.use1	(use1_i),
				.use2	(use2_i),
				.PP	(pp_generated)
			);

			always_comb begin
				if (neg_i) begin
					if (i == 0) begin
						pp_unshifted = {3'b011, pp_generated};
					end else if (i == G-1) begin
						pp_unshifted = pp_generated;
					end else begin
						pp_unshifted = {2'b10, pp_generated};
					end
				end else begin
					if (i == 0) begin
						pp_unshifted = {3'b100, pp_generated};
					end else if (i == G-1) begin
						pp_unshifted = pp_generated;
					end else begin
						pp_unshifted = {2'b11, pp_generated};
					end
				end
			end

			/* shift left the partial product by 2 * i positions in the partial product matrix (this is were sign extension to 18 bits automatically takes place because pp_matrix[i] was declared as a signed vector) */
			always_comb begin
				pp_matrix[i] = pp_unshifted << (2*i);
				if (i == 0)
					$display("SHIFTED tmp = %020b (%0d)", pp_unshifted, pp_unshifted);
			end

			always_comb begin
			    if (i == 0) begin
				$display("Slice0: neg=%b use1=%b use2=%b", neg_i, use1_i, use2_i);
				//$display("A_ext=%b twoA=%b pp_generated=%b", A_ext, twoA, pp_generated);
				$display("pp_unshifted (before shift) = %b (%0d)", pp_unshifted, pp_unshifted);
				$display("pp_matrix[0] (after shift)  = %b (%0d)", pp_unshifted << (2*i), pp_unshifted << (2*i));
			    end
			end
		end

	endgenerate
endmodule

module wallace_tree #(
	
	// input widths
	parameter int AW = NBITS,
	parameter int BW = NBITS,

	localparam int G = (BW + 1) / 2,		// number of multiplier bit slices
	localparam int PW = AW + BW			// partial product width (multiplicand bits + multiplier bits = 9 + 9 = 18)

)  (
	input 	logic unsigned 	[AW-2:0] A_fma,			// inputs A and B from the FMA are 8 bits long
	input 	logic unsigned 	[BW-2:0] B_fma,
	output 	logic unsigned	[PW-3:0] product,		// the product should be (AW + BW - 2 = 9 + 9 - 2 = 16) bits long
	output 	logic signed 	[PW+1:0] pp_matrix [G-1:0]	// partial products are 18 bits long								// EXTENDED
);

	logic signed 		[PW+1:0] M [G-1:0];														// EXTENDED

	// the top multiplier module receives 8 bits inputs (1 normalization bits + 7 mantissa bits) from fpnew_fma.sv, but to compute unsigned multiplication it must append a 0 to the inputs so that they won't be interpreted as signed values
	//logic unsigned [AW-1:0] A_ext = {1'b0, A_fma};
	//logic unsigned [BW-1:0] B_ext = {1'b0, B_fma};
	logic unsigned [AW-1:0] A_ext;
	logic unsigned [BW-1:0] B_ext;

	always_comb begin
		A_ext = {1'b0, A_fma};
		B_ext = {1'b0, B_fma};
	end
		
	always_comb begin
	    //$display("Wallace Tree | A_fma=%b B_fma=%b | A_ext=%b B_ext=%b", A_fma, B_fma, A_ext, B_ext);
	end
	// instantiate the partial product matrix generator
	pp_matrix_generator #(
		.AW(AW),
		.BW(BW)
	) matrix (
		.A		(A_ext),
		.B		(B_ext),
		.pp_matrix	(M)	// connect the pp_matrix output port of the matrix generator to the local wallace_tree matrix
	);

	// generate the partial product matrix and the final product
	assign pp_matrix = M;

	logic [PW-1:0] P;		// temporary vector to hold the bits that are dropped from previous Wallace stages directly into the result
	logic [40:0] c;			// vector for carry bits
	logic [40:0] s;			// vector for sum bits
	logic [NBITS+4-1:0] rca_sum;	// vector to hold the sum output of the final RCA
	logic rca_cout;

	genvar g;

	// 1st row of Wallace tree adders (1HA + 9FA + 2HA)
	assign P[0] = M[0][0];
	assign P[1] = M[0][1];
	half_adder h0(M[0][2], M[1][2], s[0], c[0]);
	half_adder h1(M[0][3], M[1][3], s[1], c[1]);
	generate 
		for (g = 0; g < 10; g++) full_adder fg0(M[0][g+4], M[1][g+4], M[2][g+4], s[g+2], c[g+2]);
	endgenerate
	half_adder h2(M[1][14], M[2][14], s[12], c[12]);

	// 2nd row of Wallace tree adders (9FA + 3HA)
	assign P[2] = s[0];
	half_adder h3(s[1], c[0], s[13], c[13]);
	half_adder h4(s[2], c[1], s[14], c[14]);
	half_adder h5(s[3], c[2], s[15], c[15]);
	generate
		for (g = 0; g < 9; g++) full_adder fg1(s[g+4], c[g+3], M[3][g+6], s[g+16], c[g+16]);
	endgenerate
	full_adder f19(M[2][15], c[12], M[3][15], s[25], c[25]);
	half_adder h6 (M[2][16], M[3][16], s[26], c[26]);

	// 3rd row of Wallace tree adders (4 HA + 10 FA)
	assign P[3] = s[13];
	half_adder h7(s[14], c[13], s[27], c[27]);
	half_adder h8(s[15], c[14], s[28], c[28]);
	half_adder h9(s[16], c[15], s[29], c[29]);
	half_adder h10(s[17], c[16], s[30], c[30]);
	generate
		for (g = 0; g < 9; g++) full_adder fg2(s[g+18], c[g+17], M[4][g+8], s[g+31], c[g+31]);
	endgenerate
	full_adder f29(M[3][17], c[26], M[4][17], s[40], c[40]);

/*
	// 1st row of Wallace tree adders (2 HA + 14 FA)
	assign P[0] = M[0][0];
	assign P[1] = M[0][1];
	half_adder h0(M[0][2], M[1][2], s[0], c[0]);
	half_adder h1(M[0][3], M[1][3], s[1], c[1]);
	generate 
		for (g = 0; g < 14; g++) full_adder fg0(M[0][g+4], M[1][g+4], M[2][g+4], s[g+2], c[g+2]);
	endgenerate

	// 2nd row of Wallace tree adders (4 HA + 12 FA)
	assign P[2] = s[0];
	half_adder h16(s[1], c[0], s[16], c[16]);
	half_adder h17(s[2], c[1], s[17], c[17]);
	half_adder h18(s[3], c[2], s[18], c[18]);
	generate
		for (g = 0; g < 12; g++) full_adder fg1(s[g+4], c[g+3], M[3][g+6], s[g+19], c[g+19]);
	endgenerate

	// 3rd row of Wallace tree adders (4 HA + 10 FA)
	assign P[3] = s[16];
	half_adder h31(s[17], c[16], s[31], c[31]);
	half_adder h32(s[18], c[17], s[32], c[32]);
	half_adder h33(s[19], c[18], s[33], c[33]);
	half_adder h34(s[20], c[19], s[34], c[34]);
	generate
		for (g = 0; g < 10; g++) full_adder fg2(s[g+21], c[g+20], M[4][g+8], s[g+35], c[g+35]);
	endgenerate
*/
	// final ripple carry adder
	assign P[4] = s[27];
	RCA #(
		.N(13)
	) final_adder (
		.addend1	(s[40:28]),
		.addend2	(c[39:27]),
		.SUM 		(rca_sum),
		.COUT		(rca_cout)
	);
	
	//assign product = {rca_sum[$bits(rca_sum)-2:0], P[3:0]};	// skip the 15th bit of the RCA result and concatenate with the bits that were dropped from earlier steps
	assign product = {rca_sum[10:0], P[4:0]};
endmodule




















