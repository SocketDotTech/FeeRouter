// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// Tests
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "forge-std/Script.sol";

// Contracts
import "../src/interfaces/ISocketRegistry.sol";
import "../src/utils/Ownable.sol";
import "../src/FeeRouter.sol";

contract FeeRouterTest is Test {
    event RegisterFee(
        uint16 integratorId,
        uint16 totalFeeInBps,
        uint16 part1,
        uint16 part2,
        uint16 part3,
        address feeTaker1,
        address feeTaker2,
        address feeTaker3
    );
    event UpdateFee(
        uint16 integratorId,
        uint16 totalFeeInBps,
        uint16 part1,
        uint16 part2,
        uint16 part3,
        address feeTaker1,
        address feeTaker2,
        address feeTaker3
    );
    event ClaimFee(
        uint16 integratorId,
        address tokenAddress,
        uint256 amount,
        address owner
    );
    event BridgeSocket(
        uint256 amount,
        address inputTokenAddress,
        uint16 integratorId,
        uint256 toChainId,
        uint256 middlewareId,
        uint256 bridgeId,
        uint256 totalFee
    );
    FeeRouter public feeRouter;
    ISocketRegistry public socketRegistry;

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant owner = 0x0E1B5AB67aF1c99F8c7Ebc71f41f75D4D6211e53;
    address constant feeTaker1 = 0x3db45921CCb05A28270E2F99B49A33E65C065983;
    address constant feeTaker2 = 0x0e038Ad2838aa71eC990E61688C08F395E92b9d9;
    address constant sender1 = 0xD07E50196a05e6f9E6656EFaE10fc9963BEd6E57;
    uint16 integratorId = 3;
    uint16 totalFees10 = 10;
    uint16 totalFees0 = 0;
    uint16 totalFees100 = 100;
    uint16 part3 = 3;
    uint16 part7 = 7;
    uint16 part4 = 4;

    uint16 part30 = 30;
    uint16 part70 = 70;
    uint16 part40 = 40;

    function setUp() public {
        feeRouter = new FeeRouter(
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            owner
        );
        socketRegistry = ISocketRegistry(
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0
        );
    }

    // REGISTER  FEE TESTS --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------->

    // Should Successfully pass with correct owner calling register.
    // function testOwnerRegisterSuccess() public {
    //     vm.startPrank(owner);

    //     uint16 totalFeeInBps = 0;
    //     FeeRouter.FeeSplits[3] memory feeSplits;
    //     feeSplits[0].owner = feeTaker1;
    //     feeRouter.registerFeeConfig(1, totalFeeInBps, feeSplits);
    //     vm.stopPrank();
    // }

    // // Should revert if register is not called by the owner
    // function testOwnerRegisterRevert() public {
    //     vm.startPrank(feeTaker1);

    //     FeeRouter.FeeSplits[3] memory feeSplits;
    //     feeSplits[0].owner = feeTaker1;
    //     vm.expectRevert(0x5fc483c5);
    //     feeRouter.registerFeeConfig(1, totalFees10, feeSplits);
    //     vm.stopPrank();
    // }

    // // Should fail since total fees should be equal to the parts.
    // function testRegisterFeeWithUnequalParts() public {
    //     vm.startPrank(owner);

    //     // Create FeeSplit - 1
    //     FeeRouter.FeeSplits memory feeSplit1;
    //     feeSplit1.owner = owner;
    //     feeSplit1.partOfTotalFeesInBps = part3;

    //     // Create FeeSplit - 2
    //     FeeRouter.FeeSplits memory feeSplit2;
    //     feeSplit2.owner = owner;
    //     feeSplit2.partOfTotalFeesInBps = part4;

    //     FeeRouter.FeeSplits[3] memory feeSplits;
    //     feeSplits[0] = feeSplit1;
    //     feeSplits[1] = feeSplit2;

    //     // console.log(feeSplits.length);

    //     // Create FeeConfig - Should Revert
    //     vm.expectRevert(
    //         abi.encodePacked(
    //             "Total Fee in BPS should be equal to the summation of fees when split."
    //         )
    //     );
    //     feeRouter.registerFeeConfig(3, totalFees10, feeSplits);

    //     vm.stopPrank();
    // }

    // // Should Successfully register
    // function testRegisterFeeSuccess() public {
    //     vm.startPrank(owner);
    //     // Create Config
    //     FeeRouter.FeeConfig memory feeConfig;

    //     // Create FeeSplit - 1
    //     FeeRouter.FeeSplits memory feeSplit1;
    //     feeSplit1.owner = feeTaker1;
    //     feeSplit1.partOfTotalFeesInBps = part3;

    //     // Create FeeSplit - 2
    //     FeeRouter.FeeSplits memory feeSplit2;
    //     feeSplit2.owner = feeTaker2;
    //     feeSplit2.partOfTotalFeesInBps = part7;

    //     // Set Fee Config
    //     feeConfig.feeSplits[0] = feeSplit1;
    //     feeConfig.feeSplits[1] = feeSplit2;
    //     feeConfig.totalFeeInBps = totalFees10;

    //     // Expect Event Emit
    //     vm.expectEmit(false, false, false, true);
    //     emit RegisterFee(integratorId, feeConfig);
    //     feeRouter.registerFeeConfig(integratorId, feeConfig);

    //     // Get Fee Config From the router.
    //     FeeRouter.FeeConfig memory registeredFeeConfig = feeRouter.getFeeConfig(
    //         integratorId
    //     );

    //     // Assertions.
    //     assertEq(totalFees10, registeredFeeConfig.totalFeeInBps);
    //     assertEq(feeTaker1, registeredFeeConfig.feeSplits[0].owner);
    //     assertEq(feeTaker2, registeredFeeConfig.feeSplits[1].owner);
    //     assertEq(part3, registeredFeeConfig.feeSplits[0].partOfTotalFeesInBps);
    //     assertEq(part7, registeredFeeConfig.feeSplits[1].partOfTotalFeesInBps);

    //     vm.stopPrank();
    // }

    // // Should Revert, since the same integrator Id can only update the fee, cannot register again.
    // function testRegisterFeeRevertForSameIntegrator() public {
    //     vm.startPrank(owner);
    //     FeeRouter.FeeConfig memory feeConfig;

    //     feeConfig.totalFeeInBps = 0;
    //     feeConfig.feeSplits[0].owner = feeTaker1;
    //     feeRouter.registerFeeConfig(1, feeConfig);

    //     vm.expectRevert(
    //         abi.encodePacked("Integrator Id is already registered")
    //     );
    //     feeRouter.registerFeeConfig(1, feeConfig);
    //     vm.stopPrank();
    // }

    // // UPDATE FEE TESTS ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------>

    // // Only Owner should be able to update the fee config for an integrator Id.
    // function testUpdateFeeSuccessOnlyOwner() public {
    //     vm.startPrank(owner);
    //     FeeRouter.FeeConfig memory feeConfig;

    //     feeConfig.totalFeeInBps = 0;
    //     feeConfig.feeSplits[0].owner = feeTaker1;
    //     feeRouter.registerFeeConfig(1, feeConfig);

    //     feeRouter.updateFeeConfig(1, feeConfig);
    //     vm.stopPrank();
    // }

    // // Shpuld revert if update is tried from a different address than owner.
    // function testUpdateFeeRevertOnlyOwner() public {
    //     vm.startPrank(owner);
    //     FeeRouter.FeeConfig memory feeConfig;

    //     feeConfig.totalFeeInBps = 0;
    //     feeConfig.feeSplits[0].owner = feeTaker1;
    //     feeRouter.registerFeeConfig(1, feeConfig);
    //     vm.stopPrank();

    //     vm.startPrank(feeTaker1);
    //     vm.expectRevert(0x5fc483c5);
    //     feeRouter.updateFeeConfig(1, feeConfig);
    //     vm.stopPrank();
    // }

    // // Should not update the fee for an unregistered integrator Id.
    // function testUpdateFeeRevertForUnregisteredIntegrator() public {
    //     vm.startPrank(owner);
    //     FeeRouter.FeeConfig memory feeConfig;

    //     feeConfig.totalFeeInBps = 0;
    //     feeConfig.feeSplits[0].owner = feeTaker1;
    //     feeRouter.registerFeeConfig(1, feeConfig);

    //     vm.expectRevert(abi.encodePacked("Integrator Id is not registered"));
    //     feeRouter.updateFeeConfig(2, feeConfig);
    //     vm.stopPrank();
    // }

    // // Should not set the owner fo the first fee split to 0, assumption being that there should be an owner to claim the fee.
    // function testUpdateFeeRevertForZeroOwner() public {
    //     vm.startPrank(owner);
    //     FeeRouter.FeeConfig memory feeConfig;

    //     feeConfig.totalFeeInBps = 0;
    //     feeConfig.feeSplits[0].owner = feeTaker1;
    //     feeRouter.registerFeeConfig(1, feeConfig);

    //     feeConfig.feeSplits[0].owner = address(0);
    //     vm.expectRevert(abi.encodePacked("ZERO_ADDRESS not owner"));
    //     feeRouter.updateFeeConfig(1, feeConfig);
    //     vm.stopPrank();
    // }

    // // Should Successfully Update the fee after registration.
    // function testUpdateFeeSuccessWithAssertions() public {
    //     vm.startPrank(owner);
    //     // Create Config
    //     FeeRouter.FeeConfig memory feeConfig;

    //     // Create FeeSplit - 1
    //     FeeRouter.FeeSplits memory feeSplit1;
    //     feeSplit1.owner = feeTaker1;
    //     feeSplit1.partOfTotalFeesInBps = part3;

    //     // Create FeeSplit - 2
    //     FeeRouter.FeeSplits memory feeSplit2;
    //     feeSplit2.owner = feeTaker2;
    //     feeSplit2.partOfTotalFeesInBps = part7;

    //     // Set Fee Config
    //     feeConfig.feeSplits[0] = feeSplit1;
    //     feeConfig.feeSplits[1] = feeSplit2;
    //     feeConfig.totalFeeInBps = totalFees10;

    //     feeRouter.registerFeeConfig(integratorId, feeConfig);

    //     feeSplit1.partOfTotalFeesInBps = part30;
    //     feeSplit2.partOfTotalFeesInBps = part70;
    //     feeConfig.feeSplits[0] = feeSplit1;
    //     feeConfig.feeSplits[1] = feeSplit2;
    //     feeConfig.totalFeeInBps = totalFees100;

    //     // Emits Event
    //     vm.expectEmit(false, false, false, true);
    //     emit UpdateFee(integratorId, feeConfig);
    //     feeRouter.updateFeeConfig(integratorId, feeConfig);

    //     // Get Fee Config
    //     FeeRouter.FeeConfig memory registeredFeeConfig = feeRouter.getFeeConfig(
    //         integratorId
    //     );

    //     // Assertions.
    //     assertEq(totalFees100, registeredFeeConfig.totalFeeInBps);
    //     assertEq(feeTaker1, registeredFeeConfig.feeSplits[0].owner);
    //     assertEq(feeTaker2, registeredFeeConfig.feeSplits[1].owner);
    //     assertEq(part30, registeredFeeConfig.feeSplits[0].partOfTotalFeesInBps);
    //     assertEq(part70, registeredFeeConfig.feeSplits[1].partOfTotalFeesInBps);

    //     vm.stopPrank();
    // }

    // // Should revert if the parts and the total fee do not match.
    // function testUpdateFeeRevertForUnequalParts() public {
    //     vm.startPrank(owner);
    //     // Create Config
    //     FeeRouter.FeeConfig memory feeConfig;

    //     // Create FeeSplit - 1
    //     FeeRouter.FeeSplits memory feeSplit1;
    //     feeSplit1.owner = feeTaker1;
    //     feeSplit1.partOfTotalFeesInBps = part3;

    //     // Create FeeSplit - 2
    //     FeeRouter.FeeSplits memory feeSplit2;
    //     feeSplit2.owner = feeTaker2;
    //     feeSplit2.partOfTotalFeesInBps = part7;

    //     // Set Fee Config
    //     feeConfig.feeSplits[0] = feeSplit1;
    //     feeConfig.feeSplits[1] = feeSplit2;
    //     feeConfig.totalFeeInBps = totalFees10;

    //     feeRouter.registerFeeConfig(integratorId, feeConfig);

    //     feeSplit1.partOfTotalFeesInBps = part3;
    //     feeSplit2.partOfTotalFeesInBps = part7;
    //     feeConfig.feeSplits[0] = feeSplit1;
    //     feeConfig.feeSplits[1] = feeSplit2;
    //     feeConfig.totalFeeInBps = totalFees100;

    //     // Emits Event
    //     vm.expectRevert(abi.encodePacked("Total Fee in BPS should be equal to the summation of fees when split."));
    //     feeRouter.updateFeeConfig(integratorId, feeConfig);
    // }

    // // FEE DEDUCTION TESTS --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------->
    
    // // Unregistered Integrator Ids should be reverted.
    // function testDeductionOfFeeWithUnregisteredIntegratorId() public {
    //     deal(sender1, 100e18);
    //     deal(address(DAI), sender1, 1000e18);
    //     assertEq(sender1.balance, 100e18);
    //     assertEq(IERC20(DAI).balanceOf(sender1), 1000e18);

    //     FeeRouter.FeeRequest memory feeRequest;
    //     feeRequest.integratorId = 100;
    //     feeRequest.userRequest.receiverAddress = sender1;
    //     feeRequest.userRequest.toChainId = 137;
    //     feeRequest.userRequest.amount = 1000e18;
    //     feeRequest.userRequest.bridgeRequest.inputToken = DAI;
    //     feeRequest.userRequest.bridgeRequest.id = 2;
    //     feeRequest.userRequest.bridgeRequest.optionalNativeAmount = 0;
    //     feeRequest.userRequest.middlewareRequest.inputToken = DAI;
    //     feeRequest.userRequest.middlewareRequest.id = 0;
    //     feeRequest.userRequest.middlewareRequest.optionalNativeAmount = 0;

    //     vm.startPrank(sender1);
    //     vm.expectRevert(abi.encodePacked("FeeConfig is not registered."));
    //     feeRouter.deductFeeAndCallRegistry(feeRequest);
    //     vm.stopPrank();
    // }

    // // Deduction of Fee should be accurate. 
    // function testDeductFeeAndCallRegistryForDAI() public {
    //     deal(sender1, 100e18);
    //     deal(address(DAI), sender1, 1000e18);
    //     assertEq(sender1.balance, 100e18);
    //     assertEq(IERC20(DAI).balanceOf(sender1), 1000e18);

    //     vm.startPrank(owner);
    //     // Create Config
    //     FeeRouter.FeeConfig memory feeConfig;

    //     // Create FeeSplit - 1
    //     FeeRouter.FeeSplits memory feeSplit1;
    //     feeSplit1.owner = feeTaker1;
    //     feeSplit1.partOfTotalFeesInBps = part3;

    //     // Create FeeSplit - 2
    //     FeeRouter.FeeSplits memory feeSplit2;
    //     feeSplit2.owner = feeTaker2;
    //     feeSplit2.partOfTotalFeesInBps = part7;

    //     // Set Fee Config
    //     feeConfig.feeSplits[0] = feeSplit1;
    //     feeConfig.feeSplits[1] = feeSplit2;
    //     feeConfig.totalFeeInBps = totalFees10;

    //     feeRouter.registerFeeConfig(100, feeConfig);
    //     vm.stopPrank();

    //     FeeRouter.FeeRequest memory feeRequest;
    //     feeRequest.integratorId = 100;
    //     feeRequest.userRequest.receiverAddress = sender1;
    //     feeRequest.userRequest.toChainId = 137;
    //     feeRequest.userRequest.amount = 1000e18;
    //     feeRequest.userRequest.bridgeRequest.inputToken = DAI;
    //     feeRequest.userRequest.bridgeRequest.id = 2;
    //     feeRequest.userRequest.bridgeRequest.optionalNativeAmount = 0;
    //     feeRequest.userRequest.middlewareRequest.inputToken = DAI;
    //     feeRequest.userRequest.middlewareRequest.id = 0;
    //     feeRequest.userRequest.middlewareRequest.optionalNativeAmount = 0;

    //     vm.startPrank(sender1);
    //     IERC20(DAI).approve(address(feeRouter),1000e18);
    //     // vm.expectRevert(abi.encodePacked("FeeConfig is not registered."));
    //     feeRouter.deductFeeAndCallRegistry(feeRequest);

    //     assertEq(1e18,feeRouter.getEarnedFee(address(DAI), 100));
    //     vm.stopPrank();
    // }

    // function testDeductFeeAndCallRegistryForUSDC() public {
    //     deal(sender1, 100e18);
    //     deal(address(USDC), sender1, 1000e6);
    //     assertEq(sender1.balance, 100e18);
    //     assertEq(IERC20(USDC).balanceOf(sender1), 1000e6);

    //     vm.startPrank(owner);
    //     // Create Config
    //     FeeRouter.FeeConfig memory feeConfig;

    //     // Create FeeSplit - 1
    //     FeeRouter.FeeSplits memory feeSplit1;
    //     feeSplit1.owner = feeTaker1;
    //     feeSplit1.partOfTotalFeesInBps = part3;

    //     // Create FeeSplit - 2
    //     FeeRouter.FeeSplits memory feeSplit2;
    //     feeSplit2.owner = feeTaker2;
    //     feeSplit2.partOfTotalFeesInBps = part7;

    //     // Set Fee Config
    //     feeConfig.feeSplits[0] = feeSplit1;
    //     feeConfig.feeSplits[1] = feeSplit2;
    //     feeConfig.totalFeeInBps = totalFees10;

    //     feeRouter.registerFeeConfig(100, feeConfig);
    //     vm.stopPrank();

    //     FeeRouter.FeeRequest memory feeRequest;
    //     feeRequest.integratorId = 100;
    //     feeRequest.userRequest.receiverAddress = sender1;
    //     feeRequest.userRequest.toChainId = 137;
    //     feeRequest.userRequest.amount = 1000e6;
    //     feeRequest.userRequest.bridgeRequest.inputToken = USDC;
    //     feeRequest.userRequest.bridgeRequest.id = 2;
    //     feeRequest.userRequest.bridgeRequest.optionalNativeAmount = 0;
    //     feeRequest.userRequest.middlewareRequest.inputToken = USDC;
    //     feeRequest.userRequest.middlewareRequest.id = 0;
    //     feeRequest.userRequest.middlewareRequest.optionalNativeAmount = 0;

    //     vm.startPrank(sender1);
    //     IERC20(USDC).approve(address(feeRouter),1000e6);
    //     // vm.expectRevert(abi.encodePacked("FeeConfig is not registered."));
    //     feeRouter.deductFeeAndCallRegistry(feeRequest);

    //     assertEq(1e6,feeRouter.getEarnedFee(address(USDC), 100));
    //     vm.stopPrank();
    // }


    // // CLAIM EARNED FEE TESTS ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------>
    // function testClaimFeeUSDC() public {
    //     deal(sender1, 100e18);
    //     deal(address(USDC), sender1, 1000e6);
    //     assertEq(sender1.balance, 100e18);
    //     assertEq(IERC20(USDC).balanceOf(sender1), 1000e6);

    //     vm.startPrank(owner);
    //     // Create Config
    //     FeeRouter.FeeConfig memory feeConfig;

    //     // Create FeeSplit - 1
    //     FeeRouter.FeeSplits memory feeSplit1;
    //     feeSplit1.owner = feeTaker1;
    //     feeSplit1.partOfTotalFeesInBps = part3;

    //     // Create FeeSplit - 2
    //     FeeRouter.FeeSplits memory feeSplit2;
    //     feeSplit2.owner = feeTaker2;
    //     feeSplit2.partOfTotalFeesInBps = part7;

    //     // Set Fee Config
    //     feeConfig.feeSplits[0] = feeSplit1;
    //     feeConfig.feeSplits[1] = feeSplit2;
    //     feeConfig.totalFeeInBps = totalFees10;

    //     feeRouter.registerFeeConfig(100, feeConfig);
    //     vm.stopPrank();

    //     FeeRouter.FeeRequest memory feeRequest;
    //     feeRequest.integratorId = 100;
    //     feeRequest.userRequest.receiverAddress = sender1;
    //     feeRequest.userRequest.toChainId = 137;
    //     feeRequest.userRequest.amount = 1000e6;
    //     feeRequest.userRequest.bridgeRequest.inputToken = USDC;
    //     feeRequest.userRequest.bridgeRequest.id = 2;
    //     feeRequest.userRequest.bridgeRequest.optionalNativeAmount = 0;
    //     feeRequest.userRequest.middlewareRequest.inputToken = USDC;
    //     feeRequest.userRequest.middlewareRequest.id = 0;
    //     feeRequest.userRequest.middlewareRequest.optionalNativeAmount = 0;

    //     vm.startPrank(sender1);
    //     IERC20(USDC).approve(address(feeRouter),1000e6);
    //     // vm.expectRevert(abi.encodePacked("FeeConfig is not registered."));
    //     feeRouter.deductFeeAndCallRegistry(feeRequest);

    //     assertEq(1e6,feeRouter.getEarnedFee(address(USDC), 100));
    //     vm.stopPrank();

    //     deal(feeTaker2, 100e18);
    //     vm.startPrank(feeTaker2);

    //     feeRouter.claimFee(100,address(USDC));

    //     // Assertions
    //     assertEq(0, feeRouter.getEarnedFee(address(USDC), 100));
    //     assertEq(3*1e5, IERC20(USDC).balanceOf(feeTaker1));
    //     assertEq(7*1e5, IERC20(USDC).balanceOf(feeTaker2));

    //     assertEq(1e6, (IERC20(USDC).balanceOf(feeTaker1) + IERC20(USDC).balanceOf(feeTaker2)));
    // }

    // function testClaimFeeDAI() public {
    //     deal(sender1, 100e18);
    //     deal(address(DAI), sender1, 1000e18);
    //     assertEq(sender1.balance, 100e18);
    //     assertEq(IERC20(DAI).balanceOf(sender1), 1000e18);

    //     vm.startPrank(owner);
    //     // Create Config
    //     FeeRouter.FeeConfig memory feeConfig;

    //     // Create FeeSplit - 1
    //     FeeRouter.FeeSplits memory feeSplit1;
    //     feeSplit1.owner = feeTaker1;
    //     feeSplit1.partOfTotalFeesInBps = part3;

    //     // Create FeeSplit - 2
    //     FeeRouter.FeeSplits memory feeSplit2;
    //     feeSplit2.owner = feeTaker2;
    //     feeSplit2.partOfTotalFeesInBps = part7;

    //     // Set Fee Config
    //     feeConfig.feeSplits[0] = feeSplit1;
    //     feeConfig.feeSplits[1] = feeSplit2;
    //     feeConfig.totalFeeInBps = totalFees10;

    //     feeRouter.registerFeeConfig(100, feeConfig);
    //     vm.stopPrank();

    //     FeeRouter.FeeRequest memory feeRequest;
    //     feeRequest.integratorId = 100;
    //     feeRequest.userRequest.receiverAddress = sender1;
    //     feeRequest.userRequest.toChainId = 137;
    //     feeRequest.userRequest.amount = 1000e18;
    //     feeRequest.userRequest.bridgeRequest.inputToken = DAI;
    //     feeRequest.userRequest.bridgeRequest.id = 2;
    //     feeRequest.userRequest.bridgeRequest.optionalNativeAmount = 0;
    //     feeRequest.userRequest.middlewareRequest.inputToken = DAI;
    //     feeRequest.userRequest.middlewareRequest.id = 0;
    //     feeRequest.userRequest.middlewareRequest.optionalNativeAmount = 0;

    //     vm.startPrank(sender1);
    //     IERC20(DAI).approve(address(feeRouter),1000e18);
    //     // vm.expectRevert(abi.encodePacked("FeeConfig is not registered."));
    //     feeRouter.deductFeeAndCallRegistry(feeRequest);

    //     assertEq(1e18,feeRouter.getEarnedFee(address(DAI), 100));
    //     vm.stopPrank();

    //     deal(feeTaker2, 100e18);
    //     vm.startPrank(feeTaker2);

    //     feeRouter.claimFee(100, address(DAI));

    //     // Assertions
    //     assertEq(0, feeRouter.getEarnedFee(address(DAI), 100));
    //     assertEq(3*1e17, IERC20(DAI).balanceOf(feeTaker1));
    //     assertEq(7*1e17, IERC20(DAI).balanceOf(feeTaker2));

    //     assertEq(1e18, (IERC20(DAI).balanceOf(feeTaker1) + IERC20(DAI).balanceOf(feeTaker2)));
    // }
}
