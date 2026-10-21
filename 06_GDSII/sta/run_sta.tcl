read_liberty $::env(LIBERTY)
read_verilog 06_GDSII/synthesis/netlist.v
link_design a09_abs_sign
read_sdc 04_IMPLEMENTATION/constraints/design.sdc

report_checks -path_delay max > 06_GDSII/sta/timing_report_max.txt
report_checks -path_delay min > 06_GDSII/sta/timing_report_min.txt
report_wns > 06_GDSII/sta/wns.txt
report_tns > 06_GDSII/sta/tns.txt
report_power > 06_GDSII/power/power_report.txt

exit
