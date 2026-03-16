set dblib $env(SYN_ROOT)/dblib
sh mkdir -p $dblib
set ports [list]
foreach_in_collection p [get_ports] {
    set name [get_object_name $p]
    regexp {(^[\\\w]*)} $name match res
    if {[lsearch $ports $res] == -1} {
        lappend ports $res
    }
}
redirect -file $dblib/${DESIGN_NAME}.lib {
puts "library (${DESIGN_NAME}_${corner}) {"
foreach p $ports {
    set i [get_ports $p]
    set width [sizeof_collection $i]
    if {$width != 1} {
        set idxs [list]
        foreach_in_collection n $i {
            set name [get_object_name $n]
            set idx [lindex [regexp -inline {\[(\d+)\]} $name] 1]
            lappend idxs $idx
        }
        set start [lindex $idxs 0]
        set end [lindex $idxs end]
        puts "type (${p}_bus) {"
        puts "    base_type : array ;"
        puts "    data_type : bit ;"
        puts "    bit_width : $width ;"
        puts "    bit_from : $start;"
        puts "    bit_to : $end;"
        puts "    downto : true;"
        puts "}"
    }
}
puts "  cell (${DESIGN_NAME}) {"
puts "    area : 0;"
foreach p $ports {
    set i [get_ports $p]
    set width [sizeof_collection $i]
    if {$width == 1} {
        set name [get_object_name $i]
        set dir [get_attribute $i direction]
        puts "    pin ($name) {"
        puts "      direction : ${dir}put ;"
        puts "      capacitance : 0 ;"
        puts "    }"
    } else {
        set dir [lindex [get_attribute $i direction] 0]
        puts "    bus ($p) {"
        puts "        bus_type : ${p}_bus ;"
        puts "        direction : ${dir}put ;"
        foreach_in_collection j $i {
        puts "        pin ([get_object_name $j]) {"
        puts "            direction : [get_attribute $j direction]put ;"
        puts "            capacitance : 0 ;"
        puts "        }"
        }
        puts "    }"
    }
}
puts "  }"
puts "}"
}
read_lib $dblib/$DESIGN_NAME.lib
write_lib ${DESIGN_NAME}_${corner} -output $dblib/$DESIGN_NAME.db
