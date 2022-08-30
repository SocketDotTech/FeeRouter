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
        address feeTaker
    );
    event BridgeSocket(
        uint16 integratorId,
        uint256 amount,
        address inputTokenAddress,
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
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
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
    function testOwnerRegisterSuccess() public {
        vm.startPrank(owner);

        uint16 totalFeeInBps = 0;
        FeeRouter.FeeSplits[3] memory feeSplits;
        feeSplits[0].feeTaker = feeTaker1;
        feeRouter.registerFeeConfig(1, totalFeeInBps, feeSplits);
        vm.stopPrank();
    }

    // Should revert if register is not called by the owner
    function testOwnerRegisterRevert() public {
        vm.startPrank(feeTaker1);

        FeeRouter.FeeSplits[3] memory feeSplits;
        feeSplits[0].feeTaker = feeTaker1;
        vm.expectRevert(Ownable.OnlyOwner.selector);
        feeRouter.registerFeeConfig(1, totalFees10, feeSplits);
        vm.stopPrank();
    }

    // Should fail since total fees should be equal to the parts.
    function testRegisterFeeWithUnequalParts() public {
        vm.startPrank(owner);

        // Create FeeSplit - 1
        FeeRouter.FeeSplits memory feeSplit1;
        feeSplit1.feeTaker = owner;
        feeSplit1.partOfTotalFeesInBps = part3;

        // Create FeeSplit - 2
        FeeRouter.FeeSplits memory feeSplit2;
        feeSplit2.feeTaker = owner;
        feeSplit2.partOfTotalFeesInBps = part4;

        FeeRouter.FeeSplits[3] memory feeSplits;
        feeSplits[0] = feeSplit1;
        feeSplits[1] = feeSplit2;

        // console.log(feeSplits.length);

        // Create FeeConfig - Should Revert
        vm.expectRevert(
            FeeRouter.TotalFeeAndPartsMismatch.selector
        );
        feeRouter.registerFeeConfig(3, totalFees10, feeSplits);

        vm.stopPrank();
    }

    // Should Successfully register
    function testRegisterFeeSuccess() public {
        vm.startPrank(owner);
        // Create Config

        // Create FeeSplit - 1
        FeeRouter.FeeSplits memory feeSplit1;
        feeSplit1.feeTaker = feeTaker1;
        feeSplit1.partOfTotalFeesInBps = part3;

        // Create FeeSplit - 2
        FeeRouter.FeeSplits memory feeSplit2;
        feeSplit2.feeTaker = feeTaker2;
        feeSplit2.partOfTotalFeesInBps = part7;

        // Set Fee Config
        FeeRouter.FeeSplits[3] memory feeSplits;
        feeSplits[0] = feeSplit1;
        feeSplits[1] = feeSplit2;

        // Expect Event Emit
        vm.expectEmit(false, false, false, true);
        emit RegisterFee(integratorId, totalFees10, part3, part7, 0, feeTaker1, feeTaker2, address(0));
        feeRouter.registerFeeConfig(integratorId, totalFees10, feeSplits);

        FeeRouter.FeeSplits[3] memory registerFeeSplits = feeRouter.getFeeSplits(integratorId);
        uint16 registeredTotalFees = feeRouter.getTotalFeeInBps(integratorId);

        // Assertions.
        assertEq(totalFees10, registeredTotalFees);
        assertEq(feeTaker1, registerFeeSplits[0].feeTaker);
        assertEq(feeTaker2, registerFeeSplits[1].feeTaker);
        assertEq(address(0), registerFeeSplits[2].feeTaker);
        assertEq(part3, registerFeeSplits[0].partOfTotalFeesInBps);
        assertEq(part7, registerFeeSplits[1].partOfTotalFeesInBps);
        assertEq(0, registerFeeSplits[2].partOfTotalFeesInBps);
        

        vm.stopPrank();
    }

    // Should Revert, since the same integrator Id can only update the fee, cannot register again.
    function testRegisterFeeRevertForSameIntegrator() public {
        vm.startPrank(owner);
        FeeRouter.FeeSplits[3] memory feeSplits;

        feeSplits[0].feeTaker = feeTaker1;
        feeRouter.registerFeeConfig(1, totalFees0, feeSplits);

        vm.expectRevert(
            FeeRouter.IntegratorIdAlreadyRegistered.selector
        );
        feeRouter.registerFeeConfig(1, totalFees0, feeSplits);
        vm.stopPrank();
    }

    // UPDATE FEE TESTS ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------>

    // Only Owner should be able to update the fee config for an integrator Id.
    function testUpdateFeeSuccessOnlyOwner() public {
        vm.startPrank(owner);
        FeeRouter.FeeSplits[3] memory feeSplits;

        feeSplits[0].feeTaker = feeTaker1;
        feeRouter.registerFeeConfig(1, totalFees0, feeSplits);

        feeRouter.updateFeeConfig(1, totalFees0, feeSplits);
        vm.stopPrank();
    }

    // Shpuld revert if update is tried from a different address than owner.
    function testUpdateFeeRevertOnlyOwner() public {
        vm.startPrank(owner);
        FeeRouter.FeeSplits[3] memory feeSplits;

        feeSplits[0].feeTaker = feeTaker1;
        feeRouter.registerFeeConfig(1, totalFees0, feeSplits);
        vm.stopPrank();

        vm.startPrank(feeTaker1);
        vm.expectRevert(Ownable.OnlyOwner.selector);
        feeRouter.updateFeeConfig(1, totalFees0, feeSplits);
        vm.stopPrank();
    }

    // Should not update the fee for an unregistered integrator Id.
    function testUpdateFeeRevertForUnregisteredIntegrator() public {
        vm.startPrank(owner);
        FeeRouter.FeeSplits[3] memory feeSplits;

        feeSplits[0].feeTaker = feeTaker1;
        feeRouter.registerFeeConfig(1, totalFees0, feeSplits);

        vm.expectRevert(FeeRouter.IntegratorIdNotRegistered.selector);
        feeRouter.updateFeeConfig(2, totalFees0, feeSplits);
        vm.stopPrank();
    }

    // Should Successfully Update the fee after registration.
    function testUpdateFeeSuccessWithAssertions() public {
        vm.startPrank(owner);

        // Create FeeSplit - 1
        FeeRouter.FeeSplits memory feeSplit1;
        feeSplit1.feeTaker = feeTaker1;
        feeSplit1.partOfTotalFeesInBps = part3;

        // Create FeeSplit - 2
        FeeRouter.FeeSplits memory feeSplit2;
        feeSplit2.feeTaker = feeTaker2;
        feeSplit2.partOfTotalFeesInBps = part7;

        // Set Fee Config
        FeeRouter.FeeSplits[3] memory feeSplits;
        feeSplits[0] = feeSplit1;
        feeSplits[1] = feeSplit2;

        feeRouter.registerFeeConfig(integratorId, totalFees10, feeSplits);

        feeSplit1.partOfTotalFeesInBps = part30;
        feeSplit2.partOfTotalFeesInBps = part70;
        feeSplits[0] = feeSplit1;
        feeSplits[1] = feeSplit2;

        // Emits Event
        vm.expectEmit(false, false, false, true);
        emit UpdateFee(integratorId, totalFees100, part30, part70, 0, feeTaker1, feeTaker2, address(0));
        feeRouter.updateFeeConfig(integratorId, totalFees100, feeSplits);

        FeeRouter.FeeSplits[3] memory registerFeeSplits = feeRouter.getFeeSplits(integratorId);
        uint16 registeredTotalFees = feeRouter.getTotalFeeInBps(integratorId);

        // Assertions.
        assertEq(totalFees100, registeredTotalFees);
        assertEq(feeTaker1, registerFeeSplits[0].feeTaker);
        assertEq(feeTaker2, registerFeeSplits[1].feeTaker);
        assertEq(part30, registerFeeSplits[0].partOfTotalFeesInBps);
        assertEq(part70, registerFeeSplits[1].partOfTotalFeesInBps);

        vm.stopPrank();
    }

    // Should revert if the parts and the total fee do not match.
    function testUpdateFeeRevertForUnequalParts() public {
        vm.startPrank(owner);

        // Create FeeSplit - 1
        FeeRouter.FeeSplits memory feeSplit1;
        feeSplit1.feeTaker = feeTaker1;
        feeSplit1.partOfTotalFeesInBps = part3;

        // Create FeeSplit - 2
        FeeRouter.FeeSplits memory feeSplit2;
        feeSplit2.feeTaker = feeTaker2;
        feeSplit2.partOfTotalFeesInBps = part7;

        // Set Fee Config
        FeeRouter.FeeSplits[3] memory feeSplits;
        feeSplits[0] = feeSplit1;
        feeSplits[1] = feeSplit2;

        feeRouter.registerFeeConfig(integratorId, totalFees10, feeSplits);

        feeSplit1.partOfTotalFeesInBps = part30;
        feeSplit2.partOfTotalFeesInBps = part70;
        feeSplits[0] = feeSplit1;
        feeSplits[1] = feeSplit2;

        // Emits Event
        vm.expectRevert(FeeRouter.TotalFeeAndPartsMismatch.selector);
        feeRouter.updateFeeConfig(integratorId, totalFees10, feeSplits);
    }

    // FEE DEDUCTION TESTS --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------->
    
    // Unregistered Integrator Ids should be reverted.
    function testDeductionOfFeeWithUnregisteredIntegratorId() public {
        deal(sender1, 100e18);
        deal(address(DAI), sender1, 1000e18);
        assertEq(sender1.balance, 100e18);
        assertEq(IERC20(DAI).balanceOf(sender1), 1000e18);

        FeeRouter.FeeRequest memory feeRequest;
        feeRequest.integratorId = 100;
        feeRequest.userRequest.receiverAddress = sender1;
        feeRequest.userRequest.toChainId = 137;
        feeRequest.userRequest.amount = 1000e18;
        feeRequest.userRequest.bridgeRequest.inputToken = DAI;
        feeRequest.userRequest.bridgeRequest.id = 2;
        feeRequest.userRequest.bridgeRequest.optionalNativeAmount = 0;
        feeRequest.userRequest.middlewareRequest.inputToken = DAI;
        feeRequest.userRequest.middlewareRequest.id = 0;
        feeRequest.userRequest.middlewareRequest.optionalNativeAmount = 0;
        feeRequest.inputAmount = 1000e18;

        vm.startPrank(sender1);
        vm.expectRevert(FeeRouter.IntegratorIdNotRegistered.selector);
        feeRouter.callRegistry(feeRequest);
        vm.stopPrank();
    }

    // Deduction of Fee should be accurate. 
    function testRevertFeeMismatch() public {
        deal(sender1, 100e18);
        deal(address(DAI), sender1, 1000e18);
        assertEq(sender1.balance, 100e18);
        assertEq(IERC20(DAI).balanceOf(sender1), 1000e18);

        vm.startPrank(owner);
        // Create Config
        FeeRouter.FeeSplits memory feeSplit1;
        feeSplit1.feeTaker = feeTaker1;
        feeSplit1.partOfTotalFeesInBps = part3;

        // Create FeeSplit - 2
        FeeRouter.FeeSplits memory feeSplit2;
        feeSplit2.feeTaker = feeTaker2;
        feeSplit2.partOfTotalFeesInBps = part7;

        // Set Fee Config
        FeeRouter.FeeSplits[3] memory feeSplits;
        feeSplits[0] = feeSplit1;
        feeSplits[1] = feeSplit2;

        feeRouter.registerFeeConfig(100, totalFees10, feeSplits);
        vm.stopPrank();

        // Polygon Bridge
        FeeRouter.FeeRequest memory feeRequest;
        feeRequest.integratorId = 100;
        feeRequest.userRequest.receiverAddress = sender1;
        feeRequest.userRequest.toChainId = 137;
        feeRequest.userRequest.amount = 1000e18;
        feeRequest.userRequest.bridgeRequest.inputToken = DAI;
        feeRequest.userRequest.bridgeRequest.id = 2;
        feeRequest.userRequest.bridgeRequest.optionalNativeAmount = 0;
        feeRequest.userRequest.middlewareRequest.inputToken = DAI;
        feeRequest.userRequest.middlewareRequest.id = 0;
        feeRequest.userRequest.middlewareRequest.optionalNativeAmount = 0;
        feeRequest.inputAmount = 1000e18;

        vm.startPrank(sender1);
        IERC20(DAI).approve(address(feeRouter),1000e18);
        vm.expectRevert(FeeRouter.FeeMisMatch.selector);
        feeRouter.callRegistry(feeRequest);

        // assertEq(1e18,feeRouter.getEarnedFee(address(DAI), 100));
        vm.stopPrank();
    }

    // Deduction of Fee should be accurate. 
    function testcallRegistryForDAI() public {
        deal(sender1, 100e18);
        deal(address(DAI), sender1, 1000e18);
        assertEq(sender1.balance, 100e18);
        assertEq(IERC20(DAI).balanceOf(sender1), 1000e18);

        vm.startPrank(owner);
        // Create Config
        FeeRouter.FeeSplits memory feeSplit1;
        feeSplit1.feeTaker = feeTaker1;
        feeSplit1.partOfTotalFeesInBps = part3;

        // Create FeeSplit - 2
        FeeRouter.FeeSplits memory feeSplit2;
        feeSplit2.feeTaker = feeTaker2;
        feeSplit2.partOfTotalFeesInBps = part7;

        // Set Fee Config
        FeeRouter.FeeSplits[3] memory feeSplits;
        feeSplits[0] = feeSplit1;
        feeSplits[1] = feeSplit2;

        feeRouter.registerFeeConfig(100, totalFees10, feeSplits);
        vm.stopPrank();

        // Polygon Bridge
        FeeRouter.FeeRequest memory feeRequest;
        feeRequest.integratorId = 100;
        feeRequest.userRequest.receiverAddress = sender1;
        feeRequest.userRequest.toChainId = 137;
        feeRequest.userRequest.amount = 999e18;
        feeRequest.userRequest.bridgeRequest.inputToken = DAI;
        feeRequest.userRequest.bridgeRequest.id = 2;
        feeRequest.userRequest.bridgeRequest.optionalNativeAmount = 0;
        feeRequest.userRequest.middlewareRequest.inputToken = DAI;
        feeRequest.userRequest.middlewareRequest.id = 0;
        feeRequest.userRequest.middlewareRequest.optionalNativeAmount = 0;
        feeRequest.inputAmount = 1000e18;

        vm.startPrank(sender1);
        IERC20(DAI).approve(address(feeRouter),1000e18);
        feeRouter.callRegistry(feeRequest);

        assertEq(1e18,feeRouter.getEarnedFee(address(DAI), 100));
        vm.stopPrank();
    }

    function testcallRegistryForUSDC() public {
        deal(sender1, 100e18);
        deal(address(USDC), sender1, 1000e6);
        assertEq(sender1.balance, 100e18);
        assertEq(IERC20(USDC).balanceOf(sender1), 1000e6);

        vm.startPrank(owner);
        // Create Config
        FeeRouter.FeeSplits memory feeSplit1;
        feeSplit1.feeTaker = feeTaker1;
        feeSplit1.partOfTotalFeesInBps = part3;

        // Create FeeSplit - 2
        FeeRouter.FeeSplits memory feeSplit2;
        feeSplit2.feeTaker = feeTaker2;
        feeSplit2.partOfTotalFeesInBps = part7;

        // Set Fee Config
        FeeRouter.FeeSplits[3] memory feeSplits;
        feeSplits[0] = feeSplit1;
        feeSplits[1] = feeSplit2;

        feeRouter.registerFeeConfig(100, totalFees10, feeSplits);
        vm.stopPrank();

        // Polygon Bridge
        FeeRouter.FeeRequest memory feeRequest;
        feeRequest.integratorId = 100;
        feeRequest.userRequest.receiverAddress = sender1;
        feeRequest.userRequest.toChainId = 137;
        feeRequest.userRequest.amount = 999e6;
        feeRequest.userRequest.bridgeRequest.inputToken = USDC;
        feeRequest.userRequest.bridgeRequest.id = 2;
        feeRequest.userRequest.bridgeRequest.optionalNativeAmount = 0;
        feeRequest.userRequest.middlewareRequest.inputToken = USDC;
        feeRequest.userRequest.middlewareRequest.id = 0;
        feeRequest.userRequest.middlewareRequest.optionalNativeAmount = 0;
        feeRequest.inputAmount = 1000e6;


        vm.startPrank(sender1);
        IERC20(USDC).approve(address(feeRouter),1000e6);
        feeRouter.callRegistry(feeRequest);

        assertEq(1e6,feeRouter.getEarnedFee(address(USDC), 100));
        vm.stopPrank();
    }

    function testcallRegistryForEther() public {
        deal(sender1, 101e18);
        // deal(address(USDC), sender1, 1000e6);
        assertEq(sender1.balance, 101e18);
        // assertEq(IERC20(USDC).balanceOf(sender1), 1000e6);

        vm.startPrank(owner);
        // Create Config
        FeeRouter.FeeSplits memory feeSplit1;
        feeSplit1.feeTaker = feeTaker1;
        feeSplit1.partOfTotalFeesInBps = part3;

        // Create FeeSplit - 2
        FeeRouter.FeeSplits memory feeSplit2;
        feeSplit2.feeTaker = feeTaker2;
        feeSplit2.partOfTotalFeesInBps = part7;

        // Set Fee Config
        FeeRouter.FeeSplits[3] memory feeSplits;
        feeSplits[0] = feeSplit1;
        feeSplits[1] = feeSplit2;

        feeRouter.registerFeeConfig(100, totalFees10, feeSplits);
        vm.stopPrank();

        // Polygon Bridge
        FeeRouter.FeeRequest memory feeRequest;
        feeRequest.integratorId = 100;
        feeRequest.userRequest.receiverAddress = sender1;
        feeRequest.userRequest.toChainId = 137;
        feeRequest.userRequest.amount = 999e17;
        feeRequest.userRequest.bridgeRequest.inputToken = NATIVE_TOKEN_ADDRESS;
        feeRequest.userRequest.bridgeRequest.id = 2;
        feeRequest.userRequest.bridgeRequest.optionalNativeAmount = 0;
        feeRequest.userRequest.middlewareRequest.inputToken = NATIVE_TOKEN_ADDRESS;
        feeRequest.userRequest.middlewareRequest.id = 0;
        feeRequest.userRequest.middlewareRequest.optionalNativeAmount = 0;
        feeRequest.inputAmount = 100e18;


        vm.startPrank(sender1);
        // IERC20(USDC).approve(address(feeRouter),1000e6);
        feeRouter.callRegistry{value: 100e18}(feeRequest);

        assertEq(1e17,feeRouter.getEarnedFee(NATIVE_TOKEN_ADDRESS, 100));
        vm.stopPrank();
    }

    // CLAIM EARNED FEE TESTS ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------>
    function testClaimFeeUSDC() public {
        deal(sender1, 100e18);
        deal(address(USDC), sender1, 1000e6);
        assertEq(sender1.balance, 100e18);
        assertEq(IERC20(USDC).balanceOf(sender1), 1000e6);

        vm.startPrank(owner);
        // Create Config
        FeeRouter.FeeSplits memory feeSplit1;
        feeSplit1.feeTaker = feeTaker1;
        feeSplit1.partOfTotalFeesInBps = part3;

        // Create FeeSplit - 2
        FeeRouter.FeeSplits memory feeSplit2;
        feeSplit2.feeTaker = feeTaker2;
        feeSplit2.partOfTotalFeesInBps = part7;

        // Set Fee Config
        FeeRouter.FeeSplits[3] memory feeSplits;
        feeSplits[0] = feeSplit1;
        feeSplits[1] = feeSplit2;

        feeRouter.registerFeeConfig(100, totalFees10, feeSplits);
        vm.stopPrank();

        // Polygon Bridge
        FeeRouter.FeeRequest memory feeRequest;
        feeRequest.integratorId = 100;
        feeRequest.userRequest.receiverAddress = sender1;
        feeRequest.userRequest.toChainId = 137;
        feeRequest.userRequest.amount = 999e6;
        feeRequest.userRequest.bridgeRequest.inputToken = USDC;
        feeRequest.userRequest.bridgeRequest.id = 2;
        feeRequest.userRequest.bridgeRequest.optionalNativeAmount = 0;
        feeRequest.userRequest.middlewareRequest.inputToken = USDC;
        feeRequest.userRequest.middlewareRequest.id = 0;
        feeRequest.userRequest.middlewareRequest.optionalNativeAmount = 0;
        feeRequest.inputAmount = 1000e6;


        vm.startPrank(sender1);
        IERC20(USDC).approve(address(feeRouter),1000e6);
        feeRouter.callRegistry(feeRequest);

        assertEq(1e6,feeRouter.getEarnedFee(address(USDC), 100));
        vm.stopPrank();

        deal(feeTaker2, 100e18);
        vm.startPrank(feeTaker2);

        feeRouter.claimFee(100,address(USDC));

        // Assertions
        assertEq(0, feeRouter.getEarnedFee(address(USDC), 100));
        assertEq(3*1e5, IERC20(USDC).balanceOf(feeTaker1));
        assertEq(7*1e5, IERC20(USDC).balanceOf(feeTaker2));

        assertEq(1e6, (IERC20(USDC).balanceOf(feeTaker1) + IERC20(USDC).balanceOf(feeTaker2)));
    }

    function testClaimFeeDAI() public {
        deal(sender1, 100e18);
        deal(address(DAI), sender1, 1000e18);
        assertEq(sender1.balance, 100e18);
        assertEq(IERC20(DAI).balanceOf(sender1), 1000e18);

        vm.startPrank(owner);
        // Create Config
        FeeRouter.FeeSplits memory feeSplit1;
        feeSplit1.feeTaker = feeTaker1;
        feeSplit1.partOfTotalFeesInBps = part3;

        // Create FeeSplit - 2
        FeeRouter.FeeSplits memory feeSplit2;
        feeSplit2.feeTaker = feeTaker2;
        feeSplit2.partOfTotalFeesInBps = part7;

        // Set Fee Config
        FeeRouter.FeeSplits[3] memory feeSplits;
        feeSplits[0] = feeSplit1;
        feeSplits[1] = feeSplit2;

        feeRouter.registerFeeConfig(100, totalFees10, feeSplits);
        vm.stopPrank();

        // Polygon Bridge
        FeeRouter.FeeRequest memory feeRequest;
        feeRequest.integratorId = 100;
        feeRequest.userRequest.receiverAddress = sender1;
        feeRequest.userRequest.toChainId = 137;
        feeRequest.userRequest.amount = 999e18;
        feeRequest.userRequest.bridgeRequest.inputToken = DAI;
        feeRequest.userRequest.bridgeRequest.id = 2;
        feeRequest.userRequest.bridgeRequest.optionalNativeAmount = 0;
        feeRequest.userRequest.middlewareRequest.inputToken = DAI;
        feeRequest.userRequest.middlewareRequest.id = 0;
        feeRequest.userRequest.middlewareRequest.optionalNativeAmount = 0;
        feeRequest.inputAmount = 1000e18;

        vm.startPrank(sender1);
        IERC20(DAI).approve(address(feeRouter),1000e18);
        feeRouter.callRegistry(feeRequest);

        assertEq(1e18,feeRouter.getEarnedFee(address(DAI), 100));
        vm.stopPrank();

        deal(feeTaker2, 100e18);
        vm.startPrank(feeTaker2);

        feeRouter.claimFee(100, address(DAI));

        // Assertions
        assertEq(0, feeRouter.getEarnedFee(address(DAI), 100));
        assertEq(3*1e17, IERC20(DAI).balanceOf(feeTaker1));
        assertEq(7*1e17, IERC20(DAI).balanceOf(feeTaker2));

        assertEq(1e18, (IERC20(DAI).balanceOf(feeTaker1) + IERC20(DAI).balanceOf(feeTaker2)));
    }

    function testClaimFeeEther() public {
        deal(sender1, 101e18);
        assertEq(sender1.balance, 101e18);

        console.log(feeTaker1.balance);
        console.log(feeTaker2.balance);

        vm.startPrank(owner);
        // Create Config
        FeeRouter.FeeSplits memory feeSplit1;
        feeSplit1.feeTaker = feeTaker1;
        feeSplit1.partOfTotalFeesInBps = part3;

        // Create FeeSplit - 2
        FeeRouter.FeeSplits memory feeSplit2;
        feeSplit2.feeTaker = feeTaker2;
        feeSplit2.partOfTotalFeesInBps = part7;

        // Set Fee Config
        FeeRouter.FeeSplits[3] memory feeSplits;
        feeSplits[0] = feeSplit1;
        feeSplits[1] = feeSplit2;

        feeRouter.registerFeeConfig(100, totalFees10, feeSplits);
        vm.stopPrank();

        // Polygon Bridge
        FeeRouter.FeeRequest memory feeRequest;
        feeRequest.integratorId = 100;
        feeRequest.userRequest.receiverAddress = sender1;
        feeRequest.userRequest.toChainId = 137;
        feeRequest.userRequest.amount = 999e17;
        feeRequest.userRequest.bridgeRequest.inputToken = NATIVE_TOKEN_ADDRESS;
        feeRequest.userRequest.bridgeRequest.id = 2;
        feeRequest.userRequest.bridgeRequest.optionalNativeAmount = 0;
        feeRequest.userRequest.middlewareRequest.inputToken = NATIVE_TOKEN_ADDRESS;
        feeRequest.userRequest.middlewareRequest.id = 0;
        feeRequest.userRequest.middlewareRequest.optionalNativeAmount = 0;
        feeRequest.inputAmount = 100e18;


        vm.startPrank(sender1);
        feeRouter.callRegistry{value: 100e18}(feeRequest);

        assertEq(1e17,feeRouter.getEarnedFee(NATIVE_TOKEN_ADDRESS, 100));

        feeRouter.claimFee(100, address(NATIVE_TOKEN_ADDRESS));

        // Assertions
        assertEq(0, feeRouter.getEarnedFee(NATIVE_TOKEN_ADDRESS, 100));
        assertEq(3*1e16, feeTaker1.balance);
        assertEq(7*1e16, feeTaker2.balance);

        assertEq(1e17, feeTaker1.balance + feeTaker2.balance);
    }
}
