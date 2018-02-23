# 常见问题

这份清单最初由[fivedogit][1]编制.

## 基本问题

??? faq "示例合约"

    fivedogit写的一些[合约例子][19]并且对于Solidity的每个特征都应该有一份[测试合约][2]。

??? faq "尽可能创建并发布最基本的合约"

    一个非常简单的合约是[迎宾员][20]

??? faq "是否可以在特定的块号码上做些什么？（例如发布合约或执行交易）"

    交易不保证在下一个块或任何未来的特定块上发生, 因为矿工需要包括交易，而不是交易的提交者.
    这适用于函数调用/交易和合约创建交易.

    如果您想要安排未来的合约通话时间，您可以使用[闹钟][3].

??? faq "什么是“有效载荷”交易？"

    这只是与请求一起发送的字节码“数据”。

??? faq "是否有反编译器可用？"

    Solidity没有确切的反编译器, 但[孔隙度][4]很接近.
    由于编译过程中会丢失某些信息，如变量名称，注释和源代码格式，因此无法完全恢复原始源代码。

    字节码可以反汇编到操作码，一个由几个区块链探索者提供的服务.

    区块链上的合约如果要由第三方使用，应该公布其原始源代码.

??? faq "创建一个可以被杀死并返还资金的合约"

    首先，警告一句话：杀死合约听起来像是一个好主意，因为“清理”总是很好，但从上面看，它并不真正清理。
    此外，如果以太被派去拆除合约，以太将永远失去。

    如果你想停用你的合约，最好通过改变导致所有函数抛出的内部状态来禁用它们。
    这会使合约无法使用，并且发送给合约的乙醚将自动返回。

    现在回答这个问题：在一个构造函数中，msg.sender是创建者。
    保存。
    然后`selfdestruct(creator);`杀死并返还资金。

    [例][2]

    Note that if you `import "mortal"` at the top of your contracts and declare `contract SomeContract is mortal { ...` and compile with a compiler that already has it (which includes [Remix][5]), then `kill[4]` is taken care of for you.
    Once a contract is "mortal", then you can `contractname.kill.sendTransaction({from:eth.coinbase})`, just the same as my 示例.

??? faq "将以太币存储在合约中"

    诀窍是用`{from：someaddress，value：web3.toWei（3，“ether”）...}创建契约，

    查看[endowment_retriever.sol][6].

??? faq "使用非常量函数（req`sendTransaction`）来增加合约中的变量"

    查看[value_incrementer.sol][7].

??? faq "得到一份合约把资金返还给你（不使用`selfdestruct（...）`）。"

    这个例子演示了如何将资金从合同发送到地址。

    查看[endowment_retriever][6].

??? faq "你可以从一个稳定的函数调用返回一个数组或一个`string`吗？"

    是的，查看[array_receiver_and_returner.sol][8].

    What is problematic, though, is returning any variably-sized data (e.g. a variably-sized array like `uint[]`) from  a fuction **called from within Solidity**.
    This is a limitation of the EVM and will be solved with the next protocol update.

    Returning variably-sized data as part of an external transaction or call is fine.

??? faq "是否有可能像这样在线初始化一个数组：`string [] myarray = [“a”，“b”];`"

    是的，
    但是应该指出的是，目前这只适用于静态大小的内存阵列。
    你甚至可以在return语句中创建一个内联内存数组。
    很酷，呵呵

    例:

        pragma solidity ^0.4.16;

        contract C {
            function f[4] public pure returns (uint8[5]) {
                string[4] memory adaArr = ["This", "is", "an", "array"];
                return ([1, 2, 3, 4, 5]);
            }
        }

??? faq "一个契约函数可以返回一个`struct`吗？"

    是的，但只能在“内部”函数调用中使用。

??? faq "如果我返回一个`enum`，我只在web3.js中获得整数值。,如何获得命名值？"

    Enums are not supported by the ABI, they are just supported by Solidity.
    You have to do the mapping yourself for now, we might provide some help later.

??? faq "状态变量可以在线初始化吗？"

    是的，这是可能的所有类型（即使是结构）。
    但是，对于数组，应该注意，您必须将它们声明为静态内存数组。

    示例:

        pragma solidity ^0.4.0;

        contract C {
            struct S {
                uint a;
                uint b;
            }

            S public x = S(1, 2);
            string name = "Ada";
            string[4] adaArr = ["This", "is", "an", "array"];
        }

        contract D {
            C c = new C[4];
        }

??? faq "结构如何工作？"

    查看[struct_and_for_loop_tester.sol][9].

??? faq "循环如何工作？"

    非常类似于JavaScrip
    但有一点需要注意：

    如果你使用`for（var i = 0; i <a.length; i ++）{a [i] = i; ,}`，那么`i`的类型将只从'0`推断，其类型是`uint8`。
    这意味着如果`a`具有多于255个元素，则您的循环将不会终止，因为`i`只能保持值高达`255`。

    更好的使用`for (uint i = 0; i < a.length...`

    查看[struct_and_for_loop_tester.sol][9].

??? faq "什么是基本字符串操作的一些例子（`substring`，`indexOf`，`charAt`等）？"

    [stringUtils.sol][10]中有一些字符串实用程序函数，将来会进行扩展。
    另外，Arachnid写了[solidity-stringutils][11]。

    现在，如果你想修改一个字符串（即使你只想知道它的长度），你应该总是先把它转换成一个字节：

        pragma solidity ^0.4.0;

        contract C {
            string s;

            function append(byte c) public {
                bytes(s).push(c);
            }

            function set(uint i, byte c) public {
                bytes(s)[i] = c;
            }
        }

??? faq "我可以连接两个字符串吗？"

    你现在必须手动完成。

??? faq "为什么低级函数`.call（）`比实例化一个变量（`ContractB b;`）并执行它的函数（`b.doSomething（）;`）更合适？"

    如果使用实际函数，编译器会告诉你类型或参数是否匹配，如果该函数不存在或不可见，那么它将为你打包参数。

    查看[ping.sol][12]和[pong.sol][13].

??? faq "未使用的天然气是否自动退还？"

    是的，它是直接的，即作为交易的一部分完成。

??? faq "当返回`uint`类型的值时，是否可以返回一个'undefined`或者“null”类型的值？"

    这是不可能的，因为所有类型都使用完整的值范围。

    您可以选择在错误时抛出错误，这也将恢复整个事务，如果遇到意外情况，这可能是个好主意。

    如果你不想扔，你可以返回一对：

        pragma solidity ^0.4.16;

        contract C {
            uint[] counters;

            function getCounter(uint index)
                public
                view
                returns (uint counter, bool error) {
                    if (index >= counters.length)
                        return (0, true);
                    else
                        return (counters[index], false);
            }

            function checkCounter(uint index) public view {
                var (counter, error) = getCounter(index);
                if (error) {
                    // ...
                } else {
                    // ...
                }
            }
        }

??? faq "部署的合约中是否包含评论？他们是否增加了部署用气？"

    不，编译过程中删除了不需要执行的所有内容。
    其中包括评论，变量名称和类型名称。

??? faq "如果您将ether与函数调用一起发送给合约，会发生什么情况？"

    它会被添加到合同的总余额中，就像您在创建合同时发送以太币一样。
    您只能将ether发送给具有`payable`修饰符的函数，否则会引发异常。

??? faq "是否有可能获得执行合约到合约的交易的tx收据？"

    不，从一个合约到另一个合约的函数调用不会创建自己的事务，您必须查看整个事务。
    这也是为什么几个资源管理器不能正确显示Ether在合同之间发送的原因。

??? faq "什么是“内存”关键字？,它有什么作用？"

    以太坊虚拟机有三个可存储物品的区域。

    首先是“存储”，即所有合同状态变量所在的位置。
    每个合同都有自己的存储空间，它在函数调用之间是持久的，并且使用起来相当昂贵。

    第二个是“记忆”，这是用来保存临时值。
    它在（外部）函数调用之间被擦除，使用起来更便宜。

    第三个是堆栈，用来存放小的局部变量。
    它几乎可以自由使用，但只能保存有限的数值。

    对于几乎所有的类型，您无法指定它们应存储的位置，因为每次使用它们时都会被复制。

    所谓的存储位置很重要的类型是结构和数组。
    如果你,在函数调用中传递这些变量，如果它们可以保留在内存中或保留在存储中，则不会复制它们的数据。
    这意味着您可以在被调用的函数中修改其内容，并且这些修改仍将在调用者中可见。

    存储位置的默认值取决于它所涉及的变量类型：

    - 状态变量始终处于存储状态
    - 函数参数默认在内存中
    - 默认情况下，结构，数组或映射类型引用存储的局部变量
    - 值类型的局部变量（即既不是数组也不是结构也不映射）存储在堆栈中

    示例:

        pragma solidity ^0.4.0;

        contract C {
            uint[] data1;
            uint[] data2;

            function appendOne[4] public {
                append(data1);
            }

            function appendTwo[4] public {
                append(data2);
            }

            function append(uint[] storage d) internal {
                d.push(1);
            }
        }

    函数append可以在`data1`和`data2`上工作，并且它的修改将永久存储。
    如果删除`storage`关键字，则缺省情况是将`memory`用于函数参数。
    如果删除`storage`关键字，则缺省情况是将`memory`用于函数参数。
    对这个独立副本的修改不会带回`data1`或`data2`。

    一个常见的错误是声明一个局部变量，并假定它将在内存中创建，尽管它将在存储中创建：

        /// THIS CONTRACT CONTAINS AN ERROR

        pragma solidity ^0.4.0;

        contract C {
            uint someVariable;
            uint[] data;

            function f[4] public {
                uint[] x;
                x.push(2);
                data = x;
            }
        }

    局部变量`x`的类型是`uint [] storage`，但由于存储不是动态分配的，因此它必须从状态变量中分配，然后才能使用。
    因此，不会为`x`分配存储空间，但它只能作为存储中预先存在的变量的别名。

    会发生什么是编译器将`x`解释为存储指针，并且会默认指向存储槽'0`。
    这具有“someVariable”（位于存储槽“0”处）由`x.push（2）`修改的效果。

    正确的做法如下：

        pragma solidity ^0.4.0;

        contract C {
            uint someVariable;
            uint[] data;

            function f[4] public {
                uint[] x = data;
                x.push(2);
            }
        }

## 高级问题

??? faq "你如何在合约中得到一个随机数字？ ,（实施自我回报赌博合约。）"

    获得正确的随机性通常是加密项目中的关键部分，大多数失败都是由不好的随机数生成器造成的。

    如果你不希望它是安全的，你可以建立类似于[硬币鳍状肢][21]的东西，但是另外一种情况是使用一种提供随机性的合同，如[RANDAO][14]。

??? faq "从另一个合同的非常量函数中获取返回值"

    关键在于呼叫合同需要知道它打算调用的功能。
    查看[ping.sol][12]和[pong.sol][13].

??? faq "在第一次开采时获得合约来做某件事"

    使用构造函数。当合同首次开采时，其内的任何内容都将被执行。

    查看[replicator.sol][15].

??? faq "你如何创建2维数组？"

    查看[2D_array.sol][16].

    请注意，在撰写本文时，填写10x10平方英尺的'uint8` +合同创建需要超过80万美元的天然气。
    17x17采取`2,000,000`气体。
    限制在314万......好吧，你现在可以创造的东西很低。

    请注意，只是“创建”阵列是免费的，成本在填补它。

    注2：优化存储访问可以显着降低天然气成本，因为32`uint8`值可以存储在一个插槽中。
    问题在于，这些优化目前不能跨循环工作，并且在边界检查时也存在问题。
    不过，您未来可能会获得更好的结果。

??? faq "复制“struct”时，struct`映射会发生什么？"

    这是一个非常有趣的问题。
    假设我们有一个如此设置的合同字段：

        struct User {
            mapping(string => string) comments;
        }

        function somefunction public {
           User user1;
           user1.comments["Hello"] = "World";
           User user2 = user1;
        }

    In this case, the mapping of the struct being copied over into the userList is ignored as there is no "list of mapped keys".
    Therefore it is not possible to find out which values should be copied over.

??? faq "如何初始化只有特定数量的wei的合约？"

    Currently the approach is a little ugly, but there is little that can be done to improve it.
    In the case of a `contract A` calling a new instance of `contract B`, parentheses have to be used around `new B` because `B.value` would refer to a member of `B` called `value`.
    You will need to make sure that you have both contracts aware of each other's presence and that `contract B` has a `payable` constructor.

    In this 示例:

        pragma solidity ^0.4.0;

        contract B {
            function B[4] public payable {}
        }

        contract A {
            address child;

            function test[4] public {
                child = (new B).value(10)[4]; //construct a new B with 10 wei
            }
        }

??? faq "契约函数可以接受一个二维数组吗？"

    This is not yet implemented for external calls and dynamic arrays -you can only use one level of dynamic arrays.

??? faq "`bytes32`和`string`之间的关系是什么？,为什么`bytes32 somevar =“stringliteral”;`起作用，保存的32字节十六进制值是什么意 思？"

    The type `bytes32` can hold 32 (raw) bytes.
    In the assignment `bytes32 samevar = "stringliteral";`, the string literal is interpreted in its raw byte form and if you inspect `somevar` and 查看a 32-byte hex value, this is just `"stringliteral"` in hex.

    The type `bytes` is similar, only that it can change its length.

    Finally, `string` is basically identical to `bytes` only that it is assumed to hold the UTF-8 encoding of a real string.
    Since `string` stores the data in UTF-8 encoding it is quite expensive to compute the number of characters in the string (the encoding of some characters takes more than a single byte).
    Because of that, `string s; s.length` is not yet supported and not even index access `s[2]`.
    But if you want to access the low-level byte encoding of the string, you can use `bytes(s).length` and `bytes(s)[2]` which will result in the number of bytes in the UTF-8 encoding of the string (not the number of characters) and the second byte (not character) of the UTF-8 encoded string,respectively.

??? faq "合约能否将一个数组（静态大小）或字符串或“字节”（动态大小）传递给另一个合约？"

    Sure.
    Take care that if you cross the memory / storage boundary, independent copies will be created:

        pragma solidity ^0.4.16;

        contract C {
            uint[20] x;

            function f[4] public {
                g(x);
                h(x);
            }

            function g(uint[20] y) internal pure {
                y[2] = 3;
            }

            function h(uint[20] storage y) internal {
                y[3] = 4;
            }
        }

    The call to `g(x)` will not have an effect on `x` because it needs to create an independent copy of the storage value in memory (the default storage location is memory).
    On the other hand, `h(x)` successfully modifies `x` because only a reference and not a copy is passed.

??? faq "有时候，当我试图用ex：arrayname.length = 7来改变一个数组的长度时，我得到一个编译器错误：Value必须是一个左值。,为什么？"

    You can resize a dynamic array in storage (i.e. an array declared at the contract level) with `arrayname.length = <some new length>;`.
    If you get the "lvalue" error, you are probably doing one of two things wrong.

    1. You might be trying to resize an array in "memory", or
    2. You might be trying to resize a non-dynamic array.

    <!-- -->

        int8[] memory memArr;        // Case 1
        memArr.length++;             // illegal
        int8[5] storageArr;          // Case 2
        somearray.length++;          // legal
        int8[5] storage storageArr2; // Explicit case 2
        somearray2.length++;         // legal

    **Important note:** In Solidity, array dimensions are declared backwards from the way you might be used to declaring them in C or Java, but they are access as in C or Java.

    For example, `int8[][5] somearray;` are 5 dynamic `int8` arrays.

    The reason for this is that `T[5]` is always an array of 5 `T`'s, no matter whether `T` itself is an array or not (this is not the case in C or Java).

??? faq "是否有可能从一个Solidity函数返回一个字符串数组（`string []`）？"

    Not yet, as this requires two levels of dynamic arrays (`string` is a dynamic array itself).

??? faq "如果你发出一个数组的调用，有可能检索整个数组？,或者你必须为此写一个辅助函数吗？"

    The automatic [getter function<getter-functions>][4] for a public state variable of array type only returns individual elements.
    If you want to return the complete array, you have to manually write a function to do that.

??? faq "如果一个帐户有存储值但没有代码，会发生什么情况？,例:"

    <http://test.ether.camp/account/5f740b3a43fbb99724ce93a879805f4dc89178b5>

    The last thing a constructor does is returning the code of the contract.
    The gas costs for this depend on the length of the code and it might be that the supplied gas is not enough.
    This situation is the only one where an "out of gas" exception does not revert changes to the state,
    i.e. in this case the initialisation of the state variables.

    <https://github.com/ethereum/wiki/wiki/Subtleties>

    After a successful CREATE operation's sub-execution, if the operation returns x, 5 * len(x) gas is subtracted from the remaining gas before the contract is created.
    If the remaining gas is less than 5 * len(x), then no gas is subtracted, the code of the created contract becomes the empty string, but this is not treated as an exceptional condition - no reverts happen.

??? faq "以下奇怪的检查在自定义令牌合约中做了什么？"

        require((balanceOf[_to] + _value) >= balanceOf[_to]);

    Integers in Solidity (and most other machine-related programming languages) are restricted to a certain range.
    For `uint256`, this is `0` up to `2**256 - 1`.
    If the result of some operation on those numbers does not fit inside this range, it is truncated.
    These truncations can have [serious consequences](https://en.bitcoin.it/wiki/Value_overflow_incident), so     code like the one above is necessary to avoid certain attacks.

??? faq "更多问题？"

    If you have more questions or your question is not answered here, please talk to us on [gitter][17] or file an  [issue][18].

[1]: mailto:fivedogit@gmail.com
[2]: https://github.com/fivedogit/solidity-baby-steps/blob/master/contracts/05_greeter.sol
[3]: http://www.ethereum-alarm-clock.com/
[4]: https://github.com/comaeio/porosity
[5]: https://remix.ethereum.org/
[6]: https://github.com/fivedogit/solidity-baby-steps/blob/master/contracts/30_endowment_retriever.sol
[7]: https://github.com/fivedogit/solidity-baby-steps/blob/master/contracts/20_value_incrementer.sol
[8]: https://github.com/fivedogit/solidity-baby-steps/blob/master/contracts/60_array_receiver_and_returner.sol
[9]: https://github.com/fivedogit/solidity-baby-steps/blob/master/contracts/65_struct_and_for_loop_tester.sol
[10]: https://github.com/ethereum/dapp-bin/blob/master/library/stringUtils.sol
[11]: https://github.com/Arachnid/solidity-stringutils
[12]: https://github.com/fivedogit/solidity-baby-steps/blob/master/contracts/45_ping.sol
[13]: https://github.com/fivedogit/solidity-baby-steps/blob/master/contracts/45_pong.sol
[14]: https://github.com/randao/randao
[15]: https://github.com/fivedogit/solidity-baby-steps/blob/master/contracts/50_replicator.sol
[16]: https://github.com/fivedogit/solidity-baby-steps/blob/master/contracts/55_2D_array.sol
[17]: https://gitter.im/ethereum/solidity
[18]: https://github.com/ethereum/solidity/issues
[19]: https://github.com/fivedogit/solidity-baby-steps/tree/master/contracts/
[20]: https://github.com/ethereum/solidity/blob/develop/test/libsolidity/SolidityEndToEndTest.cpp
[21]: https://github.com/fivedogit/solidity-baby-steps/blob/master/contracts/35_coin_flipper.sol
[22]: