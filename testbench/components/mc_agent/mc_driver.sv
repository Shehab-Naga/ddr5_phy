class mc_driver extends  uvm_driver#(ddr_sequence_item);
	`uvm_component_utils(mc_driver)
	parameter Physical_Rank_No = 1; 

	ddr_sequence_item				dfi_item1, dfi_item1_prev;
	virtual dfi_intf        			dfi_driver_vif;
	static int					n_words = 0;
	static logic [13:0]				CMD0,CMD1;
	static logic [Physical_Rank_No-1:0]		CS0,CS1;
	static logic [13:0]				CMD_queue [$];			
	static logic [Physical_Rank_No-1:0]		CS_queue [$];			
	static logic 					rddata_en_queue [$];			
        static int					start_flag = 1;
        static bit					termination_flag = 0;			//To terminate dram resp_sequence

	function new (string name = "mc_driver", uvm_component parent = null);
		super.new(name,parent);
	endfunction 
	
	//==========================================================================//
	//                          Build Phase                                     //
	//==========================================================================//
	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual dfi_intf)::get(this,"","dfi_vif",dfi_driver_vif))
		`uvm_fatal(get_full_name(),"Error in getting dfi_vif from database!")
		dfi_item1 = ddr_sequence_item::type_id::create("dfi_item1");
		dfi_item1_prev = ddr_sequence_item::type_id::create("dfi_item1_prev");
		uvm_config_db#(bit)::set(null,"uvm_test_top.env1.dram_agent1.dram_driver1","reset_n",dfi_item1.reset_n_i);	//Set reset in db
		uvm_config_db#(bit)::set(null,"uvm_test_top.env1.dram_agent1.dram_driver1","termination_flag",termination_flag);//Set termination flag = 0 in db
		//`uvm_info("Build_Phase", "*************** 'mc_driver' Build Phase ***************", UVM_HIGH)
	endfunction 

	//==========================================================================//
	//                        Connect Phase                                     //
	//==========================================================================//
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		//`uvm_info("Connect_phase", "*************** 'mc_driver' Connect Phase ***************", UVM_HIGH)
	endfunction

	//==========================================================================//
	//                        Pre-reset Phase                                   //
	//==========================================================================//
	task pre_reset_phase(uvm_phase phase);			//Set initial values
		phase.raise_objection(this);
		dfi_driver_vif.dfi_address_p0	<= 14'bz;
		dfi_driver_vif.dfi_address_p1	<= 14'bz;			
		dfi_driver_vif.dfi_address_p1	<= 14'bz;			
		dfi_driver_vif.dfi_address_p2	<= 14'bz;			
		dfi_driver_vif.dfi_address_p3	<= 14'bz;
		`ifdef ratio_1_to_1
			dfi_driver_vif.dfi_cs_p0		<= 1'b1;			
			dfi_driver_vif.dfi_cs_p1		<= 1'bz;			
			dfi_driver_vif.dfi_cs_p2		<= 1'bz;			
			dfi_driver_vif.dfi_cs_p3		<= 1'bz;			
			dfi_driver_vif.dfi_rddata_en_p0	<= 1'b0;				
			dfi_driver_vif.dfi_rddata_en_p1	<= 1'bz;				
			dfi_driver_vif.dfi_rddata_en_p2	<= 1'bz;				
			dfi_driver_vif.dfi_rddata_en_p3	<= 1'bz;
		`elsif ratio_1_to_2
			dfi_driver_vif.dfi_cs_p0		<= 1'b1;			
			dfi_driver_vif.dfi_cs_p1		<= 1'b1;			
			dfi_driver_vif.dfi_cs_p2		<= 1'bz;			
			dfi_driver_vif.dfi_cs_p3		<= 1'bz;			
			dfi_driver_vif.dfi_rddata_en_p0	<= 1'b0;				
			dfi_driver_vif.dfi_rddata_en_p1	<= 1'b0;				
			dfi_driver_vif.dfi_rddata_en_p2	<= 1'bz;				
			dfi_driver_vif.dfi_rddata_en_p3	<= 1'bz;
		`elsif ratio_1_to_4
			dfi_driver_vif.dfi_cs_p0		<= 1'b1;			
			dfi_driver_vif.dfi_cs_p1		<= 1'b1;			
			dfi_driver_vif.dfi_cs_p2		<= 1'b1;			
			dfi_driver_vif.dfi_cs_p3		<= 1'b1;			
			dfi_driver_vif.dfi_rddata_en_p0	<= 1'b0;				
			dfi_driver_vif.dfi_rddata_en_p1	<= 1'b0;				
			dfi_driver_vif.dfi_rddata_en_p2	<= 1'b0;				
			dfi_driver_vif.dfi_rddata_en_p3	<= 1'b0;		
		`endif  
		
		phase.drop_objection(this);
	endtask


	//==========================================================================//
	//                            Run Phase                                     //
	//==========================================================================//
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			seq_item_port.get_next_item(dfi_item1);
				drive_dfi();	
			seq_item_port.item_done();
		end
	endtask 


	//==========================================================================//
	//                           MC Tasks Prototype                             //
	//==========================================================================//
	extern task drive_dfi ();
	extern task num_of_words();
	extern task decode_cmd();
	extern task ACT_cmd ();		// ACT command_decoding
	extern task RD_cmd ();		// READ command_decoding
	extern task MRW_cmd ();		// MRW command_decoding
	extern task MRR_cmd ();		// MRR command_decoding
	extern task DES_cmd ();		// DES command_decoding
	extern task PREab_CMD ();	// PREab_CMD command_decoding
endclass : mc_driver




//==============================================================================//
//||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||//
//==============================================================================//
//				MC Driver Tasks				        //
//==============================================================================//
//||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||//
//==============================================================================//
 



//==============================================================================//
// Task: drive_dfi 		
// Description: This is the main task that translates transaction into pin level
//		Activity
//==============================================================================//

task mc_driver::drive_dfi ();	
	decode_cmd();
	num_of_words();

	if ((dfi_item1.CMD == DES) || (dfi_item1.CMD == PREab)) begin
		CMD_queue = {CMD_queue, CMD0};
		CS_queue = {CS_queue, CS0};
		if (rddata_en_queue.size() <  CMD_queue.size()) rddata_en_queue = {rddata_en_queue, 0};	//if !rddata_en then n_words will be 0
	end
	else begin
		CMD_queue = {CMD_queue, CMD0, CMD1};
		CS_queue = {CS_queue, CS0, CS1};
		if (rddata_en_queue.size() < CMD_queue.size()) begin
			if (rddata_en_queue[$] == 1) rddata_en_queue = {rddata_en_queue, 0};
			else rddata_en_queue = {rddata_en_queue, 0, 0};				//if !rddata_en then n_words will be 0
		end
	end

	if (n_words > 0) begin
		while (n_words > 0) begin							//If this cond is true then rddata_en = 1
			rddata_en_queue = {rddata_en_queue, 1};
			n_words = n_words - 1;
		end
	end
	if ((!dfi_item1.reset_n_i)||(!dfi_item1.en_i)) begin
		dfi_driver_vif.en_i			<= dfi_item1.en_i;
		dfi_driver_vif.reset_n_i		<= dfi_item1.reset_n_i;
		@(dfi_driver_vif.cb_D);
	end
	dfi_driver_vif.en_i			<= dfi_item1.en_i;
	dfi_driver_vif.reset_n_i		<= dfi_item1.reset_n_i;
	dfi_driver_vif.cb_D.phycrc_mode_i	<= dfi_item1.phycrc_mode_i;			
	dfi_driver_vif.cb_D.dfi_freq_ratio_i	<= dfi_item1.dfi_freq_ratio;


	case (dfi_item1.dfi_freq_ratio)
		2'b00 : begin	
			while (CMD_queue.size() >= 1) begin
				@(dfi_driver_vif.cb_D);
				dfi_driver_vif.cb_D.dfi_address_p0	<= CMD_queue.pop_front;
				dfi_driver_vif.cb_D.dfi_address_p1	<= 14'bz;			
				dfi_driver_vif.cb_D.dfi_address_p2	<= 14'bz;			
				dfi_driver_vif.cb_D.dfi_address_p3	<= 14'bz;			
				dfi_driver_vif.cb_D.dfi_cs_p0		<= CS_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_cs_p1		<= 1'bz;			
				dfi_driver_vif.cb_D.dfi_cs_p2		<= 1'bz;			
				dfi_driver_vif.cb_D.dfi_cs_p3		<= 1'bz;			
				dfi_driver_vif.cb_D.dfi_rddata_en_p0	<= rddata_en_queue.pop_front;				
				dfi_driver_vif.cb_D.dfi_rddata_en_p1	<= 1'bz;				
				dfi_driver_vif.cb_D.dfi_rddata_en_p2	<= 1'bz;				
				dfi_driver_vif.cb_D.dfi_rddata_en_p3	<= 1'bz;
				//`uvm_info("DRV", $sformatf("Driver: dfi_address_p0 = %b, dfi_item1.ROW = %p, dfi_item1.CID = %p,  CS_p0 = %p \t rddata_en_p0 = %p, at %t", dfi_driver_vif.cb_D.dfi_address_p0,dfi_item1.ROW,dfi_item1.CID,dfi_driver_vif.cb_D.dfi_cs_p0, dfi_driver_vif.cb_D.dfi_rddata_en_p0, $time), UVM_DEBUG)
			end
		end
		2'b01 : begin	
			while (CMD_queue.size() >= 2) begin	
				@(dfi_driver_vif.cb_D);		
				dfi_driver_vif.cb_D.dfi_address_p0	<= CMD_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_address_p1	<= CMD_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_address_p2	<= 14'bz;			
				dfi_driver_vif.cb_D.dfi_address_p3	<= 14'bz;			
				dfi_driver_vif.cb_D.dfi_cs_p0		<= CS_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_cs_p1		<= CS_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_cs_p2		<= 1'bz;			
				dfi_driver_vif.cb_D.dfi_cs_p3		<= 1'bz;			
				dfi_driver_vif.cb_D.dfi_rddata_en_p0	<= rddata_en_queue.pop_front;				
				dfi_driver_vif.cb_D.dfi_rddata_en_p1	<= rddata_en_queue.pop_front;				
				dfi_driver_vif.cb_D.dfi_rddata_en_p2	<= 1'bz;				
				dfi_driver_vif.cb_D.dfi_rddata_en_p3	<= 1'bz;
				//`uvm_info("DRV", $sformatf("Driver: Freq. ratio: %b, dfi_address_p0 = %b,  dfi_address_p1 = %b, CS_p0 = %p,  CS_p1 = %p  rddata_en_p0 = %p, rddata_en_p1 = %p, at %t",dfi_item1.dfi_freq_ratio, dfi_driver_vif.cb_D.dfi_address_p0, dfi_driver_vif.cb_D.dfi_address_p1,dfi_driver_vif.cb_D.dfi_cs_p0,dfi_driver_vif.cb_D.dfi_cs_p1,dfi_driver_vif.cb_D.dfi_rddata_en_p0,dfi_driver_vif.cb_D.dfi_rddata_en_p1, $time), UVM_DEBUG)	
			end
		end
		2'b10 : begin
			while (CMD_queue.size() >= 4) begin	
				@(dfi_driver_vif.cb_D);		
				dfi_driver_vif.cb_D.dfi_address_p0	<= CMD_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_address_p1	<= CMD_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_address_p2	<= CMD_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_address_p3	<= CMD_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_cs_p0		<= CS_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_cs_p1		<= CS_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_cs_p2		<= CS_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_cs_p3		<= CS_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_rddata_en_p0	<= rddata_en_queue.pop_front;				
				dfi_driver_vif.cb_D.dfi_rddata_en_p1	<= rddata_en_queue.pop_front;		
				dfi_driver_vif.cb_D.dfi_rddata_en_p2	<= rddata_en_queue.pop_front;				
				dfi_driver_vif.cb_D.dfi_rddata_en_p3	<= rddata_en_queue.pop_front;
				//`uvm_info("DRV", $sformatf("Driver: Freq. ratio: %b, dfi_address_p0 = %b,  dfi_address_p1 = %b, dfi_address_p2 = %b, dfi_address_p3 = %b, CS_p0 = %p, CS_p1 = %p, CS_p2 = %p, CS_p3 = %p  , rddata_en_p0 = %p, rddata_en_p1 = %p, rddata_en_p2 = %p, rddata_en_p3 = %p, at %t",dfi_item1.dfi_freq_ratio, dfi_driver_vif.cb_D.dfi_address_p0, dfi_driver_vif.cb_D.dfi_address_p1,dfi_driver_vif.cb_D.dfi_address_p2, dfi_driver_vif.cb_D.dfi_address_p3,dfi_driver_vif.cb_D.dfi_cs_p0,dfi_driver_vif.cb_D.dfi_cs_p1,dfi_driver_vif.cb_D.dfi_cs_p2,dfi_driver_vif.cb_D.dfi_cs_p3, dfi_driver_vif.cb_D.dfi_rddata_en_p0,dfi_driver_vif.cb_D.dfi_rddata_en_p1,dfi_driver_vif.cb_D.dfi_rddata_en_p2,dfi_driver_vif.cb_D.dfi_rddata_en_p3, $time), UVM_DEBUG)				
			end
		end
		default : begin				
			while (CMD_queue.size() >= 1) begin
				@(dfi_driver_vif.cb_D);
				dfi_driver_vif.cb_D.dfi_address_p0	<= CMD_queue.pop_front;
				dfi_driver_vif.cb_D.dfi_address_p1	<= 14'bz;			
				dfi_driver_vif.cb_D.dfi_address_p2	<= 14'bz;			
				dfi_driver_vif.cb_D.dfi_address_p3	<= 14'bz;			
				dfi_driver_vif.cb_D.dfi_cs_p0		<= CS_queue.pop_front;			
				dfi_driver_vif.cb_D.dfi_cs_p1		<= 1'bz;			
				dfi_driver_vif.cb_D.dfi_cs_p2		<= 1'bz;			
				dfi_driver_vif.cb_D.dfi_cs_p3		<= 1'bz;			
				dfi_driver_vif.cb_D.dfi_rddata_en_p0	<= rddata_en_queue.pop_front;				
				dfi_driver_vif.cb_D.dfi_rddata_en_p1	<= 1'bz;				
				dfi_driver_vif.cb_D.dfi_rddata_en_p2	<= 1'bz;				
				dfi_driver_vif.cb_D.dfi_rddata_en_p3	<= 1'bz;
				//`uvm_info("DRV", $sformatf("Driver: dfi_address_p0 = %b, CS_p0 = %p \t rddata_en_p0 = %p, at %t", dfi_driver_vif.cb_D.dfi_address_p0,dfi_driver_vif.cb_D.dfi_cs_p0, dfi_driver_vif.cb_D.dfi_rddata_en_p0, $time), UVM_HIGH)
			end
		end
	endcase
	uvm_config_db#(bit)::set(null,"uvm_test_top.env1.dram_agent1.dram_driver1","reset_n",dfi_item1.reset_n_i);	
	uvm_config_db#(bit)::set(null,"uvm_test_top.env1.dram_agent1.dram_driver1","termination_flag",dfi_item1.termination_flag);		//Send termination flag from mc_driver (got from sequence) to dram_driver to terminate dram resp_sequence

endtask : drive_dfi




//==============================================================================//
// Task: num_of_words 		
// Description: This task calculates the number of cycles for read data enable
//==============================================================================//

task mc_driver::num_of_words();
	if ((dfi_item1.CMD == MRW) && (dfi_item1.MRA == 0) && (dfi_item1.command_cancel != 1)) begin	
		case (dfi_item1.OP[1:0]) 
			'b00	: dfi_item1.num_of_words=BL16;
			'b01	: dfi_item1.num_of_words=BC8_OTF;
			'b10	: dfi_item1.num_of_words=BL32;
			default : dfi_item1.num_of_words=BL16;
		endcase
	end
	if ((dfi_item1.rddata_en) && (dfi_item1.command_cancel != 1)) begin
		if (dfi_item1.CMD == RD) begin
			if (!dfi_item1.BL_mod) begin		// If BL_mod is activated (Active low) >> Get BL from MR0		
				case (dfi_item1.num_of_words)
								//Return (0.5*BL) words (2*Device size)
					BL16 	: n_words = n_words + 8;		
					BC8_OTF : n_words = n_words + 4;
					BL32 	: n_words = n_words + 8;	//For each read (initial read and dummy one)
					default : n_words = n_words + 0;
				endcase
			end
			else begin
				n_words = n_words + 8;			//Default setting BL_mod High
			end
		end
		else if (dfi_item1.CMD == MRR) begin
			n_words	= n_words + 8;				//Default for read and MRR
		end
	end
endtask



//==============================================================================//
// Task: decode_cmd 		
// Description: This task Chooses which CMD encoding is chosen according to the
//		transaction item CMD
//==============================================================================//

task  mc_driver::decode_cmd();
	case (dfi_item1.CMD)
		ACT :	begin
			ACT_cmd();
		end
		RD :	begin
			RD_cmd();
		end
		MRW :	begin
			MRW_cmd();
		end
		MRR :	begin
			MRR_cmd();
		end
		DES :	begin
			DES_cmd();
		end
		PREab:begin
			PREab_CMD();
		end
		default:	begin
			DES_cmd();
		end
	endcase
endtask : decode_cmd


//==============================================================================//
// Task: ACT_cmd 		
// Description: This task performs ACT command encoding
//==============================================================================//

task automatic  mc_driver::ACT_cmd ();	// ACT command_decoding
	CMD0 = {
		dfi_item1.CID[2:0],
		dfi_item1.BG[2:0],
		dfi_item1.BA[1:0],
		dfi_item1.ROW[3:0],
		2'b00
	};
	CMD1 = {
		dfi_item1.ROW[17:4]
	};
	if(dfi_item1.command_cancel) begin
		CS0 = 0;
		CS1 = 0;
	end
	else begin
		CS0 = 0;
		CS1 = 1;
	end
endtask : ACT_cmd


//==============================================================================//
// Task: RD_cmd 		
// Description: This task performs Read command encoding
//==============================================================================//

task automatic  mc_driver::RD_cmd ();	// READ command_decoding
	CMD0 = {
		dfi_item1.CID[2:0],
		dfi_item1.BG[2:0],
		dfi_item1.BA[1:0],
		dfi_item1.BL_mod,		//Alternate BL mod (active low) in MR0 activation
		5'b11101
	};
	CMD1 = {
		dfi_item1.CID[3],
		2'b00,
		dfi_item1.AP,			//Auto precHARGE Active low
		1'b0,
		dfi_item1.C10,
		dfi_item1.Col[9:2]
	};
	if(dfi_item1.command_cancel) begin
		CS0 = 0;
		CS1 = 0;
	end
	else begin
		CS0 = 0;
		CS1 = 1;
	end
endtask : RD_cmd


//==============================================================================//
// Task: MRW_cmd 		
// Description: This task performs MRW command encoding
//==============================================================================//

task automatic  mc_driver::MRW_cmd ();	// MRW command_decoding
	CMD0 = {
		1'b0,
		dfi_item1.MRA[7:0],
		5'b00101
	};
	CMD1 = {
		3'b000,
		dfi_item1.CW,
		2'b00,
		dfi_item1.OP[7:0]
	};
	if(dfi_item1.command_cancel) begin
		CS0 = 0;
		CS1 = 0;
	end
	else begin
		CS0 = 0;
		CS1 = 1;
	end
endtask : MRW_cmd



//==============================================================================//
// Task: MRR_cmd 		
// Description: This task performs MRR command encoding
//==============================================================================//

task automatic  mc_driver::MRR_cmd ();	// MRR command_decoding
	CMD0 = {
		1'b0,
		dfi_item1.MRA[7:0],
		5'b10101
	};
	CMD1 = {
		3'b000,
		dfi_item1.CW,
		10'b0000000000
	};
	if(dfi_item1.command_cancel) begin
		CS0 = 0;
		CS1 = 0;
	end
	else begin
		CS0 = 0;
		CS1 = 1;
	end
endtask : MRR_cmd



//==============================================================================//
// Task: DES_cmd 		
// Description: This task performs DES
//==============================================================================//

task automatic mc_driver::DES_cmd ();	// Deselect command_decoding
	CMD0 = 'bz;
	CS0 = 1;
endtask : DES_cmd


//==============================================================================//
// Task: PREab_CMD 		
// Description: This task performs precharge command encoding
//==============================================================================//

task automatic mc_driver::PREab_CMD ();	// Precharge All command_decoding
	CMD0 = {
		dfi_item1.CID[2:0],
		5'b00000,
		dfi_item1.CID[3],
		5'b01011
	};
	CS0 = 0;
endtask : PREab_CMD


