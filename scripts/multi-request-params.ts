import { BigNumberish } from '@ethersproject/bignumber';

export interface MultiRequestParams {
  userRequests: UserRequestParams[];
}

export interface UserRequestParams {
  receiverAddress: string;
  toChainId: number;
  amount: string;
  middlewareRequest: {
    id: number | string;
    inputToken: string;
    optionalNativeAmount: BigNumberish;
    data: string;
  };
  bridgeRequest: {
    id: number | string;
    inputToken: string;
    optionalNativeAmount: BigNumberish;
    data: string;
  };
}