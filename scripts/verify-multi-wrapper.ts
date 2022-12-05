import { ethers, run } from "hardhat";
const hre = require("hardhat");
import { addresses } from '@socket.tech/ll-core';

export const verifyMultiRequestExecutorContract = async () => {
  try {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();
    const owner = '0x2FA81527389929Ae9FD0f9ACa9e16Cba37D3EeA1';
    const registryAddress = addresses[hre.network.config.chainId].registry;
    console.log("registry found at: ", registryAddress);
    console.log("deployer ", deployer);
    console.log("owner", owner);
    if (!registryAddress) {
      throw new Error("registry not found");
    }
    await run("verify:verify", {
      address: '0xB54347eC93060f8aE64023FfD2C87A4A66058f09',
      contract: `src/multi/MultiRequestExecutor.sol:MultiRequestExecutor`,
      constructorArguments: [registryAddress, owner],
    });

  } catch (error) {
    console.log("Error in verification of MultiRequestExecutor", error);
    return {
      success: false,
    };
  }
};

export const sleep = (delay) =>
  new Promise((resolve) => setTimeout(resolve, delay * 1000));

  verifyMultiRequestExecutorContract()
  .then(() => {
    console.log("✅ finished running your wishes.");
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
