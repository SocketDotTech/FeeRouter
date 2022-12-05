import { ethers } from 'ethers';
import { MultiRequestExecutorABI } from '../abi/MultiRequestExecutor';
import  { MultiRequestParams } from './multi-request-params';

(async () => {
    console.log(`inside gen data`);  

     const EMPTY_EXTRA_DATA = ethers.utils.defaultAbiCoder.encode(
        ["address"],
        ["0x0000000000000000000000000000000000000000"],
      );
      
    // const factory = await ethers.getContractFactory('MultiRequestExecutor');
    // const multiRequestExecutor = factory.attach('0xB54347eC93060f8aE64023FfD2C87A4A66058f09');
    
    const sender = "0x06959153b974d0d5fdfd87d561db6d8d4fa0bb0b";
    const USDC_Polygon = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
    const AnyUSDC_Polygon = "0xd69b31c3225728CC57ddaf9be532a4ee1620Be51";

    // extra data for hop
    const hopExtraData = ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint256", "uint256", "uint256", "address"],
      // bridge addr, relayer addr, amt out min, relayer fee, deadline, tokenAddress
      [
        "0xa3f9a7a13055f37479Ebc28E57C005F5c9A31F68",
        "0x0000000000000000000000000000000000000000",
        4000000,
        0,
        0,
        USDC_Polygon,
      ],
    );

    // extra data for across
    const acrossExtraData = ethers.utils.defaultAbiCoder.encode(
      ["address", 'uint64', 'uint32'],
      [USDC_Polygon, "172040000000000", "1670245675"],
    );

    const functionParams: MultiRequestParams[] = 
      [
        {
        userRequests: [
              {
                  receiverAddress: sender,
                  toChainId: 42161,
                  amount: "10000000",
                  middlewareRequest: {
                      id: 0,
                      inputToken: USDC_Polygon,
                      data: EMPTY_EXTRA_DATA,
                      optionalNativeAmount: 0,
                  },
                  bridgeRequest: {
                    id: 14,
                    optionalNativeAmount: 0,
                    inputToken: USDC_Polygon,
                    data: EMPTY_EXTRA_DATA,
                 }
              },
              {
                receiverAddress: sender,
                toChainId: 42161,
                amount: "4000000",
                middlewareRequest: {
                    id: 0,
                    inputToken: USDC_Polygon,
                    data: EMPTY_EXTRA_DATA,
                    optionalNativeAmount: 0,
                },
                bridgeRequest: {
                  id: 13,
                  optionalNativeAmount: 0,
                  inputToken: USDC_Polygon,
                  data: acrossExtraData,
                }
              }
           ]
          }
      ];
    
    const abiInterface = new ethers.utils.Interface(MultiRequestExecutorABI);
    const txData = abiInterface.encodeFunctionData(
      'execute',
      functionParams,
    );
    console.log(`txnData: ${JSON.stringify(txData)}`);
})().catch((e) => {
   console.error('error: ', e);
});