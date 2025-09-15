# //////////////////////////////////////////////////////////////////////////////
# Tcl Script for PPA Analysis of the MAC Unit (Truly Final Version)
# //////////////////////////////////////////////////////////////////////////////

# --- Configuration ---
set part "xczu3eg-sbva484-1-e"
set top_module "pipelined_mac"
set run_name "run_${top_module}"
set saif_file "./activity_sparse.saif"

# --- End of Configuration ---

puts "INFO: Starting PPA analysis for module: $top_module"
puts "INFO: Using run name: $run_name"

# //////////////////////////////////////////////////////////////////////////////
# Step 1: Synthesis
# //////////////////////////////////////////////////////////////////////////////
synth_design -top $top_module -part $part -name $run_name

puts "INFO: Synthesis complete."

# //////////////////////////////////////////////////////////////////////////////
# Step 2: Implementation
# //////////////////////////////////////////////////////////////////////////////
opt_design
place_design
route_design

puts "INFO: Implementation complete."

# //////////////////////////////////////////////////////////////////////////////
# Step 3: Report Generation
# //////////////////////////////////////////////////////////////////////////////
puts "INFO: Generating reports..."

# First, save the utilization and timing reports.
report_utilization -file ./${top_module}_utilization.rpt
report_timing_summary -file ./${top_module}_timing.rpt

# *** CHANGED HERE: Correct syntax for power reporting with SAIF ***
# 1. Read the switching activity from the SAIF file into the design.
read_saif -file $saif_file
# 2. Now run the power report. It will automatically use the activity data.
report_power -file ./${top_module}_power.rpt


puts "SUCCESS: PPA Analysis for $top_module is complete."
puts "INFO: Reports are saved in your main project directory."