module divby2_power_n
    #(parameter DIV_AMT = 8)
    (
     output logic              out_clk
     input  logic              rst_b,
     input  logic              clk
     );

logic [$clog2(DIV_AMT)-1:0] clk_div;
genvar i;
generate 
    for(i=0;i<$clog2(DIV_AMT);i++) begin
        if(i==0) begin
             always @(posedge clk or negedge rst_b)
               if (~rst_b)
                 clk_div[i] <= '0;
               else
                 clk_div[i] <= ~clk_div[i];
        end
        else begin
            always @(posedge clk_div[i-1] or negedge rst_b)
               if (~rst_b)
                 clk_div[i] <= '0;
               else
                 clk_div[i] <= ~clk_div[i];
        end
    end
endgenerate
//Separate out DFF and instantiate it as a separate module which will give you ability to instantiate DFF of specific strength.
