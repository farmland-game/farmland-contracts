# Farmland Smart Contracts

## Ethereum ERC-777 - The backbone of our tokens

Our smart Contracts are ERC-777, ERC-20 Compatble. For Techincal Details on ERC-777 Standard: [https://eips.ethereum.org/EIPS/eip-777](https://eips.ethereum.org/EIPS/eip-777)

We won't be going through all of the fantastic ERC-777 features nor the ERC-20 features on this page and instead focus purely on our smart contract implementation.

LAND and CORN tokens were written in Solidity. Be sure to check out their tutorial before jumping into code: [https://solidity.readthedocs.io/en/v0.6.9/introduction-to-smart-contracts.html](https://solidity.readthedocs.io/en/v0.6.9/introduction-to-smart-contracts.html)

## OpenZeppelin - The secure implementation layer

Our Smart Contracts utilize secure, audit and trusted [OpenZeppelin ERC-777 Smart Contract](https://docs.openzeppelin.com/contracts/2.x/api/token/erc777)

OpenZeppelin code is at the heart of our tokens and we follow their security practices and implementation very carefully.

# LAND Token

![LAND](https://farmland-game.github.io/land.png)

For the base LAND token we've kept it as simple and basic as possible. This token is a standard ERC-777 implementation and was deployed on Ethereum mainnet with fixed supply of 57,706,752 LAND. To bootstrap the ecosystem we will distribute the LAND tokens as follows:

## Continental Breakdown

| Continent | Land |
| ----------- | ----------- |
| Africa | 11,662,080|
| Antarctica | 5,376,000|
| Asia | 17,118,336|
| Europe | 3,909,120|
| North America |  9,488,256|
| South America |  6,850,560|
| Australia | 3,302,400|
| Overall | 57,706,752|

We will release LAND in several tranches, by continent. The founding team will be allocated 5% of each continent as it's released & a further 5% will be allocated for expenses as they arise. The first continent to be released will be Australia which accounts for just over 5% of the total supply of LAND.

All extensions on the base tokens are done through the ERC-777 "Operators". This feature allows other ethereum addresses to operate on behalf of your account. Instead of another address, we've used this functionality to grant the CORN smart contract the operator role.

This means that we can write additional smart contracts to extend base functionality of LAND token. The first cross-smart contract functionality written in this manner is CORN, our first, mintable crop token.

Mainnet Deployed LAND Token can be found on [Etherscan]( https://etherscan.io/address/0x3258cd8134b6b28e814772dD91D5EcceEa512818/code).

Compilation Parameters: Solidity v0.6.9+commit.3e3065ac. No Optimizations

Full LAND Token source code can be found here: [contracts/Land.sol](https://github.com/farmland-game/farmland-contracts/tree/master/contracts/Land.sol)