import { task } from "hardhat/config";
import {
  Chains,
  networks,
  logger,
} from "../config";

interface SetApproversTaskArgs {
  offrampaddress: string;
  pooladdress: string;
}

task("setApprovers", "Sets an array of approvers")
  .addParam("pooladdress", "The address of the token")
  .addParam("offrampaddress", "The address of the off ramp contract")
  .setAction(async (taskArgs: SetApproversTaskArgs, hre) => {
    const {
      offrampaddress: offrampaddress,
      pooladdress: pooladdress,
    } = taskArgs;
    const networkName = hre.network.name as Chains;

    // Ensure the network is configured
    const networkConfig = networks[networkName];
    if (!networkConfig) {
      throw new Error(`Network ${networkName} not found in config`);
    }

    // Validate the token pool address
    if (!pooladdress || !hre.ethers.isAddress(pooladdress)) {
      throw new Error(`Invalid token pool address: ${pooladdress}`);
    }

    // Validate the off ramp address
    if (!offrampaddress || !hre.ethers.isAddress(offrampaddress)) {
      throw new Error(`Invalid off ramp address: ${offrampaddress}`);
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
      ).setApprovers([offrampaddress]);

      await tx.wait(confirmations);
      logger.info(`Approver added successfully`);
    }

    catch (error) {
      logger.error(error);
      throw new Error("Adding approval failed");
    }
  });
