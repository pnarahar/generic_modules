//Reserve a CDB slot for variable latencies execution unit. If there are multiple units that have same latencies then a toggle bit is used to alternate between the two colliding requests for the cdb slot time.
module issue_unit
#(
parameter NUM_MUL_CYC = 4,
parameter NUM_DIV_CYC = 6
)
(
input logic clk,
input logic rst_b.

input logic issue_rdy_div,  //6Cycle Latency
input logic issue_rdy_mul,  //4Cycle Latency
input logic issue_rdy_int,  //1Cycle Latency
input logic issue_rdy_ls,   //1Cycle Latency

output logic issue_div,
output logic issue_mul,
output logic issue_int,
output logic issue_ls

);

localparam MAX_LAT = (NUM_MUL_CYC > NUM_DIV_CYC)? NUM_MUL_CYC : NUM_DIV_CYC;
localparam SEC_MAX_LAT = (NUM_MUL_CYC > NUM_DIV_CYC)? NUM_DIV_CYC : NUM_MUL_CYC;

logic [MAX_LAT-1:0]cdb_slot;
logic lru,lru_mul_div;
logic max_lat_arith_op;

assign max_lat_arith_op = (NUM_MUL_CYC > NUM_DIV_CYC)? issue_rdy_mul : issue_rdy_div ;
assign second_max_lat_arith_op = (NUM_MUL_CYC > NUM_DIV_CYC)? issue_rdy_div : issue_rdy_mul; 


always(@posedge clk or negedge rst_b)
   begin
     if(~rst_b) begin
         cdb_slot <='0;
         lru<=0;
         lru_mul_div<='0;
         issue_ls<=1'b0;
         issue_int<=1'b0;
         issue_div<=1'b0;
         issue_mul<=1'b0;
   end else begin
         cdb_slot<={1'b0,cdb_slot[MAX_LAT-1:1]};  //Right shift for tracking passage of time
         issue_ls<=1'b0;
         issue_int<=1'b0;
         issue_div<=1'b0;
         issue_mul<=1'b0;
      //Single Cycle reservation   
         if(~cdb_slot[0]) begin
            //Check for LS or integer requests
              if(issue_rdy_ls & ~issue_rdy_int) begin 
                   issue_ls<=1'b1;
              end else if(~issue_rdy_ls & issue_rdy_int) begin
                   issue_int<=1'b1;
              end else if(issue_rdy_ls & issue_rdy_int) begin
                   issue_int<=lru;
                   issue_int<=~lru;
                   lru<=~lru;
              end
         end
     if(MAX_LAT != SEC_MAX_LAT) begin
         if(max_lat_arith_op) begin 
           cdb_slot[MAX_LAT-1] <= 1'b1;
           if(NUM_MUL_CYC > NUM_DIV_CYC)
               issue_mul<=1'b1;
           else
               issue_div<=1'b1;

         end
        
         if(second_max_lat_arith_op & ~cdb_slot[SEC_MAX_LAT]]) begin
           cdb_slot[SEC_MAX_LAT-1] <= 1'b1;

           if(NUM_MUL_CYC > NUM_DIV_CYC)
               issue_div<=1'b1;
           else
               issue_mul<=1'b1;
         end
     end else begin
         if(max_lat_arith_op & ~second_max_lat_arith_op) begin 
               issue_div<=1'b1;
         end else if(~max_lat_arith_op & second_max_lat_arith_op) begin
               issue_mul<=1'b1;
         end else if(max_lat_arith_op & second_max_lat_arith_op) begin
               issue_mul<=lru_mul_div;
               issue_div<=~lru_mul_div;
               lru_mul_div<=~lru_mul_div;
         end
     end
   end
  end
endmodule

