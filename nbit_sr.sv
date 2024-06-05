module nbit_sr
    #(parameter DSIZE  = 1,
      parameter DLY    = 1,
      parameter SH_R   = 1,
      parameter VEC    = 10)
    (
     input  logic [DSIZE-1:0]  din   [VEC],
     output logic [DSIZE-1:0]  dout  [VEC],
     input  logic              rst_b,
     input  logic              clk
     );

logic [DSIZE-1:0] stg [0:DLY-1][VEC];


if(SH_R == 1)
 always@(posedge clk or negedge rst_b) 
  stg<=(~rst_b)?'0:{din,stg[DLY-1:1]};
else
 always@(posedge clk or negedge rst_b)
  stg<=(~rst_b)?'0:{stg[DLY-2:0],din};


if(SH_R ==1)
  assign dout=stg[0];
else
  assign dout=stg[DLY-1];

endmodule

