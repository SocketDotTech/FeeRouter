// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// Tests
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Script.sol";

// Contracts
import "../src/interfaces/ISocketRegistry.sol";
import "../src/utils/Ownable.sol";
import "../src/FeeRouter.sol";

contract FeeRouterTest is Test {
    FeeRouter public feeRouter;
    ISocketRegistry public socketRegistry;

    struct FeeSplits {
        address owner;
        uint256 partOfTotalFeesInBps;
    }

    struct FeeConfig {
        uint256 totalFeeInBps;
        FeeSplits[] feeSplits;
    }

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant owner = 0x0E1B5AB67aF1c99F8c7Ebc71f41f75D4D6211e53;
    uint256 integratorId = 3;

    function setUp() public {
        feeRouter = new FeeRouter(0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0, owner);
        socketRegistry = ISocketRegistry(0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0);
    }

    function testOwnerIsSetCorrectly() public {
        console.logAddress(feeRouter.owner());
    }

    function testRegisterFee() public {
        vm.prank(owner);

        // Create Config
        FeeRouter.FeeConfig memory feeConfig;
        FeeRouter.FeeSplits[] memory feeSplits;
        feeSplits[0].owner = owner;
        feeSplits[0].partOfTotalFeesInBps = 10;
        feeConfig.totalFeeInBps = 10;
        feeConfig.feeSplits = feeSplits;

        // Create FeeConfig
        feeRouter.registerFeeConfig(3, feeConfig);

        FeeRouter.FeeConfig memory registeredFeeConfig = feeRouter.getFeeConfig(integratorId);
        assertEq(registeredFeeConfig, feeConfig);
    }
}