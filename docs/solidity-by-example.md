# 以实例说明

## 投票

以下合同非常复杂，但展示了很多Solidity的功能。
它执行投票合同。
当然，电子投票的主要问题是如何为正确的人员分配投票权，以及如何防止操纵。
我们不会在这里解决所有问题，但至少我们会展示如何进行委派投票，以便计票自动且完全透明。

这个想法是为每个选票创建一个合同，为每个选项提供一个简称。
然后，担任主席的合同创建者将分别给予每个地址的投票权。

然后，地址背后的人可以选择自己投票，或者将他们的投票委托给他们信任的人.

在投票时间结束时，“winningProposal（）”将返回投票数最多的提案.

    pragma solidity ^0.4.16;

    // @title Voting with delegation.
    contract Ballot {
        // 这声明了一个新的复杂类型，稍后将用于变量。
        // 它将代表一个单一的选民.
        struct Voter {
            uint weight; // weight is accumulated by delegation
            bool voted;  // if true, that person already voted
            address delegate; // person delegated to
            uint vote;   // index of the voted proposal
        }

        // 这是针对单个提案的类型.
        struct Proposal {
            bytes32 name;   // short name (up to 32 bytes)
            uint voteCount; // number of accumulated votes
        }

        address public chairperson;

        // 这声明了一个状态变量，为每个可能的地址存储一个`Voter`结构.
        mapping(address => Voter) public voters;

        // 动态大小的`Proposal`结构数组.
        Proposal[] public proposals;

        // 创建一个新的选票来选择`proposalNames`中的一个.
        function Ballot(bytes32[] proposalNames) public {
            chairperson = msg.sender;
            voters[chairperson].weight = 1;

            // 对于每个提供的提议名称，创建一个新提议对象并将其添加到数组的末尾.
            for (uint i = 0; i < proposalNames.length; i++) {
                // `Proposal({...})` creates a temporary
                // Proposal object and `proposals.push(...)`
                // appends it to the end of `proposals`.
                proposals.push(Proposal({
                    name: proposalNames[i],
                    voteCount: 0
                }));
            }
        }

        // 赋予“选民”投票权.
        // 只能由`委员长'调用.
        function giveRightToVote(address voter) public {
            // 如果`require`的参数评估为'false'，它会终止并恢复对状态的所有更改，并返回到以太平衡.
            // 如果函数被错误地调用，通常使用它是一个好主意。
            // 但要小心，这也将消耗所有提供的天然气（这是计划在未来改变）。
            require((msg.sender == chairperson) && !voters[voter].voted && (voters[voter].weight == 0));
            voters[voter].weight = 1;
        }

        // 把你的选票委托给选民`到`。
        function delegate(address to) public {
            // 指定参考
            Voter storage sender = voters[msg.sender];
            require(!sender.voted);

            // 自我授权是不被允许的。
            require(to != msg.sender);

            // 只要`to`也委派给代表团。,一般来说，这样的循环是非常危险的，因为如果它们运行时间过长，它们可能需要比块中可用的更多的气体。
            // 在这种情况下，代表团将不会执行，但在其他情况下，此类循环可能会导致合同“完全停滞”。
            while (voters[to].delegate != address(0)) {
                to = voters[to].delegate;

                // We found a loop in the delegation, not allowed.
                require(to != msg.sender);
            }

            // 由于`sender`是一个参考，所以这会修改`选民[msg.sender] .voted`
            sender.voted = true;
            sender.delegate = to;
            Voter storage delegate = voters[to];
            if (delegate.voted) {
                // 如果代表已经投票，则直接增加投票数
                proposals[delegate.vote].voteCount += sender.weight;
            } else {
                // 如果代表还没有投票，请增加她的体重。
                delegate.weight += sender.weight;
            }
        }

        // 将您的投票（包括授予您的投票）提交给提案 `proposals[proposal].name`.
        function vote(uint proposal) public {
            Voter storage sender = voters[msg.sender];
            require(!sender.voted);
            sender.voted = true;
            sender.vote = proposal;

            // 如果`提议'超出了数组范围，这将自动抛出并恢复所有更改。
            proposals[proposal].voteCount += sender.weight;
        }

        // @dev计算以前所有投票的获胜建议。
        function winningProposal() public view
                returns (uint winningProposal)
        {
            uint winningVoteCount = 0;
            for (uint p = 0; p < proposals.length; p++) {
                if (proposals[p].voteCount > winningVoteCount) {
                    winningVoteCount = proposals[p].voteCount;
                    winningProposal = p;
                }
            }
        }

        // 调用winningProposal（）函数以获取提议数组中包含的获胜者的索引，然后返回获胜者的名称
        function winnerName() public view
                returns (bytes32 winnerName)
        {
            winnerName = proposals[winningProposal()].name;
        }
    }

### 可能的改进

目前，需要许多交易才能将投票权赋予所有参与者。
你能想出更好的方法吗？

## 盲目拍卖

在本节中，我们将展示在以太坊创建一个完全失明的拍卖合同是多么容易。
我们将从公开拍卖开始，每个人都可以看到所做的投标，然后将此合同扩展到盲目拍卖，在竞标期结束之前无法看到实际出价。

### 简单的公开拍卖

以下简单的拍卖合同的总体思路是每个人都可以在投标期内发送他们的出价。
出价已经包括发送金钱/以太币以使投标人与他们的出价相结合。
如果提高最高出价，以前出价最高的出价者就可以拿回她的钱了。
在投标期结束后，合同必须手动为受益人接收他的钱 - 合同不能激活自己。

    pragma solidity ^0.4.11;

    contract SimpleAuction {
        // 拍卖的参数.
        // 时间是绝对的unix时间戳（自1970-01-01以来的秒数）或以秒为单位的时间段.
        address public beneficiary;
        uint public auctionEnd;

        // 拍卖的当前状态.
        address public highestBidder;
        uint public highestBid;

        // 允许撤回之前的出价
        mapping(address => uint) pendingReturns;

        // 最后设置为true，禁止任何更改
        bool ended;

        // 将在更改中触发的事件.
        event HighestBidIncreased(address bidder, uint amount);
        event AuctionEnded(address winner, uint amount);

        // 以下是所谓的natspec评论，可以通过三个斜线来识别。
        // 它会在用户被要求确认交易时显示。

        // 代表受益人地址_beneficiary创建一个包含`_biddingTime`秒投标时间的简单拍卖。
        function SimpleAuction(
            uint _biddingTime,
            address _beneficiary
        ) public {
            beneficiary = _beneficiary;
            auctionEnd = now + _biddingTime;
        }

        // 与此次交易一起发送的价格与拍卖竞标。
        // 如果拍卖没有赢得，价值只会被退还。
        function bid() public payable {
            // 调用winningProposal（）函数以获取提议数组中包含的获胜者的索引，然后返回获胜者的名称
            // 为了能够接收以太网，功能需要关键字。

            // 如果投标期结束，请恢复通话。
            require(now <= auctionEnd);

            // 如果出价不高，请将钱退回。
            require(msg.value > highestBid);

            if (highestBidder != 0) {
                // 通过仅使用highestBidder.send（highestBid）发回资金是一种安全风险，因为它可以执行不受信任的合同。
                // 让收款人自己收回钱总是比较安全的。
                pendingReturns[highestBidder] += highestBid;
            }
            highestBidder = msg.sender;
            highestBid = msg.value;
            HighestBidIncreased(msg.sender, msg.value);
        }

        // 撤回高出价的出价。
        function withdraw() public returns (bool) {
            uint amount = pendingReturns[msg.sender];
            if (amount > 0) {
                // 将它设置为零是很重要的，因为接收者可以在发送返回之前再次调用此函数作为接收调用的一部分。
                pendingReturns[msg.sender] = 0;

                if (!msg.sender.send(amount)) {
                    // 没有必要拨打这里，只需重置欠款
                    pendingReturns[msg.sender] = amount;
                    return false;
                }
            }
            return true;
        }

        // 结束拍卖并将最高出价发送给受益人。
        function auctionEnd() public {
            // 将与其他合同交互的功能（即他们称为功能或发送以太网）分为三个阶段是一个很好的指导原则:
            // 1.
检查条件
            // 2.
执行行动（潜在的变化条件）
            // 3.
与其他合同进行交互
            // 如果这些阶段混在一起，另一个合同可以回拨到当前合同中，并且修改状态或原因效应（以太付款）将被执行多次
            // 如果内部调用的职能包括与外部合同的交互，则他们也必须被视为与外部合同的交互。

            // 1.
条件
            require(now >= auctionEnd); // auction did not yet end
            require(!ended); // this function has already been called

            // 2.
效果
            ended = true;
            AuctionEnded(highestBidder, highestBid);

            // 3.
相互作用
            beneficiary.transfer(highestBid);
        }
    }

### 盲目拍卖

以前的公开拍卖会延伸到以下的盲目拍卖。
盲目拍卖的优势在于投标期结束时没有时间压力。
在一个透明的计算平台上创建一个盲目拍卖可能听起来像是一个矛盾，但是密码学可以解救。

在投标期间，投标人实际上并没有发出她的投标，而只是一个散列版本。
由于目前认为实际上不可能找到两个（足够长）的哈希值相等的值，因此投标人承诺通过该投标。
投标结束后，投标人必须公开他们的投标：他们将他们的价值未加密并且合同检查散列值与投标期间提供的散列值相同。

另一个挑战是如何在同一时间使拍卖具有约束力和盲目性：在赢得拍卖后阻止投标人不发送货币的唯一方法是让她在拍卖中一并发送。
既然价值转移不能在以太坊蒙蔽，任何人都可以看到价值。

以下合同通过接受任何大于最高出价的值来解决此问题。
因为这当然只能在披露阶段进行检查，所以有些出价可能是无效的，这是有意的（它甚至提供了一个明确的标记，用高价值的转让放置无效的出价）:
投标人可以通过设置几个高或低的无效投标来混淆竞争。

    pragma solidity ^0.4.11;

    contract BlindAuction {
        struct Bid {
            bytes32 blindedBid;
            uint deposit;
        }

        address public beneficiary;
        uint public biddingEnd;
        uint public revealEnd;
        bool public ended;

        mapping(address => Bid[]) public bids;

        address public highestBidder;
        uint public highestBid;

        // 允许撤回之前的出价
        mapping(address => uint) pendingReturns;

        event AuctionEnded(address winner, uint highestBid);

        // 修饰符是验证函数输入的便捷方式。 ,`onlyBefore`应用于下面的`bid`：
        // 新的函数体是修饰符的主体，其中`_`被旧的函数体替换。
        modifier onlyBefore(uint _time) { require(now < _time); _; }
        modifier onlyAfter(uint _time) { require(now > _time); _; }

        function BlindAuction(
            uint _biddingTime,
            uint _revealTime,
            address _beneficiary
        ) public {
            beneficiary = _beneficiary;
            biddingEnd = now + _biddingTime;
            revealEnd = biddingEnd + _revealTime;
        }

        // 用'_blindedBid` = keccak256（价值，假，秘密）.
        // 如果投标在披露阶段正确显示，则只会退还已发送的以太币。
        // 如果与投标一起发送的以太币至少为“有价值”且“假”不真实，则投标有效。
        // 将“假”设置为真，并发送不确切的金额是隐藏实际出价但仍然需要存款的方法。
        // 同一个地址可以放置多个出价。
        function bid(bytes32 _blindedBid)
            public
            payable
            onlyBefore(biddingEnd)
        {
            bids[msg.sender].push(Bid({
                blindedBid: _blindedBid,
                deposit: msg.value
            }));
        }

        // 揭示你不知情的投标。
        // 对于所有正确无视的无效出价以及除最高出价以外的所有出价，您都将获得退款。
        function reveal(
            uint[] _values,
            bool[] _fake,
            bytes32[] _secret
        )
            public
            onlyAfter(biddingEnd)
            onlyBefore(revealEnd)
        {
            uint length = bids[msg.sender].length;
            require(_values.length == length);
            require(_fake.length == length);
            require(_secret.length == length);

            uint refund;
            for (uint i = 0; i < length; i++) {
                var bid = bids[msg.sender][i];
                var (value, fake, secret) = (_values[i], _fake[i], _secret[i]);
                if (bid.blindedBid != keccak256(value, fake, secret)) {
                    // 出价实际上并未透露。
                    // 不要退还押金。
                    continue;
                }
                refund += bid.deposit;
                if (!fake && bid.deposit >= value) {
                    if (placeBid(msg.sender, value))
                        refund -= value;
                }
                // Make it impossible for the sender to re-claim
                // the same deposit.
                bid.blindedBid = bytes32(0);
            }
            msg.sender.transfer(refund);
        }

        // 这是一个“内部”功能，这意味着它只能从合同本身（或派生合同）中调用。
        function placeBid(address bidder, uint value) internal
                returns (bool success)
        {
            if (value <= highestBid) {
                return false;
            }
            if (highestBidder != 0) {
                // 退还先前出价最高的出价者。
                pendingReturns[highestBidder] += highestBid;
            }
            highestBid = value;
            highestBidder = bidder;
            return true;
        }

        // 撤回出价过高的出价
        function withdraw() public {
            uint amount = pendingReturns[msg.sender];
            if (amount > 0) {
                // 将此设置为零是很重要的，因为接收者可以在`transfer`返回之前再次调用此函数作为接收呼叫的一部分（请参阅上面关于条件 - >效果 - >交互的注释）。
                pendingReturns[msg.sender] = 0;

                msg.sender.transfer(amount);
            }
        }

        // 结束拍卖并将最高出价发送给受益人
        function auctionEnd()
            public
            onlyAfter(revealEnd)
        {
            require(!ended);
            AuctionEnded(highestBidder, highestBid);
            ended = true;
            beneficiary.transfer(highestBid);
        }
    }

## 安全远程购买

    pragma solidity ^0.4.11;

    contract Purchase {
        uint public value;
        address public seller;
        address public buyer;
        enum State { Created, Locked, Inactive }
        State public state;

        // 确保`msg.value`是一个偶数。
        // 如果它是一个奇数，则该分区将被截断。
        // 通过乘法检查它不是奇数。
        function Purchase() public payable {
            seller = msg.sender;
            value = msg.value / 2;
            require((2 * value) == msg.value);
        }

        modifier condition(bool _condition) {
            require(_condition);
            _;
        }

        modifier onlyBuyer() {
            require(msg.sender == buyer);
            _;
        }

        modifier onlySeller() {
            require(msg.sender == seller);
            _;
        }

        modifier inState(State _state) {
            require(state == _state);
            _;
        }

        event Aborted();
        event PurchaseConfirmed();
        event ItemReceived();

        // 放弃购买并收回乙醚。
        // 只能在合同被锁定之前由卖方调用。
        function abort()
            public
            onlySeller
            inState(State.Created)
        {
            Aborted();
            state = State.Inactive;
            seller.transfer(this.balance);
        }

        // 确认购买为买方。
        // 交易必须包括`2 *值`以太。
        // ether将被锁定，直到confirmReceived被调用。
        function confirmPurchase()
            public
            inState(State.Created)
            condition(msg.value == (2 * value))
            payable
        {
            PurchaseConfirmed();
            buyer = msg.sender;
            state = State.Locked;
        }

        // 确认您（买家）收到该物品。
        // 这将释放锁定的以太。
        function confirmReceived()
            public
            onlyBuyer
            inState(State.Locked)
        {
            ItemReceived();
            // 首先改变状态很重要，否则，使用下面的`send`调用的合约可以在这里再次调用。
            state = State.Inactive;

            // 注意：这实际上允许买家和卖家阻止退款 - 应该使用退款模式。

            buyer.transfer(value);
            seller.transfer(this.balance);
        }
    }

## 微支付渠道

要写.