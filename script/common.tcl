set_param general.maxThreads 16

set_msg_config -id {[Synth 8-6901]} -string "R_PORTS" -new_severity INFO
set_msg_config -id {[Synth 8-6901]} -string "W_PORTS" -new_severity INFO
set_msg_config -id {[Synth 8-327]} -new_severity ERROR
set_msg_config -id {[Power 33-332]} -new_severity INFO
set_msg_config -id {[DRC CFGBVS-1]} -new_severity INFO
set_msg_config -id {[Vivado 12-750]} -new_severity INFO
