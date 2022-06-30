

//##############################################################################################################
/*****************************DFI_DR_1 & DFI_DR_2*******************************************/
//----------------------------------------------ONE TO ONE----------------------------------------------
// From plan:   command is driven for at least 1 DFI PHY clock cycle after the CS is active.
//              tcmd_lat specifies the number of DFI clocks after the dfi_cs signal is asserted until the associated CA signals are driven.
property dfi_address_valid(dfi_cs_px, dfi_address_px);
  @(posedge dfi_clk_i) disable iff (!reset_n_i)
    ~dfi_cs_px |-> (##tcmd_lat ~$isunknown(dfi_address_px) [*1:2]);
endproperty: dfi_address_valid


//----------------------------------------------ONE TO TWO----------------------------------------------
//The same property will work according to FIGURE 28. in DFI: second WR command is initiated in phase1
/*****************************END OF PROPERTY**************************************************/



/*****************************DFI_DR_6*******************************************/
//----------------------------------------------ONE TO ONE----------------------------------------------
// From plan:   Check the correct behaviour of CS_n on the DRAM interface (follows the behaviour of dfi_cs meaning 0=>1=>0)
// Elaboration: when dfi_cs toggles (1=>0=>1), CS_n should follow the exact same behaviour after translation delay of tctrl_delay
property  CS_n_to_dfi_cs_translation(dfi_cs_px, CS_DA_o);
  bit CS_tmp;
  @(posedge dfi_phy_clk_i) disable iff (!reset_n_i)
    ($changed(dfi_cs_px),CS_tmp=dfi_cs_px) |-> ##tctrl_delay CS_DA_o==CS_tmp;
endproperty: CS_n_to_dfi_cs_translation

//----------------------------------------------ONE TO TWO----------------------------------------------
property  CS_n_to_dfi_cs_translation(dfi_cs_px, CS_DA_o, x);
  bit CS_tmp;
  @(posedge dfi_phy_clk_i) disable iff (!reset_n_i)
    ($changed(dfi_cs_px),CS_tmp=dfi_cs_px) |-> ##(tctrl_delay+x) CS_DA_o==CS_tmp; //where x is the phase number
endproperty: CS_n_to_dfi_cs_translation
/*****************************END OF PROPERTY**************************************************/
