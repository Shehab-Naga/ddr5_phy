/***************************** RD_seq Description ****************************

Class		: 	RD_seq
Description	:	This sequence performs a random RD_seq command

************************************************************************************/

class RD_seq extends base_seq;
	function new(string name="RD_seq");
	super.new(name);
	endfunction

	`uvm_object_utils(RD_seq)

	ddr_sequence_item des_item, next_item;
	burst_length_t 	burst_length;
	
	task pre_body();
		des_item = ddr_sequence_item::type_id::create ("des_item");
		next_item = ddr_sequence_item::type_id::create ("next_item");
		assert (next_item.randomize() with { 
						next_item.CMD_prev	== local::CMD_prev; 
						next_item.max_tCCD	== local::max_tCCD; 
						next_item.CMD 		== RD; 		//RD
						}) 
		else	`uvm_fatal("RD_seq", "RD Seq randomization failed");
	endtask

	task body();

		`uvm_info("RD_seq", $sformatf("This CMD = %p, CMD_prev = %p, tCCD = %p, %t",next_item.CMD, next_item.CMD_prev, next_item.tCCD, $time),UVM_MEDIUM);

		repeat (next_item.tCCD - 2) begin	//(tCCD - 2) is the nummber of actuad DES bet CMDs to account for true tCCD bet. CMDs
			start_item (des_item);
				des_item.CMD = DES;
			finish_item (des_item);
		end

		
		

		if ((burst_length == BL32) && (next_item.BL_mod == 0)) begin
			$display("jbbuh");
			start_item (next_item);
				next_item.AP = 1;
				next_item.C10 = 1;
			finish_item (next_item);


			repeat (6) begin			//tCCD = 8 exactly
				start_item (des_item);
					des_item.CMD = DES;
				finish_item (des_item);
			end

			//Dummy read (identical to the first read except for AP & C10)
			start_item (next_item);
				next_item.C10 = 0;		//C10 should be opposite to 1st cycle
				next_item.command_cancel = 0;		//CMD cancel should not be asserted for dummy read
				next_item.rand_mode(0);
				next_item.AP.rand_mode(1);	//Randomize AP of second cycle
				assert (next_item.randomize)	else	`uvm_fatal("RD_seq", "Dummy read randomization failed");
			finish_item (next_item);
		end

		else begin					//IF not BL32 
			start_item (next_item);
			finish_item (next_item);
		end

	endtask

endclass
