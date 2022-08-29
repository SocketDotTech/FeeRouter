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
    struct FeeRequest {
        uint16 integratorId;
        ISocketRegistry.UserRequest userRequest;
        uint256 inputAmount;
    }

    struct FeeSplits {
        address owner;
        uint16 partOfTotalFeesInBps;
    }

    mapping(uint16 => bool) validIntegrators;
    mapping(uint16 => uint16) public totalFeeMapping;
    mapping(uint16 => FeeSplits[3]) public feeSplitMapping;
    mapping(uint16 => mapping(address => uint256)) earnedTokenFeeMap;

    // CORE FUNCTIONS ------------------------------------------------------------------------------------------------------>
    function registerFeeConfig(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) public onlyOwner {
        // Not checking for total fee in bps to be 0 as the total fee can be set to 0.
        require(
            validIntegrators[integratorId] == false,
            "Integrator Id is already registered"
        );

        uint16 x = feeSplits[0].partOfTotalFeesInBps +
            feeSplits[1].partOfTotalFeesInBps +
            feeSplits[2].partOfTotalFeesInBps;

        require(
            x == totalFeeInBps,
            "Total Fee in BPS should be equal to the summation of fees when split."
        );

        totalFeeMapping[integratorId] = totalFeeInBps;
        feeSplitMapping[integratorId] = feeSplits;
        validIntegrators[integratorId] = true;
        _emitRegisterFee(integratorId, totalFeeInBps, feeSplits);
    }

    function updateFeeConfig(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    ) public onlyOwner {
        require(
            validIntegrators[integratorId] == true,
            "Integrator Id is not registered"
        );

        uint16 x = feeSplits[0].partOfTotalFeesInBps +
            feeSplits[1].partOfTotalFeesInBps +
            feeSplits[2].partOfTotalFeesInBps;

        require(
            x == totalFeeInBps,
            "Total Fee in BPS should be equal to the summation of fees when split."
        );

        totalFeeMapping[integratorId] = totalFeeInBps;
        feeSplitMapping[integratorId] = feeSplits;
        _emitUpdateFee(integratorId, totalFeeInBps, feeSplits);
    }

    function claimFee(uint16 integratorId, address tokenAddress) public {
        uint256 earnedFee = earnedTokenFeeMap[integratorId][tokenAddress];
        FeeSplits[3] memory integratorFeeSplits = feeSplitMapping[integratorId];
        earnedTokenFeeMap[integratorId][tokenAddress] = 0;

        if (earnedFee == 0) return;
        for (uint8 i = 0; i < 3; i++) {
            _calculateAndClaimFee(
                integratorId,
                earnedFee,
                integratorFeeSplits[i].partOfTotalFeesInBps,
                totalFeeMapping[integratorId],
                integratorFeeSplits[i].owner,
                tokenAddress
            );
        }
    }

    function deductFeeAndCallRegistry(FeeRequest calldata _feeRequest) public {
        require(
            validIntegrators[_feeRequest.integratorId] == true,
            "FeeConfig is not registered."
        );

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
        uint256 registryAmount = _getAmountForRegistry(
            _feeRequest.integratorId,
            _feeRequest.inputAmount
        );

        // Update the earned fee for the token and integrator.
        _updateEarnedFee(
            _feeRequest.integratorId,
            inputTokenAddress,
            _feeRequest.inputAmount,
            registryAmount
        );

        // Call Registry
        if (inputTokenAddress == NATIVE_TOKEN_ADDRESS) {
            socket.outboundTransferTo{value: registryAmount}(
                _feeRequest.userRequest
            );
        } else {
            IERC20(inputTokenAddress).safeApprove(
                approvalAddress,
                registryAmount
            );
            socket.outboundTransferTo(_feeRequest.userRequest);
        }

        // Emit Bridge Event
        _emitBridgeSocket(_feeRequest, inputTokenAddress, registryAmount);
    }

    // INTERNAL UTILITY FUNCTION ------------------------------------------------------------------------------------------------------>
    function _calculateAndClaimFee(
        uint16 integratorId,
        uint256 earnedFee,
        uint16 part,
        uint16 total,
        address owner,
        address tokenAddress
    ) internal {
        if (owner != address(0)) {
            uint256 amountToBeSent = (earnedFee * part) / total;
            if (tokenAddress == NATIVE_TOKEN_ADDRESS) {
                payable(owner).transfer(amountToBeSent);
                return;
            }
            IERC20(tokenAddress).safeTransfer(owner, amountToBeSent);
            emit ClaimFee(integratorId, tokenAddress, amountToBeSent, owner);
        }
    }

    function _getApprovalAddress(
        ISocketRegistry.UserRequest calldata userRequest
    ) internal returns (address) {
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
    ) internal returns (address) {
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
        returns (uint256)
    {
        return amount - ((amount * totalFeeMapping[integratorId]) / PRECISION);
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
            _feeRequest.inputAmount,
            tokenAddress,
            _feeRequest.integratorId,
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
            feeSplits[0].owner,
            feeSplits[1].owner,
            feeSplits[2].owner
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
            feeSplits[0].owner,
            feeSplits[1].owner,
            feeSplits[2].owner
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
        return totalFeeMapping[integratorId];
    }

    // function getFeeSplits(uint16 integratorId)
    //     public
    //     view
    //     returns (FeeSplits[])
    // {
    //     return feeSplitMapping[integratorId];
    // }

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
