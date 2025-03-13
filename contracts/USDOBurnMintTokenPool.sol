// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { ITypeAndVersion } from "@chainlink/contracts-ccip/src/v0.8/shared/interfaces/ITypeAndVersion.sol";
import { IUSDO } from "./interfaces/IUSDO.sol";

import { BurnMintTokenPoolAbstract } from "@chainlink/contracts-ccip/src/v0.8/ccip/pools/BurnMintTokenPoolAbstract.sol";
import { Pool } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Pool.sol";
import { TokenPool } from "@chainlink/contracts-ccip/src/v0.8/ccip/pools/TokenPool.sol";

contract USDOBurnMintTokenPool is BurnMintTokenPoolAbstract, ITypeAndVersion {
    string public constant override typeAndVersion = "USDO BurnMintTokenPool 1.5.1";

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

        emit Burned(lockOrBurnIn.originalSender, lockOrBurnIn.amount);

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

        IUSDO(address(i_token)).mint(releaseOrMintIn.receiver, destAmount);

        uint256 balancePost = IUSDO(address(i_token)).balanceOf(releaseOrMintIn.receiver);

        if (balancePost < balancePre) {
            revert RevertNegativeMint(balancePre - balancePost);
        }

        emit Minted(
            releaseOrMintIn.receiver,
            releaseOrMintIn.amount,
            balancePost - balancePre,
            srcBonusMultiplier,
            destBonusMultiplier
        );

        return Pool.ReleaseOrMintOutV1({ destinationAmount: balancePost - balancePre });
    }

    error RevertNegativeMint(uint256 amount);

    event Minted(
        address user,
        uint256 srcAmount,
        uint256 destAmount,
        uint256 srcBonusMultiplier,
        uint256 destBonusMultiplier
    );
}
