
export const MultiRequestExecutorABI = [
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "_socketRegistry",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "owner_",
          "type": "address"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "constructor"
    },
    {
      "inputs": [],
      "name": "OnlyNominee",
      "type": "error"
    },
    {
      "inputs": [],
      "name": "OnlyOwner",
      "type": "error"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "components": [
            {
              "internalType": "address",
              "name": "receiverAddress",
              "type": "address"
            },
            {
              "internalType": "uint256",
              "name": "toChainId",
              "type": "uint256"
            },
            {
              "internalType": "uint256",
              "name": "amount",
              "type": "uint256"
            },
            {
              "components": [
                {
                  "internalType": "uint256",
                  "name": "id",
                  "type": "uint256"
                },
                {
                  "internalType": "uint256",
                  "name": "optionalNativeAmount",
                  "type": "uint256"
                },
                {
                  "internalType": "address",
                  "name": "inputToken",
                  "type": "address"
                },
                {
                  "internalType": "bytes",
                  "name": "data",
                  "type": "bytes"
                }
              ],
              "internalType": "struct ISocketRegistry.MiddlewareRequest",
              "name": "middlewareRequest",
              "type": "tuple"
            },
            {
              "components": [
                {
                  "internalType": "uint256",
                  "name": "id",
                  "type": "uint256"
                },
                {
                  "internalType": "uint256",
                  "name": "optionalNativeAmount",
                  "type": "uint256"
                },
                {
                  "internalType": "address",
                  "name": "inputToken",
                  "type": "address"
                },
                {
                  "internalType": "bytes",
                  "name": "data",
                  "type": "bytes"
                }
              ],
              "internalType": "struct ISocketRegistry.BridgeRequest",
              "name": "bridgeRequest",
              "type": "tuple"
            }
          ],
          "indexed": false,
          "internalType": "struct ISocketRegistry.UserRequest[]",
          "name": "userRequests",
          "type": "tuple[]"
        }
      ],
      "name": "MultiRequestExecuted",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "claimer",
          "type": "address"
        }
      ],
      "name": "OwnerClaimed",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "nominee",
          "type": "address"
        }
      ],
      "name": "OwnerNominated",
      "type": "event"
    },
    {
      "inputs": [
        {
          "components": [
            {
              "internalType": "address",
              "name": "receiverAddress",
              "type": "address"
            },
            {
              "internalType": "uint256",
              "name": "toChainId",
              "type": "uint256"
            },
            {
              "internalType": "uint256",
              "name": "amount",
              "type": "uint256"
            },
            {
              "components": [
                {
                  "internalType": "uint256",
                  "name": "id",
                  "type": "uint256"
                },
                {
                  "internalType": "uint256",
                  "name": "optionalNativeAmount",
                  "type": "uint256"
                },
                {
                  "internalType": "address",
                  "name": "inputToken",
                  "type": "address"
                },
                {
                  "internalType": "bytes",
                  "name": "data",
                  "type": "bytes"
                }
              ],
              "internalType": "struct ISocketRegistry.MiddlewareRequest",
              "name": "middlewareRequest",
              "type": "tuple"
            },
            {
              "components": [
                {
                  "internalType": "uint256",
                  "name": "id",
                  "type": "uint256"
                },
                {
                  "internalType": "uint256",
                  "name": "optionalNativeAmount",
                  "type": "uint256"
                },
                {
                  "internalType": "address",
                  "name": "inputToken",
                  "type": "address"
                },
                {
                  "internalType": "bytes",
                  "name": "data",
                  "type": "bytes"
                }
              ],
              "internalType": "struct ISocketRegistry.BridgeRequest",
              "name": "bridgeRequest",
              "type": "tuple"
            }
          ],
          "internalType": "struct ISocketRegistry.UserRequest",
          "name": "_userRequest",
          "type": "tuple"
        }
      ],
      "name": "callRegistry",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "claimOwner",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "components": [
            {
              "components": [
                {
                  "internalType": "address",
                  "name": "receiverAddress",
                  "type": "address"
                },
                {
                  "internalType": "uint256",
                  "name": "toChainId",
                  "type": "uint256"
                },
                {
                  "internalType": "uint256",
                  "name": "amount",
                  "type": "uint256"
                },
                {
                  "components": [
                    {
                      "internalType": "uint256",
                      "name": "id",
                      "type": "uint256"
                    },
                    {
                      "internalType": "uint256",
                      "name": "optionalNativeAmount",
                      "type": "uint256"
                    },
                    {
                      "internalType": "address",
                      "name": "inputToken",
                      "type": "address"
                    },
                    {
                      "internalType": "bytes",
                      "name": "data",
                      "type": "bytes"
                    }
                  ],
                  "internalType": "struct ISocketRegistry.MiddlewareRequest",
                  "name": "middlewareRequest",
                  "type": "tuple"
                },
                {
                  "components": [
                    {
                      "internalType": "uint256",
                      "name": "id",
                      "type": "uint256"
                    },
                    {
                      "internalType": "uint256",
                      "name": "optionalNativeAmount",
                      "type": "uint256"
                    },
                    {
                      "internalType": "address",
                      "name": "inputToken",
                      "type": "address"
                    },
                    {
                      "internalType": "bytes",
                      "name": "data",
                      "type": "bytes"
                    }
                  ],
                  "internalType": "struct ISocketRegistry.BridgeRequest",
                  "name": "bridgeRequest",
                  "type": "tuple"
                }
              ],
              "internalType": "struct ISocketRegistry.UserRequest[]",
              "name": "userRequests",
              "type": "tuple[]"
            }
          ],
          "internalType": "struct MultiRequestExecutor.MultiRequest",
          "name": "multiRequest",
          "type": "tuple"
        }
      ],
      "name": "execute",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "nominee_",
          "type": "address"
        }
      ],
      "name": "nominateOwner",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "nominee",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "owner",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "socket",
      "outputs": [
        {
          "internalType": "contract ISocketRegistry",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "stateMutability": "payable",
      "type": "receive"
    }
  ]