pragma solidity ^0.8.4;

import "./interfaces/ISocketRegistry.sol";
import "./utils/AccessControl.sol";
import "./utils/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

// import "forge-std/console.sol";

contract CommandCenter is Ownable {
    using SafeERC20 for IERC20;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    ISocketRegistry public immutable socket;

    constructor(address _socketRegistry, address owner_) Ownable(owner_) {
        socket = ISocketRegistry(_socketRegistry);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Events
    event RegisterFee();
    event UpdateFee();

    struct FeeRequest {
        uint256 integratorId;
        ISocketRegistry.UserRequest userRequest;
    }

    struct FeeSplits {
        address owner;
        uint256 partOfTotalFees;
    }

    struct FeeConfig {
        uint256 totalFeeInBps;
        FeeSplits[] feeSplits;
    }

    mapping(uint256 => FeeConfig) public feeConfigMapping;
    mapping(uint256 => mapping(address => uint256)) earnedTokenFeeMap;

    function registerFeeConfig(
        uint256 integratorId,
        FeeConfig calldata feeConfig
    ) public onlyOwner {
        // Not checking for total fee in bps to be 0 as the total fee can be set to 0.
        require(
            feeConfigMapping[integratorId].feeSplits[0].owner != address(0),
            "Integrator Id is already registered"
        );
        FeeSplits[] memory feeSplits = feeConfig.feeSplits;
        uint256 totalFeeInBps = feeConfig.totalFeeInBps;
        uint256 x = 0;

        // Can add a check for owner to be not 0, but have ignored it since its a wierd check if we are the ones calling it.
        for (uint256 i = 0; i < feeSplits.length; i++) {
            x = x + feeSplits[i].partOfTotalFees;
        }

        require(
            x == totalFeeInBps,
            "Total Fee in BPS should be equal to the summation of fees when split."
        );

        feeConfigMapping[integratorId] = feeConfig;
    }

    function updateFeeConfig(uint256 integratorId, FeeConfig calldata feeConfig)
        public
        onlyOwner
    {
        require(
            feeConfigMapping[integratorId].feeSplits[0].owner != address(0),
            "Integrator Id is not registered"
        );
        FeeSplits[] memory feeSplits = feeConfig.feeSplits;
        uint256 totalFeeInBps = feeConfig.totalFeeInBps;
        uint256 x = 0;
        for (uint256 i = 0; i < feeSplits.length; i++) {
            x = x + feeSplits[i].partOfTotalFees;
        }

        require(
            x == totalFeeInBps,
            "Total Fee in BPS should be equal to the summation of fees when split."
        );

        feeConfigMapping[integratorId] = feeConfig;
    }

    // function claimFee(address tokenAddress, uint256 integratorId) public {
    //     uint256 earnedFee = earnedTokenFeeMap[_feeRequest.integratorId][tokenAddress];
    //     FeeConfig integratorConfig = feeConfigMapping[integratorId];

    //     FeeSlipts[] feeSplits = integratorConfig.feeSplits;

    //     for (uint256 i = 0; i < feeSplits.length; i++) {
    //         IERC
    //     }
    // }

    // function deductFeeAndCallRegistry(FeeRequest calldata _feeRequest ) {
    // }
}
