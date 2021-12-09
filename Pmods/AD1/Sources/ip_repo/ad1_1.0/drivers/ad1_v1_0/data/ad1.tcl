

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "ad1" "NUM_INSTANCES" "DEVICE_ID"  "C_S_AXI_BASEADDR" "C_S_AXI_HIGHADDR" "DUAL_MODE" "OFFSET_CH0" "OFFSET_CH1" "OFFSET_STATUS" "OFFSET_CONFIG"
}
