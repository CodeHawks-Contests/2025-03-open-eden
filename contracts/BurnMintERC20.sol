// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

// @dev WARNING: This is for testing purposes only
contract BurnMintERC20 is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint8 internal immutable i_decimals;
    uint256 internal immutable i_maxSupply;
    address internal immutable i_owner;

    error MaxSupplyExceeded(uint256 supplyAfterMint);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _maxSupply) ERC20(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        i_maxSupply = _maxSupply;
        i_decimals = _decimals;
        i_owner = msg.sender;
    }

    function owner() public view returns (address) {
        return i_owner;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        if (i_maxSupply != 0 && totalSupply() + amount > i_maxSupply) revert MaxSupplyExceeded(totalSupply() + amount);
        _mint(to, amount);
    }

    function burn(uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    function grantMintRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, account);
    }

    function grantBurnRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(BURNER_ROLE, account);
    }

    function grantMintAndBurnRoles(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, account);
        grantRole(BURNER_ROLE, account);
    }

    function revokeMintRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, account);
    }

    function revokeBurnRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(BURNER_ROLE, account);
    }

    function decimals() public view virtual override returns (uint8) {
        return i_decimals;
    }

    function maxSupply() public view virtual returns (uint256) {
        return i_maxSupply;
    }
}
