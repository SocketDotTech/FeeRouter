pragma solidity ^0.8.4;

abstract contract ISocketRegistry {
    struct BridgeRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }

    struct MiddlewareRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }

    struct UserRequest {
        address receiverAddress;
        uint256 toChainId;
        uint256 amount;
        MiddlewareRequest middlewareRequest;
        BridgeRequest bridgeRequest;
    }

    struct RouteData {
        address route;
        bool isEnabled;
        bool isMiddleware;
    }

    RouteData[] public routes;

    function outboundTransferTo(UserRequest calldata _userRequest)
        external
        payable
        virtual;
}
