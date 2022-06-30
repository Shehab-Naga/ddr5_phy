class dram_driver extends  uvm_driver#(ddr_sequence_item);
	`uvm_component_utils(dram_driver)

	ddr_sequence_item   	jedec_seq_item_1;
	ddr_sequence_item   	dut_rsp;
	virtual jedec_intf      jedec_driver_vif;
	static bit		reset_n;
	static bit		termination_flag;
	static int 		cmd = 0;
	static int 		cmd1_flag = 0;
	static int 		cancel_flag = 0;
	static int 		clk = 0;
	command_t		CMD_tmp;

	
	function new (string name = "dram_driver", uvm_component parent = null);
		super.new(name,parent);
	endfunction 

	//==========================================================================//
	//                          Build Phase                                     //
	//==========================================================================//
	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual jedec_intf)::get(this,"","jedec_vif",jedec_driver_vif))
		`uvm_fatal(get_full_name(),"Error in getting jedec_vif from database!")
		jedec_seq_item_1 =ddr_sequence_item::type_id::create("jedec_seq_item_1");
		`uvm_info("Build_Phase", "*************** 'dram_driver' Build Phase ***************", UVM_HIGH)
	endfunction 

	//==========================================================================//
	//                        Connect Phase                                     //
	//==========================================================================//
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		`uvm_info("Connect_phase", "*************** 'dram_driver' Connect Phase ***************", UVM_HIGH)
	endfunction

	//==========================================================================//
	//                        Reset Phase                                     //
	//==========================================================================//
	task reset_phase(uvm_phase phase);
		phase.raise_objection(this);
		jedec_driver_vif.cb_J.DQS_AD_i 	<= 0;
		jedec_driver_vif.cb_J.DQ_AD_i 	<= 0;
		phase.drop_objection(this);
	endtask

	//==========================================================================//
	//                            Run Phase                                     //
	//==========================================================================//
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			seq_item_port.get_next_item(jedec_seq_item_1);
			fork
				begin
					translation();
					if (jedec_seq_item_1.CMD == MRW) begin
						fill_mode_regiser();
					end
				end
				parse_mode_regisers();
				drive(jedec_seq_item_1, dut_rsp);
			join
			if(!uvm_config_db#(bit)::get(this,"","reset_n",reset_n))
				`uvm_fatal("Dram driver","Error in getting reset_n from database!")
			if(!uvm_config_db#(bit)::get(this,"","termination_flag",termination_flag))
				`uvm_fatal(get_full_name(),"Error in getting Termination flag from database!")	
			dut_rsp.termination_flag = termination_flag;
			dut_rsp.set_id_info(jedec_seq_item_1);
			seq_item_port.item_done(dut_rsp);
		end
	endtask 



	extern task translation();
	extern task drive(input ddr_sequence_item jedec_seq_item_1, output ddr_sequence_item dut_rsp); 
	extern task fill_mode_regiser();
	extern task parse_mode_regisers();
endclass : dram_driver




//==============================================================================//
//||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||//
//==============================================================================//
//				DRAM Driver Tasks				//
//==============================================================================//
//||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||//
//==============================================================================//





//==============================================================================//
// Task: Translation 		
// Description: This task translates the pin-level activity on the JEDEC interface
//		into a higher level jedec-transaction in order to use it for the 
//		reactive response from the DRAM driver
// Disclaimer:	This task is cloned from the DRAM monitor task 
//==============================================================================//

task dram_driver::translation();							
	@(jedec_driver_vif.cb_J) //first clock
	clk = 1;
	if (cmd == 2) begin 
		clk = 2;
		cmd = 1;
	end
	cmd1_flag = 0;
	if (jedec_driver_vif.cb_J.CS_DA_o===0) begin //selected this chip
		cmd1_flag = 1;
		if (clk == 1) begin
			casex(jedec_driver_vif.cb_J.CA_DA_o[4:0])
			//Act:
			5'b???00: begin
				CMD_tmp			   = ACT;
				jedec_seq_item_1.ROW[3:0]  = jedec_driver_vif.cb_J.CA_DA_o[5:2];
				jedec_seq_item_1.BA[1:0]   = jedec_driver_vif.cb_J.CA_DA_o[7:6];
				jedec_seq_item_1.BG[2:0]   = jedec_driver_vif.cb_J.CA_DA_o[10:8];
				jedec_seq_item_1.CID[2:0]  = jedec_driver_vif.cb_J.CA_DA_o[13:11];
			end
			//MRW:
			5'b00101: begin
				CMD_tmp			   = MRW;
				jedec_seq_item_1.MRA[7:0]  =jedec_driver_vif.cb_J.CA_DA_o[12:5];
			end
			//MRR:
			5'b10101: begin
				CMD_tmp			   = MRR;
				jedec_seq_item_1.MRA[7:0]  =jedec_driver_vif.cb_J.CA_DA_o[12:5];
			end
			//RD:
			5'b11101: begin
				CMD_tmp			   =RD;
				jedec_seq_item_1.BL_mod    =jedec_driver_vif.cb_J.CA_DA_o[5];
				jedec_seq_item_1.BA[1:0]   =jedec_driver_vif.cb_J.CA_DA_o[7:6];
				jedec_seq_item_1.BG[2:0]   =jedec_driver_vif.cb_J.CA_DA_o[10:8];
				jedec_seq_item_1.CID[2:0]  =jedec_driver_vif.cb_J.CA_DA_o[13:11];
			end
			//precharge:
			5'b01011: begin
				jedec_seq_item_1.CMD	   =PREab;
				jedec_seq_item_1.BA[1:0]   =jedec_driver_vif.cb_J.CA_DA_o[7:6];
				jedec_seq_item_1.BG[2:0]   =jedec_driver_vif.cb_J.CA_DA_o[10:8];
				jedec_seq_item_1.CID[2:0]  =jedec_driver_vif.cb_J.CA_DA_o[13:11];
				jedec_seq_item_1.CID[3]    =jedec_driver_vif.cb_J.CA_DA_o[5];
			end
			//other:
			default: begin   
				CMD_tmp			   =DES;
			end
			endcase
		end
		`uvm_info("dram driver",$sformatf("driver says: command %s, bc: CA is   %b, CS is %b at %t",jedec_seq_item_1.CMD,jedec_driver_vif.cb_J.CA_DA_o,jedec_driver_vif.cb_J.CS_DA_o,$time),UVM_HIGH);
		if (jedec_driver_vif.cb_J.CA_DA_o[1]===0) begin //two cycle commands
			cmd = 2;
		end
	end
	if (clk == 2) begin
		//@(jedec_driver_vif.cb_J) //second clock
		if (jedec_driver_vif.cb_J.CS_DA_o===0) begin //check if canceled
			jedec_seq_item_1.command_cancel=1;
			cancel_flag = 1;
			`uvm_info("dram driver",$sformatf("driver says: command cancelled, bc: CA is   %b, CS is %b at %t",jedec_driver_vif.cb_J.CA_DA_o,jedec_driver_vif.cb_J.CS_DA_o,$time),UVM_HIGH);
		end
		else begin //not canceled
			if (cancel_flag) 	CMD_tmp = DES;
			case (CMD_tmp)
				ACT: begin
				jedec_seq_item_1.CMD	   = ACT;
				jedec_seq_item_1.ROW[17:4] =jedec_driver_vif.cb_J.CA_DA_o[13:0];
				jedec_seq_item_1.CID[3]    =jedec_driver_vif.cb_J.CA_DA_o[13];
				jedec_seq_item_1.command_cancel=0;
				end
				MRW: begin
				jedec_seq_item_1.CMD	   = MRW;
				jedec_seq_item_1.OP[7:0]   =jedec_driver_vif.cb_J.CA_DA_o[7:0];
				jedec_seq_item_1.CW        =jedec_driver_vif.cb_J.CA_DA_o[10];
				jedec_seq_item_1.command_cancel=0;
				end
				MRR: begin
				jedec_seq_item_1.CMD	   = MRR;
				jedec_seq_item_1.CW        =jedec_driver_vif.cb_J.CA_DA_o[10];
				jedec_seq_item_1.command_cancel=0;
				end
				RD: begin
				jedec_seq_item_1.CMD	   = RD;
				jedec_seq_item_1.Col[10:2] =jedec_driver_vif.cb_J.CA_DA_o[8:0];
				jedec_seq_item_1.AP        =jedec_driver_vif.cb_J.CA_DA_o[10];
				jedec_seq_item_1.CID[3]    =jedec_driver_vif.cb_J.CA_DA_o[13];
				jedec_seq_item_1.command_cancel=0;
				end
				other: begin
				//nothing
				end
				default: begin
				//nothing
				end
			endcase
			`uvm_info("dram driver",$sformatf("driver says: command %s, cycle 2, bc: CA is   %b, CS is %b at %t",jedec_seq_item_1.CMD,jedec_driver_vif.cb_J.CA_DA_o,jedec_driver_vif.cb_J.CS_DA_o,$time),UVM_HIGH);
		end
		CMD_tmp = DES;
	end

	else if (!cmd1_flag) begin
		jedec_seq_item_1.CMD       =DES;
		cancel_flag = 0;
	end
	if (!reset_n) begin
		jedec_seq_item_1.CMD       =DES;
	end
endtask : translation




//==============================================================================//
// Task: drive 		
// Description: This task clones jedec_seq_item_1 to dut_rsp for the reactive 
//	        stimulus purpose, then drives the DQS and DATA bus
//==============================================================================//

task dram_driver::drive(input ddr_sequence_item jedec_seq_item_1, output ddr_sequence_item dut_rsp);    
	if(!$cast(dut_rsp,jedec_seq_item_1.clone())) `uvm_fatal("DRVI", "cast to rsp_temp failed")
	dut_rsp = jedec_seq_item_1;				//Pass jedec_seq_item_1 values to rsp_temp
	

	jedec_driver_vif.cb_J.DQS_AD_i <= jedec_seq_item_1.dqs;	
	jedec_driver_vif.cb_J.DQ_AD_i <= jedec_seq_item_1.data;	
endtask 





//==============================================================================//
// Task: fill_mode_regiser 		
// Description: This task fills OP values in the mode registers when an MRW is
//		received
//==============================================================================//

task dram_driver::fill_mode_regiser();	//Create Mode registers
	jedec_seq_item_1.MR[jedec_seq_item_1.MRA]=jedec_seq_item_1.OP;
endtask





//==============================================================================//
// Task: parse_mode_regisers 		
// Description: This task parses the mode registers and obtain the configurations
//		of the DRAM like RL, BL, pre/post amble
//==============================================================================//

task dram_driver::parse_mode_regisers();	//Create Mode registers
	if (!reset_n) begin
		jedec_seq_item_1.MR[0] = 0;	//Reset Mode registers
		jedec_seq_item_1.MR[8] = 0;	//Reset Mode registers
		jedec_seq_item_1.MR[50] = 0;	//Reset Mode registers
	end
	if (jedec_seq_item_1.CMD != MRR) begin	// If BL_mod is activated (Active low) >> Get BL from MR0
		if (!jedec_seq_item_1.BL_mod)	begin	
			case (jedec_seq_item_1.MR[0][1:0]) 
				'b00	: jedec_seq_item_1.burst_length=BL16;
				'b01	: jedec_seq_item_1.burst_length=BC8_OTF;
				'b10	: jedec_seq_item_1.burst_length=BL32;
				default : jedec_seq_item_1.burst_length=BL16;
			endcase
		end
		else jedec_seq_item_1.burst_length	=	BL16;	//Default for read and MRR
	end
	else begin
		jedec_seq_item_1.burst_length	=	BL16;	//Default for read and MRR
	end
	jedec_seq_item_1.RL			=	22 + 2*jedec_seq_item_1.MR[0][6:2];
	jedec_seq_item_1.read_pre_amble		=	jedec_seq_item_1.MR[8'h8][2:0];

	jedec_seq_item_1.read_post_amble	=	jedec_seq_item_1.MR[8'h8][6];

	jedec_seq_item_1.CRC_enable		=	jedec_seq_item_1.MR[8'h32][0];		

endtask



