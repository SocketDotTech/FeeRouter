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

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
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

        ISocketRegistry.UserRequest memory userRequest1;
        userRequest1.receiverAddress = sender1;
        userRequest1.toChainId = 137;
        userRequest1.amount = 1000e6;
        userRequest1.bridgeRequest.inputToken = USDC;
        userRequest1.bridgeRequest.id = 1;
        userRequest1.bridgeRequest.optionalNativeAmount = 0;
        userRequests[0] = userRequest1;

        ISocketRegistry.UserRequest memory userRequest2;
        userRequest2.receiverAddress = sender1;
        userRequest2.toChainId = 137;
        userRequest2.amount = 1000e6;
        userRequest2.bridgeRequest.inputToken = USDC;
        userRequest2.bridgeRequest.id = 2;
        userRequest2.bridgeRequest.optionalNativeAmount = 0;
        userRequests[1] = userRequest2;

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
