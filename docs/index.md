# Solidity

Solidity是实施智能合约的合同导向的高级语言。
它受到C ++，Python和JavaScript的影响，旨在针对以太坊虚拟机（EVM）。

Solidity是静态类型的，支持继承，库和其他功能中复杂的用户定义类型。

正如你所看到的，可以创建投票，众筹，盲目拍卖，多重签名钱包等等的合约。

!!! note

    现在尝试使用Solidity的最好方法是使用[Remix][1] (可能需要一段时间才能加载，请耐心等待).

!!! warning

    由于软件是由人类编写的，因此它可能存在缺陷。
    因此，智能合约也应该遵循着名的软件开发最佳实践。
    这包括代码审查，测试，审计和正确性证明。
    另请注意，用户有时比其作者对代码更有信心。
    最后，区块链有自己的事情要注意，所以请看看[security_considerations][2]部分.

## 翻译

本文档由社区志愿者翻译成多种语言，但英文版可作为参考。

- [Spanish][3]
- [Russian][4](相当过时)

## 有用的链接

- [Ethereum][5]
- [更新日志][6]
- [故事积压][7]
- [源代码][8]
- [以太坊Stackexchange][9]
- [格子聊天][10]

## 可用Solidity集成

- [Remix][1]

    带有集成编译器和Solidity运行时环境的基于浏览器的IDE，无需服务器端组件。

- [IntelliJ IDEA插件][11]

    IntelliJ IDEA的固体插件（以及所有其他JetBrains IDE）

- [Visual Studio扩展][12]

    适用于包含Solidity编译器的Microsoft Visual Studio的Solidity插件。

- [SublimeText包 -  Solidity语言语法][13]

    SublimeText编辑器的固体语法高亮显示。

- [Etheratom][14]

    Atom编辑器的插件，具有语法高亮显示，编译和运行时环境（后端节点和VM兼容）。

- [Atom Solidity Linter][15]

    Atom编辑器的插件，提供了Solidity linting。

- [Atom Solium Linter][16]

    使用Solium作为基础的可配置Solidom linter for Atom。

- [Solium][17]

    Linter识别并修复Solidity中的样式和安全问题。

- [Solhint][18]

    Solidity linter为智能合约验证提供安全性，风格指南和最佳实践规则。

- [Visual Studio Code 扩展][19]

    Microsoft Visual Studio Code 包含语法高亮和Solidity编译器的Solidity插件。

- [Emacs Solidity][20]

    Emacs编辑器的插件提供语法高亮和编译错误报告。

- [Vim Solidity][21]

    Vim编辑器的插件提供语法高亮显示。

- [Vim Syntastic][22]

    Vim编辑器的插件提供编译检查。

停止更新:

- [Mix IDE][23]

    基于Qt的IDE用于设计，调试和测试可靠智能合约。

- [Ethereum Studio][24]

    专门的Web IDE，还提供对完整以太坊环境的外壳访问。

## Solidity工具

- [Dapp][25]

    为Solidity构建工具，包管理器和部署助手。

- [Solidity REPL][26]

    立即使用命令行Solidity控制台尝试Solidity。

- [solgraph][27]

    可视化Solidity控制流程并突出显示潜在的安全漏洞。

- [evmdis][28]

    EVM反汇编程序对字节码执行静态分析，以提供比原始EVM操作更高级别的抽象。

- [Doxity][29]

    文档生成器用于Solidity。

## 第三方固体解析器和语法

- [solidity解析器][30]

    适用于JavaScript的Solidity解析器

- [ANTLR的固体语法4][31]

    ANTLR 4解析器生成器的固体语法

## 语言文档

在接下来的几页中，我们将首先看到用Solidity编写的[简单智能合约][32]，然后是关于[blockchains][33]和[以太坊虚拟机] [34]的基础知识。

下一节将通过给出有用的[示例契约][35]来解释Solidity的几个*特性*请记住，您总是可以在[浏览器][36]中尝试契约！

最后和最广泛的部分将深入介绍Solidity的各个方面。

如果您仍然有疑问，可以尝试在[Ethereum Stackexchange][9]网站上搜索或询问，或者到我们的[格子频道][10]。
始终欢迎改进Solidity或本文档的想法！

![Solidity logo](logo.svg)

[1]: https://remix.ethereum.org/
[2]:
[3]: https://solidity-es.readthedocs.io
[4]: https://github.com/ethereum/wiki/wiki/%5BRussian%5D-%D0%A0%D1%83%D0%BA%D0%BE%D0%B2%D0%BE%D0%B4%D1%81%D1%82%D0%B2%D0%BE-%D0%BF%D0%BE-Solidity
[5]: https://ethereum.org
[6]: https://github.com/ethereum/solidity/blob/develop/Changelog.md
[7]: https://www.pivotaltracker.com/n/projects/1189488
[8]: https://github.com/ethereum/solidity/
[9]: https://ethereum.stackexchange.com/
[10]: https://gitter.im/ethereum/solidity/
[11]: https://plugins.jetbrains.com/plugin/9475-intellij-solidity
[12]: https://visualstudiogallery.msdn.microsoft.com/96221853-33c4-4531-bdd5-d2ea5acc4799/
[13]: https://packagecontrol.io/packages/Ethereum/
[14]: https://github.com/0mkara/etheratom
[15]: https://atom.io/packages/linter-solidity
[16]: https://atom.io/packages/linter-solium
[17]: https://github.com/duaraghav8/Solium/
[18]: https://github.com/protofire/solhint
[19]: http://juan.blanco.ws/solidity-contracts-in-visual-studio-code/
[20]: https://github.com/ethereum/emacs-solidity/
[21]: https://github.com/tomlion/vim-solidity/
[22]: https://github.com/scrooloose/syntastic
[23]: https://github.com/ethereum/mix/
[24]: https://live.ether.camp/
[25]: https://dapp.readthedocs.io
[26]: https://github.com/raineorshine/solidity-repl
[27]: https://github.com/raineorshine/solgraph
[28]: https://github.com/Arachnid/evmdis
[29]: https://github.com/DigixGlobal/doxity
[30]: https://github.com/ConsenSys/solidity-parser
[31]: https://github.com/federicobond/solidity-antlr4
[32]: simple-smart-contract.md
[33]: blockchain-basics.md
[34]: the-ethereum-virtual-machine.md
[35]: voting.md
[36]: https://remix.ethereum.org