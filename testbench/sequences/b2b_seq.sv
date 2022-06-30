/***************************** b2b Sequence Description ****************************

Class		: 	b2b_seq
Description	:	This sequence performs a b2b read/MRR commands with all
			combinations of pre/post/interamble 

************************************************************************************/

class b2b_seq extends base_seq;

	function new(string name="b2b_seq");
	super.new(name);
	endfunction

	`uvm_object_utils(b2b_seq)
	
	ddr_sequence_item item1;
	command_t CMD = MRW;
	

	task pre_body();
		item1 = ddr_sequence_item::type_id::create ("item1");
	endtask

	task body();

		MRW_cmd(.MRA(8'h00), .OP(8'b0_00000_00), .delay(8), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));		//Set CAS LATENCY, BL = 16

		for (bit [1:0] post=0; post<=1; ++post) begin
			for (bit [5:0] pre=0; pre<=4; ++pre) begin
				for (int delay=0; delay<7; ++delay) begin
					MRW_cmd(.MRA(8'h08), .OP({post,pre}), .delay(24), .iscanceled(0), .CMD_prev(CMD), .CMD(CMD));	//Set Read Preamble		

					ACT_cmd(.iscanceled(0), .delay(8), .CMD_prev(CMD), .CMD(CMD));

					read_cmd(.BL_mod(0), .AP(1), .C10(1), .iscanceled(0), .delay(8), .CMD_prev(CMD), .CMD(CMD));	//Activate BL_mode in MR0, deactivate AP
					
					read_cmd(.BL_mod(0), .AP(1), .C10(1), .iscanceled(0), .delay(8+delay), .CMD_prev(CMD), .CMD(CMD));	//Activate BL_mode in MR0, deactivate AP

					PREab_cmd(.AP(1), .delay(12), .CMD_prev(CMD), .CMD(CMD));
				end
			end
		end
		
		terminate(.delay(8));				//Send termination flag to dram_resp_seq after some delay

	endtask

	extern task MRW_cmd(byte MRA, bit [7:0] OP, int delay, bit iscanceled, command_t CMD_prev, output command_t CMD);
	extern task read_cmd(bit BL_mod, bit AP, bit C10, bit iscanceled, int delay, command_t CMD_prev, output command_t CMD);
	extern task PREab_cmd(bit AP, int delay, command_t CMD_prev, output command_t CMD);
	extern task ACT_cmd(bit iscanceled, int delay, command_t CMD_prev, output command_t CMD);
	extern task MRR_cmd(byte MRA, int delay, bit iscanceled, command_t CMD_prev, output command_t CMD);
	extern task terminate(int delay);
endclass : b2b_seq



task b2b_seq::MRW_cmd(byte MRA, bit [7:0] OP, int delay, bit iscanceled, command_t CMD_prev, output command_t CMD);
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

task b2b_seq::read_cmd(bit BL_mod, bit AP, bit C10, bit iscanceled, int delay, command_t CMD_prev, output command_t CMD);

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

task b2b_seq::MRR_cmd(byte MRA, int delay, bit iscanceled, command_t CMD_prev, output command_t CMD);

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

task b2b_seq::ACT_cmd(bit iscanceled, int delay, command_t CMD_prev, output command_t CMD);

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

task b2b_seq::PREab_cmd(bit AP, int delay, command_t CMD_prev, output command_t CMD);

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


task b2b_seq::terminate(int delay);

	repeat (delay) begin
		start_item (item1);
			item1.CMD 		 = DES; 						//DES
		finish_item (item1);
	end

	start_item (item1);
		item1.termination_flag	= 	1;
	finish_item (item1);
endtask