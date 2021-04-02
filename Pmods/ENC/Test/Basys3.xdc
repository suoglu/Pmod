# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]
	set_property IOSTANDARD LVCMOS33 [get_ports clk]

#7 segment display seg[6:0] = gfedcba
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]	
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]	
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]	
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]	
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]	
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]	
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

set_property PACKAGE_PIN U2 [get_ports {an[0]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN U4 [get_ports {an[1]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN V4 [get_ports {an[2]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN W4 [get_ports {an[3]}]
	set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]


#Buttons
set_property PACKAGE_PIN U18 [get_ports rst]
	set_property IOSTANDARD LVCMOS33 [get_ports rst]

##Pmod Header JB
##Sch name = JB1
set_property PACKAGE_PIN A14 [get_ports {A_o}]
	set_property IOSTANDARD LVCMOS33 [get_ports {A_o}]
#Sch name = JB2
set_property PACKAGE_PIN A16 [get_ports {B_o}]
	set_property IOSTANDARD LVCMOS33 [get_ports {B_o}]
#Sch name = JB3
set_property PACKAGE_PIN B15 [get_ports {dir0}]
	set_property IOSTANDARD LVCMOS33 [get_ports {dir0}]
#Sch name = JB4
set_property PACKAGE_PIN B16 [get_ports {dir1}]
	set_property IOSTANDARD LVCMOS33 [get_ports {dir1}]
# ##Sch name = JB7
# set_property PACKAGE_PIN A15 [get_ports {encClk}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {encClk}]
##Sch name = JB8
#set_property PACKAGE_PIN A17 [get_ports {JB[5]}]
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[5]}]
##Sch name = JB9
#set_property PACKAGE_PIN C15 [get_ports {JB[6]}]
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[6]}]
##Sch name = JB10
#set_property PACKAGE_PIN C16 [get_ports {JB[7]}]
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[7]}]

#Pmod Header JC
#Sch name = JC1
set_property PACKAGE_PIN K17 [get_ports {A}]
	set_property IOSTANDARD LVCMOS33 [get_ports {A}]
#Sch name = JC2
set_property PACKAGE_PIN M18 [get_ports {B}]
	set_property IOSTANDARD LVCMOS33 [get_ports {B}]
# #Sch name = JC7
# set_property PACKAGE_PIN L17 [get_ports {dir0}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {dir0}]
# #Sch name = JC8
# set_property PACKAGE_PIN M19 [get_ports {dir1}]
# 	set_property IOSTANDARD LVCMOS33 [get_ports {dir1}]
	
	
## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

