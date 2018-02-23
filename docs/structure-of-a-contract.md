# 合约结构

Solidity合同与面向对象语言中的类相似。
每个合约都可以包含`状态变量`，`函数`，`函数修饰符`，`事件`，`结构类型`和`枚举类型`。
此外，合同可以继承其他合同。

## 状态变量

状态变量是永久存储在合同存储中的值。

    pragma solidity ^0.4.0;

    contract SimpleStorage {
        uint storedData; // 状态变量
        // ...
    }

有关可用的可见性选择，请参见[types]()部分的有效状态变量类型和[visibility-and-getters]()。

## 函数

函数是合约内代码的可执行单元。

    pragma solidity ^0.4.0;

    contract SimpleAuction {
        function bid() public payable { // 函数
            // ...
        }
    }

[函数调用]()可以发生在内部或外部，并且对其他合约具有不同级别的可见性([visibility-and-getters]())。

## 函数修饰符

函数修饰符可用于以声明方式修改函数的语义(参见合同部分的[modifiers]())。

    pragma solidity ^0.4.11;

    contract Purchase {
        address public seller;

        modifier onlySeller() { // 修改
            require(msg.sender == seller);
            _;
        }

        function abort() public onlySeller { // 有用的修饰符
            // ...
        }
    }

活动

事件是EVM日志记录工具的便利接口。

    pragma solidity ^0.4.0;

    contract SimpleAuction {
        event HighestBidIncreased(address bidder, uint amount); // 事件

        function bid() public payable {
            // ...
            HighestBidIncreased(msg.sender, msg.value); // 触发事件
        }
    }

请参阅合同部分的[events]()以获取有关如何声明事件以及可以在dapp中使用的信息。

## 结构类型

结构是可以将多个变量分组的自定义定义类型(请参见类型部分中的[structs]())。

    pragma solidity ^0.4.0;

    contract Ballot {
        struct Voter { // 结构
            uint weight;
            bool voted;
            address delegate;
            uint vote;
        }
    }

## 枚举类型

枚举可用于创建具有有限数值集的自定义类型(请参见类型部分中的[enums]())。

    pragma solidity ^0.4.0;

    contract Purchase {
        enum State { Created, Locked, Inactive } // 枚举
    }
