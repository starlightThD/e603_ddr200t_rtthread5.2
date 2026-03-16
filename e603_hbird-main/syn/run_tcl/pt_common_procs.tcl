# print object name
proc show_obj_names {objs} {
    foreach_in_collection xl_obj $objs {
        puts "[get_object_name $xl_obj]"
    }
}

# report all attributes of a collection
proc report_all_attributes {objects} {
    global the_attributes

    if ![info exist the_attributes] { 
        redirect the_attr.txt {list_attr -appl}
        set f [open the_attr.txt]
        while {[gets $f line]!=-1} {
            if {[string index $line 0]=="-"} break
        }
        while {[gets $f line]!=-1} {
            if {[string index $line 0]=="-"} break
            lappend the_attributes [lindex $line 0]
        }
        close $f
        file delete the_attr.txt
        set the_attributes [lsort -unique $the_attributes]
    }
    
    foreach_in_collection o $objects {
        set class [get_attribute -quiet $o object_class]
        set name [get_object_name $o]
     
        foreach attr $the_attributes {
            if {[set value [get_attribute -quiet $o $attr]]!=""} {
                if {[regexp {^_sel\d+} $value]} {
                    set value [get_object_name $value]
                    echo [format "%-30s %30s" $attr $value]
                } else {
                    echo [format "%-30s %30s" $attr $value]
                }
            }
        }
    }

    return 1
}

##############################################################
## summary of real delay for paths
## timing_paths: collection returned from get_timing_paths
##############################################################
proc get_io_real_delay {timing_paths} {
    if {$timing_paths == ""} {
        echo "Warning: No valid timing paths found."
        return 1
    }
    set startpoint_clock  [lsort -unique [get_object_name [get_attribute $timing_paths startpoint_clock]]]
    set endpoint_clock    [lsort -unique [get_object_name [get_attribute $timing_paths endpoint_clock]]]
    set startpoint_period [format "%.2f" [get_attribute [get_clocks $startpoint_clock] period]]
    set endpoint_period   [format "%.2f" [get_attribute [get_clocks $endpoint_clock] period]]
    set path_type         [lsort -unique [get_attribute $timing_paths path_type]]
    if {$startpoint_clock == $endpoint_clock} {
        if {[get_attribute -quiet $timing_paths startpoint_input_delay_value] == ""} {
            set delay_t "output_delay"
        } else {
            set delay_t "input_delay"
        }
    } else {
        set delay_t "max_min_delay"
    }
    echo "\n"
    echo [format "startpoint_clock_name    : %40s" $startpoint_clock]
    echo [format "startpoint_clock_period  : %40f" $startpoint_period]
    echo [format "endpoint_clock_name      : %40s" $endpoint_clock]
    echo [format "endpoint_clock_period    : %40f" $endpoint_period]
    echo [format "constrain_type           : %40s" $delay_t]
    echo [format "path_type                : %40s" $path_type]
    echo [string repeat "-" 170]
    if {$delay_t == "max_min_delay"} {
        if {$startpoint_clock == "soc_iomux_v_clk"} {
            echo [format "%-16s %-140s %-10s" "startpoint" "endpoint(clock_latency)" "arrival_time"]
        } else {
            echo [format "%-140s %-16s %-10s" "startpoint(clock_latency)" "endpoint" "arrival_time"]
        }
        echo [string repeat "-" 170]
        foreach_in_collection t_path $timing_paths {
            set startpoint [get_object_name [get_attribute $t_path startpoint]]
            set endpoint   [get_object_name [get_attribute $t_path endpoint]]
            set arrival    [get_attribute $t_path arrival]
            if {$startpoint_clock == "soc_iomux_v_clk"} {
                set startpoint_input_delay_value [get_attribute $t_path startpoint_input_delay_value]
                set startpoint_clock_latency [get_attribute $t_path startpoint_clock_latency]
                set endpoint_clock_latency [get_attribute $t_path endpoint_clock_latency]
                set path_delay [expr $arrival-$startpoint_input_delay_value-$startpoint_clock_latency]
                if {[string length $endpoint] > 140} {
                    echo [format "%-16s %-140s" $startpoint "$endpoint\($endpoint_clock_latency\)"]
                    echo [format "%-157s %-10f" " " $path_delay]
                } else {
                    echo [format "%-16s %-140s %-10f" $startpoint "$endpoint\($endpoint_clock_latency\)" $path_delay]
                }
            } else {
                set startpoint_clock_latency [get_attribute $t_path startpoint_clock_latency]
                set path_delay [expr $arrival-$startpoint_clock_latency]
                if {[string length $startpoint] > 140} {
                    echo [format "%-140s" "$startpoint\($startpoint_clock_latency\)"]
                    echo [format "%-140s %-16s %-10f" " " $endpoint $path_delay]
                } else {
                    echo [format "%-140s %-16s %-10f" "$startpoint\($startpoint_clock_latency\)" $endpoint $path_delay]
                }
            }
        }
    } elseif {$delay_t == "input_delay"} {
        echo [format "%-16s %-140s %-10s" "startpoint" "endpoint(clock_latency)" "path_delay"]
        echo [string repeat "-" 170]
        foreach_in_collection t_path $timing_paths {
            set startpoint [get_object_name [get_attribute $t_path startpoint]]
            set endpoint   [get_object_name [get_attribute $t_path endpoint]]
            set arrival    [get_attribute $t_path arrival]
            set startpoint_input_delay_value [get_attribute $t_path startpoint_input_delay_value]
            set startpoint_clock_latency [get_attribute $t_path startpoint_clock_latency]
            set path_delay [expr $arrival-$startpoint_input_delay_value-$startpoint_clock_latency]
            set endpoint_clock_latency [get_attribute $t_path endpoint_clock_latency]
            echo [format "%-16s %-140s %-10f" $startpoint "$endpoint\($endpoint_clock_latency\)" $path_delay]
        }
    } elseif {$delay_t == "output_delay"} {
        echo [format "%-140s %-16s %-10s" "startpoint(clock_latency)" "endpoint(clock_latency)" "path_delay"]
        echo [string repeat "-" 170]
        foreach_in_collection t_path $timing_paths {
            set startpoint [get_object_name [get_attribute $t_path startpoint]]
            set endpoint   [get_object_name [get_attribute $t_path endpoint]]
            set arrival    [get_attribute $t_path arrival]
            set startpoint_clock_latency [get_attribute $t_path startpoint_clock_latency]
            set path_delay [expr $arrival-$startpoint_clock_latency]
            set endpoint_clock_latency [get_attribute $t_path endpoint_clock_latency]
            echo [format "%-140s %-16s %-10f" "$startpoint\($startpoint_clock_latency\)" "$endpoint\($endpoint_clock_latency\)" $path_delay]
        }
    } else {
        puts "Error: delay_type must be specified in third args and must be in one of {max_min_delay input_delay output_delay}"
    }
}
