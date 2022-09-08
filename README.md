# Socket Fee Router Contract

This contract lets an integrator take a percent based fee when bridging through Socket. 
Contract has the ability to register a fee, update a fee, claim the fee earned and passes the call to the Registry contract of socket for the final bridging. 
Fee can be split into max 3 entities if needed. 
## Install And Build

- `forge install`
- `forge build`

## Test

- `forge test -vvvvv --fork-url <RPC_URL>`

## MAIN FUNCTIONS ->

In summary:

- #### Register Fee Config:
  ```ts
  function registerFeeConfig(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    )
  ```
  Owner can register the fee config on behalf of the integrator by calling the above function.

- #### Update Fee Config:

  ```ts
  function updateFeeConfig(
        uint16 integratorId,
        uint16 totalFeeInBps,
        FeeSplits[3] calldata feeSplits
    )
  ```
  Owner can update the fee config on behalf of the integrator by calling the above function.


- #### Claim Fee
  ```ts
  function claimFee(uint16 integratorId, address tokenAddress)
  ```
  Anyone can call the above function and the earned fee will be distributed as per the fee config.

- #### Call Registry
  ```ts
  function callRegistry(FeeRequest calldata _feeRequest)
  ```
  This function is responsible for the actual bridging with fee deduction. It checks the fee in the request against the fee config and validates the request. 

## UTILITY FUNCTIONS ->

- #### Calculate And Claim Fee
    ```ts
    function _calculateAndClaimFee(
            uint16 integratorId,
            uint256 earnedFee,
            uint16 part,
            uint16 total,
            address feeTaker,
            address tokenAddress
        )
    ```
    Calculates the amount of fee from the total fee earned for the respective address and sends the fee to the registered entity.

- #### Get Approval and Input Token Address
    ```ts
    function _getApprovalAndInputTokenAddress(
        ISocketRegistry.UserRequest calldata userRequest
    )
    ```
    Returns the input token address and approval address required for bridging and deducting fee.

- #### Get User Funds to Router Contract
    ```ts
    function _getUserFundsToFeeRouter(
        address user,
        uint256 amount,
        address tokenAddress
    )
    ```
    Gets the funds to this contract if its an ERC20 from the user's wallet.

- #### Get the amount thats needed to be approved after deduction of fee.
    ```ts
    function _getAmountForRegistry(uint16 integratorId, uint256 amount)
    ```
    Calculates and returns the amount after deducting the fee from the input amount respective to the integrator fee config.

- #### Update the earned fee respecitve to the integrator and token
    ```ts
    _updateEarnedFee(
        uint16 integratorId,
        address inputTokenAddress,
        uint256 amount,
        uint256 registryAmount
    )
    ```
    Updates the fee earned by an integrator in respect to the token.

## VIEW FUNCTIONS ->
- #### Get Earned Fee
    ```ts
    function getEarnedFee(uint16 integratorId, address tokenAddress)
    ```
    Returns the amout of fee earned by an integrator against the token.

- #### Check if integrator is registered or not
    ```ts
    function getValidIntegrator(uint16 integratorId)
    ```
    Returns a boolean after checking if the integrator is registered or not.

- #### Get Total Fee In Bps for an integrator.
    ```ts
    function getTotalFeeInBps(uint16 integratorId)
    ```

- #### Get the Fee Splits for the integrator
    ```ts
    function getFeeSplits(uint16 integratorId)
    ```
    Returns a FeeSplit Array registered against the integrator Id.

## EVENTS ->
- #### Register Fee
    ```ts
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
    ```
    Event emitted when a fee is registered against an integrator.

- #### Update Fee
    ```ts
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
    ```
    Event emitted when the fee is updated for an integrator.

- #### Claim Fee
    ```ts
    event ClaimFee(
            uint16 integratorId,
            address tokenAddress,
            uint256 amount,
            address feeTaker
        );
    ```
    Event emitted when the Fee is claimed. Claim Fee will be emitted with each individual transfer.

- #### Bridge socket
    ```ts
    event BridgeSocket(
            uint16 integratorId,
            uint256 amount,
            address inputTokenAddress,
            uint256 toChainId,
            uint256 middlewareId,
            uint256 bridgeId,
            uint256 totalFee
        );
    ```
    Event emitted when `callRegistry` is successful.

## STRUCTS ->

- #### FeeRequest: 
    ```ts
    struct FeeRequest {
            uint16 integratorId;
            uint256 inputAmount;
            ISocketRegistry.UserRequest userRequest;
        }
    ```
    This forms the input to be passed to `callRegistry`,

- #### FeeSplits: 
    ```ts
    struct FeeSplits {
        address feeTaker;
        uint16 partOfTotalFeesInBps;
    }
    ```
    This forms one object in the fee split array. 

## MAPS ->

- #### Valid Integrators: 
    ```ts
    mapping(uint16 => bool) validIntegrators;
    ```
    This map will hold all the integrators that have their fee registered.

- #### Total Fee Map: 
    ```ts
    mapping(uint16 => uint16) totalFeeMap;
    ```
    This holds the totalFeeInBps for every registered integrator.

- #### Fee Split Map: 
    ```ts
    mapping(uint16 => FeeSplits[3]) feeSplitMap;
    ```
    This holds the fee split configuration for each integrator registered.

- #### Earned Token Fee Map: 
    ```ts
    mapping(uint16 => mapping(address => uint256)) earnedTokenFeeMap;
    ```
    This is the amount of fee earned in each token against an integrator id.
    