# 单位和全局可用变量

## 以太币单位

字面数可以采用`wei`，`finney`，`szabo`或`ether`的后缀在Ether的子分类之间进行转换，其中没有后缀的Ether货币数字被假定为Wei，例如， ,`2 ether == 2000 finney`评估为`true`。

## 时间单位

可以使用文字数字后面的`seconds`，`minutes`，`hours`，`days`，`weeks`和`years`等后缀在时间单位之间进行转换，其中秒是基本单位，单位被认为是天真的,以下方法：

* `1 == 1 seconds`
* `1 minutes == 60 seconds`
* `1 hours == 60 minutes`
* `1 days == 24 hours`
* `1 weeks == 7 days`
* `1 years == 365 days`

请注意，如果您使用这些单位执行日历计算，因为由于[闰秒](https://en.wikipedia.org/wiki/Leap_second)，不是每年都等于365天，甚至每天也不会有24小时。
由于闰秒无法预测，因此必须通过外部oracle更新确切的日历库。

这些后缀不能应用于变量。
如果你想解释一些输入变量，例如,日子里，你可以通过以下方式做到这一点：

```js
    function f(uint start, uint daysAfter) public {
        if (now >= start + daysAfter * 1 days) {
          // ...
        }
    }
```

## 特殊变量和函数

全局名称空间中总是存在特殊的变量和函数，主要用于提供有关区块链的信息。

### 块和事务属性

* `block.blockhash(uint blockNumber) returns (bytes32)`: 给定块的哈希 - 仅适用于256个最新的块，不包括当前的块
* `block.coinbase` (`address`): 当前块矿工的地址
* `block.difficulty` (`uint`):  当前块难度
* `block.gaslimit` (`uint`):    当前块燃料限制
* `block.number` (`uint`): 当前程序段号
* `block.timestamp` (`uint`): 当前块时间戳记为自UNIX时期以来的秒数
* `msg.data` (`bytes`): 完成调用数据
* `msg.gas` (`uint`): 剩余燃料
* `msg.sender` (`address`): 消息的发送者(当前调用)
* `msg.sig` (`bytes4`): 调用数据的前四个字节(即功能标识符)
* `msg.value` (`uint`): 与消息一起发送的wei数量
* `now` (`uint`): 当前块时间戳(`block.timestamp`的别名)
* `tx.gasprice` (`uint`): 交易的燃料价格
* `tx.origin` (`address`): 交易的发件人(完整的调用链)

!!! note

    每个外部函数调用都可以更改`msg`的所有成员的值，包括`msg.sender`和`msg.value`。
    这包括调用库函数。

!!! note

    除非你知道你在做什么，否则不要依赖`block.timestamp`，`now`和`block.blockhash`作为随机源。

    在一定程度上，时间戳和块哈希都会受到矿工的影响。
    例如，采矿社区中的不良演员可以对选定的散列运行赌场支付功能，如果他们没有收到任何钱，只需重试一次不同的散列。

    当前块时间戳必须严格大于最后一个块的时间戳，但唯一的保证是它将位于规范链中两个连续块的时间戳之间的某处。

!!! note

    出于可伸缩性原因，块哈希不可用于所有块。
    您只能访问最近256个块的哈希，其他所有值都将为零。

### 错误处理

`assert(bool condition)`: 如果条件不满足则抛出 - 用于内部错误。

`require(bool condition)`: 如果条件未满足则抛出 - 用于输入或外部组件中的错误。

`revert()`: 中止执行并恢复状态更改

### 数学和加密函数

`addmod(uint x, uint y, uint k) returns (uint)`: 计算`(x + y)％k`，其中加法以任意的精度执行，并且不会在`2 ** 256`环绕。断言从0.5.0版开始`k！= 0`。

`mulmod(uint x, uint y, uint k) returns (uint)`: 计算`(x * y)％k`，其中乘法以任意精度执行，并且不会在`2 ** 256`环绕。断言从0.5.0版开始`k！= 0`。

`keccak256(...) returns (bytes32)`: 计算[(紧密排列)参数<abi_packed_mode>]()的Ethereum-SHA-3(Keccak-256)

`sha256(...) returns (bytes32)`: 计算[(紧密排列)参数<abi_packed_mode>]()的SHA-256哈希值

`sha3(...) returns (bytes32)`:  别名到`keccak256`

`ripemd160(...) returns (bytes20)`: 计算[(紧密排列)参数<abi_packed_mode>]()的RIPEMD-160哈希值

`ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) returns (address)`: 从椭圆曲线签名中恢复与公钥相关的地址，或者在出错时返回零([示例用法](https://ethereum.stackexchange.com/q/1777/222))

在上面，“紧密排列”意味着这些参数是连续的而没有填充。
这意味着以下几点完全相同：

    keccak256("ab", "c")
    keccak256("abc")
    keccak256(0x616263)
    keccak256(6382179)
    keccak256(97, 98, 99)

如果需要填充，可以使用显式类型转换：`keccak256(“x00x12”)`与`keccak256(uint16(0x12))`相同。

请注意，常量将使用存储它们所需的最小字节数打包。
这意味着，例如`keccak256(0)== keccak256(uint8(0))`和`keccak256(0x12345678)== keccak256(uint32(0x12345678))`。

这可能是因为您在*私人区块链*上遇到了`sha256`，`ripemd160`或`ecrecover`的Out-of-Gas。
其原因是这些实现为所谓的预编译合约，并且这些合约仅在他们收到第一条消息(尽管他们的合约代码是硬编码的)后才真正存在。
发送给不存在的合约的消息更加昂贵，因此执行会出现Out-of-Gas错误。
解决此问题的方法是首先发送,在您的实际合约中使用它们之前，每个合约都有1个魏。
这不是官方或测试网上的问题。

### 地址相关

`<address>.balance` (`uint256`): 魏的[地址](https://solidity.readthedocs.io/en/develop/types.html#address)的平衡

`<address>.transfer(uint256 amount)`: 发送给定量的魏到[地址](https://solidity.readthedocs.io/en/develop/types.html#address)，发生故障，转发2300天然气津贴，不可调整

`<address>.send(uint256 amount) returns (bool)`: 发送给定数量的魏给[address](https://solidity.readthedocs.io/en/develop/types.html#address)，失败返回`false`

`<address>.call(...) returns (bool)`: 发出低级`CALL`，失败返回`false`

`<address>.callcode(...) returns (bool)`: 发出低级`CALLCODE`，失败返回`false`

`<address>.delegatecall(...) returns (bool)`: 发出低级`DELEGATECALL`，失败返回`false`

有关更多信息，请参阅[地址](https://solidity.readthedocs.io/en/develop/types.html#address)部分。

!!! Warning

    使用`send`有一些危险：如果调用堆栈深度为1024(调用程序总是强制执行此操作)，则传输将失败，并且如果收件人用完了，它也会失败。
    所以为了安全的以太网传输，请务必检查`send`的返回值，最好使用`transfer`：在接收方提取资金的地方使用的一种模式。

!!! note

    `callcode`的使用是不鼓励的，将来会被删除。

### 合约报告

`this`(当前合约的类型)：当前合约，明确转换为[地址](https://solidity.readthedocs.io/en/develop/types.html#address)

`selfdestruct(address recipient)`：销毁当前合约，将资金发送给给定的[地址](https://solidity.readthedocs.io/en/develop/types.html#address)

`suicide(address recipient)`: 别名`selfdestruct`

此外，当前合约的所有功能都可以直接包含当前功能。