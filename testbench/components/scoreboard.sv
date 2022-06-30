class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)
	parameter device_width = 4;
	//==========================================================================//
	//                          Analysis imps                                   //
	//==========================================================================//
	uvm_analysis_imp_port_mc    #(ddr_sequence_item, scoreboard)      dfi_analysis_imp;    	//Connect to dfi_analysis from DUT
	uvm_analysis_imp_port_dram  #(ddr_sequence_item, scoreboard)      jedec_analysis_imp;   //Connect to jedec_analysis from DUT
	

	ddr_sequence_item jedec_item_DUT, jedec_item_REF; 
	ddr_sequence_item dfi_item_DUT, dfi_item_REF; 
	//
	ddr_sequence_item dfi_sequence_item_handle, jedec_sequence_item_handle;

	//Syncronization events
	event got_dfi_stimulus, got_dfi_response, got_jedec_stimulus, got_jedec_response;

	//==========================================================================//
	//                      Queues to fill before comparison                    //
	//==========================================================================//
	static ddr_sequence_item     jedec_stimulus_q [$]; // to store jedec data
	static ddr_sequence_item     jedec_response_q [$]; // to store jedec commands
	static ddr_sequence_item       dfi_stimulus_q [$]; // to store dfi commands
	static ddr_sequence_item       dfi_response_q [$]; // to store dfi data
	/*
	//Using queues of logic to mitigate runtime misbehaviour (different functions can't pass a queue that's inside a transaction)
 	static logic 	[2*device_width-1:0]	dfi_response_q [$][$];    
	static logic 	[2*device_width-1:0]	jedec_stimulus_q [$][$];
	*/

	//==========================================================================//
	//                          Constructor                                     //
	//==========================================================================//
	function new (string name = "scoreboard", uvm_component parent = null);
		super.new(name,parent);
	endfunction : new

	//==========================================================================//
	//                          Build Phase                                     //
	//==========================================================================//
	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		dfi_analysis_imp       = new("dfi_analysis_imp", this);
		jedec_analysis_imp     = new("jedec_analysis_imp", this);
		jedec_item_DUT  = ddr_sequence_item::type_id::create("jedec_item_DUT");
		jedec_item_REF  = ddr_sequence_item::type_id::create("jedec_item_REF");
		dfi_item_DUT    = ddr_sequence_item::type_id::create("dfi_item_DUT");
		dfi_item_REF    = ddr_sequence_item::type_id::create("dfi_item_REF");
		`uvm_info("Build_Phase", "*************** 'scoreboard' Build Phase ***************", UVM_HIGH)
	endfunction : build_phase

	//==========================================================================//
	//                        Connect Phase                                     //
	//==========================================================================//
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		`uvm_info("Connect_phase", "*************** 'scoreboard' Connect Phase ***************", UVM_HIGH)
	endfunction : connect_phase

	//==========================================================================//
	//                            Run Phase                                     //
	//==========================================================================//
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		fork
		begin
			forever begin
				fork
					@(got_jedec_stimulus);  
					@(got_dfi_response);	// MC Received read data, comes after got_jedec_stimulus.triggered
				join 
				`uvm_info(" Inside run_phase ", $sformatf("** Before calling compare_dfi() **\ndfi_response_q[0]: %s\njedec_stimulus_q[0]: %s",dfi_response_q[0].convert2string(), jedec_stimulus_q[0].convert2string() ), UVM_DEBUG);
				compare_dfi(); // to compare DATA
			end
		end
		begin
			forever begin
				@(got_dfi_stimulus);
				@(got_jedec_response); //DRAM Recieved command, comes after got_dfi_stimulus.triggered
				`uvm_info(" Inside run_phase ", $sformatf("** Before calling compare_jedec() **\njedec_response_q[0]: %s\ndfi_stimulus_q[0]: %s",jedec_response_q[0].convert2string(), dfi_stimulus_q[0].convert2string() ), UVM_DEBUG);
				compare_jedec(); // to compare commands
			end     
		end
		join
	endtask : run_phase


	//==========================================================================//
	//                            Write functions                               //
	//==========================================================================//
	function void write_port_dram (ddr_sequence_item item);
		jedec_sequence_item_handle = ddr_sequence_item::type_id::create("jedec_sequence_item_handle");
		jedec_sequence_item_handle.copy(item);
		if(jedec_sequence_item_handle.is_data_only) begin
			jedec_stimulus_q.push_back(jedec_sequence_item_handle);
			`uvm_info(" Inside write_port_dram() ", $sformatf("** Scoreboard Received JEDEC Stimulus (data) **\jedec_sequence_item_handle: %s",jedec_sequence_item_handle.convert2string()), UVM_DEBUG);
			->got_jedec_stimulus;
		end
		else begin
			jedec_response_q.push_back(jedec_sequence_item_handle);
			`uvm_info(" Inside write_port_dram() ", $sformatf("** Scoreboard Received JEDEC Response (command) **\jedec_sequence_item_handle: %s",jedec_sequence_item_handle.convert2string()), UVM_DEBUG);
			->got_jedec_response;
		end
	endfunction : write_port_dram

	function void write_port_mc (ddr_sequence_item item);
		dfi_sequence_item_handle = ddr_sequence_item::type_id::create("dfi_sequence_item_handle");
		dfi_sequence_item_handle.copy(item);
		if(dfi_sequence_item_handle.is_data_only) begin
			dfi_response_q.push_back(dfi_sequence_item_handle);
			`uvm_info(" Inside write_port_mc()", $sformatf("** Scoreboard Received DFI Response (data) **\dfi_sequence_item_handle: %s", dfi_sequence_item_handle.convert2string()), UVM_DEBUG);
			->got_dfi_response;
		end
		else begin
			dfi_stimulus_q.push_back(dfi_sequence_item_handle);
			`uvm_info(" Inside write_port_mc()", $sformatf("** Scoreboard Received DFI Stimulus (command) **\dfi_sequence_item_handle: %s",dfi_sequence_item_handle.convert2string()), UVM_DEBUG);
			->got_dfi_stimulus;
		end
	endfunction : write_port_mc
	
	
	//==========================================================================//
	//                            Comparison functions                          //
	//==========================================================================//
	function void compare_jedec();
		bit correct;
		ddr_sequence_item dfi_item; //To store the command item, then send it to REF
		dfi_item        = ddr_sequence_item::type_id::create("dfi_item");
		//Get command transction from command queue and pass it to REF model methods
		dfi_item        = dfi_stimulus_q.pop_front();
		jedec_item_REF  = process_dfi_item(dfi_item);
		//Get DUT response transction from response queue
		jedec_item_DUT  = jedec_response_q.pop_front();
		//Comparing
		correct =       (jedec_item_REF.CMD            == jedec_item_DUT.CMD      ) &
				(jedec_item_REF.BA             == jedec_item_DUT.BA       ) &
				(jedec_item_REF.BG             == jedec_item_DUT.BG       ) &
				(jedec_item_REF.CID            == jedec_item_DUT.CID      ) &
				(jedec_item_REF.ROW            == jedec_item_DUT.ROW      ) &
				(jedec_item_REF.Col            == jedec_item_DUT.Col      ) &
				(jedec_item_REF.AP             == jedec_item_DUT.AP       ) &
				(jedec_item_REF.BL_mod         == jedec_item_DUT.BL_mod   ) &
				(jedec_item_REF.MRA            == jedec_item_DUT.MRA      ) &
				(jedec_item_REF.OP             == jedec_item_DUT.OP       ) &
				(jedec_item_REF.CW             == jedec_item_DUT.CW       ) &
				(jedec_item_REF.command_cancel == jedec_item_DUT.command_cancel );
		if(correct) 
		begin
			`uvm_info("Compare_JEDEC", $sformatf("** Test: Ok! **\n\nEXPECTED: %s\nRECEIVED: %s\n", jedec_item_REF.convert2string_Compact(), jedec_item_DUT.convert2string_Compact()), UVM_LOW);
		end 
		else 
		begin
			`uvm_error("Compare_JEDEC", $sformatf("** Test: Fail! **\n\nEXPECTED: %s\nRECEIVED: %s\n", jedec_item_REF.convert2string_Compact(), jedec_item_DUT.convert2string_Compact()));
		end
	endfunction : compare_jedec

	function void compare_dfi();
		ddr_sequence_item jedec_item; //To store the response item, then send it to REF
		jedec_item      = ddr_sequence_item::type_id::create("jedec_item");
		//Get command transction from command queue and pass it to REF model methods
		jedec_item      = jedec_stimulus_q.pop_front();
		dfi_item_REF    = process_jedec_item(jedec_item);
		//Get DUT response transction from response queue
		dfi_item_DUT    = dfi_response_q.pop_front();
		//Comparing
		if(dfi_item_DUT.dfi_rddata_queue == dfi_item_REF.dfi_rddata_queue) 
		begin
			`uvm_info("Compare_DFI", $sformatf("** Test: Ok! **\n\nEXPECTED: %s\nRECEIVED: %s\n", dfi_item_REF.convert2string_Compact(), dfi_item_DUT.convert2string_Compact()), UVM_LOW);
		end 
		else 
		begin
			`uvm_error("Compare_DFI",  $sformatf("** Test: Fail! **\n\nEXPECTED: %s\nRECEIVED: %s\n", dfi_item_REF.convert2string_Compact(), dfi_item_DUT.convert2string_Compact()) );
		end
	endfunction : compare_dfi


	//==========================================================================//
	//                            REF model Functions                           //
	//==========================================================================//
	function ddr_sequence_item process_dfi_item(ddr_sequence_item dfi_item);
		ddr_sequence_item jedec_item;
		jedec_item      = ddr_sequence_item::type_id::create("jedec_item");
		case (dfi_item.CMD)
			ACT :	begin
				dfi_address_2_CA(dfi_item, jedec_item);
			end
			RD :	begin
				dfi_address_2_CA(dfi_item, jedec_item);
			end
			MRW :	begin
				dfi_address_2_CA(dfi_item, jedec_item);
			end
			MRR :	begin
				dfi_address_2_CA(dfi_item, jedec_item);
			end
			DES :	begin
				dfi_address_2_CA(dfi_item, jedec_item);
			end
			PREab:	begin
				dfi_address_2_CA(dfi_item, jedec_item);
			end
			default:	begin
				//NOTHING
			end
		endcase
		return jedec_item;
	endfunction : process_dfi_item

	function void dfi_address_2_CA(ddr_sequence_item dfi_item, ref ddr_sequence_item jedec_item);
		int tmp; //To avoid compile error
		tmp                     = int'(dfi_item.CMD);  //To avoid compile error
		assert($cast(jedec_item.CMD, dfi_item.CMD))
		else `uvm_error("REF Model: dfi_address_2_CA",$sformatf(" FAILED to Cast dfi_item.CMD to jedec_item.CMD"));
		jedec_item.BA           = dfi_item.BA;
		jedec_item.BG           = dfi_item.BG;
		jedec_item.CID          = dfi_item.CID;
		jedec_item.ROW          = dfi_item.ROW;
		jedec_item.Col          = dfi_item.Col;
		jedec_item.AP           = dfi_item.AP;
		jedec_item.BL_mod       = dfi_item.BL_mod;
		jedec_item.MRA          = dfi_item.MRA;
		jedec_item.OP           = dfi_item.OP;
		jedec_item.CW           = dfi_item.CW;
		jedec_item.command_cancel = dfi_item.command_cancel;
		jedec_item.burst_length = dfi_item.burst_length;
		jedec_item.actual_burst_length = dfi_item.actual_burst_length;
		jedec_item.RL 		= dfi_item.RL;
		jedec_item.read_pre_amble = dfi_item.read_pre_amble;
		jedec_item.read_post_amble = dfi_item.read_post_amble;
	endfunction : dfi_address_2_CA

	function ddr_sequence_item process_jedec_item(ddr_sequence_item jedec_item);
		ddr_sequence_item dfi_item;
		dfi_item = ddr_sequence_item::type_id::create("dfi_item");
		dfi_item.dfi_rddata_queue = jedec_item.jedec_rddata_queue;
		dfi_item.is_data_only     = 1;
		return dfi_item;
	endfunction : process_jedec_item
endclass : scoreboard
