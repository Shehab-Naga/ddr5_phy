class ddr_sanity_test extends base_test;
	`uvm_component_utils(ddr_sanity_test)

	ddr_sanity_seq sanity_sequence;
	dram_resp_seq resp_seq;

	function new (string name = "ddr_sanity_test", uvm_component parent = null);
		super.new(name,parent);
	endfunction 

	//==========================================================================//
	//                          Build Phase                                     //
	//==========================================================================//
	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		sanity_sequence = ddr_sanity_seq::type_id::create("sanity_sequence");
		resp_seq = dram_resp_seq::type_id::create("resp_seq");
		`uvm_info("Build_Phase", "*************** 'ddr_sanity_test' Build Phase ***************", UVM_HIGH)
	endfunction 

	//==========================================================================//
	//                            Run Phase                                     //
	//==========================================================================//
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
			phase.raise_objection(this);
			fork
				sanity_sequence.start(env1.mc_agent1.mc_sequencer1);
				resp_seq.start(env1.dram_agent1.dram_sequencer1);
			join
			phase.drop_objection(this);
	endtask
endclass : ddr_sanity_test;
