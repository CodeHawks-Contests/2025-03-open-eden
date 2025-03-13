import { task } from "hardhat/config";
import {
  Chains,
  networks,
  logger,
} from "../config";

interface SetChainToLimitTaskArgs {
  pooladdress: string;
  sourcechain: string;
  amounts: string;
  numofapprovers: string;
}

task("setChainToLimit", "Sets chain to limit")
  .addParam("pooladdress", "The address of the token pool")
  .addParam("sourcechain", "The chain to set the threshold for")
  .addParam("amounts", "The ordered array of values corresponding to the amount for a given threshold")
  .addParam("numofapprovers", "The ordered array of the number of approvals needed for a given threshold")
  .setAction(async (taskArgs: SetChainToLimitTaskArgs, hre) => {
    const {
      pooladdress: pooladdress,
      sourcechain: sourcechain,
      amounts: amounts,
      numofapprovers: numofapprovers,
    } = taskArgs;
    const networkName = hre.network.name as Chains;

    const parsedAmounts = JSON.parse(amounts); // Converts "[10,100]" into [10, 100]
    const parsedNumOfApprovers = JSON.parse(numofapprovers); 

    // Ensure the network is configured
    const networkConfig = networks[networkName];
    if (!networkConfig) {
      throw new Error(`Network ${networkName} not found in config`);
    }

    // Validate the token pool address
    if (!pooladdress || !hre.ethers.isAddress(pooladdress)) {
      throw new Error(`Invalid token pool address: ${pooladdress}`);
    }

    // Extract router and RMN proxy from the network config
    const { router, rmnProxy, confirmations } = networkConfig;
    if (!router || !rmnProxy) {
      throw new Error(`Router or RMN Proxy not defined for ${networkName}`);
    }

    try {
      const { USDOBurnMintTokenPoolWithApproval__factory } = await import("../typechain-types");
      const signer = (await hre.ethers.getSigners())[0];

      const tx = await USDOBurnMintTokenPoolWithApproval__factory.connect(
        pooladdress,
        signer
      ).setChainToLimit(sourcechain, parsedAmounts, parsedNumOfApprovers);

      await tx.wait(confirmations);
      logger.info(`Thresholds are set successfully`);
    }

    catch (error) {
      logger.error(error);
      throw new Error("Setting thresholds failed");
    }
  });
