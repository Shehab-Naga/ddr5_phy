// TODO Preamble
// TODO Interamble
// TO postpremble

module dfi_jedec_asserts
	#(
	parameter device_width = 4,
	/**************************Timing Parameters*******************************/
	parameter tMRW 	= 2,     // specify the needed delay as "number of cycles"
	parameter tMRR 	= 2,
	parameter tMRD  = 2,
	parameter tRP 	= 1,
	parameter tCMD_cancel = 1,
	parameter tRRD_S = 1,
	parameter tRRD_L = 1,
	parameter RL = 5             

	 
  )
(
	// JEDEC Interface 
	input 	logic dfi_phy_clk,
	input	logic [13:0] CA_DA_o,
	input   logic CS_DA_o,
	input   logic CA_VALID_DA_o,
	input	logic DQS_AD_i,
	input   logic [2*device_width-1:0] DQ_AD_i
);


//-------------------------------------------------------------------------------------------------------------
//------------------------------------------------Property definitions-----------------------------------------
//-------------------------------------------------------------------------------------------------------------

/************************************************JEDEC_DR_1**&**JEDEC_DR_2*******************************************/

// The mode register contents are available on the second 8 UI’s of the burst and are repeated across all DQ’s after the RL following the MRR command
/*property MRR_DATA_spacings ;
    logic [1:0] x;
  @(posedge dfi_phy_clk)
 ((CA_DA_o[4:0] == 5'b10101) |->(##RL DQ_AD_i[1:0] == 2'b00 ##4 x = DQ_AD_i[1:0]) and 
 								(##RL DQ_AD_i[3:2] == 2'b11 ##4 DQ_AD_i[3:2] != x) and
							 	(##RL DQ_AD_i[5:4] == 2'b00 ##4 DQ_AD_i[5:4] == x) and
 								(##RL DQ_AD_i[7:6] == 2'b11 ##4 DQ_AD_i[7:6] != x)); 
endproperty: MRR_DATA_spacings
*/
property MRR_DATA_spacings ;
  @(posedge dfi_phy_clk)
 (CA_DA_o[4:0] == 5'b10101) |-> ##(RL+1+4) (DQ_AD_i[1:0] == !DQ_AD_i[3:2]) and 
 					 (DQ_AD_i[1:0] == DQ_AD_i[5:4])  and
					 (DQ_AD_i[1:0] == !DQ_AD_i[7:6]);
endproperty: MRR_DATA_spacings
property MRR_DATA_spacings_ZEROs_ONEs ;
  @(posedge dfi_phy_clk)
 (CA_DA_o[4:0] == 5'b10101) |-> ##(RL+1) ( (DQ_AD_i[1:0] == 2'b00) & (DQ_AD_i[3:2] == 2'b11) & (DQ_AD_i[5:4] == 2'b00) & (DQ_AD_i[7:6] == 2'b11) )
				      ##1 ( (DQ_AD_i[1:0] == 2'b00) & (DQ_AD_i[3:2] == 2'b11) & (DQ_AD_i[5:4] == 2'b00) & (DQ_AD_i[7:6] == 2'b11) )
				      ##1 ( (DQ_AD_i[1:0] == 2'b00) & (DQ_AD_i[3:2] == 2'b11) & (DQ_AD_i[5:4] == 2'b00) & (DQ_AD_i[7:6] == 2'b11) )
				      ##1 ( (DQ_AD_i[1:0] == 2'b00) & (DQ_AD_i[3:2] == 2'b11) & (DQ_AD_i[5:4] == 2'b00) & (DQ_AD_i[7:6] == 2'b11) );
endproperty: MRR_DATA_spacings

/************************************************JEDEC_DR_3*******************************************/
// From Plan: DQS is toggled for the duration of the MRR burst.	--> DQS is toggled for 16 BL 
property MRR_DQS_toggle ;
	@(posedge dfi_phy_clk)          
	(CA_DA_o[0:4] == 5'b10101) |->  ##(RL+1) ( ($changed(DQS_AD_i))[=1] )[*16];
endproperty: MRR_DQS_toggle

/************************************************JEDEC_DR_7*******************************************/
// From Plan: The read pre-amble and post-amble of MRR are same as normal read. 
property MRR_preamble;
  bit result;
  @(posedge dfi_phy_clk)
    (!CS_DA_o & CA_DA_o[4:0] == 5'b11101 , result=0) |-> ##(RL+1-tRPRE) (1, detect_preamble(pre_amble, result)) ##0 result;
endproperty: MRR_preamble
property MRR_postamble;
  bit result;
  @(posedge dfi_phy_clk)
    (!CS_DA_o & CA_DA_o[4:0] == 5'b11101 , result=0) |-> ##(RL+1+tRPRE+8) (1, detect_postamble(post_amble, result)) ##0 result; //burst_length is always 8 for MRR
endproperty: MRR_postamble

/************************************************JEDEC_DR_8*******************************************/
// Elaboration: spacing between MRR CMD and any other CMD is tMRR
// Timing between MRR and MRW is CL+BL/2+1 : not implemented yet
property MRR_CMD_spacings ;
  @(posedge dfi_phy_clk)          
((CA_DA_o[4:0] == 5'b10101) |-> ##1 CS_DA_o [*tMRR]); 
endproperty: MRR_CMD_spacings

/************************************************JEDEC_DR_8*******************************************/
// Elaboration: spacing between two MRW CMDs is tMRW and any other CMD is tMRR
property MRW_CMD_spacings ;
  @(posedge dfi_phy_clk)
((CA_DA_o[4:0] == 5'b00101) |-> ##1 ((CS_DA_o [*tMRW:tMRD] ##1 CA_DA_o[4:0] == 5'b00101) or CS_DA_o [*tMRD])) ; 
endproperty: MRW_CMD_spacings

/************************************************JEDEC_DR_11*******************************************/
// Elaboration: spacing between PRE CMDs and MRR/MRW is tRP
property PRE_CMD_spacings ;
  @(posedge dfi_phy_clk)
  ((CA_DA_o[4:0] == 5'b01011) |-> ##1 (CS_DA_o [*tRP] ##1 ((CA_DA_o[4:0] == 5'b00101) || (CA_DA_o[4:0] == 5'b10101)))) ;
  endproperty: PRE_CMD_spacings

/************************************************JEDEC_DR_12*******************************************/
//When a defined register byte (MR#) contains an “RFU” bit, the host must write a ZERO for those specific bits
property host_Write_zero_to_RFU ;
  @(posedge dfi_phy_clk)
(CA_DA_o[4:0] == 5'b00101 & CA_DA_o[12:5] == 0     |=> CA_DA_o[7] ==  0) and
(CA_DA_o[4:0] == 5'b00101 & CA_DA_o[12:5] == 8'h08 |=> CA_DA_o[5] ==  0) and
(CA_DA_o[4:0] == 5'b00101 & CA_DA_o[12:5] == 8'h28 |=> CA_DA_o[7:3] ==0); 
endproperty: host_Write_zero_to_RFU

/************************************************JEDEC_DR_13*******************************************/
//When the host issues an MRR to a defined register (MR#) that contains RFU bits in it, those specific bits shall always produce a ZERO.
property host_Read_zero_from_RFU ;
  @(posedge dfi_phy_clk)
(CA_DA_o[4:0] == 5'b10101 & CA_DA_o[12:5] == 8'h00 & ~CS_DA_o |-> ##(RL+1+3) DQ_AD_i[1:0] == 2'bx0) and
(CA_DA_o[4:0] == 5'b10101 & CA_DA_o[12:5] == 8'h08 & ~CS_DA_o |-> ##(RL+1+2) DQ_AD_i[1:0] == 2'bx0) ;
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
  bit result;
  @(posedge dfi_phy_clk)
    (!CS_DA_o & CA_DA_o[4:0] == 5'b11101 , result=0) |-> ##(RL+1-tRPRE) (1, detect_preamble(pre_amble, result)) ##0 result;
endproperty: RD_preamble
property RD_postamble;
  bit result;
  @(posedge dfi_phy_clk)
    (!CS_DA_o & CA_DA_o[4:0] == 5'b11101 , result=0) |-> ##(RL+1+tRPRE+burst_length/2) (1, detect_postamble(post_amble, result)) ##0 result;
endproperty: RD_postamble

/************************************************JEDEC_DR_21*******************************************/
// The minimum timing between a cancelled CMD and the following CMD is tCMD_cancel 
property CMD_Cancel_timing ;
  @(posedge dfi_phy_clk)
(!CS_DA_o[*2] ##tCMD_cancel !CS_DA_o ##1 CS_DA_o); 
endproperty: CMD_Cancel_timing


/************************************************JEDEC_DR_24*******************************************/
// Once a bank has been precharged, it is in the idle state and must be activated prior to any READ or WRITE commands being issued to that bank
property Pre_then_ACT ;
  @(posedge dfi_phy_clk)
((CA_DA_o[4:0] == 5'b11011 ##[0:$] CA_DA_o[4:0] == 5'b11101) or 
( CA_DA_o[4:0] == 5'b11011 ##[0:$] CA_DA_o[4:0] == 5'b00101) or 
( CA_DA_o[4:0] == 5'b11011 ##[0:$] CA_DA_o[4:0] == 5'b10101))  |-> 0;
endproperty: Pre_then_ACT

/************************************************JEDEC_DR_25***&**JEDEC_DR_31*******************************************/
// A PRECHARGE command is allowed if there is no open row in that bank (idle state) or if the previously open row is already in the process of precharging. 
property ACT_then_Pre_no_allowed ;
  @(posedge dfi_phy_clk)
((CA_DA_o[1:0] == 2'b00 ##[0:$] CA_DA_o[4:0] == 5'b11011) 
( CA_DA_o[1:0] == 2'b00 ##[0:$] CA_DA_o[4:0] == 5'b00101) 
( CA_DA_o[1:0] == 2'b00 ##[0:$] CA_DA_o[4:0] == 5'b10101)) |-> 0;
endproperty: ACT_then_Pre_no_allowed

/************************************************JEDEC_DR_28***&**JEDEC_DR_29*******************************************/
// tRRD_S (short) is used for timing between banks located in different bank groups.
// tRRD_L (long) is used for timing between banks located in the same bank group. 
property Different_AND_Same_bank_group_ACT_timing ;
  logic [2:0] temp;
  @(posedge dfi_phy_clk)
(((CA_DA_o[1:0] == 2'b00), temp = CA_DA_o[10:8]) |-> ##1 (CS_DA_o [*tRRD_S] or (CS_DA_o [*tRRD_L] ##1 CA_DA_o[10:8] == temp))); 

endproperty: Different_AND_Same_bank_group_ACT_timing


/************************************************JEDEC_DR_31*******************************************/
//Read Latency (RL or CL) is defined from the Read command to data and is not affected by the Read DQS offset timing (MR40 OP[2:0]).
property RDCMD_TO_DATA_DELAY ;
  @(posedge dfi_phy_clk)
(CA_DA_o[4:0] == 5'b11101 & ~CS_DA_o |-> ##(RL+1) ~$isunknown(DQ_AD_i));
endproperty: RDCMD_TO_DATA_DELAY

/************************************************JEDEC_DR_32************************************************/
// From Plan: "If CA5:BL*=L, the command places the DRAM into the alternate Burst mode described by MR0[1:0] instead of the default Burst Length 16 mode."
property  ;
  @(posedge dfi_phy_clk)
  (CA_DA_o[4:0] == 5'b11101 || CA_DA_o[4:0] == 5'b10101) & ~CS_DA_o 
endproperty: 



/************************************************JEDEC_DR_36************************************************/
//The minimum external Read command to Precharge command spacing to the same bank is equal to tRTP with tRTP being the Internal Read Command to Precharge Command Delay.
property RDToPreSpacing ;
  logic [2:0] temp;
  @(posedge dfi_phy_clk)
(((CA_DA_o[4:0] == 5'b11101), temp = CA_DA_o[7:6]) |-> ##1 (CS_DA_o [*tRTP] ##1 (CA_DA_o[4:0] == 5'b01011) & CA_DA_o[7:6] == temp));
endproperty: RDToPreSpacing



/************************************************JEDEC_DR_37************************************************/
// the minimum ACT to PRE timing, tRAS, must be satisfied as well
// the implemetation of this assertion is not correct
property PreToACTSpacing ;
logic temp;
  @(posedge dfi_phy_clk)
((CA_DA_o[4:0] == 5'b01011) |-> ##1 (CS_DA_o [*tRAS] ##1 (CA_DA_o[4:0] == 5'b01011))) & 
((CA_DA_o[4:0] == 5'b01011) |-> ##1 (CS_DA_o [*tRAS] ##1 (CA_DA_o[4:0] == 5'b01011))) ;
endproperty: PreToACTSpacing

/************************************************JEDEC_DR_37************************************************/
// A dummy RD command is required for the second half of the transfer with a delay of 8 clocks from the first RD command in case of BL32 fixed or BL32 OTF

property DummyRDCMD ;
logic temp = BL;
 @(posedge dfi_phy_clk)
(((CA_DA_o[4:0] == 5'b11101), (temp == BL32), ~CS_DA_o, ##1 CA_DA_o[10]== 1) |-> ##8 (~CS_DA_o & (CA_DA_o[4:0] == 5'b11101 & ##1 CA_DA_o[10] == 0)));
endproperty: DummyRDCMD

property C10_IS_opposite ; 
logic temp = BL;
logic C10;
 @(posedge dfi_phy_clk)
 (((CA_DA_o[4:0] == 5'b11101), (temp == BL32), ~CS_DA_o, ##1 (C10 = CA_DA_o[8] & CA_DA_o[10]== 1)) |-> ##8 (~CS_DA_o & (CA_DA_o[4:0] == 5'b11101) & ##1 (CA_DA_o[8] == ~C10 & CA_DA_o[10]== 0)));

endproperty: C10_IS_opposite


property SecondRD_resembles_first ;
logic temp = BL;
logic [13:0] first_temp_CMD;
logic [13:0] second_temp_CMD;

 @(posedge dfi_phy_clk)
 (((CA_DA_o[4:0] == 5'b11101), (temp == BL32), ~CS_DA_o, first_temp_CMD = CA_DA_o[13:0], ##1 (second_temp_CMD = CA_DA_o[13:0] & CA_DA_o[10]== 1))
 |-> ##8 (~CS_DA_o & (CA_DA_o[13:0] == first_temp_CMD) & ##1 CA_DA_o[7:0] == second_temp_CMD[7:0] & CA_DA_o[13:11] == second_temp_CMD[13:11] & CA_DA_o[9] == second_temp_CMD[9] & CA_DA_o[10]== 0));

endproperty: SecondRD_resembles_first

property BL16InBL32 ;
logic temp = BL;
 @(posedge dfi_phy_clk)
 (((CA_DA_o[4:0] == 5'b11101), (temp == BL32), ~CS_DA_o, ##1  CA_DA_o[10]== 0) ##8 ~ |-> 0; 
endproperty: BL16InBL32

property ReadTOReadSameBank ;
  logic [3:0] temp;
  @(posedge dfi_phy_clk)
(((CA_DA_o[1:0] == 5'b11101), temp = CA_DA_o[10:6]) |-> ##1 (CS_DA_o[*tCCD_S] or (CS_DA_o [*tRRD_L] ##1 CA_DA_o[10:8] == temp))); 

endproperty: ReadTOReadSameBank



//-------------------------------------------------------------------------------------------------------------
//------------------------------------------------Assertions-----------------------------------------
//-------------------------------------------------------------------------------------------------------------
/*Spacing_btn_MRR_Data:           assert property(MRR_DATA_spacings)
				else $error("ERROR: Data should be available on 8 UI's RL after MRR CMD");
COV_Spacing_btn_MRR_Data:       cover property(MRR_DATA_spacings);
*///
Spacing_btn_MRR_CMD:            assert property(MRR_CMD_spacings)
				else $error("ERROR: Spacing between MRR CMD and any other CMD should be tMRR");
COV_Spacing_btn_MRR_CMD:        cover property(MRR_CMD_spacings); 
//
Spacing_btn_MRW_CMD:            assert property(MRW_CMD_spacings)
				else $error("ERROR: Spacing between two MRW CMDs is tMRW and any other CMD should tMRR");
COV_Spacing_btn_MRW_CMD:        cover property(MRW_CMD_spacings);
//
Spacing_btn_PRE_MRR:            assert property(PRE_CMD_spacings)
				else $error("ERROR: Spacing between PRE CMDs and MRR/MRW should be tRP");
COV_Spacing_btn_PRE_MRR:        cover property(PRE_CMD_spacings);
//
host_should_Write_zero_to_RFU:  assert property(host_Write_zero_to_RFU)
				else $error("ERROR: “RFU” bits must be written ZERO by the host");
COV_host_should_Write_zero_to_RFU:        cover property(host_Write_zero_to_RFU);
//
host_should_Read_zero_from_RFU: assert property(host_Read_zero_from_RFU)
				else $error("RFU bits shall always produce a ZERO when it's being read");
COV_host_should_Read_zero_from_RFU:        cover property(host_Read_zero_from_RFU);
//
timing_btn_Canceled_CMD:            assert property(CMD_Cancel_timing)
				else $error("ERROR: The minimum timing between a cancelled CMD and the following CMD should be tCMD_cancel");
COV_timing_btn_Canceled_CMD:        cover property(CMD_Cancel_timing);
//
ACT_Should_follow_PRE:            assert property(Pre_then_ACT)
				else $error("ERROR: a bank must be activated prior to any READ or WRITE commands being issued to that bank");
COV_ACT_Should_follow_PRE:        cover property(Pre_then_ACT);
//
PRE_Mustnt_follow_ACT:            assert property(ACT_then_Pre_no_allowed)
				else $error("ERROR: Precharge CMD mustn't follow activate CMD directely");
COV_PRE_Mustnt_follow_ACT:        cover property(ACT_then_Pre_no_allowed);
//
Timing_btn_several_ACT_CMDs:            assert property(Different_AND_Same_bank_group_ACT_timing)
				else $error("ERROR: timing between banks located in different bank groups should be tRRD_S while timing between banks located in the same bank group should be tRRD_L");
COV_Timing_btn_several_ACT_CMDs:        cover property(Different_AND_Same_bank_group_ACT_timing);
//
Four_ACT_CMD_withen_tFAW:            assert property(Max_timing_for_four_ACT_CMD)
				else $error("ERROR: // Spec: Consecutive ACTIVATE commands, allowed to be issued at tRRDmin, are restricted to a maximum of four within the time period tFAW (four activate window).");
COV_Four_ACT_CMD_withen_tFAW:        cover property(Max_timing_for_four_ACT_CMD);
//


endmodule
/*
function bit is_RD_MRR(); //Check if the command is RD or MRR
	bit r;
	r =	(CA_DA_o[0:4] == 5'b10101) || (CA_DA_o[0:4] == 5'b10111);
	return r;
endfunction
*/

task detect_preamble(input bit[2:0]pre_amble, output bit result); 
	case (pre_amble[2:0])
	3'b000: begin               
			@(posedge dfi_phy_clk);
			if (DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				result = 1;//Success
			else
				result = 0;
		end
	3'b001: begin               // 0010 Pattern - in the jedec, this pattern takes 2 tCK, but the design changes DQS
				    //  in the positive edge of the clock only, so it takes 4 tCK  
		    forever begin
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				result = 1;//Success
			else
				result = 0;
		    end
		end
	3'b010: begin               // 1110 Pattern - in the jedec, this pattern takes 2 tCK, but the design changes DQS
				    //  in the positive edge of the clock only, so it takes 4 tCK
		    forever begin
			@(posedge dfi_phy_clk);
			if (DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				result = 1;//Success
			else
				result = 0;
		    end
		end
	3'b011: begin               // 000010 Pattern - in the jedec, this pattern takes 3 tCK, but the design changes DQS
				    //  in the positive edge of the clock only, so it takes 6 tCK
		    forever begin
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				result = 1;//Success
			else
				result = 0;
		    end
		end
	3'b100: begin               // 00001010 Pattern - in the jedec, this pattern takes 4 tCK, but the design changes DQS
				    //  in the positive edge of the clock only, so it takes 8 tCK
		    forever begin
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				result = 1;//Success
			else
				result = 0;
		    end
		end
	default: begin
		    //nothing
		 end
    endcase
endtask
task detect_postamble(input bit post_amble, output bit result); 
	case (post_amble)
	1'b0: begin               
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				result = 1;	//Success
			else
				result = 0;	//Error
		end
	1'b1: begin              
		    forever begin
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (DQS_AD_i) 
				//Continue
			else
				result = 0;
			@(posedge dfi_phy_clk);
			if (!DQS_AD_i) 
				result = 1;//Success
			else
				result = 0;
		    end
		end
	default: begin
		    //nothing
		 end
    endcase
endtask
