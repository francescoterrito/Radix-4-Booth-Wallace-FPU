package constants;
	// the MBE multiplier works on 9 bits, which is given by:
	//	7 mantissa bits
	// 	1 normalization bit (always equal to 1)
	//	1 positive sign extension bit (always a 0 to make the number unsigned)
	//	example: 	0010111 is the 7-bit mantissa
	//			append '1' as MSB to denormalize it -> 10010111 (8 bits)
	//			append '0' as MSB to make it unsigned (positevly signed) -> 010010111 (9 bits)
	parameter int NBITS = 9;
endpackage;
