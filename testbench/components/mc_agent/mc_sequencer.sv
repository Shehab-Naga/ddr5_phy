class mc_sequencer extends  uvm_sequencer#(ddr_sequence_item);
    `uvm_component_utils(mc_sequencer)

    uvm_seq_item_pull_imp#(ddr_sequence_item,ddr_sequence_item, mc_sequencer)	mc_seq_item_imp;


    function new (string name = "mc_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction 

    //==========================================================================//
    //                          Build Phase                                     //
    //==========================================================================//
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        mc_seq_item_imp = new("mc_seq_item_imp",this);
	`uvm_info("Build_Phase", "*************** 'mc_sequencer' Build Phase ***************", UVM_HIGH)
    endfunction 

    //==========================================================================//
    //                        Connect Phase                                     //
    //==========================================================================//
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
	`uvm_info("Connect_phase", "*************** 'mc_sequencer' Connect Phase ***************", UVM_HIGH)
    endfunction

    //==========================================================================//
    //                            Run Phase                                     //
    //==========================================================================//
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask 
endclass : mc_sequencer