const hre = require("hardhat");
import { ethers } from "hardhat";
import { ContractFactory, Contract } from "ethers";
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
const integratorTakerAddresses = undefined

// verify these before run
const socketTakerAddresses = undefined

// verify these before run
const integratorId = undefined
const totalFeeInBps = undefined
const integratorPart = undefined
const socketPart = undefined

if (!integratorId) throw new Error("integratorId needed");
if (!totalFeeInBps) throw new Error("totalFeeInBps needed");
if (!integratorPart) throw new Error("integratorPart needed");
if (!socketPart) throw new Error("socketPart needed");
if (!integratorTakerAddresses || !integratorTakerAddresses[hre.network.config.chainId]) throw new Error("integratorTakerAddresses needed");
if (!socketTakerAddresses || !socketTakerAddresses[hre.network.config.chainId]) throw new Error("socketTakerAddresses needed");

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
  const { getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();

  const signer = await ethers.getSigner(deployer);
  const factory: ContractFactory = await ethers.getContractFactory('FeeRouter');
  const feeRouter: Contract = factory.attach(addresses[hre.network.config.chainId].feeRouter);

  const tx = await feeRouter.connect(signer).updateFeeConfig(integratorId, totalFeeInBps, feeSplits);

  console.log(tx);
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
