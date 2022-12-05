const { ethers } = require('ethers');
const MultiRequestExecutorABI = require('../abi/MultiRequestExecutor');

(async () => {
    console.log(`inside gen data`);  

     const EMPTY_EXTRA_DATA = ethers.utils.defaultAbiCoder.encode(
        ["address"],
        ["0x0000000000000000000000000000000000000000"],
      );
      
    // const factory = await ethers.getContractFactory('MultiRequestExecutor');
    // const multiRequestExecutor = factory.attach('0xB54347eC93060f8aE64023FfD2C87A4A66058f09');
    
    const sender = "0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57";
    const USDC_Polygon = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
    const AnyUSDC_Polygon = "0xd69b31c3225728CC57ddaf9be532a4ee1620Be51";

    const celerExtraData = ethers.utils.defaultAbiCoder.encode(
        ["uint64", "uint32", "address"],
        [1670319344, 500, sender],
      );

    const bridgeRequest_Celer = {
          id: 1,
          optionalNativeAmount: 0,
          inputToken: USDC_Polygon,
          data: celerExtraData,
    };

    const userRequest_Celer = {
        receiverAddress: sender,
        toChainId: 10,
        amount: 10000000,
        middlewareRequest: {
            id: 0,
            inputToken: USDC_Polygon,
            data: EMPTY_EXTRA_DATA,
            optionalNativeAmount: 0,
        },
        bridgeRequest: bridgeRequest_Celer
    };

    const anyswapExtraData = ethers.utils.defaultAbiCoder.encode(
        ["address"],
        [AnyUSDC_Polygon],
      );

    const bridgeRequest_Anyswap = {
        id: 4,
        optionalNativeAmount: 0,
        inputToken: USDC_Polygon,
        data: anyswapExtraData,
    };

    const userRequest_Anyswap = {
        receiverAddress: sender,
        toChainId: 10,
        amount: 5000000,
        middlewareRequest: {
            id: 1,
            inputToken: USDC_Polygon,
            data: EMPTY_EXTRA_DATA,
            optionalNativeAmount: 0,
        },
        bridgeRequest: bridgeRequest_Anyswap
    };

    const multiRequest = { userRequests: [userRequest_Celer, userRequest_Anyswap]};

    const abiInterface = new ethers.utils.Interface(MultiRequestExecutorABI);
    const txData = abiInterface.encodeFunctionData(
       'execute',
       [[ 
         [sender, 10, 10000000, [0 , USDC_Polygon, EMPTY_EXTRA_DATA, 0], [1,0,USDC_Polygon,celerExtraData]],
         [sender, 10, 5000000,  [1 , USDC_Polygon, EMPTY_EXTRA_DATA, 0], [4,0,USDC_Polygon,anyswapExtraData]]
       ]]); 

    console.log(`txnData: ${JSON.stringify(txData)}`);
})().catch((e) => {
   console.error('error: ', e);
});