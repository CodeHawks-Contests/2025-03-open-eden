# Protocol Name: OpenEden

### Prize Pool $3,200

- Starts: Friday 24th March
- Ends: Friday 24th March

- nSLOC: 221

[//]: # (contest-details-open)

## About the Project

USDO is a daily rebasing yeild bearing token which is backed by on-chain RWA tokens such as the TBILL token. With native deployments on Ethereum andBase networks, CCIP is used to transfer the shares of the USDO token over different chains via the burn and mint mechanisms.

- [Documentation](https://docs.openeden.com/)
- [Website](https://openeden.com)
- [Twitter](https://x.com/openeden_x)
- [GitHub](https://github.com/OpenEdenHQ)


## Actors

Actors:
    Primary User: Permissioned user who is allowed to mint and burn USDO tokens as well has bridge between USDO tokens in different networks.
    Issuer: Collateralises the reserves with RWA tokens and manages the key smart contracts

[//]: # (contest-details-close)

[//]: # (scope-open)

## Scope (contracts)

```bash
├── contracts
│   ├── USDOBurnMintTokenPool.sol
│   ├── USDOBurnMintTokenPoolWithApproval.sol
```

## Compatibilities

```
Compatibilities:
  Blockchains:
      - Ethereum/Any EVM
  Tokens:
      - USDO
```

[//]: # (scope-close)

[//]: # (getting-started-open)

## Setup

Build:
```bash
forge init

forge install OpenZeppelin/openzeppelin-contracts

forge install vectorized/solady

forge build
```

Tests:
```bash
Forge test
```

[//]: # (getting-started-close)

[//]: # (known-issues-open)

## Known Issues

`Known Issues:
- Addresses other than the zero address (for example 0xdead) could prevent disputes from being resolved -
Before the buyer deploys a new Escrow, the buyer and seller should  agree to the terms for the Escrow. If the
buyer accidentally or maliciously deploys an Escrow with incorrect arbiter details, then the seller could refuse
to provide their services. Given that the buyer is the actor deploying the new Escrow and locking the funds, it's
in their best interest to deploy this correctly.

- Large arbiter fee results in little/no seller payment - In this scenario, the seller can decide to not perform
the audit. If this is the case, the only way the buyer can receive any of their funds back is by initiating the dispute
process, in which the buyer loses a large portion of their deposited funds to the arbiter. Therefore, the buyer is
disincentivized to deploy a new Escrow in such a way.

- Tokens with callbacks allow malicious sellers to DOS dispute resolutions - Each supported token will be vetted
to be supported. ERC777 should be discouraged.

- Buyer never calls confirmReceipt - The terms of the Escrow are agreed upon by the buyer and seller before deploying
it. The onus is on the seller to perform due diligence on the buyer and their off-chain identity/reputation before deciding
to supply the buyer with their services.

- Salt input when creating an Escrow can be front-run

- arbiter is a trusted role

- User error such as buyer calling confirmReceipt too soon

- Non-tokenAddress funds locked`
[//]: # (known-issues-close)