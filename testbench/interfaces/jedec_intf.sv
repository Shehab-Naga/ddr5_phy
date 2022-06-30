interface jedec_intf(input logic dfi_phy_clk);
   
        parameter device_width = 4;
                
        logic [13:0] CA_DA_o;
        logic CS_DA_o;
        logic CA_VALID_DA_o;
        logic DQS_AD_i; 
        logic [2*device_width-1:0] DQ_AD_i;

        clocking cb_J @(posedge dfi_phy_clk);
                //Drive on negedge -- Sample at #1step
        	default input #1step output negedge; 		
                input CA_DA_o, CS_DA_o, CA_VALID_DA_o;
                output DQS_AD_i, DQ_AD_i;
	endclocking
endinterface 
