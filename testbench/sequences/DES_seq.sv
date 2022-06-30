/***************************** DES_seq Description ****************************

Class		: 	DES_seq
Description	:	This sequence performs a random DES_seq command

************************************************************************************/

class DES_seq extends base_seq;
	function new(string name="DES_seq");
	super.new(name);
	endfunction

	`uvm_object_utils(DES_seq)

	ddr_sequence_item item1;

	
	task pre_body();
		item1 = ddr_sequence_item::type_id::create ("item1");
	endtask

	task body();
		repeat (4) begin
			start_item (item1);
				item1.CMD = DES; 			//DES
			finish_item (item1);
		end

		start_item (item1);
			item1.termination_flag = 1;
		finish_item (item1);
	endtask

endclass
