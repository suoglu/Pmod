# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {Main}]
  set_property tooltip {Main} ${Page_0}
  #Adding Group
  set Information [ipgui::add_group $IPINST -name "Information" -parent ${Page_0}]
  ipgui::add_static_text $IPINST -name "Basic Info" -parent ${Information} -text {Digital to Analog Converter, Pmod DA2 (DAC121S101-Q1)}

  #Adding Group
  set Configurations [ipgui::add_group $IPINST -name "Configurations" -parent ${Page_0}]
  set_property tooltip {Hardware Configurations} ${Configurations}
  ipgui::add_param $IPINST -name "DUAL_MODE" -parent ${Configurations}
  set FAST_REFRESH [ipgui::add_param $IPINST -name "FAST_REFRESH" -parent ${Configurations}]
  set_property tooltip {This will disable configurable fast refresh} ${FAST_REFRESH}

  #Adding Group
  set Usage [ipgui::add_group $IPINST -name "Usage" -parent ${Page_0}]
  set_property tooltip {Basic Usage Info} ${Usage}
  ipgui::add_static_text $IPINST -name "Basic Usage" -parent ${Usage} -text {Writing to channel registers or power mode section 
of the configuration register updates the registers 
in the IP
When not in buffering mode, DAC output is updated
automatically. In buffering mode, refresh bit of the
configuration register must be set.}
  ipgui::add_static_text $IPINST -name "Basic Usage II" -parent ${Usage} -text {In fast refresh mode, when refresh bit set, other
bits of the write channel ignored; hence configurations
are kept without a need for knowing their values. When
hardwired fast refresh enabled; IP is always in fast
refresh mode.
}


  #Adding Page
  set Register_Map [ipgui::add_page $IPINST -name "Register Map"]
  set OFFSET_CH0 [ipgui::add_param $IPINST -name "OFFSET_CH0" -parent ${Register_Map}]
  set_property tooltip {ADC Channel 0/A} ${OFFSET_CH0}
  set OFFSET_CH1 [ipgui::add_param $IPINST -name "OFFSET_CH1" -parent ${Register_Map}]
  set_property tooltip {ADC Channel 1/B} ${OFFSET_CH1}
  set OFFSET_STATUS [ipgui::add_param $IPINST -name "OFFSET_STATUS" -parent ${Register_Map}]
  set_property tooltip {Status Register} ${OFFSET_STATUS}
  ipgui::add_static_text $IPINST -name "Status Reg Contents" -parent ${Register_Map} -text {status[3] : Hardwired Fast Refresh Mode
status[2] : Dual Channel Device
status[1] : Data on the IP and the ADC is not same, needs refresh
status[0] : Busy, Ongoing transfer}
  set OFFSET_CONFIG [ipgui::add_param $IPINST -name "OFFSET_CONFIG" -parent ${Register_Map}]
  set_property tooltip {Configuration Register} ${OFFSET_CONFIG}
  ipgui::add_static_text $IPINST -name "Configuration reg contents" -parent ${Register_Map} -text {config[6]   : Soft Fast Refresh Mode
config[5:4]: Power Down Mode Channel 1/B
config[3:2]: Power Down Mode Channel 0/A
config[1]   : Refresh
config[0]   : Buffering Mode  }

  #Adding Page
  set Power_Down_Modes [ipgui::add_page $IPINST -name "Power Down Modes"]
  set_property tooltip {List of Power Down Modes} ${Power_Down_Modes}
  ipgui::add_static_text $IPINST -name "PD Modes" -parent ${Power_Down_Modes} -text {2b00 : Normal Operation
2b01 : 1kΩ to GND
2b10 : 100kΩ to GND
2b11 : High Impedance}


}

proc update_PARAM_VALUE.DUAL_MODE { PARAM_VALUE.DUAL_MODE } {
	# Procedure called to update DUAL_MODE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DUAL_MODE { PARAM_VALUE.DUAL_MODE } {
	# Procedure called to validate DUAL_MODE
	return true
}

proc update_PARAM_VALUE.FAST_REFRESH { PARAM_VALUE.FAST_REFRESH } {
	# Procedure called to update FAST_REFRESH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FAST_REFRESH { PARAM_VALUE.FAST_REFRESH } {
	# Procedure called to validate FAST_REFRESH
	return true
}

proc update_PARAM_VALUE.OFFSET_CH0 { PARAM_VALUE.OFFSET_CH0 } {
	# Procedure called to update OFFSET_CH0 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OFFSET_CH0 { PARAM_VALUE.OFFSET_CH0 } {
	# Procedure called to validate OFFSET_CH0
	return true
}

proc update_PARAM_VALUE.OFFSET_CH1 { PARAM_VALUE.OFFSET_CH1 } {
	# Procedure called to update OFFSET_CH1 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OFFSET_CH1 { PARAM_VALUE.OFFSET_CH1 } {
	# Procedure called to validate OFFSET_CH1
	return true
}

proc update_PARAM_VALUE.OFFSET_CONFIG { PARAM_VALUE.OFFSET_CONFIG } {
	# Procedure called to update OFFSET_CONFIG when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OFFSET_CONFIG { PARAM_VALUE.OFFSET_CONFIG } {
	# Procedure called to validate OFFSET_CONFIG
	return true
}

proc update_PARAM_VALUE.OFFSET_STATUS { PARAM_VALUE.OFFSET_STATUS } {
	# Procedure called to update OFFSET_STATUS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OFFSET_STATUS { PARAM_VALUE.OFFSET_STATUS } {
	# Procedure called to validate OFFSET_STATUS
	return true
}

proc update_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_BASEADDR { PARAM_VALUE.C_S_AXI_BASEADDR } {
	# Procedure called to update C_S_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_BASEADDR { PARAM_VALUE.C_S_AXI_BASEADDR } {
	# Procedure called to validate C_S_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_HIGHADDR { PARAM_VALUE.C_S_AXI_HIGHADDR } {
	# Procedure called to update C_S_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_HIGHADDR { PARAM_VALUE.C_S_AXI_HIGHADDR } {
	# Procedure called to validate C_S_AXI_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.DUAL_MODE { MODELPARAM_VALUE.DUAL_MODE PARAM_VALUE.DUAL_MODE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DUAL_MODE}] ${MODELPARAM_VALUE.DUAL_MODE}
}

proc update_MODELPARAM_VALUE.FAST_REFRESH { MODELPARAM_VALUE.FAST_REFRESH PARAM_VALUE.FAST_REFRESH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FAST_REFRESH}] ${MODELPARAM_VALUE.FAST_REFRESH}
}

proc update_MODELPARAM_VALUE.OFFSET_CH0 { MODELPARAM_VALUE.OFFSET_CH0 PARAM_VALUE.OFFSET_CH0 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OFFSET_CH0}] ${MODELPARAM_VALUE.OFFSET_CH0}
}

proc update_MODELPARAM_VALUE.OFFSET_CH1 { MODELPARAM_VALUE.OFFSET_CH1 PARAM_VALUE.OFFSET_CH1 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OFFSET_CH1}] ${MODELPARAM_VALUE.OFFSET_CH1}
}

proc update_MODELPARAM_VALUE.OFFSET_STATUS { MODELPARAM_VALUE.OFFSET_STATUS PARAM_VALUE.OFFSET_STATUS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OFFSET_STATUS}] ${MODELPARAM_VALUE.OFFSET_STATUS}
}

proc update_MODELPARAM_VALUE.OFFSET_CONFIG { MODELPARAM_VALUE.OFFSET_CONFIG PARAM_VALUE.OFFSET_CONFIG } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OFFSET_CONFIG}] ${MODELPARAM_VALUE.OFFSET_CONFIG}
}

