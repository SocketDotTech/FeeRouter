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
    [1]: '0xD7Db28c3D78023755D308519DCa82cEB9161e92C',
    [10]: '0x31F76340d97133F7F25d290Ae38dacb6E37F6566',
    [56]: '0xd4e8b950b06d4853Dd07acad9CeA1Bb2D4E359a5',
    [100]: '0x840D0384B78e923ab7Cdb6ffb470eBd2447DF71d',
    [137]: '0x6dc769Da9DCADfbee3797AcA69A4B25848E61224',
    [250]: '0x43A2A720cD0911690C248075f4a29a5e7716f758',
    [42161]: '0xAc341e26271824Ab14A107B71b403ca16a16E2dc',
    [43114]: '0xA1eD950466EF738fB5d59E5AC82e2cd0d6109E9c',
    [1313161554]: '0x299EfDC85FeEcE558A3042ed2dA1c32ada382479',
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

const integratorId = 88;
const totalFeeInBps = 5000; // PRECISION 1000000
const integratorPart = 4250;
const socketPart = 750;

const feeSplits = [{
    feeTaker: integratorTakerAddresses[hre.network.config.chainId],
    partOfTotalFeesInBps: integratorPart,
},
{
    feeTaker: socketTakerAddresses[hre.network.config.chainId],
    partOfTotalFeesInBps: socketPart
}];

export const registerFee = async () => {
  try {
    const { getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();

    const signer = await ethers.getSigner(deployer);
    const factory = await ethers.getContractFactory('FeeRouter');
    const feeRouter = factory.attach(addresses['feeRouter'][hre.network.config.chainId]);

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
