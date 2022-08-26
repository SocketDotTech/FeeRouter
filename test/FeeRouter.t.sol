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

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function setup() public {
        feeRouter = new FeeRouter(0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0, 0x0E1B5AB67aF1c99F8c7Ebc71f41f75D4D6211e53);
        socketRegistry = ISocketRegistry(0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0);
    }

    function testOwnerIsSetCorrectly() public {
        console.logAddress(feeRouter.owner());
    }
}