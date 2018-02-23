# (内联)大会快乐的通用语言(Joyfully Universal Language for (Inline) Assembly)

JULIA是一种可以编译到各种不同后端的中间语言(EVM 1.0,EVM 1.5和eWASM计划)。
正因为如此,它被设计成为所有三种平台的可用共同标准。
它已经可以用于Solidity内部的`内联汇编`,并且未来版本的Solidity编译器甚至将JULIA用作中间语言。
为JULIA构建高级优化器阶段也应该很容易。

!!! note

    请注意,用于`内联汇编`的风格不具有类型(所有内容都是`u256`),并且内置函数与EVM操作码相同。
    有关详细信息,请参阅内联汇编文档。

JULIA的核心组件是函数,块,变量,文本,for循环,if语句,switch语句,表达式和变量赋值。

JULIA是键入的,变量和文字都必须用后缀表示法指定类型。
支持的类型是`bool`,`u8`,`s8`,`u32`,`s32`,`u64`,`s64`,`u128`,`s128`,`u256`和`s256`。

JULIA本身甚至不提供运营商。
如果EVM是针对性的,则操作码将作为内置函数提供,但如果后端更改,则可以重新实现它们。
有关强制性内置函数的列表,请参阅下面的部分。

以下示例程序假定EVM操作码`mul`,`div`和`mod`可以本地或作为函数使用并计算指数运算。

```julia
{
    function power(base:u256, exponent:u256) -> result:u256
    {
        switch exponent
        case 0:u256 { result := 1:u256 }
        case 1:u256 { result := base }
        default:
        {
        result := power(mul(base, base), div(exponent, 2:u256))
        switch mod(exponent, 2:u256)
        case 1:u256 { result := mul(base, result) }
        }
    }
}
```

也可以使用for循环而不是递归来实现相同的函数。在这里,我们需要EVM操作码`lt`(小于)和`add`可用。

```julia
{
    function power(base:u256, exponent:u256) -> result:u256
    {
        result := 1:u256
        for { let i := 0:u256 } lt(i, exponent) { i := add(i, 1:u256) }
        {
        result := mul(result, base)
        }
    }
}
```

## JULIA规格

本章介绍JULIA代码。JULIA代码通常放置在JULIA对象中,将在下一章中介绍。

语法:

```julia
    Block = '{' Statement* '}'
    Statement = Block | FunctionDefinition | VariableDeclaration |  Assignment | Expression | Switch | ForLoop | BreakContinue
    FunctionDefinition = 'function' Identifier '(' TypedIdentifierList? ')'( '->' TypedIdentifierList )? Block
    VariableDeclaration = 'let' TypedIdentifierList ( ':=' Expression )?
    Assignment = IdentifierList ':=' Expression
    Expression = FunctionCall | Identifier | Literal
    If = 'if' Expression Block
    Switch = 'switch' Expression Case* ( 'default' Block )?
    Case = 'case' Literal Block
    ForLoop = 'for' Block Expression Block Block
    BreakContinue = 'break' | 'continue'
    FunctionCall = Identifier '(' ( Expression ( ',' Expression )* )? ')'
    Identifier = [a-zA-Z_$] [a-zA-Z_0-9]*
    IdentifierList = Identifier ( ',' Identifier)*
    TypeName = Identifier | BuiltinTypeName
    BuiltinTypeName = 'bool' | [us] ( '8' | '32' | '64' | '128' | '256' )
    TypedIdentifierList = Identifier ':' TypeName ( ',' Identifier ':' TypeName )*
    Literal = (NumberLiteral | StringLiteral | HexLiteral | TrueLiteral | FalseLiteral) ':' TypeName
    NumberLiteral = HexNumber | DecimalNumber
    HexLiteral = 'hex' ('"' ([0-9a-fA-F]{2})* '"' | ''' ([0-9a-fA-F]{2})* ''')
    StringLiteral = '"' ([^"rn] | '' .)* '"'
    TrueLiteral = 'true'
    FalseLiteral = 'false'
    HexNumber = '0x' [0-9a-fA-F]+
    DecimalNumber = [0-9]+
```

### 对语法的限制

交换机必须至少有一个案例(包括默认案例)。
如果表达式的所有可能值都被覆盖了,那么就不应该允许使用默认情况(例如,带`bool`表达式的开关并且同时具有true和false情况不应允许默认情况)。

每个表达式都计算为零个或多个值。
标识符和文字只计算一个值,函数调用计算的值等于所调用函数的返回值数。

在变量声明和赋值中,右侧表达式(如果存在)必须计算出与左侧变量数量相等的许多值。
这是唯一允许评估多个值的表达式。

也是语句的表达式(即在块级别)必须评估为零值。

在所有其他情况下,表达式必须评估为恰好一个值。

`continue`和`break`语句只能在循环体内使用,并且必须与循环具有相同的功能(或者两者必须位于顶层)。
for-loop的条件部分必须评估到一个值。

文字不能大于他们的类型。
定义的最大类型是256位宽。

### 范围规则

JULIA中的范围与块(除了函数和for循环,如下所述)以及所有声明(`FunctionDefinition`,`VariableDeclaration`)引入新的标识符到这些范围。

标识符在其定义的块中(包括所有子节点和子块)中都可见。
作为例外,for循环(第一个块)的`init`部分中定义的标识符在for循环的所有其他部分中都可见(但不在循环外部)。
在for循环的其他部分声明的标识符遵守常规的合成范围规则。
函数的参数和返回参数在函数体中可见,并且它们的名称不能重叠。

变量只能在声明后引用。
特别是变量不能在自己的变量声明的右边引用。
函数可以在声明之前被引用(如果它们是可见的)。

阴影是不允许的,即不能在另一个同名的标识符可见的位置声明一个标识符,即使它不可访问。

在函数内部,不可能访问在该函数之外声明的变量。

### 形式规范

我们通过在AST的各个节点上提供重载评估函数E来正式指定JULIA。
任何函数都可能有副作用,所以E需要两个状态对象和AST节点,并返回两个新的状态对象和可变数量的其他值。
这两个状态对象是全局状态对象(在EVM的上下文中是区块链的内存,存储和状态)和本地状态对象(局部变量的状态,即EVM中堆栈的一部分) ,。
如果AST节点是一个语句,E将返回两个状态对象和一个`模式`,用于`break`和`continue`语句。
如果AST节点是表达式,则E返回两个状态对象,并返回与表达式计算结果相同的值。

对于这个高层次的描述,全球国家的确切性质并没有说明。
本地状态`L`是标识符`i`到值`v`的映射,表示为`L [i] = v`。

对于标识符`v`,让`$ v`为标识符的名称。

我们将使用AST节点的解构符号。

```julia
E(G, L, <{St1, ..., Stn}>: Block) =
 let G1, L1, mode = E(G, L, St1, ..., Stn)
 let L2 be a restriction of L1 to the identifiers of L
 G1, L2, mode
E(G, L, St1, ..., Stn: Statement) =
 if n is zero:
  G, L, regular
 else:
  let G1, L1, mode = E(G, L, St1)
  if mode is regular then
 E(G1, L1, St2, ..., Stn)
  otherwise
 G1, L1, mode
E(G, L, FunctionDefinition) =
 G, L, regular
E(G, L, <let var1, ..., varn := rhs>: VariableDeclaration) =
 E(G, L, <var1, ..., varn := rhs>: Assignment)
E(G, L, <let var1, ..., varn>: VariableDeclaration) =
 let L1 be a copy of L where L1[$vari] = 0 for i = 1, ..., n
 G, L1, regular
E(G, L, <var1, ..., varn := rhs>: Assignment) =
 let G1, L1, v1, ..., vn = E(G, L, rhs)
 let L2 be a copy of L1 where L2[$vari] = vi for i = 1, ..., n
 G, L2, regular
E(G, L, <for { i1, ..., in } condition post body>: ForLoop) =
 if n >= 1:
  let G1, L1, mode = E(G, L, i1, ..., in)
  // mode has to be regular due to the syntactic restrictions
  let G2, L2, mode = E(G1, L1, for {} condition post body)
  // mode has to be regular due to the syntactic restrictions
  let L3 be the restriction of L2 to only variables of L
  G2, L3, regular
 else:
  let G1, L1, v = E(G, L, condition)
  if v is false:
 G1, L1, regular
  else:
 let G2, L2, mode = E(G1, L, body)
 if mode is break:
 G2, L2, regular
 else:
 G3, L3, mode = E(G2, L2, post)
 E(G3, L3, for {} condition post body)
E(G, L, break: BreakContinue) =
 G, L, break
E(G, L, continue: BreakContinue) =
 G, L, continue
E(G, L, <if condition body>: If) =
 let G0, L0, v = E(G, L, condition)
 if v is true:
  E(G0, L0, body)
 else:
  G0, L0, regular
E(G, L, <switch condition case l1:t1 st1 ...
case ln:tn stn>: Switch) =
 E(G, L, switch condition case l1:t1 st1 ...
case ln:tn stn default {})
E(G, L, <switch condition case l1:t1 st1 ...
case ln:tn stn default st'>: Switch) =
 let G0, L0, v = E(G, L, condition)
 // i = 1 ..
n
 // Evaluate literals, context doesn't matter
 let _, _, v1 = E(G0, L0, l1)
 ...
 let _, _, vn = E(G0, L0, ln)
 if there exists smallest i such that vi = v:
  E(G0, L0, sti)
 else:
  E(G0, L0, st')

E(G, L, <name>: Identifier) =
 G, L, L[$name]
E(G, L, <fname(arg1, ..., argn)>: FunctionCall) =
 G1, L1, vn = E(G, L, argn)
 ...
 G(n-1), L(n-1), v2 = E(G(n-2), L(n-2), arg2)
 Gn, Ln, v1 = E(G(n-1), L(n-1), arg1)
 Let <function fname (param1, ..., paramn) -> ret1, ..., retm block>
 be the function of name $fname visible at the point of the call.
 Let L' be a new local state such that
 L'[$parami] = vi and L'[$reti] = 0 for all i.
 Let G'', L'', mode = E(Gn, L', block)
 G'', Ln, L''[$ret1], ..., L''[$retm]
E(G, L, l: HexLiteral) = G, L, hexString(l),
 where hexString decodes l from hex and left-aligns it into 32 bytes
E(G, L, l: StringLiteral) = G, L, utf8EncodeLeftAligned(l),
 where utf8EncodeLeftAligned performs a utf8 encoding of l
 and aligns it left into 32 bytes
E(G, L, n: HexNumber) = G, L, hex(n)
 where hex is the hexadecimal decoding function
E(G, L, n: DecimalNumber) = G, L, dec(n),
 where dec is the decimal decoding function
```

### 类型转换函数

JULIA不支持隐式类型转换,因此存在提供显式转换的函数。
在将较大类型转换为较短类型时,如果发生溢出,则可能会发生运行时异常。

下面的类型转换函数必须可用: - `u32tobool(x:u32) -> y:bool` - `booltou32(x:bool) -> y:u32` - `u32tou64(x:u32) -> y:u64` - `u64tou32(x:u64) -> y:u32` -  等(待定)

### 低级函数

以下功能必须可用:

| *算术*  ||
|-|-|
| addu256(x:u256, y:u256) -> z:u256 | x + y |
| subu256(x:u256, y:u256) -> z:u256 | x - y |
| mulu256(x:u256, y:u256) -> z:u256 | x * y  |
| divu256(x:u256, y:u256) -> z:u256 | x/y |
| divs256(x:s256, y:s256) -> z:s256 | x/y, 对于二进制补码中的有符号数 |
| modu256(x:u256, y:u256) -> z:u256 | x % y |
| mods256(x:s256, y:s256) -> z:s256 | x % y, 对于二进制补码中的有符号数 |
| signextendu256(i:u256, x:u256) -> z:u256 | 符号从最低有效位(i * 8 + 7)位开始计数 |
| expu256(x:u256, y:u256) -> z:u256 | x对y的力量 |
| addmodu256(x:u256, y:u256, m:u256) -> z:u256  | (x + y)％m与任意精确算术 |
| mulmodu256(x:u256, y:u256, m:u256) -> z:u256  | (x * y)％m与任意精确算术 |
| ltu256(x:u256, y:u256) -> z:bool  | 1如果x <y,则为0 |
| gtu256(x:u256, y:u256) -> z:bool  | 1如果x> y,否则为0 |
| sltu256(x:s256, y:s256) -> z:bool | 如果x <y,则为1,否则为0,用于补码中的有符号数 |
| sgtu256(x:s256, y:s256) -> z:bool | 1如果x> y,则为0,否则为2的补码中的有符号数 |
| equ256(x:u256, y:u256) -> z:bool  | 1如果x == y,否则为0 |
| notu256(x:u256) -> z:u256         | ~x,x的每一位都是否定的  |
| andu256(x:u256, y:u256) -> z:u256 | 按位和x和y  |
| oru256(x:u256, y:u256) -> z:u256  | 按位和x和y |
| xoru256(x:u256, y:u256) -> z:u256 | x和y的按位异或  |
| shlu256(x:u256, y:u256) -> z:u256 | x乘以y的逻辑左移 |
| shru256(x:u256, y:u256) -> z:u256 | y的逻辑右移 |
| saru256(x:u256, y:u256) -> z:u256 | x乘以y的算术右移  |
| byte(n:u256, x:u256) -> v:u256    | x的第n个字节,其中最高有效字节是第0个字节不能用and256(shr256(n,x),0xff替代),并让它由EVM后端进行优化？  |

| *内存和存储* | |
|-|-|
| mload(p:u256) -> v:u256 | mem[p..(p+32)) |
| mstore(p:u256, v:u256)  | mem[p..(p+32)) := v |
| mstore8(p:u256, v:u256) | mem[p] := v & 0xff - 只修改一个字节  |
| sload(p:u256) -> v:u256 | storage[p] |
| sstore(p:u256, v:u256)  | storage[p] := v |
| msize() -> size:u256    | 内存大小,即最大访问内存索引,尽管是由于:由于内存扩展功能(由字扩展),这将总是32字节的倍数  |

| *执行控制*  ||
|-|-|
| create(v:u256, p:u256, s:u256) | 用代码mem [p ..(p + s))创建新的合同并发送v wei并返回新的地址 |
| call(g:u256, a:u256, v:u256, in:u256, | 在地址a处输入合同,输入mem [in ..(in + insize))insize:u256,out:u256,提供g gas和v wei,输出区域超大:u256)mem [out ..(out + oversize)),错误时返回0(例如,气体不足) - > r:u256和1成功 |
| callcode(g:u256, a:u256, v:u256, in:u256, | 与`call`完全相同,但只能使用insize:u256,out:u256,|的代码,并留在特大的背景下:u256) - > r:u256 |,否则是现行合同 |
| delegatecall(g:u256, a:u256, in:u256, | 与`callcode`相同,insize:u256,out:u256,|,但也要保持`caller`特大:u256) - > r:u256和`callvalue`  |
| stop() | 停止执行,与返回相同(0,0)也许它会有意义的退出,因为它等于return(0,0)。它可以是EVM后端的优化。|
| abort() | 中止(相当于EVM上的无效指令) |
| return(p:u256, s:u256) | 结束执行,返回数据mem [p ..(p + s)) |
| revert(p:u256, s:u256) | 结束执行,恢复状态更改,返回数据mem [p ..(p + s))  |
| selfdestruct(a:u256) | 终止执行,摧毁当前合同并将资金发送给 |
| log0(p:u256, s:u256) | 没有主题和数据记录[p ..(p + s)) |
| log1(p:u256, s:u256, t1:u256) | 记录主题t1和数据mem [p ..(p + s)) |
| log2(p:u256, s:u256, t1:u256, t2:u256) | 记录主题t1,t2和数据mem [p ..(p + s))  |
| log3(p:u256, s:u256, t1:u256, t2:u256, | 记录主题t,t2,t3和数据mem [p ..(p + s))t3:u256) |
| log4(p:u256, s:u256, t1:u256, t2:u256, | 记录主题t1,t2,t3,t4和数据mem [p ..(p + s))t3:u256,t4:u256) |

| *状态查询* ||
|-|-|
| blockcoinbase() -> address:u256 | 目前的采矿受益者  |
| blockdifficulty() -> difficulty:u256 | 当前块的难度 |
| blockgaslimit() -> limit:u256 | 阻止当前块的气体限制 |
| blockhash(b:u256) -> hash:u256 | 块nr b的散列值 - 仅适用于不包括当前值的最后256个块 |
| blocknumber() -> block:u256 | 当前程序段号 |
| blocktimestamp() -> timestamp:u256 | 当前块的时间戳,以秒为单位 |
| txorigin() -> address:u256 | 交易发件人 |
| txgasprice() -> price:u256 | 交易的天然气价格 |
| gasleft() -> gas:u256 | 天然气仍然可以执行 |
| balance(a:u256) -> v:u256 | wei在地址a处平衡 |
| this() -> address:u256 | 当前合同/执行上下文的地址 |
| caller() -> address:u256 | 呼叫发送者(不包括委托呼叫)  |
| callvalue() -> v:u256 | wei与目前的电话一起发送  |
| calldataload(p:u256) -> v:u256 | 从位置p开始的呼叫数据(32字节)  |
| calldatasize() -> v:u256 | 通话数据的大小以字节为单位 |
| calldatacopy(t:u256, f:u256, s:u256) | 从位置f的calldata复制s个字节到位置t的mem |
| codesize() -> size:u256 | 当前合同/执行上下文的代码大小  |
| codecopy(t:u256, f:u256, s:u256) | 从位置f的代码复制s字节到位置t的mem |
| extcodesize(a:u256) -> size:u256 | 地址a处代码的大小 |
| extcodecopy(a:u256, t:u256, f:u256, s:u256) | 像代码复制(t,f,s),但需要在地址a处进行编码 |

| *其他*  ||
|-|-|
| discardu256(unused:u256) | 丢弃价值 |
| splitu256tou64(x:u256) -> (x1:u64, x2:u64, | 将u256分成四个u64:x3:u64,x4:u64) |
| combineu64tou256(x1:u64, x2:u64, x3:u64, | 将四个u64合并成一个u256:x4:u64) - >(x:u256) |
| sha3(p:u256, s:u256) -> v:u256 | keccak(mem[p...(p+s))) |

### 后端

后端或目标是JULIA到特定字节码的翻译。
每个后端都可以暴露以后端名称为前缀的函数。
我们为两个建议的后端保留`evm_`和`ewasm_`前缀。

### 后端: EVM

EVM目标将具有暴露于evm_前缀的所有底层EVM操作码。

### 后端: "EVM 1.5"

TBD

### 后端:eWASM

TBD

## JULIA对象的规范

语法:

```julia
    TopLevelObject = 'object' '{' Code? ( Object | Data )* '}'
    Object = 'object' StringLiteral '{' Code? ( Object | Data )* '}'
    Code = 'code' Block
    Data = 'data' StringLiteral HexLiteral
    HexLiteral = 'hex' ('"' ([0-9a-fA-F]{2})* '"' | ''' ([0-9a-fA-F]{2})* ''')
    StringLiteral = '"' ([^"rn] | '' .)* '"'
```

上面,`Block`指的是上一章中解释的JULIA代码语法中的`Block`。

JULIA对象示例如下所示:

```julia
    // 代码由单个对象组成。
    // 单个`代码`节点是对象的代码。
    // 每个(其他)命名的对象或数据部分都被序列化并可供特殊内置函数datacopy / dataoffset / datasize访问
    object {
        code {
            let size = datasize("runtime")
            let offset = allocate(size)
            // 这将变成eWASM的内存 - >内存拷贝,以及EVM的代码拷贝
            datacopy(dataoffset("runtime"), offset, size)
            // 这是一个构造函数,返回运行时代码
            return(offset, size)
        }

        data "Table2" hex"4123"

        object "runtime" {
            code {
                // 运行时代码
                let size = datasize("Contract2")
                let offset = allocate(size)
                // 这将变成eWASM的内存 - >内存拷贝,以及EVM的代码拷贝
                datacopy(dataoffset("Contract2"), offset, size)
                // 构造函数参数是单个数字0x1234
                mstore(add(offset, size), 0x1234)
                create(offset, add(size, 32))
            }

            // 嵌入对象。
            // 用例是外部是工厂合同,Contract2是工厂创建的代码
            object "Contract2" {
                code {
                    // 代码在这里..
                }

                object "runtime" {
                    code {
                        // 代码在这里...
                    }
                }

                data "Table1" hex"4123"
            }
        }
    }
```