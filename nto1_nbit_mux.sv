//This is not an optimized solution:In the past I have seen realizing these muxes with only 2:1 is an efficient solution.(The basic primitive is a 2:1 mux at the leaf level-Anil's solution
module nto1_mbit_mux
#(parameter N=16,
  parameter M=32)
(
   input logic  [(N*M)-1:0]     in,
   output logic [M-1:0]         out,
   input  logic [$clog2(N)-1:0] sel
)
  logic [M-1:0] unpacked_out [0:N-1];
  assign out=unpacked_out[N-1];
  generate
      for(i=0;i<N;i++) begin
           unpacked_out[i] = in[(((i+1)*M)-1):i*M];
      end
  endgenerate
endmodule
