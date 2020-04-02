module nbit_sr
    #(parameter DSIZE  = 1,
      parameter DLY    = 1,
      parameter SH_R   = 1)
    (
     input  logic [DSIZE-1:0]  din,
     output logic [DSIZE-1:0]  dout,
     input  logic              rst_b,
     input  logic              clk
     );

logic [DSIZE-1:0] stg [0:DLY-1];

always@(posedge clk or negedge rst_b) begin
  if(SH_R == 1) 
    stg<=(~rst_b)?'0:{din,stg[DLY-1:1]};
  else
    stg<=(~rst_b)?'0:{stg[DLY-1:1],din};
end
assign dout=stg[DLY-1];

endmodule

