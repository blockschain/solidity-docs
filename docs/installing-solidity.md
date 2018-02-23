# 安装Solidity编译器

## 版本

除了发布之外，Solidity版本还遵循[语义版本控制][1], 夜间开发版本也可用.
夜间构建不能保证能够正常工作，尽管尽了最大的努力，它们可能包含无证和/或破碎的变化.
我们建议使用最新版本.
下面的包安装程序将使用最新版本.

## Remix

*我们推荐使用Remix进行小型合同，并快速学习Solidity*

[在线访问Remix][2], 你不需要安装任何东西.
如果你想在没有连接到互联网的情况下使用它, 访问<https://github.com/ethereum/browser-solidity/tree/gh-pages> 并按照该页面上的说明下载.ZIP文件.

此页面上的其他选项详细信息在您的计算机上安装命令行Solidity编译器软件。
如果您正在处理更大的合同或需要更多编译选项，请选择命令行编译器。

## npm/Node.js

使用npm以方便便携的方式安装solidity，solidity编译器.
solcjs程序比本页下面的所有选项具有更少的功能.
我们使用编译器文档假定您正在使用全功能编译器solc.
因此，如果您从npm安装solcjs，那么您将停止在此处阅读文档，然后继续<https://github.com/ethereum/solc-js>,

Note: [solc-js]( https://github.com/ethereum/solc-js)项目通过使用Emscripten从C ++ solc派生而来.
solc-js可以直接用于JavaScript项目（如Remix）.
有关说明，请参阅[solc-js][3]存储库.

```bash
npm install -g solc
```

!!! Note

    命令行被命名为solcj

    solcjs的comandline选项与solc和工具（如geth）不兼容，期望solc的行为不会与solcjs一起使用。

## Docker

我们为编译器提供了最新的docker版本。
`stable`版本库包含发布版本，而`nightly`版本库包含develop分支中可能不稳定的版本。

```bash
docker run ethereum/solc:stable solc --version
```

目前，docker镜像仅包含编译器可执行文件，因此您必须执行一些额外的工作来链接源目录和输出目录。

## 二进制包

Solidity的二元包装可在[solidity / releases][4].

我们也为Ubuntu提供PPA。,为最新的稳定版本。

```bash
sudo add-apt-repository ppa:ethereum/ethereum
sudo apt-get update
sudo apt-get install solc
```

如果你想使用尖端的开发者版本:

```bash
sudo add-apt-repository ppa:ethereum/ethereum
sudo add-apt-repository ppa:ethereum/ethereum-dev
sudo apt-get update
sudo apt-get install solc
```

我们也发布了一个[快照包][5], 它可以安装在所有[受支持的Linux发行版中](https://snapcraft.io/docs/core/install).
要安装solc的最新稳定版本:

```bash
sudo snap install solc
```

或者，如果你想帮助测试不稳定的solc与来自开发分支的最新变化:

```bash
sudo snap install solc --edge
```

Arch Linux也有软件包，尽管只限于最新的开发版本:

```bash
pacman -S solidity
```

在编写本文的时候，Homebrew缺少预制的瓶子，继Jenkins和TravisCI的迁移之后，Homebrew仍然可以很好地工作，作为构建源代码的一种手段.
我们很快会重新添加预制瓶.

```bash
brew update
brew upgrade
brew tap ethereum/ethereum
brew install solidity
brew linkapps solidity
```

如果您需要特定版本的Solidity，您可以直接从Github安装Homebrew公式。

查看[solidity.rb在Github上提交](https://github.com/ethereum/homebrew-ethereum/commits/master/solidity.rb).

按照历史链接，直到你有一个特定的`solidity.rb`提交的原始文件链接。

使用`brew`安装它:

```bash
brew unlink solidity
# Install 0.4.8
brew install https://raw.githubusercontent.com/ethereum/homebrew-ethereum/77cce03da9f289e5a3ffe579840d3c5dc0a62717/solidity.rb
```

Gentoo Linux还提供了一个可以使用`emerge`安装的可靠软件包:

```bash
emerge dev-lang/solidity
```

## 从源代码构建

### 克隆存储库

要克隆源代码，请执行以下命令:

```bash
git clone --recursive https://github.com/ethereum/solidity.git
cd solidity
```

如果你想帮助开发Solidity，你应该分叉Solidity并添加你的个人分叉作为第二个远程:

```bash
cd solidity
git remote add personal git@github.com:[username]/solidity.git
```

Solidity有git submodules.
确保它们正确装载:

```bash
git submodule update --init --recursive
```

### 先决条件 -  macOS

对于macOS，确保您安装了最新版本的[Xcode](https://developer.apple.com/xcode/download/).
这包含[Clang C ++编译器][6], [Xcode IDE][7]以及在OS X上构建C ++应用程序所需的其他Apple开发工具.
如果您是第一次安装Xcode，或者刚刚安装了新版本，那么在您执行命令行构建之前，您需要同意该许可证:

```bash
sudo xcodebuild -license accept
```

我们的OS X版本要求您安装[Homebrew]][8]软件包管理器来安装外部依赖项。
以下是如何卸载[Homebrew](https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/FAQ.md#how-do-i-uninstall-homebrew),如果你想从头开始重新开始.

### 先决条件 -  Windows

您需要为Windows版本的Solidity安装以下依赖项:

|软件 | 注释 |
|-|-|
| [Git for Windows][9] | 用于从Github获取源的命令行工具。|
| [CMake][10] | 跨平台的构建文件生成器。|
| [Visual Studio C ++编译器和开发环境。 ,2015年][11] ||

### 外部依赖性

我们现在有一个“一键”脚本，可以在macOS，Windows和众多Linux发行版上安装所有必需的外部依赖项.
这曾经是一个多步手动过程，但现在是一个单线程:

```bash
./scripts/install_deps.sh
```

或者，在Windows上:

```bat
scripts\install_deps.bat
```

### 命令行构建

**确保在构建之前安装外部依赖关系（参见上文）。**

Solidity项目使用CMake来配置构建。
在Linux，macOS和其他Unices上，Building Solidity非常相似:

```bash
mkdir build
cd build
cmake .. && make
```

甚至更容易:

```bash
#note: 这将在 /usr/local/bin 上安装二进制文件 solc 和 soltest
./scripts/build.sh
```

甚至对于Windows:

```bash
mkdir build
cd build
cmake -G "Visual Studio 14 2015 Win64" ..
```

后一组指令应该导致在该构建目录中创建** solidity.sln **.
双击该文件应该会导致Visual Studio启动.
我们建议构建** RelWithDebugInfo **配置，但所有其他工作.

或者，您可以在命令行上为Windows构建，就像这样:

```bash
cmake --build .
--config RelWithDebInfo
```

## CMake选项

如果您对CMake选项有用感兴趣，请运行`cmake .. -LH`。

## 版本字符串详细

Solidity版本字符串包含四个部分:

- 版本号
- 预发布标签，通常设置为`develop.YYYY.MM.DD`或`nightly.YYYY.MM.DD`
- 以`commit.GITHASH`格式提交
- 平台具有任意数量的项目，包含有关平台和编译器的详细信息

如果有本地修改，则提交将以`.mod`作为后缀。

这些部件按照Semver的要求进行组合，其中Solidity预发布标签等于Semver预发行版，并且Solidity提交和平台组合了Semver构建元数据。

一个发布的例子：`0.4.8 + commit.60cc1668.Emscripten.clang`。

预发布示例：`0.4.9-nightly.2017.1.17 + commit.6ecb4aa3.Emscripten.clang`

## 有关版本控制的重要信息

发布后，修补程序版本级别会发生变化，因为我们假定只有修补程序级别发生变化。
当合并更改时，版本应该根据semver和更改的严重程度进行调整。
最后，版本总是与当前夜间版本的版本一起发布，但没有“预发布”说明符。

例:

0. 发布0.4.0版本
1. 从现在开始，每晚构建版本为0.4.1
2. 引入了非破坏性更改 - 版本不变
3. 一个突破性的变化被引入 - 版本被撞到0.5.0
4. 发布了0.5.0版本

这种行为与[版本编译][12]指示很好地结合.

[1]: https://semver.org
[2]: https://remix.ethereum.org/
[3]: https://github.com/ethereum/solc-js
[4]: https://github.com/ethereum/solidity/releases
[5]: https://snapcraft.io/
[6]: https://en.wikipedia.org/wiki/Clang
[7]: https://en.wikipedia.org/wiki/Xcode
[8]: http://brew.sh
[9]: https://git-scm.com/download/win
[10]: https://cmake.org/download/
[11]: https://www.visualstudio.com/products/vs-2015-product-editions
[12]: version_pragma.md