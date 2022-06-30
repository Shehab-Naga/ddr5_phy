class mc_agent extends uvm_agent;
    `uvm_component_utils(mc_agent)

    mc_driver 		mc_driver1;
    mc_monitor 		mc_monitor1;
    mc_sequencer 	mc_sequencer1;

    //uvm_analysis_port for broadcasting to subscriber and scoreboard
    uvm_analysis_port#(ddr_sequence_item)	mc_analysis_port;  


    function new (string name = "mc_agent", uvm_component parent = null);
        super.new(name,parent);
    endfunction 

    //==========================================================================//
    //                          Build Phase                                     //
    //==========================================================================//
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        mc_driver1 		= mc_driver::type_id::create("mc_driver1",this);
        mc_monitor1 		= mc_monitor::type_id::create("mc_monitor1",this);
        mc_sequencer1 		= mc_sequencer::type_id::create("mc_sequencer1",this);
        mc_analysis_port	= new("mc_analysis_port",this);
	`uvm_info("Build_Phase", "*************** 'mc_agent' Build Phase ***************", UVM_HIGH)
    endfunction 

    //==========================================================================//
    //                        Connect Phase                                     //
    //==========================================================================//
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        //Connect driver port to sequencer imp/export
        mc_driver1.seq_item_port.connect(mc_sequencer1.mc_seq_item_imp);

        //Connect monitor analysis port to agent analysis port
        mc_monitor1.mc_analysis_port.connect(mc_analysis_port);           
	`uvm_info("Connect_phase", "*************** 'mc_agent' Connect Phase ***************", UVM_HIGH) 
    endfunction

    //==========================================================================//
    //                            Run Phase                                     //
    //==========================================================================//
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask
endclass : mc_agent