下载e603_hbird文件夹和linux_toolchain.tar.gz，解压对应的文件后按照如下路径修改toolchain
文件夹名，注意检查项目结构，保证e603_hbird-main和toolchain在同一个路径下，项目路径结构如下

```
.
├── e603_hbird-main
│   ├── design
│   ├── doc
│   ├── fpga
│   ├── nuclei-sdk
│   ├── prebuilt
│   ├── README.md
│   └── syn
├── README.md
└── toolchain
    ├── gcc
    └── openocd
```
## 工具依赖
需要自带`make`工具进行编译，需要自行准备串口通信工具,linux可以使用minicom。

## 开发板连接
本节参考资料为nuclei官方资料，参考[https://www.rvmcu.com/video.html#cateid8]
如果开发板上并未烧录e603 SoC的固件，则需要准备vivado工具。
![alt text](image.png)
对开发板供电并连接fpga_jtag接口后，vivado会检测到对应的开发板资源，右键`xc7a200t`，选择Add Configuration Memory Device,搜索n25q128-3.3v-spi-x1_x2_x4添加对应的flash资源后，右键该flash选则Program Configuration Memory Device，找到文件`e603_hbird-main/prebuilt/bitstream/e603_ddr200t.mcs`并确认即可完成固件烧录。

之后可以断开fpga_jtag，将hummingbird debugger kit连接到开发板和电脑上（注意两端接口均有正反之分），
linux通过命令`lsusb`搜索是否有端口接入，并使用`ls /dev/ttyUSB*`确认映射端口号，若使用minicom，命令为`minicom -D /dev/ttyUSB* -b 115200`，注意修改端口号为上述查询的值
> **注意**：如果遇到权限问题，可以将当前用户加入 `dialout` 组：
> ```bash
> sudo usermod -aG dialout $USER
> # 需要重新登录生效
> ```

## 环境配置

在单一终端中，`cd` 到路径`./e603_hbird-main/nuclei-sdk`下，然后添加编译环境的工具，其本质是将toolchain中的riscv工具链和openocd加入到工作环境
执行`source ./linux_env_setup.sh`添加编译环境（若缺失执行权限使用chmod添加），该环境仅在单一终端中有效。
根据输出，使用`where`命令确认关键工具`riscv64-unknown-elf-gcc`，`openocd`，`riscv64-unknown-elf-gdb`是否都位于`./toolchain`路径下

编译程序时，进入到路径`./e603_hbird-main/nuclei-sdk/application`的任意一个含有`Makefile`和`npk.yml`的路径下(如`cd ./rtthread_5_2/msh`)，执行对应的指令编译，调试和下载
建议配置为
1. 编译: `make clean SOC=evalsoc CORE=ux600fd BOARD=nuclei_fpga_eval all`
2. 上传: `make clean SOC=evalsoc CORE=ux600fd BOARD=nuclei_fpga_eval DOWNLOAD=flash upload`
3. 调试: `make clean SOC=evalsoc CORE=ux600fd BOARD=nuclei_fpga_eval DOWNLOAD=ilm debug`

## 上传
通过调试器上传到MCU的flash中，之后使用串口工具，找到对应的USB口，设置波特率为115200，接收串口信息。上传成功则开发板上的LED0会亮起（除非进入gdb或者uart阻塞），串口端至少会输出
```
Nuclei SDK Build Time: Mar  4 2026, 17:27:00 
Download Mode: FLASH CPU Frequency 50000035 Hz 
CPU HartID: 0 
```
## 调试
执行指令后按下enter进入gdb窗口，按照一般模式进行调试，调试过程中如果使用fpga_rst按键会导致调试器丢失信号，如果需要复位调试请使用指令
```
# 确保出现(gdb)表示进入单步停止
load # 重新载入elf文件
set $pc=0x20000000 # 如果下载时选择的是DOWNLOAD=flash
set $pc=0x60000000 # 如果下载时选择的是DOWNLOAD=ilm
```
## 关于rtthread-nano
官方sdk支持完整的rtthread-nano，在application中的rtthread文件夹，进入到对应的路径后编写程序，按照上述的方法操作即可

## 关于rtthread 5.2
个人移植的rtthread 5.2版本。编译方式与rtthread-nano方式相同，考虑到性能限制，部分功能未启用，部分功能可以选择关闭，具体参考`application/rtthread_5_2/msh/README.md`中对于`rtconfig.h`的描述。