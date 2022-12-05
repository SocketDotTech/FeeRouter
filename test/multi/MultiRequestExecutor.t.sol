// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// Tests
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "forge-std/Script.sol";

// Contracts
import "../../src/interfaces/ISocketRegistry.sol";
import "../../src/utils/Ownable.sol";
import "../../src/multi/MultiRequestExecutor.sol";

contract MultiRequestExecutorTest is Test {

    MultiRequestExecutor public multiRequestExecutor;
    ISocketRegistry public socketRegistry;

    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant AnyUSDC_Polygon = 0xd69b31c3225728CC57ddaf9be532a4ee1620Be51;
    address constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address constant owner = 0x0E1B5AB67aF1c99F8c7Ebc71f41f75D4D6211e53;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant RegistryAddress = 0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0;

    function setUp() public {
        multiRequestExecutor = new MultiRequestExecutor(
            RegistryAddress,
            owner
        );
        socketRegistry =
            ISocketRegistry(RegistryAddress);
    }

    function testMultiBridges() public {

        ISocketRegistry.UserRequest[] memory userRequests = new ISocketRegistry.UserRequest[](2);

        //Celer
        ISocketRegistry.UserRequest memory userRequest_Celer;
        userRequest_Celer.receiverAddress = sender1;
        userRequest_Celer.toChainId = 10;
        userRequest_Celer.amount = 1000e6;
        userRequest_Celer.bridgeRequest.inputToken = USDC;
        userRequest_Celer.bridgeRequest.id = 20;
        userRequest_Celer.bridgeRequest.optionalNativeAmount = 0;

        bytes memory extraData_Celer = abi.encode(block.timestamp, 501, sender1);
        userRequest_Celer.bridgeRequest.data = extraData_Celer;
        userRequests[0] = userRequest_Celer;

        //AnySwap
        ISocketRegistry.UserRequest memory userRequest_AnySwap;
        userRequest_AnySwap.receiverAddress = sender1;
        userRequest_AnySwap.toChainId = 10;
        userRequest_AnySwap.amount = 1000e6;
        userRequest_AnySwap.bridgeRequest.inputToken = USDC;
        userRequest_AnySwap.bridgeRequest.id = 2;
        userRequest_AnySwap.bridgeRequest.optionalNativeAmount = 0;

        // extra data for Anyswap (Wrapper - AnyUSDC Address)
        bytes memory data = abi.encode(AnyUSDC_Polygon);
        userRequest_AnySwap.bridgeRequest.data = data;
        userRequests[1] = userRequest_AnySwap;


        //Hop
        



        //MultiRequest Generation
        MultiRequestExecutor.MultiRequest memory multiRequest;
        multiRequest.userRequests = userRequests;

        deal(sender1, 100e18);
        assertEq(sender1.balance, 100e18);
        deal(address(USDC), sender1, 3000e6);
        assertEq(IERC20(USDC).balanceOf(sender1), 3000e6);

        vm.startPrank(sender1);
        IERC20(USDC).approve(address(multiRequestExecutor), 3000e6);
        multiRequestExecutor.execute(multiRequest);
        vm.stopPrank();
    }
}
