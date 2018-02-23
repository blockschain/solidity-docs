# 特约

总是感谢帮助！

要开始,您可以尝试[从源代码构建]()以熟悉Solidity的组件和构建过程。
此外,熟练掌握Solidity智能合约也许会有用处。

特别是,我们需要以下方面的帮助：

- 改进文档
- 回答[StackExchange][1]和[Solidity Gitter][2]上其他用户提出的问题,
- 修复并回应[Solidity的GitHub问题](https://github.com/ethereum/solidity/issues),特别是标记为[up-for-grabs][3]的标签,这些标签是外部贡献者的介绍性问题。

## 如何报告问题

要报告问题,请使用[GitHub问题跟踪器](https://github.com/ethereum/solidity/issues)。
报告问题时,请提及以下详细信息：

- 您正在使用哪个版本的Solidity
- 什么是源代码(如果适用)
- 你在哪个平台上运行
- 如何重现该问题
- 这个问题的结果是什么
- 预期的行为是什么

将导致问题的源代码减少到最低程度总是非常有用,有时甚至可以澄清误解。

## 合并请求的工作流程

为了做出贡献,请分开`develop`分支并在​​那里进行更改。
你的提交信息应该详细说明*为什么*除了*你做了什么之外,你做了你的改变(除非它是一个微小的改变)。

如果您在创建fork之后需要从`develop`进行任何更改(例如,解决潜在的合并冲突),请避免使用`git merge`,而是使用`git rebase`分支。

此外,如果您正在编写新功能,请确保编写适当的Boost测试用例并将它们放在`test/`下。

但是,如果你正在做出更大的改变,请咨询[坚实发展Gitter渠道](https://gitter.im/ethereum/solidity-dev)(与上面提到的不同,这个重点是编译器和,语言发展而不是语言使用)。

最后,请确保您尊重该项目的[编码标准](https://raw.githubusercontent.com/ethereum/cpp-ethereum/develop/CodingStandards.txt)。
另外,即使我们进行CI测试,也请测试您的代码,并确保它在提交请求之前在本地构建。

感谢您的帮助！

## 运行编译器测试

固体包括不同类型的测试。
它们被包含在名为`soltest`的应用程序中。
其中一些需要`cpp-ethereum`客户端处于测试模式,另一些则需要安装`libz3`。

要禁用z3测试,请使用`./build/test/soltest  -  --no-smt`并运行不需要`cpp-ethereum`的测试子集,使用`./build/test/soltest, -  --no-ipc`。

对于所有其他测试,您需要安装[cpp-ethereum][4]并在测试模式下运行：`eth --test -d/tmp/testeth`。

然后运行实际测试：`./build/test/soltest --ipcpath/tmp/testeth/geth.ipc`。

要运行测试的一个子集,可以使用过滤器：`soltest -t TestSuite/TestName  -  --ipcpath/tmp/testeth/geth.ipc`,其中`TestName`可以是通配符`*`。

或者,在`scripts/test.sh`上有一个测试脚本,它执行所有测试,并在路径中(但不下载)自动运行`cpp-ethereum`。

Travis CI甚至运行一些额外的测试(包括`solc-js`和测试第三方Solidity框架),这些测试需要编译Emscripten目标。

## 晶须

*Whiskers*是一个类似于[Moustache][5]的模板系统。
编译器在各个地方使用它来帮助代码的可读性以及可维护性和可验证性。

语法与Mustache有很大的区别：为了帮助解析和避免与[inline-assembly]()的冲突,模板标记`{{`和`}}`被`<`和`>`替换,内联汇编中符号`<`和`>`无效,而`{`和`}`用于分隔块)。
另一个限制是列表只能解决一个深度,他们不会递归。
这可能在未来发生变化。

一个粗略的规范如下：

任何出现的`<name>`被替换为提供的变量`name`的字符串值,不会有任何转义,也不会有迭代替换。
一个区域可以用`<#name> ... </name>`分隔。
它被替换为尽可能多的连接内容,因为有一组变量提供给模板系统,每次用各自的值替换任何内部项目。
顶级变量也可以在这些区域内使用。

[1]: https://ethereum.stackexchange.com
[2]: https://gitter.im/ethereum/solidity
[3]: https://github.com/ethereum/solidity/issues?q=is%3Aopen+is%3Aissue+label%3Aup-for-grabs
[4]: https://github.com/ethereum/cpp-ethereum/releases/download/solidityTester/eth
[5]: https://mustache.github.io