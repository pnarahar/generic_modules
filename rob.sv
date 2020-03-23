module rob
    #(parameter DSIZE = 1,
      parameter ASIZE = 1)
    (
     input logic            clk,
     input logic            rst_b,
//Interface with CDB
 
     input logic            cdb_val,   //signal to tell that the values coming on CDB is valid.
     input logic  [4:0]     cdb_robtag,//Tag of the instruction which the the CDB is broadcasting
     input logic  [31:0]    cdb_swaddr,//to give the store wordaddr

//Interface with Dispatch unit 
     input  logic           dis_inst_sw,     // signal that tells that the signal being dispatched is a store word
     input  logic           dis_reg_write,   //signal telling that the instruction is register writing instruction
     input  logic           dis_inst_valid,  //Signal telling that Dispatch unit is giving valid information
     input  logic [4:0]     dis_rob_rdaddr,  //Actual Destination register number of the instruction being dispatched
     input  logic [5:0]     dis_new_rd_phy_addr,// Current Physical Register number of dispatching instruction taken by the dispatch unit from the FRL
     input  logic [5:0]     dis_prev_phy_addr,//Previous Physical Register number of dispatch unit taken from CFC
     input  logic [5:0]     dis_sw_rt_phy_addr,// Physical Address number from where store word has to take the data    
//ROB status     
     output  logic          rob_full,
     output  logic          rob_two_or_more_vacant,        

// Interface with store buffer
     input logic            sb_full,           // Tells the ROB that the store buffer is full
     output logic [31:0]    rob_swaddr,        // The address in case of sw instruction
     output logic	    rob_commitmemwrite,// Signal to enable the memory for writing purpose  

// Interface with FRL and CFC			  
     output logic  [5:0]    rob_rdptr,            // Gives the value of TopPtr pointer of ROB(Read Pointer)
     output logic  [5:0]    rob_wrptr,            // Gives the Bottom Pointer of ROB (Write Pointer)
     output logic           rob_commit,           // FRL needs it to to add previously-mapped physical register to free list cfc needs it to remove the latest checkpointed copy
     output logic  [4:0]    rob_commitrdaddr,     // Architectural register number of committing instruction
     output logic           rob_commitregwrite,   // Indicates that the instruction that is being committed is a register writing instruction
     output logic  [5:0]    rob_commitprephyaddr, // pre physical addr of committing inst to be added to FRL
     output logic  [5:0]    rob_commitcurrphyaddr,// Current Register Address of committing instruction to update retirement rat			  
     input  logic           cdb_flush,            // Flag indicating that current instruction is mispredicted or not
     input  logic  [4:0]    cfc_robtag            // Tag of the instruction that has the checkpoint
     );

logic [31:0] [5:0]  curr_phy_addr,prev_phy_addr;
logic [31:0] [4:0]  rd_addr;
logic [31:0]        reg_wr,mem_wr,complete;
logic [31:0] [20:0] sw_addr;
logic [5:0]         wr_ptr,rd_ptr,internal_depth;
logic               full,empty;
assign full  = ((wr_ptr ^ rd_ptr)==6'b10000);
assign empty = &(~(wr_ptr ^ rd_ptr));
assign rob_rdptr = rd_ptr;
assign rob_wrptr = wr_ptr;

//Interface with store Buffer

assign rob_swaddr              = {rd_addr[rd_ptr],prev_phy_addr[rd_ptr],sw_addr[rd_ptr]}; 


//Interface with FRL and CFC
assign rob_commitrdaddr        = rd_addr[rd_ptr];
assign rob_commitregwrite      = reg_wr [rd_ptr];
assign rob_commitprephyaddr    = prev_phy_addr[rd_ptr];
assign rob_commitcurrphyaddr   = curr_phy_addr[rd_ptr];
assign rob_commit              = (~empty) & complete[rd_ptr] & (~mem_wr[rd_ptr] | ~sb_full); 
assign internal_depth          = cfc_rob_tag - rd_ptr;


always@(posedge clk or negedge rst_b)  begin
    if(~rst_b)   begin
         for(i=0;i<32;i++) begin
             reg_wr[i] <= '0;
             complete[i] <= '0;
             mem_wr[i] <= '0;
             curr_phy_addr <= '0;
             prev_phy_addr <= '0;
             rd_addr[i]    <= '0;
             sw_addr[i]    <= '0;
         end
         rd_ptr<='0;wr_ptr<='0;
    end else begin
         if(rob_commit) begin
             rd_ptr            <=rd_ptr+1;
             complete[rd_ptr]  <= 1'b1; 
         end
         if(dis_inst_valid & (~full | (full & commit))) begin
             reg_wr[wr_ptr] <= dis_reg_write;
             mem_wr[wr_ptr] <= dis_inst_sw;
             complete[wr_ptr] <= '0;
             if (~dis_inst_sw) begin
                   rd_addr[wr_ptr]       <= dis_rob_rd_addr;
                   prev_phy_addr[wr_ptr] <= dis_prev_phy_addr;
                   curr_phy_addr[wr_ptr] <= dis_new_phy_addr;   
	     end else begin	
                   CurrPhyArray[wr_ptr]  <= dis_sw_rt_phy_addr;
             end	
         end
         if(cdb_val) begin
             complete[cdb_rob_tag] <= 1'b1;
             if(mem_wr[cdb_rob_tag]) begin
                  sw_addr      [cdb_rob_tag] <= cdb_sw_addr[20:0];
                  prev_phy_addr[cdb_rob_tag] <= cdb_sw_addr[26:21];
                  rd_addr      [cdb_rob_tag] <= cdb_sw_addr[31:27];       
             end
         end
         if(cdb_flush) begin
              if(internal_depth < 0) begin
                   wr_ptr <= internal_depth + rd_ptr + {1'b1,4'b0};//Modulo 32 subtraction
              end
              else begin
                   wr_ptr <= internal_depth + rd_ptr;
              end
         end
    end
end
endmodule
