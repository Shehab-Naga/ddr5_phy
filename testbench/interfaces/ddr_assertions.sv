//`include "tb_pkg.sv"
module ddr_assertions 
	import tb_pkg::*; 
	import uvm_pkg::*;
	#(
        /**************************Design Parameters****************************/
	parameter Physical_Rank_No = 1, 
	parameter device_width = 4,
        /**************************DFI Timing Parameters****************************/
        parameter trddata_en 	= 1     ,    // Defined By System - Measured from the 2nd rising edge of the DFI_command_clock of the command
        parameter tcmd_lat      = 0     ,    // Defined By MC
        parameter tctrl_delay 	= 1     ,    // Defined By PHY
        parameter tphy_rdlat 	= 66+tctrl_delay+5   ,    // Defined By PHY: tctrl+max(RL)+phy's jedec to dfi deserialization (5 cycles in 1 to 4 ratio)
        /**************************JEDEC Timing Parameters****************************/
        parameter tMRR          = 16    +0,    // Defined By DRAM
        parameter tMRD          = 16    +0,    // Defined By DRAM
        parameter tCMD_cancel   = 8     +0,    // Defined By DRAM
		parameter tMRW		= 8,    
        parameter tRP 		= 24,
        parameter tRRD_S 	= 8,
        parameter tRRD_L 	= 8,
        parameter tCCD_S	= 8,
        parameter tRTP		= 12,
        parameter tRAS		= 5
        )
(
// DFI_Interface signals 
input   bit   		dfi_clk_i,
input   logic 		reset_n_i,
input   logic 		en_i,
input	logic 		phycrc_mode_i,
input	logic 		[1:0] dfi_freq_ratio_i, 
input   logic 		[13:0] dfi_address_p0, dfi_address_p1,dfi_address_p2,dfi_address_p3,
input   logic 		[Physical_Rank_No-1:0]dfi_cs_p0,dfi_cs_p1,dfi_cs_p2,dfi_cs_p3,
input   logic 		dfi_rddata_en_p0,dfi_rddata_en_p1,dfi_rddata_en_p2,dfi_rddata_en_p3,
input	logic 		dfi_alert_n_a0, dfi_alert_n_a1,dfi_alert_n_a2,dfi_alert_n_a3,
input   logic 		dfi_rddata_valid_w0,dfi_rddata_valid_w1,dfi_rddata_valid_w2,dfi_rddata_valid_w3,
input   logic 		[2*device_width-1:0]dfi_rddata_w0,dfi_rddata_w1,dfi_rddata_w2,dfi_rddata_w3,

// JEDEC Interface signals
input   bit   		dfi_phy_clk_i,
input	logic 		[13:0] CA_DA_o,
input   logic 		CS_DA_o,
input   logic 		CA_VALID_DA_o,
input	logic 		DQS_AD_i,
input   logic 		[2*device_width-1:0] DQ_AD_i,
//Constants fetched from the Env. (DB)
input	byte		RL,
input	burst_length_t	burst_length,
input   bit [2:0]  	pre_amble,
input	bit 		post_amble
);


`ifdef jedec_assert_en

//==========================================================================//
//                       JEDEC Properties				                    //
//==========================================================================//

/************************************************JEDEC_DR_1**&**JEDEC_DR_2*******************************************/
// From Plan: The mode register contents are available on the second 8 UI’s of the burst and are repeated across all DQ’s after the RL following the MRR command
sequence dynamic_delay(count);
 int v;
 (1, v=count) ##0 first_match((1, v=v-1'b1) [*0:$] ##1 v<=0);
 endsequence
  
property MRR_DATA_spacings;
  @(posedge dfi_phy_clk_i) disable iff (!reset_n_i)
  (CA_DA_o[4:0]==5'b10101 && !CS_DA_o)  |=> dynamic_delay(RL+4) ##0 (	(DQ_AD_i[0] == !DQ_AD_i[1]) and 
																		(DQ_AD_i[0] ==  DQ_AD_i[2]) and
																		(DQ_AD_i[0] == !DQ_AD_i[3]) and
																		(DQ_AD_i[4] == !DQ_AD_i[5]) and
																		(DQ_AD_i[4] ==  DQ_AD_i[6]) and
																		(DQ_AD_i[4] == !DQ_AD_i[7])
								);
endproperty : MRR_DATA_spacings

property MRR_DATA_spacings_ZEROs_ONEs;
int v;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
 ( CA_DA_o[4:0]==5'b10101 && !CS_DA_o, v=RL)  |=> dynamic_delay(v) ##0   (( (DQ_AD_i[0] == 1'b0) && (DQ_AD_i[1] == 1'b1) && (DQ_AD_i[2] == 1'b0) && (DQ_AD_i[3] == 1'b1) && (DQ_AD_i[4] == 1'b0) && (DQ_AD_i[5] == 1'b1) && (DQ_AD_i[6] == 1'b0) && (DQ_AD_i[7] == 1'b1) )
							##1 										  ( (DQ_AD_i[0] == 1'b0) && (DQ_AD_i[1] == 1'b1) && (DQ_AD_i[2] == 1'b0) && (DQ_AD_i[3] == 1'b1) && (DQ_AD_i[4] == 1'b0) && (DQ_AD_i[5] == 1'b1) && (DQ_AD_i[6] == 1'b0) && (DQ_AD_i[7] == 1'b1) )
							##1 										  ( (DQ_AD_i[0] == 1'b0) && (DQ_AD_i[1] == 1'b1) && (DQ_AD_i[2] == 1'b0) && (DQ_AD_i[3] == 1'b1) && (DQ_AD_i[4] == 1'b0) && (DQ_AD_i[5] == 1'b1) && (DQ_AD_i[6] == 1'b0) && (DQ_AD_i[7] == 1'b1) )
							##1 										  ( (DQ_AD_i[0] == 1'b0) && (DQ_AD_i[1] == 1'b1) && (DQ_AD_i[2] == 1'b0) && (DQ_AD_i[3] == 1'b1) && (DQ_AD_i[4] == 1'b0) && (DQ_AD_i[5] == 1'b1) && (DQ_AD_i[6] == 1'b0) && (DQ_AD_i[7] == 1'b1) )
							);
endproperty: MRR_DATA_spacings_ZEROs_ONEs

/************************************************JEDEC_DR_3*******************************************/
// From Plan: DQS is toggled for the duration of the MRR burst.	--> DQS is toggled for BL16 
property MRR_DQS_toggle ;
int v;
	@(posedge dfi_phy_clk_i)  	disable iff (!reset_n_i)        
	(CA_DA_o[4:0] == 5'b10101 && !CS_DA_o, v=RL)  |=> dynamic_delay(v) ##0 ( ($changed(DQS_AD_i))[=1] )[*8]; 
endproperty: MRR_DQS_toggle

/************************************************JEDEC_DR_7*******************************************/
// From Plan: The read pre-amble and post-amble of MRR are same as normal read. 
property MRR_preamble;
  bit result; int v;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
    (!CS_DA_o && CA_DA_o[4:0] == 5'b10101 ,  v=RL-tRPRE)  |=> dynamic_delay(v) ##0 (1, detect_preamble(pre_amble));
endproperty: MRR_preamble
property MRR_postamble;
  bit result; int v;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
    (!CS_DA_o && CA_DA_o[4:0] == 5'b10101 ,  v=RL+8)  |=> dynamic_delay(v) ##0 (1, detect_postamble(post_amble));
endproperty: MRR_postamble

/************************************************JEDEC_DR_8*******************************************/
// Elaboration: spacing between MRR CMD and any other CMD is tMRR
// Timing between MRR and MRW is CL+BL/2+1 : not implemented yet
property MRR_CMD_spacings ;
  @(posedge dfi_phy_clk_i)  disable iff (!reset_n_i)        
(CA_DA_o[4:0] == 5'b10101 && !CS_DA_o) |=> CS_DA_o [*tMRR-1]; 
endproperty: MRR_CMD_spacings

/************************************************JEDEC_DR_8*******************************************/
// Elaboration: spacing between two MRW CMDs is tMRW and any other CMD is tMRR
property MRW_MRW_spacings ;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
(CA_DA_o[4:0] == 5'b00101 && !CS_DA_o) |=> CS_DA_o[*tMRW-1];
endproperty: MRW_MRW_spacings
property MRW_OTHER_spacings;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
(CA_DA_o[4:0] == 5'b00101 && !CS_DA_o) |=>  !(is_ACT()||is_MRR()||is_PREab()||is_RD())[*tMRD-1-1]; 
endproperty: MRW_OTHER_spacings

/************************************************JEDEC_DR_11*******************************************/
// Elaboration: spacing between PRE CMDs and MRR/MRW is tRP

property PRE_CMD_spacings ;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
  (CA_DA_o[4:0] == 5'b01011 && !CS_DA_o) |=> !((CA_DA_o[4:0] == 5'b00101 || CA_DA_o[4:0] == 5'b10101) && !CS_DA_o) [*tRP-1];
  endproperty: PRE_CMD_spacings

/************************************************JEDEC_DR_12*******************************************/
//When a defined register byte (MR#) contains an “RFU” bit, the host must write a ZERO for those specific bits
property host_Write_zero_to_RFU ;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
(CA_DA_o[4:0] == 5'b00101 && CA_DA_o[12:5] == 0     |=> CA_DA_o[7] ==  0) and
(CA_DA_o[4:0] == 5'b00101 && CA_DA_o[12:5] == 8'h08 |=> CA_DA_o[5] ==  0) and
(CA_DA_o[4:0] == 5'b00101 && CA_DA_o[12:5] == 8'h28 |=> CA_DA_o[7:3] ==0); 
endproperty: host_Write_zero_to_RFU

/************************************************JEDEC_DR_13*******************************************/
//When the host issues an MRR to a defined register (MR#) that contains RFU bits in it, those specific bits shall always produce a ZERO.
property host_Read_zero_from_RFU ;
	int t_13;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
((CA_DA_o[4:0] == 5'b10101 && CA_DA_o[12:5] == 8'h00 && !CS_DA_o, t_13 = RL+7) |=> dynamic_delay(t_13) ##0 DQ_AD_i[4] == 1'b0) and
((CA_DA_o[4:0] == 5'b10101 && CA_DA_o[12:5] == 8'h08 && !CS_DA_o, t_13 = RL+6) |=> dynamic_delay(t_13) ##0 DQ_AD_i[4] == 2'bx0) ;
endproperty: host_Read_zero_from_RFU

/*****************************JEDEC_DR_17*******************************************/
//From Plan: Check that the preamble and postamble is equal to the value written in MR8
int tRPRE;
always_comb begin 
	case (pre_amble)
		000: tRPRE = 2;
		001: tRPRE = 4;
		010: tRPRE = 4;
		011: tRPRE = 6;
		100: tRPRE = 8;
		default: tRPRE = 2;
	endcase
end
property RD_preamble;
  bit result; int v;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
    (!CS_DA_o && CA_DA_o[4:0] == 5'b11101 ,  v=RL-tRPRE)  |=> dynamic_delay(v) ##0 (1, detect_preamble(pre_amble));
endproperty: RD_preamble
int num_of_bursts;
always_comb begin
	case(burst_length)
		BL16: 		num_of_bursts=8;
		BC8_OTF: 	num_of_bursts=4;
		BL32: 		num_of_bursts=16;
		//BL32_OTF: 	num_of_bursts=16;
		default: 	num_of_bursts=8;
	endcase
end
property RD_postamble;
  bit result; int v;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
    (!CS_DA_o && CA_DA_o[4:0] == 5'b11101 ,  v=RL+num_of_bursts)  |=> dynamic_delay(v) ##0 (1, detect_postamble(post_amble));
endproperty: RD_postamble

/************************************************JEDEC_DR_21*******************************************/
// The minimum timing between a cancelled CMD and the following CMD is tCMD_cancel 
property CMD_Cancel_timing ;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
(!CS_DA_o)[*2] |=> CS_DA_o[*tCMD_cancel]; 
endproperty: CMD_Cancel_timing


/************************************************JEDEC_DR_24*******************************************/
// Once a bank has been precharged, it is in the idle state and must be activated prior to any READ or WRITE commands being issued to that bank
property Pre_then_ACT ;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
(CA_DA_o[4:0] == 5'b01011 && !CS_DA_o) ##[0:$] (CA_DA_o[4:0] != 5'b11101 && !CS_DA_o) || (CA_DA_o[4:0] != 5'b00101 && !CS_DA_o) |-> 1;
endproperty: Pre_then_ACT

/************************************************JEDEC_DR_25***&**JEDEC_DR_31*******************************************/
// A PRECHARGE command is allowed if there is no open row in that bank (idle state) or if the previously open row is already in the process of precharging. 
property ACT_then_Pre_no_allowed ;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
(( CA_DA_o[1:0] == 2'b00 && !CS_DA_o) ##[0:$] (CA_DA_o[4:0] != 5'b01011 && !CS_DA_o)) |-> 1;
endproperty: ACT_then_Pre_no_allowed

/************************************************JEDEC_DR_28***&**JEDEC_DR_29*******************************************/
// tRRD_S (short) is used for timing between banks located in different bank groups.
// tRRD_L (long) is used for timing between banks located in the same bank group. 
property ACT_2_ACT_Diff_BG;
  logic [2:0] BG;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
( CA_DA_o[1:0] == 2'b00 && !CS_DA_o, BG = CA_DA_o[10:8] ) |=> (!( CA_DA_o[1:0] == 2'b00 && !CS_DA_o ))[*tRRD_S-1]; 
endproperty: ACT_2_ACT_Diff_BG
property ACT_2_ACT_Same_BG;
  logic [2:0] BG;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
((CA_DA_o[1:0] == 2'b00) && !CS_DA_o, BG = CA_DA_o[10:8]) |=> (!(CA_DA_o[1:0] == 2'b00 && !CS_DA_o && CA_DA_o[10:8] == BG))[*tRRD_L-1];
endproperty: ACT_2_ACT_Same_BG


/************************************************JEDEC_DR_31*******************************************/
//Read Latency (RL or CL) is defined from the Read command to data and is not affected by the Read DQS offset timing (MR40 OP[2:0]).
property RDCMD_TO_DATA_DELAY ;
int v;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
((CA_DA_o[4:0] == 5'b11101 && !CS_DA_o, v = RL) |=> dynamic_delay(v) ##0 !$isunknown(DQ_AD_i));
endproperty: RDCMD_TO_DATA_DELAY

/************************************************JEDEC_DR_32************************************************/
// From Plan: "If CA5:BL*=L, the command places the DRAM into the alternate Burst mode described by MR0[1:0] instead of the default Burst Length 16 mode."
// This property should measure the BL and compare it to BL16 if CA5==H or compare it to burst_length is CA5==L
task automatic detect_BL(input burst_length_t burst_length);
	bit DQS_Internal;
	DQS_Internal = DQS_AD_i;
	case(burst_length) 
		BL16:	begin
			repeat(8-1) begin
				@(posedge dfi_phy_clk_i)
				if (DQS_Internal == DQS_AD_i) //DQS_AD_i should have toggled by now
					begin
					`uvm_error("DDR Assertions",  $sformatf("detect_BL failure -- BL setting is: %d", burst_length));	
					end
				else
					DQS_Internal = DQS_AD_i;
			end
		end	
		BC8_OTF:begin
			repeat(4-1) begin
				@(posedge dfi_phy_clk_i)
				if (DQS_Internal == DQS_AD_i) //DQS_AD_i should have toggled by now
					begin
					`uvm_error("DDR Assertions",  $sformatf("detect_BL failure -- BL setting is: %d", burst_length));	
					end
				else
					DQS_Internal = DQS_AD_i;
			end
		end	
		BL32:	begin
			repeat(16-1) begin
				@(posedge dfi_phy_clk_i)
				if (DQS_Internal == DQS_AD_i) //DQS_AD_i should have toggled by now
					begin
					`uvm_error("DDR Assertions",  $sformatf("detect_BL failure -- BL setting is: %d", burst_length));	
					end
				else
					DQS_Internal = DQS_AD_i;
			end
		end	
		/*
		BL32_OTF:begin
			repeat(16-1) begin
				@(posedge dfi_phy_clk_i)
				if (DQS_Internal == DQS_AD_i) //DQS_AD_i should have toggled by now
					begin
					`uvm_error("DDR Assertions",  $sformatf("detect_BL failure -- BL setting is: %d", burst_length));	
					end
				else
					DQS_Internal = DQS_AD_i;
			end
		end
		*/	
		default:begin
			
		end 
	endcase
endtask
property RD_CA5_H;
int v;
  @(posedge dfi_phy_clk_i)disable iff (!reset_n_i)
  ( (CA_DA_o[4:0] == 5'b11101) && !CS_DA_o &&  CA_DA_o[5]==1 && burst_length!=BL32, v=RL)  |=> dynamic_delay(v) ##0 ( 1 , detect_BL(BL16) );
endproperty: RD_CA5_H
property RD_CA5_L;
int v;
  @(posedge dfi_phy_clk_i)disable iff (!reset_n_i)
  //( (CA_DA_o[4:0] == 5'b11101) && !CS_DA_o &&  CA_DA_o[5]==1, v=RL)  |=> (1, v=v-1'b1)[*1:$] ##0 v<=0 ##0 ( ( ($changed(DQS_AD_i))[=1] )[*(num_of_bursts)] );
  ( (CA_DA_o[4:0] == 5'b11101) && !CS_DA_o &&  CA_DA_o[5]==0, v=RL)  |=> dynamic_delay(v) ##0 ( 1 , detect_BL(burst_length) );
endproperty: RD_CA5_L

/************************************************JEDEC_DR_35************************************************/
// From Plan: In non-CRC mode, DQS_t and DQS_c stop toggling at the completion of the BC8 data bursts, plus the postamble -- assert stops toggeling after postamble
int tRPST;
always_comb begin
	if (post_amble)
		tRPST=1;
	else
		tRPST=3;
end
property DQS_stop ;
int v;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
    (!CS_DA_o && (CA_DA_o[4:0] == 5'b11101 ||CA_DA_o[4:0] == 5'b10101) ,  v=RL+(num_of_bursts)+tRPST)  |=> dynamic_delay(v) ##0 (!$changed(DQS_AD_i) [*10]); //The number 10 is arbitrary to make sure DQS is not toggling anymore
endproperty: DQS_stop

/************************************************JEDEC_DR_36************************************************/
//The minimum external Read command to Precharge command spacing to the same bank is equal to tRTP with tRTP being the Internal Read Command to Precharge Command Delay.
property RDToPreSpacing ;
  logic [1:0] bankaddress;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
((CA_DA_o[4:0] == 5'b11101) && !CS_DA_o, bankaddress = CA_DA_o[7:6]) |=> !( CA_DA_o[4:0]==5'b01011 && !CS_DA_o && CA_DA_o[7:6]==bankaddress) [*tRTP-1];
endproperty: RDToPreSpacing


/************************************************JEDEC_DR_37************************************************/
// the minimum ACT to PRE timing, tRAS, must be satisfied as well
property PreToACTSpacing ;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
((CA_DA_o[4:0] == 5'b01011) && !CS_DA_o) |-> ##1 !(!CS_DA_o && (CA_DA_o[1:0] == 2'b00))[*tRAS-1];
endproperty: PreToACTSpacing

/************************************************JEDEC_DR_37************************************************/
// A dummy RD command is required for the second half of the transfer with a delay of 8 clocks from the first RD command in case of BL32 fixed or BL32 OTF

property DummyRDCMD ;
burst_length_t burstlength = burst_length;
 @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
(((CA_DA_o[4:0] == 5'b11101) && !CS_DA_o && burstlength == BL32) ##1 CA_DA_o[10] == 1) |-> ##7 (!CS_DA_o && (CA_DA_o[4:0] == 5'b11101) ##1 CA_DA_o[10] == 0);
endproperty: DummyRDCMD

property C10_IS_opposite ; 
burst_length_t burstlength_ = burst_length;
logic C10;
 @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
 ((CA_DA_o[4:0] == 5'b11101 && !CS_DA_o && burstlength_ == BL32)  ##1 ( CA_DA_o[10] == 1, C10 = CA_DA_o[8])) |-> ##7 ((!CS_DA_o && (CA_DA_o[4:0] == 5'b11101)) ##1 (CA_DA_o[8] == !C10 && CA_DA_o[10]== 0));

endproperty: C10_IS_opposite


property SecondRD_resembles_first ;
burst_length_t burstlength__ = burst_length;
logic [13:0] first_temp_CMD;
logic [13:0] second_temp_CMD;
 @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
 ((CA_DA_o[4:0] == 5'b11101 && burstlength__ == BL32 && !CS_DA_o, first_temp_CMD = CA_DA_o[13:0]) ##1 (CA_DA_o[10] == 1, second_temp_CMD = CA_DA_o[13:0])) |-> ##7 ((!CS_DA_o && (CA_DA_o[13:0] == first_temp_CMD)) ##1 (CA_DA_o[7:0] == second_temp_CMD[7:0] && CA_DA_o[13:11] == second_temp_CMD[13:11] && CA_DA_o[9] == second_temp_CMD[9] && CA_DA_o[10]== 0));
endproperty: SecondRD_resembles_first

/************************************************JEDEC_DR_44************************************************/
// From Plan: AP bit must be set to LOW with the CAS command when reading BL16 in BL32 OTF mode	-- Assert that The read command has AP low
/*
property BL16_In_BL32OTF ;
 @(posedge dfi_phy_clk_i)
 (CA_DA_o[4:0] == 5'b11101 && CA_DA_o[5]==1 && burst_length==BL32_OTF && !CS_DA_o) |->  CA_DA_o[10]==0; 
endproperty: BL16_In_BL32OTF
*/


property ReadTOReadSameBank ;
  logic [4:0] ba;
  @(posedge dfi_phy_clk_i)	disable iff (!reset_n_i)
(((CA_DA_o[1:0] == 5'b11101), ba = CA_DA_o[10:6]) |-> ##1 (CS_DA_o[*tCCD_S] or (CS_DA_o [*tRRD_L] ##1 CA_DA_o[10:8] == ba))); 

endproperty: ReadTOReadSameBank



//==========================================================================//
//                       JEDEC ASSERTIONS				    //
//==========================================================================//

		Spacing_btn_MRR_Data:           assert property(MRR_DATA_spacings)
						else `uvm_error("DDR Assertions",  $sformatf("Data should be available on 8 UI's RL after MRR CMD"));
		COV_Spacing_btn_MRR_Data:       cover property(MRR_DATA_spacings);
		//
		ASRT_MRR_DATA_spacings_ZEROs_ONEs:           assert property(MRR_DATA_spacings_ZEROs_ONEs)
						else `uvm_error("DDR Assertions",  $sformatf("Data Shoulg Be Zeros And Ones when reading from MR"));
		COV_MRR_DATA_spacings_ZEROs_ONEs:       cover property(MRR_DATA_spacings_ZEROs_ONEs);

		


ASRT_MRR_preamble:           assert property(MRR_preamble)
                                else `uvm_error("DDR Assertions",  $sformatf("Preamble error after MRR command"));
COV_MRR_preamble:       cover property(MRR_preamble);

	`ifdef DQS_toggline
		ASRT_MRR_postamble:           assert property(MRR_postamble)
						else `uvm_error("DDR Assertions",  $sformatf("Postamble error after MRR command"));
		COV_MRR_postamble:       cover property(MRR_postamble);
		//
		JEDEC_DQSShouldToggleForBL:           assert property(MRR_DQS_toggle)
						else `uvm_error("DDR Assertions",  $sformatf("DQS Should Toggle For BL"));
		COV_JEDEC_DQSShouldToggleForBL:       cover property(MRR_DQS_toggle);
	`endif 

Spacing_btn_MRR_CMD:            assert property(MRR_CMD_spacings)
                                else `uvm_error("DDR Assertions",  $sformatf("Spacing between MRR CMD and any other CMD should be tMRR"));
COV_Spacing_btn_MRR_CMD:        cover property(MRR_CMD_spacings); 
//
ASRT_MRW_MRW_spacings:            assert property(MRW_MRW_spacings)
                                else `uvm_error("DDR Assertions",  $sformatf("Spacing between two MRW CMDs should be tMRW ")); 
COV_MRW_MRW_spacings:        cover property(MRW_MRW_spacings);
//
ASRT_MRW_OTHER_spacings:            assert property(MRW_OTHER_spacings)
                                else `uvm_error("DDR Assertions",  $sformatf("Spacing between two MRW CMD and any other CMD should tMRR")); 
COV_MRW_OTHER_spacings:        cover property(MRW_OTHER_spacings);
//
Spacing_btn_PRE_MRR:            assert property(PRE_CMD_spacings)
                                else `uvm_error("DDR Assertions",  $sformatf("Spacing between PRE CMDs and MRR/MRW should be tRP"));
COV_Spacing_btn_PRE_MRR:        cover property(PRE_CMD_spacings);
//
host_should_Write_zero_to_RFU:  assert property(host_Write_zero_to_RFU)
				else `uvm_error("DDR Assertions",  $sformatf("“RFU” bits must be written ZERO by the host"));
COV_host_should_Write_zero_to_RFU:        cover property(host_Write_zero_to_RFU);
//
	//`ifdef allow_ram_hog
		host_should_Read_zero_from_RFU: assert property(host_Read_zero_from_RFU)
						else `uvm_error("DDR Assertions",  $sformatf("RFU bits shall always produce a ZERO when it's being read"));
		COV_host_should_Read_zero_from_RFU:        cover property(host_Read_zero_from_RFU);
	//`endif
//

ASRT_RD_preamble:           assert property(RD_preamble)
                                else `uvm_error("DDR Assertions",  $sformatf("Preamble error after RD command"));
COV_RD_preamble:       cover property(RD_preamble);
	
	`ifdef DQS_toggline
		ASRT_RD_postamble:           assert property(RD_postamble)
						else `uvm_error("DDR Assertions",  $sformatf("Postamble error after RD command"));
		COV_RD_postamble:       cover property(RD_postamble);
	`endif 
//
timing_btn_Canceled_CMD:            assert property(CMD_Cancel_timing)
                                else `uvm_error("DDR Assertions",  $sformatf("The minimum timing between a cancelled CMD and the following CMD should be tCMD_cancel"));
COV_timing_btn_Canceled_CMD:        cover property(CMD_Cancel_timing);
//
	`ifdef allow_ram_hog
		ACT_Should_follow_PRE:            assert property(Pre_then_ACT)
						else `uvm_error("DDR Assertions",  $sformatf("a bank must be activated prior to any READ or WRITE commands being issued to that bank"));
		COV_ACT_Should_follow_PRE:        cover property(Pre_then_ACT);
		//
		PRE_Mustnt_follow_ACT:            assert property(ACT_then_Pre_no_allowed)
						else `uvm_error("DDR Assertions",  $sformatf("Precharge CMD mustn't follow activate CMD directely"));
		COV_PRE_Mustnt_follow_ACT:        cover property(ACT_then_Pre_no_allowed);
	`endif 
//
ASRT_ACT_2_ACT_Diff_BG:            assert property(ACT_2_ACT_Diff_BG)
                                else `uvm_error("DDR Assertions",  $sformatf("timing between banks located in different bank groups should be tRRD_S"));
COV_ACT_2_ACT_Diff_BG:        cover property(ACT_2_ACT_Diff_BG);
ASRT_ACT_2_ACT_Same_BG:            assert property(ACT_2_ACT_Same_BG)
                                else `uvm_error("DDR Assertions",  $sformatf("timing between banks located in the same bank group should be tRRD_L"));
COV_ACT_2_ACT_Same_BG:        cover property(ACT_2_ACT_Same_BG);
//
/* --------------------------- LOW PRIORITY, SO DISABLED ------------------------------
Four_ACT_CMD_withen_tFAW:            assert property(Max_timing_for_four_ACT_CMD)
                                else `uvm_error("DDR Assertions",  $sformatf("// Spec: Consecutive ACTIVATE commands, allowed to be issued at tRRDmin, are restricted to a maximum of four within the time period tFAW (four activate window)."));
COV_Four_ACT_CMD_withen_tFAW:        cover property(Max_timing_for_four_ACT_CMD);
//*/
ReadToDataDelayIstRL:            assert property(RDCMD_TO_DATA_DELAY)
                                else `uvm_error("DDR Assertions",  $sformatf("The delay between read command and data should be RL"));
COV_ReadToDataDelayIstRL:        cover property(RDCMD_TO_DATA_DELAY);
//
	`ifdef DQS_toggline
		ASRT_RD_CA5_H:            assert property(RD_CA5_H)
						else `uvm_error("DDR Assertions",  $sformatf("BL is not BL16 when CA5==H in a RD cmd"));
		COV_RD_CA5_H:        cover property(RD_CA5_H);

		ASRT_RD_CA5_L:            assert property(RD_CA5_L)
						else `uvm_error("DDR Assertions",  $sformatf("BL is not equal to burst_length from DB when CA5==L in a RD cmd"));
		COV_RD_CA5_L:        cover property(RD_CA5_L);
		//
		ASRT_DQS_stop:            assert property(DQS_stop)
                                else `uvm_error("DDR Assertions",  $sformatf("DQS did not stop after postamble"));
		COV_DQS_stop:        cover property(DQS_stop);
		//
	`endif 
//
ReadToPrechargeDelayIsttPTR:            assert property(RDToPreSpacing)
                                else `uvm_error("DDR Assertions",  $sformatf("The delay between read command and precharge command should be tRTB"));
COV_ReadToPrechargeDelayIsttPTR:        cover property(RDToPreSpacing);
//
PrechargeToACTDelayIsttRAS:            assert property(PreToACTSpacing)
                                else `uvm_error("DDR Assertions",  $sformatf("The delay between precharge command and ACT command should be tRAS"));
COV_PrechargeToACTDelayIsttRAS:        cover property(PreToACTSpacing);
//
ADummyReadCMDShouldExitInBL32:            assert property(DummyRDCMD)
                                else `uvm_error("DDR Assertions",  $sformatf("A Dummy Read CMD Should Exit In BL32"));
COV_ADummyReadCMDShouldExitInBL32:        cover property(DummyRDCMD);
//
C10ShouldBeOppositeInTheSecondCMD:            assert property(C10_IS_opposite)
                                else `uvm_error("DDR Assertions",  $sformatf("C10 Should Be Opposite In TheSecond CMD"));
COV_C10ShouldBeOppositeInTheSecondCMD:        cover property(C10_IS_opposite);
//
SecondCMDShouldResembleFirstCMD:            assert property(SecondRD_resembles_first)
                                else `uvm_error("DDR Assertions",  $sformatf("Second CMD Should Resemble First CMD"));
COV_SecondCMDShouldResembleFirstCMD:        cover property(SecondRD_resembles_first);
//
	/*
	ASRT_BL16_In_BL32OTF:            assert property(BL16_In_BL32OTF)
					else `uvm_error("DDR Assertions",  $sformatf("CA10 Should Be High For BL16 In BL32"));
	COV_BL16_In_BL32OTF:        cover property(BL16_In_BL32OTF);
	*/
//
ReadTOReadSameBankDelay:            assert property(ReadTOReadSameBank)
                                else `uvm_error("DDR Assertions",  $sformatf("Read TO Read SameBank Delay should be tCCD_L"));
COV_ReadTOReadSameBankDelay:        cover property(ReadTOReadSameBank);
//

`endif 


`ifdef dfi_assert_en
//==========================================================================//
//                       DFI Properties for 1 to 1 ratio                    //
//==========================================================================//

`ifdef ratio_1_to_1

	/*****************************DFI_DR_1 && DFI_DR_2*******************************************/
	// From plan:   command is driven for at least 1 DFI PHY clock cycle after the CS is active.
	//              tcmd_lat specifies the number of DFI clocks after the dfi_cs signal is asserted until the associated CA signals are driven.
	property dfi_address_valid(dfi_cs_px, dfi_address_px);
	  @(posedge dfi_clk_i) disable iff (!reset_n_i)
	    !dfi_cs_px |-> (##tcmd_lat !$isunknown(dfi_address_px) [*1:2]);
	endproperty: dfi_address_valid

	/*****************************DFI_DR_6*******************************************/
	// From plan:   Check the correct behaviour of CS_n on the DRAM interface (follows the behaviour of dfi_cs meaning 0=>1=>0)
	// Elaboration: when dfi_cs toggles (1=>0=>1), CS_n should follow the exact same behaviour after translation delay of tctrl_delay
	property  CS_n_to_dfi_cs_translation(dfi_cs_px, CS_DA_o, tctrl_delay);
	  bit CS_tmp;
	  @(posedge dfi_phy_clk_i) disable iff (!reset_n_i)
	    ($changed(dfi_cs_px), CS_tmp=dfi_cs_px) |-> ##(tctrl_delay+1) CS_DA_o===CS_tmp; //where x is the phase number
            //**NOTE:       Added 1 to all timing that envolves an input singal (TB stimulus) AND an output signal (DUT response) 
            //              because we drive on the negative edge, but the DUT's output is on the positive edge 
	endproperty: CS_n_to_dfi_cs_translation 

	/*****************************DFI_DR_11*******************************************/
	// Translation delay between DFI and JEDEC
	property dfi_address_to_CA_translation(dfi_cs_px, dfi_address_px,CA_DA_o);
	  logic [13:0] CA_temp;
	  @(posedge dfi_phy_clk_i) disable iff (!reset_n_i)
	   ($changed(dfi_address_px) , CA_temp=dfi_address_px) |-> (##(tctrl_delay+1) (CA_temp===CA_DA_o));
           //**NOTE:       Added 1 to all timing that envolves an input singal (TB stimulus) AND an output signal (DUT response) 
           //              because we drive on the negative edge, but the DUT's output is on the positive edge
	endproperty: dfi_address_to_CA_translation

	/*****************************DFI_DR_13*******************************************/
	//From Plan: check that valid data is being transferred when the dfi_rddata_valid signal is asserted
	property dfi_rddata_signal_valid(dfi_rddata_valid_wx, dfi_rddata_wx);
	  @(posedge dfi_clk_i) disable iff (!reset_n_i)
	    dfi_rddata_valid_w0 |-> !$isunknown(dfi_rddata_wx);
	endproperty: dfi_rddata_signal_valid

	/*****************************DFI_DR_13 && DFI_DR_16*******************************************/
	// From Plan: dfi_rddata_en is asserted after a RD command by trddata_en DFI_PHY_clock cycles
	property dfi_rddata_en_signal_asserted(dfi_address_px, dfi_cs_px, dfi_rddata_en_px);
	  @(posedge dfi_phy_clk_i) disable iff (!reset_n_i)
	  ((dfi_address_px[4:0] == 5'b11101) && !(dfi_cs_px)) |-> (##(trddata_en+1) dfi_rddata_en_px);
	  //**NOTE:	used ##(trddata_en+1) because the first part of the command is the antecident; therefore, an extra "1" is added to "trddata_en"
	endproperty: dfi_rddata_en_signal_asserted


	/*****************************DFI_DR_13 && DFI_DR_16*******************************************/
        // From Plan: asserting on tphy_rdlat
        property dfi_rddata_en_to_dfi_rddata_valid_delay(dfi_rddata_en, dfi_rddata_valid);
	  @(posedge dfi_phy_clk_i) disable iff (!reset_n_i)
	  $rose(dfi_rddata_en) |-> ##[0:tphy_rdlat+1] $rose(dfi_rddata_valid) ;
           //**NOTE:       Added 1 to all timing that envolves an input singal (TB stimulus) AND an output signal (DUT response) 
           //              because we drive on the negative edge, but the DUT's output is on the positive edge
	endproperty: dfi_rddata_en_to_dfi_rddata_valid_delay
        


//==========================================================================//
//                      DFI Assertions for 1 to 1 ratio                     //
//==========================================================================//

        dfi_address_VALID_p0:           assert property (dfi_address_valid(dfi_cs_p0, dfi_address_p0)) 
		                        else `uvm_error("DDR Assertions",  $sformatf("Spacing between dfi_cs_p0 and dfi_address_p0 is not %d",tcmd_lat));
	COV_dfi_address_VALID_p0:       cover property(dfi_address_valid(dfi_cs_p0, dfi_address_p0));

	CS_n_to_dfi_cs_Translation_p0:  assert property(CS_n_to_dfi_cs_translation(dfi_cs_p0, CS_DA_o, tctrl_delay))//$display("CS_n_to_dfi_cs_translation Assertion Passed at time t=%d", $time);
		                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_cs_p0 translational delay between DFI interface and JEDEC interface isn't %d",tctrl_delay+0));
	COV_CS_n_to_dfi_cs_Translation_p0:cover property(CS_n_to_dfi_cs_translation(dfi_cs_p0, CS_DA_o, tctrl_delay)); 

	dfi_address_to_CA_delay_p0:     assert property(dfi_address_to_CA_translation(dfi_cs_p0, dfi_address_p0, CA_DA_o)) 
		                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_address_p0 translational delay between DFI interface and JEDEC interface isn't %d --- Sampled CA: ",tctrl_delay+0, $sampled(CA_DA_o)));
	COV_dfi_address_to_CA_delay_p0: cover property(dfi_address_to_CA_translation(dfi_cs_p0, dfi_address_p0, CA_DA_o));

	dfi_rddata_signal_valid_p0:     assert property(dfi_rddata_signal_valid(dfi_rddata_valid_w0, dfi_rddata_w0))
		                        else `uvm_error("DDR Assertions",  $sformatf("dfi_rddata_w0 is sent without dfi_rddata_valid_w0"));

	dfi_rddata_en_signal_asserted_p0:assert property(dfi_rddata_en_signal_asserted(dfi_address_p0, dfi_cs_p0, dfi_rddata_en_p0))
		                        else `uvm_error("DDR Assertions",  $sformatf("dfi_rddata_en_p0 should be asserted %d cycles  after dfi_address_p0", trddata_en));
       
        dfi_rddata_en_to_dfi_rddata_valid_delay_p0:assert property(dfi_rddata_en_to_dfi_rddata_valid_delay(dfi_rddata_en_p0, dfi_rddata_valid_w0))
                                        else `uvm_error("DDR Assertions",  $sformatf("DFI_DR_13 && DFI_DR_16 Failure -- dfi_rddata_en to dfi_rddata_valid delay is not %d", tphy_rdlat));
	
`endif

`ifdef ratio_1_to_2
//==========================================================================//
//                       DFI Properties for 1 to 2 ratio                    //
//==========================================================================//
	/*****************************DFI_DR_1 && DFI_DR_2*******************************************/
	// From plan:   command is driven for at least 1 DFI PHY clock cycle after the CS is active.
	//              tcmd_lat specifies the number of DFI clocks after the dfi_cs signal is asserted until the associated CA signals are driven.
	property dfi_address_valid(dfi_cs_px, dfi_address_px);
	  @(posedge dfi_clk_i) disable iff (!reset_n_i)
	    !dfi_cs_px |-> (##tcmd_lat !$isunknown(dfi_address_px) [*1:2]);
	endproperty: dfi_address_valid

	/*****************************DFI_DR_6*******************************************/
	// From plan:   Check the correct behaviour of CS_n on the DRAM interface (follows the behaviour of dfi_cs meaning 0=>1=>0)
	// Elaboration: when dfi_cs toggles (1=>0=>1), CS_n should follow the exact same behaviour after translation delay of tctrl_delay
	property  CS_n_to_dfi_cs_translation(dfi_cs_px, CS_DA_o, phase);
	  bit CS_tmp;
	  @(posedge dfi_phy_clk_i) disable iff (!reset_n_i)
            ($changed(dfi_cs_px), CS_tmp=dfi_cs_px) |-> ##(2*tctrl_delay+1+phase) CS_DA_o===CS_tmp; //where phase is the phase number
            //**NOTE:	Added 1 to all timing that envolves an input singal (TB stimulus) AND an output signal (DUT response) 
            //        	because we drive on the negative edge, but the DUT's output is on the positive edge 
            //**NOTE:   Multiplied tctrl_delay by 2 because 1_to_2 ration; tctrl_delay is 1 dfi_clk cycle.     
	endproperty: CS_n_to_dfi_cs_translation

	/*****************************DFI_DR_7 -----NOT IMPLEMENTED BY THE DESIGN YET------*******************************************/
	// From plan: Check the correct behaviour of reset_n on the DRAM interface (follows the behaviour of dfi_reset_n meaning 0=>1=>0)
	// Elaboration: when dfi_reset_n toggles, reset_n should follow the exact same behaviour after translation delay of tctrl_delay
	/*
	property  ;
	  @(posedge dfi_clk_i) 
	    (dfi_reset_n ##1 !dfi_reset_n ##1 dfi_reset_n) |-> (##tctrl_delay (reset_n ##1 !reset_n ##1 reset_n));
	endproperty: 
	ERR_: assert property();
	*/   

	/*****************************DFI_DR_11*******************************************/
	// Translation delay between DFI and JEDEC
	property dfi_address_to_CA_translation(dfi_cs_px, dfi_address_px,CA_DA_o, phase);
	  logic [13:0] CA_temp;
	  @(posedge dfi_phy_clk_i) disable iff (!reset_n_i)
	   //( $rose(dfi_clk_i) && !dfi_cs_px && $changed(dfi_address_px) , CA_temp=dfi_address_px) |-> (##(tctrl_delay+x) (CA_temp==CA_DA_o));
	   ($changed(dfi_address_px) , CA_temp=dfi_address_px) |-> ##(2*tctrl_delay+1+phase) (CA_temp===CA_DA_o);
	endproperty: dfi_address_to_CA_translation

	/*****************************DFI_DR_13*******************************************/
	//From Plan: check that valid data is being transferred when the dfi_rddata_valid signal is asserted
	property dfi_rddata_signal_valid(dfi_rddata_valid_wx, dfi_rddata_wx);
	  @(posedge dfi_clk_i) disable iff (!reset_n_i)
	    dfi_rddata_valid_w0 |-> !$isunknown(dfi_rddata_wx);
	endproperty: dfi_rddata_signal_valid

	/*****************************DFI_DR_13 && DFI_DR_16*******************************************/
	// From Plan: dfi_rddata_en is asserted after a RD command by trddata_en DFI_PHY_clock cycles
	property dfi_rddata_en_signal_asserted(dfi_address_px, dfi_cs_px, dfi_rddata_en_px, a);
	  @(posedge dfi_clk_i) disable iff (!reset_n_i)
          ( ((dfi_address_px[4:0] == 5'b11101) && !(dfi_cs_px)) |-> ##(trddata_en) dfi_rddata_en_px && !(a) ); //This line encapsulates the 2 lines below; 2 assertions must be used
	  /*
	  ( ((dfi_address_p0[4:0] == 5'b11101) && !(dfi_cs_p0)) |-> (##(trddata_en) dfi_rddata_en_p0) )
          or
          ( ((dfi_address_p1[4:0] == 5'b11101) && !(dfi_cs_p1)) |-> (##(trddata_en) dfi_rddata_en_p1 && !(dfi_rddata_en_p0) ) ); //Making sure that no rddata_en is driven before two phy clocks (i.e., phases)
	  */
	endproperty: dfi_rddata_en_signal_asserted


	/*****************************DFI_DR_13 && DFI_DR_16*******************************************/
        // From Plan: asserting on tphy_rdlat
        property dfi_rddata_en_to_dfi_rddata_valid_delay(dfi_rddata_en, dfi_rddata_valid);
	  @(posedge dfi_phy_clk_i) disable iff (!reset_n_i)
	  $rose(dfi_rddata_en) |-> ##[0:tphy_rdlat+1] $rose(dfi_rddata_valid) ;
           //**NOTE:       Added 1 to all timing that envolves an input singal (TB stimulus) AND an output signal (DUT response) 
           //              because we drive on the negative edge, but the DUT's output is on the positive edge
	endproperty: dfi_rddata_en_to_dfi_rddata_valid_delay

//==========================================================================//
//                      DFI Assertions for 1 to 2 ratio                     //
//==========================================================================//
        dfi_address_p0_VALID:           assert property (dfi_address_valid(dfi_cs_p0, dfi_address_p0)) 
		                        else `uvm_error("DDR Assertions",  $sformatf("Spacing between dfi_cs_p0 and dfi_address_p0 is not %d",tcmd_lat));
	COV_dfi_address_p0_VALID:       cover property(dfi_address_valid(dfi_cs_p0, dfi_address_p0));

	CS_n_to_dfi_cs_Translation_p0:  assert property(CS_n_to_dfi_cs_translation(dfi_cs_p0, CS_DA_o, 0))
		                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_cs_p0 translational delay between DFI interface and JEDEC interface isn't tctrl_delay: %d",tctrl_delay));
	COV_CS_n_to_dfi_cs_Translation_p0:cover property(CS_n_to_dfi_cs_translation(dfi_cs_p0, CS_DA_o, 0));

	dfi_address_to_CA_delay_p0:     assert property(dfi_address_to_CA_translation(dfi_cs_p0, dfi_address_p0, CA_DA_o, 0)) 
		                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_address_p0 translational delay between DFI interface and JEDEC interface isn't tctrl_delay: %d --- Sampled CA: ",tctrl_delay, $sampled(CA_DA_o)));
	COV_dfi_address_to_CA_delay_p0: cover property(dfi_address_to_CA_translation(dfi_cs_p0, dfi_address_p0, CA_DA_o, 0));

	dfi_rddata_signal_valid_p0:     assert property(dfi_rddata_signal_valid(dfi_rddata_valid_w0, dfi_rddata_w0))
		                        else `uvm_error("DDR Assertions",  $sformatf("dfi_rddata_w0 is sent without dfi_rddata_valid_w0"));
	/*
	dfi_rddata_en_signal_asserted_p0_p1:assert property(dfi_rddata_en_signal_asserted(dfi_address_p0, dfi_cs_p0, dfi_rddata_en_p0))
		                        else `uvm_error("DDR Assertions",  $sformatf("Relating to dfi_address_p to dfi_rddata_en delay -- trddata_en=%d PHY_CLK cycles", trddata_en));
	*/
	dfi_rddata_en_signal_asserted_p0:assert property(dfi_rddata_en_signal_asserted(dfi_address_p0, dfi_cs_p0, dfi_rddata_en_p0, 0))
		                        else `uvm_error("DDR Assertions",  $sformatf("Relating to dfi_address_p to dfi_rddata_en delay -- trddata_en=%d PHY_CLK cycles", trddata_en));
	dfi_rddata_en_signal_asserted_p1:assert property(dfi_rddata_en_signal_asserted(dfi_address_p1, dfi_cs_p1, dfi_rddata_en_p1, dfi_rddata_en_p0))
		                        else `uvm_error("DDR Assertions",  $sformatf("Relating to dfi_address_p to dfi_rddata_en delay -- trddata_en=%d PHY_CLK cycles", trddata_en));
		             
		                        
        dfi_address_p1_VALID:           assert property(dfi_address_valid(dfi_cs_p1, dfi_address_p1))
                                        else `uvm_error("DDR Assertions",  $sformatf("Spacing between dfi_cs_p1 and dfi_address_p1 is not %d",tcmd_lat));
        COV_dfi_address_p1_VALID:       cover property(dfi_address_valid(dfi_cs_p1, dfi_address_p1));

        CS_n_to_dfi_cs_Translation_p1:  assert property(CS_n_to_dfi_cs_translation(dfi_cs_p1, CS_DA_o, 1))//$display("CS_n_to_dfi_cs_translation Assertion Passed at time t=%d", $time);
                                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_cs_p1 translational delay between DFI interface and JEDEC interface isn't tctrl_delay: %d",tctrl_delay));
        COV_CS_n_to_dfi_cs_Translation_p1:cover property(CS_n_to_dfi_cs_translation(dfi_cs_p1, CS_DA_o, 1));
        
        dfi_address_to_CA_delay_p1:     assert property(dfi_address_to_CA_translation(dfi_cs_p1, dfi_address_p1, CA_DA_o, 1))
                                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_address_p1 translational delay between DFI interface and JEDEC interface isn't tctrl_delay: %d",tctrl_delay));
        COV_dfi_address_to_CA_delay_p1: cover property(dfi_address_to_CA_translation(dfi_cs_p1, dfi_address_p1, CA_DA_o, 1));
        
        dfi_rddata_signal_valid_p1:     assert property(dfi_rddata_signal_valid(dfi_rddata_valid_w1, dfi_rddata_w1))
                                        else `uvm_error("DDR Assertions",  $sformatf("dfi_rddata_w1 is sent without dfi_rddata_valid_w1"));

        dfi_rddata_en_to_dfi_rddata_valid_delay_p0:assert property(dfi_rddata_en_to_dfi_rddata_valid_delay(dfi_rddata_en_p0, dfi_rddata_valid_w0))
                                        else `uvm_error("DDR Assertions",  $sformatf("DFI_DR_13 && DFI_DR_16 Failure -- dfi_rddata_en to dfi_rddata_valid delay is not %d", tphy_rdlat));
        dfi_rddata_en_to_dfi_rddata_valid_delay_p1:assert property(dfi_rddata_en_to_dfi_rddata_valid_delay(dfi_rddata_en_p1, dfi_rddata_valid_w1))
                                        else `uvm_error("DDR Assertions",  $sformatf("DFI_DR_13 && DFI_DR_16 Failure -- dfi_rddata_en to dfi_rddata_valid delay is not %d", tphy_rdlat));
`endif

`ifdef ratio_1_to_4
//==========================================================================//
//                       DFI Properties for 1 to 4 ratio                    //
//==========================================================================//
	/*****************************DFI_DR_1 && DFI_DR_2*******************************************/
	// From plan:   command is driven for at least 1 DFI PHY clock cycle after the CS is active.
	//              tcmd_lat specifies the number of DFI clocks after the dfi_cs signal is asserted until the associated CA signals are driven.
	property dfi_address_valid(dfi_cs_px, dfi_address_px);
	  @(posedge dfi_clk_i) disable iff (!reset_n_i)
	    !dfi_cs_px |-> (##tcmd_lat !$isunknown(dfi_address_px) [*1:2]);
	endproperty: dfi_address_valid

	/*****************************DFI_DR_6*******************************************/
	// From plan:   Check the correct behaviour of CS_n on the DRAM interface (follows the behaviour of dfi_cs meaning 0=>1=>0)
	// Elaboration: when dfi_cs toggles (1=>0=>1), CS_n should follow the exact same behaviour after translation delay of tctrl_delay
	property  CS_n_to_dfi_cs_translation(dfi_cs_px, CS_DA_o, phase); //where phase is the phase number
	  bit CS_tmp;
	  @(posedge dfi_phy_clk_i) disable iff (!reset_n_i)
            ($changed(dfi_cs_px), CS_tmp=dfi_cs_px) ##1 1 |-> ##(4*tctrl_delay+phase) CS_DA_o===CS_tmp;  //Working
            //**NOTE:   Multiplied tctrl_delay by 4 because 1_to_4 ratio; tctrl_delay is 1 dfi_clk cycle. 
	    //**NOTE:   added the "##1 1" because the change is detected 1 phy cycle before the negedge of dfi_clk.
	    //**NOTE:   the "phase" accounts for the additional delay added for each phase  
	endproperty: CS_n_to_dfi_cs_translation

	/*****************************DFI_DR_7 -----NOT IMPLEMENTED BY THE DESIGN YET------*******************************************/
	// From plan: Check the correct behaviour of reset_n on the DRAM interface (follows the behaviour of dfi_reset_n meaning 0=>1=>0)
	// Elaboration: when dfi_reset_n toggles, reset_n should follow the exact same behaviour after translation delay of tctrl_delay
	/*
	property  ;
	  @(posedge dfi_clk_i) 
	    (dfi_reset_n ##1 !dfi_reset_n ##1 dfi_reset_n) |-> (##tctrl_delay (reset_n ##1 !reset_n ##1 reset_n));
	endproperty: 
	ERR_: assert property();
	*/   

	/*****************************DFI_DR_11*******************************************/
	// Translation delay between DFI and JEDEC
	property dfi_address_to_CA_translation(dfi_cs_px, dfi_address_px,CA_DA_o, phase);
	  logic [13:0] CA_temp;
	  @(posedge dfi_phy_clk_i) disable iff (!reset_n_i)
	   ($changed(dfi_address_px) , CA_temp=dfi_address_px) ##1 1 |-> ##(4*tctrl_delay+phase) (CA_temp===CA_DA_o);
	endproperty: dfi_address_to_CA_translation

	/*****************************DFI_DR_13*******************************************/
	//From Plan: check that valid data is being transferred when the dfi_rddata_valid signal is asserted
	property dfi_rddata_signal_valid(dfi_rddata_valid_wx, dfi_rddata_wx);
	  @(posedge dfi_clk_i) disable iff (!reset_n_i)
	    dfi_rddata_valid_w0 |-> !$isunknown(dfi_rddata_wx);
	endproperty: dfi_rddata_signal_valid

	/*****************************DFI_DR_13 && DFI_DR_16*******************************************/
	// From Plan: dfi_rddata_en is asserted after a RD command by trddata_en DFI_PHY_clock cycles
	property dfi_rddata_en_signal_asserted(dfi_address_px, dfi_cs_px, dfi_rddata_en_px, k, a, b, c);
	  @(posedge dfi_clk_i) disable iff (!reset_n_i)
          ( ((dfi_address_px[4:0] == 5'b11101) && !(dfi_cs_px)) |-> ##(k*trddata_en) dfi_rddata_en_px && !(a||b||c) ); //This line encapsulates the 4 lines below; 4 assertions must be used
	  /*
	  ( ((dfi_address_p0[4:0] == 5'b11101) && !(dfi_cs_p0)) |-> ##(0*trddata_en) dfi_rddata_en_p2 && !(dfi_rddata_en_p0||dfi_rddata_en_p1) ) //Making sure that no rddata_en is driven before two phy clocks (i.e., phases)
          or
          ( ((dfi_address_p1[4:0] == 5'b11101) && !(dfi_cs_p1)) |-> ##(0*trddata_en) dfi_rddata_en_p3 && !(dfi_rddata_en_p0||dfi_rddata_en_p1||dfi_rddata_en_p2) )
	  or
	  ( ((dfi_address_p2[4:0] == 5'b11101) && !(dfi_cs_p2)) |-> ##(1*trddata_en) dfi_rddata_en_p0 )
          or
          ( ((dfi_address_p3[4:0] == 5'b11101) && !(dfi_cs_p3)) |-> ##(1*trddata_en) dfi_rddata_en_p1 && !(dfi_rddata_en_p0) ); //Must check that dfi_rddata_en_p0 is zero because trddata_en is Measured from the 2nd rising edge of the DFI_command_clock of the command
	  */
	endproperty: dfi_rddata_en_signal_asserted


	/*****************************DFI_DR_13 && DFI_DR_16*******************************************/
        // From Plan: asserting on tphy_rdlat
        property dfi_rddata_en_to_dfi_rddata_valid_delay(dfi_rddata_en, dfi_rddata_valid);
	  @(posedge dfi_phy_clk_i) disable iff (!reset_n_i)
	  $rose(dfi_rddata_en) |-> ##[0:tphy_rdlat+1] $rose(dfi_rddata_valid) ;
           //**NOTE:       Added 1 to all timing that envolves an input singal (TB stimulus) AND an output signal (DUT response) 
           //              because we drive on the negative edge, but the DUT's output is on the positive edge
	endproperty: dfi_rddata_en_to_dfi_rddata_valid_delay 

//==========================================================================//
//                      DFI Assertions for 1 to 4 ratio                     //
//==========================================================================//
        dfi_address_VALID_p0:           assert property (dfi_address_valid(dfi_cs_p0, dfi_address_p0)) 
		                        else `uvm_error("DDR Assertions",  $sformatf("Spacing between dfi_cs_p0 and dfi_address_p0 is not %d",tcmd_lat));
	COV_dfi_address_VALID_p0:       cover property(dfi_address_valid(dfi_cs_p0, dfi_address_p0));

	CS_n_to_dfi_cs_Translation_p0:  assert property(CS_n_to_dfi_cs_translation(dfi_cs_p0, CS_DA_o, 0))
		                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_cs_p0 translational delay between DFI interface and JEDEC interface isn't tctrl_delay=%d",tctrl_delay+0));
	COV_CS_n_to_dfi_cs_Translation_p0:cover property(CS_n_to_dfi_cs_translation(dfi_cs_p0, CS_DA_o, 0));

	dfi_address_to_CA_delay_p0:     assert property(dfi_address_to_CA_translation(dfi_cs_p0, dfi_address_p0, CA_DA_o, 0)) 
		                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_address_p0 translational delay between DFI interface and JEDEC interface isn't tctrl_delay=%d --- Sampled CA: ",tctrl_delay+0, $sampled(CA_DA_o)));
	COV_dfi_address_to_CA_delay_p0: cover property(dfi_address_to_CA_translation(dfi_cs_p0, dfi_address_p0, CA_DA_o, 0));

	dfi_rddata_signal_valid_p0:     assert property(dfi_rddata_signal_valid(dfi_rddata_valid_w0, dfi_rddata_w0))
		                        else `uvm_error("DDR Assertions",  $sformatf("dfi_rddata_w0 is sent without dfi_rddata_valid_w0"));
	/*
	dfi_rddata_en_signal_asserted_p0_p1_p2_p3:assert property(dfi_rddata_en_signal_asserted(dfi_address_p0, dfi_cs_p0, dfi_rddata_en_p0))
		                        else `uvm_error("DDR Assertions",  $sformatf("Relating to dfi_address_p to dfi_rddata_en delay -- trddata_en=%d PHY_CLK cycles", trddata_en));
	*/
	dfi_rddata_en_signal_asserted_p0:assert property(dfi_rddata_en_signal_asserted(dfi_address_p0, dfi_cs_p0, dfi_rddata_en_p2, 0, dfi_rddata_en_p0, dfi_rddata_en_p1, 0))
		                        else `uvm_error("DDR Assertions",  $sformatf("Relating to dfi_address_p to dfi_rddata_en delay -- trddata_en=%d PHY_CLK cycles", trddata_en));
	dfi_rddata_en_signal_asserted_p1:assert property(dfi_rddata_en_signal_asserted(dfi_address_p1, dfi_cs_p1, dfi_rddata_en_p3, 0, dfi_rddata_en_p0, dfi_rddata_en_p1, dfi_rddata_en_p2))
		                        else `uvm_error("DDR Assertions",  $sformatf("Relating to dfi_address_p to dfi_rddata_en delay -- trddata_en=%d PHY_CLK cycles", trddata_en));
	dfi_rddata_en_signal_asserted_p2:assert property(dfi_rddata_en_signal_asserted(dfi_address_p2, dfi_cs_p2, dfi_rddata_en_p0, 1, 0, 0, 0))
		                        else `uvm_error("DDR Assertions",  $sformatf("Relating to dfi_address_p to dfi_rddata_en delay -- trddata_en=%d PHY_CLK cycles", trddata_en));
	dfi_rddata_en_signal_asserted_p3:assert property(dfi_rddata_en_signal_asserted(dfi_address_p3, dfi_cs_p3, dfi_rddata_en_p1, 1, dfi_rddata_en_p0, 0, 0))
		                        else `uvm_error("DDR Assertions",  $sformatf("Relating to dfi_address_p to dfi_rddata_en delay -- trddata_en=%d PHY_CLK cycles", trddata_en));

        dfi_address_p1_VALID_p1:        assert property(dfi_address_valid(dfi_cs_p1, dfi_address_p1))
                                        else `uvm_error("DDR Assertions",  $sformatf("Spacing between dfi_cs_p1 and dfi_address_p1 is not %d",tcmd_lat));
        COV_dfi_address_p1_VALID_p1:    cover property(dfi_address_valid(dfi_cs_p1, dfi_address_p1));

        dfi_address_p2_VALID_p2:        assert property(dfi_address_valid(dfi_cs_p2, dfi_address_p2))
                                        else `uvm_error("DDR Assertions",  $sformatf("Spacing between dfi_cs_p2 and dfi_address_p2 is not %d",tcmd_lat));
        COV_dfi_address_p2_VALID_p2:    cover property(dfi_address_valid(dfi_cs_p2, dfi_address_p2));

        dfi_address_p3_VALID_p3:        assert property(dfi_address_valid(dfi_cs_p3, dfi_address_p3))
                                        else `uvm_error("DDR Assertions",  $sformatf("Spacing between dfi_cs_p3 and dfi_address_p3 is not %d",tcmd_lat));
        COV_dfi_address_p3_VALID_p3:    cover property(dfi_address_valid(dfi_cs_p3, dfi_address_p3));

        CS_n_to_dfi_cs_Translation_p1:  assert property(CS_n_to_dfi_cs_translation(dfi_cs_p1, CS_DA_o, 1))
                                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_cs_p1 translational delay between DFI interface and JEDEC interface isn't tctrl_delay=%d",tctrl_delay));
        COV_CS_n_to_dfi_cs_Translation_p1:cover property(CS_n_to_dfi_cs_translation(dfi_cs_p1, CS_DA_o, 1));//, 1)); 

        CS_n_to_dfi_cs_Translation_p2:  assert property(CS_n_to_dfi_cs_translation(dfi_cs_p2, CS_DA_o, 2))
                                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_cs_p2 translational delay between DFI interface and JEDEC interface isn't tctrl_delay=%d",tctrl_delay));
        COV_CS_n_to_dfi_cs_Translation_p2:cover property(CS_n_to_dfi_cs_translation(dfi_cs_p2, CS_DA_o, 2));

        CS_n_to_dfi_cs_Translation_p3:  assert property(CS_n_to_dfi_cs_translation(dfi_cs_p3, CS_DA_o, 3))
                                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_cs_p3 translational delay between DFI interface and JEDEC interface isn't tctrl_delay=%d",tctrl_delay));
        COV_CS_n_to_dfi_cs_Translation_p3:cover property(CS_n_to_dfi_cs_translation(dfi_cs_p3, CS_DA_o, 3));

        dfi_address_to_CA_delay_p1:     assert property(dfi_address_to_CA_translation(dfi_cs_p1, dfi_address_p1, CA_DA_o, 1))
                                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_address_p1 translational delay between DFI interface and JEDEC interface isn't tctrl_delay=%d",tctrl_delay));
        COV_dfi_address_to_CA_delay_p1: cover property(dfi_address_to_CA_translation(dfi_cs_p1, dfi_address_p1, CA_DA_o, 1));

        dfi_address_to_CA_delay_p2:     assert property(dfi_address_to_CA_translation(dfi_cs_p2, dfi_address_p2, CA_DA_o, 2))
                                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_address_p2 translational delay between DFI interface and JEDEC interface isn't tctrl_delay=%d",tctrl_delay));
        COV_dfi_address_to_CA_delay_p2: cover property(dfi_address_to_CA_translation(dfi_cs_p2, dfi_address_p2, CA_DA_o, 2));

        dfi_address_to_CA_delay_p3:     assert property(dfi_address_to_CA_translation(dfi_cs_p3, dfi_address_p3, CA_DA_o, 3))
                                        else `uvm_error("DDR Assertions",  $sformatf("The dfi_address_p3 translational delay between DFI interface and JEDEC interface isn't tctrl_delay=%d",tctrl_delay));
        COV_dfi_address_to_CA_delay_p3: cover property(dfi_address_to_CA_translation(dfi_cs_p3, dfi_address_p3, CA_DA_o, 3));
        
        dfi_rddata_signal_valid_p1:     assert property(dfi_rddata_signal_valid(dfi_rddata_valid_w1, dfi_rddata_w1))
                                        else `uvm_error("DDR Assertions",  $sformatf("dfi_rddata_w1 is sent without dfi_rddata_valid_w1"));

        dfi_rddata_signal_valid_p2:     assert property(dfi_rddata_signal_valid(dfi_rddata_valid_w2, dfi_rddata_w2))
                                        else `uvm_error("DDR Assertions",  $sformatf("dfi_rddata_w2 is sent without dfi_rddata_valid_w2"));
        
        dfi_rddata_signal_valid_p3:     assert property(dfi_rddata_signal_valid(dfi_rddata_valid_w3, dfi_rddata_w3))
                                        else `uvm_error("DDR Assertions",  $sformatf("dfi_rddata_w3 is sent without dfi_rddata_valid_w3"));

        dfi_rddata_en_to_dfi_rddata_valid_delay_p0:assert property(dfi_rddata_en_to_dfi_rddata_valid_delay(dfi_rddata_en_p0, dfi_rddata_valid_w0))
                                        else `uvm_error("DDR Assertions",  $sformatf("DFI_DR_13 && DFI_DR_16 Failure -- dfi_rddata_en to dfi_rddata_valid delay is not %d", tphy_rdlat));
        dfi_rddata_en_to_dfi_rddata_valid_delay_p1:assert property(dfi_rddata_en_to_dfi_rddata_valid_delay(dfi_rddata_en_p1, dfi_rddata_valid_w1))
                                        else `uvm_error("DDR Assertions",  $sformatf("DFI_DR_13 && DFI_DR_16 Failure -- dfi_rddata_en to dfi_rddata_valid delay is not %d", tphy_rdlat));
	dfi_rddata_en_to_dfi_rddata_valid_delay_p2:assert property(dfi_rddata_en_to_dfi_rddata_valid_delay(dfi_rddata_en_p2, dfi_rddata_valid_w2))
                                        else `uvm_error("DDR Assertions",  $sformatf("DFI_DR_13 && DFI_DR_16 Failure -- dfi_rddata_en to dfi_rddata_valid delay is not %d", tphy_rdlat));
        dfi_rddata_en_to_dfi_rddata_valid_delay_p3:assert property(dfi_rddata_en_to_dfi_rddata_valid_delay(dfi_rddata_en_p3, dfi_rddata_valid_w3))
                                        else `uvm_error("DDR Assertions",  $sformatf("DFI_DR_13 && DFI_DR_16 Failure -- dfi_rddata_en to dfi_rddata_valid delay is not %d", tphy_rdlat));

`endif

`endif // This guard turns DFI off to avoid RAM problem on windows


task automatic detect_preamble(input bit[2:0]pre_amble) ;
	case (pre_amble[2:0])
	3'b000: begin               
			//@(posedge dfi_phy_clk_i);
			if (DQS_AD_i) 
				begin  /*Continue*/ end
			else 
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d -- First edge is not HIGH", pre_amble));
				return;
				end
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin /*result = 1;//Success */ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d -- Second edge is not LOW", pre_amble));
				return;
				end
		end
	3'b001: begin               // 0010 Pattern - in the jedec, this pattern takes 2 tCK, but the design changes DQS
				    //  in the positive edge of the clock only, so it takes 4 tCK  
			//@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d -- First edge is not LOW", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d -- 2nd edge is not LOW", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d -- 3rd edge is not HIGH", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin /*result = 1;//Success */ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d -- 4th edge is not LOW", pre_amble));
				return;
				end//result = 0;
		end
	3'b010: begin               // 1110 Pattern - in the jedec, this pattern takes 2 tCK, but the design changes DQS
				    //  in the positive edge of the clock only, so it takes 4 tCK
			//@(posedge dfi_phy_clk_i);
			if (DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d -- First edge is not HIGH", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d -- 2nd edge is not HIGH", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d -- 3rd edge is not HIGH", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin /*result = 1;//Success */ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d -- 4th edge is not LOW", pre_amble));
				return;
				end//result = 0;
		end
	3'b011: begin               // 000010 Pattern - in the jedec, this pattern takes 3 tCK, but the design changes DQS
				    //  in the positive edge of the clock only, so it takes 6 tCK
			//@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin /*result = 1;//Success */ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
		end
	3'b100: begin               // 00001010 Pattern - in the jedec, this pattern takes 4 tCK, but the design changes DQS
				    //  in the positive edge of the clock only, so it takes 8 tCK
			//@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (DQS_AD_i) 
				begin  /*Continue*/ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin /*result = 1;//Success */ end
			else
				begin
				`uvm_error("DDR Assertions",  $sformatf("detect_preamble failure -- pre_amble setting is: %d", pre_amble));
				return;
				end//result = 0;
		end
	default: begin
		    //nothing
		 end
    endcase
endtask
task automatic detect_postamble(input bit post_amble);//, output bit result); 
	case (post_amble)
	1'b0: begin               
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin /*result = 1;//Success */ end
			else
				`uvm_error("DDR Assertions",  $sformatf("detect_postamble failure -- post_amble setting is: %d", post_amble));//result = 0;	//Error
		end
	1'b1: begin              
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin  /*Continue*/ end
			else
				`uvm_error("DDR Assertions",  $sformatf("detect_postamble failure -- post_amble setting is: %d", post_amble));//result = 0;
			@(posedge dfi_phy_clk_i);
			if (DQS_AD_i) 
				begin  /*Continue*/ end
			else
				`uvm_error("DDR Assertions",  $sformatf("detect_postamble failure -- post_amble setting is: %d", post_amble));//result = 0;
			@(posedge dfi_phy_clk_i);
			if (!DQS_AD_i) 
				begin /*result = 1;//Success */ end
			else
				`uvm_error("DDR Assertions",  $sformatf("detect_postamble failure -- post_amble setting is: %d", post_amble));//result = 0;
		end
	default: begin
		    //nothing
		 end
    endcase
endtask

////==============================================================================// 		
// Description: The following funtions are used to determine the type of command
//==============================================================================//
function bit is_ACT();
	return CA_DA_o[1:0]===2'b00 && !CS_DA_o;
endfunction
function bit is_RD();
	return CA_DA_o[4:0]===5'b11101 && !CS_DA_o;
endfunction
function bit is_MRW();
	return CA_DA_o[4:0]===5'b00101 && !CS_DA_o;
endfunction
function bit is_MRR();
	return (CA_DA_o[4:0]==5'b10101 && !CS_DA_o);
endfunction
function bit is_PREab();
	return CA_DA_o[4:0]===5'b01011 && !CS_DA_o;
endfunction

endmodule
