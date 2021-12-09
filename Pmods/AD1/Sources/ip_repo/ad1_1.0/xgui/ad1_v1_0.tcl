# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {Main}]
  set_property tooltip {Main} ${Page_0}
  #Adding Group
  set Introduction [ipgui::add_group $IPINST -name "Introduction" -parent ${Page_0} -display_name {Information}]
  set_property tooltip {Information} ${Introduction}
  ipgui::add_static_text $IPINST -name "Basic Information" -parent ${Introduction} -text {AXI4-Lite interface for Pmod AD1, dual channel 12 bit ADC AD7476A}

  #Adding Group
  set Configurations [ipgui::add_group $IPINST -name "Configurations" -parent ${Page_0}]
  set_property tooltip {Configurations} ${Configurations}
  set DUAL_MODE [ipgui::add_param $IPINST -name "DUAL_MODE" -parent ${Configurations}]
  set_property tooltip {Enable interface for both AD7476As of AD1} ${DUAL_MODE}

  #Adding Group
  set Usage [ipgui::add_group $IPINST -name "Usage" -parent ${Page_0}]
  set_property tooltip {Usage} ${Usage}
  ipgui::add_static_text $IPINST -name "Usage Information" -parent ${Usage} -text {Writing to data registers starts a new measurement.
In blocking read mode, reading from data registers also starts a new measurement.
If update both is set, both channels are updated in any new measurement,}


  #Adding Page
  set Register_Map [ipgui::add_page $IPINST -name "Register Map"]
  set_property tooltip {Register Offsets} ${Register_Map}
  ipgui::add_param $IPINST -name "OFFSET_CH0" -parent ${Register_Map}
  ipgui::add_param $IPINST -name "OFFSET_CH1" -parent ${Register_Map}
  ipgui::add_param $IPINST -name "OFFSET_STATUS" -parent ${Register_Map}
  ipgui::add_static_text $IPINST -name "Bit map: Status" -parent ${Register_Map} -text {status[1]: Dual Mode
status[0]: Busy / On going measurement}
  ipgui::add_param $IPINST -name "OFFSET_CONFIG" -parent ${Register_Map}
  ipgui::add_static_text $IPINST -name "Bit map: Config" -parent ${Register_Map} -text {config[1]: Update Both
~Initiating a measurement in any channels will update both data registers.
config[0]: Blocking Read
~Reading from a data register initiates a new measurement.
~Reading completed after measurement is done and register value is updated.
}


}

proc update_PARAM_VALUE.DUAL_MODE { PARAM_VALUE.DUAL_MODE } {
	# Procedure called to update DUAL_MODE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DUAL_MODE { PARAM_VALUE.DUAL_MODE } {
	# Procedure called to validate DUAL_MODE
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

