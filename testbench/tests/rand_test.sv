class rand_test extends base_test;
    `uvm_component_utils(rand_test)

    rand_seq rand_seq_inst;
    dram_resp_seq resp_seq;
    DES_seq DES_seq_inst;
    int no_of_transfers;			

    function new (string name = "rand_test", uvm_component parent = null);
        super.new(name,parent);
    endfunction 

    //==========================================================================//
    //                          Build Phase                                     //
    //==========================================================================//
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        rand_seq_inst = rand_seq::type_id::create("rand_seq_inst");
        DES_seq_inst = DES_seq::type_id::create("DES_seq_inst");
        resp_seq = dram_resp_seq::type_id::create("resp_seq");
	`uvm_info("Build_Phase", "*************** 'rand_test' Build Phase ***************", UVM_HIGH)
    endfunction 

    //==========================================================================//
    //                            Run Phase                                     //
    //==========================================================================//
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
		phase.raise_objection(this);
		no_of_transfers = 300;			//use in cmd line (to do)
		rand_seq_inst.max_tCCD = 40;
		rand_seq_inst.m_sequencer = env1.mc_agent1.mc_sequencer1;

				
		fork
			begin
				repeat (no_of_transfers) begin
					assert (rand_seq_inst.randomize)
					else   `uvm_fatal("DFI_Sanity", "Sanity Seq randomization failed");
					rand_seq_inst.start(env1.mc_agent1.mc_sequencer1);
				end
				DES_seq_inst.start(env1.mc_agent1.mc_sequencer1);
			end
			resp_seq.start(env1.dram_agent1.dram_sequencer1);
		join
        	phase.drop_objection(this);
    endtask
endclass : rand_test;
