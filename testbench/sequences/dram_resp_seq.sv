/***************************** dram_resp_seq Sequence Description ****************************

Class		: 	dram_resp_seq
Description	:	This sequence performs a dram_resp_seq

************************************************************************************/

class dram_resp_seq extends uvm_sequence #(ddr_sequence_item);
	static int n_words = 0;
	function new(string name="dram_resp_seq");
	super.new(name);
	endfunction

	`uvm_object_utils(dram_resp_seq)
	ddr_sequence_item drv_item;
	ddr_sequence_item rsp_item;
	static bit [2:0]  dqs_period;
	static logic [7:0]	Data_queue [$];
	static logic 		DQS_queue [$];
	static int 		gap_flag = 1;
	static int		gap_counter = 66;
	static int		gap_q [$];
	static int		rddata_delay;

	task pre_body();
		drv_item = ddr_sequence_item::type_id::create ("drv_item");
		rsp_item = ddr_sequence_item::type_id::create ("rsp_item");
	endtask

	task body();
		while(!(rsp_item.termination_flag && (Data_queue.size() == 0))) begin			//Condition on termination got from dram driver resp item
			DRAM_resp();
		end

		repeat (8) begin
			start_item (drv_item);
				drv_item.data = 0;
				drv_item.dqs = 0;
			finish_item (drv_item);
		end

	endtask
	

	extern task DRAM_resp();
	extern task fill_data_q();
	extern task fill_dqs_pre_q();
	extern task fill_dqs_post_q();
	extern task fill_dqs_inter_q();
	extern task calc_rd_gap();
	extern task drive_MRR();
endclass : dram_resp_seq

task dram_resp_seq::DRAM_resp ();
	calc_rd_gap();
	//$display("Data_queue = %p\nDQS_queue = %p\ngap_flag = %p, gap_q = %p, counter = %p, rddata_delay = %p, n_words = %p, %t\n\n", Data_queue, DQS_queue, gap_flag, gap_q, gap_counter, rddata_delay, n_words, $time);
	if ((rsp_item.CMD == RD) || (rsp_item.CMD == MRR)) begin 			// Function to Check RD
		`uvm_info("Build_Phase", $sformatf("BL = %p, Preamble: %p, RL = %p",rsp_item.burst_length, rsp_item.read_pre_amble, rsp_item.RL), UVM_DEBUG)
		
		case (rsp_item.burst_length)
			BL16 	: 	n_words = 8;
			BC8_OTF: 	n_words = 4;
			BL32 	: 	n_words = 8;
		endcase

		case (rsp_item.read_pre_amble)
			0 : dqs_period=2;
			1 : dqs_period=4;
			2 : dqs_period=4;
			3 : dqs_period=6;
			4 : dqs_period=8;
			default : dqs_period = 2;
		endcase

		if ((gap_q.size() != 0) && (gap_q[0] < rsp_item.RL)) begin
			rddata_delay = gap_q.pop_front() - n_words;
			fill_data_q();
			if(rddata_delay <= 5) fill_dqs_inter_q();
			else fill_dqs_pre_q();
		end
		else begin 
			if (gap_q.size() != 0) gap_q.delete(0);
			rddata_delay = rsp_item.RL - dqs_period;
			fill_data_q();
			fill_dqs_pre_q();
		end
		
		if (rsp_item.CMD == RD) begin					//If read randomise DQ bus
			while (n_words > 0) begin
				if (!(drv_item.randomize())) `uvm_fatal("TR_S", "tr_sequence randomization failed")
				Data_queue = {Data_queue, drv_item.data};
				DQS_queue = {DQS_queue, 0};
				n_words = n_words - 1;
			end
		end
		else begin							//IF MRR
			drive_MRR();
		end
		fill_dqs_post_q();		//Apply postample only if rddata_delay > 0 (if 0 implies b2b read)

	end
	
	
	start_item (drv_item);
		drv_item.data = Data_queue.pop_front();
		drv_item.dqs = DQS_queue.pop_front();
	finish_item (drv_item);
	get_response(rsp_item);
	
endtask : DRAM_resp





task dram_resp_seq::fill_data_q();
	for (int i = 2; i < rddata_delay; i = i + 1) begin				//i = 1 bec. [ resp latency (2CK) - CA latency (1CK) ] 
		Data_queue = {Data_queue, 0};
		DQS_queue = {DQS_queue, 0};
	end

endtask : fill_data_q





task dram_resp_seq::fill_dqs_pre_q();
	case (rsp_item.read_pre_amble)
		0 : begin
			Data_queue = {Data_queue, 0, 0};
			DQS_queue = {DQS_queue, 1, 0};				
		end
		1 : begin
			Data_queue = {Data_queue, 0, 0, 0, 0};
			DQS_queue = {DQS_queue, 0, 0, 1, 0};				
		end
		2 : begin
			Data_queue = {Data_queue, 0, 0, 0, 0};
			DQS_queue = {DQS_queue, 1, 1, 1, 0};				
		end
		3 : begin
			Data_queue = {Data_queue, 0, 0, 0, 0, 0, 0};
			DQS_queue = {DQS_queue, 0, 0, 0, 0, 1, 0};				
		end
		4 : begin
			Data_queue = {Data_queue, 0, 0, 0, 0, 0, 0, 0, 0};
			DQS_queue = {DQS_queue, 0, 0, 0, 0, 1, 0, 1, 0};				
		end
		default : begin
			Data_queue = {Data_queue, 0, 0};
			DQS_queue = {DQS_queue, 1, 0};			
		end
	endcase
endtask


task dram_resp_seq::fill_dqs_post_q();
	DQS_queue = DQS_queue [0:$-1];			//Delete last item in DQS queue because postample begins with last data word
	case (rsp_item.read_post_amble)
		0 : begin
			DQS_queue = {DQS_queue, 0};				
		end
		1 : begin
			Data_queue = {Data_queue, 0, 0};
			DQS_queue = {DQS_queue, 0, 1, 0};				
		end
		default : begin
			DQS_queue = {DQS_queue, 0};			
		end
	endcase
endtask




task dram_resp_seq::fill_dqs_inter_q();
	case (rddata_delay)							//rddata_delay = tCCD - BL/2
		0 : begin							//If tCCD = BL/2
			if (rsp_item.read_post_amble) begin			//Delete postamble
				Data_queue = Data_queue [0:$-2];
				DQS_queue =  DQS_queue [0:$-2];
			end			
		end
		1 : begin							//If tCCD = BL/2 + 1
			if (!rsp_item.read_post_amble) begin
				Data_queue = {Data_queue, 0, 0};
				DQS_queue = {DQS_queue, 1, 0};	
			end					
		end
		2 : begin							//If tCCD = BL/2 + 2
			if (rsp_item.read_post_amble) begin
				Data_queue = {Data_queue, 0, 0};
				DQS_queue = {DQS_queue, 1, 0};	
			end	
			else begin
				case (rsp_item.read_pre_amble)
					0 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 1, 0};				
					end
					1 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 1, 0};				
					end
					2 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 1, 1, 1, 0};				
					end
					3 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 1, 0};				
					end
					4 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 1, 0, 1, 0};				
					end
					default: begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 1, 0};				
					end
				endcase
			end

		end
		3 : begin							//If tCCD = BL/2 + 3
			if (rsp_item.read_post_amble) begin
				case (rsp_item.read_pre_amble)
					0 : begin
						Data_queue = {Data_queue, 0, 0};
						DQS_queue = {DQS_queue, 0, 0};	
						fill_dqs_pre_q();			
					end
					1 : begin
						fill_dqs_pre_q();			
					end
					2 : begin
						fill_dqs_pre_q();				
					end
					3 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 1, 0, 1, 0};				
					end
					4 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 1, 0};	
					end
					default: begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 1, 0, 1, 0};	
					end
				endcase
			end	
			else begin
				case (rsp_item.read_pre_amble)
					0 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0};	
						fill_dqs_pre_q();			
					end
					1 : begin
						Data_queue = {Data_queue, 0, 0};
						DQS_queue = {DQS_queue, 0, 0};	
						fill_dqs_pre_q();			
					end
					2 : begin
						Data_queue = {Data_queue, 0, 0};
						DQS_queue = {DQS_queue, 0, 0};	
						fill_dqs_pre_q();				
					end
					3 : begin
						fill_dqs_pre_q();				
					end
					4 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 1, 0, 1, 0};	
					end
					default: begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0};	
						fill_dqs_pre_q();				
					end
				endcase
			end				
		end
		4 : begin							//If tCCD = BL/2 + 4
			if (rsp_item.read_post_amble) begin
				case (rsp_item.read_pre_amble)
					0 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0};	
						fill_dqs_pre_q();			
					end
					1 : begin
						Data_queue = {Data_queue, 0, 0};
						DQS_queue = {DQS_queue, 0, 0};	
						fill_dqs_pre_q();			
					end
					2 : begin
						Data_queue = {Data_queue, 0, 0};
						DQS_queue = {DQS_queue, 0, 0};	
						fill_dqs_pre_q();				
					end
					3 : begin
						fill_dqs_pre_q();				
					end
					4 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 1, 0, 1, 0};				
					end
					default: begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0};	
						fill_dqs_pre_q();				
					end
				endcase
			end	
			else begin
				case (rsp_item.read_pre_amble)
					0 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0, 0, 0};	
						fill_dqs_pre_q();			
					end
					1 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0};	
						fill_dqs_pre_q();			
					end
					2 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0};	
						fill_dqs_pre_q();				
					end
					3 : begin
						Data_queue = {Data_queue, 0, 0};
						DQS_queue = {DQS_queue, 0, 0};
						fill_dqs_pre_q();				
					end
					4 : begin
						fill_dqs_pre_q();				
					end
					default: begin
						Data_queue = {Data_queue, 0, 0, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0, 0, 0};	
						fill_dqs_pre_q();				
					end
				endcase
			end
		end
		5 : begin							//If tCCD = BL/2 + 5
			if (rsp_item.read_post_amble) begin
				case (rsp_item.read_pre_amble)
					0 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0, 0, 0};	
						fill_dqs_pre_q();			
					end
					1 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0};	
						fill_dqs_pre_q();			
					end
					2 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0};	
						fill_dqs_pre_q();				
					end
					3 : begin
						Data_queue = {Data_queue, 0, 0};
						DQS_queue = {DQS_queue, 0, 0};
						fill_dqs_pre_q();				
					end
					4 : begin
						fill_dqs_pre_q();		
					end
					default: begin
						Data_queue = {Data_queue, 0, 0, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0, 0, 0};	
						fill_dqs_pre_q();				
					end
				endcase	
			end	
			else begin
				case (rsp_item.read_pre_amble)
					0 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0, 0, 0, 0, 0};	
						fill_dqs_pre_q();			
					end
					1 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0, 0, 0};	
						fill_dqs_pre_q();			
					end
					2 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0, 0, 0};	
						fill_dqs_pre_q();				
					end
					3 : begin
						Data_queue = {Data_queue, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0};
						fill_dqs_pre_q();				
					end
					4 : begin
						Data_queue = {Data_queue, 0, 0};
						DQS_queue = {DQS_queue, 0, 0};
						fill_dqs_pre_q();				
					end
					default: begin
						Data_queue = {Data_queue, 0, 0, 0, 0, 0, 0, 0, 0};
						DQS_queue = {DQS_queue, 0, 0, 0, 0, 0, 0, 0, 0};	
						fill_dqs_pre_q();				
					end
				endcase
			end				
		end
		default : begin
			//Do nothing		
		end
	endcase
endtask


task dram_resp_seq::calc_rd_gap();
	if ((gap_flag) && ((rsp_item.CMD == RD) || (rsp_item.CMD == MRR))) begin		//second time
		gap_flag=2;
	end
	else if ((rsp_item.CMD == RD) || (rsp_item.CMD == MRR)) begin
		gap_flag=1;
	end

	if (gap_flag)	begin
		gap_counter=gap_counter + 1;
		
	end
	else	gap_counter=0;

	if (gap_flag == 2) begin 
		gap_q.push_back(gap_counter);
		gap_flag=1;
		gap_counter=0;
	end
endtask





task dram_resp_seq::drive_MRR();

	if (rsp_item.CMD == MRR) begin			//MRR
		DQS_queue = {DQS_queue, 0, 0, 0, 0, 0, 0, 0, 0};

		Data_queue =   {Data_queue, 
				8'b10101010,
				8'b10101010,
				8'b10101010,
				8'b10101010,
				{!rsp_item.MR[rsp_item.MRA][0],
				rsp_item.MR[rsp_item.MRA][0],
				!rsp_item.MR[rsp_item.MRA][0],
				rsp_item.MR[rsp_item.MRA][0],
				!rsp_item.MR[rsp_item.MRA][1],
				rsp_item.MR[rsp_item.MRA][1],
				!rsp_item.MR[rsp_item.MRA][1],
				rsp_item.MR[rsp_item.MRA][1]
				},		
				{!rsp_item.MR[rsp_item.MRA][2],
				rsp_item.MR[rsp_item.MRA][2],
				!rsp_item.MR[rsp_item.MRA][2],
				rsp_item.MR[rsp_item.MRA][2],
				!rsp_item.MR[rsp_item.MRA][3],
				rsp_item.MR[rsp_item.MRA][3],
				!rsp_item.MR[rsp_item.MRA][3],
				rsp_item.MR[rsp_item.MRA][3]
				},	
				{!rsp_item.MR[rsp_item.MRA][4],
				rsp_item.MR[rsp_item.MRA][4],
				!rsp_item.MR[rsp_item.MRA][4],
				rsp_item.MR[rsp_item.MRA][4],
				!rsp_item.MR[rsp_item.MRA][5],
				rsp_item.MR[rsp_item.MRA][5],
				!rsp_item.MR[rsp_item.MRA][5],
				rsp_item.MR[rsp_item.MRA][5]
				},
				{!rsp_item.MR[rsp_item.MRA][6],
				rsp_item.MR[rsp_item.MRA][6],
				!rsp_item.MR[rsp_item.MRA][6],
				rsp_item.MR[rsp_item.MRA][6],
				!rsp_item.MR[rsp_item.MRA][7],
				rsp_item.MR[rsp_item.MRA][7],
				!rsp_item.MR[rsp_item.MRA][7],
				rsp_item.MR[rsp_item.MRA][7]
				}
		};
	end
endtask