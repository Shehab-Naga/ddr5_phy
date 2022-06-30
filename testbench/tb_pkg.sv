package tb_pkg;
	import uvm_pkg::*;
        //Declaration macros to provide multiple implemenation ports (multiple write functions).
        `uvm_analysis_imp_decl(_port_mc)        //  DFI Port
        `uvm_analysis_imp_decl(_port_dram)      //  JEDEC Port
        //Data Types definitions	
        typedef enum bit [2:0]   {DES, MRW, MRR, ACT, RD, NOP, PREab, other} command_t;
	typedef enum bit [1:0] 	{BL16, BC8_OTF, BL32} burst_length_t;			//Double data words
        //Includes
	`include "uvm_macros.svh"
	`include "transactions/ddr_sequence_item.sv"
	`include "components/mc_agent/mc_sequencer.sv"
	`include "components/mc_agent/mc_driver.sv"
	`include "components/mc_agent/mc_monitor.sv"
	`include "components/mc_agent/mc_agent.sv"
	`include "components/dram_agent/dram_sequencer.sv"
	`include "components/dram_agent/dram_driver.sv"
	`include "components/dram_agent/dram_monitor.sv"
	`include "components/dram_agent/dram_agent.sv"
	`include "components/scoreboard.sv"
	`include "components/subscriber.sv"
	`include "components/env.sv"
	`include "sequences/sequence_lib.sv"
	`include "tests/test_lib.sv"
endpackage : tb_pkg

`include "interfaces/dfi_intf.sv"
`include "interfaces/jedec_intf.sv"



