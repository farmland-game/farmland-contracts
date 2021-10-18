## LAND Smart Contract

![CORN](https://farmland-game.github.io/logo.png)

The L2CORN token is a standard ERC-777 implementation and was deployed on Arbitrum mainnet with 150,000 supply to seed liquidity. It contains standard Arbitrum functionality to bridge Corn from the Ethereum Mainnet.

Here's the Arbitrum One [Whitelist](https://bridge.arbitrum.io/token-list-42161.json)

Corn is configured as follows (pending whitelisting):

```JSON
"chainId": 42161,
"address": "0xFcc0351f3a1ff72409Df66a7589c1F9efBf53386",
"name": "Corn",
"symbol": "CORN",
"decimals": 18,
"extensions": {
    "l1Address": "0x3CD1833Ce959E087D0eF0Cb45ed06BffE60F23Ba",
    "l1GatewayAddress": "0xcEe284F754E854890e311e3280b767F80797180d"
```

Arbitrum One deployed L2CORN Token can be found on [Arbiscan](https://arbiscan.io/token/0xFcc0351f3a1ff72409Df66a7589c1F9efBf53386#code).

Compilation Parameters: Solidity v0.6.12+commit.27d51765. Optimizations Enabled

Full L2CORN source code can be found here & has been fully commented: [contracts/L2Corn.sol](https://github.com/farmland-game/farmland-contracts/tree/master/contracts/L2Corn.sol)