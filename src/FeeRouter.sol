pragma solidity ^0.8.4;

import "./interfaces/ISocketRegistry.sol";
import "./utils/AccessControl.sol";
import "./utils/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

// import "forge-std/console.sol";

contract FeeRouter is Ownable {
    using SafeERC20 for IERC20;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    ISocketRegistry public immutable socket;

    uint256 immutable PRECISION = 10000;

    constructor(address _socketRegistry, address owner_) Ownable(owner_) {
        socket = ISocketRegistry(_socketRegistry);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Events
    event RegisterFee(uint256 integratorId, FeeConfig feeConfig);
    event UpdateFee(uint256 integratorId, FeeConfig feeConfig);
    event ClaimFee(
        uint256 integratorId,
        address tokenAddress,
        uint256 amount,
        address owner
    );
    event BridgeSocket(
        uint256 amount,
        address inputTokenAddress,
        uint256 integratorId,
        uint256 toChainId,
        uint256 middlewareId,
        uint256 bridgeId,
        uint256 totalFee
    );
    struct FeeRequest {
        uint256 integratorId;
        ISocketRegistry.UserRequest userRequest;
    }

    struct FeeSplits {
        address owner;
        uint256 partOfTotalFeesInBps;
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
            x = x + feeSplits[i].partOfTotalFeesInBps;
        }

        require(
            x == totalFeeInBps,
            "Total Fee in BPS should be equal to the summation of fees when split."
        );

        feeConfigMapping[integratorId] = feeConfig;
        emit RegisterFee(integratorId, feeConfig);
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
            x = x + feeSplits[i].partOfTotalFeesInBps;
        }

        require(
            x == totalFeeInBps,
            "Total Fee in BPS should be equal to the summation of fees when split."
        );

        feeConfigMapping[integratorId] = feeConfig;
        emit UpdateFee(integratorId, feeConfig);
    }

    function claimFee(address tokenAddress, uint256 integratorId) public {
        uint256 earnedFee = earnedTokenFeeMap[integratorId][tokenAddress];
        FeeConfig memory integratorConfig = feeConfigMapping[integratorId];

        FeeSplits[] memory feeSplits = integratorConfig.feeSplits;

        if (tokenAddress == NATIVE_TOKEN_ADDRESS) {
            for (uint256 i = 0; i < feeSplits.length; i++) {
                uint256 amountToBeSent = (earnedFee *
                    feeSplits[i].partOfTotalFeesInBps) / PRECISION;
                payable(feeSplits[i].owner).transfer(amountToBeSent);
                emit ClaimFee(
                    integratorId,
                    tokenAddress,
                    amountToBeSent,
                    feeSplits[i].owner
                );
            }
        } else {
            for (uint256 i = 0; i < feeSplits.length; i++) {
                uint256 amountToBeSent = (earnedFee *
                    feeSplits[i].partOfTotalFeesInBps) / PRECISION;
                IERC20(tokenAddress).safeTransfer(
                    feeSplits[i].owner,
                    amountToBeSent
                );
                emit ClaimFee(
                    integratorId,
                    tokenAddress,
                    amountToBeSent,
                    feeSplits[i].owner
                );
            }
        }
    }

    function deductFeeAndCallRegistry(FeeRequest memory _feeRequest) public {
        address inputTokenAddress;
        address approvalAddress;
        if (_feeRequest.userRequest.middlewareRequest.id == 0) {
            inputTokenAddress = _feeRequest
                .userRequest
                .bridgeRequest
                .inputToken;
            (address routeAddress, bool x, bool y) = socket.routes(
                _feeRequest.userRequest.bridgeRequest.id
            );
            approvalAddress = routeAddress;
        } else {
            inputTokenAddress = _feeRequest
                .userRequest
                .middlewareRequest
                .inputToken;
            (address routeAddress, bool x, bool y) = socket.routes(
                _feeRequest.userRequest.middlewareRequest.id
            );
            approvalAddress = routeAddress;
        }

        FeeConfig memory feeConfig = feeConfigMapping[_feeRequest.integratorId];
        uint256 amountToBeSent = _feeRequest.userRequest.amount -
            ((_feeRequest.userRequest.amount * feeConfig.totalFeeInBps) /
                PRECISION);

        _feeRequest.userRequest.amount = amountToBeSent;
        if (inputTokenAddress == NATIVE_TOKEN_ADDRESS) {
            socket.outboundTransferTo{value: amountToBeSent}(
                _feeRequest.userRequest
            );
        } else {
            IERC20(inputTokenAddress).safeApprove(
                approvalAddress,
                amountToBeSent
            );
            socket.outboundTransferTo(_feeRequest.userRequest);
        }
        emit BridgeSocket(
            _feeRequest.userRequest.amount,
            inputTokenAddress,
            _feeRequest.integratorId,
            _feeRequest.userRequest.toChainId,
            _feeRequest.userRequest.middlewareRequest.id,
            _feeRequest.userRequest.bridgeRequest.id,
            amountToBeSent
        );
    }

    function getEarnedFee(address tokenAddress, uint256 integratorId)
        public
        view
        returns (uint256)
    {
        return earnedTokenFeeMap[integratorId][tokenAddress];
    }

    function getFeeConfig(uint256 integratorId) public view returns (FeeConfig memory feeConfig) {
        return feeConfigMapping[integratorId];
    }
}
