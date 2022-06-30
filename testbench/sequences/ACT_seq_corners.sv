/***************************** ACT Sequence Description ****************************

Class		: 	ACT_seq_corners
Description	:	This sequence performs a ACT command

************************************************************************************/

class ACT_seq_corners extends base_seq;
	function new(string name="ACT_seq_corners");
	super.new(name);
	endfunction

	`uvm_object_utils(ACT_seq_corners)

	ddr_sequence_item des_item, next_item;

	task pre_body();
		des_item = ddr_sequence_item::type_id::create ("des_item");
		next_item = ddr_sequence_item::type_id::create ("next_item");
		assert (next_item.randomize() with { 
						next_item.CMD_prev	== local::CMD_prev;
						next_item.max_tCCD	== local::max_tCCD; 	
						next_item.CMD 		== ACT;
						next_item.ROW			inside {2**18-1,0};
						next_item.Col			inside {2**9-1,0};		//ACT
						}) 
		else	`uvm_fatal("ACT_seq_corners", "ACT_seq_corners randomization failed");
	endtask

	task body();

		`uvm_info("ACT_seq_corners", $sformatf("This CMD = %p, CMD_prev = %p, tCCD = %p, %t",next_item.CMD, CMD_prev, next_item.tCCD, $time),UVM_MEDIUM);

		repeat (next_item.tCCD - 2) begin	//(tCCD - 2) is the nummber of actuad DES bet CMDs to account for true tCCD bet. CMDs
			start_item (des_item);
				des_item.CMD = DES;
			finish_item (des_item);
		end

		start_item (next_item);
		finish_item (next_item);
	endtask
endclass
