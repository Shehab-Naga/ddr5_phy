/*********************************Sequence Description****************************
// The DFI base sequence. All children sequences inherit this behavior. It raises/drops objections in the pre/post_body.
*/
class base_seq extends uvm_sequence #(ddr_sequence_item);

	function new(string name="base_seq");
	super.new(name);
	endfunction

	`uvm_object_utils(base_seq)

	int max_tCCD = 20;

	command_t CMD_prev;

	virtual task pre_body();
	endtask

	virtual task body();
	endtask

	virtual task post_body();
	endtask

endclass : base_seq
