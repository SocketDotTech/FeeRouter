pragma solidity ^0.8.4;

import "../interfaces/ISocketRegistry.sol";
import "../utils/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultiRequestExecutor is Ownable,ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @notice Address used to identify if it is a native token transfer or not
     */
    address private constant NATIVE_TOKEN_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice variable for our registry contract, registry contract is responsible for redirecting to different bridges
     */
    ISocketRegistry public immutable socket;

    constructor(address _socketRegistry, address owner_) Ownable(owner_) {
        socket = ISocketRegistry(_socketRegistry);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}


    /**
     * @notice Container for Multiple User Request
     * @member userRequests requests that is passed in a loop on to the registry
     */
    struct MultiRequest {
        ISocketRegistry.UserRequest[] userRequests;
    }

        /**
     * @notice Event emitted when call registry is successful
     */
    event MultiRequestExecuted(
        ISocketRegistry.UserRequest[] userRequests
    );

    function execute(MultiRequest calldata multiRequest) public payable nonReentrant {

        ISocketRegistry.UserRequest[] memory userRequests = multiRequest.userRequests;

        for (uint i = 0; i < userRequests.length; ++i) {
            callRegistry(userRequests[i]);
        }

        emit MultiRequestExecuted(multiRequest.userRequests);
    }

    /**
     * @notice Function that calls the registry
     * @dev multiRequest amount should match the aount after deducting the fee from the input amount
     * @param _userRequest _userRequest contains the input amount and the bridge request that is passed to socket registry
     */
    function callRegistry(ISocketRegistry.UserRequest memory _userRequest) public payable {
        address inputTokenAddress = _userRequest.bridgeRequest.inputToken;
        (address routeAddress, , ) = socket.routes(
                _userRequest.bridgeRequest.id
            );

        // Call Registry
        IERC20(inputTokenAddress).safeTransferFrom(msg.sender, address(this), _userRequest.amount);

        IERC20(inputTokenAddress).safeApprove(
            routeAddress,
            _userRequest.amount
        );

        socket.outboundTransferTo{value: msg.value}(
            _userRequest
        );
    }
}
