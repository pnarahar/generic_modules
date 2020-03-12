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
     output logic  [4:0]    rob_wrptr,            // Gives the Bottom Pointer of ROB (Write Pointer)
     output logic           rob_commit,           // FRL needs it to to add previously-mapped physical register to free list cfc needs it to remove the latest checkpointed copy
     output logic  [4:0]    rob_commitrdaddr,     // Architectural register number of committing instruction
     output logic           rob_commitregwrite,   // Indicates that the instruction that is being committed is a register writing instruction
     output logic  [5:0]    rob_commitprephyaddr, // pre physical addr of committing inst to be added to FRL
     output logic  [5:0]    rob_commitcurrphyaddr,// Current Register Address of committing instruction to update retirement rat			  
     input  logic           cdb_flush,            // Flag indicating that current instruction is mispredicted or not
     input  logic  [4:0]    cfc_robtag            // Tag of the instruction that has the checkpoint
     );

