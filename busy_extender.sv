//Make no assumptions on the width of busy_in

module busy_extender
(
input logic clk,
input logic reset,
input logic busy_in,
output logic busy_out
);
#(parameter NSTAGES=4)

//busy_out is NSTAGES+1 wide.
//Assuming a posedge async reset
logic busy_in_r;
logic all_stage_ored;
logic busy_pls;
genvar i;
reg [NSTAGES-1:0] stage;

//Edge detect busy(Making a cycle wide)
always@(posedge clk or posedge reset)
  begin
    if(reset) busy_in_r<='0;
    else busy_in_r<=busy_in;
  end

assign busy_pls=~busy_in_r & busy_in;

generate
  for (i = 0; i < N_STAGES; i++) begin
    if (i == 0) begin
      always @(posedge clk or posedge reset) begin
        if (reset)
          stage[i] <= '0;
        else
          stage[i] <= busy_pls;
      end
    end else begin
      always @(posedge clk or posedge reset) begin
        if (reset)
          stage[i] <= '0;
        else
          stage[i] <= stage[i-1];
      end
	end
  end
endgenerate

assign all_stage_ored=|stage;
assign busy_out=busy_pls | all_stage_ored;

endmodule
