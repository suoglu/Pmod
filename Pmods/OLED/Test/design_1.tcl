
################################################################
# This is a generated script based on design: design_1
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2020.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_1_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# clock_generator_parametric, oled, oled_decoder, oled_tester

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a35tcpg236-1
   set_property BOARD_PART digilentinc.com:basys3:part0:1.1 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name design_1

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:xlconstant:1.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
clock_generator_parametric\
oled\
oled_decoder\
oled_tester\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports

  # Create ports
  set JB [ create_bd_port -dir O -from 7 -to 0 JB ]
  set JC [ create_bd_port -dir O -from 7 -to 0 JC ]
  set btnD [ create_bd_port -dir I btnD ]
  set btnL [ create_bd_port -dir I btnL ]
  set btnR [ create_bd_port -dir I btnR ]
  set btnU [ create_bd_port -dir I btnU ]
  set clk [ create_bd_port -dir I -type clk -freq_hz 100000000 clk ]
  set rst [ create_bd_port -dir I -type rst rst ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rst
  set sw [ create_bd_port -dir I -from 15 -to 0 sw ]

  # Create instance: clock_generator_para_0, and set properties
  set block_name clock_generator_parametric
  set block_cell_name clock_generator_para_0
  if { [catch {set clock_generator_para_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $clock_generator_para_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.OUTPUT_PERIOD {200} \
 ] $clock_generator_para_0

  # Create instance: oled_0, and set properties
  set block_name oled
  set block_cell_name oled_0
  if { [catch {set oled_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $oled_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: oled_decoder_0, and set properties
  set block_name oled_decoder
  set block_cell_name oled_decoder_0
  if { [catch {set oled_decoder_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $oled_decoder_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: oled_tester_0, and set properties
  set block_name oled_tester
  set block_cell_name oled_tester_0
  if { [catch {set oled_tester_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $oled_tester_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create port connections
  connect_bd_net -net btnD_1 [get_bd_ports btnD] [get_bd_pins oled_tester_0/btnD]
  connect_bd_net -net btnL_1 [get_bd_ports btnL] [get_bd_pins oled_tester_0/btnL]
  connect_bd_net -net btnR_1 [get_bd_ports btnR] [get_bd_pins oled_tester_0/btnR]
  connect_bd_net -net btnU_1 [get_bd_ports btnU] [get_bd_pins oled_tester_0/btnU]
  connect_bd_net -net clk_1 [get_bd_ports clk] [get_bd_pins clock_generator_para_0/clk_i] [get_bd_pins oled_0/clk] [get_bd_pins oled_tester_0/clk]
  connect_bd_net -net clock_generator_para_0_clk_o [get_bd_pins clock_generator_para_0/clk_o] [get_bd_pins oled_0/ext_spi_clk]
  connect_bd_net -net oled_0_CS [get_bd_pins oled_0/CS] [get_bd_pins oled_tester_0/CS]
  connect_bd_net -net oled_0_DEBUG [get_bd_ports JC] [get_bd_pins oled_tester_0/JC]
  connect_bd_net -net oled_0_MOSI [get_bd_pins oled_0/MOSI] [get_bd_pins oled_tester_0/MOSI]
  connect_bd_net -net oled_0_SCK [get_bd_pins oled_0/SCK] [get_bd_pins oled_tester_0/SCK]
  connect_bd_net -net oled_0_character_code [get_bd_pins oled_0/character_code] [get_bd_pins oled_decoder_0/character_code]
  connect_bd_net -net oled_0_data_command_cntr [get_bd_pins oled_0/data_command_cntr] [get_bd_pins oled_tester_0/data_command_cntr]
  connect_bd_net -net oled_0_power_rst [get_bd_pins oled_0/power_rst] [get_bd_pins oled_tester_0/power_rst]
  connect_bd_net -net oled_0_vbat_c [get_bd_pins oled_0/vbat_c] [get_bd_pins oled_tester_0/vbat_c]
  connect_bd_net -net oled_0_vdd_c [get_bd_pins oled_0/vdd_c] [get_bd_pins oled_tester_0/vdd_c]
  connect_bd_net -net oled_decoder_0_decoded_bitmap [get_bd_pins oled_0/current_bitmap] [get_bd_pins oled_decoder_0/decoded_bitmap]
  connect_bd_net -net oled_tester_0_JB [get_bd_ports JB] [get_bd_pins oled_tester_0/JB]
  connect_bd_net -net oled_tester_0_contrast [get_bd_pins oled_0/contrast] [get_bd_pins oled_tester_0/contrast]
  connect_bd_net -net oled_tester_0_cursor_enable [get_bd_pins oled_0/cursor_enable] [get_bd_pins oled_tester_0/cursor_enable]
  connect_bd_net -net oled_tester_0_cursor_flash [get_bd_pins oled_0/cursor_flash] [get_bd_pins oled_tester_0/cursor_flash]
  connect_bd_net -net oled_tester_0_cursor_pos [get_bd_pins oled_0/cursor_pos] [get_bd_pins oled_tester_0/cursor_pos]
  connect_bd_net -net oled_tester_0_display_data [get_bd_pins oled_0/display_data] [get_bd_pins oled_tester_0/display_data]
  connect_bd_net -net oled_tester_0_display_off [get_bd_pins oled_0/display_off] [get_bd_pins oled_tester_0/display_off]
  connect_bd_net -net oled_tester_0_display_reset [get_bd_pins oled_0/display_reset] [get_bd_pins oled_tester_0/display_reset]
  connect_bd_net -net oled_tester_0_line_count [get_bd_pins oled_0/line_count] [get_bd_pins oled_tester_0/line_count]
  connect_bd_net -net oled_tester_0_power_on [get_bd_pins oled_0/power_on] [get_bd_pins oled_tester_0/power_on]
  connect_bd_net -net oled_tester_0_update [get_bd_pins oled_0/update] [get_bd_pins oled_tester_0/update]
  connect_bd_net -net rst_1 [get_bd_ports rst] [get_bd_pins clock_generator_para_0/rst] [get_bd_pins oled_0/rst] [get_bd_pins oled_tester_0/rst]
  connect_bd_net -net sw_1 [get_bd_ports sw] [get_bd_pins oled_tester_0/sw]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins clock_generator_para_0/en] [get_bd_pins xlconstant_0/dout]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


