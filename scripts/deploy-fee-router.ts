import { ethers } from "hardhat";
const hre = require("hardhat");
import { addresses } from '@socket.tech/ll-core';

export const deployFeeRouterContract = async () => {
  try {
    const { deployments, getNamedAccounts } = hre;
    const { deterministic } = deployments;
    const { deployer } = await getNamedAccounts();

    const registryAddress = addresses[hre.network.config.chainId].registry;
    console.log("registry found at: ", registryAddress);
    console.log("deployer ", deployer);
    if (!registryAddress) {
      throw new Error("registry not found");
    }

    const { address, deploy } = await deterministic("FeeRouter", {
      from: deployer,
      args: [registryAddress, deployer],
      salt: deployer,
      log: true,
    });
    await deploy();

    console.log("Fee router deployed at ", address);

  } catch (error) {
    console.log("Error in deploying fee router", error);
    return {
      success: false,
    };
  }
};

deployFeeRouterContract()
  .then(() => {
    console.log("✅ finished running your wishes.");
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
