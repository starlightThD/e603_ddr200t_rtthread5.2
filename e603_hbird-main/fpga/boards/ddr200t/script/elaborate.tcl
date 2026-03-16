set_param {messaging.defaultLimit} 1000000
set_param place.doNopt2 0
set_param pwropt.maxFaninFanoutToNetRatio 100

read_ip [glob -directory $ipdir [file join * {*.xci}]]

synth_design -include_dirs $env(INSTALL_RTL)/subsys/  -include_dirs $env(INSTALL_RTL)/core/ -top $top -rtl -rtl_skip_ml

