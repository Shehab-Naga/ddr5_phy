class dram_sequencer extends  uvm_sequencer#(ddr_sequence_item);
    `uvm_component_utils(dram_sequencer)

    uvm_seq_item_pull_imp#(ddr_sequence_item,ddr_sequence_item, dram_sequencer)	dram_seq_item_imp;

    
    function new (string name = "dram_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction 

    //==========================================================================//
    //                          Build Phase                                     //
    //==========================================================================//
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        dram_seq_item_imp = new("dram_seq_item_imp",this);
	`uvm_info("Build_Phase", "*************** 'dram_sequencer' Build Phase ***************", UVM_HIGH)
    endfunction 

    //==========================================================================//
    //                        Connect Phase                                     //
    //==========================================================================//
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
	`uvm_info("Connect_phase", "*************** 'dram_sequencer' Connect Phase ***************", UVM_HIGH)
    endfunction

    //==========================================================================//
    //                            Run Phase                                     //
    //==========================================================================//
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask 
endclass : dram_sequencer