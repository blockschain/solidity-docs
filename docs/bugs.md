# 已知错误列表

下面，您可以在Solidity编译器中找到一些JSON格式的已知安全相关错误列表。
该文件本身托管在[Github存储库](https://github.com/ethereum/solidity/blob/develop/docs/bugs.json).
该列表延伸至0.3.0版本，已知只存在于未列出的版本中的错误。

还有一个名为[bugs_by_version.json] [1]的文件，它可以用来检查哪些bug影响编译器的特定版本。

合同来源验证工具以及与合同交互的其他工具应根据以下标准查阅此列表：

> - 如果使用夜间编译器版本而不是发布版本来编译合约，这是轻度可疑的。,此列表不会跟踪未发布版本或夜间版本。
> - 如果合同是用合同创建时最近期的版本编制的，那么它也是轻度可疑的。 对于从其他合同创建的合同，您必须按照创建链回到交易，并使用该交易的日期作为创建日期。
> - 如果使用包含已知错误的编译器编译合同并且在包含修补程序的较新编译器版本已经发布的时间创建合同，那么它是高度可疑的。

下面已知错误的JSON文件是一个对象数组，每个错误使用以下关键字：

- **name**: 赋予错误的唯一名称
- **summary**: 简短的错误描述
- **description**: 错误的详细描述
- **link**: 具有更详细信息的网站的URL，可选
- **introduced**: 包含该错误的第一个发布的编译器版本，可选
- **fixed**: 第一个发布的编译器版本不再包含该错误
- **publish**: 错误变得公开的日期，可选
- **severity**: 错误的严重程度: very low, low, medium, high. 考虑到合同测试中的可发现性，发生的可能性以及漏洞可能造成的损害。
- **conditions**: 必须满足触发错误的条件。 目前，这是一个可以包含布尔值`optimizer`的对象，这意味着必须打开优化器才能启用该错误。 如果没有给出条件，则假定存在该错误。

```json
[
    {
        "name": "ZeroFunctionSelector",
        "summary": "可以制定一个函数的名称，以便在非常特殊的情况下执行该函数而不是回退函数。",
        "description": "如果一个函数只有一个由零组成的选择器，是可支付的并且没有回退函数并且最多有五个外部函数的合约的一部分，如果以太网被发送给合同，则调用该函数而不是回退函数,没有数据。",
        "fixed": "0.4.18",
        "severity": "very low"
    },
    {
        "name": "DelegateCallReturnValue",
        "summary": "The low-level .delegatecall() does not return the execution outcome, but converts the value returned by the functioned called to a boolean instead.",
        "description": "The return value of the low-level .delegatecall() function is taken from a position in memory, where the call data or the return data resides. This value is interpreted as a boolean and put onto the stack. This means if the called function returns at least 32 zero bytes, .delegatecall() returns false even if the call was successuful.",
        "introduced": "0.3.0",
        "fixed": "0.4.15",
        "severity": "low"
    },
    {
        "name": "ECRecoverMalformedInput",
        "summary": "The ecrecover() builtin can return garbage for malformed input.",
        "description": "The ecrecover precompile does not properly signal failure for malformed input (especially in the 'v' argument) and thus the Solidity function can return data that was previously present in the return area in memory.",
        "fixed": "0.4.14",
        "severity": "medium"
    },
    {
        "name": "SkipEmptyStringLiteral",
        "summary": "If \"\" is used in a function call, the following function arguments will not be correctly passed to the function.",
        "description": "If the empty string literal \"\" is used as an argument in a function call, it is skipped by the encoder. This has the effect that the encoding of all arguments following this is shifted left by 32 bytes and thus the function call data is corrupted.",
        "fixed": "0.4.12",
        "severity": "low"
    },
    {
        "name": "ConstantOptimizerSubtraction",
        "summary": "In some situations, the optimizer replaces certain numbers in the code with routines that compute different numbers.",
        "description": "The optimizer tries to represent any number in the bytecode by routines that compute them with less gas. For some special numbers, an incorrect routine is generated. This could allow an attacker to e.g. trick victims about a specific amount of ether, or function calls to call different functions (or none at all).",
        "link": "https://blog.ethereum.org/2017/05/03/solidity-optimizer-bug/",
        "fixed": "0.4.11",
        "severity": "low",
        "conditions": {
            "optimizer": true
        }
    },
    {
        "name": "IdentityPrecompileReturnIgnored",
        "summary": "Failure of the identity precompile was ignored.",
        "description": "Calls to the identity contract, which is used for copying memory, ignored its return value. On the public chain, calls to the identity precompile can be made in a way that they never fail, but this might be different on private chains.",
        "severity": "low",
        "fixed": "0.4.7"
    },
    {
        "name": "OptimizerStateKnowledgeNotResetForJumpdest",
        "summary": "The optimizer did not properly reset its internal state at jump destinations, which could lead to data corruption.",
        "description": "The optimizer performs symbolic execution at certain stages. At jump destinations, multiple code paths join and thus it has to compute a common state from the incoming edges. Computing this common state was simplified to just use the empty state, but this implementation was not done properly. This bug can cause data corruption.",
        "severity": "medium",
        "introduced": "0.4.5",
        "fixed": "0.4.6",
        "conditions": {
            "optimizer": true
        }
    },
    {
        "name": "HighOrderByteCleanStorage",
        "summary": "For short types, the high order bytes were not cleaned properly and could overwrite existing data.",
        "description": "Types shorter than 32 bytes are packed together into the same 32 byte storage slot, but storage writes always write 32 bytes. For some types, the higher order bytes were not cleaned properly, which made it sometimes possible to overwrite a variable in storage when writing to another one.",
        "link": "https://blog.ethereum.org/2016/11/01/security-alert-solidity-variables-can-overwritten-storage/",
        "severity": "high",
        "introduced": "0.1.6",
        "fixed": "0.4.4"
    },
    {
        "name": "OptimizerStaleKnowledgeAboutSHA3",
        "summary": "The optimizer did not properly reset its knowledge about SHA3 operations resulting in some hashes (also used for storage variable positions) not being calculated correctly.",
        "description": "The optimizer performs symbolic execution in order to save re-evaluating expressions whose value is already known. This knowledge was not properly reset across control flow paths and thus the optimizer sometimes thought that the result of a SHA3 operation is already present on the stack. This could result in data corruption by accessing the wrong storage slot.",
        "severity": "medium",
        "fixed": "0.4.3",
        "conditions": {
            "optimizer": true
        }
    },
    {
        "name": "LibrariesNotCallableFromPayableFunctions",
        "summary": "Library functions threw an exception when called from a call that received Ether.",
        "description": "Library functions are protected against sending them Ether through a call. Since the DELEGATECALL opcode forwards the information about how much Ether was sent with a call, the library function incorrectly assumed that Ether was sent to the library and threw an exception.",
        "severity": "low",
        "introduced": "0.4.0",
        "fixed": "0.4.2"
    },
    {
        "name": "SendFailsForZeroEther",
        "summary": "The send function did not provide enough gas to the recipient if no Ether was sent with it.",
        "description": "The recipient of an Ether transfer automatically receives a certain amount of gas from the EVM to handle the transfer. In the case of a zero-transfer, this gas is not provided which causes the recipient to throw an exception.",
        "severity": "low",
        "fixed": "0.4.0"
    },
    {
        "name": "DynamicAllocationInfiniteLoop",
        "summary": "Dynamic allocation of an empty memory array caused an infinite loop and thus an exception.",
        "description": "Memory arrays can be created provided a length. If this length is zero, code was generated that did not terminate and thus consumed all gas.",
        "severity": "low",
        "fixed": "0.3.6"
    },
    {
        "name": "OptimizerClearStateOnCodePathJoin",
        "summary": "The optimizer did not properly reset its internal state at jump destinations, which could lead to data corruption.",
        "description": "The optimizer performs symbolic execution at certain stages. At jump destinations, multiple code paths join and thus it has to compute a common state from the incoming edges. Computing this common state was not done correctly. This bug can cause data corruption, but it is probably quite hard to use for targeted attacks.",
        "severity": "low",
        "fixed": "0.3.6",
        "conditions": {
            "optimizer": true
        }
    },
    {
        "name": "CleanBytesHigherOrderBits",
        "summary": "The higher order bits of short bytesNN types were not cleaned before comparison.",
        "description": "Two variables of type bytesNN were considered different if their higher order bits, which are not part of the actual value, were different. An attacker might use this to reach seemingly unreachable code paths by providing incorrectly formatted input data.",
        "severity": "medium/high",
        "fixed": "0.3.3"
    },
    {
        "name": "ArrayAccessCleanHigherOrderBits",
        "summary": "Access to array elements for arrays of types with less than 32 bytes did not correctly clean the higher order bits, causing corruption in other array elements.",
        "description": "Multiple elements of an array of values that are shorter than 17 bytes are packed into the same storage slot. Writing to a single element of such an array did not properly clean the higher order bytes and thus could lead to data corruption.",
        "severity": "medium/high",
        "fixed": "0.3.1"
    },
    {
        "name": "AncientCompiler",
        "summary": "This compiler version is ancient and might contain several undocumented or undiscovered bugs.",
        "description": "The list of bugs is only kept for compiler versions starting from 0.3.0, so older versions might contain undocumented bugs.",
        "severity": "high",
        "fixed": "0.3.0"
    }
]
```

[1]: https://github.com/ethereum/solidity/blob/develop/docs/bugs_by_version.json