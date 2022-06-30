`include "uvm_pkg.sv"
`include "tb_pkg.sv"
`include "interfaces/ddr_assertions.sv"
//RTL includes
`include "Serializer_V1.sv"
`include "CRC_Valid.sv"
`include "CA_Manager.sv"
`include "FSM_setting.sv"
`include "generic_FSM.sv"
`include "GapCounter.sv"
`include "CountCalc.sv"
`include "FIFO.sv"
`include "EdgeDetectorFSM.sv"
`include "pattern_detector.sv"
`include "ControlUnit.sv"
`include "ValidCounter.sv"
`include "top.sv"
`include "DataManager.sv"
`include "Deserializer_V1.sv"
`include "DDR5_PHY.sv"
`timescale 1ps/1ps


module top_testbench;
	import uvm_pkg::*;
	import tb_pkg::*;

	logic dfi_clk_i 	= 1;
	logic dfi_phy_clk_i 	= 1;

	dfi_intf 	dfi_if	  (dfi_clk_i);
	jedec_intf 	jedec_if  (dfi_phy_clk_i);

	parameter DFI_CLK_PERIOD = 800;
	`ifdef ratio_1_to_1
		parameter PHY_CLK_PERIOD = DFI_CLK_PERIOD;
	`elsif ratio_1_to_2
		parameter PHY_CLK_PERIOD = DFI_CLK_PERIOD/2;
	`elsif ratio_1_to_4
		parameter PHY_CLK_PERIOD = DFI_CLK_PERIOD/4;
	`else 				
		parameter PHY_CLK_PERIOD = DFI_CLK_PERIOD;		//Default
	`endif 


	always #(DFI_CLK_PERIOD/2) dfi_clk_i		 = ~dfi_clk_i;
	always #(PHY_CLK_PERIOD/2) dfi_phy_clk_i	 = ~dfi_phy_clk_i; 		//TO BE Considered Freq_ratio

	DDR5_PHY #(
		// Prameters
		.Physical_Rank_No 		(1), 
		.device_width 			(4)
	) ddr_DUT (	
		// Inputs	
		.dfi_phy_clk_i			(dfi_phy_clk_i			),		//Fast clock
		.dfi_clk_i 			(dfi_clk_i			),		//Slow clock
		.reset_n_i			(dfi_if.reset_n_i		),
		.en_i				(dfi_if.en_i			),
		.phycrc_mode_i			(dfi_if.phycrc_mode_i		), 		//one if CRC implemented in PHY, zero if not
		.dfi_freq_ratio_i		(dfi_if.dfi_freq_ratio_i	), 		//freq ratio between MC and PHY supported ratios are 1x, 2x, 4x, not in the interface
		.dfi_address_p0			(dfi_if.dfi_address_p0		),
		.dfi_address_p1			(dfi_if.dfi_address_p1		),
		.dfi_address_p2			(dfi_if.dfi_address_p2		),
		.dfi_address_p3			(dfi_if.dfi_address_p3		),
		.dfi_cs_p0			(dfi_if.dfi_cs_p0		),
		.dfi_cs_p1			(dfi_if.dfi_cs_p1		),
		.dfi_cs_p2			(dfi_if.dfi_cs_p2		),
		.dfi_cs_p3			(dfi_if.dfi_cs_p3		),
		.dfi_rddata_en_p0		(dfi_if.dfi_rddata_en_p0	),
		.dfi_rddata_en_p1		(dfi_if.dfi_rddata_en_p1	),
		.dfi_rddata_en_p2		(dfi_if.dfi_rddata_en_p2	),
		.dfi_rddata_en_p3		(dfi_if.dfi_rddata_en_p3	),
		.DQS_AD_i			(jedec_if.DQS_AD_i		),		//data strobe
		.DQ_AD_i 			(jedec_if.DQ_AD_i 		),		//data bus
		 
		// Outputs 
		.dfi_alert_n_a0			(dfi_if.dfi_alert_n_a0		),	
		.dfi_alert_n_a1			(dfi_if.dfi_alert_n_a1		),	
		.dfi_alert_n_a2			(dfi_if.dfi_alert_n_a2		),	
		.dfi_alert_n_a3			(dfi_if.dfi_alert_n_a3		),	
		.dfi_rddata_valid_w0		(dfi_if.dfi_rddata_valid_w0	),
		.dfi_rddata_valid_w1		(dfi_if.dfi_rddata_valid_w1	),
		.dfi_rddata_valid_w2		(dfi_if.dfi_rddata_valid_w2	),
		.dfi_rddata_valid_w3		(dfi_if.dfi_rddata_valid_w3	),
		.dfi_rddata_w0			(dfi_if.dfi_rddata_w0		),	
		.dfi_rddata_w1			(dfi_if.dfi_rddata_w1		),	
		.dfi_rddata_w2			(dfi_if.dfi_rddata_w2		),	
		.dfi_rddata_w3			(dfi_if.dfi_rddata_w3		),	
		.CA_DA_o			(jedec_if.CA_DA_o		),
		.CS_DA_o			(jedec_if.CS_DA_o		),
		.CA_VALID_DA_o			(jedec_if.CA_VALID_DA_o		)
	);

	static  bit 		CRC_enable	= 0;
	static  bit	[2:0]	pre_amble 	= 3'b000;
	static  bit 	        post_amble 	= 0;
	static  byte	        RL 		= 8'd22;
	static  burst_length_t  burst_length 	= BL16;
	initial begin
		uvm_config_db #(virtual	dfi_intf  	)::set(null,"uvm_test_top","dfi_vif"	,dfi_if	 );
		uvm_config_db #(virtual jedec_intf	)::set(null,"uvm_test_top","jedec_vif"	,jedec_if);
		run_test();
	end

	initial begin
		fork
			forever begin
				uvm_config_db #(byte)::wait_modified(null, "*", "RL");
				if(!uvm_config_db#(byte)::get(null,"","RL",RL))
					`uvm_fatal("TOP","Error in getting RL from database!")
				$display("********************RL FROM TOP = %p",RL);
			end
			forever begin
				uvm_config_db #(burst_length_t)::wait_modified(null, "*", "burst_length");
				if(!uvm_config_db#(burst_length_t)::get(null,"","burst_length",burst_length))
					`uvm_fatal("TOP","Error in getting burst_length from database!")
				$display("********************BL FROM TOP = %p",burst_length);
			end
			forever begin
				uvm_config_db #(bit)::wait_modified(null, "*", "pre_amble");
				if(!uvm_config_db#(bit)::get(null,"","pre_amble",pre_amble))
					`uvm_fatal("TOP","Error in getting pre_amble from database!")
				//$display("********************Pre FROM TOP = %p",pre_amble);
			end
			forever begin
				uvm_config_db #(bit)::wait_modified(null, "*", "post_amble");
				if(!uvm_config_db#(bit)::get(null,"","post_amble",post_amble))
					`uvm_fatal("TOP","Error in getting post_amble from database!")
				//$display("********************POST FROM TOP = %p",post_amble);
			end
			forever begin
				uvm_config_db #(bit)::wait_modified(null, "*", "CRC_enable");
				if(!uvm_config_db#(bit)::get(null,"","CRC_enable",CRC_enable))
					`uvm_fatal("TOP","Error in getting CRC_enable from database!")
				//$display("********************CRC_enable FROM TOP = %p",CRC_enable);
			end
		join
	end



`ifdef assert_en
	ddr_assertions ddr_sva_inst (
		                // Inputs	
		                .dfi_phy_clk_i			(dfi_phy_clk_i			),		//Fast clock
		                .dfi_clk_i 				(dfi_clk_i			),		//Slow clock
		                .reset_n_i				(dfi_if.reset_n_i		),
		                .en_i					(dfi_if.en_i			),
		                .phycrc_mode_i			(dfi_if.phycrc_mode_i		), 		//one if CRC implemented in PHY, zero if not
		                .dfi_freq_ratio_i		(dfi_if.dfi_freq_ratio_i	), 		//freq ratio between MC and PHY supported ratios are 1x, 2x, 4x, not in the interface
		                .dfi_address_p0			(dfi_if.dfi_address_p0		),
		                .dfi_address_p1			(dfi_if.dfi_address_p1		),
		                .dfi_address_p2			(dfi_if.dfi_address_p2		),
		                .dfi_address_p3			(dfi_if.dfi_address_p3		),
		                .dfi_cs_p0				(dfi_if.dfi_cs_p0		),
		                .dfi_cs_p1				(dfi_if.dfi_cs_p1		),
		                .dfi_cs_p2				(dfi_if.dfi_cs_p2		),
		                .dfi_cs_p3				(dfi_if.dfi_cs_p3		),
		                .dfi_rddata_en_p0		(dfi_if.dfi_rddata_en_p0	),
		                .dfi_rddata_en_p1		(dfi_if.dfi_rddata_en_p1	),
		                .dfi_rddata_en_p2		(dfi_if.dfi_rddata_en_p2	),
		                .dfi_rddata_en_p3		(dfi_if.dfi_rddata_en_p3	),
		                .DQS_AD_i				(jedec_if.DQS_AD_i		),		//data strobe
		                .DQ_AD_i 				(jedec_if.DQ_AD_i 		),		//data bus
		                
		                // Outputs 
		                .dfi_alert_n_a0			(dfi_if.dfi_alert_n_a0		),	
		                .dfi_alert_n_a1			(dfi_if.dfi_alert_n_a1		),	
		                .dfi_alert_n_a2			(dfi_if.dfi_alert_n_a2		),	
		                .dfi_alert_n_a3			(dfi_if.dfi_alert_n_a3		),	
		                .dfi_rddata_valid_w0		(dfi_if.dfi_rddata_valid_w0	),
		                .dfi_rddata_valid_w1		(dfi_if.dfi_rddata_valid_w1	),
		                .dfi_rddata_valid_w2		(dfi_if.dfi_rddata_valid_w2	),
		                .dfi_rddata_valid_w3		(dfi_if.dfi_rddata_valid_w3	),
		                .dfi_rddata_w0			(dfi_if.dfi_rddata_w0		),	
		                .dfi_rddata_w1			(dfi_if.dfi_rddata_w1		),	
		                .dfi_rddata_w2			(dfi_if.dfi_rddata_w2		),	
		                .dfi_rddata_w3			(dfi_if.dfi_rddata_w3		),	
		                .CA_DA_o			(jedec_if.CA_DA_o		),
		                .CS_DA_o			(jedec_if.CS_DA_o		),
		                .CA_VALID_DA_o			(jedec_if.CA_VALID_DA_o		),
				.RL				(RL),
				.burst_length			(burst_length),
				.pre_amble			(pre_amble),
				.post_amble			(post_amble)
		                );
`endif



endmodule : top_testbench

//==========================================================================//
//                        Binding Assertions                                //
//==========================================================================//
/*
`ifdef assert_en
	bind top_testbench.ddr_DUT ddr_assertions ddr_sva_inst (
		                // Inputs	
		                .dfi_phy_clk_i			(dfi_phy_clk_i			),		//Fast clock
		                .dfi_clk_i 			(dfi_clk_i			),		//Slow clock
		                .reset_n_i			(dfi_if.reset_n_i		),
		                .en_i				(dfi_if.en_i			),
		                .phycrc_mode_i			(dfi_if.phycrc_mode_i		), 		//one if CRC implemented in PHY, zero if not
		                .dfi_freq_ratio_i		(dfi_if.dfi_freq_ratio_i	), 		//freq ratio between MC and PHY supported ratios are 1x, 2x, 4x, not in the interface
		                .dfi_address_p0			(dfi_if.dfi_address_p0		),
		                .dfi_address_p1			(dfi_if.dfi_address_p1		),
		                .dfi_address_p2			(dfi_if.dfi_address_p2		),
		                .dfi_address_p3			(dfi_if.dfi_address_p3		),
		                .dfi_cs_p0			(dfi_if.dfi_cs_p0		),
		                .dfi_cs_p1			(dfi_if.dfi_cs_p1		),
		                .dfi_cs_p2			(dfi_if.dfi_cs_p2		),
		                .dfi_cs_p3			(dfi_if.dfi_cs_p3		),
		                .dfi_rddata_en_p0		(dfi_if.dfi_rddata_en_p0	),
		                .dfi_rddata_en_p1		(dfi_if.dfi_rddata_en_p1	),
		                .dfi_rddata_en_p2		(dfi_if.dfi_rddata_en_p2	),
		                .dfi_rddata_en_p3		(dfi_if.dfi_rddata_en_p3	),
		                .DQS_AD_i			(jedec_if.DQS_AD_i		),		//data strobe
		                .DQ_AD_i 			(jedec_if.DQ_AD_i 		),		//data bus
		                
		                // Outputs 
		                .dfi_alert_n_a0			(dfi_if.dfi_alert_n_a0		),	
		                .dfi_alert_n_a1			(dfi_if.dfi_alert_n_a1		),	
		                .dfi_alert_n_a2			(dfi_if.dfi_alert_n_a2		),	
		                .dfi_alert_n_a3			(dfi_if.dfi_alert_n_a3		),	
		                .dfi_rddata_valid_w0		(dfi_if.dfi_rddata_valid_w0	),
		                .dfi_rddata_valid_w1		(dfi_if.dfi_rddata_valid_w1	),
		                .dfi_rddata_valid_w2		(dfi_if.dfi_rddata_valid_w2	),
		                .dfi_rddata_valid_w3		(dfi_if.dfi_rddata_valid_w3	),
		                .dfi_rddata_w0			(dfi_if.dfi_rddata_w0		),	
		                .dfi_rddata_w1			(dfi_if.dfi_rddata_w1		),	
		                .dfi_rddata_w2			(dfi_if.dfi_rddata_w2		),	
		                .dfi_rddata_w3			(dfi_if.dfi_rddata_w3		),	
		                .CA_DA_o			(jedec_if.CA_DA_o		),
		                .CS_DA_o			(jedec_if.CS_DA_o		),
		                .CA_VALID_DA_o			(jedec_if.CA_VALID_DA_o		)
		                );
`endif
*/