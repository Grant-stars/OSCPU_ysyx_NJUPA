# 必做题

##### 1. 从状态机视角理解程序运行

```text
(0, x, x) -> (1, 0, x) -> (2, 0, 0) -> (3, 0, 1) -> (4, 1, 1) -> (2, 1, 1) -> (3, 1, 2) -> (4, 3, 2) -> (2, 3, 2) -> (3, 3, 3) -> (4, 6, 3) -> ... ->  -> (2, 4950, 99) -> (3, 4950, 100) -> (4, 5050, 100) -> (5, 5050, 100) -> (5, 5050, 100) -> ...
```

# 实验心得

## PA2

### 整理一条指令在NEMU中的执行过程

首先`exec_once`负责一条指令的执行。接受一个`Decode`类型的结构体指针`s`, 其中该结构体包含相关`PC`以及`ISADecodeInfo isa` （对于`risc-v32`来说是包含了`uint32_t inst`的一个结构体）。随后调用`isa_exec_once`根据具体的`isa`进行对应的指令操作。

#### 取指

`isa_exec_once()`做的第一件事情就是取指令，调用函数`inst_fetch()`(在`nemu/include/cpu/ifetch.h`中定义)专门负责取指令的工作. `inst_fetch()`最终会根据参数`len`来调用`vaddr_ifetch()`(在`nemu/src/memory/vaddr.c`中定义), 而目前`vaddr_ifetch()`又会通过`paddr_read()`来访问物理内存中的内容. 因此, 取指操作的本质只不过就是一次内存的访问而已.

`isa_exec_once()`在调用`inst_fetch()`的时候传入了`s->snpc`的地址, 因此`inst_fetch()`最后还会根据`len`来更新`s->snpc`, 从而让`s->snpc`指向下一条指令.

#### 译码

紧接着进入`decode_exec`函数，用`INSTPAT`模式匹配去匹配指令，解析出具体的`opcode`。`INSTPAT`模式匹配格式如下:

```text
INSTPAT(模式字符串, 指令名称, 指令类型, 指令执行操作);
例如：INSTPAT("??????? ????? ????? ??? ????? 00101 11", auipc, U, R(rd) = s->pc + imm);
```

`指令名称`在代码中仅当注释使用, 不参与宏展开; `指令类型`用于后续译码过程; 而`指令执行操作`则是通过C代码来模拟指令执行的真正行为.

首先`INSTPAT_START()`宏会定义`const void * __instpat_end = &&__instpat_end_`标签地址方便`goto`语句跳转至`INSTPAT_END()`宏生成的`__instpat_end_`标签处，代表一条指令解析完毕。

由这两个宏包裹起来的即各条模式匹配主体语句。以：

```text
INSTPAT("??????? ????? ????? 100 ????? 00000 11", lbu    , I, R(rd) = Mr(src1 + imm, 1));
```

为例，即用`lbu`这条规则去匹配指令（信息包含于结构体s中）。

将`INSTPAT`展开，首先会进入`pattern_decode`函数，提取模式字符串的特征，用于后续检验指令是否匹配该条规则。函数主体是`macro64(0)`，此处运用递归将宏展开，最终达到生成`macro(0)~macro(63)`的效果。对于`macro(i)`，`__key`依次移位，提取出模式字符串中的1，其余为0，也即提取出`opcode`和`funct3`；`__mask`将非`'?'`字符记录下来，作为掩码；`__shift`则从`str[0]`依次往后读取，记录下最后一个0或1后面的`'?'`，也即表示`opcode`距离最低位的比特数量。此处其值为：

```text
key = 100000000000011
mask = 111000001111111 
shift = 0
```

接着会利用得到的`shift` 、` mask`和 `key`对取得的指令`(uint64_t)INSTPAT_INST(s)`进行检查，看是否符合该条指令规则。若符合规则，将会利用宏`INSTPAT_MATCH`进行进一步的译码操作。其中宏参数`##__VA_ARGS__`表示`INSTPAT`宏所接受及参数中除了`pattern`的其余参数（可变参数）。在宏内，首先会定义`rd`、`src1` 、 `src2` 、 `imm` 等变量为后续做准备。接着调用`decode_operand`函数解析出指令中的操作数。在其中用到宏`BITS`进行位抽取，并且通过`src1R()` 、`src2R()`、` immS()`等宏，根据传入的指令类型`type`来进行操作数的译码，并将结果将记录到函数参数`rd`, `src1`, `src2`和`imm`中：

```text
  int rs1 = BITS(i, 19, 15);	#位抽取获取五位数字表示的寄存器rs1
  int rs2 = BITS(i, 24, 20);	#位抽取获取五位数字表示的寄存器rs2
  *rd     = BITS(i, 11, 7);		#位抽取获取五位数字表示的寄存器rd
 
#define src1R() do { *src1 = R(rs1); } while (0)	#将rs1的读取结果记录到相应的操作数变量src1中
#define src2R() do { *src2 = R(rs2); } while (0)	#将rs2的读取结果记录到相应的操作数变量src2中
#define immI() do { *imm = SEXT(BITS(i, 31, 20), 12); } while(0)	#抽取出I型立即数
#define immU() do { *imm = SEXT(BITS(i, 31, 12), 20) << 12; } while(0)		#抽取出U型立即数
#define immS() do { *imm = (SEXT(BITS(i, 31, 25), 7) << 5) | BITS(i, 11, 7); } while(0)		#抽取出S型立即数

```

#### 执行

在执行完译码之后，`INSTPAT_MATCH`中的`__VA_ARGS__ `即传入`INSTPAT`宏的`指令执行操作`参数（如`R(rd) = Mr(src1 + imm, 1))`），相应的操作宏如：

```text
#define R(i) gpr(i)		#读写寄存器
#define Mr vaddr_read	#读内存
#define Mw vaddr_write	#写内存

#该函数会检验传入的寄存器数字是否符合要求
static inline int check_reg_idx(int idx) {
  IFDEF(CONFIG_RT_CHECK, assert(idx >= 0 && idx < MUXDEF(CONFIG_RVE, 16, 32)));
  return idx;
}

#define gpr(idx) (cpu.gpr[check_reg_idx(idx)])	#cpu.gpr即寄存器堆
```

`INSTPAT_MATCH`结束之后，会跳转至`INSTPAT_END()`宏生成的`__instpat_end_`标签处，也即所有模式匹配规则的后面，代表一条指令解析完毕。随后`decode_exec()`函数将会返回`0`, 并一路返回到`exec_once()`函数中.

#### 更新

最后是更新PC，将`s->dnpc`赋值给`cpu.pc`即可。**在指令执行的过程中需正确地维护`s->dnpc`。**

### 调试宏

利用`-E`选项生成`.i`预处理结果文件查看宏展开，可运用`gdb`或者`printf`调试



### 为什么 ADD/SUB/MUL 不需要区分有符号和无符号

对于一个32位数，若最高位为1且按无符号解释成x，按照有符号数去解释，其值为
$$
\text{signed}(x)=x-2^{32}
$$
原因是符号位可以以
$$
-2^{31}
$$
为权来展开, 

故对于加法:
$$
\text{signed}(x_1) + \text{signed}(x_2) = x_1+ x_2-2\times 2^{32}
$$
取低32位结果，即对结果取：
$$
\text{mod} 2^{32}
$$
最后结果为：
$$
(x_1+ x_2-2\times 2^{32})\text{mod} 2^{32} =(x_1+ x_2)\text{mod} 2^{32}-(2\times 2^{32})\text{mod}2^{32}=(x_1+ x_2)\text{mod} 2^{32}-0=(x_1+ x_2)\text{mod} 2^{32}
$$
最终结果与全按无符号数解释结果一样，减法以及有符号数加减无符号数也是同理。

对于乘法：
$$
R_s=signed(x_1)×signed(x_2)=x_1x_2-(x_1+x_2)\times 2^{32}+2^{64}
$$
取低32位结果：
$$
R_s=(x_1x_2-(x_1+x_2)\times 2^{32}+2^{64})\text{mod} 2^{32}=x_1x_2
$$
最终结果与全按无符号数解释结果一样，有符号数乘无符号数也是同理。

但是MULH等取高位结果的指令就需区分有无符号。对于C语言来说，在处理`mulhsu`等指令的时候，只需根据其有无符号情况扩展至64位，然后直接进行乘法即可。因为数的类型只影响C语言如何看待这个数。以`mulhsu`为例，两操作数分别扩展至`int64_t`和`uint64_t`，进行乘法之后，模拟器不需要管结果是什么类型，直接取高32位即可，因为结果是什么类型只影响C语言怎么解读，并不会影响其具体的位值。**但是扩展时必须注意，如`src1 = -1`，若直接`(uint64_t)src1`，那么扩展之后`src1=0x00000000ffffffff`，并不是我们想要的`-1`；直接`(int64_t)src1`也不行，因为`src1`是`uint32_t`类型的，那么C语言会将其视为一个正数再做扩展。故需先转换为`int32_t`类型：即`(int64_t)(int32_t)src1`**

### 对AM的理解

AM是按照**计算机发展史**，将计算机功能**抽象**地**模块化**的**裸机运行时环境**。总的来说，应用程序调用AM提供的`api`，对于各个架构需要由具体的`api`实现。`klib`提供一些常用函数库（与机器无关），可以理解为klib 位于应用程序和 AM 之间，是一个更靠近应用程序的库抽象层。因此在`klib`上开发程序可以不去关心底层实现。

```text
                应用程序
                    |
          +---------+---------+
          |                   |
          v                   v
        klib              AM API
 (printf/memcpy/strlen)  (halt/io/putch)
          |
          |  部分函数调用
          v
        AM API
          |
          v
  架构相关AM实现
(riscv32-nemu/native/...)
          |
          v
      NEMU / 硬件
```

例如，程序或者`kilb`可以不管架构，直接调用`putch`函数，但是AM就需要对`putch`函数进行对应架构的实现：

```text
nemu下putch()实现为：
void putch(char ch) {
  outb(SERIAL_PORT, ch);
}

native下实现为：
void putch(char ch) {
  putchar(ch);
}

```



| PA       | Linux PC                |
| -------- | ----------------------- |
| 硬件模块 | 硬件模块                |
| ISA      | ISA                     |
| AM       | glibc + Linux ABI       |
| start.S  | crt1.o                  |
| klib     | libc                    |
| ioe      | system call             |
| NEMU     | Linux kernel + hardware |
| loader   | Linux ELF loader        |



### 如何快速了解Makefile

`make -n`或`make -nB`（**强制重建所有目标**）与`make --debug=v`结合使用（查看依赖分析过程以及所执行的命令），还可在`Makefile`文件中添加`$(info)`语句打印查看变量值（注意延迟展开的规则，见下文调试中遇到的bug）。

`make --trace`

`make -nB | vim `以`vim`形式浏览输出，可进行进一步处理提高可读性：

```vim
# 只保留gcc或g++开头的行
:%!grep "^\(gcc\|g++\)"

# 将环境变量$NEMU_HOME所指示字符串替换为$NEMU_HOME
:%!sed -e "s+$NEMU_HOME+\$NEMU_HOME+g"

# 将$NEMU_HOME/build/obj-riscv32-nemu-interpreter替换为$OBJ_DIR
:%s+\$NEMU_HOME/build/obj-riscv32-nemu-interpreter+$OBJ_DIR+g

# 将-c之前的内容替换为$CFLAGS
:%s/-O2.*=riscv32/$CFLAGS/g

# 将空格替换成换行并缩进两格
:%s/  */\r  /g

#全文每行下方插入空行
:%s/\n/\r\r/g

# 列出.c和.S文件
make ARCH=riscv32-nemu run -nB | grep -o "[^ ]*\.[cS]$" | xargs realpath 2> /dev/null | sort | uniq
```

### `AM`Makefile分析：

以`/home/grant/Projects/PA/ysyx-workbench/am-kernels/kernels/hello`为例，执行命令

```shell
make ARCH=riscv32-nemu run
```

，对于`hello`文件夹下的`Makefile`先指定目标文件名，接着执行`$(AM_HOME)/Makefile`里的内容：

```makefile
NAME = hello
SRCS = hello.c
include $(AM_HOME)/Makefile
```

对于`$(AM_HOME)/Makefile`，其中有

```makefile
-include $(AM_HOME)/scripts/$(ARCH).mk
```

也即读取了`scripts/riscv32-nemu.mk`文件，而在该文件中又有

```makefile
include $(AM_HOME)/scripts/isa/riscv.mk
include $(AM_HOME)/scripts/platform/nemu.mk
```

即读取了两个架构`Makefile`文件。在`nemu.mk`文件中有

```makefile
insert-arg: image
	@python $(AM_HOME)/tools/insert-arg.py $(IMAGE).bin $(MAINARGS_MAX_LEN) $(MAINARGS_PLACEHOLDER) "$(mainargs)"

image: image-dep
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: insert-arg
	$(MAKE) -C $(NEMU_HOME) ISA=$(ISA) run ARGS="$(NEMUFLAGS)" IMG=$(IMAGE).bin

gdb: insert-arg
	$(MAKE) -C $(NEMU_HOME) ISA=$(ISA) gdb ARGS="$(NEMUFLAGS)" IMG=$(IMAGE).bin

```

故先对`run`目标进行检查：

​	1.`run`文件不存在，检查其依赖`insert-arg`：

​		2.`insert-arg`文件不存在，检查其依赖`image`：

​			3.`image`文件不存在，检查其依赖`image-dep`：

​				4.在`$(AM_HOME)/Makefile`有`image-dep: $(IMAGE).elf`，故检查其依赖（展开后为				`/home/grant/Projects/PA/ysyx-workbench/am-kernels/kernels/hello/build/hello-riscv32-nemu.elf`）:

​					5.发现` $(IMAGE).elf`不存在，检查其依赖：

```makefile
$(IMAGE).elf: $(LINKAGE) $(LDSCRIPTS)
	@echo \# Creating image [$(ARCH)]
	@echo + LD "->" $(IMAGE_REL).elf
ifneq ($(filter $(ARCH),native),)
	@$(CXX) -o $@ -Wl,--whole-archive $(LINKAGE) -Wl,-no-whole-archive $(LDFLAGS_CXX)
else
	@$(LD) $(LDFLAGS) -o $@ --start-group $(LINKAGE) --end-group
endif
```

其中`$(LDSCRIPTS)`在`nemu.mk`中定义：`LDSCRIPTS += $(AM_HOME)/scripts/linker.ld`。而`$(LINKAGE)`则稍显复杂：

```makefile
OBJS      = $(addprefix $(DST_DIR)/, $(addsuffix .o, $(basename $(SRCS))))
LIBS     := $(sort $(LIBS) am klib) # lazy evaluation ("=") causes infinite recursions
$(info # variable LIBS: $(LIBS))	#打印变量
LINKAGE   = $(OBJS)  # library archives are added by LIB_TEMPLATE below
...
define LIB_TEMPLATE =
$$(AM_HOME)/$(1)/build/$(1)-$$(ARCH).a: force
	@$$(MAKE) -s -C $$(AM_HOME)/$(1) archive
LINKAGE += $$(AM_HOME)/$(1)/build/$(1)-$$(ARCH).a
endef

### Rule (recursive make): build a dependent library (am, klib, ...)
$(foreach lib, $(LIBS), $(eval $(call LIB_TEMPLATE,$(lib))))
endif
```

其中`OBJS`即为`$HELLO_WORK_DIR/build/riscv32-nemu/hello.o`（其中`$HELLO_WORK_DIR`为区别于下文`$AM_WORK_DIR`和`$KILB_WORK_DIR`的工作目录）；`LIBS`为`am klib`；`LINKAGE`先被定义为`$HELLO_WORK_DIR/build/riscv32-nemu/hello.o`。下文中的`LIB_TEMPLATE` 是一个 Makefile 规则模板；`foreach + call + eval` 根据 `LIBS` 列表动态生成每个依赖库的编译规则，并把生成的静态库路径加入链接列表 `LINKAGE`。其中 `$$(...)` 是为了让变量延迟到规则执行时再展开。

即相当于生成了

```makefile
$AM_HOME/am/build/am-riscv32-nemu.a: force
	make -s -C /home/user/abstract-machine/am archive


$AM_HOME/abstract-machine/klib/build/klib-riscv32-nemu.a: force
	make -s -C /home/user/abstract-machine/klib archive


LINKAGE += \
$AM_HOME/am/build/am-riscv32-nemu.a \
$AM_HOME/klib/build/klib-riscv32-nemu.a
```

故`LINKAGE`的值就为：

```text
# variable LINKAGE: $HELLO_WORK_DIR/build/riscv32-nemu/hello.o   $AM_WORK_DIR/build/am-riscv32-nemu.a $KLIB_WORK_DIR/build/klib-riscv32-nemu.a
```

​						6.发现`LINKAGE`文件不存在，因此触发相应构建规则：

- 对于`$HELLO_WORK_DIR/build/riscv32-nemu/hello.o`，触发规则

  ```makefile
  $(DST_DIR)/%.o: %.c
  	@mkdir -p $(dir $@) && echo + CC $<
  	@$(CC) -std=gnu11 $(CFLAGS) -c -o $@ $(realpath $<)
  ```

- 对于`$AM_WORK_DIR/build/am-riscv32-nemu.a `，触发规则

  ```makefile
  $AM_HOME/abstract-machine/klib/build/klib-riscv32-nemu.a: force
  	make -s -C /home/user/abstract-machine/am archive
  ```

  其中`force`的作用是让该规则强制执行：进入目录`/home/user/abstract-machine/am`并执行`make archive`：其内容为：

  ```makefile
  NAME     := am
  SRCS      = $(addprefix src/, $(AM_SRCS))
  INC_PATH += $(AM_HOME)/am/src
  
  include $(AM_HOME)/Makefile
  ```

  即指定构建的目标为`am`相关代码（`$(AM_SRCS)`在`nemu.mk`和`riscv32-nemu.mk`中涉及），随后读入`$(AM_HOME)/Makefile`文件。因为指定目标为`archive`，且有`archive: $(ARCHIVE)`，其中 `$(ARCHIVE)`目标：

  ```makefile
  ifeq ($(MAKECMDGOALS),archive)
  ### Rule (archive): objects (`*.o`) -> `ARCHIVE.a` (ar)
  $(ARCHIVE): $(OBJS)
  	@echo + AR "->" $(shell realpath $@ --relative-to .)
  	@$(AR) rcs $@ $^
  else
  ```

  故检查其依赖`$(OBJS)`，此处`$(OBJS)`则为`AM`相关文件：

  ```text
    $AM_WORK_DIR/build/riscv32-nemu/src/platform/nemu/trm.o 
    $AM_WORK_DIR/build/riscv32-nemu/src/platform/nemu/ioe/ioe.o 
    $AM_WORK_DIR/build/riscv32-nemu/src/platform/nemu/ioe/timer.o 
    $AM_WORK_DIR/build/riscv32-nemu/src/platform/nemu/ioe/input.o 
    $AM_WORK_DIR/build/riscv32-nemu/src/platform/nemu/ioe/gpu.o 
    $AM_WORK_DIR/build/riscv32-nemu/src/platform/nemu/ioe/audio.o 
    $AM_WORK_DIR/build/riscv32-nemu/src/platform/nemu/ioe/disk.o 
    $AM_WORK_DIR/build/riscv32-nemu/src/platform/nemu/mpe.o 
    $AM_WORK_DIR/build/riscv32-nemu/src/riscv/nemu/start.o 
    $AM_WORK_DIR/build/riscv32-nemu/src/riscv/nemu/cte.o 
    $AM_WORK_DIR/build/riscv32-nemu/src/riscv/nemu/trap.o 
    $AM_WORK_DIR/build/riscv32-nemu/src/riscv/nemu/vme.o  
  ```

  ​	这些依赖不存在，因此触发对应的构建规则：`$(DST_DIR)/%.o: %.c` 以及`$(DST_DIR)/%.o: %.S`（`$(AM_SRCS)`包含`.S`文件）

  `$(OBJS)`构建完毕后即执行`archive`构建规则，其中将`am`相关`.o`文件打包成`$AM_WORK_DIR/build/am-riscv32-nemu.a `文件，至此，最开始的`LINKAGE`中的`$AM_WORK_DIR/build/am-riscv32-nemu.a`构建完成

- 对于`$KLIB_WORK_DIR/build/klib-riscv32-nemu.a`，同理，触发规则

  ```makefile
  $AM_HOME/abstract-machine/klib/build/klib-riscv32-nemu.a: force
  	make -s -C /home/user/abstract-machine/klib archive
  ```

  最终`$KLIB_WORK_DIR/build/klib-riscv32-nemu.a`构建完成

  至此，`LINKAGE`全部构建完成。

​					5.` $(IMAGE).elf`依赖更新完毕，执行相应规则`@$(LD) $(LDFLAGS) -o $@ --start-group $(LINKAGE) --end-group`，链接生成`$HELLO_WORK_DIR/build/hello-riscv32-nemu.elf`文件。

​				4.`image-dep`的依赖（`$(IMAGE).elf`）更新完毕，而`image-dep`下是空规则，故直接认为 `image-dep` 成功更新。

​			3.`image`的依赖`image-dep`更新完毕，执行对应规则：对于`$(IMAGE).elf`文件，用`objdump`工具生成对应反汇编文件；用`objcopy`工具生成对应的机器码可执行文件

​		2.`insert-arg`的依赖`image`更新完毕，执行对应规则：用于把命令行参数插入到生成的 `binary` 镜像中。

​	1.`run`的依赖`insert-arg`：更新完毕，执行对应规则：

```makefile
$(MAKE) -C $(NEMU_HOME) ISA=$(ISA) run ARGS="$(NEMUFLAGS)" IMG=$(IMAGE).bin
```

进入`$(NEMU_HOME)`，执行命令，运行NEMU。

```makefile
make ISA=$(ISA) run ARGS="$(NEMUFLAGS)" IMG=$(IMAGE).bin
```

在`nemu`的`native.mk`中，`$(ARGS) $(IMG)`将作为参数传递给`$BINARY`(`/home/grant/Projects/PA/ysyx-workbench/nemu/build/riscv32-nemu-interpreter `)。**因此若要想以批处理模式运行NEMU，则可以在`$(NEMUFLAGS)`中添加`-b`选项。**



#### 调试中遇到的bug：

在利用`make -nB`查看输出的时候，发现构建`am-riscv32-nemu.a`目标时`$(OBJS)`为空，最后通过多个`$(info)`语句才搞清":"是延迟展开，即调用的时候再展开。而在定义处时，还未引入`riscv32-nemu.mk`相关文件，故`$(AM_SRCS)`、`$(SRCS)`、`$(OBJS)`均为空。而后面检查`$(ARCHIVE)`的依赖`$(OBJS)`时，已经引入了`riscv32-nemu.mk`相关文件，此时`$(AM_SRCS)`、`$(SRCS)`有了定义，故此时展开`$(OBJS)`便不为空。



### mainargs传递方式

-  在`riscv32-nemu`中，有

  ```c
  
  #define STRINGIFY(s)        #s
  #define TOSTRING(s)         STRINGIFY(s)
  ...
  static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER); // defined in CFLAGS
  ...
  int ret = main(mainargs);
  ...
  MAINARGS_MAX_LEN = 64
  MAINARGS_PLACEHOLDER = the_insert-arg_rule_in_Makefile_will_insert_mainargs_here
  CFLAGS += -DMAINARGS_MAX_LEN=$(MAINARGS_MAX_LEN) -DMAINARGS_PLACEHOLDER=$(MAINARGS_PLACEHOLDER)
  ```

  由此编译好的程序就有`main`函数接受了`mainargs = "the_insert-arg_rule_in_Makefile_will_insert_mainargs_here"`的参数。随后在`nemu.mk`文件中的`insert-arg:`目标下调用`python`脚本：

  ```python
  #!/usr/bin/env python3
  
  from sys import argv
  
  bin = argv[1]
  max_len = int(argv[2])
  placeholder = argv[3]
  mainargs = argv[4]
  
  if len(mainargs) >= max_len:
      print("Error: mainargs should not be longer than {0} bytes\n".format(max_len))
      exit(1)
  print("mainargs={0}".format(mainargs))
  
  fp = open(bin, 'r+b')
  data = fp.read()
  idx = data.find(str.encode(placeholder))
  if idx == -1:
      print("Error: placeholder not found!\n")
      exit(1)
  fp.seek(idx)
  mainargs_pad = str.encode(mainargs) + ((max_len - len(mainargs)) * str.encode("\0"))
  if len(mainargs_pad) != max_len:
      print("Error: len(mainargs_pad) != max_len\n")
      exit(1)
  fp.write(mainargs_pad)
  fp.close()
  
  ```

  找到二进制文件中字符串`"the_insert-arg_rule_in_Makefile_will_insert_mainargs_here"`的位置，将其替换成传入的`mainargs`字符串（若未传入则全替换成`'\0'`），由此实现了`mainargs`参数从`make`到C程序的传递。

- 在`native`中，`abstract-machine/am/src/native/platform.c`中有

  ```c
    const char *args = getenv("mainargs");
    halt(main(args ? args : "")); // call main here!
  ```

  `getenv`函数能获取指定环境变量的值（如果不存在则返回NULL）。在执行`make`指令的时候，传入`mainargs=xxx`的参数，而根据`make`手册：

  ```text
  When make runs a recipe, some variables defined in the makefile are placed into the environment of each command make invokes. By default, only variables that came from the make’s environment or set on its command line are placed into the environment of the commands. 
  ```

  变量`mainargs`属于命令行传入，故会放进`make`规则下所调用的每一条命令的（进程）环境变量里面，故`getenv("mainargs")`能成功获取其值。

### 游戏是如何运行的

#### 打字游戏逻辑

首先调用`init`相关函数初始化。在`video_init`函数中，通过访问抽象寄存器`AM_GPU_CONFIG`获得屏幕大小，将单个字母大小的像素pixels`blank[]`设为背景色，然后把整个屏幕填充成背景色紫色。最后通过一个三层循环，描述26个字母的形状：在`font[]`中有26行代表26个字母，每一行有16个字节，代表每个字母高16个像素（`CHAR_H`），每一个字节有8位，代表每个字母宽8个像素（`CHAR_W`）,用来指示字母所占一行的8个像素里哪些像素需要画出，不需要画出的设为背景色`COL_PURPLE`，将信息记录在`texture`里。

进入主循环后通过访问时钟寄存器来获取程序运行的时间并计算当前应该前进到的帧数`frames`。如果当前帧数`current`等于`frames`，则说明还未到前进一帧的时间，便会在这个`while(1)`中一直循环下去，和直到`frames>current`，才会进行游戏逻辑的更新。若`frames-current=2`，则会调用`game_logic_update()`函数进行(`frames-current`)次游戏逻辑更新。

在`game_logic_update()`函数内 ，首先会判断是否要创建新字符。`CPS`代表每秒生成的字符数，也就是说每经过`FPS/CPS`帧就会调用`new_char()`创建一个新字符。在`new_char()`内，会遍历`chars[]`结构体数组，找出第一个`c->ch=='\0'`的元素（即不在屏幕中），并将`c->ch`设为随机大写字母，并赋予其随机横坐标和速度（单位为像素/帧，范围），并将`c->t`设为0（`c->t`代表在屏幕底部存在的时间）。`new_char()`结束后，会遍历`chars[]`结构体数组，对`c->ch!='\0'`的元素（即在屏幕中）进行处理：

- 若`c->t > 0`，即判定为在屏幕底部，每一帧都会对进行自减操作，若减到0，则将其从屏幕中移除（即将`c->ch`设为`\0`）
- 否则字符在屏幕中，按照速度对y坐标进行增加，模拟下落。如果下落到屏幕底部则判定为`miss`，并将`c->t`设为`FPS`，也即未打出的字符将在屏幕底部停留一秒。

退出`game_logic_update()`函数后，会进入按键处理循环。在这个`while(1)`循环内会读取完键盘发送的按键事件队列，直到没有新的按键事件（`AM_KEY_NONE`）。对于每一个按下的键，会进入`check_hit()`函数，遍历`chars[]`数组找出屏幕中最靠近底部的对应按键的字母，并将他的速度设为`-(screen_h - CHAR_H + 1) / (FPS)`，即让这个字母向上移动。

处理完所有按键事件后，便会进入屏幕绘制逻辑。若新的一帧到来，即`current > rendered`，会进入`render()`函数。`x[NCHAR]`和` y[NCHAR]`记录了上一帧中在屏幕中的字符的位置。首先通过循环在这些位置写入背景色（即擦除上一帧的画面），然后分情况绘制还处于屏幕中的字符：

- 速度为正，即正在下落的字符，绘制成白色；
- 速度为负值，即正在上升的字符（已命中），绘制成绿色；
- 速度为0，即在屏幕底部的字符，绘制成红色。

同时也会将当前帧中还在屏幕上的字符位置记录到`x[NCHAR]`和` y[NCHAR]`里。

如此循环，形成了

```
while (1) {
  等待新的一帧();  // AM_TIMER_UPTIME
  更新游戏逻辑();  // TRM
  处理用户按键();  // AM_INPUT_KEYBRD
  绘制新的屏幕();  // AM_GPU_FBDRAW
}
```

的游戏逻辑。

#### AM与NEMU的支持

从程序的视角来看，访问设备 = 读出数据 + 写入数据 + 控制状态，操作对象为设备的寄存器。

而程序访问设备寄存器有两种方式：

- **端口I/O**：一种I/O编址方式是端口映射I/O(port-mapped I/O), CPU使用专门的I/O指令对设备进行访问, 并把设备的地址称作端口号.  有了端口号以后, 在I/O指令中给出端口号, 就知道要访问哪一个设备寄存器了. 市场上的计算机绝大多数都是IBM PC兼容机, IBM  PC兼容机对常见设备端口号的分配有[专门的规定](https://wiki.osdev.org/I/O_Ports#The_list).
- **内存映射I/O**：通过不同的物理内存地址给设备编址的. 这种编址方式将一部分物理内存的访问"重定向"到I/O地址空间中, CPU尝试访问这部分物理内存的时候, 实际上最终是访问了相应的I/O设备, CPU却浑然不知. 这样以后, CPU就可以通过普通的访存指令来访问设备.

设备访问的具体实现是架构相关的, 自然地, 设备访问这一架构相关的功能, 应该归入AM中.因此AM提供了与IOE有关的三个API:

```c
bool ioe_init();
void ioe_read(int reg, void *buf);
void ioe_write(int reg, void *buf);
```

同时这里的寄存器也是AM抽象出来的寄存器，与架构无关。`abstract-machine/am/include/amdev.h`中定义了常见设备的"抽象寄存器"编号和相应的结构.每个架构在实现各自的IOE API时, 都需要遵循这些定义(约定).  klib中提供了`io_read()`和`io_write()`这两个宏, 它们分别对`ioe_read()`和`ioe_write()`这两个API进行了进一步的封装.

也即**若程序想要访问设备，只需用`io_read()`和`io_write()`等API实现，具体实现交给具体的架构实现。**

- 在AM的`riscv32-nemu`架构中，由于`riscv32`采取的是内存映射的方案，因此在AM的`riscv32-nemu`架构具体实现中，`io_read()`和`io_write()`等会被实现为访问相对应的地址（具体的地址映射关系定义在`abstract-machine/am/src/platform/nemu/include/nemu.h`里面），于是这些代码最终会被编译成访存指令。
- 编译好的代码在对应平台(`riscv32-nemu`)运行时，`nemu`会根据访存指令中地址的范围来决定访问内存还是设备，若访问设备，则会根据约定读写对应的设备寄存器。而`nemu`没有具体的硬件，故通过软件方式模拟硬件的行为，对寄存器内的数据进行读写。

以这个打字游戏为例：

##### AM：

首先程序中调用`io_read(AM_TIMER_UPTIME)`函数来访问`AM_TIMER_UPTIME`这个寄存器。

​	这些寄存器在`amdev.h`里面定义，宏`AM_DEVREG`会对每个寄存器分配对应的`id`，并定义相应的结构体。例如

```c
AM_DEVREG( 6, TIMER_UPTIME, RD, uint64_t us);
//会展开成：
enum { AM_TIMER_UPTIME = (6) }; typedef struct { uint64_t us; } AM_TIMER_UPTIME_T;
```

宏`io_read`是`klib`定义的封装`ioe_read`的宏，例如

```c
io_read(AM_TIMER_UPTIME)
//展开成
({ AM_TIMER_UPTIME_T __io_param; ioe_read(AM_TIMER_UPTIME, &__io_param); __io_param; })
```

即定义一个对应寄存器类型的结构体，然后传给`ioe_read()`，最后返回读取的结构体。

进一步，`ioe_read()`会通过抽象寄存器的编号索引到一个处理函数, 然后调用它。对于`AM_TIMER_UPTIME`来说，会调用`inl()`函数执行对应的内存访问操作，将约定地址设备的寄存器（时钟）中的值读取出来。这个代码最后会被编译成访存指令。其中`inl()`等访存函数定义在`abstract-machine/am/src/$ISA/$ISA.h`里，**其中关键字`volatile`是必不可少的，否则很可能被编译器优化掉。**

##### NEMU：

`nemu`解析访存指令，会落到`paddr_read()`函数上来。在其内部对地址的范围进行判断，如果不在`pmem`的范围内，则会进入`mmio_read()`里面，对设备的寄存器进行访问。

`NEMU`里面的设备是由`src/device/`下相关代码模拟的。首先初始化设备时进入`init_device()`函数：

​	先进入`init_map`函数，为设备分配一块空间，用于模拟设备寄存器，存放相关寄存器的数据。

​	紧接着会进入各个设备的初始化函数。以`init_timer()`函数为例，调用`new_space(8)`为其分配一块大小为8字节的空间，对应两个	寄存器。然后调用`add_mmio_map()`函数，注册`0xa00003F8`处长度为8字节的MMIO空间（也即客户程序访问地址为`0xa00003F8`时	将被映射到RTC设备的`rtc_port_base`处），并将`name`（设备名称）,  `low`（MMIO空间起始地址）,  `high`（MMIO空间终止地址）,  	`space`（映射的设备寄存器空间）以及`callback`（回调函数）打包成结构体放进全局的结构体数组`maps`中。

在`mmio_read()`里面，首先会调用`fetch_mmio_map(addr)`函数，根据地址范围，在结构体数组`maps`中找到初始化时注册的对应的设备寄存器结构体，然后传递给`map_read()`函数。在其中，主要会调用对应的回调函数（**相当于更新设备对寄存器的读写，准备后续读数据**），然后会调用`host_read()`函数，根据相应的映射关系，读取`map->space`（映射的设备寄存器空间）的数据。（若在`map_write()`函数中，则先向`map->space`中写数据，然后再调用回调函数更新设备读取寄存器内的数据）。

由此便实现了计算机系统(NEMU, ISA, AM, 运行时环境, 程序) 的协同工作。



### 一些值的记录的bug：

- 宏定义未用`do{} while(0)`包裹
- 运行马里奥时方向键是反的。
