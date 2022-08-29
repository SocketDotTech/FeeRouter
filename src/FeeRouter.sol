pragma solidity ^0.8.4;

import "./interfaces/ISocketRegistry.sol";
import "./utils/Ownable.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

// import "forge-std/console.sol";

contract FeeRouter is Ownable {
    using SafeERC20 for IERC20;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    ISocketRegistry public immutable socket;

    uint16 immutable PRECISION = 10000;

    constructor(address _socketRegistry, address owner_) Ownable(owner_) {
        socket = ISocketRegistry(_socketRegistry);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Events
    event RegisterFee(uint16 integratorId, FeeConfig feeConfig);
    event UpdateFee(uint16 integratorId, FeeConfig feeConfig);
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
    struct FeeRequest {
        uint16 integratorId;
        ISocketRegistry.UserRequest userRequest;
    }

    struct FeeSplits {
        address owner;
        uint16 partOfTotalFeesInBps;
    }

    struct FeeConfig {
        uint16 totalFeeInBps;
        FeeSplits[3] feeSplits;
    }

    mapping(uint16 => uint8) validIntegrators;
    mapping(uint16 => FeeConfig) public feeConfigMapping;
    mapping(uint16 => mapping(address => uint256)) earnedTokenFeeMap;

    function registerFeeConfig(
        uint16 integratorId,
        FeeConfig calldata feeConfig
    ) public onlyOwner {
        // Not checking for total fee in bps to be 0 as the total fee can be set to 0.
        require(
            validIntegrators[integratorId] == 0,
            "Integrator Id is already registered"
        );

        require(
            feeConfig.feeSplits[0].owner != address(0),
            "ZERO_ADDRESS not owner"
        );
        uint16 x = feeConfig.feeSplits[0].partOfTotalFeesInBps +
            feeConfig.feeSplits[1].partOfTotalFeesInBps +
            feeConfig.feeSplits[2].partOfTotalFeesInBps;

        require(
            x == feeConfig.totalFeeInBps,
            "Total Fee in BPS should be equal to the summation of fees when split."
        );

        feeConfigMapping[integratorId] = feeConfig;
        validIntegrators[integratorId] = 1;
        emit RegisterFee(integratorId, feeConfig);
    }

    function updateFeeConfig(uint16 integratorId, FeeConfig calldata feeConfig)
        public
        onlyOwner
    {
        require(
            validIntegrators[integratorId] == 1,
            "Integrator Id is not registered"
        );
        require(
            feeConfig.feeSplits[0].owner != address(0),
            "ZERO_ADDRESS not owner"
        );

        uint16 x = feeConfig.feeSplits[0].partOfTotalFeesInBps +
            feeConfig.feeSplits[1].partOfTotalFeesInBps +
            feeConfig.feeSplits[2].partOfTotalFeesInBps;

        require(
            x == feeConfig.totalFeeInBps,
            "Total Fee in BPS should be equal to the summation of fees when split."
        );

        feeConfigMapping[integratorId] = feeConfig;
        emit UpdateFee(integratorId, feeConfig);
    }

    function claimFee(uint16 integratorId, address tokenAddress) public {
        uint256 earnedFee = earnedTokenFeeMap[integratorId][tokenAddress];
        FeeConfig memory integratorConfig = feeConfigMapping[integratorId];
        earnedTokenFeeMap[integratorId][tokenAddress] = 0;

        if (earnedFee == 0) return;
        if (tokenAddress == NATIVE_TOKEN_ADDRESS) {
            for (uint8 i = 0; i < 3; i++) {
                if (integratorConfig.feeSplits[i].owner != address(0)) {
                    uint256 amountToBeSent = (earnedFee *
                        integratorConfig.feeSplits[i].partOfTotalFeesInBps) /
                        integratorConfig.totalFeeInBps;
                    payable(integratorConfig.feeSplits[i].owner).transfer(amountToBeSent);
                    emit ClaimFee(
                        integratorId,
                        tokenAddress,
                        amountToBeSent,
                        integratorConfig.feeSplits[i].owner
                    );
                }
            }
        } else {
            for (uint8 i = 0; i < 3; i++) {
                if (integratorConfig.feeSplits[i].owner != address(0)) {
                    uint256 amountToBeSent = (earnedFee *
                        integratorConfig.feeSplits[i].partOfTotalFeesInBps) /
                        integratorConfig.totalFeeInBps;
                    IERC20(tokenAddress).safeTransfer(
                        integratorConfig.feeSplits[i].owner,
                        amountToBeSent
                    );
                    emit ClaimFee(
                        integratorId,
                        tokenAddress,
                        amountToBeSent,
                        integratorConfig.feeSplits[i].owner
                    );
                }
            }
        }
    }

    function deductFeeAndCallRegistry(FeeRequest memory _feeRequest) public {
        address inputTokenAddress;
        address approvalAddress;
        require(
            validIntegrators[_feeRequest.integratorId] == 1,
            "FeeConfig is not registered."
        );
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
        if (inputTokenAddress != NATIVE_TOKEN_ADDRESS) {
            IERC20(inputTokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _feeRequest.userRequest.amount
            );
        }

        FeeConfig memory feeConfig = feeConfigMapping[_feeRequest.integratorId];
        uint256 amountToBeSent = _feeRequest.userRequest.amount -
            ((_feeRequest.userRequest.amount * feeConfig.totalFeeInBps) /
                PRECISION);

        earnedTokenFeeMap[_feeRequest.integratorId][inputTokenAddress] =
            earnedTokenFeeMap[_feeRequest.integratorId][inputTokenAddress] +
            _feeRequest.userRequest.amount -
            amountToBeSent;
        emit BridgeSocket(
            _feeRequest.userRequest.amount,
            inputTokenAddress,
            _feeRequest.integratorId,
            _feeRequest.userRequest.toChainId,
            _feeRequest.userRequest.middlewareRequest.id,
            _feeRequest.userRequest.bridgeRequest.id,
            _feeRequest.userRequest.amount - amountToBeSent
        );
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
    }

    function getEarnedFee(address tokenAddress, uint16 integratorId)
        public
        view
        returns (uint256)
    {
        return earnedTokenFeeMap[integratorId][tokenAddress];
    }

    function getValidIntegrator(uint16 integratorId)
        public
        view
        returns (uint8)
    {
        return validIntegrators[integratorId];
    }

    function getFeeConfig(uint16 integratorId)
        public
        view
        returns (FeeConfig memory feeConfig)
    {
        return feeConfigMapping[integratorId];
    }

    // Rescue Function For ERC20
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }

    // Rescue Function For Native Tokens
    function rescueNative(address payable userAddress, uint256 amount)
        external
        onlyOwner
    {
        userAddress.transfer(amount);
    }
}
