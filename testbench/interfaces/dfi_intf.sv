interface dfi_intf(input logic dfi_clk);

	parameter Physical_Rank_No = 1; 
	parameter device_width = 4;
	logic 				reset_n_i;
	logic 				en_i;
	logic 				phycrc_mode_i;
	logic [1:0]  			dfi_freq_ratio_i; 
	logic [13:0] 			dfi_address_p0;
	logic [13:0] 			dfi_address_p1;
	logic [13:0] 			dfi_address_p2;
	logic [13:0] 			dfi_address_p3;
	logic [Physical_Rank_No-1:0 ]	dfi_cs_p0;
	logic [Physical_Rank_No-1:0 ]	dfi_cs_p1;
	logic [Physical_Rank_No-1:0 ]	dfi_cs_p2;
	logic [Physical_Rank_No-1:0 ]	dfi_cs_p3;
	logic 				dfi_rddata_en_p0;
	logic 				dfi_rddata_en_p1;
	logic 				dfi_rddata_en_p2;
	logic 				dfi_rddata_en_p3;
	logic 				dfi_alert_n_a0;
	logic 				dfi_alert_n_a1;
	logic 				dfi_alert_n_a2;
	logic 				dfi_alert_n_a3;
	logic 				dfi_rddata_valid_w0;
	logic 				dfi_rddata_valid_w1;
	logic 				dfi_rddata_valid_w2;
	logic 				dfi_rddata_valid_w3;
	logic [2*device_width-1:0]	dfi_rddata_w0;
	logic [2*device_width-1:0]	dfi_rddata_w1;
	logic [2*device_width-1:0]	dfi_rddata_w2;
	logic [2*device_width-1:0]	dfi_rddata_w3;

        clocking cb_D @(posedge dfi_clk);
                //Drive on negedge -- Sample at #1step
                default input #1step output negedge; 
	        input dfi_alert_n_a0, dfi_alert_n_a1,dfi_alert_n_a2,dfi_alert_n_a3, dfi_rddata_valid_w0,dfi_rddata_valid_w1,dfi_rddata_valid_w2,dfi_rddata_valid_w3, dfi_rddata_w0,dfi_rddata_w1,dfi_rddata_w2,dfi_rddata_w3;
                output reset_n_i, en_i, phycrc_mode_i, dfi_freq_ratio_i, dfi_address_p0, dfi_address_p1,dfi_address_p2,dfi_address_p3, dfi_cs_p0,dfi_cs_p1,dfi_cs_p2,dfi_cs_p3, dfi_rddata_en_p0,dfi_rddata_en_p1,dfi_rddata_en_p2,dfi_rddata_en_p3;
        endclocking
endinterface 