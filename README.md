# DDR5 PHY Verification
This repo includes the uvm testbench for DDR5 PHY as part of Graduation project titled "Verification of the Digital Data-Path of DDR5 PHY" in Nanotechnology & Nano-Electronics Engineering program - Zewail City (2021 - 2022) 
***************************************************************************
Files Organization:
- docs: Verification plan, Waveforms
- rtl: The rtl is not included in this project as it is not part of this work
- scripts: Shell script for test run automation
- testbench: UVM tb environment (comps, sequences, tests, interfaces, transactions)
******************************************************************************
Brief Description: <br/>
A physical layer facilitates the communication between the memory controller and the DRAM. In order to perform this functionality, it should satisfy both communication protocols between the memory controller and PHY and between PHY and DRAM which are DDR PHY Interface (DFI 5.1) standard and JEDEC JESD209-5A standard respectively. Therefore, both standards are considered the golden references from which the PHY features and virtual environment will be constructed. Furthermore, the
project utilizes simulation-based verification using UVM and SystemVerilog. Hence, the testbench development will rely on the IEEE standards of UVM
and SystemVerilog too.
********************************************************************************
Team:
[Abdullah Allam](https://www.linkedin.com/in/abdullah-shaaban-154581167/),
[Shehab Naga](https://www.linkedin.com/in/shehabbahaaengineer/),
[Mohamed Abdelall](https://www.linkedin.com/in/mohamedabdelall/),
[John Saber](https://www.linkedin.com/in/john-wafeek-2824a9168/),
[Tarek Abou-Elkheir](https://www.linkedin.com/in/tarek-abdelnasser-b0aa27173/)
