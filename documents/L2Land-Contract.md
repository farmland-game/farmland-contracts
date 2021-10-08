## LAND Smart Contract

![LAND](https://farmland-game.github.io/land.png)

The L2LAND token is a standard ERC-777 implementation and was deployed on Arbitrum mainnet with zero supply. It contains standard Arbitrum functionality to bridge Land from the Ethereum Mainnet.

Here's the Arbitrum One [Whitelist](https://bridge.arbitrum.io/token-list-42161.json)

Land is configured as follows:

```JSON
"chainId": 42161,
"address": "0x3CD1833Ce959E087D0eF0Cb45ed06BffE60F23Ba",
"name": "Land",
"symbol": "LAND",
"decimals": 18,
"extensions": {
    "l1Address": "0x3258cd8134b6b28e814772dD91D5EcceEa512818",
    "l1GatewayAddress": "0xcEe284F754E854890e311e3280b767F80797180d"
```

Bridging Land to Arbitrum One can be completed following this [tutorial](https://t.co/Ycd1gLMOBo)

Arbitrum One deployed L2LAND Token can be found on [Arbiscan](https://arbiscan.io/address/0x3CD1833Ce959E087D0eF0Cb45ed06BffE60F23Ba#code).

Compilation Parameters: Solidity v0.6.12+commit.27d51765. Optimizations Enabled

Full L2LAND source code can be found here: [contracts/L2Land.sol](https://github.com/farmland-game/farmland-contracts/tree/master/contracts/L2Land.sol)