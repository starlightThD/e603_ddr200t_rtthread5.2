#############################################################
##    Author: Li Chao (lichao@nucleisys.com)
##    Description: some commonly used user-defined dc procs
#############################################################

proc set_dont_ungroup_hierarchy {{instance_list}} {
    #exit if no instance name is provided
    if {[string compare $instance_list ""] == 0} {
        puts "Instance name is missing."
        return 0
    }

    #convert all input into collection
    if {[regexp "_sel.*" $instance_list] == 0} {; #if instance_list is not a DC object
        set instance_items [get_cells $instance_list]
    } else {; #if instance_list is a DC object
        set instance_items $instance_list
    }

    #iterate on all input elements
    foreach_in_collection instance_col $instance_items {
        set instance [get_attribute $instance_col full_name]

        #exit if non existing hierarchical instance is provided
        if {[sizeof_collection [get_cells $instance]] < 1} {continue}

        #exit if provided instance is not hierarchical 
        if {[sizeof_collection [filter [get_cells $instance] "@is_hierarchical == true"]] < 1} {
           puts "Warning: Instance $instance is not hierarchical, attribute is not annotated."
           continue
        }

        #filter and get only hierarchical cells under the parent instance 
        set hier_cells [filter [get_cells -hier] -regexp "@full_name =~ ${instance}/.*"]
        set hier_cells [filter $hier_cells "@is_hierarchical == true"]

        #if cell list is empty, set attibute on parent cell, flag a message and exit
        set cell_count [sizeof_collection $hier_cells]
        set_ungroup $instance false
        if {$cell_count < 1} {
           puts "Information: There is no hierarchical instance under $instance. Only $instance \
recee t he set_ungroup false attribute."
           continue
        }

        #set the attribute on all cells found
        set_ungroup [filter $hier_cells "@is_hierarchical == true"] false

        #summary report
        puts "Information: Attribute set_ungroup false annotated for [expr $cell_count+1] \
hierchical cells, including parent cell $instance."
    }
    return 1
}

proc report_all_attributes {objects} {
    global the_attributes
    global suppress_errors
    set save_message $suppress_errors
    lappend suppress_errors UID-101 UID-341 UID-125

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
        set class [get_attribute $o object_class]
        set name [get_object_name $o]
     
        foreach attr $the_attributes {
            if {[set value [get_attribute $o $attr]]!=""} {
                echo [format "%-30s %30s" $attr $value]
            }
        }
    }
    set suppress_errors $save_message
    return 1
}

# Name:        get_multi_stage_level
# Requires:    collection of clock-gating cells
# Modifies:    None
# returns:     Nothing
# Description: Procedure that shows which stage each ICG belongs to

proc get_multi_stage_level {cgs} {
    redirect -var rpt {report_clock_gating -structure}
    foreach_in_collection cg $cgs {
        set cg_name [get_object_name $cg]
        # Check that the elements are valid
        if {[get_attribute -quiet $cg is_clock_gate]!=true} { 
            echo "Warning, $cg_name is not identified as a clock gate and cannot be reported"
        } else {
            # get the line with the clock gate you are looking for,  ugly?but works
            # echo $rpt 
            set line [regexp   -all  -line -inline -- "\[\\d]+ \[ ]+\[|] $cg_name " $rpt]
            #remove braces
            set line [string map {\{ "" \} ""}  $line]
            #uniquify spaces
            set line [regsub -line -all "\[ ]+"  $line " "]
            #echo $line 
            # get stage number:
            set stage [lindex [split $line "| "] 0]
            echo "$cg_name is in stage $stage"
        }
    }
}

# Name:        is_multi_stage
# Requires:    collection of cells
# Modifies:    None
# returns:     true if the cell is a clock-gate driving other clock gates, false otherwise
# Description: Procedure that checks if a cell is a mutistage clock gating cell

proc is_multi_stage {cell} { 
    set cell_name [get_attribute $cell full_name]
    if {[get_attribute -quiet $cell is_clock_gate]!=true} {
        echo "Warning: $cell_name is not a clock-gate"
        return false
    }
    set pin [get_pins -of_object $cell -filter "pin_direction==out"]
    set pins [filter_collection [all_connected [all_connected [get_attribute $pin full_name]]] "pin_direction == in"]
    foreach_in_collection gated_pin $pins { 
        set driven_cell [get_cells -of_objects $gated_pin] 
        if {[get_attribute -quiet $driven_cell clock_gating_logic]==true} {
            echo "$cell_name is a multi-stage clock-gate"
            return true
        }
    } 
    echo "$cell_name is not a multi-stage clock-gate"
    return false
}

## report timing paths cross clock domains
proc report_paths_cross_domains { clock_1 clock_2 }  {

    set path_no 1
    set paths [ get_timing_paths  -max_pat 1000 -nworst 1000 -delay max_rise -from [get_clocks $clock_1] -to [get_clocks $clock_2]]
    if { [sizeof_collection $paths] > 0 } {
        echo "There is timing  path crossing from clock  $clock_1  to clock $clock_2"
        echo "\n"
    }

    foreach_in_collection each_path $paths  {
        echo "path no $path_no"
        echo "The start point of the path --> [get_object_name [get_attribute $each_path startpoint]]"
        echo "The end point of the path --> [get_object_name [get_attribute $each_path endpoint]]"
        echo "\n"
        incr path_no
    }

    set path_no 1
    set paths [ get_timing_paths  -max_pat 1000 -nworst 1000 -delay max_rise -from [get_clocks $clock_2] -to [get_clocks $clock_1]]

    if { [sizeof_collection $paths] > 0 } {
        echo "There is timing  path crossing  from clock  $clock_2 to clock $clock_1"
        echo "\n"
    }

    foreach_in_collection each_path $paths {
        echo "path no $path_no"
        echo "The start point of the path --> [get_object_name [get_attribute $each_path startpoint]]"
        echo "The end point of the path --> [get_object_name [get_attribute $each_path endpoint]]"
        echo "\n"
        incr path_no
    }     
}

# proc used for debugging clock_info on pins
proc find_gen_clk {cpin} {
    set genclks [get_generated_clocks]
    set int_clks [get_attr $cpin clocks]
    foreach_in_collection intck $int_clks {
        if { [lsearch [get_object_name $genclks] [get_object_name $intck]] >= 0 } {
            puts "\t  Yes  \t\t   Yes   \t[get_object_name $cpin]      \tPin        \t[get_object_name $intck]"
            puts " "
        }
    }
    puts " INFO:: kindly pass the pin [get_object_name $cpin] to the proc Dbg_Clks to find out the master of the generated clock"
}

proc dbg_Clks {cell_pins} {
    puts "------ Starting ---------"
    puts " *************************************************************************************************** "
    foreach_in_collection cpin $cell_pins {
        puts ""
        puts ""
        puts "######  Tracing the Pin                                               : [get_object_name $cpin] ..."
        if {[get_attribute $cpin is_on_clock_network]==true} {
            set clks [get_attribute  $cpin clocks]
            set src_fanin [all_fanin -to [get_object_name $cpin] -flat -startpoints_only]
                puts " ## DETAILS OF THE CLOCK(s) found "
                puts " ---------------------------------"
                puts "\t FOUND \t\t GEN_CLK \tDES_OBJECT \tOBJ_TYPE \tNAME "  
                puts " \t  -----  \t    -------    \t  ----------   \t --------   \t---- "               
                foreach_in_collection src $src_fanin {
                    if { [get_attr [get_object_name $src] object_class] == "port" && [get_attr [get_object_name $src] is_on_clock_network] == "true" } {
                        puts "\t  Yes  \t\t   No    \t[get_object_name $src]          \tPort       \t[get_object_name $clks] "
                        puts " "
                    } elseif { [get_attr [get_object_name $src] object_class] == "pin" && [get_attr [get_object_name $src] is_on_clock_network] == "true" } {
                        find_gen_clk $src              
                    } else  {
                         puts ".. "
                    }
                }
        } else {
            puts "The object [get_object_name $cpin] is not on Clock-Network. Kindly provide another design object .."
        }
    } 
    puts ""
    puts " ----    Finished -------- "
    puts " *************************************************************************************************** "
}

# report all startpoint clocks for timing paths
proc report_startpoint_clock {timing_paths} {
    set xl_all_clks {}
    foreach_in_collection point $timing_paths {
        set xl_clk [get_object_name [get_attribute $point startpoint_clock]]
        lappend xl_all_clks $xl_clk
    }
    return [lsort -unique $xl_all_clks]
}

# report all endpoint clocks for timing paths
proc report_endpoint_clock {timing_paths} {
    set xl_all_clks {}
    foreach_in_collection point $timing_paths {
        set xl_clk [get_object_name [get_attribute $point endpoint_clock]]
        lappend xl_all_clks $xl_clk
    }
    return [lsort -unique $xl_all_clks]
}

# print object name
proc show_obj_names {objs} {
    foreach_in_collection xl_obj $objs {
        puts "[get_object_name $xl_obj]"
    }
}
