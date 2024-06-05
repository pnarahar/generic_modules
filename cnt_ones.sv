package cnt_ones_pkg;
  localparam WI_SZ=32;
  localparam WO_SZ=$clog2(WI_SZ)+1;
  `define IMPL "RECURSE" 
endpackage


module cnt_ones 
import cnt_ones_pkg::*;
(
  input  logic [WI_SZ-1:0] in,
  output logic [WO_SZ-1:0] out
);
    
  generate
    // Base Case: Num of ones in two bits.
   if (`IMPL == "RECURSE") begin

    localparam TWO_BITS = 2;
    logic [WO_SZ-1:0] sum;
    always_comb out = sum;

    if (WI_SZ == TWO_BITS) begin: ADD_2BITS
       assign sum = ones[1] + ones[0];
    end: ADD_2BITS
    else begin: MOD_RECURSE
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
     logic [SPLIT_WO_SZ-1:0] lhs_ones;
     logic [SPLIT_WO_SZ-1:0] rhs_ones;
     
     /* Recurse Left */
     cnt_ones #(
       .WI_SZ(SPLIT_WI_SZ),
       .WO_SZ(SPLIT_WO_SZ)
     ) cnt_ones_lhs_u (
       .in(in[LHS_START:LHS_END]),
       .out(lhs_ones)
     );
     
     /* Recurse Right */
     cnt_ones #(
       .WI_SZ(SPLIT_WI_SZ),
       .WO_SZ(SPLIT_WO_SZ)
     ) cnt_ones_rhs_u (
       .in(in[RHS_START:RHS_END]),
       .out(rhs_ones)
     );
     
     /* Assemble the left-hand and right-hand sum.*/
     assign sum = lhs_ones + rhs_ones;
     
   end: MOD_RECURSE
   else begin
        logic [WO_SZ-1:0] sum;
        always_comb begin
             sum=0;
             for(i=0;i<WI_SZ;i++)
                sum+=in[i];
        end
        assign out = sum;
   end
   end
  endgenerate
  
endmodule
