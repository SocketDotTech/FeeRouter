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
    [1]: '0x1f03565656D66E53EA0F2Fa7d72EF8eea6A6c6eE',
    [10]: '0x1f03565656D66E53EA0F2Fa7d72EF8eea6A6c6eE',
    [56]: '0x1f03565656D66E53EA0F2Fa7d72EF8eea6A6c6eE',
    [137]: '0x1f03565656D66E53EA0F2Fa7d72EF8eea6A6c6eE',
    [42161]: '0x1f03565656D66E53EA0F2Fa7d72EF8eea6A6c6eE',
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
const integratorId = 99;
const totalFeeInBps = 3000; // PRECISION 1000000
const integratorPart = 2550;
const socketPart = 450;

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
