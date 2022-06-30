/***************************** mc_sanity Sequence Description ****************************

Class		: 	rand_seq
Description	:	This sequence performs a random commands with constraints

************************************************************************************/

class rand_seq extends base_seq;

	function new(string name="rand_seq");
	super.new(name);
	endfunction

	`uvm_object_utils(rand_seq)

	mc_sequencer m_sequencer;
	
	ddr_sequence_item item1;
	RD_seq	RD_seq_inst ;
	MRR_seq	MRR_seq_inst;
	MRW_seq	MRW_seq_inst;
	ACT_seq	ACT_seq_inst;
	PREab_seq PREab_seq_inst;

	//Initialization
	command_t	CMD_prev = MRW;
	bit 		AP_prev = 1;
	bit 		command_cancel_prev = 0;
	burst_length_t 	burst_length;

	task pre_body();
		item1 = ddr_sequence_item::type_id::create ("item1");
		RD_seq_inst  = RD_seq::type_id::create  ("RD_seq_inst ");
		MRR_seq_inst = MRR_seq::type_id::create ("MRR_seq_inst");
		MRW_seq_inst = MRW_seq::type_id::create ("MRW_seq_inst");
		ACT_seq_inst = ACT_seq::type_id::create ("ACT_seq_inst");
		PREab_seq_inst = PREab_seq::type_id::create ("PREab_seq_inst");
		RD_seq_inst.CMD_prev  = CMD_prev;
		MRR_seq_inst.CMD_prev = CMD_prev;
		MRW_seq_inst.CMD_prev = CMD_prev;
		ACT_seq_inst.CMD_prev = CMD_prev;
		PREab_seq_inst.CMD_prev = CMD_prev;
		RD_seq_inst.max_tCCD  = max_tCCD;
		MRR_seq_inst.max_tCCD = max_tCCD;
		MRW_seq_inst.max_tCCD = max_tCCD;
		ACT_seq_inst.max_tCCD = max_tCCD;
		PREab_seq_inst.max_tCCD = max_tCCD;

		RD_seq_inst.burst_length = burst_length;
	endtask

	task body();

		assert (item1.randomize() with { 
						item1.CMD_prev			== local::CMD_prev; 
						item1.AP_prev			== local::AP_prev;
						item1.command_cancel_prev	== local::command_cancel_prev;
						}) 
		else	`uvm_fatal("Rand_seq", "Rand Seq randomization failed");
		
		`uvm_info("rand_seq", $sformatf("In rand, CMD_next = %p, %t", item1.CMD, $time),UVM_MEDIUM);
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
					ACT_seq_inst.start(m_sequencer);
					item1 = ACT_seq_inst.next_item;
			end
			RD 	: begin 
					RD_seq_inst.start(m_sequencer);
					item1 = RD_seq_inst.next_item;
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
		get_MRW_settings(item1);
	endtask
	
	extern task get_MRW_settings(input ddr_sequence_item item1);
endclass : rand_seq





task rand_seq::get_MRW_settings(input ddr_sequence_item item1);
	if (item1.CMD == MRW) begin
		case (item1.MRA)
			8'h00	: begin
					case (item1.OP[1:0]) 
						'b00	: burst_length = BL16;
						'b01	: burst_length = BC8_OTF;
						'b10	: burst_length = BL32;
						default : burst_length = BL16;
					endcase
			end
			8'h08	: begin
					item1.read_pre_amble	=	item1.OP[2:0];
					item1.read_post_amble	=	item1.OP[6];
			end
		endcase
	end
endtask