# 常见模式

## 退出合同

推荐的方法是在效果使用撤回模式后发送资金。
尽管发送Ether的最直观的方法是作为一个效果的结果，但是这是一个直接的“发送”调用，但不建议这样做，因为它会带来潜在的安全风险。
您可以在[security_considerations]（）页面阅读更多关于此的信息。

这是一个合同实践中退出模式的例子，其目的是为了成为“最富有”的灵感来源于[King of the Ether]（https://www.kingoftheether.com）,的.com /）。

在下面的合同中，如果你被篡夺为最富有者，你将获得继续成为新富的人的资金。

    pragma solidity ^0.4.11;

    contract WithdrawalContract {
        address public richest;
        uint public mostSent;

        mapping (address => uint) pendingWithdrawals;

        function WithdrawalContract() public payable {
            richest = msg.sender;
            mostSent = msg.value;
        }

        function becomeRichest() public payable returns (bool) {
            if (msg.value > mostSent) {
                pendingWithdrawals[richest] += msg.value;
                richest = msg.sender;
                mostSent = msg.value;
                return true;
            } else {
                return false;
            }
        }

        function withdraw() public {
            uint amount = pendingWithdrawals[msg.sender];
            // Remember to zero the pending refund before
            // sending to prevent re-entrancy attacks
            pendingWithdrawals[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }

这与更直观的发送模式相反：

    pragma solidity ^0.4.11;

    contract SendContract {
        address public richest;
        uint public mostSent;

        function SendContract() public payable {
            richest = msg.sender;
            mostSent = msg.value;
        }

        function becomeRichest() public payable returns (bool) {
            if (msg.value > mostSent) {
                // This line can cause problems (explained below).
                richest.transfer(msg.value);
                richest = msg.sender;
                mostSent = msg.value;
                return true;
            } else {
                return false;
            }
        }
    }

注意，在这个例子中，攻击者可以通过使'最富有'成为具有失败后备功能的合同的地址（例如，通过使用'revert（）'或者通过消耗更多的资源来将合同陷入不可用状态,比2300天然气津贴）。
这样一来，无论何时调用“转移”来向“有毒”合同提供资金，它都会失败，因此“成为最富有”也将失败，合同永久停滞。

相比之下，如果您使用第一个示例中的“撤回”模式，则攻击者只能导致他或她自己的撤回失败，而不会影响合同的其余部分。

## 限制访问

限制访问是合同的常见模式。
请注意，您永远不能限制任何人员或计算机阅读您的交易内容或合同状态。
通过使用加密技术可以使其变得更加困难，但如果您的合同应该读取数据，其他人也应该这样做。

您可以通过**其他合同**来限制对合同状态的读取权限。
这实际上是默认的，除非你声明让你的状态变量为public。

此外，您可以限制谁可以修改合约的状态或调用合约的功能，这是本节的内容。

**函数修饰符**的使用使得这些限制具有高度的可读性。

    pragma solidity ^0.4.11;

    contract AccessRestriction {
        // 这些将在施工阶段进行分配，其中`msg.sender`是创建此合同的帐户。
        address public owner = msg.sender;
        uint public creationTime = now;

        // 修饰符可用于更改函数的主体。
        // 如果使用了这个修饰符，它将预先执行一个检查，只有在函数从某个地址被调用时才会通过检查。
        modifier onlyBy(address _account)
        {
            require(msg.sender == _account);
            // 不要忘记“_”！,当使用修饰符时，它将被实际的功能体取代。
            _;
        }

        // 使`_newOwner`成为本合同的新所有者。
        function changeOwner(address _newOwner)
            public
            onlyBy(owner)
        {
            owner = _newOwner;
        }

        modifier onlyAfter(uint _time) {
            require(now >= _time);
            _;
        }

        // 清除所有权信息。
        // 可能只能在合同创建后的6周内被调用。
        function disown()
            public
            onlyBy(owner)
            onlyAfter(creationTime + 6 weeks)
        {
            delete owner;
        }

        // 该修饰符需要与函数调用相关的特定费用。
        // 如果主叫方发送太多，他或她将被退回，但只能在功能主体之后。
        // 在Solidity版本0.4.0之前这是很危险的，因为在`_;`之后可能会跳过该部分。

        modifier costs(uint _amount) {
            require(msg.value >= _amount);
            _;
            if (msg.value > _amount)
                msg.sender.send(msg.value - _amount);
        }

        function forceOwnerChange(address _newOwner)
            public
            costs(200 ether)
        {
            owner = _newOwner;
            // 只是一些示例条件
            if (uint(owner) & 0 == 1)
                // 在版本0.4.0之前，这并没有退还给Solidity。
                return;
            // 退还多付的费用
        }
    }

下一个例子将讨论访问函数调用的更专门的方法。

## 状态机

合同通常充当状态机，这意味着它们具有某些**阶段**，其中它们的行为不同或者可以调用不同的功能。
函数调用通常结束一个阶段并将合约转换到下一阶段（特别是如果合约模拟**交互**）。
一些阶段在**时间**的某个时间点自动到达也很常见。

一个例子就是一个盲目拍卖合同，从“接受不知情的投标”阶段开始，然后过渡到“揭示投标”，以“确定拍卖结果”结束。

在这种情况下，可以使用功能修饰符来模拟状态并防止错误地使用合同。

### 例

在下面的例子中，修饰符`atStage`确保函数只能在某个阶段被调用。

自动定时转换由修饰符`timeTransitions`处理，它应该用于所有功能。

::: {.note}
::: {.admonition-title}
Note
:::

**修改器顺序问题**.
如果atStage与timedTransitions结合使用，请确保在后者之后提及它，以便将新阶段考虑在内。
:::

最后，可以使用修饰符'transitionNext`在函数结束时自动进入下一个阶段。

::: {.note}
::: {.admonition-title}
Note
:::

**修改器可能会被跳过**.
这仅适用于版本0.4.0之前的Solidity：因为通过简单替换代码而不是使用函数调用来应用修饰符，所以如果函数本身使用return，则可以跳过transitionNext修饰符中的代码。
如果你想这样做，一定要从这些功能手动调用nextStage。
从版本0.4.0开始，即使函数显式返回，修饰符代码也会运行。
:::

    pragma solidity ^0.4.11;

    contract StateMachine {
        enum Stages {
            AcceptingBlindedBids,
            RevealBids,
            AnotherStage,
            AreWeDoneYet,
            Finished
        }

        // 这是现阶段。
        Stages public stage = Stages.AcceptingBlindedBids;

        uint public creationTime = now;

        modifier atStage(Stages _stage) {
            require(stage == _stage);
            _;
        }

        function nextStage() internal {
            stage = Stages(uint(stage) + 1);
        }

        // 执行定时转换。
        // 一定要先提到这个修饰符，否则卫兵不会考虑新的阶段。
        modifier timedTransitions() {
            if (stage == Stages.AcceptingBlindedBids && now >= creationTime + 10 days)
                nextStage();
            if (stage == Stages.RevealBids && now >= creationTime + 12 days)
                nextStage();
            // 其他阶段按交易过渡
            _;
        }

        // 修饰符的顺序很重要！
        function bid()
            public
            payable
            timedTransitions
            atStage(Stages.AcceptingBlindedBids)
        {
            // 我们不会在这里实现
        }

        function reveal()
            public
            timedTransitions
            atStage(Stages.RevealBids)
        {
        }

        // 该功能完成后，该修改器进入下一个阶段。
        modifier transitionNext()
        {
            _;
            nextStage();
        }

        function g()
            public
            timedTransitions
            atStage(Stages.AnotherStage)
            transitionNext
        {
        }

        function h()
            public
            timedTransitions
            atStage(Stages.AreWeDoneYet)
            transitionNext
        {
        }

        function i()
            public
            timedTransitions
            atStage(Stages.Finished)
        {
        }
    }
