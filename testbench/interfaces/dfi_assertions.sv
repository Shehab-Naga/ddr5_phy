module dfi_jedec_asserts
	#(
	parameter Physical_Rank_No = 1, 
	parameter device_width = 4,
        /**************************Timing Parameters*******************************/
        parameter trddata_en 	= 2,     // specify the needed delay as "number of cycles"
        parameter tphy_rdlat 	= 2,
        parameter tcmd_lat      = 0,
        parameter tctrl_delay 	= 1)
(
// DFI_Interface signals 
input   logic reset_n_i,
input   logic en_i,
input 	logic dfi_clk,
input	logic phycrc_mode_i,
input	logic [1:0] dfi_freq_ratio_i, 
input   logic [13:0] dfi_address_p0, dfi_address_p1,dfi_address_p2,dfi_address_p3,
input   logic [Physical_Rank_No-1:0]dfi_cs_p0,dfi_cs_p1,dfi_cs_p2,dfi_cs_p3,
input   logic dfi_rddata_en_p0,dfi_rddata_en_p1,dfi_rddata_en_p2,dfi_rddata_en_p3,
input	logic dfi_alert_n_a0, dfi_alert_n_a1,dfi_alert_n_a2,dfi_alert_n_a3,
input   logic dfi_rddata_valid_w0,dfi_rddata_valid_w1,dfi_rddata_valid_w2,dfi_rddata_valid_w3,
input   logic [2*device_width-1:0]dfi_rddata_w0,dfi_rddata_w1,dfi_rddata_w2,dfi_rddata_w3,

// JEDEC Interface signals
input   logic CS_DA_o,
input   logic [13:0]CA_DA_o
);


//Continue
/**************************************************************************/

//==========================================================================//
//                           Property definitions                           //
//==========================================================================//

/*****************************DFI_DR_1 & DFI_DR_2*******************************************/
// command is driven for at least 1 DFI PHY clock cycle after the CS is active.
// tcmd_lat specifies the number of DFI clocks after the dfi_cs signal is asserted until the associated CA signals are driven.
property dfi_address_valid(dfi_cs_px, dfi_address_px);
  @(posedge dfi_clk)
    ~dfi_cs_px |-> (##tcmd_lat ~$isunknown(dfi_address_px) [*2]);
endproperty: dfi_address_valid

/*****************************DFI_DR_6*******************************************/
// From plan: Check the correct behaviour of CS_n on the DRAM interface (follows the behaviour of dfi_cs meaning 0=>1=>0)
// Elaboration: when dfi_cs toggles (1=>0=>1), CS_n should follow the exact same behaviour after translation delay of tctrl_delay
property  CS_n_to_dfi_cs_translation(dfi_cs_px, CS_DA_o);
  @(posedge dfi_clk)
    (dfi_cs_px ##1 ~dfi_cs_px ##1 dfi_cs_px) |-> (##tctrl_delay (CS_DA_o ##1 ~CS_DA_o ##1 CS_DA_o));
endproperty: CS_n_to_dfi_cs_translation

/*****************************DFI_DR_7*******************************************/
// From plan: Check the correct behaviour of reset_n on the DRAM interface (follows the behaviour of dfi_reset_n meaning 0=>1=>0)
// Elaboration: when dfi_reset_n toggles, reset_n should follow the exact same behaviour after translation delay of tctrl_delay
/*property  ;
  @(posedge dfi_clk)
    (dfi_reset_n ##1 ~dfi_reset_n ##1 dfi_reset_n) |-> (##[tctrl_delay] (reset_n ##1 ~reset_n ##1 reset_n));
endproperty: 
ERR_: assert property();*/   // NOT IMPLEMENTED BY THE DESIGN YET


/*****************************DFI_DR_11*******************************************/
// Translation delay between DFI and JEDEC
property dfi_address_CA_delay(dfi_cs_px, dfi_address_px,CA_DA_o);
  int temp;
  @(posedge dfi_clk)
	( ~dfi_cs_px && ~$isunknown(dfi_address_px) , temp=dfi_address_px) |-> (##[0:tctrl_delay] (temp==CA_DA_o));	
endproperty: dfi_address_CA_delay
/*property dfi_address_CA_delay ;
  @(posedge dfi_clk)                    //---------THIS IS A WRONG IMPLEMENTATION OF THE ASSERTION-------------//
	(~$isunknown(dfi_address_p0) or ~$isunknown(dfi_address_p1) or ~$isunknown(dfi_address_p2) or ~$isunknown(dfi_address_p3)) |-> ##[0:tctrl_delay] ~$isunknown(CA_DA_o);	
endproperty: dfi_address_CA_delay*/

/*****************************DFI_DR_13*******************************************/
//From Plan: check that valid data is being transferred when the dfi_rddata_valid signal is asserted
property dfi_rddata_signal_valid(dfi_rddata_valid_wx, dfi_rddata_wx);
  @(posedge dfi_clk)
    dfi_rddata_valid_w0 |-> ~$isunknown(dfi_rddata_wx);
endproperty: dfi_rddata_signal_valid

/*****************************DFI_DR_13 & DFI_DR_16*******************************************/
property dfi_rddata_en_signal_asserted(dfi_address_px, dfi_cs_px, dfi_rddata_en_px);
  @(posedge dfi_clk)
  ((dfi_address_px[4:0] == 5'b11101) && ~(dfi_cs_px)) |-> (##trddata_en dfi_rddata_en_px);
endproperty: dfi_rddata_en_signal_asserted

/*****************************DFI_DR_13 & DFI_DR_16*******************************************/
// From Plan: number of dfi_rddata_en assertion clocks = number of dfi_rddata_valid assertion clocks
property dfi_rddata_valid_match_dfi_rddata_en(dfi_rddata_en_px, dfi_rddata_valid_wx);
  @(posedge dfi_clk)
  ($rose(dfi_rddata_en_px) |-> ##tphy_rdlat $rose(dfi_rddata_valid_wx)) and ($fell(dfi_rddata_en_px) |-> ##tphy_rdlat $fell(dfi_rddata_valid_wx));  
endproperty: dfi_rddata_valid_match_dfi_rddata_en 



//==========================================================================//
//                               Assertions                                 //
//==========================================================================//

dfi_address_p0_VALID:           assert property(dfi_address_valid(dfi_cs_p0, dfi_address_p0))
                                else $error("ERROR");
COV_dfi_address_p0_VALID:       cover property(dfi_address_valid(dfi_cs_p0, dfi_address_p0));

CS_n_to_dfi_cs_Translation_p0:  assert property(CS_n_to_dfi_cs_translation(dfi_cs_p0, CS_DA_o))
                                else $error("ERROR");
COV_CS_n_to_dfi_cs_Translation_p0:cover property(CS_n_to_dfi_cs_translation(dfi_cs_p0, CS_DA_o)); 

dfi_address_to_CA_delay_p0:     assert property(dfi_address_CA_delay(dfi_cs_p0, dfi_address_p0, CA_DA_o))
                                else $error("ERROR");
COV_dfi_address_to_CA_delay_p0: cover property(dfi_address_CA_delay(dfi_cs_p0, dfi_address_p0, CA_DA_o));

dfi_rddata_signal_valid_p0:     assert property(dfi_rddata_signal_valid(dfi_rddata_valid_w0, dfi_rddata_w0))
                                else $error("ERROR");

dfi_rddata_en_signal_asserted_p0:assert property(dfi_rddata_en_signal_asserted(dfi_address_p0, dfi_cs_p0, dfi_rddata_en_p0))
                                else $error("ERROR");

dfi_rddata_valid_match_dfi_rddata_en_p0:assert property(dfi_rddata_valid_match_dfi_rddata_en(dfi_rddata_en_p0, dfi_rddata_valid_w0))
                                else $error("DFI_DR_13 & DFI_DR_16 Failure -- dfi_rddata_valid does not match dfi_rddata_en in length after tphy_rdlat");

`ifdef ratio_one_to_two
        dfi_address_p1_VALID:           assert property(dfi_address_valid(dfi_cs_p1, dfi_address_p1))
                                        else $error("ERROR");
        COV_dfi_address_p1_VALID:       cover property(dfi_address_valid(dfi_cs_p1, dfi_address_p1));

        CS_n_to_dfi_cs_Translation_p1:  assert property(CS_n_to_dfi_cs_translation(dfi_cs_p1, CS_DA_o)) // This should be activated only when freq ratio is 1:2 or 1:4
                                        else $error("ERROR");
        COV_CS_n_to_dfi_cs_Translation_p1:cover property(CS_n_to_dfi_cs_translation(dfi_cs_p1, CS_DA_o)); // This should be activated only when freq ratio is 1:2 or 1:4
        
        dfi_address_to_CA_delay_p1:     assert property(dfi_address_CA_delay(dfi_cs_p1, dfi_address_p1, CA_DA_o))
                                        else $error("ERROR");
        COV_dfi_address_to_CA_delay_p1: cover property(dfi_address_CA_delay(dfi_cs_p1, dfi_address_p1, CA_DA_o));
        
        dfi_rddata_signal_valid_p1:     assert property(dfi_rddata_signal_valid(dfi_rddata_valid_w1, dfi_rddata_w1))
                                        else $error("ERROR");

        dfi_rddata_en_signal_asserted_p1:assert property(dfi_rddata_en_signal_asserted(dfi_address_p1, dfi_cs_p1, dfi_rddata_en_p1))
                                        else $error("ERROR");

        dfi_rddata_valid_match_dfi_rddata_en_p1:assert property(dfi_rddata_valid_match_dfi_rddata_en(dfi_rddata_en_p1, dfi_rddata_valid_w1))
                                        else $error("ERROR");$error("DFI_DR_13 & DFI_DR_16 Failure -- dfi_rddata_valid does not match dfi_rddata_en in length after tphy_rdlat");
`endif 

`ifdef ratio_one_to_four
        dfi_address_p1_VALID_p1:        assert property(dfi_address_valid(dfi_cs_p1, dfi_address_p1))
                                        else $error("ERROR");
        COV_dfi_address_p1_VALID_p1:    cover property(dfi_address_valid(dfi_cs_p1, dfi_address_p1));

        dfi_address_p2_VALID_p2:        assert property(dfi_address_valid(dfi_cs_p2, dfi_address_p2))
                                        else $error("ERROR");
        COV_dfi_address_p2_VALID_p2:    cover property(dfi_address_valid(dfi_cs_p2, dfi_address_p2));

        dfi_address_p3_VALID_p3:        assert property(dfi_address_valid(dfi_cs_p3, dfi_address_p3))
                                        else $error("ERROR");
        COV_dfi_address_p3_VALID_p3:    cover property(dfi_address_valid(dfi_cs_p3, dfi_address_p3));

        CS_n_to_dfi_cs_Translation_p1:  assert property(CS_n_to_dfi_cs_translation(dfi_cs_p1, CS_DA_o)) // This should be activated only when freq ratio is 1:2 or 1:4
                                        else $error("ERROR");
        COV_CS_n_to_dfi_cs_Translation_p1:cover property(CS_n_to_dfi_cs_translation(dfi_cs_p1, CS_DA_o)); // This should be activated only when freq ratio is 1:2 or 1:4

        CS_n_to_dfi_cs_Translation_p2:  assert property(CS_n_to_dfi_cs_translation(dfi_cs_p2, CS_DA_o)) // This should be activated only when freq ratio is 1:4
                                        else $error("ERROR");
        COV_CS_n_to_dfi_cs_Translation_p2:cover property(CS_n_to_dfi_cs_translation(dfi_cs_p2, CS_DA_o)); // This should be activated only when freq ratio is 1:4

        CS_n_to_dfi_cs_Translation_p3:  assert property(CS_n_to_dfi_cs_translation(dfi_cs_p3, CS_DA_o)) // This should be activated only when freq ratio is 1:4
                                        else $error("ERROR");
        COV_CS_n_to_dfi_cs_Translation_p3:cover property(CS_n_to_dfi_cs_translation(dfi_cs_p3, CS_DA_o)); // This should be activated only when freq ratio is 1:4

        dfi_address_to_CA_delay_p1:     assert property(dfi_address_CA_delay(dfi_cs_p1, dfi_address_p1, CA_DA_o))
                                        else $error("ERROR");
        COV_dfi_address_to_CA_delay_p1: cover property(dfi_address_CA_delay(dfi_cs_p1, dfi_address_p1, CA_DA_o));

        dfi_address_to_CA_delay_p2:     assert property(dfi_address_CA_delay(dfi_cs_p2, dfi_address_p2, CA_DA_o))
                                        else $error("ERROR");
        COV_dfi_address_to_CA_delay_p2: cover property(dfi_address_CA_delay(dfi_cs_p2, dfi_address_p2, CA_DA_o));

        dfi_address_to_CA_delay_p3:     assert property(dfi_address_CA_delay(dfi_cs_p3, dfi_address_p3, CA_DA_o))
                                        else $error("ERROR");
        COV_dfi_address_to_CA_delay_p3: cover property(dfi_address_CA_delay(dfi_cs_p3, dfi_address_p3, CA_DA_o));
        
        dfi_rddata_signal_valid_p1:     assert property(dfi_rddata_signal_valid(dfi_rddata_valid_w1, dfi_rddata_w1))
                                        else $error("ERROR");

        dfi_rddata_signal_valid_p2:     assert property(dfi_rddata_signal_valid(dfi_rddata_valid_w2, dfi_rddata_w2))
                                        else $error("ERROR");
        
        dfi_rddata_signal_valid_p3:     assert property(dfi_rddata_signal_valid(dfi_rddata_valid_w3, dfi_rddata_w3))
                                        else $error("ERROR");
        
        dfi_rddata_en_signal_asserted_p1:assert property(dfi_rddata_en_signal_asserted(dfi_address_p1, dfi_cs_p1, dfi_rddata_en_p1))
                                        else $error("ERROR");

        dfi_rddata_en_signal_asserted_p2:assert property(dfi_rddata_en_signal_asserted(dfi_address_p2, dfi_cs_p2, dfi_rddata_en_p2))
                                        else $error("ERROR");

        dfi_rddata_en_signal_asserted_p3:assert property(dfi_rddata_en_signal_asserted(dfi_address_p3, dfi_cs_p3, dfi_rddata_en_p3))
                                        else $error("ERROR");

        dfi_rddata_valid_signal_dfi_rddata_en_p1:assert property(dfi_rddata_valid_match_dfi_rddata_en(dfi_rddata_en_p1, dfi_rddata_valid_w1))
                                        else $error("ERROR");$error("DFI_DR_13 & DFI_DR_16 Failure -- dfi_rddata_valid does not match dfi_rddata_en in length after tphy_rdlat");

        dfi_rddata_valid_signal_dfi_rddata_en_p2:assert property(dfi_rddata_valid_match_dfi_rddata_en(dfi_rddata_en_p2, dfi_rddata_valid_w2))
                                        else $error("ERROR");$error("DFI_DR_13 & DFI_DR_16 Failure -- dfi_rddata_valid does not match dfi_rddata_en in length after tphy_rdlat");

        dfi_rddata_valid_signal_dfi_rddata_en_p3:assert property(dfi_rddata_valid_match_dfi_rddata_en(dfi_rddata_en_p3, dfi_rddata_valid_w3))
                                        else $error("ERROR");$error("DFI_DR_13 & DFI_DR_16 Failure -- dfi_rddata_valid does not match dfi_rddata_en in length after tphy_rdlat");
`endif 


/*****************************DFI_DR_13  & DFI_DR_16*******************************************   
property dfi_rddata_valid_signal_asserted ;
  @(posedge dfi_clk)
  dfi_rddata_en_p0 |-> ##[0:tphy_rdlat] dfi_rddata_valid_w0;
  dfi_rddata_en_p1 |-> ##[0:tphy_rdlat] dfi_rddata_valid_w1;
  dfi_rddata_en_p2 |-> ##[0:tphy_rdlat] dfi_rddata_valid_w2;
  dfi_rddata_en_p3 |-> ##[0:tphy_rdlat] dfi_rddata_valid_w3;

endproperty: dfi_rddata_valid_signal_asserted

ERR_dfi_rddata_valid_signal_not_asserted: assert property(dfi_rddata_valid_signal_asserted);  // CONSIDER REMOVING: THIS IS DISABLED CUZ THE ONE ABOVE IT DOES THE SAME JOB
*/


	
endmodule
