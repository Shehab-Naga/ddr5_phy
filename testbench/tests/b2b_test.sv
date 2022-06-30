class b2b_test extends base_test;
	`uvm_component_utils(b2b_test)

	b2b_seq b2b_sequence;
	dram_resp_seq resp_seq;

	function new (string name = "b2b_test", uvm_component parent = null);
		super.new(name,parent);
	endfunction 

	//==========================================================================//
	//                          Build Phase                                     //
	//==========================================================================//
	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		b2b_sequence = b2b_seq::type_id::create("b2b_sequence");
		resp_seq = dram_resp_seq::type_id::create("resp_seq");
		`uvm_info("Build_Phase", "*************** 'b2b_test' Build Phase ***************", UVM_HIGH)
	endfunction 

	//==========================================================================//
	//                            Run Phase                                     //
	//==========================================================================//
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
			phase.raise_objection(this);
			fork
				b2b_sequence.start(env1.mc_agent1.mc_sequencer1);
				resp_seq.start(env1.dram_agent1.dram_sequencer1);
			join
			phase.drop_objection(this);
	endtask
endclass : b2b_test;
