pragma solidity ^0.8.4;

import "./interfaces/ISocketRegistry.sol";
import "./utils/Ownable.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

// import "forge-std/console.sol";

contract FeeRouter is Ownable {
    using SafeERC20 for IERC20;
    address private immutable NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    ISocketRegistry public immutable socket;

    error IntegratorIdAlreadyRegistered();
    error TotalFeeAndPartsMismatch();
    error IntegratorIdNotRegistered();
    error FeeMisMatch();

    uint16 immutable PRECISION = 10000;

    constructor(address _socketRegistry, address owner_) Ownable(owner_) {
        socket = ISocketRegistry(_socketRegistry);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Events
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
    struct FeeRequest {
        uint16 integratorId;
        uint256 inputAmount;
        ISocketRegistry.UserRequest userRequest;
    }

    struct FeeSplits {
        address feeTaker;
        uint16 partOfTotalFeesInBps;
    }

    mapping(uint16 => bool) validIntegrators;
    mapping(uint16 => uint16) totalFeeMap;
    mapping(uint16 => FeeSplits[3]) feeSplitMap;
    mapping(uint16 => mapping(address => uint256)) earnedTokenFeeMap;

    // CORE FUNCTIONS ------------------------------------------------------------------------------------------------------>
    function registerFeeConfig(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) external onlyOwner {
        // Not checking for total fee in bps to be 0 as the total fee can be set to 0.
        if (validIntegrators[integratorId] != false)
            revert IntegratorIdAlreadyRegistered();

        uint16 x = feeSplits[0].partOfTotalFeesInBps +
            feeSplits[1].partOfTotalFeesInBps +
            feeSplits[2].partOfTotalFeesInBps;

        if (x != totalFeeInBps) revert TotalFeeAndPartsMismatch();

        totalFeeMap[integratorId] = totalFeeInBps;
        feeSplitMap[integratorId][0] = feeSplits[0];
        feeSplitMap[integratorId][1] = feeSplits[1];
        feeSplitMap[integratorId][2] = feeSplits[2];
        validIntegrators[integratorId] = true;
        _emitRegisterFee(integratorId, totalFeeInBps, feeSplits);
    }

    function updateFeeConfig(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) external onlyOwner {
        if (validIntegrators[integratorId] != true)
            revert IntegratorIdNotRegistered();

        uint16 x = feeSplits[0].partOfTotalFeesInBps +
            feeSplits[1].partOfTotalFeesInBps +
            feeSplits[2].partOfTotalFeesInBps;

        if (x != totalFeeInBps) revert TotalFeeAndPartsMismatch();

        totalFeeMap[integratorId] = totalFeeInBps;
        feeSplitMap[integratorId][0] = feeSplits[0];
        feeSplitMap[integratorId][1] = feeSplits[1];
        feeSplitMap[integratorId][2] = feeSplits[2];
        _emitUpdateFee(integratorId, totalFeeInBps, feeSplits);
    }

    function claimFee(uint16 integratorId, address tokenAddress) external {
        uint256 earnedFee = earnedTokenFeeMap[integratorId][tokenAddress];
        FeeSplits[3] memory integratorFeeSplits = feeSplitMap[integratorId];
        earnedTokenFeeMap[integratorId][tokenAddress] = 0;

        if (earnedFee == 0) return;
        for (uint8 i = 0; i < 3; i++) {
            _calculateAndClaimFee(
                integratorId,
                earnedFee,
                integratorFeeSplits[i].partOfTotalFeesInBps,
                totalFeeMap[integratorId],
                integratorFeeSplits[i].feeTaker,
                tokenAddress
            );
        }
    }

    function callRegistry(FeeRequest calldata _feeRequest)
        external
        payable
    {
        if (validIntegrators[_feeRequest.integratorId] != true)
            revert IntegratorIdNotRegistered();

        // Get approval and token addresses.
        address inputTokenAddress = _getInputTokenAddress(
            _feeRequest.userRequest
        );
        address approvalAddress = _getApprovalAddress(_feeRequest.userRequest);

        // Get amount to the contract if ERC20
        if (inputTokenAddress != NATIVE_TOKEN_ADDRESS) {
            _getUserFundsToFeeRouter(
                msg.sender,
                _feeRequest.inputAmount,
                inputTokenAddress
            );
        }

        // Calculate Amount to Send to Registry.
        uint256 amountToBridge = _getAmountForRegistry(
            _feeRequest.integratorId,
            _feeRequest.inputAmount
        );

        if (_feeRequest.userRequest.amount != amountToBridge)
            revert FeeMisMatch();

        // Update the earned fee for the token and integrator.
        uint256 x = gasleft();
        _updateEarnedFee(
            _feeRequest.integratorId,
            inputTokenAddress,
            _feeRequest.inputAmount,
            amountToBridge
        );
        console.log(x - gasleft());

        // Call Registry
        if (inputTokenAddress == NATIVE_TOKEN_ADDRESS) {
            socket.outboundTransferTo{
                value: msg.value - (_feeRequest.inputAmount - amountToBridge)
            }(_feeRequest.userRequest);
        } else {
            IERC20(inputTokenAddress).safeApprove(
                approvalAddress,
                amountToBridge
            );
            socket.outboundTransferTo{value: msg.value}(
                _feeRequest.userRequest
            );
        }

        // Emit Bridge Event
        _emitBridgeSocket(_feeRequest, inputTokenAddress, amountToBridge);
    }

    // INTERNAL UTILITY FUNCTION ------------------------------------------------------------------------------------------------------>
    function _calculateAndClaimFee(
        uint16 integratorId,
        uint256 earnedFee,
        uint16 part,
        uint16 total,
        address feeTaker,
        address tokenAddress
    ) internal {
        if (feeTaker != address(0)) {
            uint256 amountToBeSent = (earnedFee * part) / total;
            emit ClaimFee(integratorId, tokenAddress, amountToBeSent, feeTaker);
            if (tokenAddress == NATIVE_TOKEN_ADDRESS) {
                payable(feeTaker).transfer(amountToBeSent);
                return;
            }
            IERC20(tokenAddress).safeTransfer(feeTaker, amountToBeSent);
        }
    }

    function _getApprovalAddress(
        ISocketRegistry.UserRequest calldata userRequest
    ) internal view returns (address) {
        if (userRequest.middlewareRequest.id == 0) {
            (address routeAddress, , ) = socket.routes(
                userRequest.bridgeRequest.id
            );
            return routeAddress;
        } else {
            (address routeAddress, , ) = socket.routes(
                userRequest.middlewareRequest.id
            );
            return routeAddress;
        }
    }

    function _getInputTokenAddress(
        ISocketRegistry.UserRequest calldata userRequest
    ) internal pure returns (address) {
        if (userRequest.middlewareRequest.id == 0) {
            return userRequest.bridgeRequest.inputToken;
        } else {
            return userRequest.middlewareRequest.inputToken;
        }
    }

    function _getUserFundsToFeeRouter(
        address user,
        uint256 amount,
        address tokenAddress
    ) internal {
        IERC20(tokenAddress).safeTransferFrom(user, address(this), amount);
    }

    function _getAmountForRegistry(uint16 integratorId, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return amount - ((amount * totalFeeMap[integratorId]) / PRECISION);
    }

    function _updateEarnedFee(
        uint16 integratorId,
        address inputTokenAddress,
        uint256 amount,
        uint256 registryAmount
    ) internal {
        earnedTokenFeeMap[integratorId][inputTokenAddress] =
            earnedTokenFeeMap[integratorId][inputTokenAddress] +
            amount -
            registryAmount;
    }

    function _emitBridgeSocket(
        FeeRequest calldata _feeRequest,
        address tokenAddress,
        uint256 registryAmount
    ) internal {
        emit BridgeSocket(
            _feeRequest.integratorId,
            _feeRequest.inputAmount,
            tokenAddress,
            _feeRequest.userRequest.toChainId,
            _feeRequest.userRequest.middlewareRequest.id,
            _feeRequest.userRequest.bridgeRequest.id,
            _feeRequest.inputAmount - registryAmount
        );
    }

    function _emitUpdateFee(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) internal {
        emit UpdateFee(
            integratorId,
            totalFeeInBps,
            feeSplits[0].partOfTotalFeesInBps,
            feeSplits[1].partOfTotalFeesInBps,
            feeSplits[2].partOfTotalFeesInBps,
            feeSplits[0].feeTaker,
            feeSplits[1].feeTaker,
            feeSplits[2].feeTaker
        );
    }

    function _emitRegisterFee(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) internal {
        emit RegisterFee(
            integratorId,
            totalFeeInBps,
            feeSplits[0].partOfTotalFeesInBps,
            feeSplits[1].partOfTotalFeesInBps,
            feeSplits[2].partOfTotalFeesInBps,
            feeSplits[0].feeTaker,
            feeSplits[1].feeTaker,
            feeSplits[2].feeTaker
        );
    }

    // VIEW FUNCTIONS --------------------------------------------------------------------------------------------------------->
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
        returns (bool)
    {
        return validIntegrators[integratorId];
    }

    function getTotalFeeInBps(uint16 integratorId)
        public
        view
        returns (uint16)
    {
        return totalFeeMap[integratorId];
    }

    function getFeeSplits(uint16 integratorId)
        public
        view
        returns (FeeSplits[3] memory feeSplits)
    {
        return feeSplitMap[integratorId];
    }

    // RESCUE FUNCTIONS ------------------------------------------------------------------------------------------------------>
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }

    function rescueNative(address payable userAddress, uint256 amount)
        external
        onlyOwner
    {
        userAddress.transfer(amount);
    }
}
