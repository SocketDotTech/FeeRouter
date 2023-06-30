import { BigNumberish } from "ethers";

export const gasLimit = undefined;
export const gasPrice = undefined;
export const type = 0;

export const overrides: {
  [key: number]: {
    type: number | undefined;
    gasLimit: BigNumberish | undefined;
    gasPrice: BigNumberish | undefined;
  };
} = {
  [1]: {
    type,
    gasLimit,
    gasPrice: 50_000_000_000,
  },
  [10]: {
    type,
    gasLimit: 2_000_000,
    gasPrice,
  },
  [56]: {
    type,
    gasLimit,
    gasPrice,
  },
  [100]: {
    type,
    gasLimit,
    gasPrice,
  },
  [137]: {
    type,
    gasLimit,
    gasPrice: 500_000_000_000,
  },
  [250]: {
    type,
    gasLimit,
    gasPrice: 200_000_000_000,
  },
  [42161]: {
    type,
    gasLimit: 20_000_000,
    gasPrice,
  },
  [43114]: {
    type,
    gasLimit,
    gasPrice,
  },
  [1313161554]: {
    type,
    gasLimit,
    gasPrice,
  },
};
