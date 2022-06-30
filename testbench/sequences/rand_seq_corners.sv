/***************************** mc_sanity Sequence Description ****************************

Class		: 	rand_seq_corners
Description	:	This sequence performs a random commands at corner rows and columns

************************************************************************************/

class rand_seq_corners extends base_seq;
	function new(string name="rand_seq_corners");
	super.new(name);
	endfunction

	`uvm_object_utils(rand_seq_corners)

	mc_sequencer m_sequencer;
	
	ddr_sequence_item item1;
	RD_seq_corners	RD_seq_corners_inst ;
	MRR_seq	MRR_seq_inst;
	MRW_seq	MRW_seq_inst;
	ACT_seq_corners	ACT_seq_corners_inst;
	PREab_seq PREab_seq_inst;

	command_t	CMD_prev = MRW;
	bit 		AP_prev = 1;
	bit 		command_cancel_prev = 0;


	task pre_body();
		item1 = ddr_sequence_item::type_id::create ("item1");
		RD_seq_corners_inst  = RD_seq_corners::type_id::create  ("RD_seq_corners_inst");
		MRR_seq_inst = MRR_seq::type_id::create ("MRR_seq_inst");
		MRW_seq_inst = MRW_seq::type_id::create ("MRW_seq_inst");
		ACT_seq_corners_inst = ACT_seq_corners::type_id::create ("ACT_seq_corners_inst");
		PREab_seq_inst = PREab_seq::type_id::create ("PREab_seq_inst");
		RD_seq_corners_inst.CMD_prev  = CMD_prev;
		MRR_seq_inst.CMD_prev = CMD_prev;
		MRW_seq_inst.CMD_prev = CMD_prev;
		ACT_seq_corners_inst.CMD_prev = CMD_prev;
		PREab_seq_inst.CMD_prev = CMD_prev;
		/*RD_seq_corners_inst.AP_prev  = AP_prev;
		MRR_seq_inst.AP_prev = AP_prev;
		MRW_seq_inst.AP_prev = AP_prev;
		ACT_seq_corners_inst.AP_prev = AP_prev;
		PREab_seq_inst.AP_prev = AP_prev;
		RD_seq_corners_inst.command_cancel_prev  = command_cancel_prev;
		MRR_seq_inst.command_cancel_prev = command_cancel_prev;
		MRW_seq_inst.command_cancel_prev = command_cancel_prev;
		ACT_seq_corners_inst.command_cancel_prev = command_cancel_prev;
		PREab_seq_inst.command_cancel_prev = command_cancel_prev;*/
		RD_seq_corners_inst.max_tCCD  = max_tCCD;
		MRR_seq_inst.max_tCCD = max_tCCD;
		MRW_seq_inst.max_tCCD = max_tCCD;
		ACT_seq_corners_inst.max_tCCD = max_tCCD;
		PREab_seq_inst.max_tCCD = max_tCCD;
	endtask

	task body();

		assert (item1.randomize() with { 
						item1.CMD_prev			== local::CMD_prev; 
						item1.AP_prev			== local::AP_prev;
						item1.command_cancel_prev	== local::command_cancel_prev;
						item1.ROW			inside {2**18-1,0};
						item1.Col			inside {2**9-1,0};
						}) 
		$display("hello, row: %p, col: %p",item1.ROW,item1.Col);
		else	`uvm_fatal("Rand_seq_corners", "Rand Seq randomization failed");
		
		`uvm_info("rand_seq_corners", $sformatf("In rand, CMD_next = %p, %t", item1.CMD, $time),UVM_MEDIUM);
		case (item1.CMD)
			MRW 	: begin 
					MRW_seq_inst.start(m_sequencer);
					item1 = MRW_seq_inst.next_item;
			end
			MRR 	: begin
					MRR_seq_inst.start(m_sequencer);
					item1 = MRR_seq_inst.next_item;
			end
			ACT 	: begin
					ACT_seq_corners_inst.start(m_sequencer);
					item1 = ACT_seq_corners_inst.next_item;

			end
			RD 	: begin 
					RD_seq_corners_inst.start(m_sequencer);
					item1 = RD_seq_corners_inst.next_item;
			end
			PREab 	: begin 
					PREab_seq_inst.start(m_sequencer);
					item1 = PREab_seq_inst.next_item;
			end
			default	: MRW_seq_inst.start(m_sequencer);
		endcase
	endtask

	task post_body();
		CMD_prev = item1.CMD;
		AP_prev = item1.AP;
		command_cancel_prev = item1.command_cancel;
	endtask
	
endclass : rand_seq_corners

