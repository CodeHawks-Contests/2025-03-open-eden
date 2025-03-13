import { task } from "hardhat/config";
import {
  Chains,
  networks,
  logger,
} from "../config";

interface GrantBurnMintRolesTaskArgs {
  tokenaddress: string;
  tokenpooladdress: string;
}

// Task to grant burner and minter roles
task("grantBurnMintRoles", "Grants burner and minter roles")
  .addParam("tokenaddress", "The address of the token")
  .addParam("tokenpooladdress", "The address of the token pool")
  .setAction(async (taskArgs: GrantBurnMintRolesTaskArgs, hre) => {
    const {
      tokenaddress: tokenAddress,
      tokenpooladdress: tokenPoolAddress,
    } = taskArgs;
    const networkName = hre.network.name as Chains;

    // Ensure the network is configured
    const networkConfig = networks[networkName];
    if (!networkConfig) {
      throw new Error(`Network ${networkName} not found in config`);
    }

    // Validate the token address
    if (!tokenAddress || !hre.ethers.isAddress(tokenAddress)) {
      throw new Error(`Invalid token address: ${tokenAddress}`);
    }

    const { confirmations } = networkConfig;

    try {
      // Grant minter and burner roles to the token pool
      logger.info(
        `Granting minter and burner roles to ${tokenPoolAddress} on token ${tokenAddress}`
      );

      const { BurnMintERC20__factory } = await import("../typechain-types");
      const signer = (await hre.ethers.getSigners())[0];

      const tokenContract = BurnMintERC20__factory.connect(
        tokenAddress,
        signer
      );

      const burnerRole = await tokenContract.BURNER_ROLE();
      const minterRole = await tokenContract.MINTER_ROLE();

      // Grant roles on the token contract for the token pool
      const burnTx = await BurnMintERC20__factory.connect(
        tokenAddress,
        signer
      ).grantRole(burnerRole, tokenPoolAddress);

      await burnTx.wait(confirmations);
      logger.info(`Burner role granted to: ${tokenPoolAddress}`);

      const mintTx = await BurnMintERC20__factory.connect(
        tokenAddress,
        signer
      ).grantRole(minterRole, tokenPoolAddress);

      await mintTx.wait(confirmations);
      logger.info(`Minter role granted to: ${tokenPoolAddress}`);
    } catch (error) {
      logger.error(error);
      throw new Error("Granting burner and minter roles failed");
    }
  });
