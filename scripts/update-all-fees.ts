const hre = require("hardhat");
import { ethers } from "hardhat";
import { ContractFactory, Contract, ContractTransaction } from "ethers";
import { addresses } from "@socket.tech/ll-core";
import { allIntegratorFeeConfig } from "./all-fee-config";
import { overrides } from "./overrides";

export interface FeeSplit {
    feeTaker: string,
    partOfTotalFeesInBps: number,
}

export interface FeeConfig {
  integratorId: number;
  totalFeeInBps: number;
  feeSplits: FeeSplit[];
}

const idToSlug = {
  [1]: 'mainnet',
  [10]: 'opt',
  [56]: 'binance',
  [100]: 'xdai',
  [137]: 'polygon',
  [250]: 'fantom',
  [42161]: 'arbitrum',
  [43114]: 'avax',
  [1313161554]: 'aurora',
}

const run = async () => {
  const { getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();

  for (const integratorConfig of allIntegratorFeeConfig) {
    console.log("checking", integratorConfig.integratorName);
    const chainIds = Object.keys(integratorConfig.integratorTakerAddresses).map(c => parseInt(c))

    for (const chainId of chainIds) {
      console.log("chain", chainId);
      hre.changeNetwork(idToSlug[chainId]);

      const signer = await ethers.getSigner(deployer);
      const factory: ContractFactory = await ethers.getContractFactory('FeeRouter');
      const feeRouter: Contract = factory.attach(addresses[chainId].feeRouter);

      const oldSplits: FeeSplit[] = await feeRouter.getFeeSplits(integratorConfig.integratorId);

      const newSplits: FeeSplit[] = [{
        feeTaker: integratorConfig.integratorTakerAddresses[chainId],
        partOfTotalFeesInBps: integratorConfig.integratorPart,
      },
      {
        feeTaker: integratorConfig.socketTakerAddresses[chainId],
        partOfTotalFeesInBps: integratorConfig.socketPart
      },
      {
        feeTaker: ethers.constants.AddressZero,
        partOfTotalFeesInBps: 0
      }];

      if (
        oldSplits[0].feeTaker.toLowerCase() !== newSplits[0].feeTaker.toLowerCase() ||
        oldSplits[0].partOfTotalFeesInBps !== newSplits[0].partOfTotalFeesInBps ||
        oldSplits[1].feeTaker.toLowerCase() !== newSplits[1].feeTaker.toLowerCase() ||
        oldSplits[1].partOfTotalFeesInBps !== newSplits[1].partOfTotalFeesInBps ||
        oldSplits[2].feeTaker.toLowerCase() !== newSplits[2].feeTaker.toLowerCase() ||
        oldSplits[2].partOfTotalFeesInBps !== newSplits[2].partOfTotalFeesInBps
      ) {
        const tx: ContractTransaction = await feeRouter.connect(signer).updateFeeConfig(
          integratorConfig.integratorId,
          integratorConfig.totalFeeInBps,
          newSplits,
          { ...overrides[chainId] }
        );
        console.log("updating", tx.hash);
        await tx.wait();
        console.log("done");
      } else {
        console.log("skip");
      }
    }
  }
}

run()
  .then(() => {
    console.log('done')
    process.exit(0)
  })
  .catch((e) => {
    console.error('failed', e)
    process.exit(1)
  })
