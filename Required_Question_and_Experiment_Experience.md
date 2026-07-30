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

> 但是MULH等取高位结果的指令就需区分有无符号