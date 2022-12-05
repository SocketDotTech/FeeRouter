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

    function setUp() public {
        multiRequestExecutor = new MultiRequestExecutor(
            0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0,
            owner
        );
        socketRegistry =
            ISocketRegistry(0xc30141B657f4216252dc59Af2e7CdB9D8792e1B0);
    }





}