# 使用编译器

## 使用命令行编译器

Solidity存储库的一个构建目标是`solc`，solidity命令行编译器。
使用`solc --help`为您提供所有选项的解释。
编译器可以生成各种输出，范围从简单的二进制文件和汇编到抽象语法树(解析树)，以估计天然气使用情况。
如果你只想编译一个文件，你可以像`solc --bin sourceFile.sol`那样运行它，它会打印二进制文件。
在部署合同之前，请在使用`solc --optimize --bin sourceFile.sol`编译时激活优化器。
如果你想得到`solc`的一些更高级的输出变体，最好告诉它使用`solc -o outputDirectory --bin --ast --asm sourceFile.sol`输出所有东西来分离文件。

命令行编译器会自动从文件系统中读取导入的文件，但也可以通过以下方式使用`prefix = path`来提供路径重定向：

    solc github.com/ethereum/dapp-bin/=/usr/local/lib/dapp-bin/=/usr/local/lib/fallback file.sol

这本质上指示编译器搜索以`/usr/local/lib/dapp-bin`下的`github.com/ethereum/dapp-bin/`开始的任何内容，如果它没有在那里找到该文件，它将查看,`/usr/local/lib/fallback`(空的前缀总是匹配)。
`solc`不会读取文件系统中位于重映射目标之外和显式指定的源文件所在目录之外的文件，所以`import`/etc/passwd`;`只适用于添加了`=/,`作为重映射。

如果由于重映射而存在多个匹配，则选择具有最长公共前缀的那个匹配。

出于安全原因，编译器限制了它可以访问的目录。
在命令行中指定的源文件的路径(及其子目录)和通过重映射定义的路径可用于导入语句，但其他所有内容都被拒绝。
可以通过`--allow-paths/sample/path,/another/sample/path`开关允许其他路径(及其子目录)。

如果您的合同使用[libraries](libraries.md)，您会注意到该字节码包含`__LibraryName ______`形式的子字符串。
您可以使用`solc`作为链接器，这意味着它将在这些位置为您插入库地址：

为你的命令添加`--libraries'Math：0x12345678901234567890 Heap：0xabcdef0123456'`为每个库提供一个地址或者将该字符串存储在一个文件中(每行一个库)并使用`--library fileName`运行`solc` ,。

如果使用选项`--link`调用`solc`，则所有输入文件在上面给出的`__LibraryName ____`格式中被解释为未链接的二进制文件(十六进制编码)，并就地链接(如果输入被读取,从标准输入写入标准输出)。
在这种情况下，除了`--libraries`之外的所有选项都被忽略(包括`-o`)。

如果使用选项`--standard-json`调用`solc`，则它将在标准输入上期望JSON输入(如下所述)，并在标准输出上返回JSON输出。

## 编译器输入和输出JSON描述

这些JSON格式由编译器API使用，也可以通过`solc`获得。
这些可能会发生变化，有些字段是可选的(如上所述)，但其目的仅在于进行向后兼容的更改。

编译器API需要JSON格式的输入，并以JSON格式的输出输出编译结果。

评论当然是不允许的，这里仅用于解释目的。

### 输入描述

```json
{
 //必需：源代码语言，如`Solidity`，`蛇`，`lll`，`程序集`等。
  language: "Solidity",
 //需要
  sources:
  {
   //这里的关键字是源文件的`全局`名称，导入可以通过重新映射使用其他文件(请参见下文)。
    "myFile.sol":
    {
     //可选：源文件的keccak256散列
     //它用于验证通过URL导入的检索内容。
      "keccak256": "0x123...",
     //必需(除非使用`内容`，请参阅下文)：源文件的URL。
     //应按此顺序导入URL，并根据keccak256散列(如果可用)检查结果。
     //如果散列不匹配或者没有一个URL导致成功，则应该引发错误。
      "urls":
      [
        "bzzr://56ab...",
        "ipfs://Qma...",
        "file:///tmp/path/to/file.sol"
      ]
    },
    "mortal":
    {
     //可选：源文件的keccak256散列
      "keccak256": "0x234...",
     //必需(除非使用`urls`)：源文件的文字内容
      "content": "contract mortal is owned { function kill() { if (msg.sender == owner) selfdestruct(owner); } }"
    }
  },
 //可选的
  settings:
  {
   //可选：分类重新映射列表
    remappings: [ ":g/dir" ],
   //可选：优化器设置(启用默认为false)
    optimizer: {
      enabled: true,
      runs: 500
    },
   //元数据设置(选项
    metadata: {
     //只使用文字内容而不使用URL(默认为false)
      useLiteralContent: true
    },
   //图书馆的地址。
   //如果不是所有库都在这里给出，它可能会导致输出数据不同的未链接对象。
    libraries: {
     //顶级密钥是使用库的源文件的名称。
     //如果使用重新映射，则在应用重新映射后，此源文件应与全局路径匹配。
     //如果此键是空字符串，则表示全局级别。
      "myFile.sol": {
        "MyLib": "0x123123..."
      }
    }
   //以下可用于选择所需的输出。
   //如果这个字段被忽略，那么编译器会加载并执行类型检查，但除了错误之外不会生成任何输出。
   //第一级密钥是文件名，第二级是合同名称，空合同名称是指文件本身，而明星是指所有合同。
   //
   //可用的输出类型如下所示：
   //  abi - ABI
   //  ast - 所有源文件的AST
   //  legacyAST - 所有源文件的传统AST
   //  devdoc - 开发者文档(natspec)
   //  userdoc - 用户文档(natspec)
   //  metadata - 元数据
   //  ir - 脱钩前的新汇编格式
   //  evm.assembly - 脱钩后的新汇编格式
   //  evm.legacyAssembly - JSON中的旧式汇编格式
   //  evm.bytecode.object - 字节码对象
   //  evm.bytecode.opcodes - 操作码列表
   //  evm.bytecode.sourceMap - 源映射(用于调试)
   //  evm.bytecode.linkReferences - 链接引用(如果未链接的对象)
   //  evm.deployedBytecode* - 部署的字节码(与evm.bytecode具有相同的选项)
   //  evm.methodIdentifiers - 函数哈希列表
   //  evm.gasEstimates - 功能气体估计
   //  ewasm.wast - eWASM S表达式格式(不支持atm)
   //  ewasm.wasm - eWASM二进制格式(不支持atm)
   //
   //请注意，使用`evm`，`evm.bytecode`，`ewasm`等将选择该输出的每个目标部分。
   //另外，`*`可以用作通配符来请求所有内容。
   //
    outputSelection: {
     //启用每个合约的元数据和字节码输出。
      "*": {
        "*": [ "metadata", "evm.bytecode" ]
      },
     //启用文件def中定义的MyContract的abi和opcodes输出。
      "def": {
        "MyContract": [ "abi", "evm.bytecode.opcodes" ]
      },
     //启用每个合同的源图输出。
      "*": {
        "*": [ "evm.bytecode.sourceMap" ]
      },
     //启用每个文件的传统AST输出。
      "*": {
        "": [ "legacyAST" ]
      }
    }
  }
}
```

### 输出说明

```json
{
 //可选：如果没有遇到错误/警告，则不存在
  errors: [
    {
     //可选：源文件中的位置。
      sourceLocation: {
        file: "sourceFile.sol",
        start: 0,
        end: 100
      ],
     //强制性：错误类型，例如`TypeError`，`InternalCompilerError`，`Exception`等。
     //请参阅下面的完整类型列表。
      type: "TypeError",
     //强制性：发生错误的组件，例如`一般`，`ewasm`等
      component: "general",
     //强制性(`错误`或`警告`)
      severity: "error",
     //强制性
      message: "Invalid keyword"
     //可选：用源位置格式化的消息
      formattedMessage: "sourceFile.sol:100: Invalid keyword"
    }
  ],
 //这包含文件级输出。
 //可以通过outputSelection设置来限制/过滤。
  sources: {
    "sourceFile.sol": {
     //标识符(用于源地图)
      id: 1,
     //AST对象
      ast: {},
     //传统的AST对象
      legacyAST: {}
    }
  },
 //这包含合同级别的输出。
 //如果使用的语言没有合同名称，则该字段应该等于一个空字符串。
  contracts: {
    "sourceFile.sol": {
     //如果使用的语言没有合同名称，则该字段应该等于一个空字符串。
      "ContractName": {
       //以太坊合同ABI。
       //如果为空，则表示为空数组。
       //查看 https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI
        abi: [],
       //请参阅元数据输出文档(序列化的JSON字符串)
        metadata: "{...}",
       //用户文档(natspec)
        userdoc: {},
       //开发者文档(natspec)
        devdoc: {},
       //中间表示(字符串)
        ir: "",
       //与EVM相关的输出
        evm: {
         //大会(字符串)
          assembly: "",
         //旧式组件(对象)
          legacyAssembly: {},
         //字节码和相关细节。
          bytecode: {
           //字节码作为十六进制字符串。
            object: "00fe",
           //操作码列表(字符串)
            opcodes: "",
           //源映射为字符串。
           //请参阅源映射定义。
            sourceMap: "",
           //如果给出，这是一个未链接的对象。
            linkReferences: {
              "libraryFile.sol": {
               //字节偏移到字节码中。
               //链接取代了那里的20个字节。
                "Library1": [
                  { start: 0, length: 20 },
                  { start: 200, length: 20 }
                ]
              }
            }
          },
         //与上面相同的布局。
          deployedBytecode: { },
         //函数哈希列表
          methodIdentifiers: {
            "delegate(address)": "5c19a95c"
          },
         //功能气体估计
          gasEstimates: {
            creation: {
              codeDepositCost: "420000",
              executionCost: "infinite",
              totalCost: "infinite"
            },
            external: {
              "delegate(address)": "25000"
            },
            internal: {
              "heavyLifting()": "infinite"
            }
          }
        },
       //eWASM相关输出
        ewasm: {
         //S表达式格式
          wast: "",
         //二进制格式(十六进制字符串)
          wasm: ""
        }
      }
    }
  }
}
```

#### 错误类型

1. `JSONError`: JSON输入不符合所需的格式，例如,输入不是JSON对象，不支持该语言等。
2. `IOError`: IO和导入处理错误，例如在所提供的源中无法解析的URL或散列不匹配。
3. `ParserError`: 源代码不符合语言规则。
4. `DocstringParsingError`: 注释块中的NatSpec标签无法解析。
5. `SyntaxError`: 语法错误，如`continue`在`for`循环之外使用。
6. `DeclarationError`: 无效的，无法解析的或冲突的标识符名称。,例如,没有找到标识符
7. `TypeError`: 类型系统中的错误，例如无效类型转换，无效分配等。
8. `UnimplementedFeatureError`: 功能不被编译器支持，但预计将在未来版本中受支持。
9. `InternalCompilerError`: 在编译器中触发的内部错误 - 这应该被报告为一个问题。
10. `Exception`: 编译期间未知的失败 - 这应该被报告为一个问题。
11. `CompilerError`: 编译器堆栈的使用无效 - 这应该被报告为一个问题。
12. `FatalError`: 致命错误没有被正确处理 - 这应该被报告为一个问题。
13. `Warning`: 一个警告，并没有停止编译，但应尽可能解决。