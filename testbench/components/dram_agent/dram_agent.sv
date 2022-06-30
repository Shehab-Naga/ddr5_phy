class dram_agent extends uvm_agent;
    `uvm_component_utils(dram_agent)
    
    dram_driver 	dram_driver1;
    dram_monitor 	dram_monitor1;
    dram_sequencer 	dram_sequencer1;

    //uvm_analysis_port for broadcasting to subscriber and scoreboard
    uvm_analysis_port#(ddr_sequence_item)	dram_analysis_port;   


    function new (string name = "dram_agent", uvm_component parent = null);
        super.new(name,parent);
    endfunction 

    //==========================================================================//
    //                          Build Phase                                     //
    //==========================================================================//
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        dram_driver1 		= dram_driver::type_id::create("dram_driver1",this);
        dram_monitor1 		= dram_monitor::type_id::create("dram_monitor1",this);
        dram_sequencer1 	= dram_sequencer::type_id::create("dram_sequencer1",this);
        dram_analysis_port 	= new("dram_analysis_port",this);
	`uvm_info("Build_Phase", "*************** 'dram_agent' Build Phase ***************", UVM_HIGH)
    endfunction 

    //==========================================================================//
    //                        Connect Phase                                     //
    //==========================================================================//
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        //Connect driver port to sequencer imp/export
        dram_driver1.seq_item_port.connect(dram_sequencer1.dram_seq_item_imp);
        //Connect monitor analysis port to agent analysis port
        dram_monitor1.dram_analysis_port.connect(dram_analysis_port);  
	`uvm_info("Connect_phase", "*************** 'dram_agent' Connect Phase ***************", UVM_HIGH)          
    endfunction

    //==========================================================================//
    //                            Run Phase                                     //
    //==========================================================================//
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask
endclass : dram_agent