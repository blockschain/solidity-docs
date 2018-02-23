# 类型

Solidity是一种静态类型语言，这意味着每个变量(状态和本地)的类型需要在编译时指定(或者至少已知 - 参见下面的[type-deduction]())。
Solidity提供了几种可以组合形成复杂类型的基本类型。

另外，类型可以在包含运算符的表达式中相互交互。
有关各种运算符的快速参考，请参见[order]()。

## 值类型

以下类型也称为值类型，因为这些类型的变量总是按值传递，即当它们用作函数参数或赋值时，它们总是被复制。

### 布尔

`bool`: 可用值是常量`true`和`false`。

运算符:

- `!` (逻辑否)
- `&&`(逻辑和)
- `||`(逻辑或)
- `==`(等)
- `!=`(不等)

运算符`||`和`&&`遵从常见的短路规则。这意味着在表达式`f(x) || g(y)`，如果`f(x)`为`true`，`g(y)`即使可能有副作用也不会被计算。

### 整型

`int` / `uint`：各种大小的有符号和无符号整数。
关键词`uint8`到`uint256`以`8`(无符号8到256位)和`int8`到`int256`为步长。
`uint`和`int`分别是`uint256`和`int256`的别名。

运算符:

- 比较：`<=`，`<`，`==`，`！=`，`> =`，`>`(结果为`bool`)
- 位运算符：`＆`，`|`，`^`(按位异或)，`~`(按位否)
- 算术运算符：`+`, `-`, unary `-`, unary `+`, `*`, `/`, `%`(余), `**`(幂), `<<`(左移), `>>`(右移)

除法总是截断(它只是编译为EVM的`DIV`操作码)，但如果两个操作符都是[文字](https://solidity.readthedocs.io/en/develop/types.html#rational-literals)(或文字表达式)，它就不会截断。

用零和模数除零引发运行时异常。
移位操作的结果是左操作数的类型。
表达式`x << y`相当于`x * 2 ** y`，`x >> y`相当于`x / 2 ** y`。
这意味着移动负数符号会延长。
按负数移动会引发运行时异常。

!!! warning

    由有符号整数类型的负值移位产生的结果与其他编程语言产生的结果不同
    在Solidity中，将右侧的地图向右移动，因此移位后的负值将舍入为零(截断)。
    在其他编程语言中，负值的右移就像四舍五入的分割(朝向负无穷)。

### 定点号

!!! warning

    固定点数量尚未完全支持。
    它们可以被声明，但不能被分配给或从中分配。

`fixed` / `ufixed`: 各种大小的有符号和无符号定点数。
关键词`ufixedMxN`和`fixedMxN`，其中`M`表示类型所占的位数，`N`表示可用的小数点数。
`M`必须可以被8整除并且从8到256位。
`N`必须在0到80之间，包括0和80。
`ufixed`和`fixed`分别是`ufixed128x19`和`fixed128x19`的别名。

运算符:

- 比较：`<=`，`<`，`==`，`！=`，`> =`，`>`(结果`bool`)
- 算术运算符：`+`，`-`，unary `-`，unary `+`，`*`，`/`，`％`(余数)

!!! Note

    浮点数(在许多语言中浮点和双精度，更准确地说IEEE 754数字)和定点数之间的主要区别在于整数和小数部分(小数点后的部分)使用的位数在前者中是灵活的，而在后者中严格定义
    一般来说，在浮点数中，几乎整个空间都用来表示数字，而只有少量的数字定义了小数点的位置。

### 地址

`address`: 保存20个字节的值(以太坊地址的大小)。地址类型也有成员，并作为所有合约的基础。

运算符:

- `<=`, `<`, `==`, `!=`, `>=` 和 `>`

!!! Note

    从版本0.5.0开始，合约不会从地址类型派生，但仍可以明确地转换为地址。

#### 地址成员

- `balance` 和 `transfer`

有关快速参考，请参阅[地址相关](https://solidity.readthedocs.io/en/develop/units-and-global-variables.html#address-related)。

可以使用属性`balance`查询地址的余额，并使用`transfer`函数将以太网(以wei为单位)发送到一个地址：

```js
    address x = 0x123;
    address myAddress = this;
    if(x.balance < 10 && myAddress.balance >= 10) x.transfer(10);
```

!!! Note

    如果`x`是合约地址，则其代码(更具体地说：它的后备功能，如果存在的话)将与`transfer`调用(这是EVM的一项功能，无法阻止)一起执行。
    如果运行时燃料耗尽或以任何方式失败, 以太汇款将被退回，目前的合约将停止，并抛出异常.

- `send`

Send是`transfer`的低级副本。
如果执行失败，当前合约不会停止并产生异常，但是`send`将返回`false`。

!!! warning

    使用`send`时存在一些危险：如果调用堆栈深度为1024(这可以始终由调用者强制)，则传输失败，如果收件人燃料耗尽，则传输也会失败。
    所以为了安全的以太传输， 总是检查`send`的返回值， 使用`transfer`更好: 使用收款人提款的模式.

- `call`, `callcode` and `delegatecall`

此外, 与不符合ABI的合约进行接口, 提供了函数`call`，它可以接受任意类型的任意数量的参数。
这些参数被填充到32个字节并连接。
一个例外是第一个参数被编码为正好四个字节的情况。
在这种情况下，它没有被填充以允许在这里使用功能签名。

```js
    address nameReg = 0x72ba7d8e73fe8eb666ea66babc8116a41bfb10e2;
    nameReg.call("register", "MyName");
    nameReg.call(bytes4(keccak256("fun(uint256)")), a);
```

`call`返回一个布尔值，指示被调用的函数是否终止(`true`)或导致EVM异常(`false`)。
无法访问返回的实际数据(为此，我们需要事先知道编码和大小).

可以用`.gas()`修饰符调整供给的气体：

    namReg.call.gas(1000000)("register", "MyName");

同样，所提供的以太值也可以被控制：

```js
    nameReg.call.value(1 ether)("register", "MyName");
```

最后，这些修饰符可以结合使用。
他们的顺序无关紧要：

```js
    nameReg.call.gas(1000000).value(1 ether)("register", "MyName");
```

!!! Note

    在重载函数上使用`gas`或`value`修饰符还不可能。

    解决方法是引入`gas`和`value`的特例，并重新检查它们是否存在于重载分辨率点。

以类似的方式，可以使用函数`delegatecall`：不同之处在于只使用给定地址的代码，所有其他方面(存储，余额...)取自当前合约。
`delegatecall`的目的是使用存储在另一个合约中的库代码。
用户必须确保两个合约中的存储布局适合使用委托呼叫。
在家园之前，只有一个名为`callcode`的有限变体可用，它不能访问原始的`msg.sender`和`msg.value`值。

所有三个函数`call`，`delegatecall`和`callcode`都是非常低级的函数，只能作为*最后的手段*，因为它们会破坏Solidity的类型安全性。

`.gas()`选项可用于所有三种方法，而`.value()`选项不支持`delegatecall`。

!!! Note

    所有合约都继承地址成员，所以可以使用`this.balance`查询当前合约的余额。

!!! Note

    `callcode`的使用是不鼓励的，将来会被删除。

!!! warning

    所有这些功能都是低级功能，应小心使用。
    特别, 任何未知的合约可能是恶意的，如果你调用它, 您将控制权移交给该合约，而该合约又可以回调您的合约, 因此在呼叫返回时准备好更改状态变量.

### 固定大小的字节数组

`bytes1`, `bytes2`, `bytes3`, ..., `bytes32`.
`byte`是`bytes1`的别名。

运算符:

- 比较: `<=`, `<`, `==`, `!=`, `>=`, `>`(评估为 `bool`)
- 位运算符: `&`, `|`, `^`(按位异或), `~`(按位否), `<<`(左移), `>>`(右移)
- 索引访问: 如果`x`的类型是`bytesI`，那么`0 <= k <I`的`x [k]`返回第k个字节(只读)。

移位运算符使用任何整数类型作为右操作数(但会返回左操作数的类型)，这表示要移位的位数。
按负数移动会导致运行时异常。

成员:

- `.length`产生字节数组的固定长度(只读)。

!!! Note

    可以使用一个字节数组作为`byte[]`，但是当传入调用时，它会浪费很多空间，每个元素占用31个字节。
    最好使用`bytes`。

### 动态大小的字节数组

`bytes`: 动态大小的字节数组，请参见[阵列](https://solidity.readthedocs.io/en/develop/types.html#arrays)。 不是一种值型！

`string`: 动态大小的UTF-8编码字符串，请参见[阵列](https://solidity.readthedocs.io/en/develop/types.html#arrays)。 不是一种值型！

根据经验，对任意长度的原始字节数据使用`bytes`，对任意长度的字符串(UTF-8)数据使用`string`。
如果你可以限制长度到一定数量的字节，总是使用`bytes1`到`bytes32`中的一个，因为它们便宜得多。

### 地址文字`address`

通过地址校验和测试的十六进制文字, 例如`0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF`是`address`类型。
长度在39到41位之间且未通过校验和测试的十六进制文字会产生警告，并被视为常规有理数字文字。

!!! Note

    混合大小写地址校验和格式在[EIP-55](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md)中定义.

### 理性和整数文字

整数文字是由0-9范围内的一系列数字组成的。
它们被解释为小数。
例如，`69`意味着六十九个。
Octal文字不存在于Solidity中，前导零是无效的。

小数部分文字由一个`.`形成，一边至少有一个数字。
例子包括`1.`，`.1`和`1.3`。

科学记数法也支持，其中基数可以有分数，而指数则不可以。
例子包括2e10，-2e10，2e-10，2.5e1。

数字文字表达式保持任意精度，直到它们被转换为非文字类型(即通过将它们与非文字表达式一起使用)。
这意味着计算不会溢出，并且分区不会在数字文字表达式中截断。

例如，`(2 ** 800 + 1) -  2 ** 800`的结果是常量`1`(类型为`uint8`)，尽管中间结果甚至不适合机器字的大小。
此外，`.5 * 8`产生整数`4`(尽管在它们之间使用了非整数)。

只要操作数是整数，任何可以应用于整数的运算符也可以应用于数字文字表达式。
如果两者中的任何一个都是小数，则位操作是不允许的，并且如果指数是分数的(因为这可能导致非有理数)，指数是不允许的。

!!! Note

    对于每个有理数，Solidity都有一个数字字面类型。
    整数文字和有理数字文字属于数字文字类型。
    此外，所有数字文字表达式(即仅包含数字文字和运算符的表达式)属于数字文字类型。
    因此，数字文字表达式`1 + 2`和`2 + 1`对于有理数3都属于相同的数字文字类型。

!!! warning

    用于在早期版本中截断的整数字面积的划分，但现在将转换为有理数，即`5/2`不等于`2`，而是等于`2.5`。

!!! Note

    数字文字表达式只要与非文字表达式一起使用，就会转换为非文字类型。
    尽管我们知道在下面的例子中赋值给`b`的表达式的值是一个整数，但部分表达式`2.5 + a`没有检查类型，所以代码不会编译

uint128 a = 1;
uint128 b = 2.5 + a + 0.5;

@nosy check here

### 字符串文字

字符串文字用双引号或单引号("foo"或'bar')编写。
它们并不意味着像C中那样跟随零; "foo"代表三个字节而不是四个。
与整数文字一样，它们的类型可能会有所不同，但如果它们适合`字节`和`字符串`，它们可以隐式转换为`bytes1`，...，`bytes32`。

字符串文字支持转义字符，如`n`，`xNN`和`uNNNN`。
`xNN`接受一个十六进制值并插入相应的字节，而`uNNNN`接受一个Unicode代码点并插入一个UTF-8序列。

### 十六进制文字

十六进制文字前缀为关键字`hex`，并用双引号或单引号(`hex`001122FF``)括起来。
它们的内容必须是十六进制字符串，它们的值将是这些值的二进制表示。

Hexademical Literals的行为与String Literals类似，并具有相同的可转换性限制。

### 枚举

枚举是在Solidity中创建用户定义类型的一种方法。
它们可以显式转换为所有整数类型，但是不允许隐式转换。
显式转换检查运行时的值范围，失败会导致异常。
枚举需要至少一个成员。

```js
    pragma solidity ^0.4.16;

    contract test {
        enum ActionChoices { GoLeft, GoRight, GoStraight, SitStill }
        ActionChoices choice;
        ActionChoices constant defaultChoice = ActionChoices.GoStraight;

        function setGoStraight() public {
            choice = ActionChoices.GoStraight;
        }

        // Since enum types are not part of the ABI, the signature of "getChoice"
        // will automatically be changed to "getChoice() returns(uint8)"
        // for all matters external to Solidity.
        // The integer type used is just
        // large enough to hold all enum values, i.e. if you have more values,
        // `uint16` will be used and so on.
        function getChoice() public view returns(ActionChoices) {
            return choice;
        }

        function getDefaultChoice() public pure returns(uint) {
            return uint(defaultChoice);
        }
    }
```

### 函数类型

函数类型是函数的类型。
函数类型的变量可以从函数中分配，而函数类型的函数参数可以用于将函数传递给函数调用并从函数调用返回函数。
函数类型有两种口味 -  *内部*和*外部*函数：

内部函数只能在当前合约内(更具体地说，在当前代码单元内部，它还包含内部库函数和继承函数)内部调用，因为它们不能在当前合约的上下文之外执行。
调用内部函数是通过跳转到其入口标签来实现的，就像在内部调用当前合约的函数一样。

外部函数由一个地址和一个函数签名组成，它们可以通过外部函数调用传递并返回。

函数类型的标注如下：

```js
function(<parameter types>) {internal|external} [pure|constant|view|payable] [returns(<return types>)]
```

与参数类型不同，返回类型不能为空 - 如果函数类型不返回任何内容，则必须省略整个`returns(<返回类型>)`部分。

默认情况下，函数类型是内部的，所以`internal`关键字可以省略。
相比之下，契约函数本身在默认情况下是公共的，只有当用作类型的名称时，默认是内部的。

有两种方法可以访问当前合约中的函数：直接使用其名称，`f`或使用`this.f`。
前者将产生内部功能，后者则具有外部功能。

如果函数类型变量未初始化，调用它将导致异常。
如果你在使用`delete`之后调用一个函数，也会发生同样的情况。

如果外部函数类型在Solidity上下文之外使用，则它们被视为`函数`类型，它将地址和函数标识符一起编码成单个`bytes24`类型。

请注意，当前合约的公共职能既可以用作内部函数，也可以用作外部函数。
要使用`f`作为内部函数，只要使用`f`，如果你想使用它的外部形式，可以使用`this.f`。

此外，公共(或外部)函数还有一个名为`selector`的特殊成员，它返回[ABI函数选择器<abi_function_selector>]()：

```js
    pragma solidity ^0.4.16;

    contract Selector {
      function f() public view returns(bytes4) {
        return this.f.selector;
      }
    }
```

显示如何使用内部函数类型的示例：

```js
    pragma solidity ^0.4.16;

    library ArrayUtils {
      // internal functions can be used in internal library functions because
      // they will be part of the same code context
      function map(uint[] memory self, function(uint) pure returns(uint) f)
        internal
        pure
        returns(uint[] memory r)
      {
        r = new uint[](self.length);
        for(uint i = 0; i < self.length; i++) {
          r[i] = f(self[i]);
        }
      }
      function reduce(
        uint[] memory self,
        function(uint, uint) pure returns(uint) f
      )
        internal
        pure
        returns(uint r)
      {
        r = self[0];
        for(uint i = 1; i < self.length; i++) {
          r = f(r, self[i]);
        }
      }
      function range(uint length) internal pure returns(uint[] memory r) {
        r = new uint[](length);
        for(uint i = 0; i < r.length; i++) {
          r[i] = i;
        }
      }
    }

    contract Pyramid {
      using ArrayUtils for *;
      function pyramid(uint l) public pure returns(uint) {
        return ArrayUtils.range(l).map(square).reduce(sum);
      }
      function square(uint x) internal pure returns(uint) {
        return x * x;
      }
      function sum(uint x, uint y) internal pure returns(uint) {
        return x + y;
      }
    }
```

另一个使用外部函数类型的例子：

```js
    pragma solidity ^0.4.11;

    contract Oracle {
      struct Request {
        bytes data;
        function(bytes memory) external callback;
      }
      Request[] requests;
      event NewRequest(uint);
      function query(bytes data, function(bytes memory) external callback) public {
        requests.push(Request(data, callback));
        NewRequest(requests.length - 1);
      }
      function reply(uint requestID, bytes response) public {
        // Here goes the check that the reply comes from a trusted source
        requests[requestID].callback(response);
      }
    }

    contract OracleUser {
      Oracle constant oracle = Oracle(0x1234567); // known contract
      function buySomething() {
        oracle.query("USD", this.oracleResponse);
      }
      function oracleResponse(bytes response) public {
        require(msg.sender == address(oracle));
        // Use the data
      }
    }
```

!!! Note

    Lambda或内联函数已计划但尚未支持。

## 参考类型

复杂类型，即不总是适合256位的类型必须比我们已经看到的值类型更仔细地处理。
由于复制它们可能非常昂贵，我们必须考虑是否要将它们存储在**存储器**(不是持久存储器)或**存储**(其中保存状态变量)中。

### 数据位置

由于复制它们可能非常昂贵，我们必须考虑是否要将它们存储在**存储器**(不是持久存储器)或**存储**(其中保存状态变量)中。
根据上下文，总是有一个默认值，但是可以通过在类型中附加`storage`或`memory`来覆盖它。
函数参数(包括返回参数)的缺省值是`memory`，局部变量的默认值是`storage`，显然，状态变量的位置被强制为`storage`。

还有第三个数据位置`calldata`，它是存储函数参数的不可修改的非持久性区域。
外部函数的函数参数(而不是返回参数)被强制为`calldata`，其行为与`memory`类似。

数据位置非常重要，因为它们改变了作业的行为方式：
存储和内存之间的分配以及状态变量(甚至来自其他状态变量)之间的分配始终会创建一个独立副本。
虽然本地存储变量的赋值只能指定一个引用，并且该引用始终指向状态变量，即使后者在此期间发生更改。
另一方面，从内存存储引用类型到另一个内存存储引用类型的分配不会创建副本。

```js
    pragma solidity ^0.4.0;

    contract C {
        uint[] x; // the data location of x is storage

        // the data location of memoryArray is memory
        function f(uint[] memoryArray) public {
            x = memoryArray; // works, copies the whole array to storage
            var y = x; // works, assigns a pointer, data location of y is storage
            y[7]; // fine, returns the 8th element
            y.length = 2; // fine, modifies x through y
            delete x; // fine, clears the array, also modifies y
            // The following does not work; it would need to create a new temporary /
            // unnamed array in storage, but storage is "statically" allocated:
            // y = memoryArray;
            // This does not work either, since it would "reset" the pointer, but there
            // is no sensible location it could point to.
            // delete y;
            g(x); // calls g, handing over a reference to x
            h(x); // calls h and creates an independent, temporary copy in memory
        }

        function g(uint[] storage storageArray) internal {}
        function h(uint[] memoryArray) public {}
    }
```

#### 概要

强制数据位置：

- 外部函数的参数(不返回)：calldata
- 状态变量：存储

默认数据位置：

- 函数的参数(也返回)：内存
- 所有其他本地变量：存储

### 数组

数组可以有编译时固定的大小，也可以是动态的。
对于存储阵列，元素类型可以是任意的(即其他数组，映射或结构)。
对于内存数组，它不能是一个映射，如果它是一个公共可见函数的参数，则它必须是ABI类型。

一个固定大小的数组`k`和元素类型`T`被写为`T [k]`，一个动态大小的数组作为`T []`。
例如，一个由5个动态数组组成的`uint`数组就是`uint [] [5]`(注意与其他一些语言相比，该记号是反转的)。
要访问第三个动态数组中的第二个uint，可以使用`x [2] [1]`(索引是基于零的，并且访问以与声明相反的方式工作，即`x [2]`刮掉一个级别,在右边的类型中)。

`bytes`和`string`类型的变量是特殊数组。
`bytes`类似于`byte []`，但是它紧紧包装在calldata中。
`string`等于`bytes`，但不允许长度或索引访问(现在)。

所以`byte`应该总是比`byte []`更受欢迎，因为它比较便宜。

!!! Note

    如果你想访问字符串`s`的字节表示，可以使用`bytes(s).length` /`bytes(s)[7] =`x`;`。
    请记住，您正在访问UTF-8表示的低级字节，而不是单个字符！

可以将数组标记为`public`并使Solidity创建一个[getter <visibility-and-getters>]()。
数字索引将成为getter的必需参数。

#### 分配内存数组

在内存中创建具有可变长度的数组可以使用`new`关键字完成。
与存储阵列相反，通过赋予`.length`成员来调整内存数组的大小是不可能的。

```js
    pragma solidity ^0.4.16;

    contract C {
        function f(uint len) public pure {
            uint[] memory a = new uint[](7);
            bytes memory b = new bytes(len);
            // 这里我们有a.length == 7和b.length == len
            a[6] = 8;
        }
    }
```

#### 数组文字/行内数组

数组文字是作为表达式写入的数组，并且不会立即分配给变量。

```js
    pragma solidity ^0.4.16;

    contract C {
        function f() public pure {
            g([uint(1), 2, 3]);
        }
        function g(uint[3] _data) public pure {
            // ...
        }
    }
```

数组文本的类型是固定大小的存储器数组，其基数类型是给定元素的常见类型。
`[1,2,3]`的类型是`uint8 [3]内存`，因为这些常量中的每一个的类型都是`uint8`。
因此，有必要将上例中的第一个元素转换为uint。
请注意，目前固定大小的存储器阵列不能分配给动态大小的存储器阵列，即以下情况是不可能的：

```js
    // 这不会编译。
    pragma solidity ^0.4.0;

    contract C {
        function f() public {
            // 下一行创建类型错误，因为uint [3]内存不能转换为uint []内存。
            uint[] x = [uint(1), 3, 4];
        }
    }
```

计划在将来删除此限制，但由于数组在ABI中的传递方式，目前会产生一些复杂性。

#### 成员

**length**:

数组有一个`长度`成员来保存其元素数量。
动态数组可以通过改变`.length`成员在存储器中(不在内存中)调整大小。
尝试访问当前长度以外的元素时，不会自动发生。
存储器阵列的大小一旦被创建就是固定的(但是动态的，即它可以依赖于运行时参数)。

**push**:

动态存储数组和`bytes`(而不是`string`)有一个叫做`push`的成员函数，可以用来追加数组末尾的元素。
该函数返回新的长度。

!!! warning

    尚不可能在外部函数中使用数组的数组。

!!! warning

    由于EVM的限制，无法从外部函数调用返回动态内容。
    合约C {函数f()返回(uint []){...}}`中的函数`f`将返回从web3.js中调用的东西，但如果从Solidity调用则返回。

    现在唯一的解决方法是使用大型静态大小的数组。

```js
    pragma solidity ^0.4.16;

    contract ArrayContract {
        uint[2**20] m_aLotOfIntegers;
        // Note that the following is not a pair of dynamic arrays but a
        // dynamic array of pairs(i.e. of fixed size arrays of length two).
        bool[2][] m_pairsOfFlags;
        // newPairs is stored in memory - the default for function arguments

        function setAllFlagPairs(bool[2][] newPairs) public {
            // assignment to a storage array replaces the complete array
            m_pairsOfFlags = newPairs;
        }

        function setFlagPair(uint index, bool flagA, bool flagB) public {
            // access to a non-existing index will throw an exception
            m_pairsOfFlags[index][0] = flagA;
            m_pairsOfFlags[index][1] = flagB;
        }

        function changeFlagArraySize(uint newSize) public {
            // if the new size is smaller, removed array elements will be cleared
            m_pairsOfFlags.length = newSize;
        }

        function clear() public {
            // these clear the arrays completely
            delete m_pairsOfFlags;
            delete m_aLotOfIntegers;
            // identical effect here
            m_pairsOfFlags.length = 0;
        }

        bytes m_byteData;

        function byteArrays(bytes data) public {
            // byte arrays("bytes") are different as they are stored without padding,
            // but can be treated identical to "uint8[]"
            m_byteData = data;
            m_byteData.length += 7;
            m_byteData[3] = byte(8);
            delete m_byteData[2];
        }

        function addFlag(bool[2] flag) public returns(uint) {
            return m_pairsOfFlags.push(flag);
        }

        function createMemoryArray(uint size) public pure returns(bytes) {
            // Dynamic memory arrays are created using `new`:
            uint[2][] memory arrayOfPairs = new uint[2][](size);
            // Create a dynamic byte array:
            bytes memory b = new bytes(200);
            for(uint i = 0; i < b.length; i++)
                b[i] = byte(i);
            return b;
        }
    }
```

### 结构

Solidity提供了一种以结构形式定义新类型的方法，如以下示例所示：

```js
    pragma solidity ^0.4.11;

    contract CrowdFunding {
        // Defines a new type with two fields.
        struct Funder {
            address addr;
            uint amount;
        }

        struct Campaign {
            address beneficiary;
            uint fundingGoal;
            uint numFunders;
            uint amount;
            mapping(uint => Funder) funders;
        }

        uint numCampaigns;
        mapping(uint => Campaign) campaigns;

        function newCampaign(address beneficiary, uint goal) public returns(uint campaignID) {
            campaignID = numCampaigns++; // campaignID is return variable
            // Creates new struct and saves in storage.We leave out the mapping type.
            campaigns[campaignID] = Campaign(beneficiary, goal, 0, 0);
        }

        function contribute(uint campaignID) public payable {
            Campaign storage c = campaigns[campaignID];
            // Creates a new temporary memory struct, initialised with the given values
            // and copies it over to storage.
            // Note that you can also use Funder(msg.sender, msg.value) to initialise.
            c.funders[c.numFunders++] = Funder({addr: msg.sender, amount: msg.value});
            c.amount += msg.value;
        }

        function checkGoalReached(uint campaignID) public returns(bool reached) {
            Campaign storage c = campaigns[campaignID];
            if(c.amount < c.fundingGoal)
                return false;
            uint amount = c.amount;
            c.amount = 0;
            c.beneficiary.transfer(amount);
            return true;
        }
    }
```

合约没有提供众筹合约的全部功能，但它包含了理解结构所必需的基本概念。
结构类型可以用在映射和数组中，它们本身可以包含映射和数组。

尽管结构本身可以是映射成员的值类型，但结构不可能包含它自己类型的成员。
这个限制是必要的，因为结构的大小必须是有限的。

请注意，在所有函数中，结构类型被分配给(缺省存储数据位置的)局部变量。
这不会复制该结构，而只会存储一个引用，以便分配给本地变量的成员实际写入该状态。

当然，你也可以直接访问结构体的成员，而不必将它分配给局部变量，就像`campaign [campaignID] .amount = 0`一样。

映射

映射类型被声明为`映射(_KeyType => _ValueType)`。
这里`_KeyType`几乎可以是任何类型，除了映射，动态调整大小的数组，合约，枚举和结构。
`_ValueType`实际上可以是任何类型，包括映射。

映射可以看作是[哈希表](https://en.wikipedia.org/wiki/Hash_table)，它们被虚拟初始化，这样每个可能的键都存在并映射到一个字节表示全为零的值：一个类型,[默认值<默认值>]()。
但是，相似性在此处结束：关键数据实际上并不存储在映射中，只有其用于查找值的`keccak256`哈希值。

因此，映射没有长度或`设置`键或值的概念。

映射只能用于状态变量(或作为内部函数中的存储引用类型)。

可以将映射标记为public，并使Solidity创建一个[getter <visibility-and-getters>]()。
`_KeyType`将成为getter的必需参数，它将返回`_ValueType`。

`_ValueType`也可以是一个映射。
getter将递归地为每个`_KeyType`使用一个参数。

```js
    pragma solidity ^0.4.0;

    contract MappingExample {
        mapping(address => uint) public balances;

        function update(uint newBalance) public {
            balances[msg.sender] = newBalance;
        }
    }

    contract MappingUser {
        function f() public returns(uint) {
            MappingExample m = new MappingExample();
            m.update(100);
            return m.balances(this);
        }
    }
```

!!! Note

    映射不可迭代，但可以在其上实现数据结构。
    有关示例，请参见[可迭代映射](https://github.com/ethereum/dapp-bin/blob/master/library/iterable_mapping.sol).

## 涉及LValues的操作符

如果`a`是一个LValue(即一个变量或可以分配的东西)，则下列运算符可用作简写：

`a + = e`相当于`a = a + e`。
相应地定义了运算符` -  =`，`* =`，`/ =`，`％=`，`| =`，`＆=`和`^ =`。
`a ++`和`a  - `相当于`a + = 1` /`a  -  = 1`，但表达式本身仍然具有以前的a值。
相反，` -  a`和`++ a`对`a`具有相同的效果，但在更改后返回值。

### 删除

`delete a`将类型的初始值赋给`a`。
即,对于整数，它相当于`a = 0`，但它也可以用于数组，它分配一个长度为零的动态数组或者一个长度相同的静态数组，并且所有元素都被重置。
对于结构体，它分配一个所有成员重置的结构体。

`delete`对整个映射没有影响(因为映射的键可能是任意的并且通常是未知的)。
因此，如果你删除一个结构体，它将重置所有不是映射的成员，并且还会映射到成员中，除非它们是映射关系。
但是，可以删除个人密钥及其映射的内容。

需要注意的是，`delete a`的确像`a`的赋值，即它将一个新对象存储在`a`中。

```js
pragma solidity ^0.4.0;

contract DeleteExample {
    uint data;
    uint[] dataArray;

    function f() public {
        uint x = data;
        delete x; // 将x设置为0，不影响数据
        delete data; // 将数据设置为0，不会影响仍保留副本的x
        uint[] storage y = dataArray;
        delete dataArray;
        // 这将dataArray.length设置为零，
        // 但是由于uint[]是一个复杂的对象，
        // y也会受到影响，这是存储对象的别名
        // 另一方面: "delete y" 无效,
        // 因为引用存储对象的本地变量的分配只能由现有存储对象创建。
    }
}
```

## 基本类型之间的转换

### 隐式转换

如果运算符应用于不同的类型，编译器会尝试隐式地将其中一个操作数转换为另一个操作数的类型(对于赋值也是如此)。
在一般情况下，值类型之间的隐式转换是可能的，如果它是有道理的语义和不丢失任何信息：`uint8`可以转换为`uint16`和`int128`到`int256`，但`int8`是无法转换为` ,uint256`(因为`uint256`不能包含`-1`)。
此外，无符号整数可以转换为相同或更大尺寸的字节，但反之亦然。
任何可以转换为`uint160`的类型也可以转换为`address`。

### 显式转换

如果编译器不允许隐式转换，但您知道自己在做什么，则有时可以使用显式类型转换。
请注意，这可能会给你一些意想不到的行为，所以一定要测试以确保结果是你想要的！,拿下面的例子，你将一个负的`int8`转换为`uint`：

```js
int8 y = -3;
uint x = uint(y);
```

在这个代码片段的末尾，`x`将具有值`0xfffff..fd`(64个十六进制字符)，在256位的二进制补码表示中为-3。

如果某种类型明确转换为较小类型，则会切断较高位：

```js
uint32 a = 0x12345678;
uint16 b = uint16(a); // b will be 0x5678 now
```

## 类型扣除

为了方便起见，并不总是需要明确指定变量的类型，编译器会根据分配给变量的第一个表达式的类型自动推断它：

```js
uint24 x = 0x123;
var y = x;
```

在这里，`y`的类型将是`uint24`。
函数参数或返回参数不能使用`var`。

!!! warning

    这个类型只是从第一个赋值中推导出来的，所以下面的代码片段中的循环是无限的，因为`i`将具有`uint8`类型并且这个类型的最大值小于`2000`.`for(var i ,= 0; i <2000; i ++){...}`
