/***************************** mc_sanity Sequence Description ****************************

Class		: 	ddr_sanity_seq
Description	:	This sequence performs a mc_sanity sequence (for direct test)

************************************************************************************/

class ddr_sanity_seq extends base_seq;

	function new(string name="ddr_sanity_seq");
	super.new(name);
	endfunction

	`uvm_object_utils(ddr_sanity_seq)
	
	ddr_sequence_item item1;
	command_t CMD = MRW;
	

	task pre_body();
		item1 = ddr_sequence_item::type_id::create ("item1");
	endtask

	task body();
		ACT_cmd(.iscanceled(0), .delay(8), .CMD_prev(CMD), .CMD(CMD));

		read_cmd(.BL_mod(0), .AP(1), .C10(1), .iscanceled(0), .delay(8), .CMD_prev(CMD), .CMD(CMD));			//Activate BL_mode in MR0, deactivate AP

		PREab_cmd(.AP(1), .delay(12), .CMD_prev(CMD), .CMD(CMD));

		MRW_cmd(.MRA(8'h08), .OP(8'b00000_000), .delay(24), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));	//Set Read Preamble		

		MRW_cmd(.MRA(8'h00), .OP(8'b0_00111_00), .delay(8), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));	//Set CAS LATENCY, BL 
				
		MRR_cmd(.MRA('d0), .delay(16), .iscanceled(1), .CMD_prev(CMD), .CMD(CMD));
	
		MRR_cmd(.MRA('d0), .delay(16), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));

		ACT_cmd(.iscanceled(0), .delay(30), .CMD_prev(CMD), .CMD(CMD));
	
		read_cmd(.BL_mod(0), .AP(1), .C10(1), .iscanceled(0), .delay(24), .CMD_prev(CMD), .CMD(CMD));			

		read_cmd(.BL_mod(0), .AP(0), .C10(0), .iscanceled(0), .delay(8), .CMD_prev(CMD), .CMD(CMD));

		ACT_cmd(.iscanceled(0), .delay(86), .CMD_prev(CMD), .CMD(CMD));

		read_cmd(.BL_mod(0), .AP(1), .C10(1), .iscanceled(0), .delay(24), .CMD_prev(CMD), .CMD(CMD));

		read_cmd(.BL_mod(0), .AP(0), .C10(0), .iscanceled(0), .delay(8), .CMD_prev(CMD), .CMD(CMD));

		ACT_cmd(.iscanceled(0), .delay(36), .CMD_prev(CMD), .CMD(CMD));

		read_cmd(.BL_mod(0), .AP(1), .C10(1), .iscanceled(1), .delay(24), .CMD_prev(CMD), .CMD(CMD));

		read_cmd(.BL_mod(0), .AP(0), .C10(0), .iscanceled(1), .delay(8), .CMD_prev(CMD), .CMD(CMD));

		read_cmd(.BL_mod(0), .AP(1), .C10(1), .iscanceled(0), .delay(11), .CMD_prev(CMD), .CMD(CMD));

		read_cmd(.BL_mod(0), .AP(0), .C10(0), .iscanceled(1), .delay(8), .CMD_prev(CMD), .CMD(CMD));

		//PREab_cmd(.AP(1), .delay(80), .CMD_prev(CMD), .CMD(CMD));
/* Furthur Combinations

		//BC8_OTF,  Preamble 4, 
		MRW_cmd(.MRA(8'h08), .OP(8'b00000_100), .delay(8), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));		//Set Read Preamble		

		MRW_cmd(.MRA(8'h00), .OP(8'b0_00101_01), .delay(16), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));	//Set CAS LATENCY, BL 
				
		MRR_cmd(.MRA('d0), .delay(8), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));

		ACT_cmd(.iscanceled(0), .delay(8), .CMD_prev(CMD), .CMD(CMD));
	
		read_cmd(.BL_mod(0), .AP(1), .C10(1), .iscanceled(0), .delay(8), .CMD_prev(CMD), .CMD(CMD));


		//BL32,  Preamble 0
		MRW_cmd(.MRA(8'h08), .OP(8'b00000_000), .delay(8), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));		//Set Read Preamble		

		MRW_cmd(.MRA(8'h00), .OP(8'b0_00101_10), .delay(16), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));	//Set CAS LATENCY, BL 
				
		MRR_cmd(.MRA('d0), .delay(8), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));

		ACT_cmd(.iscanceled(0), .delay(8), .CMD_prev(CMD), .CMD(CMD));
	
		read_cmd(.BL_mod(0), .AP(1), .C10(1), .iscanceled(0), .delay(8), .CMD_prev(CMD), .CMD(CMD));



		//BL32_OTF,  Preamble 2
		MRW_cmd(.MRA(8'h08), .OP(8'b00000_010), .delay(8), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));		//Set Read Preamble		

		MRW_cmd(.MRA(8'h00), .OP(8'b0_00101_11), .delay(16), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));	//Set CAS LATENCY, BL 
				
		MRR_cmd(.MRA('d0), .delay(8), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));

		ACT_cmd(.iscanceled(0), .delay(8), .CMD_prev(CMD), .CMD(CMD));
	
		read_cmd(.BL_mod(0), .AP(1), .C10(1), .iscanceled(0), .delay(8), .CMD_prev(CMD), .CMD(CMD));


*/
	terminate(.delay(8));				//Send termination flag to dram_resp_seq after some delay

	endtask

	extern task MRW_cmd(byte MRA, bit [7:0] OP, int delay, bit iscanceled, command_t CMD_prev, output command_t CMD);
	extern task read_cmd(bit BL_mod, bit AP, bit C10, bit iscanceled, int delay, command_t CMD_prev, output command_t CMD);
	extern task PREab_cmd(bit AP, int delay, command_t CMD_prev, output command_t CMD);
	extern task ACT_cmd(bit iscanceled, int delay, command_t CMD_prev, output command_t CMD);
	extern task MRR_cmd(byte MRA, int delay, bit iscanceled, command_t CMD_prev, output command_t CMD);
	extern task terminate(int delay);
endclass : ddr_sanity_seq


//==============================================================================//
// Task: MRW_cmd 		
// Description: This task perfoms MRW command transaction with various arguments 
// 	 	to configure the MRW transaction
//==============================================================================//

task ddr_sanity_seq::MRW_cmd(byte MRA, bit [7:0] OP, int delay, bit iscanceled, command_t CMD_prev, output command_t CMD);
	repeat (delay-2) begin
		start_item (item1);
			item1.CMD 		 = DES; 						//DES
		finish_item (item1);
	end

	start_item (item1);
	assert  (item1.randomize() with { 
					item1.CMD_prev 		== CMD_prev; 				
					item1.CMD 		== MRW; 				//MRW
					item1.MRA		== local::MRA;				
					item1.OP		== local::OP;
					item1.command_cancel	== local::iscanceled;
					}) 
	else	`uvm_fatal("DFI_Sanity", "MRW randomization failed");
	CMD = item1.CMD;
	finish_item (item1);
endtask




//==============================================================================//
// Task: read_cmd 		
// Description: This task perfoms RD command transaction with various arguments 
// 	 	to configure the RD transaction
//==============================================================================//

task ddr_sanity_seq::read_cmd(bit BL_mod, bit AP, bit C10, bit iscanceled, int delay, command_t CMD_prev, output command_t CMD);

	repeat (delay - 2) begin
		start_item (item1);
			item1.CMD 		 = DES; 						//DES
		finish_item (item1);
	end

	start_item (item1);
	assert (item1.randomize() with { 
					item1.CMD_prev 		== CMD_prev;
					item1.CMD 		== RD; 					//Read
					item1.BL_mod		== local::BL_mod;
					item1.AP		== local::AP;
					item1.C10		== local::C10;
					item1.command_cancel	== local::iscanceled;
					})
	else	`uvm_fatal("DFI_Sanity", "RD randomization failed");
	CMD = item1.CMD;
	finish_item (item1);
endtask




//==============================================================================//
// Task: MRR_cmd 		
// Description: This task perfoms MRR command transaction with various arguments 
// 	 	to configure the MRR transaction
//==============================================================================//

task ddr_sanity_seq::MRR_cmd(byte MRA, int delay, bit iscanceled, command_t CMD_prev, output command_t CMD);

	repeat (delay - 2) begin
		start_item (item1);
			item1.CMD 		 = DES; 						//DES
		finish_item (item1);
	end


	start_item (item1);
	assert (item1.randomize() with { 
					item1.CMD_prev 		== CMD_prev;
					item1.CMD 		== MRR; 				//MRR
					item1.MRA		== local::MRA;
					item1.command_cancel		== local::iscanceled;
					})
	else	`uvm_fatal("DFI_Sanity", "MRR randomization failed");
	CMD = item1.CMD;
	finish_item (item1);

endtask






//==============================================================================//
// Task: ACT_cmd 		
// Description: This task perfoms ACT command transaction with various arguments 
// 	 	to configure the ACT transaction
//==============================================================================//

task ddr_sanity_seq::ACT_cmd(bit iscanceled, int delay, command_t CMD_prev, output command_t CMD);

	repeat (delay - 2) begin
		start_item (item1);
			item1.CMD 		 = DES; 						//DES
		finish_item (item1);
	end

	start_item (item1);
	assert (item1.randomize() with { 
					item1.CMD_prev 		== CMD_prev;
					item1.CMD 		== ACT; 				//ACT
					item1.command_cancel	== local::iscanceled;
					}) 
	else	`uvm_fatal("DFI_Sanity", "ACT randomization failed");
	CMD = item1.CMD;
	finish_item (item1);
endtask





//==============================================================================//
// Task: PREab_cmd 		
// Description: This task perfoms PREab command transaction with various arguments 
// 	 	to configure the PREab transaction
//==============================================================================//

task ddr_sanity_seq::PREab_cmd(bit AP, int delay, command_t CMD_prev, output command_t CMD);

	repeat (delay - 2) begin
		start_item (item1);
			item1.CMD 		 = DES; 						//DES
		finish_item (item1);
	end


	start_item (item1);
		assert (item1.randomize() with { 
						item1.AP		== local::AP;
						item1.CMD_prev 		== CMD_prev;
						item1.CMD 		== PREab; 			//PREab
						})
		else	`uvm_fatal("DFI_Sanity", "PREab randomization failed");
		CMD = item1.CMD;
	finish_item (item1);
endtask




//==============================================================================//
// Task: PREab_cmd 		
// Description: This task perfoms terminates the TB
//==============================================================================//

task ddr_sanity_seq::terminate(int delay);

	repeat (delay) begin
		start_item (item1);
			item1.CMD 		 = DES; 						//DES
		finish_item (item1);
	end

	start_item (item1);
		item1.termination_flag	= 	1;
	finish_item (item1);
endtask