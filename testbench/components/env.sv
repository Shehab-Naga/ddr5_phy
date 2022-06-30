class env extends uvm_env;
    `uvm_component_utils(env)

    dram_agent          dram_agent1;
    mc_agent            mc_agent1;
    scoreboard          scb1;
    subscriber          subs1;
    virtual dfi_intf    env_dfi_vif;
    virtual jedec_intf  env_jedec_vif;


    function new (string name = "env", uvm_component parent = null);
        super.new(name,parent);
    endfunction 

    //==========================================================================//
    //                          Build Phase                                     //
    //==========================================================================//
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual dfi_intf)::get(this,"","dfi_vif",env_dfi_vif))
            `uvm_fatal(get_full_name(),"Error in getting dfi_vif from database!")
	if(!uvm_config_db#(virtual jedec_intf)::get(this,"","jedec_vif",env_jedec_vif))
            `uvm_fatal(get_full_name(),"Error in getting jedec_vif from database!")
		
        mc_agent1       = mc_agent::type_id::create("mc_agent1",this);
	dram_agent1     = dram_agent::type_id::create("dram_agent1",this); 
        scb1            = scoreboard::type_id::create("scb1",this);
        subs1           = subscriber::type_id::create("subs1",this);
        `uvm_info("Build_Phase", "*************** 'env' Build Phase ***************", UVM_HIGH)
        //set virtual interfaces visible to all components below env in hirarchy
        uvm_config_db#(virtual dfi_intf)::set(this,"*","dfi_vif",env_dfi_vif);
	uvm_config_db#(virtual jedec_intf)::set(this,"*","jedec_vif",env_jedec_vif);
    endfunction 

    //==========================================================================//
    //                        Connect Phase                                     //
    //==========================================================================//
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        //*************Connect agents analysis port to subscriber and scoreboard analysis imp
        //Scoreboard
        mc_agent1.mc_analysis_port.connect(scb1.dfi_analysis_imp);
	dram_agent1.dram_analysis_port.connect(scb1.jedec_analysis_imp);
        //Subscriber
        mc_agent1.mc_analysis_port.connect(subs1.mc_analysis_imp);
        dram_agent1.dram_analysis_port.connect(subs1.dram_analysis_imp);
	`uvm_info("Connect_phase", "*************** 'env' Connect Phase ***************", UVM_HIGH)
    endfunction

    //==========================================================================//
    //                            Run Phase                                     //
    //==========================================================================//
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask
endclass : env
