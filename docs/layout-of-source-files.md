# 合适源文件的布局

源文件可以包含任意数量的合约定义，包括指令和编译指示。

## 版本编译指示

源文件必须用版本编译指示来注释，以杜绝编入不兼容版本。
我们试图将这种变化保持在绝对最低限度，特别是以语义变化的方式引入变化也会要求语法上的变化，但这当然不总是可能的。
因此，至少对于包含重大变更的版本，通读变更日志始终是一个好主意，这些版本将始终具有`0.x.0`或`x.0.0`形式的版本。

版本附注使用如下：

```js
pragma solidity ^0.4.0;
```

这样的源文件不会在编译早于版本0.4.0的编译器下编译，且它也不适用于从版本0.5.0开始的编译器(第二个条件是使用`^`添加的)。
这背后的想法是，在版本0.5.0之前不会有任何重大更改，所以我们可以始终确保我们的代码将按照我们预期的方式进行编译。
我们不修复编译器的确切版本，所以错误修复版本仍然是可能的。

可以为编译器版本指定更复杂的规则，表达式遵循[npm](https://docs.npmjs.com/misc/semver)使用的规则.

## 导入文件

### 语法和语义

Solidity 支持类似于 JavaScript 中的导入语句(来自ES6)，尽管Solidity不知道`default export`的概念。

在全局范围内，您可以使用以下格式的导入语句：

```js
import "filename";
```

该语句从`filename`(及其导入的符号)中导入所有全局符号到当前全局作用域(与ES6不同，但向后兼容Solidity)。

```js
import * as symbolName from "filename";
```

...创建一个新的全局符号`symbolName`，其成员都是`"filename"`中的全局符号。

```js
import {symbol1 as alias, symbol2} from "filename";
```

...分别创建新的全局符号`alias`和`symbol2`，它们分别从`"filename"`引用`symbol1`和`symbol2`。

另一种语法不是ES6的一部分，但可能很方便：

```js
import "filename" as symbolName;
```

这相当于`import * as symbolName from "filename";`。

### 路径

在上面的例子中，`filename`路径以`/`作为目录分隔符，`.`作为当前目录，`..`作为父目录。
当`.`或`..`后面跟着一个除`/`以外的字符时，它不被视为当前目录或父目录。
除非以`.`或`..`开头，否则所有路径都视为绝对路径。

要从当前文件相同的目录中导入文件`x`，请使用`import "./x" as x;`。
如果使用`import "x" as x;`，则可以引用不同的文件(在全局`包含目录`中)。

这取决于编译器如何实际解析路径(见下文)。

通常，目录层次结构不需要严格映射到本地文件系统，它也可以映射到通过`ipfs`, `http`或者`git`发现的资源.

### 在实际编译器中使用

编译器被调用时，不仅可以指定如何发现路径的第一个元素，但是可以指定路径前缀重映射，例如`github.com/ethereum/dapp-bin/library`被重新映射到`/usr/local/dapp-bin/library`，编译器将从那里读取文件。
如果可以应用多重重映射，则首先尝试使用最长密钥的那个。
这允许用例如“后备-重新映射” ,`""`映射到`"/usr/local/include/solidity"`。
此外，这些重新映射可能取决于上下文，从而允许您配置要导入的包如不同版本的同名库。

**solc**:

对于solc(命令行编译器)，这些重新映射是作为`context：prefix = target`参数提供的，其中`context：`和`= target`部分是可选的(目标默认为前缀)。
所有重新映射的常规文件都被编译(包括它们的依赖关系)。
这种机制是完全向后兼容的(只要没有文件名包含`=`或`:`)，因此不是一个突破性的改变。
在导入以`prefix`开头的文件的`context`目录下的文件中的所有导入都将通过`target`替换`prefix`来重定向。

例如，如果您将`github.com/ethereum/dapp-bin/`本地克隆到`/usr/local/dapp-bin`，则可以在源文件中使用以下内容：

```js
import "github.com/ethereum/dapp-bin/library/iterable_mapping.sol" as it_mapping;
```

然后运行编译器

```bash
solc github.com/ethereum/dapp-bin/=/usr/local/dapp-bin/source.sol
```

作为一个更复杂的例子，假设你依赖于一些使用非常旧版本的`dapp-bin`的模块。在`/usr/local/dapp-bin_old`处检出旧版本的`dapp-bin`，然后就可以使用

```bash
solc module1:github.com/ethereum/dapp-bin/=/usr/local/dapp-bin/
     module2:github.com/ethereum/dapp-bin/=/usr/local/dapp-bin_old/
     source.sol
```

因此`module2`中的所有导入都指向旧版本，但是`module1`中的导入将获得新版本。

请注意，solc仅允许您包含来自特定目录的文件：它们必须位于某个明确指定的源文件的目录(或子目录)中，或位于重新映射目标的目录(或子目录)中。
如果你想允许直接绝对包含，只需添加重新映射`=/`。

如果存在多个导致有效文件的重映射，则选择具有最长公共前缀的重映射。

**Remix**:

[Remix](https://remix.ethereum.org/)为github提供了自动重新映射，并且还会自动通过网络检索文件：您可以通过`import "github.com/ethereum/dapp-bin/library/iterable_mapping.sol" as it_mapping;`导入可迭代映射。

其他源代码提供者可能会在未来添加。

## 注释

单行注释(`//`)和多行注释(`/*...*/`)是可用的。

```js
// 这是一条单线注释。

/*
    这是一个
    多行注释。
*/
```

此外，还有另一种类型的注释，称为`natspec`注释，文档尚未编写。
它们是用三斜杠(`///`)或双星号块(`/** ... * /`)编写的，它们应该直接用在函数声明或语句之上。
你可以在这些注释中使用[Doxygen](https://en.wikipedia.org/wiki/Doxygen)风格的标签来记录函数, 注释正式验证的条件, 并提供**确认文本**，当用户尝试调用函数时向用户显示.

在下面的例子中，我们记录了合同的标题，两个输入参数和两个返回值的解释。

```js
    pragma solidity ^0.4.0;

    /** @title 计算形状 */

    contract shapeCalculator {
        /** @dev 计算矩形的表面和周长。
          * @param w 矩形的宽度。
          * @param h 矩形的高度。
          * @return s 计算的表面
          * @return p 计算的周长。
          */
        function rectangle(uint w, uint h) returns (uint s, uint p) {
            s = w * h;
            p = 2 * (w + h);
        }
    }
```
