/***************************** b2b Sequence Description ****************************

Class		: 	reset_seq
Description	:	This sequence performs dut reset (executed in reset phase 
			of base test)

************************************************************************************/

class reset_seq extends base_seq;

	function new(string name="reset_seq");
	super.new(name);
	endfunction

	`uvm_object_utils(reset_seq)
	
	ddr_sequence_item item1;
	command_t CMD = MRW;
	

	task pre_body();
		item1 = ddr_sequence_item::type_id::create ("item1");
	endtask

	task body();

		start_item (item1);
			item1.reset_n_i = 0; 				
			item1.en_i 	= 0; 				
		finish_item (item1);

		start_item (item1);
			item1.reset_n_i = 1; 				
			item1.en_i 	= 1; 				
		finish_item (item1);
		
	endtask

endclass : reset_seq

