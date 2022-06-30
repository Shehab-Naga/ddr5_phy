class base_test extends uvm_test;
	`uvm_component_utils(base_test)

	env 			env1;
	base_seq		base_seq_inst;
	reset_seq		reset_seq_inst;
	virtual dfi_intf 	test_dfi_vif;
	virtual jedec_intf 	test_jedec_vif;
	virtual dfi_intf 	env_dfi_vif;
	virtual jedec_intf 	env_jedec_vif;

	function new (string name = "base_test", uvm_component parent = null);
		super.new(name,parent);
	endfunction 

	//==========================================================================//
	//                          Build Phase                                     //
	//==========================================================================//
	virtual function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual dfi_intf)::get(this,"","dfi_vif",test_dfi_vif))
		`uvm_fatal(get_full_name(),"Error in getting dfi_vif from database!")
		if(!uvm_config_db#(virtual jedec_intf)::get(this,"","jedec_vif",test_jedec_vif))
		`uvm_fatal(get_full_name(),"Error in getting jedec_vif from database!")

		env_dfi_vif     = test_dfi_vif;
		env_jedec_vif   = test_jedec_vif;
		env1 = env::type_id::create("env1",this);
		uvm_config_db#(virtual dfi_intf)::set(this,"env1","dfi_vif",env_dfi_vif);
		uvm_config_db#(virtual jedec_intf)::set(this,"env1","jedec_vif",env_jedec_vif);
		
		`uvm_info("Build_Phase", "*************** 'base_test' Build Phase ***************", UVM_HIGH)
	endfunction 

	//==========================================================================//
	//                        Connect Phase                                     //
	//==========================================================================//
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		`uvm_info("Connect_phase", "*************** 'base_test' Connect Phase ***************", UVM_HIGH)
	endfunction

	//==========================================================================//
	//                      End of Elaboration Phase                            //
	//==========================================================================//
	virtual function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
		uvm_top.print_topology();
		`uvm_info("End of Elaboration Phase", "*************** 'base_test' End of Elaboration Phase ***************", UVM_HIGH)
	endfunction

	//==========================================================================//
	//                            Run Phase                                     //
	//==========================================================================//
	virtual task run_phase(uvm_phase phase);
		reset_seq_inst = reset_seq::type_id::create("reset_seq_inst");
		base_seq_inst = base_seq::type_id::create("base_seq_inst");
		super.run_phase(phase);
		phase.raise_objection(this);
			reset_seq_inst.start(env1.mc_agent1.mc_sequencer1);
			base_seq_inst.start(env1.mc_agent1.mc_sequencer1);
		phase.drop_objection(this);
	endtask
endclass : base_test;
