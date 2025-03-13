// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { ITypeAndVersion } from "@chainlink/contracts-ccip/src/v0.8/shared/interfaces/ITypeAndVersion.sol";
import { IUSDO } from "./interfaces/IUSDO.sol";
import { IAny2EVMOffRamp } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMOffRamp.sol";

import { BurnMintTokenPoolAbstract } from "@chainlink/contracts-ccip/src/v0.8/ccip/pools/BurnMintTokenPoolAbstract.sol";
import { Pool } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Pool.sol";
import { TokenPool } from "@chainlink/contracts-ccip/src/v0.8/ccip/pools/TokenPool.sol";

contract USDOBurnMintTokenPoolWithApproval is BurnMintTokenPoolAbstract, ITypeAndVersion {
    string public constant override typeAndVersion = "USDO BurnMintTokenPool 1.5.1";

    mapping(address => bool) public approvers;
    mapping(bytes32 => TxnLimit) public txnToLimitSet;
    mapping(uint64 => Limit[]) public chainToLimit;
    mapping(bytes32 => Transaction) public txnHashToTransaction;

    constructor(
        IUSDO token,
        uint8 localTokenDecimals,
        address[] memory allowlist,
        address rmnProxy,
        address router
    ) TokenPool(token, localTokenDecimals, allowlist, rmnProxy, router) {}

    /// @inheritdoc BurnMintTokenPoolAbstract
    function _burn(uint256 amount) internal virtual override {
        IUSDO(address(i_token)).burn(address(this), amount);
    }

    function lockOrBurn(
        Pool.LockOrBurnInV1 calldata lockOrBurnIn
    ) external virtual override returns (Pool.LockOrBurnOutV1 memory) {
        _validateLockOrBurn(lockOrBurnIn);

        _burn(lockOrBurnIn.amount);

        emit Burned(msg.sender, lockOrBurnIn.amount);

        return
            Pool.LockOrBurnOutV1({
                destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector),
                destPoolData: abi.encode(IUSDO(address(i_token)).bonusMultiplier())
            });
    }

    function releaseOrMint(
        Pool.ReleaseOrMintInV1 calldata releaseOrMintIn
    ) external virtual override returns (Pool.ReleaseOrMintOutV1 memory) {
        _validateReleaseOrMint(releaseOrMintIn);

        uint256 srcBonusMultiplier = abi.decode(releaseOrMintIn.sourcePoolData, (uint256));
        uint256 destBonusMultiplier = IUSDO(address(i_token)).bonusMultiplier();

        uint256 destAmount = releaseOrMintIn.amount;

        if (srcBonusMultiplier != destBonusMultiplier) {
            destAmount = (destAmount * destBonusMultiplier) / srcBonusMultiplier;
        }

        uint256 balancePre = IUSDO(address(i_token)).balanceOf(releaseOrMintIn.receiver);

        bytes calldata originalSender = releaseOrMintIn.originalSender;
        address sender;
        assembly {
            sender := calldataload(originalSender.offset)
        }
        uint64 nonce = IAny2EVMOffRamp(msg.sender).getSenderNonce(sender);

        bytes memory payload = abi.encode(
            releaseOrMintIn.remoteChainSelector,
            nonce,
            releaseOrMintIn.receiver,
            destAmount
        );
        bytes32 txnHash = keccak256(payload);
        txnHashToTransaction[txnHash] = Transaction(releaseOrMintIn.receiver, destAmount);
        _attachLimit(destAmount, txnHash, releaseOrMintIn.remoteChainSelector);
        _authorizeTransaction(txnHash);
        _mintIfApprovalsMet(txnHash);

        uint256 balancePost = IUSDO(address(i_token)).balanceOf(releaseOrMintIn.receiver);

        if (balancePost < balancePre) {
            revert RevertNegativeMint(balancePre - balancePost);
        }

        emit TransactionInitiated(txnHash);
        return Pool.ReleaseOrMintOutV1({ destinationAmount: balancePost - balancePre });
    }

    function _attachLimit(uint256 amount, bytes32 txnHash, uint64 srcChain) internal {
        Limit[] storage limit = chainToLimit[srcChain];
        for (uint256 i = 0; i < limit.length; ++i) {
            if (amount <= limit[i].amount) {
                txnToLimitSet[txnHash] = TxnLimit(limit[i].numOfApprovalsNeeded, new address[](0));
                return;
            }
        }
        revert NoLimitForChain();
    }

    function _authorizeTransaction(bytes32 txnHash) internal {
        TxnLimit storage limit = txnToLimitSet[txnHash];
        for (uint256 i = 0; i < limit.approvers.length; ++i) {
            if (limit.approvers[i] == msg.sender) {
                revert AlreadyAuthorized();
            }
        }
        limit.approvers.push(msg.sender);
    }

    function _hasRequiredApprovals(bytes32 txnHash) internal view returns (bool) {
        TxnLimit memory limit = txnToLimitSet[txnHash];
        return limit.numOfApprovalsNeeded <= limit.approvers.length;
    }

    function approve(bytes32 txnHash) external {
        if (!approvers[msg.sender]) {
            revert NotAuthorized();
        }
        _authorizeTransaction(txnHash);
        _mintIfApprovalsMet(txnHash);
    }

    function setApprovers(address[] calldata newApprovers) external onlyOwner {
        for (uint256 i = 0; i < newApprovers.length; i++) {
            approvers[newApprovers[i]] = true;
        }
        emit ApproversSet(newApprovers);
    }

    function removeApprover(address approver) external onlyOwner {
        delete approvers[approver];
        emit ApproverRemoved(approver);
    }

    function setChainToLimit(
        uint64 srcChain,
        uint256[] calldata amounts,
        uint256[] calldata numOfApprovers
    ) external onlyOwner {
        uint256 amountsLength = amounts.length;
        if (amountsLength != numOfApprovers.length) {
            revert ArrayLengthMismatch();
        }
        delete chainToLimit[srcChain];
        uint256 prevAmount = 0;
        for (uint256 i = 0; i < amountsLength; ++i) {
            if (i > 0 && amounts[i] <= prevAmount) {
                revert LimitNotInAscendingOrder();
            }
            chainToLimit[srcChain].push(Limit(amounts[i], numOfApprovers[i]));
            prevAmount = amounts[i];
        }
        emit LimitSet(srcChain, amounts, numOfApprovers);
    }

    function rescueTokens(address _token) external onlyOwner {
        uint256 balance = IUSDO(_token).balanceOf(address(this));
        IUSDO(_token).transfer(owner(), balance);
    }

    function _mintIfApprovalsMet(bytes32 txnHash) internal {
        if (_hasRequiredApprovals(txnHash)) {
            Transaction memory txn = txnHashToTransaction[txnHash];
            IUSDO(address(i_token)).mint(txn.sender, txn.amount);
            delete txnHashToTransaction[txnHash];
            emit BridgeCompleted(txn.sender, txn.amount);
        }
    }

    function getNumApproved(bytes32 txnHash) external view returns (uint256) {
        return txnToLimitSet[txnHash].approvers.length;
    }

    struct Limit {
        uint256 amount;
        uint256 numOfApprovalsNeeded;
    }

    struct TxnLimit {
        uint256 numOfApprovalsNeeded;
        address[] approvers;
    }

    struct Transaction {
        address sender;
        uint256 amount;
    }

    event TransactionInitiated(bytes32 txnHash);
    event LimitSet(uint64 chain, uint256[] amounts, uint256[] numOfApprovers);
    event BridgeCompleted(address user, uint256 amount);
    event ApproversSet(address[] newApprovers);
    event ApproverRemoved(address approver);

    error NotAuthorized();
    error NoLimitForChain();
    error AlreadyAuthorized();
    error LimitNotInAscendingOrder();
    error ArrayLengthMismatch();
    error RevertNegativeMint(uint256 amount);
}
