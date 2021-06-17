
################################################################
# This is a generated script based on design: block_design
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
# source block_design_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# clock_generator_parametric, cmps2, cmps2_tester

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
set design_name block_design

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
cmps2\
cmps2_tester\
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
  set SCL [ create_bd_port -dir IO -type clk -freq_hz 400000 SCL ]
  set SDA [ create_bd_port -dir IO SDA ]
  set an [ create_bd_port -dir O -from 3 -to 0 an ]
  set btnL [ create_bd_port -dir I btnL ]
  set btnR [ create_bd_port -dir I btnR ]
  set clk [ create_bd_port -dir I -type clk -freq_hz 100000000 clk ]
  set debug [ create_bd_port -dir O -from 1 -to 0 debug ]
  set led [ create_bd_port -dir O -from 15 -to 0 led ]
  set rst [ create_bd_port -dir I -type rst rst ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $rst
  set seg [ create_bd_port -dir O -from 6 -to 0 seg ]
  set sw [ create_bd_port -dir I -from 15 -to 0 sw ]
  set tx [ create_bd_port -dir O tx ]

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
   CONFIG.OUTPUT_PERIOD {1260} \
 ] $clock_generator_para_0

  # Create instance: cmps2_0, and set properties
  set block_name cmps2
  set block_cell_name cmps2_0
  if { [catch {set cmps2_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $cmps2_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: cmps2_tester_0, and set properties
  set block_name cmps2_tester
  set block_cell_name cmps2_tester_0
  if { [catch {set cmps2_tester_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $cmps2_tester_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create port connections
  connect_bd_net -net Net [get_bd_ports SCL] [get_bd_pins cmps2_0/SCL]
  connect_bd_net -net Net1 [get_bd_ports SDA] [get_bd_pins cmps2_0/SDA]
  connect_bd_net -net btnL_1 [get_bd_ports btnL] [get_bd_pins cmps2_tester_0/btnL]
  connect_bd_net -net btnR_1 [get_bd_ports btnR] [get_bd_pins cmps2_tester_0/btnR]
  connect_bd_net -net clk_1 [get_bd_ports clk] [get_bd_pins clock_generator_para_0/clk_i] [get_bd_pins cmps2_0/clk] [get_bd_pins cmps2_tester_0/clk]
  connect_bd_net -net clock_generator_para_0_clk_o [get_bd_pins clock_generator_para_0/clk_o] [get_bd_pins cmps2_0/clkI2Cx2]
  connect_bd_net -net cmps2_0_valid [get_bd_pins cmps2_0/valid] [get_bd_pins cmps2_tester_0/valid]
  connect_bd_net -net cmps2_0_x_axis [get_bd_pins cmps2_0/x_axis] [get_bd_pins cmps2_tester_0/x_axis]
  connect_bd_net -net cmps2_0_x_offset [get_bd_pins cmps2_0/x_offset] [get_bd_pins cmps2_tester_0/x_offset]
  connect_bd_net -net cmps2_0_y_axis [get_bd_pins cmps2_0/y_axis] [get_bd_pins cmps2_tester_0/y_axis]
  connect_bd_net -net cmps2_0_y_offset [get_bd_pins cmps2_0/y_offset] [get_bd_pins cmps2_tester_0/y_offset]
  connect_bd_net -net cmps2_0_z_axis [get_bd_pins cmps2_0/z_axis] [get_bd_pins cmps2_tester_0/z_axis]
  connect_bd_net -net cmps2_0_z_offset [get_bd_pins cmps2_0/z_offset] [get_bd_pins cmps2_tester_0/z_offset]
  connect_bd_net -net cmps2_tester_0_an [get_bd_ports an] [get_bd_pins cmps2_tester_0/an]
  connect_bd_net -net cmps2_tester_0_calibrate [get_bd_pins cmps2_0/calibrate] [get_bd_pins cmps2_tester_0/calibrate]
  connect_bd_net -net cmps2_tester_0_debug [get_bd_ports debug] [get_bd_pins cmps2_tester_0/debug]
  connect_bd_net -net cmps2_tester_0_led [get_bd_ports led] [get_bd_pins cmps2_tester_0/led]
  connect_bd_net -net cmps2_tester_0_measure [get_bd_pins cmps2_0/measure] [get_bd_pins cmps2_tester_0/measure]
  connect_bd_net -net cmps2_tester_0_resolution [get_bd_pins cmps2_0/resolution] [get_bd_pins cmps2_tester_0/resolution]
  connect_bd_net -net cmps2_tester_0_seg [get_bd_ports seg] [get_bd_pins cmps2_tester_0/seg]
  connect_bd_net -net cmps2_tester_0_tx [get_bd_ports tx] [get_bd_pins cmps2_tester_0/tx]
  connect_bd_net -net rst_1 [get_bd_ports rst] [get_bd_pins clock_generator_para_0/rst] [get_bd_pins cmps2_0/rst] [get_bd_pins cmps2_tester_0/rst]
  connect_bd_net -net sw_1 [get_bd_ports sw] [get_bd_pins cmps2_tester_0/sw]
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


