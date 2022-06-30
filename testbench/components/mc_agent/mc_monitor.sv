typedef mailbox #(burst_length_t)		burst_length_mbx;

class mc_monitor extends  uvm_monitor;
	`uvm_component_utils(mc_monitor)
	virtual dfi_intf				            dfi_monitor_vif;
	ddr_sequence_item				            dfi_item1;
	ddr_sequence_item				            dfi_item2;
	uvm_analysis_port#(ddr_sequence_item)   	mc_analysis_port;
	static bit [3:0]                           	next_start_word = 0;//starting word number for rotation
	static bit [3:0]                            	start_word = 0;     //temp variable for rotation
	static int                                  	BLs_queue [$];      //a queue of read data commands' BLs
	static bit                                  	is_second_cycle = 0;
	static bit                                  	is_dummy_read = 0;
	//static burst_length_t				burst_length_queue [$];
	burst_length_mbx				burst_length_mbx_inst;
	//==========================================================================//
	//                      Mode Register Variables                             //
	//==========================================================================//
	static  bit 		 [2:0]	                read_pre_amble 	= 3'b000;
	static  bit 	        	                read_post_amble = 0;
	static  byte	                           	RL 		= 8'd22;
	static  burst_length_t     			burst_length 	= BL16;
	static  burst_length_t     			actual_burst_length;
	static  burst_length_t     			data_burst_length = BL16;
	static int					words_counter=0;
	static int					number_of_words =8;
	static bit					get_size_flag=1;
	//==========================================================================//
	//                     frequency ratio divider                              //
	//==========================================================================//
	`ifdef ratio_1_to_1
		static int                                 freq_ratio_divider = 1;
		`elsif ratio_1_to_2
		static int                                 freq_ratio_divider = 2;
		`elsif ratio_1_to_4
		static int                                 freq_ratio_divider = 4;
		`else 
		static int                                 freq_ratio_divider = 1;				//Default
	`endif 

	//====================================================================================================================================================//
	// DFI_DR_13 && DFI_DR_16 - From Plan: number of dfi_rddata_en assertion clocks = number of dfi_rddata_valid assertion clocks			      //
	//====================================================================================================================================================//
	static int num_of_en	[$];
	static int num_of_valid [$];
	event 	counted_en; 
	event 	counted_valid;
	int count_valid=0, count_en=0;

	function new (string name = "mc_monitor", uvm_component parent = null);
		super.new(name,parent);
	endfunction 

	//==========================================================================//
	//                          Build Phase                                     //
	//==========================================================================//
	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual dfi_intf)::get(this,"","dfi_vif",dfi_monitor_vif))
		`uvm_fatal(get_full_name(),"Error in getting dfi_vif from database!")
		dfi_item1 = ddr_sequence_item::type_id::create("dfi_item1");
		dfi_item2 = ddr_sequence_item::type_id::create("dfi_item2");
		mc_analysis_port = new("mc_analysis_port",this);
		burst_length_mbx_inst=new();
		`uvm_info("Build_Phase", "*************** 'mc_monitor' Build Phase ***************", UVM_HIGH)
	endfunction 

	//==========================================================================//
	//                        Connect Phase                                     //
	//==========================================================================//
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		`uvm_info("Connect_phase", "*************** 'mc_monitor' Connect Phase ***************", UVM_HIGH)
	endfunction

	//==========================================================================//
	//                            Run Phase                                     //
	//==========================================================================//
	task run_phase(uvm_phase phase);
		super.run_phase(phase);

		@(posedge dfi_monitor_vif.en_i);
		@(posedge dfi_monitor_vif.reset_n_i);
		fork begin
			forever begin
				monitor_data(phase);
			end
		end
		begin 
			forever begin
				monitor_cmd(phase);
			end
		end
		begin
			forever begin
				count_en_cycles(phase);
			end
		end
		begin
			forever begin
				@(counted_en);
				@(counted_valid);
				$display("num_of_en = %d & num_of_valid = %d", num_of_en[0], num_of_valid[0]);	
				if(num_of_valid.pop_front()==num_of_en.pop_front())
				begin
					//Success
				end
				else
				begin
					`uvm_error("DDR Assertions",  $sformatf("dfi_rddata_valid does not match dfi_rddata_en in length") );
				end
			end
		end
		join
	endtask

	extern task monitor_data(uvm_phase phase);
	extern task monitor_cmd(uvm_phase phase);
	extern task monitor_phase(input [13:0] dfi_address, input dfi_cs, uvm_phase phase);
	extern task count_en_cycles(uvm_phase phase);
endclass : mc_monitor



//==============================================================================//
//||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||//
//==============================================================================//
//				MC Monitor Tasks				//
//==============================================================================//
//||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||//
//==============================================================================//

//==============================================================================//
// Task: count en cycles 		
// Description: 
//==============================================================================//
task mc_monitor::count_en_cycles(uvm_phase phase);
	count_en=0;
        @(posedge dfi_monitor_vif.dfi_rddata_en_p0 ,posedge  dfi_monitor_vif.dfi_rddata_en_p1 ,posedge  dfi_monitor_vif.dfi_rddata_en_p2 ,posedge  dfi_monitor_vif.dfi_rddata_en_p3);
        @(dfi_monitor_vif.cb_D);
	while ( (dfi_monitor_vif.dfi_rddata_en_p0 || dfi_monitor_vif.dfi_rddata_en_p1 || dfi_monitor_vif.dfi_rddata_en_p2 || dfi_monitor_vif.dfi_rddata_en_p3) )//|| (dfi_monitor_vif.cb_D.dfi_rddata_en_p0 || dfi_monitor_vif.cb_D.dfi_rddata_en_p1 || dfi_monitor_vif.cb_D.dfi_rddata_en_p2 || dfi_monitor_vif.cb_D.dfi_rddata_en_p3) ) 
	begin
		if (dfi_monitor_vif.dfi_rddata_en_p0) begin
			next_start_word=1;
			//Counting en Cycles
			count_en = count_en+1;
			$display("Inside count_en_cycles task: count_en = %d at time = %d", count_en , $time);
			//
		end
		if (dfi_monitor_vif.dfi_rddata_en_p1) begin
			next_start_word=2;
			//Counting en Cycles
			count_en = count_en+1;
			$display("Inside count_en_cycles task: count_en = %d at time = %d", count_en , $time);
		//
		end
		if (dfi_monitor_vif.dfi_rddata_en_p2) begin
			next_start_word=3;
			//Counting en Cycles
			count_en = count_en+1;
			$display("Inside count_en_cycles task: count_en = %d at time = %d", count_en , $time);
		//
		end
		if (dfi_monitor_vif.dfi_rddata_en_p3) begin
			next_start_word=0;
			//Counting en Cycles
			count_en = count_en+1;
			$display("Inside count_en_cycles task: count_en = %d at time = %d", count_en , $time);
		//
		end      	
                @(dfi_monitor_vif.cb_D);
        end
	num_of_en.push_back(count_en);
	->counted_en;
endtask


//==============================================================================//
// Task: monitor_data 		
// Description: 
//==============================================================================//
task mc_monitor::monitor_data(uvm_phase phase);
        dfi_item1.is_data_only = 1;
	count_valid=0; 
        //Removed the ".cb_D." because dfi_rddata_valid_w0 acts as a trigger for the while. If cb_D is used, the first word will be missed!
        @(posedge dfi_monitor_vif.dfi_rddata_valid_w0 ,posedge  dfi_monitor_vif.dfi_rddata_valid_w1 ,posedge  dfi_monitor_vif.dfi_rddata_valid_w2 ,posedge  dfi_monitor_vif.dfi_rddata_valid_w3);
        //Removed the ".cb_D." because dfi_rddata_valid_w0 acts as a trigger for the while. If cb_D is used, the first word will be missed!
        //Added the ORRING of the same expression but with the cb_D to catch the last word; otherwise it will be missed
        while ( (dfi_monitor_vif.dfi_rddata_valid_w0 || dfi_monitor_vif.dfi_rddata_valid_w1 || dfi_monitor_vif.dfi_rddata_valid_w2 || dfi_monitor_vif.dfi_rddata_valid_w3) || (dfi_monitor_vif.cb_D.dfi_rddata_valid_w0 || dfi_monitor_vif.cb_D.dfi_rddata_valid_w1 || dfi_monitor_vif.cb_D.dfi_rddata_valid_w2 || dfi_monitor_vif.cb_D.dfi_rddata_valid_w3) ) begin
                //@(dfi_monitor_vif.cb_D);
                start_word=next_start_word;
                for (int i=0; i<freq_ratio_divider; i++) begin
			if (get_size_flag) begin
				get_size_flag=0;
				burst_length_mbx_inst.get(data_burst_length);
				//$display("MONITOR: got %p from the mbx",data_burst_length);
				case (data_burst_length)
					BL16: 		number_of_words = 8;      // BL16: 8 Clock cycles
					BC8_OTF: 	number_of_words = 4;      // BC8 OTF: 4 Clock cycles
					BL32: 		number_of_words = 16;      // BL32: 16 Clock cycles
				endcase
			end
                        case ((start_word+i)%freq_ratio_divider)
                        0: begin
                                if (dfi_monitor_vif.cb_D.dfi_rddata_valid_w0) begin
                                dfi_item1.dfi_rddata_queue.push_back(dfi_monitor_vif.cb_D.dfi_rddata_w0);
                                words_counter=words_counter+1;
				next_start_word=1;
				//Counting Valid Cycles
				count_valid = count_valid+1;
				$display("Inside monitor_data task: count_valid = %d at time = %d", count_valid , $time);
				//
                                end
                        end
                        1: begin
                                if (dfi_monitor_vif.cb_D.dfi_rddata_valid_w1) begin
                                dfi_item1.dfi_rddata_queue.push_back(dfi_monitor_vif.cb_D.dfi_rddata_w1);
                                words_counter=words_counter+1;
				next_start_word=2;
				//Counting Valid Cycles
				count_valid = count_valid+1;
				$display("Inside monitor_data task: count_valid = %d at time = %d", count_valid , $time);
				//
                                end
                        end
                        2: begin
                                if (dfi_monitor_vif.cb_D.dfi_rddata_valid_w2) begin
                                dfi_item1.dfi_rddata_queue.push_back(dfi_monitor_vif.cb_D.dfi_rddata_w2);
                                words_counter=words_counter+1;
				next_start_word=3;
				//Counting Valid Cycles
				count_valid = count_valid+1;
				$display("Inside monitor_data task: count_valid = %d at time = %d", count_valid , $time);
				//
                                end
                        end
                        3: begin
                                if (dfi_monitor_vif.cb_D.dfi_rddata_valid_w3) begin
                                dfi_item1.dfi_rddata_queue.push_back(dfi_monitor_vif.cb_D.dfi_rddata_w3);
                                words_counter=words_counter+1;
				next_start_word=0;
				//Counting Valid Cycles
				count_valid = count_valid+1;
				$display("Inside monitor_data task: count_valid = %d at time = %d", count_valid , $time);
				//
                                end
                        end
                        default: begin
                                if (dfi_monitor_vif.cb_D.dfi_rddata_valid_w0) begin
                                dfi_item1.dfi_rddata_queue.push_back(dfi_monitor_vif.cb_D.dfi_rddata_w0);
                                words_counter=words_counter+1;
				next_start_word=1;
				//Counting Valid Cycles
				count_valid = count_valid+1;
				$display("Inside monitor_data task: count_valid = %d at time = %d", count_valid , $time);
				//
                                end
                        end
                        endcase
			if (words_counter>=number_of_words) begin
				//$display("MONITOR: counted %p words and sent them as %p",words_counter,dfi_item1.dfi_rddata_queue);
				words_counter=0;
				get_size_flag=1;
				phase.raise_objection(this);
					`uvm_info("MON", $sformatf("Monitor_data: data = %p, at %t", dfi_item1.dfi_rddata_queue, $time), UVM_DEBUG)	
					mc_analysis_port.write(dfi_item1);
				phase.drop_objection(this);
				dfi_item1.dfi_rddata_queue = {};
				dfi_item1.is_data_only = 1;
			end
                end		
                @(dfi_monitor_vif.cb_D);
        end
	num_of_valid.push_back(count_valid);
	->counted_valid;
endtask

//==============================================================================//
// Task: monitor_cmd 		
// Description: 
//==============================================================================//
task mc_monitor::monitor_cmd(uvm_phase phase);
	//note: no crc
	//assumed one physical rank
	
	wait(dfi_monitor_vif.en_i)
	wait(dfi_monitor_vif.reset_n_i)
	@(posedge dfi_monitor_vif.dfi_clk);
	dfi_item2.is_data_only = 0;
	dfi_item2.command_cancel = 0;
	case (dfi_monitor_vif.dfi_freq_ratio_i)
	2'b00 : begin
		monitor_phase(dfi_monitor_vif.dfi_address_p0,dfi_monitor_vif.dfi_cs_p0,phase); 
	end
	2'b01 : begin
		monitor_phase(dfi_monitor_vif.dfi_address_p0,dfi_monitor_vif.dfi_cs_p0,phase); 
		monitor_phase(dfi_monitor_vif.dfi_address_p1,dfi_monitor_vif.dfi_cs_p1,phase); 
	end
	2'b10 : begin
		monitor_phase(dfi_monitor_vif.dfi_address_p0,dfi_monitor_vif.dfi_cs_p0,phase); 
		monitor_phase(dfi_monitor_vif.dfi_address_p1,dfi_monitor_vif.dfi_cs_p1,phase); 
		monitor_phase(dfi_monitor_vif.dfi_address_p2,dfi_monitor_vif.dfi_cs_p2,phase); 
		monitor_phase(dfi_monitor_vif.dfi_address_p3,dfi_monitor_vif.dfi_cs_p3,phase); 
	end
	default: begin
		monitor_phase(dfi_monitor_vif.dfi_address_p0,dfi_monitor_vif.dfi_cs_p0,phase); 
	end
	endcase
endtask


//==============================================================================//
// Task: monitor_phase 		
// Description: 
//==============================================================================//
task mc_monitor::monitor_phase(input [13:0] dfi_address, input dfi_cs, uvm_phase phase);
	if (is_second_cycle) begin //second cycle
	if(dfi_cs) begin //good second cycle
		case (dfi_item2.CMD)
		ACT: begin
			dfi_item2.CID[3]     = dfi_address[13];
			dfi_item2.ROW[17:4]  = dfi_address[13:0];
		end
		MRW: begin
			dfi_item2.OP[7:0]    = dfi_address[7:0];
			dfi_item2.CW         = dfi_address[10];
			case (dfi_item2.MRA[7:0])
				8'h00:  begin
						if (!$cast(burst_length, dfi_item2.OP[1:0]))			// MR0, Burst Length
							`uvm_error("mc monitor_cmd:","Cast failed")
						RL 			= 22 + 2*dfi_item2.OP[6:2];
						dfi_item2.burst_length 	= burst_length;
						//$display("MONITOR: mode register changed BL to %p",burst_length);
						dfi_item2.RL 		= RL;
					end	
				8'h08:  begin                                                               // MR8
						read_pre_amble[2:0] 		= dfi_item2.OP[2:0]; 		        // Read Preamble Settings
						read_post_amble 		= dfi_item2.OP[6];                       // Read Postamble Settings
						dfi_item2.read_pre_amble 	= read_pre_amble;
						dfi_item2.read_post_amble 	= read_post_amble;
					end
				default: begin
					//nothing
					end
			endcase
		end
		MRR: begin
			dfi_item2.CW         = dfi_address[10];
			dfi_item2.actual_burst_length    = BL16;
			dfi_item2.RL 			= RL;
			dfi_item2.read_pre_amble 	= read_pre_amble;
			dfi_item2.read_post_amble 	= read_post_amble;
			burst_length_mbx_inst.put(dfi_item2.actual_burst_length);
			//$display("MONITOR: MRR command put %p into the mbx",dfi_item2.actual_burst_length);

		end
		RD: begin
			if (is_dummy_read)begin
				dfi_item2.CMD=DES;
				is_dummy_read=0;
				//$display("MONITOR: Ignored Dummy RD");

			end 
			else begin
				dfi_item2.Col[10:2]  = dfi_address[8:0];
				dfi_item2.AP         = dfi_address[10];
				dfi_item2.CID[3]     = dfi_address[13];
				dfi_item2.burst_length 		= burst_length;
				dfi_item2.actual_burst_length = dfi_item2.burst_length;
				if (dfi_item2.BL_mod) dfi_item2.actual_burst_length = BL16;
				dfi_item2.RL 			= RL;
				dfi_item2.read_pre_amble 	= read_pre_amble;
				dfi_item2.read_post_amble 	= read_post_amble;
				burst_length_mbx_inst.put(dfi_item2.actual_burst_length);
				//$display("MONITOR: RD command put %p into the mbx",dfi_item2.actual_burst_length);
				//dealing with BL32
				if (dfi_item2.actual_burst_length == BL32) begin
					is_dummy_read=1;
				end
			end
		end
		default: begin
			//nothing
		end
		endcase
	end
	else begin //canceled second cycle
		dfi_item2.command_cancel=1;
	end
	is_second_cycle=0;
	if(dfi_item2.CMD!=DES) begin
		phase.raise_objection(this);
			`uvm_info("MON", $sformatf("Monitor_cmd: cmd = %p, cancelled: %b  ,row= %p, CID= %p,  at %t", dfi_item2.CMD, dfi_item2.command_cancel,dfi_item2.ROW,dfi_item2.CID ,$time), UVM_DEBUG)	
			mc_analysis_port.write(dfi_item2);
		phase.drop_objection(this); 
	end
	end
	else begin  //first cycle
	if(!dfi_cs) begin //selected
		casex(dfi_address[4:0])
		//Act:
		5'b???00: begin
			dfi_item2.CMD        = ACT;
			dfi_item2.ROW[3:0]   = dfi_address[5:2];
			dfi_item2.BA[1:0]    = dfi_address[7:6];
			dfi_item2.BG[2:0]    = dfi_address[10:8];
			dfi_item2.CID[2:0]   = dfi_address[13:11];
		end
		//MRW:
		5'b00101: begin
			dfi_item2.CMD        = MRW;
			dfi_item2.MRA[7:0]   = dfi_address[12:5];
		end
		//MRR:
		5'b10101: begin
			dfi_item2.CMD        = MRR;
			dfi_item2.MRA[7:0]   = dfi_address[12:5];
		end
		//RD:
		5'b11101: begin
			dfi_item2.CMD        = RD;
			dfi_item2.BL_mod     = dfi_address[5];
			dfi_item2.BA[1:0]    = dfi_address[7:6];
			dfi_item2.BG[2:0]    = dfi_address[10:8];
			dfi_item2.CID[2:0]   = dfi_address[13:11];
		end
		//NOP:
		5'b11111: begin
			dfi_item2.CMD        = NOP;
		end
		//precharge:
		5'b01011: begin
			dfi_item2.CMD        = PREab;
			dfi_item2.CID[2:0]   = dfi_address[13:11];
			dfi_item2.CID[3]     = dfi_address[5];
		end
		//other:
		default: begin   
			dfi_item2.CMD        = other;
		end
		endcase
		if (dfi_address[1]) begin //one cycle
		phase.raise_objection(this);
			`uvm_info("MON", $sformatf("Monitor_cmd: cmd = %p, cancelled: %b  ,row= %p, CID= %p,  at %t", dfi_item2.CMD, dfi_item2.command_cancel,dfi_item2.ROW,dfi_item2.CID ,$time), UVM_DEBUG)	
			mc_analysis_port.write(dfi_item2);	
		phase.drop_objection(this);
		end
		else begin //two cycles
		is_second_cycle=1;
		end
	end 
	else begin  //deselect
		dfi_item2.CMD        = DES;
	end
	end
endtask
