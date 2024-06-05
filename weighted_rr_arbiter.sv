module weighted_rr_arbiter
   #(parameter NUM_REQ=10,
     parameter IMPL_TYPE = 1)
  (    
      input  logic [NUM_REQ-1:0] req,
      output logic [NUM_REQ-1:0] gnt,
      input  logic               clk,
      input  logic               rst_b 
  )


//Although Round robin adopts a fair policy. Sometimes a single requestor can hog the bus
//For example: 
/*
Pri	Req	gnt
001	101	001
010	101	001
010	101	001
010	101	001
010	101	001

*/

/* with weights as soon as the weight of a requestor is 0, then its request is gated
	Weights	Pri	Req	gnt
	4-4-4	001	101	001
	4-4-3	010	101	001
	4-4-2	010	101	001
	4-4-1	010	101	001
	4-4-0	010	100	100
	3-4-0	010	100	100
	2-4-0	010	100	100
	1-4-0	010	100	100
	0-4-0	010	000	000
Reset	4-4-4	010	101	001


*/



//Define weights for each requestor(Can have different weights per requestor)
localparam INIT_WEIGHT = 3;
logic [3:0] weights [NUM_REQ];
logic gnt_zero,weights_zero;

assign gnt_zero=!|gnt;

always_comb begin
  for(int i=0 ; i<NUM_REQ ; i++)
      weights_zero &= weights[i] == 0;
end


always_ff(@posedge clk or negedge rst_b) begin
     if(!rst_b) begin
          for(int i=0 ; i<NUM_REQ ; i++)
             weights[i]<= INIT_WEIGHT;
     end else begin
          for(int i=0 ; i<NUM_REQ ; i++)
            if(gnt[i])
               weights[i] <= weights[i]-1;
            else if (weights_zero)
            //Reset back to initial weights
               weights[i] <= INIT_WEIGHT;
     end
end


always_comb begin
   for(int i=0 ; i<NUM_REQ ; i++)
      new_req[i] = req[i] & (weights[i]!=0);
end


rr_arbiter 

    (.NUM_REQ(NUM_REQ),
     .IMPL_TYPE(IMPL_TYPE)) rr_arbiter_u
    ( .req(new_req),
      .gnt(gnt),
      .clk(clk),
      .rst_b(rst_b)
    );

endmodule
