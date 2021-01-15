# Farmland Smart Contracts

## Ethereum ERC-777 - The backbone of our tokens

Our smart Contracts are ERC-777, ERC-20 Compatble. For Techincal Details on ERC-777 Standard: [https://eips.ethereum.org/EIPS/eip-777](https://eips.ethereum.org/EIPS/eip-777)

We won't be going through all of the fantastic ERC-777 features nor the ERC-20 features on this page and instead focus purely on our smart contract implementation.

LAND and CORN tokens were written in Solidity. Be sure to check out their tutorial before jumping into code: [https://solidity.readthedocs.io/en/v0.6.9/introduction-to-smart-contracts.html](https://solidity.readthedocs.io/en/v0.6.9/introduction-to-smart-contracts.html)

## OpenZeppelin - The secure implementation layer

Our Smart Contracts utilize secure, audit and trusted [OpenZeppelin ERC-777 Smart Contract](https://docs.openzeppelin.com/contracts/2.x/api/token/erc777)

OpenZeppelin code is at the heart of our tokens and we follow their security practices and implementation very carefully.

## Smart Contracts

### Land
- [Detailed Land Smart Contract Documentation](https://github.com/farmland-game/farmland-contracts/tree/master/documents/Land-Contract.md)
- [Land Contract](https://github.com/farmland-game/farmland-contracts/tree/master/contracts/Land.sol)

### Corn
- [Detailed Corn Smart Contract Documentation](https://github.com/farmland-game/farmland-contracts/tree/master/documents/Corn-Contract.md)
- [Corn Contract](https://github.com/farmland-game/farmland-contracts/tree/master/contracts/Corn.sol)