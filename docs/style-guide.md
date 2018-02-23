# 样式指南

## 介绍

本指南旨在为编写可靠性代码提供编码约定。
本指南应该被认为是一个不断变化的文件，随着时间的推移会发生变化，因为找到有用的约定而旧的惯例已经过时。

许多项目将实施他们自己的风格指南。
在发生冲突时，项目特定的风格指南优先。

该风格指南中的结构和许多建议都来自python的[pep8风格指南](https://www.python.org/dev/peps/pep-0008/)。

本指南的目标是*不*是正确的方式或编写固体代码的最佳方式。
本指南的目标是*一致性*。
python的[pep8][1]引用了这个概念。

> 风格指南是关于一致性的。
> 与此风格指南保持一致非常重要。
> 项目中的一致性更重要。
> 一个模块或功能内的一致性是最重要的。
> 但最重要的是：知道什么时候不一致 - 有时风格指南不适用。
> 如有疑问，请使用您的最佳判断。
> 看看其他例子，并决定什么看起来最好。
> 不要犹豫，问！

## 代码布局

### 缩进

每个缩进级别使用4个空格。

### 选项卡或空格

空格是首选的缩进方法。

应该避免混合标签和空格。

### 空白行

在两个空白行中围绕可靠来源的顶层声明。

正确:

    contract A {
        ...
    }


    contract B {
        ...
    }


    contract C {
        ...
    }

错误:

    contract A {
        ...
    }
    contract B {
        ...
    }

    contract C {
        ...
    }

在一个合同环绕函数声明中有一个空白行。

在相关单行的组之间可以省略空行(例如抽象合约的存根函数)

正确:

    contract A {
        function spam() public;
        function ham() public;
    }


    contract B is A {
        function spam() public {
            ...
        }

        function ham() public {
            ...
        }
    }

错误:

    contract A {
        function spam() public {
            ...
        }
        function ham() public {
            ...
        }
    }

### 源文件编码

UTF-8或ASCII编码是首选。

### 进口

导入语句应始终放在文件的顶部。

正确:

    import "owned";


    contract A {
        ...
    }


    contract B is owned {
        ...
    }

错误:

    contract A {
        ...
    }


    import "owned";


    contract B is owned {
        ...
    }

### 函数顺序

排序有助于读者识别他们可以调用哪些函数，并更容易地找到构造函数和回退定义。

功能应根据其可见性分组，并命令：

- constructor
- fallback function (if exists)
- external
- public
- internal
- private

在一个分组中，最后放置`constant`函数。

正确:

    contract A {
        function A() public {
            ...
        }

        function() public {
            ...
        }

        // External functions
        // ...

        // External functions that are constant
        // ...

        // Public functions
        // ...

        // Internal functions
        // ...

        // Private functions
        // ...
    }

错误:

    contract A {

        // External functions
        // ...

        // Private functions
        // ...

        // Public functions
        // ...

        function A() public {
            ...
        }

        function() public {
            ...
        }

        // Internal functions
        // ...
    }

### 表达式中的空格

在以下情况下避免无关的空白：

立即在括号，括号或大括号内，除单行函数声明外。

正确:

    spam(ham[1], Coin({name: "ham"}));

错误:

    spam( ham[ 1 ], Coin( { name: "ham" } ) );

Exception:

    function singleLine() public { spam(); }

紧接在逗号前面的分号：

正确:

    function spam(uint i, Coin coin) public;

错误:

    function spam(uint i , Coin coin) public ;

在任务或其他运营商周围的多个空间与另一个空间对齐：

正确:

    x = 1;
    y = 2;
    long_variable = 3;

错误:

    x             = 1;
    y             = 2;
    long_variable = 3;

不要在后备功能中包含空格：

正确:

    function() public {
        ...
    }

错误:

    function () public {
        ...
    }

### 控制结构

表示合同，图书馆，职能和结构主体的大括号应该：

- 与宣言打开在同一行
- 在宣言开始的同一缩进级别自行关闭。
- 开口支架应该由一个空间进行。

正确:

    contract Coin {
        struct Bank {
            address owner;
            uint balance;
        }
    }

错误:

    contract Coin
    {
        struct Bank {
            address owner;
            uint balance;
        }
    }

同样的建议适用于控制结构if，else，while，for。

此外，在控制结构if，while和for之间应该有一个单独的空间，并且用括号表示条件，以及在有条件的圆括号和左括号之间的单个空格。

正确:

    if (...) {
        ...
    }

    for (...) {
        ...
    }

错误:

    if (...)
    {
        ...
    }

    while(...){
    }

    for (...) {
        ...;}

对于其主体包含单个语句的控制结构，如果语句包含在一行中，省略大括号即可。

正确:

    if (x < 10)
        x += 1;

错误:

    if (x < 10)
        someArray.push(Coin({
            name: 'spam',
            value: 42
        }));

对于有`else`或`else if`子句的`if`块，`else`应该和`if`的右大括号放在同一行。
与其他块状结构的规则相比，这是一个例外。

正确:

    if (x < 3) {
        x += 1;
    } else if (x > 7) {
        x -= 1;
    } else {
        x = 5;
    }


    if (x < 3)
        x += 1;
    else
        x -= 1;

错误:

    if (x < 3) {
        x += 1;
    }
    else {
        x -= 1;
    }

### 函数声明

对于简短的函数声明，建议将函数体的左大括号与函数声明保持在同一行。

右大括号应该与函数声明的缩进级别相同。

开放大括号应该有一个空格。

正确:

    function increment(uint x) public pure returns (uint) {
        return x + 1;
    }

    function increment(uint x) public pure onlyowner returns (uint) {
        return x + 1;
    }

错误:

    function increment(uint x) public pure returns (uint)
    {
        return x + 1;
    }

    function increment(uint x) public pure returns (uint){
        return x + 1;
    }

    function increment(uint x) public pure returns (uint) {
        return x + 1;
        }

    function increment(uint x) public pure returns (uint) {
        return x + 1;}

函数的可见性修饰符应该位于任何自定义修饰符之前。

正确:

    function kill() public onlyowner {
        selfdestruct(owner);
    }

错误:

    function kill() onlyowner public {
        selfdestruct(owner);
    }

对于长函数声明，建议将每个参数放在与函数体相同的缩进级别的自己的行上。
右括号和左括号应该放在它们自己的行上，以及与函数声明相同的缩进级别。

正确:

    function thisFunctionHasLotsOfArguments(
        address a,
        address b,
        address c,
        address d,
        address e,
        address f
    )
        public
    {
        doSomething();
    }

错误:

    function thisFunctionHasLotsOfArguments(address a, address b, address c,
        address d, address e, address f) public {
        doSomething();
    }

    function thisFunctionHasLotsOfArguments(address a,
                                            address b,
                                            address c,
                                            address d,
                                            address e,
                                            address f) public {
        doSomething();
    }

    function thisFunctionHasLotsOfArguments(
        address a,
        address b,
        address c,
        address d,
        address e,
        address f) public {
        doSomething();
    }

如果一个长函数声明有修饰符，那么每个修饰符应该放在它自己的行中。

正确:

    function thisFunctionNameIsReallyLong(address x, address y, address z)
        public
        onlyowner
        priced
        returns (address)
    {
        doSomething();
    }

    function thisFunctionNameIsReallyLong(
        address x,
        address y,
        address z,
    )
        public
        onlyowner
        priced
        returns (address)
    {
        doSomething();
    }

错误:

    function thisFunctionNameIsReallyLong(address x, address y, address z)
                                          public
                                          onlyowner
                                          priced
                                          returns (address) {
        doSomething();
    }

    function thisFunctionNameIsReallyLong(address x, address y, address z)
        public onlyowner priced returns (address)
    {
        doSomething();
    }

    function thisFunctionNameIsReallyLong(address x, address y, address z)
        public
        onlyowner
        priced
        returns (address) {
        doSomething();
    }

对于基础需要参数的继承契约的构造函数，如果函数声明很长或难以阅读，建议将基础构造函数以与修饰符相同的方式放到新行上。

正确:

    contract A is B, C, D {
        function A(uint param1, uint param2, uint param3, uint param4, uint param5)
            B(param1)
            C(param2, param3)
            D(param4)
            public
        {
            // do something with param5
        }
    }

错误:

    contract A is B, C, D {
        function A(uint param1, uint param2, uint param3, uint param4, uint param5)
        B(param1)
        C(param2, param3)
        D(param4)
        public
        {
            // do something with param5
        }
    }

    contract A is B, C, D {
        function A(uint param1, uint param2, uint param3, uint param4, uint param5)
            B(param1)
            C(param2, param3)
            D(param4)
            public {
            // do something with param5
        }
    }

当用单个语句声明简短函数时，允许在一行中完成。

可允许:

    function shortFunction() public { doSomething(); }

这些函数声明的准则旨在提高可读性。
作者应该使用他们的最佳判断，因为本指南并不试图涵盖函数声明的所有可能的排列。

### 映射

TODO

### 变量声明

数组变量的声明在类型和括号之间不应该有空格。

正确:

    uint[] x;

错误:

    uint [] x;

### 其他建议

- 字符串应该用双引号而不是单引号引用。

正确:

    str = "foo";
    str = "Hamlet says, 'To be or not to be...'";

错误:

    str = 'bar';
    str = '"Be yourself; everyone else is already taken." -Oscar Wilde';

- 环绕操作员，在任何一边都有一个空间。

正确:

    x = 3;
    x = 100 / 10;
    x += 3 + 4;
    x |= y && z;

错误:

    x=3;
    x = 100/10;
    x += 3+4;
    x |= y&&z;

- 比其他优先级高的运算符可以排除周围的空白，以表示优先级。这是为了提高复杂语句的可读性。您应该始终在运算符的任一侧使用相同数量的空白：

正确:

    x = 2**3 + 5;
    x = 2*y + 3*z;
    x = (a+b) * (a-b);

错误:

    x = 2** 3 + 5;
    x = y+z;
    x +=1;

## 命名约定

命名约定在被广泛采用和使用时功能强大。
使用不同的约定可以传达重要的*meta*信息，否则这些信息不会立即可用。

这里给出的命名建议旨在提高可读性，因此它们不是规则，而是试图帮助通过事物名称传达最多信息的指导原则。

最后，代码库中的一致性应始终取代本文档中概述的任何约定。

### 命名样式

为避免混淆，下列名称将用于指代不同的命名风格。

- `b` (单小写字母)
- `B` (单个大写字母)
- `lowercase`
- `lower_case_with_underscores`
- `UPPERCASE`
- `UPPER_CASE_WITH_UNDERSCORES`
- `CapitalizedWords` (或`CapWords`)
- ``mixedCase`` (与大写字母不同的是小写字母！)
- `Capitalized_Words_With_Underscores`

::: {.note}
::: {.admonition-title}
Note
:::

在`CapWords`中使用缩写时，请将缩写的所有字母大写。
因此`HTTPServerError`比`HTTPServerError`好。
:::

### 要避免的名称

- `l` - 小写字母 el
- `O` - 大写字母 oh
- `I` - 大写字母 eye

切勿将任何这些用于单个字母的变量名称。
它们通常与数字1和零不可区分。

### 合同和图书馆名称

合约和库应该使用`CapWords`风格命名。
示例: `SimpleToken`, `SmartBank`, `CertificateHashRepository`, `Player`.

### 结构名称

结构应该使用`CapWords`风格命名。
示例: `MyCoin`, `Position`, `PositionXY`.

### 事件名称

事件应该使用`CapWords`风格命名。
示例: `Deposit`, `Transfer`, `Approval`, `BeforeTransfer`, `AfterTransfer`.

### 函数名称

构造函数以外的函数应该使用`mixedCase`。
示例: `getBalance`, `transfer`, `verifyOwner`, `addMember`, `changeOwner`.

### 函数参数名称

函数参数应该使用`mixedCase`。
示例: `initialSupply`, `account`, `recipientAddress`, `senderAddress`, `newOwner`.

在编写对自定义结构进行操作的库函数时，该结构应该是第一个参数，并且应该始终命名为“self”。

### 本地和国家变量名称

使用`mixedCase`。
示例: `totalSupply`, `remainingSupply`, `balancesOf`, `creatorAddress`, `isPreSale`, `tokenExchangeRate`.

### 常量

常量应以全部大写字母命名，并用下划线分隔单词。
示例: `MAX_BLOCKS`, `TOKEN_NAME`, `TOKEN_TICKER`, `CONTRACT_VERSION`.

### 修饰符名称

使用`mixedCase`。
示例: `onlyBy`, `onlyAfter`, `onlyDuringThePreSale`.

### 枚举

使用简单类型声明的风格的枚举应该使用`CapWords`风格来命名。
示例: `TokenGroup`, `Frame`, `HashStyle`, `CharacterLocation`.

### 避免命名冲突

- `single_trailing_underscore_`

当所需名称与内置名称或其他名称相冲突时，会提示此惯例。

### 一般建议

TODO

[1]: https://www.python.org/dev/peps/pep-0008/#a-foolish-consistency-is-the-hobgoblin-of-little-minds
