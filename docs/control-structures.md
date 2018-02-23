# 表达式和控制结构

## 输入参数和输出参数

与Javascript一样，函数可能会将参数作为输入;,不像在Javascript和C中，它们也可以返回任意数量的参数作为输出。

### 输入参数

输入参数的声明方式与变量相同。
作为例外，未使用的参数可以省略变量名称。
例如，假设我们希望我们的合同接受一种具有两个整数的外部调用，我们会写如下所示的内容：

    pragma solidity ^0.4.16;

    contract Simple {
        function taker(uint _a, uint _b) public pure {
            // do something with _a and _b.
        }
    }

### 输出参数

输出参数可以在`returns`关键字之后用相同的语法声明。
例如，假设我们希望返回两个结果：两个给定整数的总和和乘积，那么我们会写：

    pragma solidity ^0.4.16;

    contract Simple {
        function arithmetics(uint _a, uint _b)
            public
            pure
            returns (uint o_sum, uint o_product)
        {
            o_sum = _a + _b;
            o_product = _a * _b;
        }
    }

输出参数的名称可以省略。
输出值也可以用`return`语句指定。
return语句也可以返回多个值，参见[multi-return]（）。
返回参数被初始化为零;,如果他们没有明确设定，他们将保持为零。

输入参数和输出参数可以用作函数体中的表达式。
在那里，它们也可以在作业的左侧使用。

## 控制结构

除了`switch`和`goto`之外，大多数来自JavaScript的控制结构都可以使用。
所以有：if，else，while，do，for，break，continue，return，`？ ,：`，用C或JavaScript已知的通常语义。

对于条件式，括号不能被忽略，但可以在单个语句的机构周围省略括号。

请注意，不存在从非布尔类型到布尔类型的类型转换，因为在C和JavaScript中存在，所以`if（1）{...}`不是*有效的Solidity。

### 返回多个值

当函数有多个输出参数时，`return（v0，v1，...，vn）`可以返回多个值。
组件的数量必须与输出参数的数量相同。

## 函数调用

### 内部函数调用

可以直接（“内部”）调用当前合约的功能，也可以递归地调用，如在这个无意义的示例中所见：

    pragma solidity ^0.4.16;

    contract C {
        function g(uint a) public pure returns (uint ret) { return f(); }
        function f() internal pure returns (uint ret) { return g(7) + f(); }
    }

这些函数调用被转换为EVM内部的简单跳转。
这样做的效果是当前内存不会被清除，即将内存引用传递给内部调用的函数非常有效。
只有同一合同的功能可以在内部调用。

### 外部函数调用

表达式`this.g（8）;`和`cg（2）;`（其中`c`是一个契约实例）也是有效的函数调用，但这次函数将被称为“外部”,消息调用，而不是直接通过跳转。
请注意，`this`上的函数调用不能在构造函数中使用，因为实际合约尚未创建。

其他合同的功能必须从外部调用。
对于外部调用，所有函数参数都必须复制到内存中。

当调用其他合约的函数时，可以用特殊选项`.value（）`和`.gas（）`分别指定发出呼叫和瓦斯的数量:

    pragma solidity ^0.4.0;

    contract InfoFeed {
        function info() public payable returns (uint ret) { return 42; }
    }

    contract Consumer {
        InfoFeed feed;
        function setFeed(address addr) public { feed = InfoFeed(addr); }
        function callFeed() public { feed.info.value(10).gas(800)(); }
    }

“应付”修饰符必须用于“info”，否则，.value（）选项将不可用。

请注意，表达式“InfoFeed（addr）”执行显式类型转换，指出“我们知道给定地址的合约类型为'InfoFeed`”，并且这不会执行构造函数。
显式类型转换必须谨慎处理。
不要在不确定其类型的合同上调用函数。

我们也可以使用`function setFeed（InfoFeed _feed）{feed = _feed; ,``直接。
注意只有（本地）`feed.info.value（10）.gas（800）`设置函数调用发送的气体的值和数量，并且只有最后的括号才会执行实际的调用。

如果被叫合同不存在（在账户不包含代码的意义上），或者被叫合同本身抛出异常或缺油，函数调用会导致异常。

!!! Warning

    与其他合同的任何交互都会产生潜在的危险，特别是如果合同的源代码未提前知晓。
    目前的合同将控制权移交给被叫合同，这可能会做任何事情。
    即使被叫合同继承自已知的父合同，继承合同也只需要具有正确的接口。
    然而，合同的执行可能是完全随意的，因此构成危险。
    另外，要做好准备，以防其在您的系统的其他合同中调用，甚至在第一次调用返回之前回到呼叫合同中。
    这意味着被叫合同可以通过其功能改变主叫合同的状态变量。
    以某种方式编写函数，例如，在对合同中的状态变量进行任何更改后调用外部函数，以使合同不易受到重入式攻击的影响。

### 命名的呼叫和匿名功能参数

函数调用参数也可以按任意顺序由名称给出，如果它们包含在“{}”中，如以下示例中所示。
参数列表必须按名称与函数声明中的参数列表重合，但可以按任意顺序排列。

    pragma solidity ^0.4.0;

    contract C {
        function f(uint key, uint value) public {
            // ...
        }

        function g() public {
            // 命名参数
            f({value: 2, key: 3});
        }
    }

### 省略函数参数名称

未使用的参数名称（特别是返回参数）可以省略。
这些参数仍然存在于堆栈中，但它们无法访问。

    pragma solidity ^0.4.16;

    contract C {
        // 省略参数名称
        function func(uint k, uint) public pure returns(uint) {
            return k;
        }
    }

## 通过`new`创建合同

合同可以使用`new`关键字创建新合同。
创建合同的完整代码必须事先知道，因此递归创建依赖关系是不可能的。

    pragma solidity ^0.4.0;

    contract D {
        uint x;
        function D(uint a) public payable {
            x = a;
        }
    }

    contract C {
        D d = new D(4); // will be executed as part of C's constructor

        function createD(uint arg) public {
            D newD = new D(arg);
        }

        function createAndEndowD(uint arg, uint amount) public payable {
            // Send ether along with the creation
            D newD = (new D).value(amount)(arg);
        }
    }

从示例中可以看出，可以在使用`.value（）`选项创建`D`实例的同时转发Ether，但不可能限制气体的数量。
如果创建失败（由于堆栈外，没有足够的余额或其他问题），会引发异常。

## 表达式评估顺序

没有指定表达式的评估顺序（更正式地说，表达式树中一个节点的子节点的评估顺序未被指定，但它们当然是在节点本身之前进行评估的）。
只能保证语句按顺序执行，布尔表达式的短路完成。
有关更多信息，请参见[order]（）。

## 分配

### 解构赋值和返回多值

Solidity在内部允许元组类型，即在编译时大小为常量的可能不同类型的对象列表。
这些元组可以同时返回多个值，并同时将它们分配给多个变量（或一般的LValues）：

    pragma solidity ^0.4.16;

    contract C {
        uint[] data;

        function f() public pure returns (uint, bool, uint) {
            return (7, true, 2);
        }

        function g() public {
            // 声明和分配变量。,显式指定类型是不可能的。
            var (x, b, y) = f();
            // 分配给预先存在的变量。
            (x, y) = (2, 7);
            // 交换值的常用技巧 - 不适用于非值存储类型。
            (x, y) = (y, x);
            // 组件可以省略（也用于变量声明）。
            // 如果元组以空组件结束，则其余的值将被丢弃。
            (data.length,) = f(); // 将长度设置为7
            // 左侧也可以做同样的事情。
            // 如果元组以空组件开始，则开始值将被丢弃。
            (,data[3]) = f(); // Sets data[3] to 2
            // 组件只能在作业的左侧排除，但有一个例外：
            (x,) = (1,);
            // （1，）是指定1分量元组的唯一方法，因为（1）等于1。
        }
    }

### 阵列和结构的并发症

赋值语义对于像数组和结构体这样的非值类型来说更复杂一些。
将*分配给状态变量总是会创建一个独立副本。
另一方面，分配给局部变量只为基本类型创建独立副本，即适合32个字节的静态类型。
如果通过状态变量将结构或数组（包括`字节`和`字符串`）分配给局部变量，则局部变量保存对原始状态变量的引用。
对局部变量的第二个赋值不会修改状态，只会改变引用。
赋值给局部变量的成员（或元素）*做*改变状态。

## 范围界定和声明

声明的变量将具有初始缺省值，其字节表示全部为零。
变量的“默认值”是任何类型的典型“零状态”。
例如，“bool”的默认值是“false”。
uint或int类型的默认值是'0'。
对于静态大小的数组和“bytes1”到“bytes32”，每个单独的元素将被初始化为与其类型相对应的默认值。
最后，对于动态大小的数组，“字节”和“字符串”，缺省值是一个空数组或字符串。

无论声明在哪里，在函数的任何位置声明的变量都将处于* entire函数的范围内。
发生这种情况是因为Solidity从JavaScript继承了它的范围规则。
这与许多语言形成对比，在这些语言中变量仅在语义块结尾处声明的范围内。
因此，下面的代码是非法的，并且会导致编译器抛出一个错误，“已经声明的标识符”：

    // 这不会编译

    pragma solidity ^0.4.16;

    contract ScopingErrors {
        function scoping() public {
            uint i = 0;

            while (i++ < 1) {
                uint same1 = 0;
            }

            while (i++ < 2) {
                uint same1 = 0;// 非法，第二次声明同1
            }
        }

        function minimalScoping() public {
            {
                uint same2 = 0;
            }

            {
                uint same2 = 0;// 非法，同样的第二次声明2
            }
        }

        function forLoopScoping() public {
            for (uint same3 = 0; same3 < 1; same3++) {
            }

            for (uint same3 = 0; same3 < 1; same3++) {// 非法，第二次宣布同样3
            }
        }
    }

除此之外，如果声明了一个变量，它将在函数的开头初始化为其默认值。
因此，尽管写得不好，但下面的代码是合法的：

    pragma solidity ^0.4.0;

    contract C {
        function foo() public pure returns (uint) {
            // baz被隐含地初始化为0
            uint bar = 5;
            if (true) {
                bar += baz;
            } else {
                uint baz = 10;// 永不跑步
            }
            return bar;// 返回5
        }
    }

## 错误处理：断言，要求，恢复和例外

Solidity使用状态恢复异常来处理错误。
这种异常将撤消对当前调用（及其所有子调用）中的状态所做的所有更改，并且还向调用者标记错误。
便利函数`assert`和`require`可用于检查条件并在条件不满足时抛出异常。
`assert`函数只能用于测试内部错误，并检查不变量。
'require'函数应该用于确保满足有效条件（例如输入或合同状态变量）或验证从外部合同调用返回的值。
如果使用得当，分析工具可以评估您的合同，以确定将触发失败的“断言”的条件和函数调用。
正确运行的代码不应该达到失败的断言语句;,如果发生这种情况，您应该修复合同中的错误。

还有其他两种方法可以触发异常：`revert`功能可以用来标记错误并恢复当前的呼叫。
将来还可能在“revert”调用中包含有关错误的详细信息。
`throw`关键字也可以用作`revert（）`的替代。

!!! Note

    从版本0.4.13开始，“throw”关键字被弃用，并且将在未来逐步淘汰。

当子通话发生异常时，它们会自动“冒泡”（即重新排除异常）。
这个规则的例外是`send`和低级函数`call`，`delegatecall`和`callcode`
-- 那些在发生异常而不是“冒泡”的情况下返回“false”。

!!! Warning

    作为EVM设计的一部分，如果被叫帐户不存在，则低级`call`，`delegatecall`和`callcode`将返回成功。
    如果需要，必须在调用之前检查是否存在。

捕捉异常尚不可能。

在下面的例子中，您可以看到`require`如何可以轻松地检查输入条件以及`assert`如何用于内部错误检查：

    pragma solidity ^0.4.0;

    contract Sharer {
        function sendHalf(address addr) public payable returns (uint balance) {
            require(msg.value % 2 == 0); // 只允许偶数
            uint balanceBeforeTransfer = this.balance;
            addr.transfer(msg.value / 2);
            // 由于转移在失败时抛出异常并且不能在这里回拨，我们应该没有办法让我们仍然有一半的资金。
            assert(this.balance == balanceBeforeTransfer - msg.value / 2);
            return this.balance;
        }
    }

在以下情况下会产生一个`assert`样式异常：

1. 在以下情况下会产生一个`assert`样式异常：
2. 如果您访问固定长度的`bytesN`的索引太大或为负数。
3. 如果用零进行分或模（例如`5 / 0`或`23％0`）。
4. 如果你转移负数。
5. 如果你将一个太大或负值的值转换为一个枚举类型。
6. 如果您调用内部函数类型的零初始化变量。
7. 如果你用一个参数评估为false来调用`assert`。

在以下情况下会产生`require`-style异常：

1. 调用`throw`。
2. 调用`require`的参数值为`false`。
3. 如果通过消息调用调用某个函数，但是它不能正常完成（例如，它耗尽了气体，没有匹配的函数，或者本身抛出一个异常），除了低级别的操作`call`，`send`，``,委托调用“或”调用码“被使用。,低级别的操作不会抛出异常，但通过返回“false”来指示失败
4. 如果您使用`new`关键字创建合同，但是合同创建没有正确完成（请参阅上面有关“未正确完成”的定义）。
5. 如果您针对不包含代码的合同执行外部函数调用。
6. 如果您的合同通过没有“应付”修饰符（包括构造函数和后备功能）的公共函数接收Ether。
7. 如果你的合同通过公共的getter函数接收Ether。
8. 如果`.transfer（）`失败。

在内部，Solidity为`require`类型的异常执行回复操作（指令`0xfd`）并执行无效操作（指令`0xfe`）来引发`assert`类型的异常。
在这两种情况下，这都会导致EVM恢复对该状态所做的所有更改。
恢复的原因是没有安全的方法来继续执行，因为预期的效果没有发生。
因为我们想保留交易的原子性，所以最安全的做法是恢复所有更改并使整个交易（或至少是通话）无效。
请注意，`assert`样式的异常会消耗掉所有可用的呼叫，而`require`-style异常不会消耗任何从