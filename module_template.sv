module sync_fifo
    #(parameter DSIZE = 1,
      parameter ASIZE = 1)
    (
     input  logic [DSIZE-1:0]  din,
     input  logic              wr_en,
     input  logic              rd_en,
     output logic [DSIZE-1:0]  dout,
     output logic              full,
     output logic              empty,
     input  logic              rst_b,
     input  logic              clk
     );

