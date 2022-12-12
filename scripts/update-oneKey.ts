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

const integratorTakerAddresses = {
    [1]: '0x4f5fc02be49bea15229041b87908148b04c14717',
    [10]: '0x4f5fc02be49bea15229041b87908148b04c14717',
    [56]: '0x4f5fc02be49bea15229041b87908148b04c14717',
    [100]: '0x4f5fc02be49bea15229041b87908148b04c14717',
    [137]: '0x4f5fc02be49bea15229041b87908148b04c14717',
    [250]: '0x4f5fc02be49bea15229041b87908148b04c14717',
    [42161]: '0x4f5fc02be49bea15229041b87908148b04c14717',
    [43114]: '0x4f5fc02be49bea15229041b87908148b04c14717',
    [1313161554]: '0x4f5fc02be49bea15229041b87908148b04c14717',
};

const socketTakerAddresses = {
    [1]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
    [10]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
    [56]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
    [100]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
    [137]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
    [250]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
    [42161]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
    [43114]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
    [1313161554]: '0x59483D576e949d84D3BeDB5AAB24353A9f375093',
}

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

export const updateFee = async () => {
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

    const tx = await feeRouter.connect(signer).updateFeeConfig(integratorId, totalFeeInBps, feeSplits, {nonce: 195});

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

updateFee()
  .then(() => {
    console.log('done')
    process.exit(0)
  })
  .catch((e) => {
    console.error('failed', e)
    process.exit(1)
  })
