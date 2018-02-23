# 杂项

## 存储状态变量的布局

静态大小的变量(除映射和动态大小的数组类型之外的所有内容)都是从位置'0'开始连续放置在存储中的。
如果可能的话，需要少于32个字节的多个项目按照以下规则打包到一个存储插槽中：

- 存储槽中的第一项存储在低位对齐中。
- 基本类型只使用存储它们所需的那么多字节。
- 如果基本类型不适合存储插槽的其余部分，则将其移动到下一个存储插槽。
- 结构和数组数据总是会启动一个新的槽并占用整个槽(但是根据这些规则，结构或数组内的项会紧紧地压缩)。

!!! Warning

    使用小于32字节的元素时，您合同的天然气使用量可能会更高。
    这是因为EVM一次运行32个字节。
    因此，如果元素小于此值，则EVM必须使用更多操作才能将元素的大小从32个字节减小到所需的大小。

    如果您正在处理存储值，那么只使用减小尺寸的参数是有益的，因为编译器会将多个元素打包到一个存储槽中，从而将多个读取或写入组合到一个操作中。
    处理函数参数或内存值时，没有固有的好处，因为编译器不会打包这些值。

    最后，为了让EVM为此优化，请确保您尝试对存储变量和`struct`成员进行排序，以便它们可以紧密打包。
    例如，按照`uint128，uint128，uint256`而不是`uint128，uint256，uint128`的顺序声明存储变量，因为前者只占用两个存储空间，而后者占用三个空间。

结构和数组的元素会相互存储，就像明确地给出一样。

由于其大小不可预知，映射和动态大小的数组类型使用Keccak-256散列计算来查找值或数组数据的起始位置。
这些起始位置总是全堆栈插槽。

根据上述规则(或者通过递归地将该规则映射到映射或数组数组)，映射或动态数组本身占据存储在某个位置'p'的(未填充)槽。
对于动态数组，此槽存储数组中元素的数量(字节数组和字符串在这里是一个例外，见下文)。
对于映射，该槽未被使用(但是需要使得两个相同的映射在彼此之后将使用不同的散列分布)。
阵列数据位于`keccak256(p)`，对应于映射关键字'k`的值位于`keccak256(k .p)`，其中`.`是串联的。
如果该值又是非基本类型，则通过添加偏移量'keccak256(k .p)`来找到位置。

`bytes`和`string`将它们的数据存储在同一个插槽中，如果它们很短，那么也会存储长度。
特别是：如果数据长度最多为31个字节，则它存储在高位字节中(左对齐)，最低位字节存储“length * 2”。
如果时间更长，主槽存储`长度* 2 + 1'，并且数据像往常一样存储在`keccak256(slot)`中。

因此，对于以下合同片段：

    pragma solidity ^0.4.0;

    contract C {
        struct s { uint a; uint b; }
        uint x;
        mapping(uint => mapping(uint => s)) data;
    }

'data [4][9] .b`的位置在`keccak256(uint256(9).keccak256(uint256(4).uint256(1)))+ 1`。

## 内存中的布局

Solidity保留三个256位插槽：

- 0 - 64: 用于哈希方法的临时空间
- 64 - 96: 目前分配的内存大小(又称空闲内存指针)

语句之间可以使用临时空间(即在内联程序集内)。

Solidity始终将新对象放置在空闲内存指针上，内存永远不会释放(这可能会在未来发生变化)。

!!! Warning

    > Solidity中有一些操作需要大于64字节的临时内存区域，因此不适合临时空间。
    > 它们将被放置在空闲内存指向的位置，但由于其生命周期较短，指针不会更新。
    > 内存可能会或可能不会被清零。
    > 正因为如此，人们不应该期望自由内存被清零。

## 呼叫数据的布局

当部署Solidity合同并从账户调用时，假定输入数据采用[ABI规范<ABI>]()中的格式。
ABI规范要求将参数填充为32个字节的倍数。
内部函数调用使用不同的约定。

## 内部 - 清理变量

当某个值小于256位时，在某些情况下必须清除其余的位。
Solidity编译器设计用于在任何可能受其余位中潜在垃圾影响的操作之前清除这些剩余位。
例如，在将值写入存储器之前，需要清除其余位，因为存储器内容可用于计算散列值或作为消息调用的数据发送。
类似地，在将值存储在存储器中之前，需要清除其余位，否则可以观察到乱码值。

另一方面，如果紧接着的操作不受影响，我们不清除这些位。
例如，由于`JUMPI`指令将任何非零值视为`true`，所以我们在将它们用作`JUMPI`的条件之前不会清除布尔值。

除了上面的设计原理外，Solidity编译器还会在输入数据加载到堆栈时清除输入数据。

不同类型的清理无效值的规则有所不同：

|类型    |有效值    |无效值的意思
|-|-|-|
|enum of n members | 0 until n - 1 | 例外
|bool | 0 or 1 | 1
|signed integers | sign-extended word | 目前默默地包裹着; 将来会有异常情况发生
|unsigned integers | higher bits zeroed | 目前默默地包裹着; 将来会有异常情况发生

## 内部 - 优化器

Solidity优化器在装配上运行，所以它可以并且也被其他语言使用。
它将指令序列拆分为`JUMPs`和`JUMPDESTs`的基本块。
在这些块内部，分析指令，并且对堆栈，存储器或存储器的每个修改都被记录为表达式，该表达式包括指令和基本上指向其他表达式的参数列表的表达式。
现在主要想法是找到始终相等的表达式(在每个输入上)并将它们组合到一个表达式类中。
优化器首先尝试在已知表达式的列表中查找每个新表达式。
如果这不起作用，则根据诸如“常数+常数= sum_of_constants”或“X * 1 = X”的规则简化表达式。
由于这是递归完成的，所以如果第二个因子是一个更复杂的表达式，我们知道它总是会评估为1，那么我们也可以应用后一个规则。
对存储和内存位置的修改必须删除有关存储和内存位置的知识，这些知识并不是已知的不同：如果我们先写入位置x，然后写入位置y，并且都是输入变量，则第二个可能会覆盖第一个，所以我们,实际上在我们写给y之后不知道在x处存储了什么。
另一方面，如果表达式x  -  y的简化计算为非零常数，那么我们知道我们可以保存关于x中存储的内容的知识。

在这个过程结束时，我们知道最后哪些表达式必须在堆栈上，并且有一个修改内存和存储的列表。
该信息与基本块一起存储并用于链接它们。
此外，关于堆栈，存储和内存配置的知识被转发到下一个块。
如果我们知道所有“JUMP”和“JUMPI”指令的目标，我们就可以构建一个完整的程序流程图。
如果只有一个我们不知道的目标(原则上可能发生，跳跃目标可以从输入计算)，我们必须消除关于块输入状态的所有知识，因为它可能是未知的目标， ,JUMP`。
如果发现一个JUMPI，其条件评估为一个常量，它将被转换为无条件跳转。

作为最后一步，每个块中的代码都会完全重新生成。
从块的结尾处的表达式创建依赖关系图，并且不是该图的一部分的每个操作都基本上被丢弃。
现在生成的代码会按照原始代码中的顺序将修改应用于内存和存储(删除已发现不需要的修改)，最后生成需要在堆栈中正确显示的所有值,地点。

这些步骤适用于每个基本块，如果较小，则新生成的代码将用作替换。
如果在JUMPI处分割一个基本块并在分析过程中，条件评估为一个常量，则根据常量的值替换JUMPI，因此代码就像

    var x = 7;
    data[7] = 9;
    if (data[x] != x + 2)
        return 2;
    else
        return 1;

被简化为也可以编译的代码

    data[7] = 9;
    return 1;

即使指令在开始时包含跳转。

## 源映射

作为AST输出的一部分，编译器提供AST中相应节点所代表的源代码范围。
这可以用于各种用途，从用于报告基于AST的错误的静态分析工具和突出显示局部变量及其用途的调试工具。

此外，编译器还可以生成从字节码到生成该指令的源代码范围的映射。
对于在字节码级别上运行的静态分析工具，以及在调试器中显示源代码中的当前位置或处理断点，这一点同样重要。

这两种源映射都使用整数标识符来引用源文件。
这些是通常称为``sourceList'`的源文件列表的常规数组索引，它是json / npm编译器的组合json和输出的一部分。

AST内部的源映射使用以下表示法：`s：l：f`

其中`s`是源文件中范围起始处的字节偏移量，`l`是源范围的长度(以字节为单位)，`f`是上面提到的源索引。

字节码的源映射中的编码更加复杂：它是由`;`分隔的`s：l：f：j`列表。
每个元素都对应一条指令，即不能使用字节偏移量，但必须使用指令偏移量(按下指令比单个字节长)。
字段's`，`l`和`f`如上所述，`j`可以是`i`，`o`或`-`，表示跳转指令是进入函数，从函数返回还是,作为例如一部分的常规跳转,一个循环。

为了压缩这些源映射，尤其是字节码，使用以下规则：

- 如果一个字段为空，则使用前一个元素的值。
- 如果缺少`：`，则以下所有字段都将被视为空。

这意味着以下源映射表示相同的信息：

`1:2:1;1:9:1;2:1:2;2:1:2;2:1:2`

`1:2:1;:9;2::2;;`

## 技巧和窍门

- 使用数组上的`delete`来删除它的所有元素。
- 对结构元素使用较短的类型并对它们进行排序，以便将短类型组合在一起。这可以降低天然气成本，因为多个“SSTORE”操作可能合并为一个(“SSTORE”成本5000或20000气体，所以这是您想要优化的)。 使用天然气价格估算器(启用优化器)来检查！
- 公开你的状态变量 - 编译器会自动为你创建[getters](visibility-and-getters.md)。
- 如果最终检查输入条件或在函数的开始处声明很多，请尝试使用[修饰符]().
- 如果您的合同有一个名为`send`的函数，但您想使用内置的send函数，请使用`address(contractVariable).send(amount)`。
- 用一个赋值初始化存储结构：`x = MyStruct({a：1，b：2});`

## 备忘单

### 运算符优先级

以下是按评估顺序列出的运算符的优先顺序。

| 优先级 | 描述 | 运算符 |
|-|-|-|
| *1* | 后缀增量和减量 | `++`, `--` |
| *1* | 新的表达 | `new <typename>` |
| *1* | 数组下标 | `<array>[<index>]` |
| *1* | 成员访问 | `<object>.<member>` |
| *1* | 函数调用 | `<func>(<args...>)` |
| *1* | 括号 | `(<statement>)` |
| *2* | 前缀增量和减量 | `++`, `--` |
| *2* | 一元正负号 | `+`, `-` |
| *2* | 一元操作 | `delete` |
| *2* | 逻辑否 | `!` |
| *2* | 按位否 | `~` |
| *3* | 幂 | `**` |
| *4* | 乘法,除法和模 | `*`, `/`, `%` |
| *5* | 加减 | `+`, `-` |
| *6* | 移位运算符 | `<<`, `>>` |
| *7* | 按位与 | `&` |
| *8* | 按位异或 | `^` |
| *9* | 按位或 | `|` |
| *10* | 不等运算符 | `<`, `>`, `<=`, `>=` |
| *11* | 等运算符 | `==`, `!=` |
| *12* | 逻辑和 | `&&` |
| *13* | 逻辑或 | `||` |
| *14* | 三元运算符 | `<conditional> ? <if-true> : <if-false>` |
| *15* | 赋值运算符 | `=`, `|=`, `^=`, `&=`, `<<=`, `>>=`, `+=`, `-=`, `*=`, `/=`, `%=` |
| *16* | 逗号运算符 | `,` |

### 全局变量

- `block.blockhash(uint blockNumber) returns (bytes32)`: 给定块的散列 - 仅适用于256个最新块
- `block.coinbase` (`address`): 当前块矿工的地址
- `block.difficulty` (`uint`): 目前的阻挡困难
- `block.gaslimit` (`uint`): 当前阻止gaslimit
- `block.number` (`uint`): 当前程序段号
- `block.timestamp` (`uint`): 当前块时间戳
- `msg.data` (`bytes`): 完成calldata
- `msg.gas` (`uint`): 剩余的气体
- `msg.sender` (`address`): 消息的发送者(当前呼叫)
- `msg.value` (`uint`): 与消息一起发送的wei数量
- `now` (`uint`): 当前块时间戳(block'timestamp的别名)
- `tx.gasprice` (`uint`): 交易的天然气价格
- `tx.origin` (`address`): 交易的发件人(完整的呼叫链)
- `assert(bool condition)`: 如果条件为“假”，则中止执行并恢复状态更改(用于内部错误)
- `require(bool condition)`: 如果条件为“假”，则中止执行并恢复状态更改(用于格式错误的输入或外部组件中的错误)
- `revert()`: 中止执行并恢复状态更改
- `keccak256(...) returns (bytes32)`: compute the Ethereum-SHA-3 (Keccak-256) hash of the [(tightly packed) arguments <abi_packed_mode>]()
- `sha3(...) returns (bytes32)`: an alias to `keccak256`
- `sha256(...) returns (bytes32)`: compute the SHA-256 hash of the [(tightly packed) arguments <abi_packed_mode>]()
- `ripemd160(...) returns (bytes20)`: compute the RIPEMD-160 hash of the [(tightly packed) arguments <abi_packed_mode>]()
- `ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) returns (address)`: 从椭圆曲线签名恢复与公钥相关的地址，错误时返回零
- `addmod(uint x, uint y, uint k) returns (uint)`: 计算`(x + y)％k`，其中加法以任意的精度执行，并且不会在`2 ** 256`环绕。,断言从0.5.0版开始`k！= 0`。
- `mulmod(uint x, uint y, uint k) returns (uint)`: 计算`(x * y)％k`，其中乘法以任意精度执行，并且不会在`2 ** 256`环绕。,断言从0.5.0版开始`k！= 0`。
- `this` (current contract's type): 目前的合同，明确可转换为“地址”
- `super`: 继承层次结构中高一级的合同
- `selfdestruct(address recipient)`: 销毁当前的合同，将资金转到给定的地址
- `suicide(address recipient)`: “selfdestruct”的别名
- `<address>.balance` (`uint256`): 魏的[地址]()的平衡
- `<address>.send(uint256 amount) returns (bool)`: 发送给定数量的魏给[address]()，失败时返回`false`
- `<address>.transfer(uint256 amount)`: 发给魏的量给[地址]()，抛出失败

### 函数可见性说明符

    function myFunction() <visibility specifier> returns (bool) {
        return true;
    }

- `public`: 在外部和内部可见(为存储/状态变量创建一个[getter函数<getter-functions>]())
- `private`: 只在当前合同中可见
- `external`: 只在外部可见(仅用于函数) - 即只能被称为消息(通过`this.func`)
- `internal`: 只在内部可见

### 修饰符

- `pure` 用户函数: 不允许修改或访问状态 - 这还没有执行。
- `view` 用户函数: 不允许修改状态 - 这还没有执行。
- `payable` 用户函数: 允许他们在接到电话的同时接收Ether。
- `constant` 为状态变量: 允许他们在接到电话的同时接收Ether。
- `constant` 用户函数: 与`view`相同。
- `anonymous` 为事件: 不会将事件签名存储为主题。
- `indexed` 用于事件参数: 将参数存储为主题。

### 保留关键字

这些关键字保留在Solidity中。
它们可能成为未来语法的一部分：

`abstract`, `after`, `case`, `catch`, `default`, `final`, `in`,
`inline`, `let`, `match`, `null`, `of`, `relocatable`, `static`,
`switch`, `try`, `type`, `typeof`.

### 语言语法

```
SourceUnit = (PragmaDirective | ImportDirective | ContractDefinition)*

// Pragma actually parses anything up to the trailing ';' to be fully forward-compatible.
PragmaDirective = 'pragma' Identifier ([^;]+) ';'

ImportDirective = 'import' StringLiteral ('as' Identifier)? ';'
        | 'import' ('*' | Identifier) ('as' Identifier)? 'from' StringLiteral ';'
        | 'import' '{' Identifier ('as' Identifier)? ( ',' Identifier ('as' Identifier)? )* '}' 'from' StringLiteral ';'

ContractDefinition = ( 'contract' | 'library' | 'interface' ) Identifier
                     ( 'is' InheritanceSpecifier (',' InheritanceSpecifier )* )?
                     '{' ContractPart* '}'

ContractPart = StateVariableDeclaration | UsingForDeclaration
             | StructDefinition | ModifierDefinition | FunctionDefinition | EventDefinition | EnumDefinition

InheritanceSpecifier = UserDefinedTypeName ( '(' Expression ( ',' Expression )* ')' )?

StateVariableDeclaration = TypeName ( 'public' | 'internal' | 'private' | 'constant' )? Identifier ('=' Expression)? ';'
UsingForDeclaration = 'using' Identifier 'for' ('*' | TypeName) ';'
StructDefinition = 'struct' Identifier '{'
                     ( VariableDeclaration ';' (VariableDeclaration ';')* )? '}'

ModifierDefinition = 'modifier' Identifier ParameterList? Block
ModifierInvocation = Identifier ( '(' ExpressionList? ')' )?

FunctionDefinition = 'function' Identifier? ParameterList
                     ( ModifierInvocation | StateMutability | 'external' | 'public' | 'internal' | 'private' )*
                     ( 'returns' ParameterList )? ( ';' | Block )
EventDefinition = 'event' Identifier EventParameterList 'anonymous'? ';'

EnumValue = Identifier
EnumDefinition = 'enum' Identifier '{' EnumValue? (',' EnumValue)* '}'

ParameterList = '(' ( Parameter (',' Parameter)* )? ')'
Parameter = TypeName StorageLocation? Identifier?

EventParameterList = '(' ( EventParameter (',' EventParameter )* )? ')'
EventParameter = TypeName 'indexed'? Identifier?

FunctionTypeParameterList = '(' ( FunctionTypeParameter (',' FunctionTypeParameter )* )? ')'
FunctionTypeParameter = TypeName StorageLocation?

// semantic restriction: mappings and structs (recursively) containing mappings
// are not allowed in argument lists
VariableDeclaration = TypeName StorageLocation? Identifier

TypeName = ElementaryTypeName
         | UserDefinedTypeName
         | Mapping
         | ArrayTypeName
         | FunctionTypeName

UserDefinedTypeName = Identifier ( '.' Identifier )*

Mapping = 'mapping' '(' ElementaryTypeName '=>' TypeName ')'
ArrayTypeName = TypeName '[' Expression? ']'
FunctionTypeName = 'function' FunctionTypeParameterList ( 'internal' | 'external' | StateMutability )*
                   ( 'returns' FunctionTypeParameterList )?
StorageLocation = 'memory' | 'storage'
StateMutability = 'pure' | 'constant' | 'view' | 'payable'

Block = '{' Statement* '}'
Statement = IfStatement | WhileStatement | ForStatement | Block | InlineAssemblyStatement |
            ( DoWhileStatement | PlaceholderStatement | Continue | Break | Return |
              Throw | SimpleStatement ) ';'

ExpressionStatement = Expression
IfStatement = 'if' '(' Expression ')' Statement ( 'else' Statement )?
WhileStatement = 'while' '(' Expression ')' Statement
PlaceholderStatement = '_'
SimpleStatement = VariableDefinition | ExpressionStatement
ForStatement = 'for' '(' (SimpleStatement)? ';' (Expression)? ';' (ExpressionStatement)? ')' Statement
InlineAssemblyStatement = 'assembly' StringLiteral? InlineAssemblyBlock
DoWhileStatement = 'do' Statement 'while' '(' Expression ')'
Continue = 'continue'
Break = 'break'
Return = 'return' Expression?
Throw = 'throw'
VariableDefinition = ('var' IdentifierList | VariableDeclaration) ( '=' Expression )?
IdentifierList = '(' ( Identifier? ',' )* Identifier? ')'

// Precedence by order (see github.com/ethereum/solidity/pull/732)
Expression
  = Expression ('++' | '--')
  | NewExpression
  | IndexAccess
  | MemberAccess
  | FunctionCall
  | '(' Expression ')'
  | ('!' | '~' | 'delete' | '++' | '--' | '+' | '-') Expression
  | Expression '**' Expression
  | Expression ('*' | '/' | '%') Expression
  | Expression ('+' | '-') Expression
  | Expression ('<<' | '>>') Expression
  | Expression '&' Expression
  | Expression '^' Expression
  | Expression '|' Expression
  | Expression ('<' | '>' | '<=' | '>=') Expression
  | Expression ('==' | '!=') Expression
  | Expression '&&' Expression
  | Expression '||' Expression
  | Expression '?' Expression ':' Expression
  | Expression ('=' | '|=' | '^=' | '&=' | '<<=' | '>>=' | '+=' | '-=' | '*=' | '/=' | '%=') Expression
  | PrimaryExpression

PrimaryExpression = BooleanLiteral
                  | NumberLiteral
                  | HexLiteral
                  | StringLiteral
                  | TupleExpression
                  | Identifier
                  | ElementaryTypeNameExpression

ExpressionList = Expression ( ',' Expression )*
NameValueList = Identifier ':' Expression ( ',' Identifier ':' Expression )*

FunctionCall = Expression '(' FunctionCallArguments ')'
FunctionCallArguments = '{' NameValueList? '}'
                      | ExpressionList?

NewExpression = 'new' TypeName
MemberAccess = Expression '.' Identifier
IndexAccess = Expression '[' Expression? ']'

BooleanLiteral = 'true' | 'false'
NumberLiteral = ( HexNumber | DecimalNumber ) (' ' NumberUnit)?
NumberUnit = 'wei' | 'szabo' | 'finney' | 'ether'
           | 'seconds' | 'minutes' | 'hours' | 'days' | 'weeks' | 'years'
HexLiteral = 'hex' ('"' ([0-9a-fA-F]{2})* '"' | '\'' ([0-9a-fA-F]{2})* '\'')
StringLiteral = '"' ([^"\r\n\\] | '\\' .)* '"'
Identifier = [a-zA-Z_$] [a-zA-Z_$0-9]*

HexNumber = '0x' [0-9a-fA-F]+
DecimalNumber = [0-9]+ ( '.' [0-9]* )? ( [eE] [0-9]+ )?

TupleExpression = '(' ( Expression? ( ',' Expression? )*  )? ')'
                | '[' ( Expression  ( ',' Expression  )*  )? ']'

ElementaryTypeNameExpression = ElementaryTypeName

ElementaryTypeName = 'address' | 'bool' | 'string' | 'var'
                   | Int | Uint | Byte | Fixed | Ufixed

Int = 'int' | 'int8' | 'int16' | 'int24' | 'int32' | 'int40' | 'int48' | 'int56' | 'int64' | 'int72' | 'int80' | 'int88' | 'int96' | 'int104' | 'int112' | 'int120' | 'int128' | 'int136' | 'int144' | 'int152' | 'int160' | 'int168' | 'int176' | 'int184' | 'int192' | 'int200' | 'int208' | 'int216' | 'int224' | 'int232' | 'int240' | 'int248' | 'int256'

Uint = 'uint' | 'uint8' | 'uint16' | 'uint24' | 'uint32' | 'uint40' | 'uint48' | 'uint56' | 'uint64' | 'uint72' | 'uint80' | 'uint88' | 'uint96' | 'uint104' | 'uint112' | 'uint120' | 'uint128' | 'uint136' | 'uint144' | 'uint152' | 'uint160' | 'uint168' | 'uint176' | 'uint184' | 'uint192' | 'uint200' | 'uint208' | 'uint216' | 'uint224' | 'uint232' | 'uint240' | 'uint248' | 'uint256'

Byte = 'byte' | 'bytes' | 'bytes1' | 'bytes2' | 'bytes3' | 'bytes4' | 'bytes5' | 'bytes6' | 'bytes7' | 'bytes8' | 'bytes9' | 'bytes10' | 'bytes11' | 'bytes12' | 'bytes13' | 'bytes14' | 'bytes15' | 'bytes16' | 'bytes17' | 'bytes18' | 'bytes19' | 'bytes20' | 'bytes21' | 'bytes22' | 'bytes23' | 'bytes24' | 'bytes25' | 'bytes26' | 'bytes27' | 'bytes28' | 'bytes29' | 'bytes30' | 'bytes31' | 'bytes32'

Fixed = 'fixed' | ( 'fixed' [0-9]+ 'x' [0-9]+ )

Ufixed = 'ufixed' | ( 'ufixed' [0-9]+ 'x' [0-9]+ )

InlineAssemblyBlock = '{' AssemblyItem* '}'

AssemblyItem = Identifier | FunctionalAssemblyExpression | InlineAssemblyBlock | AssemblyLocalBinding | AssemblyAssignment | AssemblyLabel | NumberLiteral | StringLiteral | HexLiteral
AssemblyLocalBinding = 'let' Identifier ':=' FunctionalAssemblyExpression
AssemblyAssignment = ( Identifier ':=' FunctionalAssemblyExpression ) | ( '=:' Identifier )
AssemblyLabel = Identifier ':'
FunctionalAssemblyExpression = Identifier '(' AssemblyItem? ( ',' AssemblyItem )* ')'

```
