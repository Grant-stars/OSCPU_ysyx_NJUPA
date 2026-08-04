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

对于一个32位数，若按无符号解释成x，按照有符号数去解释，其值为
$$
\text{signed}(x)=x-2^{32}
$$
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

但是MULH等取高位结果的指令就需区分有无符号。

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

### 如何快速了解Makefile

`make -n`或`make -nB`（**强制重建所有目标**）与`make --debug=v`结合使用（查看依赖分析过程以及所执行的命令）

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
