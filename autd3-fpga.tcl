set project_directory   [file dirname [info script]]
set project_name        "autd3-fpga"

cd $project_directory
create_project -force $project_name $project_directory

set_property PART xc7a200tfbg676-2 [current_project]

set_property "default_lib"        "xil_defaultlib" [current_project]
set_property "simulator_language" "Verilog"          [current_project]
set_property "target_language"    "Verilog"           [current_project]


if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
}

if {[string equal [get_filesets -quiet constrs_1] ""]} {
    create_fileset -constrset constrs_1
}

if {[string equal [get_filesets -quiet sim_1] ""]} {
    create_fileset -simset sim_1
}


set synth_1_flow     "Vivado Synthesis 2021"
set synth_1_strategy "Flow_PerfOptimized_high"
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -flow $synth_1_flow -strategy $synth_1_strategy -constrset constrs_1
} else {
    set_property flow     $synth_1_flow     [get_runs synth_1]
    set_property strategy $synth_1_strategy [get_runs synth_1]
}
current_run -synthesis [get_runs synth_1]

set impl_1_flow      "Vivado Implementation 2021"
set impl_1_strategy  "Performance_ExplorePostRoutePhysOpt"
if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -flow $impl_1_flow -strategy $impl_1_strategy -constrset constrs_1 -parent_run synth_1
} else {
    set_property flow     $impl_1_flow      [get_runs impl_1]
    set_property strategy $impl_1_strategy  [get_runs impl_1]
}
current_run -implementation [get_runs impl_1]


add_files -fileset constrs_1 -norecurse [file join $project_directory "rtl/constrs_1/new/top.xdc"]
add_files -fileset constrs_1 -norecurse [file join $project_directory "rtl/constrs_1/new/timing.xdc"]
set_property used_in_synthesis false [get_files rtl/constrs_1/new/timing.xdc]

proc add_verilog_file {fileset_name library_name file_name} {
    set file    [file normalize $file_name]
    set fileset [get_filesets   $fileset_name] 
    add_files -norecurse -fileset $fileset $file
    set file_obj [get_files -of_objects $fileset $file]
    set_property "file_type" "SystemVerilog" $file_obj
    set_property "library" $library_name $file_obj
}
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/interfaces/cpu_bus_if.sv
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/interfaces/mod_sync_if.sv
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/interfaces/seq_sync_if.sv
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/sequence/focus_calculator.sv
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/sequence/seq_operator.sv
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/transducer/delayed_fifo.sv
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/transducer/pwm_generator.sv
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/config_manager.sv
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/modulator.sv
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/normal_operator.sv
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/silent_lpf_v2.sv
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/synchronizer.sv
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/top.sv
add_verilog_file sources_1 xil_defaultlib rtl/sources_1/new/tr_cntroller.sv

proc add_header_file {fileset_name library_name file_name} {
    set file    [file normalize $file_name]
    set fileset [get_filesets   $fileset_name] 
    add_files -norecurse -fileset $fileset $file
    set file_obj [get_files -of_objects $fileset $file]
    set_property "file_type" "Verilog Header" $file_obj
    set_property "library" $library_name $file_obj
}
add_header_file sources_1 xil_defaultlib rtl/sources_1/new/cvt_uid.vh
add_header_file sources_1 xil_defaultlib rtl/sources_1/new/param.vh

import_ip rtl/sources_1/ip/addr_88/addr_88.xci
import_ip rtl/sources_1/ip/BRAM_CONFIG/BRAM_CONFIG.xci
import_ip rtl/sources_1/ip/BRAM_MOD_1/BRAM_MOD.xci
import_ip rtl/sources_1/ip/BRAM_SEQ_1/BRAM_SEQ.xci
import_ip rtl/sources_1/ip/BRAM16x512/BRAM16x512.xci
import_ip rtl/sources_1/ip/dist_mem_delay_1/dist_mem_delay.xci
import_ip rtl/sources_1/ip/div8/div8.xci
import_ip rtl/sources_1/ip/div64_48/div64_48.xci
import_ip rtl/sources_1/ip/divider/divider.xci
import_ip rtl/sources_1/ip/divider64/divider64.xci
import_ip rtl/sources_1/ip/lpf_silent/lpf_silent.xci
import_ip rtl/sources_1/ip/mult_19/mult_19.xci
import_ip rtl/sources_1/ip/mult_24/mult_24.xci
import_ip rtl/sources_1/ip/mult8x8/mult8x8.xci
import_ip rtl/sources_1/ip/sqrt_40/sqrt_40.xci
import_ip rtl/sources_1/ip/ultrasound_cnt_clk_gen/ultrasound_cnt_clk_gen.xci

proc add_sim_file {fileset_name library_name file_name} {
    set file    [file normalize $file_name]
    set fileset [get_filesets   $fileset_name] 
    add_files -norecurse -fileset $fileset $file
    set file_obj [get_files -of_objects $fileset $file]
    set_property "file_type" "SystemVerilog" $file_obj
    set_property "library" $library_name $file_obj
}
add_sim_file sim_1 xil_defaultlib rtl/sim_1/new/sim_delayed_fifo.sv
add_sim_file sim_1 xil_defaultlib rtl/sim_1/new/sim_lpf.sv
add_sim_file sim_1 xil_defaultlib rtl/sim_1/new/sim_pwm_generator.sv
add_sim_file sim_1 xil_defaultlib rtl/sim_1/new/sim_seq.sv

set_msg_config -id {Synth 8-7080} -new_severity {ADVISORY}
set_msg_config -id {Synth 8-7129} -new_severity {ADVISORY}
set_msg_config -id {Synth 8-5640} -new_severity {ADVISORY}
set_msg_config -id {Synth 8-5858} -new_severity {ADVISORY}
