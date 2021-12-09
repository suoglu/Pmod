# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_S_AXI_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DUAL_MODE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "OFFSET_CH0" -parent ${Page_0}
  ipgui::add_param $IPINST -name "OFFSET_CH1" -parent ${Page_0}
  ipgui::add_param $IPINST -name "OFFSET_CONFIG" -parent ${Page_0}
  ipgui::add_param $IPINST -name "OFFSET_STATUS" -parent ${Page_0}


}

proc update_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_DATA_WIDTH
	return true
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

proc update_MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH}
}

