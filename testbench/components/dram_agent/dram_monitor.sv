	typedef mailbox #(bit [4:0]) RD_and_MRR_CMD_mbx;    	// Stores the RD and MRR CMD (commands that sends data on the DQ)
								// (To specify the burst length and MMR encoding required)
	typedef mailbox #(bit) BL_mod_mbx;                  	// Stores BL_mod corresponding to the Read CMD.
								// (the size of this mailbox = # of RD CMDs in RD_and_MRR_CMD_mbx)
	typedef mailbox #(int) clock_cycles_between_RD_mbx;     // Stores the number of cycles between each two consecutive RD commands.
	typedef mailbox #(int) clock_cycles_between_MRR_mbx;     // Stores the number of cycles between each two consecutive MRR commands.
	
	class dram_monitor extends  uvm_monitor;
	`uvm_component_utils(dram_monitor)
	
	parameter device_width = 4;

	virtual jedec_intf			jedec_monitor_vif;
	ddr_sequence_item			jedec_seq_item_1;
	ddr_sequence_item			jedec_seq_item_2;
	uvm_analysis_port#(ddr_sequence_item)	dram_analysis_port;
	//==========================================================================//
	//                      Mode Register Variables                             //
	//==========================================================================//
	static  bit 		 [2:0]	                read_pre_amble 	= 3'b000;
	static  bit 	        	                read_post_amble = 0;
	static  byte	                           	RL 		= 8'd22;
	static  burst_length_t     			burst_length 	= BL16;
	static  burst_length_t     			actual_burst_length;
	
	//==========================================================================//
	//                    mailboxes to specify the Burst Length                 //
	//==========================================================================//
	RD_and_MRR_CMD_mbx                          RD_and_MRR_CMD_mbx_inst;
	BL_mod_mbx                                  BL_mod_mbx_inst;
	//===============================================================================================//
	//        mailboxes and varialbes for the number of cycles between RD->RD or MRR->MRR            //
	//===============================================================================================//
	clock_cycles_between_RD_mbx                 clock_cycles_between_RD_mbx_inst;
	clock_cycles_between_MRR_mbx                clock_cycles_between_MRR_mbx_inst;
	static int number_of_cycles_between_RD;
	static bit first_RD_flag = 1;
	static int number_of_cycles_between_MRR;
	static bit first_MRR_flag = 1;
	static int number_of_data_cycles;

	//==========================================================================//
	//           variables to detect the postamble or interamble                //
	//==========================================================================//
	static int          number_of_cycles_between_RD_dataThread;
	static int          number_of_cycles_between_MRR_dataThread;
	static bit [4:0]    CMD_type;
	static int          RD_try_get_result = 1;
	static int          MRR_try_get_result = 1;
	static bit          preample_flag = 1;
	//==========================================================================//
	//           		    Handling Dummy Read                		    //
	//==========================================================================//
	static bit waiting_dummy_read = 0;


	function new (string name = "dram_monitor", uvm_component parent = null);
		super.new(name,parent);
	endfunction : new

	//==========================================================================//
	//                          Build Phase                                     //
	//==========================================================================//
	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual jedec_intf)::get(this,"","jedec_vif",jedec_monitor_vif))
		`uvm_fatal(get_full_name(),"Error in getting jedec_vif from database!")
		jedec_seq_item_1                  = ddr_sequence_item::type_id::create("jedec_seq_item_1");
		jedec_seq_item_2                  = ddr_sequence_item::type_id::create("jedec_seq_item_2");
		RD_and_MRR_CMD_mbx_inst           = new();
		BL_mod_mbx_inst                   = new();
		clock_cycles_between_RD_mbx_inst  = new();
		clock_cycles_between_MRR_mbx_inst = new();
		dram_analysis_port      = new("dram_analysis_port",this);
		set_db(jedec_seq_item_1);
		`uvm_info("Build_Phase", "*************** 'dram_monitor' Build Phase ***************", UVM_HIGH)
	endfunction : build_phase

	//==========================================================================//
	//                        Connect Phase                                     //
	//==========================================================================//
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		`uvm_info("Connect_phase", "*************** 'dram_monitor' Connect Phase ***************", UVM_HIGH)
	endfunction : connect_phase

	//==========================================================================//
	//                            Run Phase                                     //
	//==========================================================================//
	task run_phase(uvm_phase phase);
		super.run_phase(phase);

		fork begin
		forever begin
			monitor_data();
			phase.raise_objection(this);
			`uvm_info("D_Monitor_data", $sformatf("data_array = %p, at %t", jedec_seq_item_2.jedec_rddata_queue ,$time), UVM_DEBUG)
			dram_analysis_port.write(jedec_seq_item_2);
			phase.drop_objection(this);
		end
		end
		begin 
		forever begin
			monitor_cmd();
			if(jedec_seq_item_1.CMD!=DES) begin
				phase.raise_objection(this);
					dram_analysis_port.write(jedec_seq_item_1);
					set_db(jedec_seq_item_1);//Set MR Abstraction into DB to top level
					`uvm_info("D_Monitor_cmd", $sformatf("cmd = %p, cancelled: %b,row= %p, CID= %p  ,at %t", jedec_seq_item_1.CMD, jedec_seq_item_1.command_cancel,jedec_seq_item_1.ROW,jedec_seq_item_1.CID ,$time), UVM_DEBUG)
				phase.drop_objection(this);
			end
		end
		end
		join
	endtask : run_phase
	//==========================================================================//
	//                 dram_monitor Tasks & Functions Prototype                 //
	//==========================================================================// 
	extern task monitor_data();
	extern task monitor_cmd();
	extern function void set_db(input ddr_sequence_item jedec_seq_item_1);

endclass : dram_monitor

	//==============================================================================//
	//				Dram Monitor Tasks		                                		//
	//==============================================================================//

task dram_monitor::monitor_cmd();
	jedec_seq_item_1.is_data_only = 0;
	jedec_seq_item_1.command_cancel=0;
	@(jedec_monitor_vif.cb_J) //first clock
	number_of_cycles_between_MRR ++;
	number_of_cycles_between_RD ++;

	if (jedec_monitor_vif.cb_J.CS_DA_o===0 && jedec_monitor_vif.cb_J.CA_VALID_DA_o) begin //selected this chip
		casex(jedec_monitor_vif.cb_J.CA_DA_o[4:0])
		//Act:
		5'b???00: begin
			jedec_seq_item_1.CMD        = ACT;
			jedec_seq_item_1.ROW[3:0]   = jedec_monitor_vif.cb_J.CA_DA_o[5:2];
			jedec_seq_item_1.BA[1:0]    = jedec_monitor_vif.cb_J.CA_DA_o[7:6];
			jedec_seq_item_1.BG[2:0]    = jedec_monitor_vif.cb_J.CA_DA_o[10:8];
			jedec_seq_item_1.CID[2:0]   = jedec_monitor_vif.cb_J.CA_DA_o[13:11];
		end
		//MRW:
		5'b00101: begin
			jedec_seq_item_1.CMD        = MRW;
			jedec_seq_item_1.MRA[7:0]   = jedec_monitor_vif.cb_J.CA_DA_o[12:5];
		end
		//MRR:
		5'b10101: begin
			jedec_seq_item_1.CMD        = MRR;
			jedec_seq_item_1.MRA[7:0]   = jedec_monitor_vif.cb_J.CA_DA_o[12:5];
		end
		//RD:
		5'b11101: begin
			jedec_seq_item_1.CMD        = RD;
			jedec_seq_item_1.BL_mod     = jedec_monitor_vif.cb_J.CA_DA_o[5];
			jedec_seq_item_1.BA[1:0]    = jedec_monitor_vif.cb_J.CA_DA_o[7:6];
			jedec_seq_item_1.BG[2:0]    = jedec_monitor_vif.cb_J.CA_DA_o[10:8];
			jedec_seq_item_1.CID[2:0]   = jedec_monitor_vif.cb_J.CA_DA_o[13:11];
		end
		//NOP:
		5'b11111: begin
			jedec_seq_item_1.CMD        = NOP;
		end
		//precharge:
		5'b01011: begin
			jedec_seq_item_1.CMD        = PREab;
			jedec_seq_item_1.CID[2:0]   = jedec_monitor_vif.cb_J.CA_DA_o[13:11];
			jedec_seq_item_1.CID[3]     = jedec_monitor_vif.cb_J.CA_DA_o[5];
		end
		//other:
		default: begin   
			jedec_seq_item_1.CMD        = other;
		end
		endcase
		`uvm_info("dram monitor",$sformatf("Monitor says: command %s, bc: CA is   %b, CS is %b at %t",jedec_seq_item_1.CMD,jedec_monitor_vif.cb_J.CA_DA_o,jedec_monitor_vif.cb_J.CS_DA_o,$time),UVM_HIGH);
		if (jedec_monitor_vif.cb_J.CA_DA_o[1]===0) begin //two cycle commands
			@(jedec_monitor_vif.cb_J) //second clock

			number_of_cycles_between_MRR ++;
			number_of_cycles_between_RD ++;

			if (jedec_monitor_vif.cb_J.CS_DA_o===0) begin //check if canceled
				jedec_seq_item_1.command_cancel=1;
				`uvm_info("dram monitor",$sformatf("Monitor says: command cancelled, bc: CA is   %b, CS is %b at %t",jedec_monitor_vif.cb_J.CA_DA_o,jedec_monitor_vif.cb_J.CS_DA_o,$time),UVM_HIGH);
			end
			else begin //not canceled
				case (jedec_seq_item_1.CMD)
				ACT: begin
					jedec_seq_item_1.ROW[17:4]  = jedec_monitor_vif.cb_J.CA_DA_o[13:0];
					jedec_seq_item_1.CID[3]     = jedec_monitor_vif.cb_J.CA_DA_o[13];
				end
				MRW: begin
					jedec_seq_item_1.OP[7:0]    = jedec_monitor_vif.cb_J.CA_DA_o[7:0];
					jedec_seq_item_1.CW         = jedec_monitor_vif.cb_J.CA_DA_o[10];
					
					case (jedec_seq_item_1.MRA[7:0])
					8'h00:  begin
							if (!$cast(burst_length, jedec_seq_item_1.OP[1:0]))			// MR0, Burst Length
								`uvm_error("dram monitor_cmd:","Cast failed")
							RL 				= 22 + 2*jedec_seq_item_1.OP[6:2];
							jedec_seq_item_1.burst_length 	= burst_length;
							jedec_seq_item_1.RL 		= RL;
						end	
					8'h08:  begin                                                               // MR8
							read_pre_amble[2:0] 			= jedec_seq_item_1.OP[2:0]; 		        // Read Preamble Settings
							read_post_amble 			= jedec_seq_item_1.OP[6];                       // Read Postamble Settings
							jedec_seq_item_1.read_pre_amble 	= read_pre_amble;
							jedec_seq_item_1.read_post_amble 	= read_post_amble;
						end
					default: begin
						//nothing
						end
					endcase
				end
				MRR: begin
					RD_and_MRR_CMD_mbx_inst.put(5'b10101);

					if (! first_MRR_flag) begin
						jedec_seq_item_1.number_of_cycles_between_MRR = number_of_cycles_between_MRR;
						clock_cycles_between_MRR_mbx_inst.put(number_of_cycles_between_MRR);  // if this is te first read command, then do not put the cycles number in the queue because it has no meaning.
					end
					if (first_MRR_flag)      first_MRR_flag = 0;   // This flag marks the first MRR command is issued.
					number_of_cycles_between_MRR = 0;

					jedec_seq_item_1.CW         		= jedec_monitor_vif.cb_J.CA_DA_o[10];
					jedec_seq_item_1.burst_length 		= burst_length;

					jedec_seq_item_1.actual_burst_length    = BL16;

					jedec_seq_item_1.RL 			= RL;
					jedec_seq_item_1.read_pre_amble 	= read_pre_amble;
					jedec_seq_item_1.read_post_amble 	= read_post_amble;
				end
				RD: begin
					if (!waiting_dummy_read) begin 
						RD_and_MRR_CMD_mbx_inst.put(5'b11101);
						BL_mod_mbx_inst.put(jedec_seq_item_1.BL_mod);

						if (! first_RD_flag) begin
							jedec_seq_item_1.number_of_cycles_between_RD = number_of_cycles_between_RD;
							clock_cycles_between_RD_mbx_inst.put(number_of_cycles_between_RD);  // if this is te first read command, then do not put the cycles number in the queue because it has no meaning.
						end
						if (first_RD_flag)      first_RD_flag = 0;   // This flag marks the first RD command is issued.
						number_of_cycles_between_RD = 0;

						jedec_seq_item_1.Col[10:2]  		= jedec_monitor_vif.cb_J.CA_DA_o[8:0];
						jedec_seq_item_1.AP         		= jedec_monitor_vif.cb_J.CA_DA_o[10];
						jedec_seq_item_1.CID[3]     		= jedec_monitor_vif.cb_J.CA_DA_o[13];
						jedec_seq_item_1.burst_length 		= burst_length;

						jedec_seq_item_1.actual_burst_length = jedec_seq_item_1.burst_length;
						if (jedec_seq_item_1.BL_mod) jedec_seq_item_1.actual_burst_length = BL16;

						waiting_dummy_read = 0;
						if (jedec_seq_item_1.actual_burst_length == BL32) waiting_dummy_read = 1;

						jedec_seq_item_1.RL 			= RL;
						jedec_seq_item_1.read_pre_amble 	= read_pre_amble;
						jedec_seq_item_1.read_post_amble 	= read_post_amble;

					end else begin
						// in this case we are receiving the dummy read 
						// it will be considered as DES so that it is not sent to the subscriber and scoreboard
						jedec_seq_item_1.CMD        = DES;
						waiting_dummy_read = 0; // for the next cycles
					end
				end
				other: begin
					//nothing
				end
				default: begin
					//nothing
				end
				endcase
				`uvm_info("dram monitor",$sformatf("Monitor says: command %s, cycle 2, bc: CA is   %b, CS is %b at %t",jedec_seq_item_1.CMD,jedec_monitor_vif.cb_J.CA_DA_o,jedec_monitor_vif.cb_J.CS_DA_o,$time),UVM_HIGH);
			end
		end
	end
	else begin
		jedec_seq_item_1.CMD        = DES;
		`uvm_info("dram monitor",$sformatf("Monitor says DOWN: command %s, bc: CA is   %b, CS is %b at %t",jedec_seq_item_1.CMD,jedec_monitor_vif.cb_J.CA_DA_o,jedec_monitor_vif.cb_J.CS_DA_o,$time),UVM_HIGH);
	end
	
	endtask : monitor_cmd

task dram_monitor::monitor_data();

	// Commands of interest: MRR, RD. Commands not required: Act, NOP, Precharge, others
	// the data of MRW command is sent over the CA pins 
	
	bit preamble_pattern [];
	bit BL_mod;
	bit overlap_flag_2tCK;
	bit overlap_flag_3tCK;
	bit overlap_flag_4tCK;

        // Setting the "data only" flag to 1 to signify a transaction carrying read/mrr data (not a command)
	jedec_seq_item_2.is_data_only = 1;
	
        // Empty the jedec_rddata_queue from the data of the previous cycle
	jedec_seq_item_2.jedec_rddata_queue.delete();    
	
	//`uvm_info("", $sformatf("before preamble at %t", $time), UVM_DEBUG)

	if (preample_flag) begin
		//`uvm_info("", $sformatf("after preamble at %t", $time), UVM_DEBUG)

		//==========================================================================//
		//                    detecting the preamble pattern                        //
		//==========================================================================//
		// assuming that the DQS is zero unless there is preamble, interamble, or postamble.
		overlap_flag_2tCK = 0;
		overlap_flag_3tCK = 0;
		overlap_flag_4tCK = 0;
		forever begin
		@(posedge jedec_monitor_vif.dfi_phy_clk);       
		case (read_pre_amble[2:0])      // specify the preample pattern
			3'b000: begin               // 10 Pattern - in the jedec, this pattern takes 1 tCK, but the design changes DQS
						//  in the positive edge of the clock only, so it takes 2 tCK
				`uvm_info("Preample detection", $sformatf("DQS: %b , at %t",  jedec_monitor_vif.DQS_AD_i,$time), UVM_DEBUG)
				if ( jedec_monitor_vif.DQS_AD_i !== 1) continue;
				@(posedge jedec_monitor_vif.dfi_phy_clk);
				`uvm_info("Preample detection", $sformatf("DQS: %b , at %t",  jedec_monitor_vif.DQS_AD_i,$time), UVM_DEBUG)
				if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
				`uvm_info("Preample detection", $sformatf("DQS: %b , at %t",  jedec_monitor_vif.DQS_AD_i,$time), UVM_DEBUG)
				break;
				end
			3'b001: begin               // 0010 Pattern - in the jedec, this pattern takes 2 tCK, but the design changes DQS
						//  in the positive edge of the clock only, so it takes 4 tCK  
				if (overlap_flag_2tCK === 0) begin
					if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
					@(posedge jedec_monitor_vif.dfi_phy_clk);
					if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
					@(posedge jedec_monitor_vif.dfi_phy_clk);
				end
				if (jedec_monitor_vif.DQS_AD_i !== 1) begin
					overlap_flag_2tCK = 1;
					continue;
				end
				@(posedge jedec_monitor_vif.dfi_phy_clk);
				if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
				break;
				end
			3'b010: begin               // 1110 Pattern - in the jedec, this pattern takes 2 tCK, but the design changes DQS
						//  in the positive edge of the clock only, so it takes 4 tCK
				`uvm_info("Preample detection", $sformatf("DQS: %b , at %t",  jedec_monitor_vif.DQS_AD_i,$time), UVM_DEBUG)
				if (jedec_monitor_vif.DQS_AD_i !== 1) continue;
				`uvm_info("Preample detection", $sformatf("Pattern detected: 1, at %t" ,$time), UVM_DEBUG)
				@(posedge jedec_monitor_vif.dfi_phy_clk);
				if (jedec_monitor_vif.DQS_AD_i !== 1) continue;
				`uvm_info("Preample detection", $sformatf("Pattern detected: 1, at %t" ,$time), UVM_DEBUG)
				@(posedge jedec_monitor_vif.dfi_phy_clk);
				if (jedec_monitor_vif.DQS_AD_i !== 1) continue;
				`uvm_info("Preample detection", $sformatf("Pattern detected: 1, at %t" ,$time), UVM_DEBUG)
				@(posedge jedec_monitor_vif.dfi_phy_clk);
				if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
				`uvm_info("Preample detection", $sformatf("Pattern detected: 0, at %t" ,$time), UVM_DEBUG)
				`uvm_info("Preample detection", $sformatf("Pattern detected, at %t" ,$time), UVM_DEBUG)
				break;
				end
			3'b011: begin               // 000010 Pattern - in the jedec, this pattern takes 3 tCK, but the design changes DQS
						//  in the positive edge of the clock only, so it takes 6 tCK
				if (overlap_flag_3tCK === 0) begin 
					if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
					@(posedge jedec_monitor_vif.dfi_phy_clk);
					if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
					@(posedge jedec_monitor_vif.dfi_phy_clk);
					if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
					@(posedge jedec_monitor_vif.dfi_phy_clk);
					if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
					@(posedge jedec_monitor_vif.dfi_phy_clk);
				end
				if (jedec_monitor_vif.DQS_AD_i !== 1) begin 
					overlap_flag_3tCK = 1;
					continue;
				end
				@(posedge jedec_monitor_vif.dfi_phy_clk);
				if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
				break;
				end
			3'b100: begin               // 00001010 Pattern - in the jedec, this pattern takes 4 tCK, but the design changes DQS
						//  in the positive edge of the clock only, so it takes 8 tCK
				if (overlap_flag_4tCK === 0) begin
					if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
					@(posedge jedec_monitor_vif.dfi_phy_clk);
					if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
					@(posedge jedec_monitor_vif.dfi_phy_clk);
					if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
					@(posedge jedec_monitor_vif.dfi_phy_clk);
					if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
					@(posedge jedec_monitor_vif.dfi_phy_clk);
				end
				if (jedec_monitor_vif.DQS_AD_i !== 1) begin 
					overlap_flag_4tCK = 1;
					continue;
				end
				@(posedge jedec_monitor_vif.dfi_phy_clk);
				if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
				@(posedge jedec_monitor_vif.dfi_phy_clk);
				if (jedec_monitor_vif.DQS_AD_i !== 1) continue;
				@(posedge jedec_monitor_vif.dfi_phy_clk);
				if (jedec_monitor_vif.DQS_AD_i !== 0) continue;
				break;
				end
			default: begin
				
				end
		endcase
		end
		`uvm_info("", $sformatf("after case at %t", $time), UVM_DEBUG)
		@(posedge jedec_monitor_vif.dfi_phy_clk);
		
	end else begin
		if (CMD_type == 5'b11101) begin                             // RD command
		repeat(number_of_cycles_between_RD_dataThread-number_of_data_cycles)  @(posedge jedec_monitor_vif.dfi_phy_clk);
		end else if (CMD_type == 5'b10101) begin                    // MRR command 
		repeat(number_of_cycles_between_MRR_dataThread-number_of_data_cycles)  @(posedge jedec_monitor_vif.dfi_phy_clk);
		end
	end
	`uvm_info("ID1", $sformatf("before determine burst length at %t", $time), UVM_DEBUG)
	//==========================================================================//
	//                    Determine The Burst Length                            //
	//==========================================================================//    
	RD_and_MRR_CMD_mbx_inst.get(CMD_type);          // get command type (RD = 5'b11101 or MRR = 5'b10101)
							// blocking because if the preample patteren was detected, then surely, there is RD or MRR command.
	`uvm_info("ID2", $sformatf("CMD_type %b at %t", CMD_type,$time), UVM_DEBUG)
	
	actual_burst_length = burst_length; 		// the burst length is the value specified in corresonding mode register.
	// unless specified otherwise in the following conditions:
	if (CMD_type == 5'b11101) begin                 // if RD command, get BL_mod
							// if (BL_mod == 1),  actual_burst_length = default Burst Length 16 mode
		BL_mod_mbx_inst.get(BL_mod);
		if (BL_mod) actual_burst_length = BL16;
	end
	
	if (CMD_type == 5'b10101) actual_burst_length = BL16; // if (CMD_type == MRR), actual_burst_length = Burst Length 16 mode
	
	jedec_seq_item_2.actual_burst_length 	= actual_burst_length;
	//==========================================================================//
	//                    collecting the data                                   //
	//==========================================================================//
	`uvm_info("ID3", $sformatf("actual_burst_length %b at %t", actual_burst_length,$time), UVM_DEBUG)
	case (actual_burst_length)
		BL16: 		number_of_data_cycles = 8;      // BL16: 8 Clock cycles
		BC8_OTF: 	number_of_data_cycles = 4;      // BC8 OTF: 4 Clock cycles
		BL32: 		number_of_data_cycles = 16;      // BL32: 16 Clock cycles
	endcase
	`uvm_info("ID4", $sformatf("number_of_data_cycles %d at %t", number_of_data_cycles,$time), UVM_DEBUG)
	jedec_seq_item_2.jedec_rddata_queue.push_back(jedec_monitor_vif.DQ_AD_i);
	`uvm_info("ID5", $sformatf("data_array = %p, at %t", jedec_seq_item_2.jedec_rddata_queue ,$time), UVM_DEBUG)
	repeat(number_of_data_cycles - 1) begin 
		@(posedge jedec_monitor_vif.dfi_phy_clk);
		jedec_seq_item_2.jedec_rddata_queue.push_back(jedec_monitor_vif.DQ_AD_i);
		`uvm_info("ID6", $sformatf("data_array = %p, at %t", jedec_seq_item_2.jedec_rddata_queue ,$time), UVM_DEBUG)
	end
	
	// if (CMD_type == MRR), the DQ data are encoded according to Table 14, Section 3.4.1 in the JEDEC.
	// the monitor decodes this data to send the correct OP.
	if (CMD_type == 5'b10101) begin
		for (int i = 4; i < 8; i++) begin       // burst length is always BL16 for MRR
		jedec_seq_item_2.OP[2*(i-4)] = jedec_seq_item_2.jedec_rddata_queue[i][2*device_width-1];
		jedec_seq_item_2.OP[2*(i-4) + 1] = jedec_seq_item_2.jedec_rddata_queue[i][device_width-1];
		end
	end
		@(posedge jedec_monitor_vif.dfi_phy_clk);
	`uvm_info("ID7", $sformatf("data_array = %p, at %t", jedec_seq_item_2.jedec_rddata_queue ,$time), UVM_DEBUG)

	//==========================================================================//
		//                    Setting Flags for Next Cycle                          //
		//==========================================================================//
	if (CMD_type == 5'b11101) begin      
		if (RD_try_get_result == 0)   // Edge Case: will be used after the first RD. This is the result from the previous RD command
		clock_cycles_between_RD_mbx_inst.get(number_of_cycles_between_RD_dataThread);                  // blocking because there must be at least one item in the mailbox because the previous command didn't find this element, and we are now stating the postamble of the current RD command which means that 
														// the current command came at or after the postamble of the previous RD, and we don't need it now.
														// must return non-zero value
		RD_try_get_result  = clock_cycles_between_RD_mbx_inst.try_get(number_of_cycles_between_RD_dataThread);      // non-blocking method because there could be no following RD commands at this point
														// get the number of cycles between the current RD or MRR command and the next RD or MRR, RESPECTIVELY (RD->RD or MRR->MRR), if exists.
		if (RD_try_get_result == 0) preample_flag = 1;
		else                        preample_flag = 0;
	end else if (CMD_type == 5'b10101) begin 
		if (MRR_try_get_result == 0)   // Edge Case: will be used after the first RD. This is the result from the previous RD command
		clock_cycles_between_MRR_mbx_inst.get(number_of_cycles_between_MRR_dataThread);                  // blocking because there must be at least one item in the mailbox because the previous command didn't find this element, and we are now stating the postamble of the current RD command which means that 
														// the current command came at or after the postamble of the previous RD, and we don't need it now.
														// must return non-zero value
		MRR_try_get_result = clock_cycles_between_MRR_mbx_inst.try_get(number_of_cycles_between_MRR_dataThread);      // non-blocking method because there could be no following RD commands at this point
														// get the number of cycles between the current RD or MRR command and the next RD or MRR, RESPECTIVELY (RD->RD or MRR->MRR), if exists.
		if (MRR_try_get_result == 0) preample_flag = 1;
		else                         preample_flag = 0;
	end

	endtask : monitor_data



	function void dram_monitor::set_db(input ddr_sequence_item jedec_seq_item_1);
		uvm_config_db#(byte)::set(null,"*","RL",jedec_seq_item_1.RL);	
		uvm_config_db#(burst_length_t)::set(null,"*","burst_length",jedec_seq_item_1.actual_burst_length);	
		uvm_config_db#(bit)::set(null,"*","pre_amble",jedec_seq_item_1.read_pre_amble);	
		uvm_config_db#(bit)::set(null,"*","post_amble",jedec_seq_item_1.read_post_amble);	
		uvm_config_db#(bit)::set(null,"*","CRC_enable",jedec_seq_item_1.CRC_enable);	
	endfunction
