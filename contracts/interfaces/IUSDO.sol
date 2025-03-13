// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IBurnMintERC20 } from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";

interface IUSDO is IBurnMintERC20 {
    function bonusMultiplier() external view returns (uint256);
}
