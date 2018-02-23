# Solidity汇编

Solidity定义了一种汇编语言，也可以在没有Solidity的情况下使用。
此汇编语言也可以用作Solidity源代码中的`内联汇编`。
我们从描述如何使用内联汇编开始，以及它如何与独立汇编不同，然后指定汇编本身。

## 内部汇编

为了更细粒度的控制，尤其是为了通过编写库来增强语言，可以使用接近虚拟机的语言将内联汇编中的Solidity语句交织在一起。
由于EVM是堆栈机，因此通常很难解决正确的堆栈插槽问题，并为堆栈上正确的操作码提供参数。
Solidity的内联汇编试图通过以下功能来促进编写手动汇编时出现的问题和其他问题：

- functional-style opcodes: `mul(1, add(2, 3))` instead of `push1 3 push1 2 add push1 1 mul`
- assembly-local variables: `let x := add(2, 3)  let y := mload(0x40)  x := add(x, y)`
- access to external variables: `function f(uint x) public { assembly { x := sub(x, 1) } }`
- labels: `let x := 10  repeat: x := sub(x, 1) jumpi(repeat, eq(x, 0))`
- loops: `for { let i := 0 } lt(i, x) { i := add(i, 1) } { y := mul(2, y) }`
- if statements: `if slt(x, 0) { x := sub(0, x) }`
- switch statements: `switch x case 0 { y := mul(x, 2) } default { y := 0 }`
- function calls: `function f(x) -> y { switch x case 0 { y := 1 } default { y := mul(x, f(sub(x, 1))) }   }`

我们现在要详细描述内联汇编语言。

!!! Warning

    内联汇编是一种在低级别访问以太坊虚拟机的方法。
    这丢弃了Solidity的几个重要的安全特征。

!!! todo

    写下内联汇编的范围规则是如何有点不同以及例如使用库的内部函数时出现的复杂情况。
    此外，编写有关编译器定义的符号。

### 例

以下示例提供了库代码来访问另一个合约的代码并将其加载到`bytes`变量中。
这对于`简单的固体`来说根本不可能，并且这个想法是组装库将被用来以这种方式增强语言。

```
pragma solidity ^0.4.0;

library GetCode {
    function at(address _addr) public view returns (bytes o_code) {
        assembly {
            // 检索代码的大小，这需要大会
            let size := extcodesize(_addr)
            // 分配输出字节数组 - 这也可以通过使用`o_code = new bytes(size)`来进行组装
            o_code := mload(0x40)
            // 新的“内存结束”包括填充
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // 在存储器中存储长度
            mstore(o_code, size)
            // 实际上检索代码，这需要大会
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }
}
```

在优化器无法生成高效代码的情况下，内联汇编也可能是有益的。
请注意，由于编译器不执行检查，所以汇编更难以编写，因此只有在您确实知道自己在做什么时，才应该将它用于复杂的事情。

```
pragma solidity ^0.4.16;

library VectorSum {
    // 此函数效率较低，因为优化器当前无法删除数组访问中的边界检查。
    function sumSolidity(uint[] _data) public view returns (uint o_sum) {
        for (uint i = 0; i < _data.length; ++i)
            o_sum += _data[i];
    }

    // 我们知道我们只能访问数组的边界，所以我们可以避免检查。
    // 需要将0x20添加到数组中，因为第一个插槽包含数组长度。
    function sumAsm(uint[] _data) public view returns (uint o_sum) {
        for (uint i = 0; i < _data.length; ++i) {
            assembly {
                o_sum := add(o_sum, mload(add(add(_data, 0x20), mul(i, 0x20))))
            }
        }
    }

    // 与上面相同，但在内联汇编中完成整个代码。
    function sumPureAsm(uint[] _data) public view returns (uint o_sum) {
        assembly {
           // 加载长度(前32个字节)
           let len := mload(_data)

           // 跳过长度字段。
           // 保持临时变量，以便它可以在原地增加。
           // 注意：增加_data会导致此组合块后不可用的_data变量
           let data := add(_data, 0x20)

           // 迭代，直到不符合约束。
           for
               { let end := add(data, len) }
               lt(data, end)
               { data := add(data, 0x20) }
           {
               o_sum := add(o_sum, mload(data))
           }
        }
    }
}
```

### 句法

Assembly会像Solidity一样解析注释，文字和标识符，因此您可以使用通常的`//`和`/* */`注释。
内联汇编由`assembly {...}`标记，并且在这些花括号内，可以使用以下内容(请参阅后面的章节以获取更多详细信息)

- 文字，即`0x123`，`42`或`abc`(最多32个字符的字符串)
- 操作码(以`指令样式`)，例如,`mload sload dup1 sstore`，查看下面的列表
- 功能风格的操作码，例如,添加(1，mlod(0))`标签，例如， ,`名称：`
- 变量声明，例如,`let x：= 7`，`let x：= add(y，3)`或者`let x`(空(0)的初始值被赋值)
- 标识符(标签或装配本地变量和外部元素，如果用作内联装配) ,`jump(name)`，`3 x add`
- 分配(以`指令风格`)，例如,`3 =：x`
- 功能风格的分配，例如,`x：= add(y，3)`
- 其中局部变量在范围内的块，例如， ,`{let x：= 3 {let y：= add(x，1)}}`

### 操作码

本文档不希望成为以太坊虚拟机的完整描述，但以下列表可用作其操作码的参考。

如果一个操作码需要参数(总是从栈顶开始)，它们会在括号中给出。
请注意，参数的顺序可以被看作是在非功能性风格中被颠倒(下面解释)。
标有`-`的操作码不会将物品推入堆栈，标有`*`的物品是特殊的，所有其他物品都只能将一个物品推入堆栈。

在下面，`mem[a ... b]`表示从位置`a`开始直到(不包括)位置`b`的存储器字节，并且`mem[p]`表示位置`p`处的存储内容,。

操作码`pushi`和`jumpdest`不能直接使用。

在语法中，操作码被表示为预定义的标识符。

| 函数 || 详情 |
|-|-|-|
|stop +              |-| 停止执行，与返回相同(0,0)
|add(x, y)           | | x + y
|sub(x, y)           | | x - y
|mul(x, y)           | | x * y
|div(x, y)           | | x / y
|sdiv(x, y)          | | x / y, 对于二进制补码中的有符号数
|mod(x, y)           | | x % y
|smod(x, y)          | | x % y, 对于二进制补码中的有符号数
|exp(x, y)           | | x to the power of y
|not(x)              | | ~x, x的每一位都是否定的
|lt(x, y)            | | 1 if x < y, 0 otherwise
|gt(x, y)            | | 1 if x > y, 0 除此以外
|slt(x, y)           | | 1 if x < y, 0 否则，对于二进制补码中的有符号数
|sgt(x, y)           | | 1 if x > y, 0 否则，对于二进制补码中的有符号数
|eq(x, y)            | | 1 if x == y, 0 otherwise
|iszero(x)           | | 1 if x == 0, 0 otherwise
|and(x, y)           | | 按位和x和y
|or(x, y)            | | 按位或x和y
|xor(x, y)           | | x和y的按位异或
|byte(n, x)          | | x的第n个字节，其中最高有效字节是第0字节
|addmod(x, y, m)     | | (x + y)％m与任意精确算术
|mulmod(x, y, m)     | | (x * y)％m与任意精确算术
|signextend(i, x)    | | 符号从最低有效位(i * 8 + 7)位开始计数
|keccak256(p, n)     | | keccak(mem[p...(p+n)))
|sha3(p, n)          | | keccak(mem[p...(p+n)))
|jump(label)         |-| 跳转到标签/代码位置
|jumpi(label, cond)  |-| 如果cond不为零，则跳转到标签
|pc                  | | 代码中的当前位置
|pop(x)              |-| 删除由x推送的元素
|dup1 ... dup16      | | 将ith堆栈槽复制到顶部(从顶部开始计数)
|swap1 ... swap16    |*| 在其下面交换最上面的和第i个栈槽
|mload(p)            | | mem[p..(p+32))
|mstore(p, v)        |-| mem[p..(p+32)) := v
|mstore8(p, v)       |-| mem [p]：= v＆0xff  - 仅修改单个字节
|sload(p)            | | storage[p]
|sstore(p, v)        |-| storage[p] := v
|msize               | | 内存大小，即最大访问内存索引
|gas                 | | 天然气仍然可以执行
|address             | | 当前合同/执行上下文的地址
|balance(a)          | | wei在地址a处平衡
|caller              | | 呼叫发送者(不包括委托呼叫)
|callvalue           | | wei与目前的电话一起发送
|calldataload(p)     | | 从位置p开始的呼叫数据(32字节)
|calldatasize        | | 通话数据的大小以字节为单位
|calldatacopy(t, f, s)   |-| 从位置f的calldata复制s个字节到位置t的mem
|codesize                | | 当前合同/执行上下文的代码大小
|codecopy(t, f, s)       |-| 从位置f的代码复制s字节到位置t的mem
|extcodesize(a)          | | 地址a处代码的大小
|extcodecopy(a, t, f, s) |-| 像代码复制(t，f，s)，但需要在地址a处进行编码
|returndatasize          | | 最近一次返回数据的大小
|returndatacopy(t,f, s)  |-| 将f位置的返回数据的字节复制到t位置的mem
|create(v, p, s)         | | 用代码mem [p ..(p + s))创建新的合同并发送v wei并返回新的地址
|create2(v, n, p, s)     | | 在地址keccak256(`<address>`。n。keccak256(mem [p ..(p + s)))上创建与代码mem [p ..(p + s))的新契约并发送v wei并返回新地址
|call(g, a, v, in, insize, out, outsize)     ||  在输入mem [in ..(in + insize))的地址a处调用合同，提供g gas和v wei以及输出区mem [out .. `|`(out + oversize))在错误时返回0(例如， ,1成功
|callcode(g, a, v, in, insize, out, outsize) ||  与呼叫相同，但只能使用a中的代码，否则将保留在当前合同的上下文中
|delegatecall(g, a, in, insize, out,outsize) ||  与呼叫码相同，但也保留“呼叫者”和“呼叫值”
|staticcall(g, a,in, insize, out, outsize)   ||  (g，a，0，in，insize，out，oversize)，但不允许状态修改
|return(p, s)        |-| 结束执行，返回数据mem [p ..(p + s))
|revert(p, s)        |-| 结束执行，恢复状态更改，返回数据mem [p ..(p + s))
|selfdestruct(a)     |-| 终止执行，摧毁当前合同并将资金发送给
|invalid             |-| 用无效指令结束执行
|log0(p, s)          |-| 没有主题和数据记录[p ..(p + s))
|log1(p, s, t1)      |-| 记录主题t1和数据mem [p ..(p + s))
|log2(p, s, t1, t2)  |-| 记录主题t1，t2和数据mem [p ..(p + s))
|log3(p, s, t1, t2, t3)     |-|  记录主题t1，t2和数据mem [p ..(p + s))
|log4(p, s, t1, t2,t3, t4)  |-|  记录主题t1，t2，t3，t4和数据mem [p ..(p + s))
|origin       || 交易发送
|gasprice     || 交易的天然气价格
|blockhash(b) || 块nr b的散列值 - 仅适用于不包括当前值的最后256个块
|coinbase     || 目前的采矿受益者
|timestamp    || 当前块的时间戳，以秒为单位
|number       || 当前程序段号
|difficulty   || 当前块的难度
|gaslimit     || 阻止当前块的气体限制

### 字面

您可以使用十进制或十六进制符号键入整数常量，并自动生成相应的`PUSHi`指令。
下面的代码创建代码，将2和3加起来得到5，然后计算按位和字符串`abc`。
字符串存储为左对齐，不能超过32个字节。

```
assembly { 2 3 add "abc" and }
```

### 功能样式

您可以在操作码之后键入操作码，它们将以字节码结尾。
例如，将`3`添加到内存中`0x80`位置的内容中

```
3 0x80 mload add 0x80 mstore
```

由于通常很难看到某些操作码的实际参数是什么，所以Solidity内联汇编还提供了一种`功能样式`表示法，其中相同的代码将如下编写

```
mstore(0x80, add(mload(0x80), 3))
```

函数式表达式不能在内部使用指令形式，即`1 2 mstore(0x80，add)`不是有效的程序集，它必须写为`mstore(0x80，add(2，1))`。
对于不带参数的操作码，括号可以省略。

请注意，参数的顺序在函数式中与指令式相反。
如果使用功能样式，第一个参数将会在堆栈顶部结束。

### 访问外部变量和函数

通过简单地使用它们的名称就可以访问固体变量和其他标识符。
对于内存变量，这会将地址而不是值推入堆栈。
存储变量不同：存储中的值可能不占用完整的存储槽，因此它们的`地址`由该槽中的槽和字节偏移量组成。
为了检索变量`x`所指向的槽，你使用`x_slot`来检索你使用`x_offset`的字节偏移量。

在作业中(见下文)，我们甚至可以使用本地Solidity变量来分配。

也可以访问内联汇编外部的函数：汇编将推入它们的入口标签(应用虚函数解析)。
可靠的调用语义是：

- 调用者推送返回标签arg1，arg2，...，argn
- 该呼叫将以ret1，ret2，...，retm返回

这个特性使用起来还是有点麻烦，因为在调用期间堆栈偏移量本质上发生了变化，因此对局部变量的引用将会出错。

```
pragma solidity ^0.4.11;

contract C {
    uint b;
    function f(uint x) public returns (uint r) {
        assembly {
            r := mul(x, sload(b_slot)) // ignore the offset, we know it is zero
        }
    }
}
```

### 标签

EVM组装中的另一个问题是`jump`和`jumpi`使用可以轻易改变的绝对地址。
Solidity inline assembly提供了标签，以便更容易地使用跳转。
请注意，标签是低级特征，只需使用汇编函数，循环，if和切换指令(参见下文)，就可以编写无标签的高效汇编。
以下代码计算斐波那契数列中的一个元素。

```
{
    let n := calldataload(4)
    let a := 1
    let b := a
    loop:
        jumpi(loopend, eq(n, 0))
        a add swap1
        n := sub(n, 1)
        jump(loop)
    loopend:
        mstore(0, a)
        return(0, 0x20)
}
```

请注意，只有汇编器知道当前堆栈高度时，才能自动访问堆栈变量。
如果跳转源和目标具有不同的堆栈高度，这将失效。
使用这种跳转仍然很好，但在这种情况下，您应该不会访问任何堆栈变量(即使是程序集变量)。

此外，堆栈高度分析器通过操作码(而不是根据控制流)来检查代码操作码，因此在下面的情况下，汇编器对标签为`2`的堆栈高度会产生错误的印象：

```
{
    let x := 8
    jump(two)
    one:
        // Here the stack height is 2 (because we pushed x and 7),
        // but the assembler thinks it is 1 because it reads
        // from top to bottom.
        // Accessing the stack variable x here will lead to errors.
        x := 9
        jump(three)
    two:
        7 // push something onto the stack
        jump(one)
    three:
}
```

### 声明装配本地变量

您可以使用`let`关键字来声明只在内联汇编中可见的变量，实际上只在当前的`{...}` - 块中可见。
会发生什么情况是`let`指令会创建一个为变量保留的新堆栈槽，并在到达块末尾时再次自动删除。
您需要为变量提供一个初始值，它可以是`0`，但它也可以是一个复杂的函数式表达式。

```
pragma solidity ^0.4.16;

contract C {
    function f(uint x) public view returns (uint b) {
        assembly {
            let v := add(x, 1)
            mstore(0x80, v)
            {
                let y := add(sload(v), 1)
                b := y
            } // y is "deallocated" here
            b := add(b, v)
        } // v is "deallocated" here
    }
}
```

### 分配

可以将汇编局部变量和局部变量赋值给函数。
请注意，当您分配指向内存或存储的变量时，只会更改指针而不是数据。

有两种作业：功能风格和教学风格。
对于函数式分配(`variable：= value`)，您需要在函数式表达式中提供一个值，该值可以导致恰好一个堆栈值和指令样式(`=：variable`)，该值只是,从栈顶取出。
对于这两种方式，冒号指向变量的名称。
通过用新值替换堆栈上的变量值来执行分配。

```
{
    let v := 0 // 函数式的赋值作为变量声明的一部分
    let g := add(v, 2)
    sload(10)
    =: v // 指令样式赋值，将sload(10)的结果放入v中
}
```

### If

if语句可以用于有条件地执行代码。
没有`其他`部分，如果您需要多种选择，请考虑使用`开关`(请参阅​​下文)。

```
{
    if eq(value, 0) { revert(0, 0) }
}
```

身体的花括号是必需的。

### Switch

你可以使用switch语句作为`if / else`的一个非常基本的版本。
它采用表达式的值并将其与几个常量进行比较。
采用与匹配常数对应的分支。
与某些编程语言的容易出错的行为相反，控制流不会从一种情况继续下去。
可以有一个后备或默认情况下称为`default`。

```
{
    let x := 0
    switch calldataload(4)
    case 0 {
        x := calldataload(0x24)
    }
    default {
        x := calldataload(0x44)
    }
    sstore(0, div(x, 2))
}
```

案件清单不需要大括号，但案件的主体确实需要它们。

### 循环

程序集支持一个简单的for-style循环。
For-style循环有一个包含初始化部分，条件和后迭代部分的头文件。
条件必须是功能式的表达，而另外两个是块。
如果初始化部分声明了任何变量，则这些变量的作用域被扩展到正文中(包括条件和后迭代部分)。

以下示例计算内存中区域的总和。

```
{
    let x := 0
    for { let i := 0 } lt(i, 0x100) { i := add(i, 0x20) } {
        x := add(x, mload(i))
    }
}
```

For循环也可以写成它们像循环一样的行为：
只需将初始化和后迭代部分留空即可。

```
{
    let x := 0
    let i := 0
    for { } lt(i, 0x100) { } {     // while(i < 0x100)
        x := add(x, mload(i))
        i := add(i, 0x20)
    }
}
```

### 功能

程序集允许定义低级函数。
这些从堆栈中取出它们的参数(并返回PC)，并将结果放入堆栈。
调用函数的方式与执行功能样式的操作码相同。

函数可以在任何地方定义，并且在声明它们的块中可见。
在函数内部，您不能访问在该函数之外定义的局部变量。
没有明确的`return`语句。

如果调用返回多个值的函数，则必须使用`a，b：= f(x)`或`let a，b：= f(x)`将它们分配给一个元组。

以下示例通过平方和乘法实现幂函数。

```
{
    function power(base, exponent) -> result {
        switch exponent
        case 0 { result := 1 }
        case 1 { result := base }
        default {
            result := power(mul(base, base), div(exponent, 2))
            switch mod(exponent, 2)
                case 1 { result := mul(base, result) }
        }
    }
}
```

### 要避免的事情

内联汇编可能具有相当高级的外观，但实际上它是非常低级的。
函数调用，循环，ifs和开关通过简单的重写规则进行转换，然后，汇编程序为您做的唯一事情就是重新安排函数式操作码，管理跳转标签，计算变量访问的堆栈高度并删除堆栈槽,装配本地变量到达块的末尾时。
特别是对于最后两种情况，重要的是要知道，汇编程序仅从上到下计数堆栈高度，而不一定遵循控制流程。
而且，swap等操作只会交换堆栈的内容，而不会交换变量的位置。

### 固体惯例

与EVM组装相比，Solidity知道窄于256位的类型，例如，`uint24`。
为了使它们更高效，大多数算术运算只将它们视为256位数字，而高位位只在必要时清除，即在它们被写入内存之前或执行比较之前,。
这意味着如果您从内联汇编中访问这样的变量，则可能必须首先手动清除更高位。

Solidity以一种非常简单的方式管理内存：内存中位置为0x40的地方有一个`空闲内存指针`。
如果你想分配内存，只需使用内存，并相应地更新指针。

Solidity中的内存数组中的元素总是占用32个字节的倍数(是的，这对于byte []来说甚至是正确的，但对于字节和字符串则不然)。
多维存储器阵列是指向存储器阵列的指针。
动态数组的长度存储在数组的第一个插槽中，然后仅跟随数组元素。

!!! Warning

    静态大小的内存数组没有长度字段，但它很快就会添加，以便在静态和动态大小的数组之间实现更好的可转换性，所以请不要依赖它。

## 独立装配

以上内联汇编语言描述的汇编语言也可以单独使用，实际上，计划是将其用作Solidity编译器的中间语言。
在这种形式下，它试图实现几个目标：

1. 写在其中的程序应该是可读的，即使代码是由Solidity的编译器生成的。
2. 从汇编到字节码的翻译应该包含尽可能少的`意外`。
3. 控制流应该易于检测，以帮助进行形式验证和优化。

为了实现第一个和最后一个目标，汇编提供了像`for`循环，`if`和`switch`语句和函数调用这样的高级结构。
应该可以编写不使用明确的`SWAP`，`DUP`，`JUMP`和`JUMPI`语句的汇编程序，因为前两个混淆了数据流和最后两个混淆控制流。
此外，形式为`mul(add(x，y)，7)`的函数语句优于纯操作码语句，如`7 yx add mul`，因为在第一种形式中，更容易看出哪个操作数用于,哪个操作码。

第二个目标是通过引入一个desugaring阶段来实现的，该阶段只能以非常规的方式移除较高级别的构造，并且仍然允许检查生成的低级汇编代码。
汇编程序执行的唯一非本地操作是用户定义标识符(函数，变量，...)的名称查找，它遵循非常简单和常规的范围规则以及从堆栈中清除局部变量。

作用域：声明的标识符(标签，变量，函数，程序集)仅在声明的块中可见(包括当前块中的嵌套块)。
跨功能边界访问局部变量是不合法的，即使它们在范围内。
阴影是不允许的。
局部变量在声明之前不能被访问，但标签，函数和程序集可以。
组件是特殊的块，用于例如,返回运行时代码或创建合同。
子组件中没有可见的外部组件标识符。

如果控制流经过块的末尾，则会插入与该块中声明的局部变量数匹配的流行指令。
无论何时引用局部变量，代码生成器都需要知道其当前在堆栈中的相对位置，因此需要跟踪当前所谓的堆栈高度。
由于所有局部变量都在块的末尾被删除，块前后的堆栈高度应该相同。
如果情况并非如此，则会发出警告。

为什么我们要使用更高层次的结构，比如`switch`，`for`和functions：

使用`switch`，`for`和函数，应该可以在不使用`jump`或`jumpi`的情况下编写复杂的代码。
这使得分析控制流程变得更加容易，从而可以改进形式验证和优化。

而且，如果允许手动跳转，计算堆栈高度相当复杂。
需要知道堆栈中所有局部变量的位置，否则在块结束时既不会自动引用局部变量也不会从堆栈中自动删除局部变量。
脱钩机构正确地将操作插入无法访问的块中，以便在没有持续控制流的跳转情况下正确调整堆栈高度。

例:

我们将按照Solidity的示例汇编去装配。
我们考虑以下Solidity程序的运行时字节码：

    pragma solidity ^0.4.16;

    contract C {
      function f(uint x) public pure returns (uint y) {
        y = 1;
        for (uint i = 0; i < x; i++)
          y = 2 * y;
      }
    }

将生成以下组件：

    {
      mstore(0x40, 0x60) // store the "free memory pointer"
      // function dispatcher
      switch div(calldataload(0), exp(2, 226))
      case 0xb3de648b {
        let (r) = f(calldataload(4))
        let ret := $allocate(0x20)
        mstore(ret, r)
        return(ret, 0x20)
      }
      default { revert(0, 0) }
      // memory allocator
      function $allocate(size) -> pos {
        pos := mload(0x40)
        mstore(0x40, add(pos, size))
      }
      // the contract function
      function f(x) -> y {
        y := 1
        for { let i := 0 } lt(i, x) { i := add(i, 1) } {
          y := mul(2, y)
        }
      }
    }

解除阶段后，它看起来如下：

    {
      mstore(0x40, 0x60)
      {
        let $0 := div(calldataload(0), exp(2, 226))
        jumpi($case1, eq($0, 0xb3de648b))
        jump($caseDefault)
        $case1:
        {
          // the function call - we put return label and arguments on the stack
          $ret1 calldataload(4) jump(f)
          // This is unreachable code.
          // Opcodes are added that mirror the effect of the function on the stack height: Arguments are removed and return values are introduced.
          pop pop
          let r := 0
          $ret1: // the actual return point
          $ret2 0x20 jump($allocate)
          pop pop let ret := 0
          $ret2:
          mstore(ret, r)
          return(ret, 0x20)
          // although it is useless, the jump is automatically inserted, since the desugaring process is a purely syntactic operation that does not analyze control-flow
          jump($endswitch)
        }
        $caseDefault:
        {
          revert(0, 0)
          jump($endswitch)
        }
        $endswitch:
      }
      jump($afterFunction)
      allocate:
      {
        // we jump over the unreachable code that introduces the function arguments
        jump($start)
        let $retpos := 0 let size := 0
        $start:
        // output variables live in the same scope as the arguments and is actually allocated.
        let pos := 0
        {
          pos := mload(0x40)
          mstore(0x40, add(pos, size))
        }
        // This code replaces the arguments by the return values and jumps back.
        swap1 pop swap1 jump
        // Again unreachable code that corrects stack height.
        0 0
      }
      f:
      {
        jump($start)
        let $retpos := 0 let x := 0
        $start:
        let y := 0
        {
          let i := 0
          $for_begin:
          jumpi($for_end, iszero(lt(i, x)))
          {
            y := mul(2, y)
          }
          $for_continue:
          { i := add(i, 1) }
          jump($for_begin)
          $for_end:
        } // Here, a pop instruction will be inserted for i
        swap1 pop swap1 jump
        0 0
      }
      $afterFunction:
      stop
    }

大会发生在四个阶段：

1. 解析
2. Desugaring(删除开关，用于和功能)
3. 操作码流生成
4. 字节码生成

我们将以伪正式的方式指定第一步到第三步。
更正式的规格将随之而来。

### 解析/语法

解析器的任务如下:

- 评论是常规的JavaScript / C ++评论，并且以与Whitespace相同的方式进行解释。
- 根据下面的语法将令牌流转换为AST
- 使用它们在其中定义的块注册标识符(注释到AST节点)并注意从哪个点开始，可以访问变量。

汇编词法分析器遵循由Solidity自己定义的那个。

空格用于分隔令牌，它由空格，制表符和换行符组成。
评论是常规的JavaScript / C ++评论，并且以与Whitespace相同的方式进行解释。

Grammar:

    AssemblyBlock = `{` AssemblyItem* `}`
    AssemblyItem =
        Identifier |
        AssemblyBlock |
        FunctionalAssemblyExpression |
        AssemblyLocalDefinition |
        FunctionalAssemblyAssignment |
        AssemblyAssignment |
        LabelDefinition |
        AssemblyIf |
        AssemblySwitch |
        AssemblyFunctionDefinition |
        AssemblyFor |
        `break` | `continue` |
        SubAssembly | `dataSize` `(` Identifier `)` |
        LinkerSymbol |
        `errorLabel` | `bytecodeSize` |
        NumberLiteral | StringLiteral | HexLiteral
    Identifier = [a-zA-Z_$] [a-zA-Z_0-9]*
    FunctionalAssemblyExpression = Identifier `(` ( AssemblyItem ( `,` AssemblyItem )* )? `)`
    AssemblyLocalDefinition = `let` IdentifierOrList `:=` FunctionalAssemblyExpression
    FunctionalAssemblyAssignment = IdentifierOrList `:=` FunctionalAssemblyExpression
    IdentifierOrList = Identifier | `(` IdentifierList `)`
    IdentifierList = Identifier ( `,` Identifier)*
    AssemblyAssignment = `=:` Identifier
    LabelDefinition = Identifier `:`
    AssemblyIf = `if` FunctionalAssemblyExpression AssemblyBlock
    AssemblySwitch = `switch` FunctionalAssemblyExpression AssemblyCase*
        ( `default` AssemblyBlock )?
    AssemblyCase = `case` FunctionalAssemblyExpression AssemblyBlock
    AssemblyFunctionDefinition = `function` Identifier `(` IdentifierList? `)`
        ( `->` `(` IdentifierList `)` )? AssemblyBlock
    AssemblyFor = `for` ( AssemblyBlock | FunctionalAssemblyExpression)
        FunctionalAssemblyExpression ( AssemblyBlock | FunctionalAssemblyExpression) AssemblyBlock
    SubAssembly = `assembly` Identifier AssemblyBlock
    LinkerSymbol = `linkerSymbol` `(` StringLiteral `)`
    NumberLiteral = HexNumber | DecimalNumber
    HexLiteral = `hex` (`"` ([0-9a-fA-F]{2})* `"` | ``` ([0-9a-fA-F]{2})* ```)
    StringLiteral = `"` ([^"rn] | `` .)* `"`
    HexNumber = `0x` [0-9a-fA-F]+
    DecimalNumber = [0-9]+

### 脱糖

AST转换删除，切换和函数结构。
结果仍然可以由同一个解析器解析，但它不会使用某些结构。
如果jumpdests被添加，只跳转到不继续，将添加有关堆栈内容的信息，除非未访问外部作用域的局部变量或堆栈高度与前一条指令相同。

伪代码:

    desugar item: AST -> AST =
    match item {
    AssemblyFunctionDefinition(`function` name `(` arg1, ..., argn `)` `->` ( `(` ret1, ..., retm `)` body) ->
      <name>:
      {
        jump($<name>_start)
        let $retPC := 0 let argn := 0 ... let arg1 := 0
        $<name>_start:
        let ret1 := 0 ... let retm := 0
        { desugar(body) }
        swap and pop items so that only ret1, ... retm, $retPC are left on the stack
        jump
        0 (1 + n times) to compensate removal of arg1, ..., argn and $retPC
      }
    AssemblyFor(`for` { init } condition post body) ->
      {
        init // cannot be its own block because we want variable scope to extend into the body
        // find I such that there are no labels $forI_*
        $forI_begin:
        jumpi($forI_end, iszero(condition))
        { body }
        $forI_continue:
        { post }
        jump($forI_begin)
        $forI_end:
      }
    `break` ->
      {
        // find nearest enclosing scope with label $forI_end
        pop all local variables that are defined at the current point
        but not at $forI_end
        jump($forI_end)
        0 (as many as variables were removed above)
      }
    `continue` ->
      {
        // find nearest enclosing scope with label $forI_continue
        pop all local variables that are defined at the current point
        but not at $forI_continue
        jump($forI_continue)
        0 (as many as variables were removed above)
      }
    AssemblySwitch(switch condition cases ( default: defaultBlock )? ) ->
      {
        // find I such that there is no $switchI* label or variable
        let $switchI_value := condition
        for each of cases match {
          case val: -> jumpi($switchI_caseJ, eq($switchI_value, val))
        }
        if default block present: ->
          { defaultBlock jump($switchI_end) }
        for each of cases match {
          case val: { body } -> $switchI_caseJ: { body jump($switchI_end) }
        }
        $switchI_end:
      }
    FunctionalAssemblyExpression( identifier(arg1, arg2, ..., argn) ) ->
      {
        if identifier is function <name> with n args and m ret values ->
          {
            // find I such that $funcallI_* does not exist
            $funcallI_return argn  ... arg2 arg1 jump(<name>)
            pop (n + 1 times)
            if the current context is `let (id1, ..., idm) := f(...)` ->
              let id1 := 0 ... let idm := 0
              $funcallI_return:
            else ->
              0 (m times)
              $funcallI_return:
              turn the functional expression that leads to the function call
              into a statement stream
          }
        else -> desugar(children of node)
      }
    default node ->
      desugar(children of node)
    }

### 操作码流生成

在操作码流生成期间，我们会跟踪计数器中的当前堆栈高度，以便可以通过名称访问堆栈变量。
每个修改堆栈的操作码以及每个用堆栈调整注释的标签都会修改堆栈高度。
每次引入一个新的局部变量时，它都会与当前堆栈高度一起注册。
如果访问变量(复制其值或赋值)，根据引入变量时当前堆栈高度和堆栈高度之间的差异选择适当的`DUP`或`SWAP`指令。

伪代码:

    codegen item: AST -> opcode_stream =
    match item {
    AssemblyBlock({ items }) ->
      join(codegen(item) for item in items)
      if last generated opcode has continuing control flow:
        POP for all local variables registered at the block (including variables
        introduced by labels)
        warn if the stack height at this point is not the same as at the start of the block
    Identifier(id) ->
      lookup id in the syntactic stack of blocks
      match type of id
        Local Variable ->
          DUPi where i = 1 + stack_height - stack_height_of_identifier(id)
        Label ->
          // reference to be resolved during bytecode generation
          PUSH<bytecode position of label>
        SubAssembly ->
          PUSH<bytecode position of subassembly data>
    FunctionalAssemblyExpression(id ( arguments ) ) ->
      join(codegen(arg) for arg in arguments.reversed())
      id (which has to be an opcode, might be a function name later)
    AssemblyLocalDefinition(let (id1, ..., idn) := expr) ->
      register identifiers id1, ..., idn as locals in current block at current stack height
      codegen(expr) - assert that expr returns n items to the stack
    FunctionalAssemblyAssignment((id1, ..., idn) := expr) ->
      lookup id1, ..., idn in the syntactic stack of blocks, assert that they are variables
      codegen(expr)
      for j = n, ..., i:
      SWAPi where i = 1 + stack_height - stack_height_of_identifier(idj)
      POP
    AssemblyAssignment(=: id) ->
      look up id in the syntactic stack of blocks, assert that it is a variable
      SWAPi where i = 1 + stack_height - stack_height_of_identifier(id)
      POP
    LabelDefinition(name:) ->
      JUMPDEST
    NumberLiteral(num) ->
      PUSH<num interpreted as decimal and right-aligned>
    HexLiteral(lit) ->
      PUSH32<lit interpreted as hex and left-aligned>
    StringLiteral(lit) ->
      PUSH32<lit utf-8 encoded and left-aligned>
    SubAssembly(assembly <name> block) ->
      append codegen(block) at the end of the code
    dataSize(<name>) ->
      assert that <name> is a subassembly ->
      PUSH32<size of code generated from subassembly <name>>
    linkerSymbol(<lit>) ->
      PUSH32<zeros> and append position to linker table
    }
