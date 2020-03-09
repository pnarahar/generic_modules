
//Author - Pradeep Naraharirao

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

localparam MAX_DEPTH = 2 ** ASIZE;

//Flip Flop based, Can be adapted to BRAM/SRAM based
logic  [DSIZE-1:0] queue [MAX_DEPTH - 1 : 0];

//Using n bit pointer:Tracking full/inference using almost full/empty
logic  [ASIZE-1  :0] rd_ptr;
logic  [ASIZE-1  :0] wr_ptr;
logic wr_en_q;
logic rd_en_q;

//Write and Read enable qualifiers
assign wr_en_q = wr_en & (~full);
assign rd_en_q = rd_en & (~empty);

always @(posedge clk or negedge rst_b)
begin
   if (~rst_b) begin
      rd_ptr <= 0;
      wr_ptr <= 0;
   end
   else begin
      if (wr_en_q) wr_ptr <= wr_ptr + {{(ASIZE-1){1'b0}}, 1'b1};
      if (rd_en_q) rd_ptr <= rd_ptr + {{(ASIZE-1){1'b0}}, 1'b1};
   end
end

always @(posedge clk)
begin
   if (wr_en_q)
      queue[wr_ptr[ASIZE-1:0]] <= din;
end

//full inference
always@(posedge clk or negedge rst_b) begin
    if(~rst_b)                                            full<=1'b0;
    else if(rd_en_q)                                      full<=1'b0;
    else if(wr_en_q && (rd_ptr==wr_ptr+1'b1))             full<=1'b1; //going to be full
    else                                                  full<=full;
end
//empty inference
always@(posedge clk or negedge rst_b) begin
    if(~rst_b)                                            empty<=1'b1;
    else if(wr_en_q)                                      empty<=1'b0;
    else if(rd_en_q && (wr_ptr==rd_ptr+1'b1))             empty<=1'b1; //going to be empty
    else                                                  empty<=empty;
end

assign dout = queue[rd_ptr[ASIZE-1:0]];

endmodule
