// Declare a testbench module called "tb_fpnew_top" without ports "()"
module tb_fpnew_top ();

//   parameter fpnew_pkg::fpu_features_t       Features       = fpnew_pkg::RV32F;
   
   // Define the format (16-bit bfloat FPU), the implementation (pipelined) and the type for tagging operations (logic)
   parameter fpnew_pkg::fpu_features_t       Features       = fpnew_pkg::RVBF16;  
   parameter fpnew_pkg::fpu_implementation_t Implementation = fpnew_pkg::ISA_PIPE;
   parameter type                            TagType        = logic;
   
   // Define width of operands and the number of operands per operation
   localparam int unsigned WIDTH        = Features.Width;
   localparam int unsigned NUM_OPERANDS = 3;
   
   // SIGNALS AND VARIABLES
   wire clk_i;						// clock
   wire rst_ni;						// active low reset
   logic [NUM_OPERANDS-1:0][WIDTH-1:0] operands_i;	// 3 operands of width WIDTH
   var fpnew_pkg::roundmode_e rnd_mode_i;		// floating point rounding mode
   var fpnew_pkg::operation_e op_i;			// operation type (ADD, MUL...)
   var logic op_mod_i;					
   var fpnew_pkg::fp_format_e src_fmt_i;		// input/output FP and integer formats
   var fpnew_pkg::fp_format_e dst_fmt_i;
   var fpnew_pkg::int_format_e int_fmt_i;
   var logic vectorial_op_i;				// if the operation is vectorized
   var TagType tag_i;					// optional tag to track operations
   logic in_valid_i;					// handshakes for input
   wire in_ready_o;		
   var logic flush_i;							
   wire [WIDTH-1:0] result_o;				// FPU outpute result
   var fpnew_pkg::status_t status_o;			// status flags (overflow, underflow...)
   wire tag_o;						// optional tag to track operations
   wire out_valid_o;					// handshakes for output
   var logic out_ready_i;
   wire busy_o;						// FPU busy signal
   wire end_sim;					// signals end of testbench run

   // STATIC ASSIGNMENTS
   assign rnd_mode_i	= fpnew_pkg::RNE;		// fixed rounding mode to nearest even (RNE)
   assign op_i 		= fpnew_pkg::MUL;		// fixed operation to multiply (MUL)
/* -----\/----- EXCLUDED -----\/-----
   assign src_fmt_i = fpnew_pkg::FP32;
   assign dst_fmt_i = fpnew_pkg::FP32;
   assign int_fmt_i = fpnew_pkg::INT32;
 -----/\----- EXCLUDED -----/\----- */
   assign src_fmt_i 	= fpnew_pkg::FP16ALT;		// in/out formats set to 16-bit FP format
   assign dst_fmt_i 	= fpnew_pkg::FP16ALT;
   assign int_fmt_i 	= fpnew_pkg::INT16;   		// integer format set to 16-bit
   assign vectorial_op_i = 0;				// not using vector operations
   assign tag_i 	= 0;				// tags, flush and operation modifier all default to 0
   assign flush_i 	= 0;
   assign op_mod_i 	= 0;
   assign out_ready_i 	= out_valid_o;			// automatically consume the output when it is valid
      		     
   // INSTATIATE CLOCK GENERATOR
   clk_gen CG(.END_SIM(end_sim),			// instantiate a clk_gen module to drive the clock and reset and provide end simulation signal
              .CLK(clk_i),
              .RST_n(rst_ni));

   // INSTATIATE DATA GENERATOR
/* -----\/----- EXCLUDED -----\/-----
   data_gen32 DG(.CLK(clk_i),
	       .RST_n(rst_ni),
	       .D0(operands_i[0]),
	       .D1(operands_i[1]),
	       .D2(operands_i[2]),
	       .VOUT(in_valid_i),
	       .END_SIM(end_sim));
 -----/\----- EXCLUDED -----/\----- */

/* ---   data_gen16 DG(.CLK(clk_i),
	       .RST_n(rst_ni),
	       .D0(operands_i[0]),
	       .D1(operands_i[1]),
	       .D2(operands_i[2]),
	       .VOUT(in_valid_i),
	       .END_SIM(end_sim)); --- */  		       
   
   initial begin

	// define 10 pairs of operands (FP 16-bit)
        logic [9:0][WIDTH-1:0] opA, opB;

	in_valid_i = 0;

	// wait for reset release
	@(negedge rst_ni);
	@(posedge rst_ni);
	#10;

	// initialize 10 pairs of operands (FP 16-bit)
	opA = '{ 16'h40E0, 16'h3F00, 16'h4180, 16'h41A0, 16'h4158, 16'h4000, 16'h4100, 16'h40E0, 16'h4110, 16'h4130 };
	opB = '{ 16'h41C8, 16'h3F00, 16'h3E80, 16'h4248, 16'h4040, 16'h42A6, 16'h40E0, 16'h40C0, 16'h4100, 16'h4130 };

	// loop through 10 multiplications
	for (int i = 0; i < 10; i++) begin
		operands_i[0] = opA[i];
		operands_i[1] = opB[i];
		operands_i[2] = 0;
		in_valid_i = 1;
		#10;				// wait for a few cycles
		in_valid_i = 0;
		
		// wait for result of this multiplication
		wait(out_valid_o);
		#20;
	end
/*
        // first multiplication
        operands_i[0] = 16'h40E0;
        operands_i[1] = 16'h41C8;
        operands_i[2] = 0;
        in_valid_i = 1;
	#10;                                            // wait a few cycles
	in_valid_i = 0;

	// wait for first result
	wait(out_valid_o);
	#20;

        // second multiplication
        operands_i[0] = 16'h4100;
        operands_i[1] = 16'h4100;
        operands_i[2] = 0;
	in_valid_i = 1;
	#10;
	in_valid_i = 0;

	// wait for second result
	wait(out_valid_o);
	#20;
*/	
	$finish;
   end
      
   // INSTANTIATE FPU UNDER TEST
   fpnew_top UUT(					// instatiate FPU under test and connect all signals
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
		 .status_o,
		 .tag_o,
		 .out_valid_o,
		 .out_ready_i,
		 .busy_o);	
	 
endmodule

