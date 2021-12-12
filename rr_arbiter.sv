module fixed_prioritizer
#(parameter NUM_REQ=10)
(
input  logic [NUM_REQ-1:0] req,
output logic [NUM_REQ-1:0] gnt 
);
logic [NUM_REQ-1:0] higher_prior_req;
assign gnt[NUM_REQ-1:0] = req[NUM_REQ-1:0] & (~higher_prior_req[NUM_REQ-1:0]);
genvar i;
   generate
       for(i=0;i<NUM_REQ;i++) begin
           if(i==0) 
              higher_prior_req[i] = 0;
           else
              higher_prior_req[i]=req[i-1] | higher_prior_req[i-1];
       end
   endgenerate
endmodule


//Algorithm for RR arbitration 
module rr_arbiter
   #(parameter NUM_REQ=10)
  (    
      input  logic [NUM_REQ-1:0] req,
      output logic [NUM_REQ-1:0] gnt,
      input  logic               clk,
      input  logic               rst_b 
  )

 logic [2*NUM_REQ-1:0] rot_req,rot_gnt_one_hot;
 logic [$clog2(NUM_REQ)-1:0] gnt_enc; 

 //Add a mux here to hold the current requestor priority intact. The current requestor would still win the arbitration
 assign rot_req = {req,req} >> (curr_gnt+1);
  
 //Fixed Priority resolver

 fixed_prioritizer
   (
     .NUM_REQ(NUM_REQ)
   ) fixed_prioritizer_u
   (
     .req(rot_req[NUM_REQ-1:0]),
     .gnt(gnt_one_hot[NUM_REQ-1:0])
   );
//Rerotate

 assign rot_gnt_one_hot = {gnt_one_hot,gnt_one_hot} << (curr_gnt+1);
 assign gnt = rot_gnt_one_hot[2*NUM_REQ-1:NUM_REQ];

//Register the current gnt number in encoded format

 always @(posedge clk or negedge rst_b)  begin
    if(~rst_b) curr_gnt <= NUM_REQ-1;
    else       curr_gnt <= gnt_enc;
 end



if(MUX_BASED==1) begin
      always_comb begin
         gnt_enc='0;
         for(int i=0 ; i<NUM_REQ ;i++)
            if(gnt[i]) gnt_enc = i;
      end
end else begin


   
//Decoded Format to Encoded Format: Mux Based

//	7	6	5	4	3	2	1	0			|oh & mask
//one	1	0	0	0	0	0	0	0			
//Mask	1	0	1	0	1	0	1	0		[0]	1
//Mask	1	1	0	0	1	1	0	0		[1]	1
//Mask	1	1	1	1	0	0	0	0		[2]	1
//											
//											
//one	0	1	0	0	0	0	0	0               [0]	0
//										[1]	1
//										[2]	1




//Better method : building a mask for each output binary bit


for (genvar j = 0; j < $clog2(NUM_REQ); j++) begin : jl
        logic [NUM_REQ-1:0] tmp_mask;
            for (genvar i = 0; i < NUM_REQ; i++) begin : il
                logic [$clog2(NUM_REQ)-1:0] tmp_i;
                assign tmp_i = i;
                assign tmp_mask[i] = tmp_i[j];
            end
        assign gnt_enc[j] = |(tmp_mask & gnt);
end

end

endmodule
