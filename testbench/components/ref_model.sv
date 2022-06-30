

class ref_model extends uvm_component;
    `uvm_component_utils(ref_model)

        //**********TLM -- Revieving the DFI & JEDEC items from the analysis ports of MC and DRAM agents.
        uvm_analysis_imp_port_mc     #(ddr_sequence_item, ref_model)   mc_analysis_imp;
        uvm_analysis_imp_port_dram   #(ddr_sequence_item, ref_model) dram_analysis_imp;

	//**********TLM -- Broadcasting the result of the model
	uvm_analysis_port#(ddr_sequence_item)        dfi_REF_analysis_port;
	uvm_analysis_port#(ddr_sequence_item)      jedec_REF_analysis_port;
	
	//**********Two internal items to copy the incoming items in them
	ddr_sequence_item 		dfi_item, dfi_item_to_scbd; //Copy incoming item in dfi_item, while dfi_item_to_scbd is used to send a "processed jedec item" to the scbd.
	ddr_sequence_item		jedec_item, jedec_item_to_scbd;

	//**************An event to make sure the items are copied before the "run phase" operates on the items
	//event recieved_dfi_item;
	static int recieved_dfi_item_flag=0;
	static int recieved_jedec_item_flag=0;
	
        //*************Constructor
        function new (string name = "ref_model", uvm_component parent = null);
                super.new(name,parent);
        endfunction : new
                
        //****************Build Phase
        function void build_phase (uvm_phase phase);
                super.build_phase(phase);
                jedec_item_to_scbd      = ddr_sequence_item::type_id::create("jedec_item_to_scbd");
                dfi_item_to_scbd        = ddr_sequence_item::type_id::create("dfi_item_to_scbd");
                mc_analysis_imp         = new("mc_analysis_imp",this);
                dram_analysis_imp       = new("dram_analysis_imp",this);
                dfi_REF_analysis_port   = new("dfi_REF_analysis_port",this);
                jedec_REF_analysis_port = new("jedec_REF_analysis_port",this);
		`uvm_info("Build_Phase", "*************** 'ref_model' Build Phase ***************", UVM_HIGH)
        endfunction : build_phase

        //****************Connect Phase
        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);
		`uvm_info("Connect_phase", "*************** 'ref_model' Connect Phase ***************", UVM_HIGH)
        endfunction : connect_phase

        //*****************Run Phase                                     
        task run_phase(uvm_phase phase);
                super.run_phase(phase);
                /*forever 
                begin
                        //***********Operate on the items - thread for each item (just in case they come simultaneously)
                        if(recieved_dfi_item_flag) 
                        begin
                                process_dfi_item(dfi_item);
                                recieved_dfi_item_flag  =0; //Deactivate the if statement until the write function is called again; i.e., new incoming transaction arrives		
                                jedec_REF_analysis_port.write(jedec_item_to_scbd);
                        $display("LOL 0");
                        end
                        $display("LOL 1");
                        if(recieved_jedec_item_flag) 
                        begin
                        $display("LOL 0");
                                process_jedec_item(jedec_item);
                                recieved_jedec_item_flag=0; //Deactivate the if statement until the write function is called again; i.e., new incoming transaction arrives
                                dfi_REF_analysis_port.write(dfi_item_to_scbd);
                        end
                end	*/ 
        endtask : run_phase
	
	//***************Write implementations -- copy the incoming items in the internal items to be processed
        function void write_port_mc (ddr_sequence_item item);           //write implementation for the mc port	
		$display("REF is Processing a DFI Item");
                dfi_item = ddr_sequence_item::type_id::create("dfi_item", this);
                dfi_item.copy(item);
		//-> recieved_dfi_item;
		//recieved_dfi_item_flag=1;
                process_dfi_item(dfi_item);
                //recieved_dfi_item_flag  =0; //Deactivate the if statement until the write function is called again; i.e., new incoming transaction arrives		
                jedec_REF_analysis_port.write(jedec_item_to_scbd);
	endfunction : write_port_mc

	function void write_port_dram (ddr_sequence_item item);       //write implementation for the dram port 
                //$display("REF is Processing a JEDEC Item");	
		jedec_item = ddr_sequence_item::type_id::create("jedec_item", this);
                jedec_item.copy(item);
		//-> recieved_jedec_item;
		//recieved_jedec_item_flag=1;
                process_jedec_item(jedec_item);
                //recieved_jedec_item_flag=0; //Deactivate the if statement until the write function is called again; i.e., new incoming transaction arrives
                dfi_REF_analysis_port.write(dfi_item_to_scbd);
                $display("Sending From REF to Scoreboard FIFO");
        endfunction : write_port_dram

	//***************Functions to process the seq items
	function void process_dfi_item(ddr_sequence_item dfi_item1);
                case (dfi_item1.CMD)
                        dfi_item1.ACT :	begin
                                dfi_address_2_CA();
                        end
                        dfi_item1.RD :	begin
                                dfi_address_2_CA();
                        end
                        dfi_item1.MRW :	begin
                                dfi_address_2_CA();
                        end
                        dfi_item1.MRR :	begin
                                dfi_address_2_CA();
                        end
                        dfi_item1.DES :	begin
                                dfi_address_2_CA();
                        end
                        default:	begin
                                //NOTHING
                        end
                endcase
	endfunction : process_dfi_item

        function void dfi_address_2_CA();
                //jedec_item_to_scbd.CMD          = dfi_item.CMD;
                jedec_item_to_scbd.BA           = dfi_item.BA;
                jedec_item_to_scbd.BG           = dfi_item.BG;
                jedec_item_to_scbd.CID          = dfi_item.CID;
                jedec_item_to_scbd.ROW          = dfi_item.ROW;
                jedec_item_to_scbd.Col          = dfi_item.Col;
                jedec_item_to_scbd.AP           = dfi_item.AP;
                jedec_item_to_scbd.BL_mod       = dfi_item.BL_mod;
                jedec_item_to_scbd.MRA          = dfi_item.MRA;
                jedec_item_to_scbd.OP           = dfi_item.OP;
                jedec_item_to_scbd.CW           = dfi_item.CW;
                jedec_item_to_scbd.command_cancel = dfi_item.command_cancel;
        endfunction : dfi_address_2_CA

	function void process_jedec_item(ddr_sequence_item jedec_item);
		dfi_item_to_scbd.dfi_rddata_queue = jedec_item.jedec_rddata_queue;
	endfunction : process_jedec_item

endclass : ref_model