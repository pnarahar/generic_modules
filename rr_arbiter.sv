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
   #(parameter NUM_REQ=10,
     parameter IMPL_TYPE = 1)
  (    
      input  logic [NUM_REQ-1:0] req,
      input  logic [NUM_REQ-1:0] hold,
      output logic [NUM_REQ-1:0] gnt,
      input  logic               clk,
      input  logic               rst_b 
  )


if(IMPL_TYPE == 0) begin

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
end else begin
   
   logic gnt_zero;
   logic [NUM_REQ-1:0] pri,pri_req,req_eff;

   assign gnt_zero = ~|gnt;


//Determine the priorities for each requestor, Clear the priorities as and when an adjacent grant is presented.
   for (genvar i=0 ; i<NUM_REQ; i++) begin
              logic [NUM_REQ-1:0] tmp_i;
//pri for gnt[0] is set if there was a grant for gnt[NUM_REQ-1] or if there was no grant in current cycle hold the priorities 
              assign tmp_i = i[NUM_REQ-1:0];
              always_ff(posedge clk or negedge rst_n)
              if(!rst_n)     pri[i] <= '1;
              else           pri[i] <= gnt[tmp_i-1]  | (gnt_zero & pri[i]);
   end

   assign pri_req = pri & req ;
 
//Check if masked request is 0  
   assign req_eff = (~|pri_req) ? req : pri_req;


    //Fixed Priority resolver

 fixed_prioritizer
   (
     .NUM_REQ(NUM_REQ)
   ) fixed_prioritizer_u
   (
     .req(req_eff[NUM_REQ-1:0]),
     .gnt(gnt_int[NUM_REQ-1:0])
   );

 //There are situations when a particular requestor need to continue to get access to the bus. This may be due to Qos requirements or a narrow width which would need multiple cycles for a transaction to go across.
 //Then a hold signal is introduced to keep the current grant active until the hold can be released.
 //Memorize the current grant in a register called grant_last.
 logic [NUM_REQ-1:0] gnt_int,gnt_o,gnt_last;
 logic any_hold;
 always_ff(@posedge clk or negedge rst_n) begin
   if(!rst_n)
     gnt_last <= '0;
   else if(|gnt)
     gnt_last <= gnt;
 end
 
 //gnt_last is one hot vector
 assign any_hold = |(gnt_last & hold);
 assign gnt      = gnt_o | (gnt_last & hold);
 //Negates the internally calculated current arbitration if there is a hold condition from any requestors.
 assign gnt_o    = gnt_int & !any_hold;

end
endmodule
