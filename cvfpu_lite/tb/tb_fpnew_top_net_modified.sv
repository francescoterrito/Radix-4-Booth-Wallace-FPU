module tb_fpnew_top ();

//   parameter fpnew_pkg::fpu_features_t       Features       = fpnew_pkg::RV32F;
   parameter fpnew_pkg::fpu_features_t       Features       = fpnew_pkg::RVBF16;   
   parameter fpnew_pkg::fpu_implementation_t Implementation = fpnew_pkg::ISA_PIPE;
   parameter type                            TagType        = logic;
   localparam int unsigned WIDTH        = Features.Width;
   localparam int unsigned NUM_OPERANDS = 3;

   // ====== INPUTS MODIFIED FROM WIRE TO LOGIC ======
   logic clk_i;						
   logic rst_ni;
   logic [NUM_OPERANDS-1:0][WIDTH-1:0] operands_i;
   fpnew_pkg::roundmode_e rnd_mode_i;
   fpnew_pkg::operation_e op_i;
   logic op_mod_i;
   fpnew_pkg::fp_format_e src_fmt_i;
   fpnew_pkg::fp_format_e dst_fmt_i;
   fpnew_pkg::int_format_e int_fmt_i;
   logic vectorial_op_i;
   TagType tag_i;

   // control signals
   logic in_valid_i;
   wire in_ready_o;
   logic flush_i;
   wire [WIDTH-1:0] result_o;
   wire 	    status_o_NV_;
   wire 	    status_o_DZ_;
   wire 	    status_o_OF_;
   wire 	    status_o_UF_;
   wire 	    status_o_NX_;
   TagType tag_o;
   wire out_valid_o;
   logic out_ready_i;
   wire busy_o;
   logic end_sim;	
   // =================================================

   assign rnd_mode_i = fpnew_pkg::RNE;
   assign op_i = fpnew_pkg::MUL;
/* -----\/----- EXCLUDED -----\/-----
   assign src_fmt_i = fpnew_pkg::FP32;
   assign dst_fmt_i = fpnew_pkg::FP32;
   assign int_fmt_i = fpnew_pkg::INT32;
 -----/\----- EXCLUDED -----/\----- */
   assign src_fmt_i = fpnew_pkg::FP16ALT;
   assign dst_fmt_i = fpnew_pkg::FP16ALT;
   assign int_fmt_i = fpnew_pkg::INT32;    // changed from INT16 to INT32
   assign vectorial_op_i 	= 0;
   assign tag_i 		= 0;
   assign flush_i 		= 0;
   assign op_mod_i 		= 0;

/* === REMOVED: same signal cannot be driven both procedurally and continuously ===
   assign out_ready_i = out_valid_o;
  
   === REMOVED: does not work ===
   clk_gen CG(.END_SIM(end_sim),
              .CLK(clk_i),
              .RST_n(rst_ni));
   ============================== */

   // clock generation
   initial begin
	clk_i = 0;
	forever #5 clk_i = ~clk_i;	
   end

   // reset signal
   initial begin
	rst_ni = 0;
	repeat (5) @(posedge clk_i);
	rst_ni = 1;
   end

/* -----\/----- EXCLUDED -----\/-----
   data_gen32 DG(.CLK(clk_i),
	       .RST_n(rst_ni),
	       .D0(operands_i[0]),
	       .D1(operands_i[1]),
	       .D2(operands_i[2]),
	       .VOUT(in_valid_i),
	       .END_SIM(end_sim));  		    
 -----/\----- EXCLUDED -----/\----- */
 
/* ====== REMOVED: data operands are created manually ======
   data_gen16 DG(.CLK(clk_i),
	       .RST_n(rst_ni),
	       .D0(operands_i[0]),
	       .D1(operands_i[1]),
	       .D2(operands_i[2]),
	       .VOUT(in_valid_i),
	       .END_SIM(end_sim));  	
   ========================================================== */		       
	       
   fpnew_top UUT(
                 .clk_i,
                 .rst_ni,
		 .operands_i,
		 .rnd_mode_i,
		 .op_i,
		 .op_mod_i,
		 .src_fmt_i,
		 .dst_fmt_i,
		 .int_fmt_i,
		 .vectorial_op_i,
		 .tag_i,
		 .in_valid_i,
		 .in_ready_o,
		 .flush_i,
		 .result_o,
		 .status_o_NV_,
		 .status_o_DZ_,
		 .status_o_OF_, 
		 .status_o_UF_, 
		 .status_o_NX_,		 
		 .tag_o,
		 .out_valid_o,
		 .out_ready_i,
		 .busy_o);		 
   
  initial begin

        in_valid_i = 0;
        out_ready_i = 1;
	operands_i = '0;
        @(posedge rst_ni);
	repeat (2) @(posedge clk_i);        

        // test cases (as reference use results in ../fp_test/results.txt) - format sign (1b) + exponent (8b) + mantissa (7b)
        test_mul(16'h40E0, 16'h41C8); // 7.0    25.0
        test_mul(16'h3F00, 16'h3F00); // 0.5    0.5
        test_mul(16'h4180, 16'h3E80); // 16.0   0.25
        test_mul(16'h41A0, 16'h4248); // 20.0   50.0
        test_mul(16'h4158, 16'h4040); // 13.5   3.0
        test_mul(16'h4000, 16'h42A6); // 2.0    83.0
        test_mul(16'h4100, 16'h40E0); // 8.0    7.0
        test_mul(16'h40E0, 16'h40C0); // 7.0    6.0
        test_mul(16'h4110, 16'h4100); // 9.0    8.0
        test_mul(16'h4130, 16'h4130); // 11.0   11.0

        $display("All test cases applied.");
	repeat (20) @(posedge clk_i);        
	$finish;
end

task automatic test_mul(input [15:0] opa, input [15:0] opb);
begin

	// set operands
	@(posedge clk_i);
	operands_i[0] = opa;
	operands_i[1] = opb;
	operands_i[2] = 16'h0000;

	// after one clock cycle the input becomes valid
	@(posedge clk_i);
	in_valid_i = 1;

	// wait until the inputs are ready
	@(posedge clk_i);
	while (!in_ready_o) @(posedge clk_i);

	// inputs no longer valid after they are set to "ready"
	in_valid_i = 0;

	// wait until the result is valid
	wait(out_valid_o == 1);		// out_valid_o is asserted by the DUT when a new result_o is available
	
	// add additional clock cycles to make the results visible on the waveform display (or they would only last one clock cycle)
	out_ready_i = 0;		// out_ready_i is asserted by the testbench when ready to accept data (if low, DUT hold off)
	repeat (5) @(posedge clk_i); 
	out_ready_i = 1;		// after 5 clock cycles the transaction completes (out_valid_o & out_ready_i high -> result accepted)

	$display("A=%h B=%h => Result=%h", opa, opb, result_o);

	// wait one clock cycle before the next operation
	@(posedge clk_i);
	  
end
endtask

endmodule
   
