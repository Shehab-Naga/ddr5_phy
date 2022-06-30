/***************************** RD_seq_corners Description ****************************

Class		: 	RD_seq_corners
Description	:	This sequence performs a random RD_seq_corners command

************************************************************************************/

class RD_seq_corners extends base_seq;
	function new(string name="RD_seq_corners");
	super.new(name);
	endfunction

	`uvm_object_utils(RD_seq_corners)

	ddr_sequence_item des_item, next_item;

	
	task pre_body();
		des_item = ddr_sequence_item::type_id::create ("des_item");
		next_item = ddr_sequence_item::type_id::create ("next_item");
		assert (next_item.randomize() with { 
						next_item.CMD_prev	== local::CMD_prev; 
						next_item.max_tCCD	== local::max_tCCD; 
						next_item.CMD 		== RD; 		//RD
						next_item.rddata_en	== 1;
						next_item.ROW			inside {2**18-1,0};
						next_item.Col			inside {2**9-1,0};
						}) 
		else	`uvm_fatal("RD_seq_corners", "RD Seq randomization failed");
	endtask

	task body();

		`uvm_info("RD_seq_corners", $sformatf("This CMD = %p, CMD_prev = %p, tCCD = %p, %t",next_item.CMD, next_item.CMD_prev, next_item.tCCD, $time),UVM_MEDIUM);

		repeat (next_item.tCCD - 2) begin	//(tCCD - 2) is the nummber of actuad DES bet CMDs to account for true tCCD bet. CMDs
			start_item (des_item);
				des_item.CMD = DES;
			finish_item (des_item);
		end

		
		start_item (next_item);
		finish_item (next_item);
	endtask

endclass
