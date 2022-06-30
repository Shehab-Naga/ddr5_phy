class ddr_sequence_item extends  uvm_sequence_item;
	
	parameter device_width = 4;
	parameter Physical_Rank_No = 1;

	`uvm_object_utils(ddr_sequence_item)	


	//================================ dfi_freq_ratio abstraction ==============================//
	//According to DFI, freq ratio 'b00 = 1:1, 'b01 = 1:2, 'b10 = 1:4
	`ifdef ratio_1_to_1
		bit [1:0] dfi_freq_ratio = 'b00;
	`elsif ratio_1_to_2
		bit [1:0] dfi_freq_ratio = 'b01;
	`elsif ratio_1_to_4
		bit [1:0] dfi_freq_ratio = 'b10;
	`else 
		bit [1:0] dfi_freq_ratio = 'b00;				//Default
	`endif  


	//================================ dfi_reset_n abstraction =================================//
	bit reset_n_i = 1;
	bit en_i = 1;
	bit dfi_reset_n; 
	
	//================================ phycrc_mode_i abstraction ===============================//
	bit phycrc_mode_i = 0;
	
	//=============================== No of DES (tCCD) abstraction ==============================//
	rand int tCCD;				//******Abdullah: changed type from "randc" to rand 
	rand int max_tCCD;			//******Abdullah: changed type from "randc" to rand
	int number_of_cycles_between_RD;	// used for interamble coverage
	int number_of_cycles_between_MRR; 	// used for interamble coverage
	

	//===================================== Data abstraction =====================================//
	rand bit [2*device_width-1:0] 	data ; 			//data
	bit 			      	dqs = 1;
	byte 				MR [50:0] ;		//MRs
	bit 			      	CS_DA_o;
	logic [2*device_width-1:0]    	jedec_rddata_queue [$];
	bit 			      	is_data_only;
	bit				termination_flag;

	//=============================== For rand test abstraction ====================================//
	rand command_t 	CMD_prev;
	rand bit 	AP_prev;
	rand bit 	command_cancel_prev;

	//=============================== dfi_address/CA abstraction ===================================//
	rand  command_t 		CMD;          
	randc bit 		[1:0]	BA;				//Bank Address 
	randc bit 		[2:0]	BG;				//Bank Group
	randc bit 		[3:0]	CID; 
	randc bit 		[17:0]	ROW;				//Row Address				
	randc bit 		[10:2]	Col;				//Column Address
	randc bit 		 	AP; 				 
	randc bit 		 	BL_mod;				 
	rand  bit 		[7:0]	MRA;				//Mode Register Address
	rand  bit 		[7:0]	OP;				//Mode Register Write Data (Sent on the CA bus)
	randc bit 		 	CW;				//Control Word
	rand  bit			C10;			
	rand  bit			command_cancel;			
	
	//=============================== MR Abstraction =====================================//
	burst_length_t 		burst_length;		// burst length value in the MR
	burst_length_t 		actual_burst_length;
	byte			RL 			= 22;			// Read/CAS latency [22:66]
	bit 		[2:0]	read_pre_amble 		= 0;
	bit 	        	read_post_amble 	= 0;
	bit			CRC_enable 		= 0;

	//=============================== dfi_rddata_en abstraction ===============================//
	burst_length_t						num_of_words;	 				//number of cycle to make dfi_rddata_en HIGH = 0.5*BL 
	rand bit						rddata_en;					 // I need this  item (John) in the driver
	logic 			[2*device_width-1:0] 		dfi_rddata_queue [$];


	//===========================================================================//
	//                                Constraints                                //
	//===========================================================================//
	//constraint c_dfi_reset_n {dfi_reset_n == 1;} 	 		// df1_reset_n is forced to 0 manually at the begnning of each sequence.
	
	constraint c_MRA {MRA inside {8'h00, 8'h08, 8'h32};}	// MR0, MR8, MR40, MR50 (The only registers used in the current DUT)
	
	constraint c_OP{ 
		if (MRA == 8'h00){					// MR0
			OP[1:0] inside {[2'b00:2'b10]}; 		// Burst Length: exlcude 11 (BL32 OTF) because it is not implemented in the current design
			OP[6:2] inside {[5'b000_00:5'b101_10]}; 	// CAS Latency (RL)
			OP[7] == 0;					// RFU bit = 0
		}else { 
		if (MRA == 8'h08){					// MR8
			OP[2:0] inside {[3'b000:3'b100]}; 		// Read Preamble Settings
			OP[5] == 0;					// RFU bit = 0
		} else {
		if (MRA == 8'h32){ 					// MR50
			OP[0] dist {0:/70, 1:/30};			// To favor the default value for most cases
			OP[7:6] == 0;					// RFU bits = 0
		}}}
		solve MRA before OP;
	}

	constraint c_command_cancel {command_cancel dist {0:/95, 1:/5};}

	constraint c_tCCD{ 
		if (CMD_prev == MRW) {
			if (command_cancel){
				tCCD inside {[8:8 + max_tCCD]};
			}
			else {
				if (CMD == MRW){
					tCCD inside {[8 :8 + max_tCCD]};		//Note min tMRW = 8 clk Page 20
				}
				else {
					tCCD inside {[16:16 + max_tCCD]};		//Note min tMRD = 16 clk
				} 
			}
		}
		else if (CMD_prev == MRR) {
			if (command_cancel){
				tCCD inside {[8:8 + max_tCCD]};
			}
			else {
				if (CMD == MRR){
					tCCD inside {[16:16 + max_tCCD]};		//Note min tMRR = 16 clk (back to back MRRs)
				}
				else if (CMD == MRW) {
					tCCD inside {[RL + 9 : RL + 9 + max_tCCD]};	/*Need Attention*/		//Note min from MRR to MRW = CL + BL/2 +1 = CL + 9
				}
				else {
					tCCD inside {[16:16 + max_tCCD]};			//Note min tMRD = 16 clk
				} 
			}
		}
		else if (CMD_prev == RD) {
			if (command_cancel){
				tCCD inside {[8:8 + max_tCCD]};
			}
			else {
				if (CMD == PREab){
					tCCD inside {[12:12 + max_tCCD]};			//Note min tRTP = 12 clk = 7.5 ns (Jedec Page 127, P 446)
				}
				else if (CMD == RD) {
					tCCD inside {[8:8 + max_tCCD]};	 /*Need Attention*/	//Note min tCCD_s, tCCD_L = 8 (p444)  BL16 in BL32 OTF or whatever (but in Fixed BL32 theremust be a dummy read after 8 nCK)
				}	
				else {								//Else AP must be activated (see rand seq constraints)
					tCCD inside {[36:36 + max_tCCD]};			//Note min delay  = tRTP + tRP = 36 (Jedec Page 134)
				}
			}
		}
		else if (CMD_prev == ACT) {
			if (command_cancel){
				tCCD inside {[8:8 + max_tCCD]};
			}
			else {
				if (CMD == ACT) {
					tCCD inside {[8:8 + max_tCCD]};				//Note: tRRD = 8 clk (Act to ACt) (Jedec page 446)
				} 								//else : RD cmd
				else {
					tCCD inside {[24:24 + max_tCCD]};			//Note: tRCD = 14 ns = 24 clk (ACT to Read or Write command) (Jedec Page 412)
				}
			}
		}
		else if (CMD_prev == PREab) {
			if (CMD == PREab){
				tCCD inside {[2:2 + max_tCCD]};				//Prechage to precharge delay tPPD = 2 P115
			}
			else {
				tCCD inside {[24:24 + max_tCCD]};			//Note: tRP = 14 ns = 24 clk (ROW Precharge) (Jedec Page 412)
			}
		}
		solve CMD before tCCD;
		solve max_tCCD before tCCD;
	}




	constraint c_CMD{ 
		if (CMD_prev == MRW) {
			CMD inside {MRW, MRR, ACT};
		}
		else if (CMD_prev == MRR) {
			CMD inside {MRW, MRR, ACT};
		}
		else if (CMD_prev == RD) {
			if ((!AP_prev) && (!command_cancel_prev)){			//If Auto Precharge is activated (active low) and not cancelled
				CMD inside {MRW, MRR, ACT};
			}       
			else {
				CMD inside {PREab, RD};
			}
		}
		else if (CMD_prev == ACT) {
			if (command_cancel_prev) {
				CMD inside {MRW, MRR, ACT};
			}
			else {
				CMD inside {ACT, RD};
				CMD dist {ACT:/20, RD:/80};	//Favor rd after act
			}	
		}
		else if (CMD_prev == PREab) {
			CMD inside {ACT, MRW, MRR/*, PREab*/};
		}
		else {
			CMD inside {MRW, MRR, ACT};
		}
		solve CMD_prev before CMD;
	}


	constraint c_rddata_en{ 
		if ((CMD == RD)||(CMD == MRR)) {
			rddata_en == 1;
		}
		else {
			rddata_en == 0;
		}
		solve CMD before rddata_en;
	}

	//***********Functions***********//
	extern function new (string name = "ddr_sequence_item");

	virtual function void do_copy (uvm_object rhs);
		ddr_sequence_item item;
		if (!$cast(item, rhs)) begin 
			`uvm_error("do_copy:","Cast failed")
			return;
		end
		super.do_copy(rhs);		// chain the copy with parent classes
		data 				= 	item.data ; 	
		dqs				=	item.dqs;
		CS_DA_o				=	item.CS_DA_o;
		jedec_rddata_queue		=	item.jedec_rddata_queue;
		is_data_only			=	item.is_data_only;
		dfi_freq_ratio 			= 	item.dfi_freq_ratio;
		dfi_reset_n			= 	item.dfi_reset_n; 
		phycrc_mode_i			= 	item.phycrc_mode_i;
		CMD				=	item.CMD;
		BA				=	item.BA; 	
		BG				=	item.BG; 
		CID				=	item.CID;	 
		ROW				=	item.ROW;	 
		Col				=	item.Col;	
		AP				=	item.AP; 	
		BL_mod				=	item.BL_mod; 
		MRA				=	item.MRA;
		OP				=	item.OP;
		CW				=	item.CW;			
		command_cancel			=	item.command_cancel;			
		burst_length			=	item.burst_length;
		actual_burst_length		=	item.actual_burst_length;		
		RL				=	item.RL;			
		tCCD				=	item.tCCD;			
		AP				=	item.AP;			
		read_pre_amble			=	item.read_pre_amble;
		read_post_amble			=	item.read_post_amble;
		CRC_enable			=	item.CRC_enable;
		//num_of_words 			= 	item.num_of_words;      //**********Abdullah: Remove because not used anymore
		rddata_en 			= 	item.rddata_en;
		dfi_rddata_queue		= 	item.dfi_rddata_queue;
		number_of_cycles_between_RD 	= 	item.number_of_cycles_between_RD;
		number_of_cycles_between_MRR 	= 	item.number_of_cycles_between_MRR;
	endfunction : do_copy

	virtual function string convert2string();
		string contents = "";
		$sformat(contents, "%s \n CMD     \t\t= %p\n",contents, CMD);
		$sformat(contents, "%s dfi_rddata_queue \t= %p\n",contents, dfi_rddata_queue);
		$sformat(contents, "%s dfi_freq_ratio     \t= %p\n",contents, dfi_freq_ratio);
		$sformat(contents, "%s dfi_reset_n     \t= %p\n",contents, dfi_reset_n);
		$sformat(contents, "%s phycrc_mode_i     \t= %p\n",contents, phycrc_mode_i);
		$sformat(contents, "%s data     \t\t= %p\n",contents, data);
		$sformat(contents, "%s dqs     \t\t= %p\n",contents, dqs);
		$sformat(contents, "%s CS_DA_o     \t\t= %p\n",contents, CS_DA_o);
		$sformat(contents, "%s jedec_rddata_queue\t= %p\n",contents, jedec_rddata_queue);
		$sformat(contents, "%s is_data_only     \t= %p\n",contents, is_data_only);
		$sformat(contents, "%s BA     \t\t= %p\n",contents, BA);
		$sformat(contents, "%s BG     \t\t= %p\n",contents, BG);
		$sformat(contents, "%s CID     \t\t= %p\n",contents, CID);
		$sformat(contents, "%s ROW     \t\t= %p\n",contents, ROW);
		$sformat(contents, "%s Col     \t\t= %p\n",contents, Col);
		$sformat(contents, "%s AP     \t\t= %p\n",contents, AP);
		$sformat(contents, "%s BL_mod     \t\t= %p\n",contents, BL_mod);
		$sformat(contents, "%s MRA     \t\t= %p\n",contents, MRA);
		$sformat(contents, "%s OP     \t\t= %p\n",contents, OP);
		$sformat(contents, "%s CW     \t\t= %p\n",contents, CW);
		$sformat(contents, "%s command_cancel     \t= %p\n",contents, command_cancel);
		$sformat(contents, "%s burst_length     \t= %p\n",contents, burst_length);
		$sformat(contents, "%s actual_burst_length \t= %p\n",contents, actual_burst_length);
		$sformat(contents, "%s RL     \t\t= %p\n",contents, RL);
		$sformat(contents, "%s read_pre_amble     \t= %p\n",contents, read_pre_amble);
		$sformat(contents, "%s read_post_amble     \t= %p\n",contents, read_post_amble);
		$sformat(contents, "%s CRC_enable     \t= %p\n",contents, CRC_enable);
		//$sformat(contents, "%s num_of_words     \t= %p\n",contents, num_of_words);  //**********Abdullah: Remove because not used anymore
		$sformat(contents, "%s rddata_en     \t= %p\n",contents, rddata_en);
		$sformat(contents, "%s is_data_only     \t= %p\n",contents, is_data_only);
		$sformat(contents, "%s number_of_cycles_between_RD     \t= %p\n",contents, number_of_cycles_between_RD);
		$sformat(contents, "%s number_of_cycles_between_MRR     \t= %p\n",contents, number_of_cycles_between_MRR);
		return contents;
		// To print the content of any object, use the following:
		// `uvm_info("obj_name", obj_name.convert2string(), UVM_MEDIUM)
	endfunction : convert2string
	
	virtual function string convert2string_Compact();
		string contents = "";
		$sformat(contents, "%s \n CMD     \t\t= %p\n",contents, CMD);
		$sformat(contents, "%s dfi_rddata_queue \t= %p\n",contents, dfi_rddata_queue);
		$sformat(contents, "%s command_cancel     \t= %p\n",contents, command_cancel);
		$sformat(contents, "%s tCCD     \t\t= %p\n",contents, tCCD);
		$sformat(contents, "%s AP     \t\t= %p\n",contents, AP);
		$sformat(contents, "%s BL_mod     \t\t= %p\n",contents, BL_mod);
		$sformat(contents, "%s MRA     \t\t= %p\n",contents, MRA);
		$sformat(contents, "%s burst_length     \t= %p\n",contents, burst_length);
		$sformat(contents, "%s actual_burst_length \t= %p\n",contents, actual_burst_length);
		$sformat(contents, "%s RL     \t\t= %p\n",contents, RL);
		$sformat(contents, "%s read_pre_amble     \t= %p\n",contents, read_pre_amble);
		return contents;
		// To print the content of any object, use the following:
		// `uvm_info("obj_name", obj_name.convert2string_Compact(), UVM_MEDIUM)
	endfunction : convert2string_Compact
	
	virtual function void do_print(uvm_printer printer); 
		$display("\n\n\t\t*** print() and sprint() are not implemented ", "for this transaction type ***\n\n"); 
	endfunction : do_print

	
endclass : ddr_sequence_item


function ddr_sequence_item::new (string name = "ddr_sequence_item");
	super.new(name);
endfunction


/*
variables used for coverage:
	From data thread:
		actual_burst_length
		jedec_rddata_queue
		OP (if MRR)
	From cmd thread:
			CMD
			BA
			BG
			CID
			ROW
			MRA
			BL_mod
			command_cancel
			OP (if MRW)
			CW
			Col
			AP
			number_of_cycles_between_RD
		RL
		read_pre_amble
		burst_length // the burst length in the MR	

*/
/* 
ACT:
CMD
ROW
BA
BG
CID
command_cancel
-------------------------------------------
MRW:
CMD
MRA
command_cancel
OP
CW
burst_length
RL
read_pre_amble
read_post_amble
--------------------------------------------
MRR:
CMD
MRA
command_cancel
CW
burst_length
actual_burst_length
RL
read_pre_amble
read_post_amble
--------------------------------------------
RD:
CMD
BL_mod
BA
BG
CID
command_cancel
Col
AP
burst_length
actual_burst_length
RL
read_pre_amble
read_post_amble
--------------------------------------------
NOP:
CMD
command_cancel
--------------------------------------------
precharge:
CMD
BA
BG
CID
command_cancel
--------------------------------------------
*/
// New Variable: actual_burst_length

