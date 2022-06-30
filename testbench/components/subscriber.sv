
class subscriber extends uvm_subscriber#(ddr_sequence_item);	
    `uvm_component_utils(subscriber)

    uvm_analysis_imp_port_mc     #(ddr_sequence_item, subscriber) mc_analysis_imp;
    uvm_analysis_imp_port_dram   #(ddr_sequence_item, subscriber) dram_analysis_imp;
    ddr_sequence_item                                             dfi_sequence_item_coverage;
    ddr_sequence_item                                             jedec_sequence_item_coverage;
    ddr_sequence_item                                             dfi_sequence_item_handle;
    ddr_sequence_item                                             jedec_sequence_item_handle;
    ddr_sequence_item                                             jedec_complete_sequence_item;
    ddr_sequence_item                                             dfi_complete_sequence_item;
    
    //Syncronization events for receiving a complete transaction (CMD + data) 
    event dfi_transaction_complete, jedec_transaction_complete;
    //==========================================================================//
    //                      Queues to fill before sampling                      //
    //==========================================================================//
    static ddr_sequence_item     jedec_completeItem_q      [$];
    static ddr_sequence_item     jedec_commandThread_q     [$];
    static ddr_sequence_item     dfi_commandThread_q       [$];
    static ddr_sequence_item     dfi_completeItem_q        [$];
    //==========================================================================//
    //            The number of data cycles of the previous read command        //
    //==========================================================================//
    static int  number_of_data_cycles_of_previous_read;        // with respect to the sampling event
	static bit first_RD_flag = 1;

    //======================================================================================================//
    //                                  START of covergroup definitions                                     //
    //======================================================================================================//
    //==========================================================================//
    //                              JEDEC Coverage                              //
    //==========================================================================//

    covergroup JEDEC_coverage;
        type_option.comment = "Coverage model for the JEDEC features";
        //=================================================================================//
        // Creating coverpoints that will be used to construct the required cross cross    //
        //   (these coverpoints do NOT contribute to the total coverage calculations)      //
        //=================================================================================//
        CMD_cp: coverpoint jedec_sequence_item_coverage.CMD {
            type_option.weight = 0;                 // only sampled to be used in the cross statement 
            bins MRR = {MRR};
            bins MRW = {MRW};
            bins ACT = {ACT};
            bins RD = {RD};
            }
        MRA_cp: coverpoint jedec_sequence_item_coverage.MRA {
            type_option.weight = 0;     // only sampled to be used in the cross statement 
            bins MR0 = {8'h00};         // Burst Length & CAS Latency (RL)
            bins MR8 = {8'h08};         // Read pre- and post- amble Settings
            // CRC MR is not used because it is not supported in the current design
        }
        actual_burst_length_cp: coverpoint jedec_sequence_item_coverage.actual_burst_length {
            type_option.weight = 0;     // only sampled to be used in the cross statement
            // 3 bins are created automatically with the following values: BL16, BC8_OTF, BL32
            }
        burst_length_cp: coverpoint jedec_sequence_item_coverage.burst_length {
            type_option.weight = 0;     // only sampled to be used in the cross statement 
            // 3 bins are created automatically with the following values: BL16, BC8_OTF, BL32
            }
        read_pre_amble_cp: coverpoint jedec_sequence_item_coverage.read_pre_amble {
            type_option.weight = 0;     // only sampled to be used in the cross statement 
            bins read_pre_amble_Val [] = {[3'b000:3'b100]};        // 5 seperate bins are created
            }
        read_post_amble_cp: coverpoint jedec_sequence_item_coverage.read_post_amble {
            type_option.weight = 0;     // only sampled to be used in the cross statement 
            // 2 bins are created automatically 
            }
        command_cancel_cp: coverpoint jedec_sequence_item_coverage.command_cancel{
            type_option.weight = 0;     // only sampled to be used in the cross statement 
            // 2 bins are created automatically
            bins no_cancel  = {0};
            bins cancel     = {1};
        }
        OP_BL_cp: coverpoint jedec_sequence_item_coverage.OP[1:0] {
            type_option.weight = 0;     // only sampled to be used in the cross statement 
            // 4 bins are created automatically with the following values: 
            // 'b00: BL16, 'b01: BC8_OTF, 'b10: BL32
            ignore_bins exclude_BL32_OTF = {3};
        }  
        OP_read_pre_amble_cp: coverpoint jedec_sequence_item_coverage.OP[2:0] {
            type_option.weight = 0;     // only sampled to be used in the cross statement 
            bins read_pre_amble_Val [] = {[3'b000:3'b100]};        // 5 seperate bins are created
        }  
        OP_read_post_amble_cp: coverpoint jedec_sequence_item_coverage.OP[6] {
            type_option.weight = 0;     // only sampled to be used in the cross statement 
            // 2 bins are created automatically 
        }
        interamble_cp: coverpoint jedec_sequence_item_coverage.number_of_cycles_between_RD - number_of_data_cycles_of_previous_read {
            type_option.weight = 0;     // only sampled to be used in the cross statement 
            bins tCCD_min           = {0};
            bins tCCD_minPlusOne    = {1};
            bins tCCD_minPlusTwo    = {2};
            bins tCCD_minPlusThree  = {3};
            bins tCCD_minPlusFour   = {4};
            bins tCCD_minPlusFive   = {5};
        }

        //=================================================================================//
        // JEDEC_DR_4: The MRR has a command burst length 16 regardless of the MR0 setting //
        //=================================================================================//
        JEDEC_DR_4_cross: cross CMD_cp, actual_burst_length_cp, burst_length_cp {
            type_option.comment = "Coverage model for features JEDEC_DR_4"; 
            // included bins: binsof(CMD_cp.MRR) with (actual_burst_length_cp == BL16)
            illegal_bins ill = binsof(CMD_cp.MRR) with (actual_burst_length_cp != BL16);        // illegal_bins have higher priority than ignored_bins
            ignore_bins excluded_JEDEC_DR_4_bins = !binsof(CMD_cp.MRR);
            }

        //=================================================================================//
        // JEDEC_DR_6: The read pre-amble and post-amble of MRR are same as normal read    //
        //=================================================================================//
        JEDEC_DR_6_part1_cross: cross CMD_cp, read_pre_amble_cp {   // could be: cross CMD_cp, read_pre_amble_cp, read_post_amble_cp;   to accommodate for all pre and post combinations
            type_option.comment = "Coverage model for features JEDEC_DR_6_part1";
            ignore_bins excluded_JEDEC_DR_6_part1_bins = ! binsof(CMD_cp.MRR);
            }
        JEDEC_DR_6_part2_cross: cross CMD_cp, read_post_amble_cp {
            type_option.comment = "Coverage model for features JEDEC_DR_6_part2";
            ignore_bins excluded_JEDEC_DR_6_part2_bins = ! binsof(CMD_cp.MRR);
            }

        //=================================================================================//
        // JEDEC_DR_18: The DRAM will not execute these 2-cycle commands if the CS_n is    //
        //              LOW on the 2nd cycle (command cancel).                             //
        //=================================================================================//
        JEDEC_DR_18_cross: cross CMD_cp, command_cancel_cp {
            type_option.comment = "Coverage model for features JEDEC_DR_18";
            // included bins: binsof(CMD_cp.MRW) || binsof(CMD_cp.ACT) 
            ignore_bins excluded_JEDEC_DR_18_bins = !binsof(CMD_cp.MRW) && !binsof(CMD_cp.ACT);
        }
        //=======================================================================================//
        // JEDEC_DR_25_and_26: In Read to Read operations with tCCD=BL/2, postamble for 1st      //
        //                     command and preamble for 2nd command shall disappear to create    //
        //                     consecutive DQS latching edge for seamless burst operations.      //
        //                     In the case of Read to Read operations with command interval of   //
        //                     tCCD+1, tCCD+2, etc., if the postamble and preambles overlap,     //
        //                     the toggles take precedence over static preambles.                //
        //=======================================================================================//
        JEDEC_DR_25_and_26_cross: cross interamble_cp, OP_read_pre_amble_cp, OP_read_post_amble_cp iff ( (jedec_sequence_item_coverage.CMD == RD) && (first_RD_flag == 0) ) {
            // (first_RD_flag == 0) is used for the corner case of the first RD command
            type_option.comment = "Coverage model for features JEDEC_DR_25_and_26";
        }

        // the following features cover that: 
        // Part (1): all mode registers have been written into and read from using all possible values (Using MRW and MRR commands).
        // Part (2): all these values of the mode registers have been used by using RD command.

        // Part (1)
        //=================================================================================//
        //                 JEDEC_DR_8: MRW and MRR to all supported MRA                    //
        //=================================================================================//
        JEDEC_DR_8_cross: cross MRA_cp, CMD_cp iff (!jedec_sequence_item_coverage.command_cancel) {
            type_option.comment = "Coverage model for features JEDEC_DR_8"; 
            // included bins: binsof(CMD_cp.MRW) || binsof(CMD_cp.MRR) 
            ignore_bins excluded_JEDEC_DR_8_bins = !binsof(CMD_cp.MRW) && !binsof(CMD_cp.MRR);
        }

        //=======================================================================================//
        // JEDEC_DR_14: all burst length values are written and read from the mode register      //
        //=======================================================================================//
        JEDEC_DR_14_cross: cross MRA_cp, OP_BL_cp, CMD_cp iff (!jedec_sequence_item_coverage.command_cancel) {
            type_option.comment = "Coverage model for features JEDEC_DR_14";
            // included bins: (binsof(CMD_cp.MRW) || binsof(CMD_cp.MRR)) && binsof(MRA_cp.MR0) 
            ignore_bins excluded_JEDEC_DR_14_bins =  (!binsof(CMD_cp.MRW) && !binsof(CMD_cp.MRR)) || !binsof(MRA_cp.MR0) ;
        }

        //===============================================================================================//
        // JEDEC_DR_15: all pre- and post- amble values are written and read from the mode register      //
        //===============================================================================================//
        JEDEC_DR_15_part1_cross: cross MRA_cp, OP_read_pre_amble_cp, CMD_cp iff (!jedec_sequence_item_coverage.command_cancel) {
            type_option.comment = "Coverage model for features JEDEC_DR_15_part1";
            // included bins: (binsof(CMD_cp.MRW) || binsof(CMD_cp.MRR)) && binsof(MRA_cp.MR8) 
            ignore_bins excluded_JEDEC_DR_15_part1_bins =  (!binsof(CMD_cp.MRW) && !binsof(CMD_cp.MRR)) || !binsof(MRA_cp.MR8) ;
        }
        JEDEC_DR_15_part2_cross: cross MRA_cp, OP_read_post_amble_cp, CMD_cp iff (!jedec_sequence_item_coverage.command_cancel) {
            type_option.comment = "Coverage model for features JEDEC_DR_15_part2";
            // included bins: (binsof(CMD_cp.MRW) || binsof(CMD_cp.MRR)) && binsof(MRA_cp.MR8) 
            ignore_bins excluded_JEDEC_DR_15_part2_bins =  (!binsof(CMD_cp.MRW) && !binsof(CMD_cp.MRR)) || !binsof(MRA_cp.MR8) ;
        }

        // Part (2)
        //=================================================================================//
        // JEDEC_DR_31: when BL_mod != 1, DDR5 shall support BC8, BL16, BL32 (optional)    //
        //              and BL32 OTF (optional) during a READ or WRITE command.            //
        //              MR0[1:0] is used to select burst operation mode.                   //
        //=================================================================================//
        JEDEC_DR_31_cross: cross CMD_cp, actual_burst_length_cp {
            type_option.comment = "Coverage model for features JEDEC_DR_31"; 
            // included bins: binsof(CMD_cp.RD)
            ignore_bins excluded_JEDEC_DR_31_bins = ! binsof(CMD_cp.RD);
        }

        //=================================================================================//
        // JEDEC_DR_32: In non-CRC mode, DQS_t and DQS_c stop toggling at the completion   //
        //              of the BC8 data bursts, plus the postamble.                        //
        //=================================================================================//
        JEDEC_DR_32_part1_cross: cross CMD_cp, read_pre_amble_cp {
            type_option.comment = "Coverage model for features JEDEC_DR_32_part1";
            // included bins: binsof(CMD_cp.RD)
            ignore_bins excluded_JEDEC_DR_32_part1_bins = ! binsof(CMD_cp.RD);
        }
        JEDEC_DR_32_part2_cross: cross CMD_cp, read_post_amble_cp {
            type_option.comment = "Coverage model for features JEDEC_DR_32_part2"; 
            // included bins: binsof(CMD_cp.RD)
            ignore_bins excluded_JEDEC_DR_32_part2_bins = ! binsof(CMD_cp.RD);
        }

    endgroup: JEDEC_coverage

    covergroup JEDEC_transitions;
        //=================================================================================//
        //                               JEDEC_DR_7_and_10                                 //
        //=================================================================================//        
        JEDEC_DR_7_and_10_cp: coverpoint jedec_sequence_item_coverage.CMD {   // note this coverpoint has a weight in the total coverage calculations
            type_option.comment = "Coverage model for features JEDEC_DR_7_and_10";
            // JEDEC_DR_7
            bins JEDEC_DR_7  =  (MRR => MRR => MRW),
                                (MRR => MRR => ACT);
            // JEDEC_DR_10
            bins JEDEC_DR_10 =  (MRW => MRW => MRR),
                                (MRW => MRW => ACT);
            // these bins are hit for the following sequences (with no command cancel in the sequence):
            // MRR => DES [indefinite repetition] => MRR => DES [indefinite repetition] => MRW      
            // MRR => DES [indefinite repetition] => MRR => DES [indefinite repetition] => ACT
            // MRW => DES [indefinite repetition] => MRW => DES [indefinite repetition] => MRR
            // MRW => DES [indefinite repetition] => MRW => DES [indefinite repetition] => ACT
            // why is there indefinite repetition for DES command? because the monitors do not send the DES command transaction.
            }
        
    endgroup : JEDEC_transitions

    //==========================================================================//
    //                              DFI Coverage                                //
    //==========================================================================//

    covergroup DFI_coverage;
        type_option.comment = "Coverage model for the DFI features";
        //=================================================================================//
        // Creating coverpoints that will be used to construct the required cross cross    //
        //   (these coverpoints do NOT contribute to the total coverage calculations)      //
        //=================================================================================//
        CMD_cp: coverpoint dfi_sequence_item_coverage.CMD {
            type_option.weight = 0;     // only sampled to be used in the cross statement
            bins MRW = {MRW};
            bins MRR = {MRR};
            bins ACT = {ACT};
            bins RD = {RD};
        }
        command_cancel_cp: coverpoint dfi_sequence_item_coverage.command_cancel{
            type_option.weight = 0;     // only sampled to be used in the cross statement
        }
        MRA_cp: coverpoint dfi_sequence_item_coverage.MRA {
            type_option.weight = 0;     // only sampled to be used in the cross statement
            bins MR0 = {8'h00};         // Burst Length & CAS Latency (RL)
            bins MR8 = {8'h08};         // Read pre- and post- amble Settings
            // CRC MR is not used because it is not supported in the current design
        }
        CW_cp: coverpoint dfi_sequence_item_coverage.CW {
            type_option.weight = 0;     // only sampled to be used in the cross statement
            // 2 bins are created automatically
        }
        AP_cp: coverpoint dfi_sequence_item_coverage.AP {
            type_option.weight = 0;     // only sampled to be used in the cross statement
        }
        BL_mod_cp: coverpoint dfi_sequence_item_coverage.BL_mod {
            type_option.weight = 0;     // only sampled to be used in the cross statement
        }
        BA_cp: coverpoint dfi_sequence_item_coverage.BA {
            type_option.weight = 0;             // only sampled to be used in the cross statement
            bins BA [] = {0, 2**2-1};           // first and last bank address
        }
        BG_cp: coverpoint dfi_sequence_item_coverage.BG {
            type_option.weight = 0;             // only sampled to be used in the cross statement
            bins BG [] = {0, 2**3-1};           // first and last bank group
        }
        CID_cp: coverpoint dfi_sequence_item_coverage.CID {
            type_option.weight = 0;             // only sampled to be used in the cross statement
            bins CID [] = {0, 2**4-1};         // first and last CID
        }
        ROW_cp: coverpoint dfi_sequence_item_coverage.ROW {
            type_option.weight = 0;             // only sampled to be used in the cross statement
            bins rows [] = {0, 2**18-1};        // first and last row
        }
        Col_cp: coverpoint dfi_sequence_item_coverage.Col {
            type_option.weight = 0;             // only sampled to be used in the cross statement
            bins columns [] = {0, 2**9-1};      // first and last columns
        }

        //===============================================================================================//
        //                             two_cycle_command_cancel feature                                  //
        //===============================================================================================//
        two_cycle_command_cancel_cross: cross CMD_cp, command_cancel_cp{
            type_option.comment = "Coverage model for two_cycle_command_cancel feature"; 
            // included bins: binsof(CMD_cp.MRW) || binsof(CMD_cp.ACT)
            ignore_bins two_cycle_command_cancel_bins = !binsof(CMD_cp.MRW) && !binsof(CMD_cp.ACT);
        }

        //===============================================================================================//
        //       All supported mode registers are written into and read from using MRW and MRR           //
        //===============================================================================================//
        mode_register_cross: cross MRA_cp, CW_cp, CMD_cp iff (!dfi_sequence_item_coverage.command_cancel) {
            type_option.comment = "Coverage model for MRW & MRR to all supported mode registers";
            // included bins: binsof(CMD_cp.MRW) || binsof(CMD_cp.MRR)
            ignore_bins excluded_mode_register_bins = !binsof(CMD_cp.MRW) && !binsof(CMD_cp.MRR);
        }

        //===============================================================================================//
        //                             Automatic precharge after RD feature                              //
        //===============================================================================================//
        AP_cross: cross CMD_cp, AP_cp {
            type_option.comment = "Coverage model for Automatic precharge feature"; 
            // included bins: binsof(CMD_cp.RD)
            ignore_bins excluded_AP_bins = ! binsof(CMD_cp.RD);
        }

        //===============================================================================================//
        //                                     BL_mod of RD feature                                      //
        //===============================================================================================//
        BL_mod_cross: cross CMD_cp, BL_mod_cp {
            type_option.comment = "Coverage model for BL_mod of RD feature"; 
            // included bins: binsof(CMD_cp.RD)
            ignore_bins excluded_BL_mod_bins = ! binsof(CMD_cp.RD);
        }
        
        //===============================================================================================//
        //                                          Address corners                                      //
        //===============================================================================================//
        BA_cross: cross BA_cp, CMD_cp iff (!dfi_sequence_item_coverage.command_cancel) {
            type_option.comment = "Coverage model for BA corners";
            // included bins: binsof(CMD_cp.ACT) || binsof(CMD_cp.RD)
            ignore_bins excluded_BA_bins = !binsof(CMD_cp.ACT) && !binsof(CMD_cp.RD);
        }
        BG_cross: cross BG_cp, CMD_cp iff (!dfi_sequence_item_coverage.command_cancel) {
            type_option.comment = "Coverage model for BG corners";
            // included bins: binsof(CMD_cp.ACT) || binsof(CMD_cp.RD)
            ignore_bins excluded_BG_bins = !binsof(CMD_cp.ACT) && !binsof(CMD_cp.RD);
        }
        CID_cross: cross CID_cp, CMD_cp iff (!dfi_sequence_item_coverage.command_cancel) {
            type_option.comment = "Coverage model for CID corners";
            // included bins: binsof(CMD_cp.ACT) || binsof(CMD_cp.RD)
            ignore_bins excluded_CID_bins = !binsof(CMD_cp.ACT) && !binsof(CMD_cp.RD);
        }
        ROW_cross: cross ROW_cp, CMD_cp iff (!dfi_sequence_item_coverage.command_cancel) {
            type_option.comment = "Coverage model for ROW corners";
            // included bins: binsof(CMD_cp.ACT)
            ignore_bins excluded_ROW_bins = ! binsof(CMD_cp.ACT);
        }
        Col_cross: cross CMD_cp, Col_cp {
            type_option.comment = "Coverage model for Col corners";
            // included bins: binsof(CMD_cp.RD)
            ignore_bins excluded_Col_bins = ! binsof(CMD_cp.RD);
        }

    endgroup : DFI_coverage

    covergroup DFI_transitions;
        CMD_cp: coverpoint dfi_sequence_item_coverage.CMD {
            bins sequence1   = (ACT => RD);
            // this bin is hit for the following sequence:
            // ACT => DES [indefinite repetition] => RD
            // why is there indefinite repetition for DES command? because the monitors do not send the DES command transaction.
        }

    endgroup : DFI_transitions

    //======================================================================================================//
    //                                  END of covergroup definitions                                       //
    //======================================================================================================//

    function new (string name = "subscriber", uvm_component parent = null);
        super.new(name,parent);
        DFI_coverage        = new ();
        DFI_transitions     = new ();
        JEDEC_coverage      = new ();
        JEDEC_transitions   = new ();
    endfunction : new

    //==========================================================================//
    //                          Build Phase                                     //
    //==========================================================================//
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        mc_analysis_imp     = new("mc_analysis_imp",this);
        dram_analysis_imp   = new("dram_analysis_imp",this);
	`uvm_info("Build_Phase", "*************** 'subscriber' Build Phase ***************", UVM_HIGH)
    endfunction : build_phase

    //==========================================================================//
    //                        Connect Phase                                     //
    //==========================================================================//
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
	`uvm_info("Connect_phase", "*************** 'subscriber' Connect Phase ***************", UVM_HIGH)
    endfunction : connect_phase

    //==========================================================================//
    //                            Run Phase                                     //
    //==========================================================================//
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
        begin
            forever begin
                @(dfi_transaction_complete); // MC Received read data, comes after got_jedec_stimulus.triggered 
                        // $display("data_array = %p, at %t", jedec_stimulus_q[0].jedec_rddata_queue ,$time);
                dfi_sequence_item_coverage = dfi_completeItem_q.pop_front();
                DFI_coverage.sample();
                if (! dfi_sequence_item_coverage.command_cancel) DFI_transitions.sample();                
            end
        end
        begin
            forever begin
                @(jedec_transaction_complete); //DRAM Recieved command, comes after got_dfi_stimulus.triggered
                jedec_sequence_item_coverage = jedec_completeItem_q.pop_front();
                JEDEC_coverage.sample();
                if (! jedec_sequence_item_coverage.command_cancel) JEDEC_transitions.sample();

                // the number of data cycles of the previous read command with respect to the sampling event
                if (jedec_sequence_item_coverage.CMD == RD) begin
                    if (first_RD_flag)      first_RD_flag = 0;   // This flag marks the first RD command is issued.

                    case (jedec_sequence_item_coverage.actual_burst_length)
                        BL16: 		number_of_data_cycles_of_previous_read = 8;      // BL16: 8 Clock cycles
                        BC8_OTF: 	number_of_data_cycles_of_previous_read = 4;      // BC8 OTF: 4 Clock cycles
                        BL32: 		number_of_data_cycles_of_previous_read = 16;      // BL32: 16 Clock cycles
                    endcase 
                end

            end     
        end
        join
    endtask : run_phase

    extern function void write_port_mc (ddr_sequence_item item);			//write implementation for the mc port 
    extern function void write_port_dram (ddr_sequence_item item);	    //write implementation for the dram port 


    function void write (ddr_sequence_item t);			// the built-in write function; NOT used 
    endfunction : write

endclass : subscriber

    function void subscriber::write_port_mc (ddr_sequence_item item);			//write implementation for the mc port 
	`uvm_info("write_port_mc", "*************** Hello from write_port_mc ***************", UVM_DEBUG)
        `uvm_info("write_port_mc", $sformatf("dfi_item1.CMD = %p, at %t", item.CMD ,$time), UVM_DEBUG) 

        dfi_sequence_item_handle = ddr_sequence_item::type_id::create("dfi_sequence_item_handle");
                // $display("before copy: CMD = %p, at %t", item.CMD ,$time);
                // $display("before copy: OP = %p, at %t", item.OP ,$time);
        dfi_sequence_item_handle.copy(item);
                // $display("after copy: CMD = %p, at %t", dfi_sequence_item_handle.CMD ,$time);
                // $display("after copy: OP = %p, at %t", dfi_sequence_item_handle.OP ,$time);

        if(dfi_sequence_item_handle.is_data_only) begin
            dfi_complete_sequence_item                   = dfi_commandThread_q.pop_front();
            dfi_complete_sequence_item.dfi_rddata_queue  = dfi_sequence_item_handle.dfi_rddata_queue;
            dfi_completeItem_q.push_back(dfi_complete_sequence_item);
            `uvm_info("DFI data thread", {"item.dfi_rddata_queue"}, UVM_DEBUG);
            ->dfi_transaction_complete;
        end
        else begin
                    // $display("before pushing: CMD = %p, at %t", dfi_sequence_item_handle.CMD ,$time);
                    // $display("before pushing: OP = %p, at %t", dfi_sequence_item_handle.OP ,$time);
            if ( (dfi_sequence_item_handle.CMD != MRR ) && (dfi_sequence_item_handle.CMD != RD ) ) begin
                    dfi_complete_sequence_item = dfi_sequence_item_handle;
                    dfi_completeItem_q.push_back(dfi_complete_sequence_item);
                    ->dfi_transaction_complete;
            end else begin
                dfi_commandThread_q.push_back(dfi_sequence_item_handle);
            end
            `uvm_info("DFI command thread", {"item.CMD"}, UVM_DEBUG);
                    // $display("after pushing: CMD = %p, at %t", dfi_sequence_item_handle.CMD ,$time);
                    // $display("after pushing: OP = %p, at %t", dfi_sequence_item_handle.OP ,$time);
        end
    endfunction : write_port_mc

    function void subscriber::write_port_dram (ddr_sequence_item item);	//write implementation for the dram port 
       `uvm_info("write_port_dram", "*************** Hello from write_port_dram ***************", UVM_DEBUG)

        jedec_sequence_item_handle = ddr_sequence_item::type_id::create("jedec_sequence_item_handle");
                // $display("before copy: CMD = %p, at %t", item.CMD ,$time);
                // $display("before copy: OP = %p, at %t", item.OP ,$time);
        jedec_sequence_item_handle.copy(item);
                // $display("after copy: CMD = %p, at %t", jedec_sequence_item_handle.CMD ,$time);
                // $display("after copy: OP = %p, at %t", jedec_sequence_item_handle.OP ,$time);

        if(jedec_sequence_item_handle.is_data_only) begin
            jedec_complete_sequence_item                     = jedec_commandThread_q.pop_front();
            jedec_complete_sequence_item.jedec_rddata_queue  = jedec_sequence_item_handle.jedec_rddata_queue;
            
            if (jedec_complete_sequence_item.CMD == MRR) 
                jedec_complete_sequence_item.OP  = jedec_sequence_item_handle.OP;

            jedec_complete_sequence_item.actual_burst_length = jedec_sequence_item_handle.actual_burst_length;
            jedec_completeItem_q.push_back(jedec_complete_sequence_item);
            `uvm_info("JEDEC data thread", {"item.jedec_rddata_queue"}, UVM_HIGH);
                    // $display("data_array = %p, at %t", jedec_sequence_item_handle.jedec_rddata_queue ,$time);
            ->jedec_transaction_complete;
        end
        else begin
                    // $display("before pushing: CMD = %p, at %t", jedec_sequence_item_handle.CMD ,$time);
                    // $display("before pushing: OP = %p, at %t", jedec_sequence_item_handle.OP ,$time);
            if ( (jedec_sequence_item_handle.CMD != MRR ) && (jedec_sequence_item_handle.CMD != RD ) ) begin
                    jedec_complete_sequence_item = jedec_sequence_item_handle;
                    jedec_completeItem_q.push_back(jedec_complete_sequence_item);
                    ->jedec_transaction_complete;
            end else begin
                jedec_commandThread_q.push_back(jedec_sequence_item_handle);
            end
            `uvm_info("JEDEC command thread", {"item.CMD"}, UVM_HIGH);
                    // $display("after pushing: CMD = %p, at %t", jedec_sequence_item_handle.CMD ,$time);
                    // $display("after pushing: OP = %p, at %t", jedec_sequence_item_handle.OP ,$time);
        end
    endfunction : write_port_dram
