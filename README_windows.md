下载e603_hbird文件夹和windows_toolchain.zip，解压对应的文件后修改toolchain文件夹名，将其放在没有中文的路径中，注意检查项目结构，保证e603_hbird-main和toolchain在同一个路径下，项目路径结构如下

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
	├── SSCOM32.exe
    ├── env-windows
    ├── build-tool
    ├── gcc
    └── openocd

```
## 工具依赖
windows的所有工具均包含在`toolchain`中，其中SSCOM32可以替换为任意串口工具，如Tera Term

## 开发板连接
本节参考资料为nuclei官方资料，参考[https://www.rvmcu.com/video.html#cateid8]
如果开发板上并未烧录e603 SoC的固件，则需要准备vivado工具。
![alt text](image.png)
对开发板供电并连接fpga_jtag接口后，vivado会检测到对应的开发板资源，右键`xc7a200t`，选择Add Configuration Memory Device,搜索n25q128-3.3v-spi-x1_x2_x4添加对应的flash资源后，右键该flash选则Program Configuration Memory Device，找到文件`e603_hbird-main/prebuilt/bitstream/e603_ddr200t.mcs`并确认即可完成固件烧录。

之后可以断开fpga_jtag，将hummingbird debugger kit连接到开发板和电脑上（注意两端接口均有正反之分），
windows通过windows设备管理器确认接入的端口号，并在tera term等串口工具中设置对应的端口号和波特率115200，完成对uart0的输入和输出配置，如果当前电脑仅接入一个串口，串口工具应该会自动识别。
## 环境配置

找到位于路径`.\toolchain\env-windows\env.exe`的工具，打开，等待环境配置后显示RT-Thread欢迎界面，此时可以进行类似linux的指令操作。
在env工具中，通过cd命令进入到路径`..\..\e603_hbird-main\nuclei-sdk\`下，在该路径下准备文件`setup_config.bat`，内容为`set NUCLEI_TOOL_ROOT=?:\path\to\your\toolchain`，注意修改路径为对应的toolchain路径,如`set NUCLEI_TOOL_ROOT=D:\ddr200t\toolchain`。
之后只需要执行`setup.bat`进行环境配置。根据输出，使用`where`命令确认关键工具`riscv64-unknown-elf-gcc`，`openocd`，`riscv64-unknown-elf-gdb`是否都位于`./toolchain`路径下，成功后即可开始编译

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