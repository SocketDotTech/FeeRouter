import { ethers, run } from "hardhat";
const hre = require("hardhat");
import { addresses } from '@socket.tech/ll-core';

export const deployFeeRouterContract = async () => {
  try {
    const { deployments, getNamedAccounts } = hre;
    const { deterministic } = deployments;
    const { deployer } = await getNamedAccounts();
    const owner = '0x5fD7D0d6b91CC4787Bcb86ca47e0Bd4ea0346d34';

    const registryAddress = addresses[hre.network.config.chainId].registry;
    console.log("registry found at: ", registryAddress);
    console.log("deployer ", deployer);
    console.log("owner", owner);
    if (!registryAddress) {
      throw new Error("registry not found");
    }

    const factory = await ethers.getContractFactory('FeeRouter');
    const feeRouterContract = await factory.deploy(registryAddress, owner);
    await feeRouterContract.deployed();


    // const { address, deploy } = await deterministic("FeeRouter", {
    //   from: deployer,
    //   args: [registryAddress, owner],
    //   salt: deployer,
    //   log: true,
    // });
    // await deploy();

    console.log("Fee router deployed at ", feeRouterContract.address);

    await sleep(30);

    // console.log(await new ethers.providers.StaticJsonRpcProvider('https://red-old-log.optimism.quiknode.pro/e6f22dd5961bc5feccf7419be75d1afb6c09d94c/').getCode('0xc1c34251Fcd223771A4002dba7bef1B4105bA61F'));
    // return;
    await run("verify:verify", {
      address: feeRouterContract.address,
      // address: '0xc9b6F5eEaBb099BBbFB130b78249E81f70EFc946', // ignore
      // address: '0xc9b6F5eEaBb099BBbFB130b78249E81f70EFc946', // polygon - verified
      // address: '0x61dFf4a2a75523767B52b0F6043a7AA96EA80846', // opt - verified
      // address: '0x7E486DE56b18e0EBe156B9d264E3e933242EB5dF', //arb 
      // address: '0x5adde24B6a11B86C23a4f61c236A8795BD4aa2bB', // ftm - verified
      // address: '0x9995A39465541a6179E22b300A782195779c056D', // avax - verified
      // address: '0x090E83668b7136075d3f76F7D6533B7256538667', // aurora
      // address: '0x61dff4a2a75523767b52b0f6043a7aa96ea80846', // binance - verified
      // address: '0xb4B34c1bE663Cae46871FC943Cb25D37c12Ef6bb', // xdai - verified
      // address: '0xfc5b37ba0f6a43fd67cdd7f30a2fc1df126a1027', // ethereum - verified
      contract: `src/FeeRouter.sol:FeeRouter`,
      constructorArguments: [registryAddress, owner],
    });


  } catch (error) {
    console.log("Error in deploying fee router", error);
    return {
      success: false,
    };
  }
};

export const sleep = (delay) =>
  new Promise((resolve) => setTimeout(resolve, delay * 1000));

deployFeeRouterContract()
  .then(() => {
    console.log("✅ finished running your wishes.");
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
