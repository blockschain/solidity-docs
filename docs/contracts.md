# 合约

Solidity合约与面向对象语言中的类相似。
它们包含可以修改这些变量的状态变量和函数中的持久数据。
在不同的契约(实例)上调用函数将执行EVM函数调用，从而切换上下文以使状态变量不可访问。

## 创建合约

合约可以通过以太坊交易或从Solidity合约中`从外部`创建。

IDE(如[Remix][1])使用UI元素使创建过程无缝。

在Ethereum上以编程方式创建合约最好通过使用JavaScript API [web3.js][2]完成。
截至今天，它有一个名为[web3.eth.Contract][3]的方法来促进合约创建。

创建合约时，其构造函数(与合约名称相同的函数)将执行一次。
构造函数是可选的。
只允许一个构造函数，这意味着不支持超载。

在内部，构造函数参数在合约本身的代码之后传递[ABI编码的<ABI>][1]，但如果使用`web3.js`，则不需要关心这个。

如果合约要创建另一个合约，则创建者必须知道所创建合约的源代码(和二进制文件)。
这意味着循环创建依赖是不可能的。

    pragma solidity ^0.4.16;

    contract OwnedToken {
        // TokenCreator是下面定义的合约类型。
        // 只要不用于创建新合约，引用它就很好。

        TokenCreator creator;
        address owner;
        bytes32 name;

        // 这是注册创建者和分配名称的构造函数。

        function OwnedToken(bytes32 _name) public {
            // 状态变量通过它们的名字而不是通过例如,this.owner。,这也适用于函数，特别是在构造函数中，您只能像这样称呼它们(`内部`)，因为合约本身还不存在。

            owner = msg.sender;

            // 我们做了一个从`address`到`TokenCreator`的显式类型转换，并假定调用合约的类型是TokenCreator，没有真正的方法来检查它。

            creator = TokenCreator(msg.sender);
            name = _name;
        }

        function changeName(bytes32 newName) public {
            // 只有创建者可以更改名称，因为合约可以隐式转换为地址，因此可以进行比较。

            if (msg.sender == address(creator))
                name = newName;
        }

        function transfer(address newOwner) public {

            // 只有当前所有者才能传送令牌。
            // if (msg.sender != owner) return;
            // 我们还想询问创建者转移是否正常。请注意，这将调用下面定义的合约的一个函数。如果调用失败(例如，由于燃料不足)，则立即停止执行。

            if (creator.isTokenTransferOK(owner, newOwner))
                owner = newOwner;
        }
    }

    contract TokenCreator {
        function createToken(bytes32 name)
           public
           returns (OwnedToken tokenAddress)
        {
            // 创建一个新的令牌合约并返回它的地址。
            // 从JavaScript方面来说，返回类型只是`地址`，因为这是ABI中最接近的类型。

            return new OwnedToken(name);
        }

        function changeName(OwnedToken tokenAddress, bytes32 name)  public {
            // 同样，`tokenAddress`的外部类型就是`address`。

            tokenAddress.changeName(name);
        }

        function isTokenTransferOK(address currentOwner, address newOwner)
            public
            view
            returns (bool ok)
        {
            // 检查一些任意的情况。
            address tokenAddress = msg.sender;
            return (keccak256(newOwner) & 0xff) == (bytes20(tokenAddress) & 0xff);
        }
    }

## 能见度和吸气剂

由于Solidity知道两种函数调用(不产生实际EVM调用的内部函数(也称为`消息调用`)和外部函数调用)，函数和状态变量有四种类型的可见性。

函数可以被指定为`external`，`public`，`internal`或`private`，默认为`public`。
对于状态变量，`external`不可能，默认是`internal`。

`external`: 外部功能是合约界面的一部分，这意味着可以从其他合约和交易中调用它们。外部函数`f`不能在内部调用(即`f[1]`不起作用，但`this.f[1]`起作用)。外部函数在接收大量数据时有时更高效。

`public`: 公共职能是合约接口的一部分，可以在内部或通过消息调用。对于公共状态变量，会生成一个自动获取器函数(见下文)。

`internal`: 这些函数和状态变量只能在内部进行访问(即从当前合约或从中派生的合约内)，而不使用`this`。

`private`: 私有函数和状态变量仅对它们在其中定义的合约而不在派生的合约中可见。

!!! Note

    所有外部观察者都可以看到合约内的所有内容。
    制作`私人`的东西只会阻止其他合约访问和修改信息，但在区块链之外，整个世界仍然可以看到它。

可见性说明符在状态变量的类型之后以及函数的参数列表和返回参数列表之间给出。

    pragma solidity ^0.4.16;

    contract C {
        function f(uint a) private pure returns (uint b) { return a + 1; }
        function setData(uint a) internal { data = a; }
        uint public data;
    }

在下面的例子中，`D`，可以调用`c.getData[1]`来检索状态存储中`data`的值，但不能调用`f`。
合约`E`来自`C`，因此可以调用`compute`。

    // 这不会编译

    pragma solidity ^0.4.0;

    contract C {
        uint private data;

        function f(uint a) private returns(uint b) { return a + 1; }
        function setData(uint a) public { data = a; }
        function getData[1] public returns(uint) { return data; }
        function compute(uint a, uint b) internal returns (uint) { return a+b; }
    }

    contract D {
        function readData[1] public {
            C c = new C[1];
            uint local = c.f(7); // error: member `f` is not visible
            c.setData(3);
            local = c.getData[1];
            local = c.compute(3, 5); // error: member `compute` is not visible
        }
    }

    contract E is C {
        function g[1] public {
            C c = new C[1];
            uint val = compute(3, 5); // access to internal member (from derived to parent contract)
        }
    }

### Getter函数

编译器自动为所有** public **状态变量创建getter函数。
对于下面给出的合约，编译器将生成一个名为`data`的函数，它不接受任何参数并返回一个`uint`，即状态变量`data`的值。
状态变量的初始化可以在声明中完成。

    pragma solidity ^0.4.0;

    contract C {
        uint public data = 42;
    }

    contract Caller {
        C c = new C[1];
        function f[1] public {
            uint local = c.data[1];
        }
    }

吸气剂功能具有外部可见性。
如果符号在内部被访问(即没有`this.`)，则它被评估为状态变量。
如果它是外部访问的(即用`this.`)，则它被评估为一个函数。

    pragma solidity ^0.4.0;

    contract C {
        uint public data;
        function x[1] public {
            data = 3; // 内部访问
            uint val = this.data[1]; // 外部访问
        }
    }

下一个例子有点复杂:

    pragma solidity ^0.4.0;

    contract Complex {
        struct Data {
            uint a;
            bytes3 b;
            mapping (uint => uint) map;
        }
        mapping (uint => mapping(bool => Data[])) public data;
    }

它将生成以下形式的功能:

    function data(uint arg1, bool arg2, uint arg3) public returns (uint a, bytes3 b) {
        a = data[arg1][arg2][arg3].a;
        b = data[arg1][arg2][arg3].b;
    }

请注意，结构中的映射被省略，因为没有提供映射关键的好方法。

## 功能修饰符

修饰符可以用来轻松改变函数的行为。
例如，他们可以在执行该功能之前自动检查一个条件。
修饰符是合约的可继承属性，可能会被衍生合约覆盖。

    pragma solidity ^0.4.11;

    contract owned {
        function owned[1] public { owner = msg.sender; }
        address owner;

        // 该合约只定义了一个修饰符，但不使用它：它将用于衍生合约。
        // 函数体插入修饰符定义中出现的特殊符号'_;`的位置。
        // 这意味着如果所有者调用此函数，则会执行该函数，否则将抛出异常。

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
    }

    contract mortal is owned {
        // 该合约从`owned`继承'onlyOwner`修饰符，并将其应用于`close`函数，这会导致只有在存储所有者创建`close`时才会产生效果。

        function close[1] public onlyOwner {
            selfdestruct(owner);
        }
    }

    contract priced {
        // 修饰符可以接收参数：
        modifier costs(uint price) {
            if (msg.value >= price) {
                _;
            }
        }
    }

    contract Register is priced, owned {
        mapping (address => bool) registeredAddresses;
        uint price;

        function Register(uint initialPrice) public { price = initialPrice; }

        // 在这里也提供`付款'关键字是很重要的，否则这个功能会自动拒绝发送给它的所有以太网。

        function register[1] public payable costs(price) {
            registeredAddresses[msg.sender] = true;
        }

        function changePrice(uint _price) public onlyOwner {
            price = _price;
        }
    }

    contract Mutex {
        bool locked;
        modifier noReentrancy[1] {
            require(!locked);
            locked = true;
            _;
            locked = false;
        }

        // 该函数受互斥锁保护，这意味着`msg.sender.call`中的重入调用不能​​再次调用`f`。
        // 'return 7'语句将7赋值给返回值，但仍然在修饰符中执行'locked = false'语句。

        function f[1] public noReentrancy returns (uint) {
            require(msg.sender.call[1]);
            return 7;
        }
    }

通过在一个空白分隔的列表中指定多个修饰符并按照所给出的顺序对其进行评估。

!!! Warning

    在早期版本的Solidity中，具有修饰符的函数中的`return`语句表现不同。

来自修饰符或函数体的显式返回仅保留当前修饰符或函数体。
返回变量被赋值并且控制流程在前一个修改器中的`_`之后继续。

允许任意表达式用于修饰符参数，在此上下文中，从该函数可见的所有符号在修饰符中可见。
在修饰符中引入的符号在函数中不可见(因为它们可能会通过覆盖来更改)。

## 恒定状态变量

状态变量可以声明为`常量`。
在这种情况下，它们必须从编译时的常量表达式中分配。
任何访问存储，区块链数据(例如`now`，`this.balance`或`block.number`)或执行数据(`msg.gas`)或调用外部合约的表达式都是不允许的。
对内存分配可能有副作用的表达式是允许的，但对其他内存对象可能有副作用的表达式则不允许。
允许内置函数`keccak256`，`sha256`，`ripemd160`，`ecrecover`，`addmod`和`mulmod`(尽管它们确实调用了外部契约)。

在内存分配器上允许副作用的原因是应该可以构造复杂的对象，例如，,查找表。
此功能尚未完全可用。

编译器不会为这些变量预留存储空间，并且每个事件都会被各自的常量表达式(可能会被优化器计算为单个值)替换。

并非所有类型的常量都在此时执行。
唯一支持的类型是值类型和字符串。

    pragma solidity ^0.4.0;

    contract C {
        uint constant x = 32**22 + 8;
        string constant text = "abc";
        bytes32 constant myHash = keccak256("abc");
    }

## 函数

### 查看功能

函数可以被声明为`view`，在这种情况下他们保证不修改状态。

以下声明被视为修改状态：

1. 写入状态变量。
2. [发射事件<events>][1].
3. [创建其他合约<creating-contracts>][1].
4. 使用`selfdestruct`。
5. 通过电话发送以太。
6. 调用任何未标记为`视图`或`纯`的函数。
7. 使用低级别呼叫。
8. 使用包含某些操作码的内联汇编。

    pragma solidity ^0.4.16;

    contract C {
        function f(uint a, uint b) public view returns (uint) {
            return a * (b + 42) + now;
        }
    }

!!! Note

    `constant`是`view`的别名。

!!! Note

    Getter方法被标记为`view`。

!!! Warning

    编译器还没有强制`view`方法没有修改状态。

### 纯函数

函数可以声明为`pure`，在这种情况下，它们承诺不读取或修改状态。

除了上面解释的状态修改语句列表之外，以下内容被认为是从状态中读取的：

1. 使用包含某些操作码的内联汇编。
2. 访问`this.balance`或`<address> .balance`。
3. 访问`block`，`tx`，`msg`的任何成员(除`msg.sig`和`msg.data`外)。
4. 调用任何未标记为`pure`的函数。
5. 使用包含某些操作码的内联汇编。

    pragma solidity ^0.4.16;

    contract C {
        function f(uint a, uint b) public pure returns (uint) {
            return a * (b + 42);
        }
    }

!!! Warning

    编译器还没有强制执行`pure`方法不能读取状态。

### 后备功能

合约可以有一个未命名的功能。
这个函数不能有参数，也不能返回任何东西。
如果没有任何其他函数与给定的函数标识符匹配(或者根本没有提供数据)，它将在对合约的调用中执行。

此外，只要合约收到普通以太网(无数据)，就会执行此功能。
此外，为了接收以太网，后备功能必须标记为`应付`。
如果不存在此类功能，则合约无法通过正常交易接收以太币。

在这种情况下，函数调用通常只有很少的燃料(准确地说，2300个燃料)，所以重要的是使后备函数尽可能便宜。
请注意，调用回退函数的交易(而不是内部呼叫)所需的天然气要高得多，因为每次交易都会额外收取21000瓦斯或更多的费用，用于签名检查等事情。

特别是，以下操作会消耗比提供给回退功能的津贴更多的天然气：

- 写入存储
- 创建合约
- 调用消耗大量燃料的外部函数
- 发送以太币

请确保您在部署合约之前彻底测试您的后备功能，以确保执行成本低于2300瓦斯。

!!! Note

    即使回退函数不能有参数，仍然可以使用`msg.data`来检索随该调用提供的任何有效内容。

!!! Warning

    直接接收Ether的合约(没有函数调用，即使用`send`或`transfer`)，但没有定义回退函数会抛出异常，发回Ether(这在Solidity v0.4.0之前是不同的)。
    所以如果你想让你的合约接收Ether，你必须实现一个后备功能。

!!! Warning

    没有应付回退功能的合约可以接收以太网作为coinbase交易(又名矿工区块奖励)的收件人或作为`selfdestruct`的目的地。

    合约不能对这种以太币传输作出反应，因此也不能拒绝它们。
    这是EVM的设计选择，而且Solidity无法解决这个问题。

    这也意味着`this.balance`可以高于合约中实施的一些手工记帐的总和(即，具有在退回功能中更新的计数器)。

```solidity
    pragma solidity ^0.4.0;

    contract Test {
        // 所有发送到此合约的消息都会调用此函数(没有其他函数)。
        // 向此合约发送以太网会导致异常，因为后退功能没有`应付`修饰符。
        function[1] public { x = 1; }
        uint x;
    }


    // 这个合约让所有以太网发送给它，没有办法让它恢复。
    contract Sink {
        function[1] public payable { }
    }

    contract Caller {
        function callTest(Test test) public {
            test.call(0xabcdef01); // 哈希不是前
            // results in test.x becoming == 1.
            // 以下内容不能编译，但即使有人向该合约发送了以太，该交易也会失败并拒绝以太网。
            // test.send(2 ether);
        }
    }
```

### 函数重载

合约可以具有多个具有相同名称但具有不同参数的功能。
这也适用于继承功能。
以下示例显示了在`A`合约范围内重载`f`函数。

    pragma solidity ^0.4.16;

    contract A {
        function f(uint _in) public pure returns (uint out) {
            out = 1;
        }

        function f(uint _in, bytes32 _key) public pure returns (uint out) {
            out = 2;
        }
    }

重载功能也存在于外部接口中。
如果两个外部可见函数的Solidity类型不同而不是它们的外部类型不同，这是错误的。

    // 这不会编译
    pragma solidity ^0.4.16;

    contract A {
        function f(B _in) public pure returns (B out) {
            out = _in;
        }

        function f(address _in) public pure returns (address out) {
            out = _in;
        }
    }

    contract B {
    }

上述两个`f`函数重载最终都会接受ABI的地址类型，尽管它们在Solidity内部被认为是不同的。

#### 重载解析和参数匹配

通过将当前作用域中的函数声明与函数调用中提供的参数进行匹配来选择重载函数。
如果所有参数都可以隐式转换为预期类型，则函数被选为超载候选。
如果没有确切的一个候选人，则解决失败。

!!! Note

    重载分辨率不考虑返回参数。

```solidity
    pragma solidity ^0.4.16;

    contract A {
        function f(uint8 _in) public pure returns (uint8 out) {
            out = _in;
        }

        function f(uint256 _in) public pure returns (uint256 out) {
            out = _in;
        }
    }
```

调用`f(50)`会产生一个类型错误，因为`250`可以隐式转换为`uint8`和`uint256`类型。
另一方面`f(256)`会解析为'f(uint256)`重载，因为`256`不能隐式转换为`uint8`。

## 活动

事件允许方便地使用EVM日志记录工具，后者又可用于在用于监听这些事件的dapp的用户界面中`调用`JavaScript回调。

活动是可继承的合约成员。
当它们被调用时，它们会使参数存储在事务日志中 - 区块链中的特殊数据结构。
这些日志与合约的地址相关联，并且只要可访问块(永远为Frontier和Homestead，但这可能会随着Serenity而改变)，将被并入区块链并停留在区块链中。
记录和事件数据不能从合约内访问(甚至不能从创建它们的合约中访问)。

可以使用日志的SPV证明，因此如果外部实体提供这种证明的合约，它可以检查日志是否确实存在于区块链中。
但请注意，必须提供块头，因为合约只能看到最后的256块散列。

最多三个参数可以接收`indexed`属性，这会导致搜索各个参数：可以在用户界面中筛选索引参数的特定值。

如果使用数组(包括`string`和`bytes`)作为索引参数，它的Keccak-256哈希将被存储为topic。

事件签名的散列是除了用`匿名`说明符声明事件外的其中一个主题。
这意味着无法通过名称筛选特定的匿名事件。

所有非索引参数都将存储在日志的数据部分中。

!!! Note

    索引参数不会自行存储。
    您只能搜索这些值，但不可能自行检索这些值。

```solidity
    pragma solidity ^0.4.0;

    contract ClientReceipt {
        event Deposit(
            address indexed _from,
            bytes32 indexed _id,
            uint _value
        );

        function deposit(bytes32 _id) public payable {
            // 任何对此函数的调用(甚至是深度嵌套)都可以通过过滤调用`Deposit`的JavaScript API来检测。
            Deposit(msg.sender, _id, msg.value);
        }
    }
```

JavaScript API中的用法如下:

    var abi = /* abi as generated by the compiler */;
    var ClientReceipt = web3.eth.contract(abi);
    var clientReceipt = ClientReceipt.at("0x1234...ab67" /* address */);

    var event = clientReceipt.Deposit[1];

    // 留意变化
    event.watch(function(error, result){
        // result will contain various information
        // including the argumets given to the `Deposit`
        // call.
        if (!error)
            console.log(result);
    });

    // 或者通过回拨立即开始观看
    var event = clientReceipt.Deposit(function(error, result) {
        if (!error)
            console.log(result);
    });

### 对日志的低级接口

也可以通过函数`log0`，`log1`，`log2`，`log3`和`log4`来访问记录机制的底层接口。
`logi`采用`bytes32`类型的`i + 1`参数，其中第一个参数将用于日志的数据部分，其他部分用作主题。
上面的事件调用可以按照与上面相同的方式执行

    pragma solidity ^0.4.10;

    contract C {
        function f[1] public payable {
            bytes32 _id = 0x420042;
            log3(
                bytes32(msg.value),
                bytes32(0x50cb9fe53daa9737b786ab3646f04d0150dc50ef4e75f59509d83667ad5adb20),
                bytes32(msg.sender),
                _id
            );
        }
    }

其中长十六进制数等于`keccak256(`Deposit(address，hash256，uint256)`)`，事件的签名。

### 了解活动的其他资源

- [Javascript文档][5]
- [事件的示例用法][6]
- [如何在js中访问它们][7]

## 遗产

通过复制包括多态性的代码，Solidity支持多重继承。

所有的函数调用都是虚拟的，这意味着调用了大多数派生函数，除非明确给出了合约名称。

当合约从多个合约中继承时，只会在区块链上创建单个合约，并将所有基础合约中的代码复制到创建的合约中。

一般继承系统与[Python][4]非常相似，特别是关于多重继承。

以下示例中给出了详细信息。

    pragma solidity ^0.4.16;

    contract owned {
        function owned[1] { owner = msg.sender; }
        address owner;
    }

    // 使用`is`来从另一个合约中派生出来。
    // 派生合约可以访问所有非私有成员，包括内部函数和状态变量。
    // 虽然这些不能通过`this`从外部访问。

    contract mortal is owned {
        function kill[1] {
            if (msg.sender == owner) selfdestruct(owner);
        }
    }

    // 仅提供这些抽象合约以使编译器知道接口。
    // 请注意没有主体的功能。
    // 如果合约没有实现所有功能，它只能用作接口。

    contract Config {
        function lookup(uint id) public returns (address adr);
    }

    contract NameReg {
        function register(bytes32 name) public;
        function unregister[1] public;
     }

    // 多重继承是可能的。
    // 请注意，`owned`也是`mortal`的基类，但只有一个`owned'的实例(就C ++中的虚拟继承而言)。

    contract named is owned, mortal {
        function named(bytes32 name) {
            Config config = Config(0xD5f9D8D94886E70b06E474c3fB14Fd43E2f23970);
            NameReg(config.lookup(1)).register(name);
        }

        // 函数可以被具有相同名称和相同数量/类型输入的另一个函数覆盖。
        // 如果覆盖函数具有不同类型的输出参数，则会导致错误。
        // 本地和基于消息的函数调用都将这些覆盖考虑在内。

        function kill[1] public {
            if (msg.sender == owner) {
                Config config = Config(0xD5f9D8D94886E70b06E474c3fB14Fd43E2f23970);
                NameReg(config.lookup(1)).unregister[1];
                // It is still possible to call a specific
                // overridden function.
                mortal.kill[1];
            }
        }
    }

    // 如果一个构造函数接受一个参数，它就需要在头文件中提供(或者派生契约的构造函数中的modifier-invocation-style(见下文))。

    contract PriceFeed is owned, mortal, named("GoldFeed") {
       function updateInfo(uint newInfo) public {
          if (msg.sender == owner) info = newInfo;
       }

       function get[1] public view returns(uint r) { return info; }

       uint info;
    }

请注意，上面我们称`mortal.kill[1]`为`转发`销毁请求。
这样做的方式是有问题的，如以下示例所示：

    pragma solidity ^0.4.0;

    contract owned {
        function owned[1] public { owner = msg.sender; }
        address owner;
    }

    contract mortal is owned {
        function kill[1] public {
            if (msg.sender == owner) selfdestruct(owner);
        }
    }

    contract Base1 is mortal {
        function kill[1] public { /* do cleanup 1 */ mortal.kill[1]; }
    }

    contract Base2 is mortal {
        function kill[1] public { /* do cleanup 2 */ mortal.kill[1]; }
    }

    contract Final is Base1, Base2 {
    }

调用`Final.kill[1]`会调用`Base2.kill`作为派生最重要的覆盖，但这个函数将绕过`Base1.kill`，主要是因为它甚至不知道'Base1`。

The way around this is to use `super`:

    pragma solidity ^0.4.0;

    contract owned {
        function owned[1] public { owner = msg.sender; }
        address owner;
    }

    contract mortal is owned {
        function kill[1] public {
            if (msg.sender == owner) selfdestruct(owner);
        }
    }

    contract Base1 is mortal {
        function kill[1] public { /* do cleanup 1 */ super.kill[1]; }
    }


    contract Base2 is mortal {
        function kill[1] public { /* do cleanup 2 */ super.kill[1]; }
    }

    contract Final is Base1, Base2 {
    }

如果`Base2`调用`super`函数，它不会简单地在它的一个基本合约上调用这个函数。
相反，它在最终继承图中的下一个基础合约上调用该函数，因此它将调用`Base1.kill[1]`(请注意，最终继承序列是 - 从派生最多的合约开始：Final，Base2，Base1 ,，凡人，拥有)。
使用super时调用的实际函数在使用它的类的上下文中是未知的，尽管其类型是已知的。
这对于普通的虚拟方法查找是相似的。

### 基础构造函数的参数

派生契约需要提供基础构造函数所需的所有参数。

这可以通过两种方式完成：

    pragma solidity ^0.4.0;

    contract Base {
        uint x;
        function Base(uint _x) public { x = _x; }
    }

    contract Derived is Base(7) {
        function Derived(uint _y) Base(_y * _y) public {
        }
    }

一种方法是直接在继承列表中(`Base(7)`)。
另一种方式是在派生构造函数的头部(`Base(_y * _y)`)中调用修饰符。
如果构造函数参数是一个常量并且定义合约的行为或描述它，第一种实现方法更为方便。
如果基础的构造函数参数取决于衍生合约的构造函数参数，则必须使用第二种方法。
如果像在这个愚蠢的例子中一样，使用这两个地方，那么修饰语风格的参数优先。

### 多重继承和线性化

允许多重继承的语言必须处理几个问题。
一个是[钻石问题][8]。
Solidity遵循Python的路径，并使用`[C3线性化][9]`来强制基类的DAG中的特定顺序。
这导致单调性的理想特性，但不允许某些继承图。
尤其是，在`is`指令中给出基类的顺序很重要。
在下面的代码中，Solidity会给出错误`继承图的线性化不可能`。

    // This will not compile

    pragma solidity ^0.4.0;

    contract X {}
    contract A is X {}
    contract C is A, X {}

原因是`C`请求``X'来重载`A`(通过按顺序指定`A，X`)，但是`A`本身请求重载`X`，这是一个不可能的矛盾,解决。

要记住的一个简单规则是按照`最基类`到`最多派生`的顺序​​指定基类。

### 继承不同类型的同名会员

当继承导致具有相同名称的函数和修饰符的契约时，它被视为错误。
这个错误也是由同名的事件和修饰符以及同名的函数和事件产生的。
作为一个例外，状态变量getter可以覆盖公共函数。

## 抽象合约

合约函数可能缺少如下例所示的实现(请注意，函数声明头以`;`结尾)：

    pragma solidity ^0.4.0;

    contract Feline {
        function utterance[1] public returns (bytes32);
    }

这些合约不能被编译(即使它们包含已实现的功能以及未实现的功能)，但它们可以用作基本合约：

    pragma solidity ^0.4.0;

    contract Feline {
        function utterance[1] public returns (bytes32);
    }

    contract Cat is Feline {
        function utterance[1] public returns (bytes32) { return "miaow"; }
    }

如果合约继承自抽象合约，并且没有通过覆盖来实现所有未实现的功能，它本身就是抽象的。

## 接口

接口与抽象契约类似，但它们不能实现任何功能。
还有其他限制：

1. 无法继承其他合约或接口。
2. 无法定义构造函数。
3. 无法定义变量。
4. 无法定义结构。
5. 无法定义枚举。

这些限制中的一些可能在未来取消。

接口基本上仅限于合约ABI可以表示的内容，并且ABI和接口之间的转换应该是可能的，而不会丢失任何信息。

接口由它们自己的关键字表示：

    pragma solidity ^0.4.11;

    interface Token {
        function transfer(address recipient, uint amount) public;
    }

合约可以继承接口，因为它们会继承其他合约。

## 库

库与契约类似，但其用途是它们只在特定地址部署一次，并使用EVM的DELEGATECALL(CALLCODE，直到Homestead)功能重用其代码。
这意味着，如果调用库函数，它们的代码将在调用合约的上下文中执行，即`this`指向调用合约，特别是可以访问来自调用合约的存储。
由于库是一段独立的源代码，因此它只能访问调用协定的状态变量(如果它们被明确提供)(否则无法命名它们)。
如果库函数不修改状态(即，它们是`view`或`pure`函数)，则只能直接调用库函数(即不使用`DELEGATECALL`)，因为库被假定为无状态。
特别是，除非Solidity的类型系统被规避，否则不可能破坏库。

库可以被视为使用它们的合约的隐含基础合约。
它们在继承层次结构中不会显式可见，但对库函数的调用看起来就像调用显式基础合约的函数(如果`L`是库的名称，则为`L.f[1]`)。
此外，库的`内部`功能在所有合约中都是可见的，就像库是基础合约一样。
当然，对内部函数的调用使用内部调用约定，这意味着可以传递所有内部类型，并且内存类型将通过引用传递并且不会被复制。
为了在EVM中实现这一点，内部库函数和其中调用的所有函数的代码将在编译时被拉入到调用合约中，并且将使用常规的`JUMP`调用而不是`DELEGATECALL`。

以下示例说明了如何使用库(但请务必查看[使用对于<using-for>][1]以获得更高级的示例以实现集合)。

    pragma solidity ^0.4.16;

    library Set {
      // 我们定义了一个新的结构数据类型，用于在调用合约中保存其数据。

      struct Data { mapping(uint => bool) flags; }

      // 请注意，第一个参数是`存储引用`类型，因此只有其存储地址而不是其内容作为调用的一部分传递。
      // 这是库函数的一个特殊功能。
      // 如果可以将该函数看作是该对象的一种方法，那么调用第一个参数`self`是习惯用法。

      function insert(Data storage self, uint value)
          public
          returns (bool)
      {
          if (self.flags[value])
              return false; // already there
          self.flags[value] = true;
          return true;
      }

      function remove(Data storage self, uint value)
          public
          returns (bool)
      {
          if (!self.flags[value])
              return false; // not there
          self.flags[value] = false;
          return true;
      }

      function contains(Data storage self, uint value)
          public
          view
          returns (bool)
      {
          return self.flags[value];
      }
    }

    contract C {
        Set.Data knownValues;

        function register(uint value) public {
            // 因为`实例`将是当前合约，所以库函数可以在没有特定实例的情况下被调用。
            require(Set.insert(knownValues, value));
        }
        // 在这个合约中，我们也可以直接访问knownValues.flags，如果我们想的话。
    }

当然，您不必遵循这种方式来使用库：它们也可以在不定义结构数据类型的情况下使用。
功能也可以在没有任何存储参考参数的情况下工作，并且它们可以具有多个存储参考参数并且在任何位置。

对`Set.contains`，`Set.insert`和`Set.remove`的调用都被编译为调用(DELEGATECALL)到外部契约/库。
如果使用库，请注意执行实际的外部函数调用。
(msg.sender`，`msg.value`和`this`将在这次调用中保留它们的值，但是(在Homestead之前，因为使用了`CALLCODE`，`msg.sender`和`msg.value` ,，但)。

下面的例子显示了如何在库中使用内存类型和内部函数，以实现自定义类型，而无需外部函数调用的开销：

    pragma solidity ^0.4.16;

    library BigInt {
        struct bigint {
            uint[] limbs;
        }

        function fromUint(uint x) internal pure returns (bigint r) {
            r.limbs = new uint[](1);
            r.limbs[0] = x;
        }

        function add(bigint _a, bigint _b) internal pure returns (bigint r) {
            r.limbs = new uint[](max(_a.limbs.length, _b.limbs.length));
            uint carry = 0;
            for (uint i = 0; i < r.limbs.length; ++i) {
                uint a = limb(_a, i);
                uint b = limb(_b, i);
                r.limbs[i] = a + b + carry;
                if (a + b < a || (a + b == uint(-1) && carry > 0))
                    carry = 1;
                else
                    carry = 0;
            }
            if (carry > 0) {
                // too bad, we have to add a limb
                uint[] memory newLimbs = new uint[](r.limbs.length + 1);
                for (i = 0; i < r.limbs.length; ++i)
                    newLimbs[i] = r.limbs[i];
                newLimbs[i] = carry;
                r.limbs = newLimbs;
            }
        }

        function limb(bigint _a, uint _limb) internal pure returns (uint) {
            return _limb < _a.limbs.length ? _a.limbs[_limb] : 0;
        }

        function max(uint a, uint b) private pure returns (uint) {
            return a > b ? a : b;
        }
    }

    contract C {
        using BigInt for BigInt.bigint;

        function f[1] public pure {
            var x = BigInt.fromUint(7);
            var y = BigInt.fromUint(uint(-1));
            var z = x.add(y);
        }
    }

由于编译器无法知道库的部署位置，所以这些地址必须由链接器填充到最终的字节码中(有关如何使用命令行编译器进行链接，请参阅命令行编译器)。
如果地址未作为编译器的参数给出，编译的十六进制代码将包含形式为__Set ______的占位符(其中`Set`是库的名称)。
地址可以通过用库合约地址的十六进制编码替换所有这40个符号来手动填充。

与合约相比，库的限制：

- 没有状态变量
- 不能继承，也不能继承
- 无法接收以太

(这些可能会在稍后解除。)

### 呼叫保护的库

正如介绍中提到的，如果一个库的代码是使用`CALL`而不是`DELEGATECALL`或`CALLCODE`执行的，除非调用`view`或`pure`函数，否则它将会恢复。

EVM没有提供直接的方式让合约检测是否使用`CALL`调用它，但合约可以使用`ADDRESS`操作码来找出它当前正在运行的`哪里`。
生成的代码将此地址与施工时使用的地址进行比较，以确定呼叫模式。

更具体地说，库的运行时代码始终以一个推送指令开始，该指令在编译时为20个字节的零。
部署代码运行时，该常量在内存中被当前地址替换，并且此修改的代码存储在合约中。
在运行时，这会导致部署时间地址成为第一个被压入堆栈的常量，并且调度程序代码会将当前地址与此常量进行比较，以查看任何非视图和非纯函数。

## 使用For

可以使用指令`将A用于B;`来将库函数(从库`A`)连接到任何类型(`B`)。
这些函数将接收它们作为第一个参数被调用的对象(就像Python中的`self`变量)。

`将A用于*;`的效果是库`A`的函数被附加到任何类型。

在这两种情况下，都会附加所有函数，即使第一个参数的类型与对象的类型不匹配的函数也是如此。
在函数被调用的地方检查类型并执行函数重载解析。

`使用A for B;`指令对当前作用域是有效的，该作用域目前仅限于一个合约，但稍后将被提升到全局作用域，这样通过包含一个模块，其数据类型(包括库函数),不得不添加进一步的代码。

让我们以这种方式重写库中的设置示例:

    pragma solidity ^0.4.16;

    // 这是与以前相同的代码，只是没有评论
    library Set {
      struct Data { mapping(uint => bool) flags; }

      function insert(Data storage self, uint value)
          public
          returns (bool)
      {
          if (self.flags[value])
            return false; // already there
          self.flags[value] = true;
          return true;
      }

      function remove(Data storage self, uint value)
          public
          returns (bool)
      {
          if (!self.flags[value])
              return false; // not there
          self.flags[value] = false;
          return true;
      }

      function contains(Data storage self, uint value)
          public
          view
          returns (bool)
      {
          return self.flags[value];
      }
    }

    contract C {
        using Set for Set.Data; // 这是至关重要的变化
        Set.Data knownValues;

        function register(uint value) public {
            // 在这里，Set.Data类型的所有变量都有相应的成员函数。
            // 以下函数调用与`Set.insert(knownValues，value)`相同
            require(knownValues.insert(value));
        }
    }

以这种方式扩展基本类型也是可能的：

    pragma solidity ^0.4.16;

    library Search {
        function indexOf(uint[] storage self, uint value)
            public
            view
            returns (uint)
        {
            for (uint i = 0; i < self.length; i++)
                if (self[i] == value) return i;
            return uint(-1);
        }
    }

    contract C {
        using Search for uint[];
        uint[] data;

        function append(uint value) public {
            data.push(value);
        }

        function replace(uint _old, uint _new) public {
            // This performs the library function call
            uint index = data.indexOf(_old);
            if (index == uint(-1))
                data.push(_new);
            else
                data[index] = _new;
        }
    }

请注意，所有库调用都是实际的EVM函数调用。
这意味着如果你传递了内存或值类型，就会执行一个副本，甚至是'self`变量。
唯一不执行复制的情况是使用存储引用变量时。

[1]: https://remix.ethereum.org/
[2]: https://github.com/ethereum/web3.js
[3]: https://web3js.readthedocs.io/en/1.0/web3-eth-contract.html#new-contract
[4]: https://docs.python.org/3/tutorial/classes.html#inheritance
[5]: https://github.com/ethereum/wiki/wiki/JavaScript-API#contract-events
[6]: https://github.com/debris/smart-exchange/blob/master/lib/contracts/SmartExchange.sol
[7]: https://github.com/debris/smart-exchange/blob/master/lib/exchange_transactions.js
[8]: https://en.wikipedia.org/wiki/Multiple_inheritance#The_diamond_problem
[9]: https://en.wikipedia.org/wiki/C3_linearization