## E603 SoC 修改说明

当前版本的E603 SoC相比于官方的E603预编译mcs和bit文件，修改了LED的输出功能，增加了SW的输入，并增加GPIO模块用于支持总线和GPIO的通信，具体修改如下
1. 原有LED0显示`wfi_mode`状态，亮起表示芯片进入wfi模式；LED1显示`cpu_sleep`模式，亮起表示CPU进入睡眠；LED7表示MCU就位，当MCU准备完毕后会自动亮起。
2. 现将上述功能全部悬空不用，而将LED0-7全部注册为GPIO的输出端。同时将SW0-7注册为GPIO的输入端。其基地址为`0x10010000`，LED寄存器偏移为`0x0000` ，SW寄存器偏移为`0x0004`，并提供了使用样例程序，位于`application/baremetal/demo_gpio`中，可以按照实验手册实验一的步骤进行测试使用。

## E603 SoC 编译说明

E603 官方版本限制了IP核`mig_7series`版本为4.2，因此建议使用vivado 2019及以上版本进行编译，考虑到实验室环境，现将该版本限制去除，支持vivado 2018.1版本使用，但编译时对于ddr3有部分时序冲突，测试暂时没有出现错误，如果出现问题，优先考虑更换vivado版本，并在文件`e603_hbird-main/fpga/boards/ddr200t/script/ip.tcl`中修改
```
if ($env(DDR3_EN)) {
create_ip -vendor xilinx.com -library ip -name mig_7series -module_name ddr3 -dir $ipdir -force
set_property CONFIG.XML_INPUT_FILE [file normalize $scriptdir/mig_a.prj
  ] [get_ips ddr3]
}
```
为
```
if ($env(DDR3_EN)) {
create_ip -vendor xilinx.com -library ip -name mig_7series -version 4.2 -module_name ddr3 -dir $ipdir -force
set_property CONFIG.XML_INPUT_FILE [file normalize $scriptdir/mig_a.prj
  ] [get_ips ddr3]
}
```

在对SoC做出修改后，首先确定电脑上是否有vivado工具，然后找到`\Xilinx\Vivado\2017.4\settings64.bat`路径，通过`env`工具打开终端，执行`path/to/settings64.bat`来配置windows环境，之后通过cd命令进入路径`e603_hbird-main/fpga`，在该路径下执行`make clean && make mcs`重新编译适配ddr200t的mcs文件，该过程可能需要20分钟，之后在路径`e603_hbird-main/fpga/gen/ddr200t/obj`中找到对应的mcs文件并使用。
对于linux系统，只需要在终端中执行上述操作即可。