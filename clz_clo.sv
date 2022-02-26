//Not an Efficient implementation both in terms of Power and Area.
//The beauty of this design is that it is scalable.
//This is a very intuitive code for a hardware Engineer, This applies 2 important concepts of software engineering: Divide and Conquer(Binary Tree approach) && Recursion(recursion in Hardware??? Are you kidding?)
//Recursive compilation is not supported in cadence genus 19.12
package clz_clo_pkg;
  localparam WI_SZ=32;
  localparam WO_SZ=$clog2(WI_SZ)+1;
  `define IMPL "RECURSE" 
endpackage


module clz_clo 
import clz_clo_pkg::*;
(
  input  logic [WI_SZ-1:0] in,
  output logic [WO_SZ-1:0] out
);
    
  generate
    // Base Case: Get LZC from two bits.
   if (`IMPL == "RECURSE") begin

    localparam TWO_BITS = 2;
    logic [WO_SZ-1:0] lzc;
    always_comb out = lzc;

     if (WI_SZ == TWO_BITS) begin: MUX_2BIT
      always_comb begin
        case (in)
         2'b00   : lzc = 2'b10;
         2'b01   : lzc = 2'b01;
         default : lzc = 2'b00;
       endcase
     end
   end: MUX_2BIT
   else begin: MOD_RECURSE
     /* Split Register into Halves */ 
     /* Module IO Sizes */
     localparam SPLIT_WI_SZ = WI_SZ/2;
     localparam SPLIT_WO_SZ = $clog2(SPLIT_WI_SZ)+1;
     /* Left Segment */
  	 localparam LHS_START = WI_SZ-1;
  	 localparam LHS_END   = WI_SZ-SPLIT_WI_SZ;
     /* Right Segment */
  	 localparam RHS_START = LHS_END-1;
  	 localparam RHS_END   = 0;
     /* Module Output Wires */
     logic [SPLIT_WO_SZ-1:0] lhs_lzc;
     logic [SPLIT_WO_SZ-1:0] rhs_lzc;
     
     /* Recurse Left */
     clz_clo #(
       .WI_SZ(SPLIT_WI_SZ),
       .WO_SZ(SPLIT_WO_SZ)
     ) LZC_LHS (
       .in(in[LHS_START:LHS_END]),
       .out(lhs_lzc)
     );
     
     /* Recurse Right */
     clz_clo #(
       .WI_SZ(SPLIT_WI_SZ),
       .WO_SZ(SPLIT_WO_SZ)
     ) LZC_RHS (
       .in(in[RHS_START:RHS_END]),
       .out(rhs_lzc)
     );
     
     /* Assemble the left-hand and right-hand LZC.
      * Decode using a Multiplexer
      */

     //This is same as:
     
     /* if(lhs_lzc>1) 
              lzc = lhs_lzc + rhs_lzc;
        else
              lzc = lhs_lzc;
     */ 
     always @(*) begin: MUX_DECODE
       logic lhs_msb, rhs_msb;
       logic [SPLIT_WO_SZ-2:0] rhs_no_msb;
       lhs_msb    = lhs_lzc[SPLIT_WO_SZ-1];
       rhs_msb    = rhs_lzc[SPLIT_WO_SZ-1];
       rhs_no_msb = rhs_lzc[SPLIT_WO_SZ-2:0];
       
       case ({lhs_msb,rhs_msb})
         2'b00 : lzc = lhs_lzc;
         2'b01 : lzc = lhs_lzc;
         2'b10 : lzc = {1'b1, rhs_no_msb};
         2'b11 : lzc = {rhs_lzc, 1'b0};
       endcase
       
     end: MUX_DECODE
     
   end: MOD_RECURSE
   else begin
     //Case Z based: Incomplete Implementation, 329 sq Microns in TSMC 110nm
      always_comb  begin
           casez(in[31:0])
             32'b01??????_????????_????????_????????: out = 1;
             32'b001?????_????????_????????_????????: out = 2;
           default : out = 0;
          endcase
      end
   end
    
  endgenerate
  
endmodule
