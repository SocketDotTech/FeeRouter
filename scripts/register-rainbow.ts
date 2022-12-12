const hre = require("hardhat");
import { ethers } from "hardhat";
import { utils, ContractFactory, Contract } from "ethers";
import { addresses } from "@socket.tech/ll-core";

export interface FeeSplits {
    feeTaker: string,
    partOfTotalFeesInBps: number,
}

export interface FeeConfig {
  integratorId: number;
  totalFeeInBps: number;
  feeSplits: FeeSplits[];
}

// verify these before run
const integratorTakerAddresses = {
  [1]: '0x69D6D375DE8c7ADE7e44446dF97f49E661fDAD7d',
  [10]: '0x0d9b71891Dc86400aCc7ead08c80aF301cCb3D71',
  [56]: '0x9670271ec2e2937A2E9Df536784344bbfF2bbEa6',
  [137]: '0xFB9af3DB5E19c4165F413F53fE3bBE6226834548',
  [42161]: '0x0F9259af03052C96AFdA88ADD62eB3b5CbC185f1',
};

// verify these before run
const socketTakerAddresses = {
  [1]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
  [10]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
  [56]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
  [137]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
  [42161]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
}

// verify these before run
const integratorId = 109;
const totalFeeInBps = 2500; // PRECISION 1000000
const integratorPart = 2375;
const socketPart = 125;

const feeSplits = [{
    feeTaker: integratorTakerAddresses[hre.network.config.chainId],
    partOfTotalFeesInBps: integratorPart,
},
{
    feeTaker: socketTakerAddresses[hre.network.config.chainId],
    partOfTotalFeesInBps: socketPart
},
{
  feeTaker: ethers.constants.AddressZero,
  partOfTotalFeesInBps: 0
}];

export const registerFee = async () => {
  if (!integratorId) throw new Error("integratorId needed");
  if (!totalFeeInBps) throw new Error("totalFeeInBps needed");
  if (!integratorPart) throw new Error("integratorPart needed");
  if (!socketPart) throw new Error("socketPart needed");
  if (!integratorTakerAddresses || !integratorTakerAddresses[hre.network.config.chainId]) throw new Error("integratorTakerAddresses needed");
  if (!socketTakerAddresses || !socketTakerAddresses[hre.network.config.chainId]) throw new Error("socketTakerAddresses needed");
  try {
    const { getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();

    const signer = await ethers.getSigner(deployer);
    const factory = await ethers.getContractFactory('FeeRouter');
    const feeRouter = factory.attach(addresses[hre.network.config.chainId].feeRouter);

    const tx = await feeRouter.connect(signer).registerFeeConfig(integratorId, totalFeeInBps, feeSplits);

    console.log(tx);
    return {
      success: true,
    };
  } catch (error) {
    console.log("error in adding routes to the registry address", error);
    return {
      success: false,
    };
  }
};

registerFee()
  .then(() => {
    console.log('done')
    process.exit(0)
  })
  .catch((e) => {
    console.error('failed', e)
    process.exit(1)
  })
