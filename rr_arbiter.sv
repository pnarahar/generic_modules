module fixed_prioritizer
#(parameter NUM_REQ=10)
(
input  logic [NUM_REQ-1:0] req,
output logic [NUM_REQ-1:0] gnt 
);
logic [NUM_REQ-1:0] higher_prior_req;
assign gnt[N-1:0] = req[N-1:0] & (~higher_prior_req[N-1:0]);
genvar i;
   generate
       for(i=0;i<NUM_REQ;i++) begin
           if(i==0) 
              higher_prior_req[i] = 0;
           else
              higher_prior_req[i]=req[i] | higher_prior_req[i-1];
       end
   endgenerate
endmodule


//Algorithm for RR arbitration 
module rr_arbiter
   #(parameter NUM_REQ=10)
  (    
      input logic [NUM_REQ-1:0]  req,
      output logic [NUM_REQ-1:0] gnt,
      input  logic               clk,
      input  logic               rst_b 
  )

 logic [2*NUM_REQ-1:0] rot_req,rot_gnt_one_hot;
 logic [NUM_REQ-1:0]   rot_gnt_one_hot;
 logic [$clog2(NUM_REQ)-1:0] 

 assign rot_req = {req,req} >> (curr_gnt+1);
  
 //Fixed Priority resolver

 fixed_prioritizer
   (
     .NUM_REQ(NUM_REQ)
   )
   (
     .req(rot_req[NUM_REQ-1:0]),
     .gnt(gnt_one_hot[NUM_REQ-1:0])
   );
//Rerotate

 assign gnt = {gnt_one_hot,gnt_one_hot} << (curr_gnt+1);

//Register the current gnt number in encoded format

 always @(posedge clk or negedge rst_b)  begin
    if(~rst_b) curr_gnt <= NUM_REQ-1;
    else       curr_gnt <= gnt_enc;
 end
   
always_comb begin
   gnt_enc='0;
   for(int i=0 ; i<NUM_REQ ;i++)
      if(gnt[i]) gnt_enc = i;
end
 

endmodule