/***************************** MRW_seq Description ****************************

Class		: 	MRW_seq
Description	:	This sequence performs a random MRW_seq command

************************************************************************************/

class MRW_seq extends base_seq;
	function new(string name="MRW_seq");
	super.new(name);
	endfunction

	`uvm_object_utils(MRW_seq)

	ddr_sequence_item des_item, next_item;

	task pre_body();
		des_item = ddr_sequence_item::type_id::create ("des_item");
		next_item = ddr_sequence_item::type_id::create ("next_item");
		assert (next_item.randomize() with { 
						next_item.CMD_prev	== local::CMD_prev;
						next_item.max_tCCD	== local::max_tCCD; 				
						next_item.CMD 		== MRW; 			//MRW
						}) 
		else	`uvm_fatal("MRW_seq", "MRW_Seq randomization failed");
	endtask

	task body();
	
		`uvm_info("MRW_seq", $sformatf("This CMD = %p, CMD_prev = %p, tCCD = %p, %t",next_item.CMD, next_item.CMD_prev, next_item.tCCD, $time),UVM_MEDIUM);

		repeat (next_item.tCCD - 2) begin	//(tCCD - 2) is the nummber of actuad DES bet CMDs to account for true tCCD bet. CMDs
			start_item (des_item);
				des_item.CMD = DES;
			finish_item (des_item);
		end

		
		start_item (next_item);
		finish_item (next_item);
	endtask

endclass
