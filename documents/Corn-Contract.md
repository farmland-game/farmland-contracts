# Corn Smart Contract

![CORN](https://farmland-game.github.io/logo.png)

All extensions on the base tokens are done through the ERC-777 "Operators". This feature allows other ethereum addresses to operate on behalf of your account. Instead of another address, we've used this functionality to grant the Corn smart contract the operator role.

This means that we can write additional smart contracts to extend base functionality of LAND token. The first cross-smart contract functionality written in this manner is Corn, our first, mintable Corn token.

The Corn token has been based heavily on the audited [Datamine FLUX smart contract](https://etherscan.io/address/0x469eDA64aEd3A3Ad6f868c44564291aA415cB1d9#code) there are a few changes we've made to suit the Farmland use case, but mainly these are terminology and data aggregation changes.

## Detailed Breakdown

Below we have covered the Corn smart contract in detail skipping the OpenZeppelin ERC-777 base implementation and focusing on the Corn implementation. If you want more information on the OpenZeppelin ERC-777 contracts visit [OpenZeppelin ERC-777 Documentation](https://docs.openzeppelin.com/contracts/3.x/erc777)

The Corn smart contract drives the business logic and is open sourced for review. Let's jump right into the smart contract code. We'll go through code in logical blocks.

The first Corn token deployed to main net is Corn, it can be found on [Etherscan](https://etherscan.io/address/?/code).

Compilation Parameters: Solidity v0.6.9+commit.3e3065ac. Optimizations Enabled

The full Corn source code can be found here: [contracts/Corn.sol](https://github.com/farmland-game/farmland-contracts/tree/master/contracts/Corn.sol)

## Libraries & Interfaces

```Solidity
pragma solidity 0.6.9;
```

The first Corn smart contract deployed to mainnet is CORN with solidity 0.6.9. This number is locked as per security recommendation: [Lock pragmas to specific compiler version](https://consensys.github.io/smart-contract-best-practices/recommendations/#lock-pragmas-to-specific-compiler-version)

```Solidity
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
```

We've referenced the OpenZeppelin secure libraries which is the base ERC-777 implementation that Corn is based on.

```Solidity
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
```

We've already included ERC777.sol, why include the interface? Corn smart contract accepts a \_token as one of the constructor parameters. We'll discuss this in the **constructor** section below.

```Solidity
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
```

The Corn token is an ERC-777 token, that also implements `IERC777Recipient`. `IERC1820Registry` is called to register our own `tokensReceived()` implementation. This allows us to control what kinds of tokens can be sent to the Corn token.

The reason behind both of these decisions is discussed in ERC-1820 ERC777TokensRecipient Implementation section.

```Solidity
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
```

We're using both Math and SafeMath libraries from OpenZeppelin: [https://docs.openzeppelin.com/contracts/2.x/api/math](https://docs.openzeppelin.com/contracts/2.x/api/math)

These are critical security libraries to avoid [Integer Overflow and Underflow](https://consensys.github.io/smart-contract-best-practices/known_attacks/#integer-overflow-and-underflow). All math operations such as `.add()`, `.sub()`, `.mul()`, `.div()` are done through the SafeMath library.

```Solidity
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
```

The final library helps us avoid reentrancy vulnerabilities read more about this type of issue here - [Reentrancy After Istanbul](https://blog.openzeppelin.com/reentrancy-after-istanbul/)

## Farms

LAND tokens can be allocated to a Corn smart contract (by using our two way ERC-777 operator cross-smart contract communication). The locking process is address-specific and is stored in a struct in the following format:

```Solidity
/**
 * @dev Details of a farm at an address
 */
struct Farm {
    uint256 amount;
    uint256 compostedAmount;
    uint256 blockNumber;
    uint256 lastHarvestedBlockNumber;
    address harvesterAddress;
}
```

Please pay attention to explicit `uin256` types to be in line with OpenZeppelin contracts. These structs are stored in a `mapping` as described later.

## Contract Inheritance & Implementations

```Solidity
/**
 * @dev Farmland - Corn Smart Contract
 */
contract Corn is ERC777, IERC777Recipient, ReentrancyGuard {
```

The Corn token is both an `ERC777` contract but also implements `IERC777Recipient`. The reason behind this is discussed in [ERC-1820 ERC777TokensRecipient Implementation](#erc-1820-erc777tokensrecipient-implementation) section. Additionally, we implement the reentrancy protection here.

## Security: SafeMath base

```Solidity
/**
 * @dev Protect against overflows by using safe math operations (these are .add,.sub functions)
 */
using SafeMath for uint256;
```

This is the first line of contract and is an extremely important security feature. We use OpenZeppelin SafeMath for all arithmetic operations to avoid Integer Overflow and Underflow attacks as described here: https://consensys.github.io/smart-contract-best-practices/known_attacks/#integer-overflow-and-underflow

## Security: Our Modifiers

Once again, we like to over-do it a bit on the security side in favor of gas costs. Take a look a look at our `preventSameBlock()` modifier:

```Solidity
/**
* @dev To limit one action per block per address
*/
modifier preventSameBlock(address targetAddress) {
    require(farms[targetAddress].blockNumber != block.number && farms[targetAddress].lastHarvestedBlockNumber != block.number, "You can not allocate/release or harvest in the same block");
    _; // Call the actual code
}
```

To keep things simple and to avoid potential attacks in the future we've limited our all smart contract state changes to one block per address. This means you can't lock/unlock or lock/mint within the same block. Please note the goal of this is to prevent user error so it's still possible to do partial mints within the same block if you send different targetBlock numbers.

Since Ethereum blocks are only around 13.5 seconds on average we thought this slight time delay is not a factor for a normal user and is an added security benefit.

We also have the following modifier that is used throughout all state changes:

```Solidity
/**
* @dev There must be a farm on this LAND to execute this function
*/
modifier requireFarm(address targetAddress, bool requiredState) {
    if (requiredState) {
        require(farms[targetAddress].amount != 0, "You must have allocated land to grow crops on your farm");
    }else{
        require(farms[targetAddress].amount == 0, "You must have released your land");
    }
    _; // Call the actual code
}
```

This modifier allows us to quickly check if an address has LAND allocated for a specific address. Since most state changes require this check this is an extremely useful modifier.

## LAND token address

In the Corn constructor we accept an address for deployed LAND token smart contract address:

```Solidity
/**
 * @dev This will be LAND token smart contract address
 */
IERC777 immutable private _token;
```

Notice the `immutable` keyword, this was introduced in Solidity 0.6.5 and it's a nice security improvement as we know this address won't change somehow later in the contract.

## ERC-1820 ERC777TokensRecipient Implementation

```Solidity
/**
* @dev Decline some incoming transactions (Only allow crop smart contract to send/receive LAND)
*/
function tokensReceived(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes calldata,
    bytes calldata
) external override {
}
```

Our ERC777TokensRecipient implementation is quite unique here. Let's go through this line by line:

```Solidity
require(amount > 0, "You must receive a positive number of tokens");
```

Over-doing it on security even though amount is a unsigned int, we don't want to somehow receive 0 tokens.

```Solidity
require(_msgSender() == address(_token), "You can only build farms on LAND");
```

Ensure that only LAND tokens can be sent to the Corn smart contract. Reverts any other tokens sent to the Corn smart contract, which is most likely done by accident by the user. Since the transaction is reverted the user gets the tokens back and is not charged a gas fee.

```Solidity
// Ensure someone doesn't send in some LAND to this contract by mistake (Only the contract itself can send itself LAND)
require(operator == address(this) , "Only CORN contract can send itself LAND tokens");
```

Since LAND tokens are allocated to the Corn smart contract we wanted to avoid users sending tokens to the contract itself (we want to ensure the user has access to the private keys). This avoids a user
sending LAND from an exchange account (as the user doesn't have private key to the address that was used).

By performing this one simple check we avoid potential loss of funds down the road. Only the Corn contract can send itself tokens, quite a clever usage of ERC-777.

```Solidity
require(to == address(this), "Funds must be coming into a CORN token");
```

Since `ERC777TokensRecipient` can be overriden in ERC-1820 registry we wanted to be 100% certain that the funds are sent to the Corn smart contract. It shouldn't be possible so why not pay a bit of gas to be 100% sure?

```Solidity
require(from != to, "Why would CORN contract send tokens to itself?");
```

Another impossible case is also covered by this check. If Corn token can only operate as source or destination, why would it be both?

## Security: Immutable State Variables

Let's take a look at our immutable state variables. We'll be assuming our usual 1 block = 13.5 seconds for all calculations. This makes our math easy and avoids [Timestamp Dependence attacks](https://consensys.github.io/smart-contract-best-practices/known_attacks/#timestamp-dependence).

If Ethereum block times change significantly in the future then the entire Corn smart contract follows suite and the rewards might be accelerated or slowed down accordingly.

```Solidity
/**
    * @dev How many blocks before the farm maturity boost starts ( Set to 6400 on mainnet - around 1 day )
    */
uint256 immutable private _startMaturityBoost;
```

To start receiving the farm maturity boost (which is capped a user will need to wait this many blocks). This is set to ~24 hours on mainnet and prevents users from locking-in LAND tokens for a short duration. Once again, our goal here is incentivized security where we want you to allocate your tokens for months at a time.

```Solidity
/**
    * @dev How many blocks before the maximum 3x farm maturity boost is reached ( Set to 179200 on mainnet - around 28 days)
    */
uint256 immutable private _endMaturityBoost;
```

Used in farm maturity boost math as the maximum reward point. This is set to ~28 days so if you allocate your LAND tokens for this duration you will receive the maximum farm maturity boost.

```Solidity
/**
* @dev How many blocks until the fail safe limit is lifted and you are able to allocate any amount of LAND to growing crops (Set to 161280 on mainnet for 28 day failsafe period)
*/
uint256 immutable private _failsafeTargetBlock;
```

Corn Smart Contracts features a failsafe mode. We only let you allocate 1000 LAND for 28 days after launch. This is done in accordance with the [Ethereum Fail-Safe Security Best Practice](https://solidity.readthedocs.io/en/v0.6.9/security-considerations.html#include-a-fail-safe-mode).

## Constructor

```Solidity
constructor(address token, uint256 startMaturityBoost, uint256 endMaturityBoost, uint256 failsafeBlockDuration) public ERC777("Corn", "CORN", new address[](0)) {
    require(endMaturityBoost > 0, "endMaturityBoost must be at least 1 block (min 24 hours before time farm maturation starts)"); // to avoid division by 0

    _token = IERC777(token);
    _startMaturityBoost = startMaturityBoost;
    _endMaturityBoost = endMaturityBoost;
    _failsafeTargetBlock = block.number.add(failsafeBlockDuration);

    _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
}
```

Here we construct our Corn token with 0 Corn premine, assign our immutable state variables and register the contract as an `ERC777TokensRecipient`

**Security Note:** Notice that we are using `block.number.add()` here to find out when failsafe ends (approx 28 days), using OpenZeppelin SafeMath.

**Security Note:** Notice that we are using `require(endMaturityBoost > 0)` here to avoid division by 0 for any other smart contracts implementing our contract. This is done to avoid division by 0 and is an extra guard for incorrect Smart Contract deployment.

## Constants

All of our constants are private and are hardcoded at time of smart contract creation. Let's go through constants one by one:

```Solidity
/**
* @dev 0.00000001 Corns grown per block for each LAND allocated to a farm ... 10^18 / 10^8 = 10^10
*/
uint256 private constant _harvestPerBlockDivisor = 10 ** 8;
```

The amount of Corn that can be minted each block is fixed. This is the number that we divide by at the end of the harvest formula. We want 1 LAND (10^18) to mint exactly 0.00000001 Corn (10^10).

```Solidity
/**
* @dev To avoid small burn ratios we multiply the ratios by this number.
*/
uint256 private constant _ratioMultiplier = 10 ** 10;
```

Because there are no decimals, if amount of burned Corn is < amount allocated LAND tokens then we would always get 1x burn multiplier. While this is not going to be a problem in the future (assuming ~8m Corn is minted per year eventually amount of burned Corn > allocated LAND tokens) we wanted to make sure the formula would still be rewarding during early stages of mainnet launch.

```Solidity
/**
 * @dev To get 4 decimals on our multipliers we'll multiply all ratios & divide ratios by this number.
 * @dev This is done because we're using integers without any decimals.
 */
uint256 private constant _percentMultiplier = 10000;
```

Both time and burn multipliers have 4 decimal precision. Because we're using only integers we can't actually get decimals. So we always use this as base "1.0000x" multiplier. This means ratios are always multiplied by this number.

## Public Variables

Here we will cover the logic of the Corn smart contract and the contract's public variables. These variables are also marked as PUBLIC for both ability to read their values in ABIs on our dApp.

```Solidity
/**
* @dev The maximum LAND that can be allocated to a farm during fail safe period.
*/
uint256 public constant failsafeMaxAmount = 1000 * (10 ** 18);
```

This is the maximum amount of LAND tokens that can be allocated to the Corn smart contract during the failsafe mode. LAND are 18 decimals hence `10 ** 18`. And you can only allocate a fixed & limited amount of LAND during failsafe mode.

```Solidity
/**
* @dev This is the farm's maximum 10x compost productivity boost. It's multiplicative with the maturity boost.
*/
uint256 public constant maxCompostBoost = 100000;
```

You can compost a Corn to get up to compost boot. This is that number and is used in the harvesting formula. This number is divided by \_percentMultiplier constant.

```Solidity
/**
* @dev This is the maximum the maturity boost extends beyond the base level of 1x. This is the "2x" in the "1x base + (0x to 2x bonus) with a maximum of 3x"
*/
uint256 public constant maxMaturityBoost = 30000;
```

You can get a farm maturity boost based on the time since your farm was built, this number is divided by \_percentMultiplier constant.

```Solidity
/**
* @dev This is the maximum number of blocks in each growth cycle ( around 42 days) before a harvest is required. After this many blocks Corn will stop growing.
*/
uint256 public constant maxGrowthCycle = 268800;
```

This number defines the maximum number of blocks that the Corn will continue to grow before harvesting.

```Solidity
/**
* @dev How does time maturity boost scale? This is the "2x" in the "1x base + (0x to 2x bonus) = max 3x"
*/
uint256 public constant maturityBoostExtension = 20000;
```

To get to the 3x maturity boost we will be starting from 0 and gradually going up to 2x (`_maturityBoostExtension/_percentMultiplier`). This number would only start to go up after `_startMaturityBoost` # of blocks elapsed.

Next, we'll take a look at our public state variable. Here we must pay extra attention to security as these are the mutable variables.

```Solidity
/**
* @dev PUBLIC: By making farms public we can access elements through the contract view (vs having to create methods)
*/
mapping (address => Farm) public farms;
```

Here we specify state of each farm, this is the most important state variable. The struct itself is explained in detail in Land Allocate Section. By using a struct for all farm states we can greatly simplify our business logic.

```Solidity
/**
* @dev PUBLIC: Store how much LAND is allocated to growing Corns in farms globally
*/
uint256 public globalAllocatedAmount;
```

Whenever some allocated some LAND to a farm they will be added to this number. This number will also be effected when an address releases their LAND and returns it to the owner.

```Solidity
/**
* @dev PUBLIC: Store how much is Corn has been composted globally (only from active farms on LAND addresses)
*/
uint256 public globalCompostedAmount;
```

This number is adjusted by allocate/release just like `globalAllocatedAmount` variable but tracks sum of all composted Corn. Please note that this is the global aggregate of only allocated LAND addresses. This keeps the smart contract future-proof as the number of LAND allocated gradually decreases.

```Solidity
/**
* @dev PUBLIC: Store how many addresses currently have an active farm
*/
uint256 public globalTotalFarms;
```

This number keeps a running tally of the total number of farms.

## Events

All user interaction that modifies state variables produce events.

We're using [Checks-Effects-Interactions Pattern](https://solidity.readthedocs.io/en/v0.6.9/security-considerations.html#use-the-checks-effects-interactions-pattern) for events to ensure any external calls are performed at the end and that events occur before these calls.

Our events are extra light, if data can be figured out by iterating through previous events we do not send them along with the event (This data can always be viewed or constructed). Let's go through these events one by one:

```Solidity
event Allocated(address sender, uint256 blockNumber, address farmerAddress, uint256 amount, uint256 burnedAmountIncrease);
```

Occurs when LAND tokens are allocated to the Corn smart contract.

- **sender**: Which address allocated the LAND tokens?
- **blockNumber**: On what block number were the funds allocated? This number is included in the event as there is math that is bassed off this number and we have to be specific to what number was used in the calculations.
- **amount**: How much LAND was allocated?
- **burnedAmountIncrease**: How much did the global burn amount increase by? This is taking the burned amount of the address that allocated the LAND tokens.

```Solidity
event Released(address sender, uint256 amount, uint256 burnedAmountDecrease);
```

Occurs when LAND tokens are released from the Corn smart contract. Note that we don't emit block number of when this was done as it's not used in calculations.

- **sender**: What address released the LAND tokens?
- **amount**: How much LAND was unlocked?
- **burnedAmountDecrease**: How much did the global burn amount decrease by? This is taking the burned amount of the address that allocated the LAND tokens.

```Solidity
event Composted(address sender, address targetAddress, uint256 amount);
```

Occurs when Corn tokens are composted (burned) to an address with a farm.

- **sender**: What address composted the Corn tokens?
- **targetAddress**: To what address did they burn Corn tokens?
- **amount**: How much Corn was burned to this target address?

```Solidity
event Harvested(address sender, uint256 blockNumber, address sourceAddress, address targetAddress, uint256 targetBlock, uint256 amount);
```

Occurs when Corn tokens are harvested by the delegated farmer.

- **sender**: What is the address of the delegated minter?
- **blockNumber**: What block number did this harvest occur on? This is important for math calculations, need to be precise here.
- **sourceAddress**: From what address are we harvesting from? The harvested amount will be based on this address and the sender must be the delegated farmer for this address.
- **targetAddress**: What address are we harvesting this Corn to? (The recipient of the Corn)
- **targetBlock**: Up to what block are we harvesting? This works for partial harvesting as you can harvest up to a specific block (without harvesting your entire outstanding Corn balance).
- **amount**: How much Corn was harvested?

## Public State Modifying Functions

Let's now go through the core actiona functions. These are the functions that perform all of the interactive state changes such as allocating, releasing, composting and harvesting of Corn.

### allocate()

Let's take a look at how LAND tokens get allocated to the Corn smart contract.

```Solidity
/**
* @dev PUBLIC: Allocate LAND to growing crops on a farm with the specified address as the harvester.
*/
function allocate(address farmerAddress, uint256 amount)
    nonReentrant()
    preventSameBlock(_msgSender())
    requireFarm(_msgSender(), false) // Ensure LAND is not already in a farm
public {
```

- **minterAddress**: Who do we want the target farmer to be?
- **amount**: How many LAND tokens are we allocating?
- **nonReentrant modifier**: OpenZeppelin standard re-entrancy protection.
- **preventSameBlock modifier**: We don't want the message sender address that is performing an action to be able to execute multiple actions within the same block. This avoids potential forms of transaction spamming.
- **requireFarm modifier**: When calling `allocate()` function make sure that current message sender does not have LAND tokens allocated their address (no Farm). To keep things simple there are only two states to addresses: "allocated/not allocated".

Let's go through the function body:

```Solidity
require(amount > 0, "You must provide a positive amount of LAND to build a farm");
```

We don't want users allocating 0 LAND. Since we're using unsigned integers this could also be written as `amount != 0`

```Solidity
// Ensure you can only lock up to 1000 LAND during failsafe period
if (block.number < _failsafeTargetBlock) {
    require(amount <= _failsafeMaxAmount, "You can only allocate a maximum of 1000 LAND during failsafe.");
}
```

During our fail-safe mode (Based on [Ethereum Fail-Safe Security Best Practice](https://solidity.readthedocs.io/en/v0.6.9/security-considerations.html#include-a-fail-safe-mode)) we don't want addresses to allocate more than `_failsafeMaxAmount` which is 1000 LAND (10^18) at launch. This allows us to pull smart contract for 28 days in case of an issue & limit financial exposure for the community.

```Solidity
Farm storage senderFarm = farms[_msgSender()]; // Shortcut accessor
```

You will notice this common pattern for a mapping value reference in many Corn smart contract functions. This allows us to use `senderFarm` instead of `farms[_msgSender()]` while accessing struct. You can read more about it here: https://solidity.readthedocs.io/en/v0.6.9/types.html#structs

```Solidity
senderFarm.amount = amount;
senderFarm.blockNumber = block.number;
senderFarm.lastHarvestedBlockNumber = block.number; // Reset the last harvest height to the new LAND allocation height
senderFarm.harvesterAddress = farmerAddress;
```

Here we are storing farm amount (in LAND), block number of when the sender called the function and saving the delegated harvester address into the struct. Notice we also reset `lastMintBlockNumber` to the same block as the LAND allocate.

```Solidity
globalAllocatedAmount = globalAllocatedAmount.add(amount);
globalCompostedAmount = globalCompostedAmount.add(senderFarm.compostedAmount);
globalTotalFarms += 1;
```

Adjust the global allocated & composted amounts using SafeMath functions. Also, we increment the total number of farms. We then emit our state change event:

```Solidity
emit Allocated(_msgSender(), block.number, farmerAddress, amount, senderFarm.compostedAmount);
```

Emit an event to confirm that LAND was allocated by the message sender on this block with the delegated harvester. You can read more about this event in our Events Section.

```Solidity
// Send [amount] of LAND token from the address that is calling this function to crop smart contract.
IERC777(_token).operatorSend(_msgSender(), address(this), amount, "", ""); // [RE-ENTRANCY WARNING] external call, must be at the end
```

Finally the "Interactions" in [Checks-Effects-Interactions Pattern](https://solidity.readthedocs.io/en/v0.6.9/security-considerations.html#use-the-checks-effects-interactions-pattern). Here we use the new ERC-777 Operators to move LAND tokens (by the Corn smart contract) into the Corn smart contract itself. The amount comes from the function.

**Security Note:** There are no checks on the balance of Corn tokens as this check is performed internally by the `operatorSend()` function.

### release()

You can always choose to release your LAND to get 100% of your LAND tokens back. This is an extremley useful feature and it's done in a completely secure and decentralized manner.

```Solidity
/**
* @dev PUBLIC: Releasing a farm returns LAND to the owners
*/
function release()
    nonReentrant()
    preventSameBlock(_msgSender())
    requireFarm(_msgSender(), true)  // Ensure the address you are releasing has a farm on the LAND
public {
```

- **nonReentrant modifier**: OpenZeppelin standard re-entrancy protection.
- **preventSameBlock modifier**: We don't want the message sender address that is performing an action to be able to execute multiple actions within the same block. This avoids potential forms of transaction spamming.
- **requireLocked modifier**: When calling `release()` function make sure that current message sender has at least some LAND tokens allocated their address (it's a farm). To keep things simple there are only two states to addresses: "allocated/not allocated".

```Solidity
Farm storage senderFarm = farms[_msgSender()]; // Shortcut accessor
```

You will notice this common pattern for a mapping value reference in many Corn smart contract functions. This allows us to use `senderFarm` instead of `farms[_msgSender()]` while accessing struct. You can read more about it here: https://solidity.readthedocs.io/en/v0.6.9/types.html#structs

```Solidity
uint256 amount = senderFarm.amount;
senderFarm.amount = 0;
```

A secure amount -> 0 swap so we stop referring to the `senderFarm.amount` later in the function as we want to avoid any type of re-entrancy.

```Solidity
globalAllocatedAmount = globalAllocatedAmount.sub(amount);
globalCompostedAmount = globalCompostedAmount.sub(senderFarm.compostedAmount);
globalTotalFarms = globalTotalFarms.sub(1);
```

When unlocking LAND tokens the address contributions are subtracted from global amounts. This is done to ensure the global competition remains fair even in the future as less LAND tokens are available on the market.

We will now emit our state change event:

```Solidity
emit Released(_msgSender(), amount, senderFarm.compostedAmount);
```

Emit that LAND was released by the message sender. You can read more about this event in our Events Section

```Solidity
// Send back the LAND [amount] to person calling the method
IERC777(_token).send(_msgSender(), amount, ""); // [RE-ENTRANCY WARNING] external call, must be at the end
```

Finally the "Interactions" in [Checks-Effects-Interactions Pattern](https://solidity.readthedocs.io/en/v0.6.9/security-considerations.html#use-the-checks-effects-interactions-pattern). Here we use the new ERC-777 `send()` function to send the allocated LAND tokens from the Corn token address back to the message sender.

**Security Note:** There are no checks on the balance of LAND tokens as this check is performed internally by the `send()` function.

### compost()

The Corn tokens are designed to be composted (burned) to provide an on-chain reward mechanism. By composting (burning) Corn's you receive higher harvest boost. Let's take a look at how this function works:

```Solidity
/**
* @dev PUBLIC: Composting a Corn fertilizes a farm at specific address
*/
function compost(address targetAddress, uint256 amount)
    nonReentrant()
    requireFarm(targetAddress, true) // Ensure the address you are composting to has a farm on the LAND
public {
```

- **nonReentrant modifier**: OpenZeppelin standard re-entrancy protection.
- **requireLocked modifier**: When calling `release()` function make sure that current message sender has at least some LAND tokens allocated their address (it's a farm). To keep things simple there are only two states to addresses: "allocated/not allocated".

```Solidity
require(amount > 0, "Nothing to compost");
```

We don't want to deal with 0 Corn compost cases so it's the first check to sanitize the user input.

```Solidity
Farm storage targetFarm = farms[targetAddress]; // Shortcut accessor, pay attention to targetAddress here
```

You will notice this common pattern for a mapping value reference in many Corn smart contract functions. This allows us to use `targetFarm` instead of `targetFarm[_msgSender()]` while accessing struct. Notice the targetAddress here, we want to be sure that the address we are burning TO has some LAND tokens allocated. This is an extra quality of life check to ensure addresses don't accidentally burn Corn to the wrong address.

```Solidity
targetFarm.compostedAmount = targetFarm.compostedAmount.add(amount);
```

Credit the address we are composting to with the burned amount (even though the message sender is the one that has the Corn composted).

```Solidity
globalCompostedAmount = globalCompostedAmount.add(amount);
```

Increase the global composted amount by the additional amount using SafeMath.

We will now emit our state change event:

```Solidity
emit Composted(_msgSender(), targetAddress, amount);
```

Emit an event that indicated LAND was composted by the message sender to the target address. You can read more about this event in our Events Section.

```Solidity
// Call the normal ERC-777 burn (this will destroy a Corn token). We don't check address balance for amount because the internal burn does this check for us.
_burn(_msgSender(), amount, "", ""); // [RE-ENTRANCY WARNING] external call, must be at the end
```

Finally the "Interactions" in [Checks-Effects-Interactions Pattern](https://solidity.readthedocs.io/en/v0.6.9/security-considerations.html#use-the-checks-effects-interactions-pattern). Here we use the ERC-777 `_burn()` function to finally burn the message sender's amount of Corn.

**Security Note:** There are no checks on the balance of LAND tokens as this check is performed internally by the `_burn()` function.

### harvest()

This is the final state modifying function that drives the entire minting logic. The area requires maximum security as we're creating new tokens.

```Solidity
/**
* @dev PUBLIC: Harvests Corns from a specific address to a specified address UP TO the target block
*/
function harvest(address sourceAddress, address targetAddress, uint256 targetBlock)
    nonReentrant()
    preventSameBlock(sourceAddress)
    requireFarm(sourceAddress, true) // Ensure the adress that is being harvested has a farm on the LAND
public {
```

- **nonReentrant modifier**: OpenZeppelin standard re-entrancy protection.
- **preventSameBlock modifier**: We don't want the source address that is performing an action to be able to execute multiple actions within the same block. This avoids potential forms of transaction spamming.
- **requireLocked modifier**: When calling `harvest()` function make sure that source address has at least some LAND tokens allocated their address (it's a farm). To keep things simple there are only two states to addresses: "allocated/not allocated".

```Solidity
require(targetBlock <= block.number, "You can only harvest up to current block");
```

Since you can target harvest up to a specific block (without harvesting your entire balance) we don't want you to mint Corn with a block number in the future.

```Solidity
Farm storage sourceFarm = farms[sourceAddress]; // Shortcut accessor, pay attention to sourceAddress here
```

You will notice this common pattern for a mapping value reference in many Corn smart contract functions. This allows us to use `sourceFarm` instead of `Farm[sourceAddress]` while accessing struct. Notice the sourceAddress here, since we are harvesting FROM a specific address that is not the message sender (delegated harvesting).

```Solidity
require(sourceFarm.lastHarvestedBlockNumber < targetBlock, "You can only harvest ahead of last harvested block");
```

This is an additional security mechanism to prevent harvesting prior to the last harveted block. That means you can allocate your LAND to a farm in block 1, harvest on block 3 and then you can't harvest prior to block 4 even though the farm was built in block 1.

```Solidity
require(sourceFarm.harvesterAddress == _msgSender(), "You must be the delegated harvester of the sourceAddress");
```

Ensure that the delegated harvester of the source address is the message sender. This means the delegated harvester address can also be the source address itself.

```Solidity
uint256 mintAmount = getHarvestAmount(sourceAddress, targetBlock);
require(mintAmount > 0, "Nothing to harvest");
```

Here we use the same public-facing view-only `getHarvestAmount()` function to get the actual harvestable amount for the source address up to the target block. This function must return a positive balance so you can't harvest 0 Corn.

```Solidity
sourceFarm.lastHarvestedBlockNumber = targetBlock; // Reset the last harvested height
```

It is important for us to reset the last harvested block height to the TARGET BLOCK. So the next time we can continue from the partial harvest block and can't target a block before the new target block harvest.

We will now emit our state change event:

```Solidity
emit Harvested(_msgSender(), block.number, sourceAddress, targetAddress, targetBlock, mintAmount);
```

Emit that Corn was harvested by the message sender on the current block number from source address to the target address. You can read more about this event in our Events Section.

```Solidity
// Call the normal ERC-777 mint (this will harvest Corn tokens to targetAddress)
_mint(targetAddress, mintAmount, "", ""); // [RE-ENTRANCY WARNING] external call, must be at the end
```

Finally the "Interactions" in [Checks-Effects-Interactions Pattern](https://solidity.readthedocs.io/en/v0.6.9/security-considerations.html#use-the-checks-effects-interactions-pattern). Here we use the ERC-777 `_mint()` function to finally mint the outstanding Corn amount to the target address.

**Security Note:** There are no checks on the balance of LAND tokens as this check is performed internally by the ERC-777 `_mint()` function.

## Public View-Only Functions

In this section there are no state changes so these functions are all view-only and don't cost any gas to call. We use these public functions to fetch smart contract data on our dApp. Here you will find all of the mathematics behind our logic.

### getHarvestAmount()

Let's take a look at how we calculate how much Corn to harvest for an address that has a farm. The returned number is the total amount of Corn that would be harvested if the current address performs a harvest:

```Solidity
/**
* @dev PUBLIC: Get the harvested amount of a specific address up to a target block
*/
function getHarvestAmount(address targetAddress, uint256 targetBlock) public view returns(uint256) {
```

- **targetAddress:** To figure out how much is being harvested we require a target address and target block. This target address must have a farm allocated.
- **targetBlock:** We can perform partial harvests by specifying a target block some time after the farm was built in a specific block. The target block can not exceed current block.

```Solidity
// Ensure this address has a farm on the LAND
if (targetFarm.amount == 0) {
    return 0;
}
```

This is similar to `requireFarm()` modifier in terms of logic. However if the address doesn't have a farm it returns 0 instead of reverting.

```Solidity
require(targetBlock <= block.number, "You can only calculate up to current block");
```

We don't want to specify a block in the future.

```Solidity
require(targetFarm.lastHarvestedBlockNumber <= targetBlock, "You can only specify blocks at or ahead of last harvested block");
```

We want to ensure that you can't specify an block BEFORE your last harvest (as this would an overflow revert). Instead there is a more descriptive error message.

### Harvest Amount Logic

Let's look into how the actual harvest amount is calculated inside `getHarvestAmount()` function:

```Solidity
uint256 lastBlockInGrowthCycle = targetFarm.lastHarvestedBlockNumber.add(_maxGrowthCycle); // end of growth cycle last allowed block
uint256 blocksMinted = _maxGrowthCycle;

if (targetBlock < lastBlockInGrowthCycle) {
    blocksMinted = targetBlock.sub(targetFarm.lastHarvestedBlockNumber);
}
```

This is the logic to ensure that Corn doesn't grow continuously. We first determine the last block in the growth cycle using the safe math library & initialise a variable where we calculate the number of blocks from last harvest (or the farm was built) either to the target block or the end of the growth cycle (if this comes first). This variable is then used later in the function.

```Solidity
uint256 amount = targetFarm.amount; // Total of size of the farm [in LAND] for this address
uint256 blocksMintedByAmount = amount.mul(blocksMinted);
```

How much LAND tokens are locked in to a farm? Take the number of blocks that passed since last harvest and multiply them by the amount of LAND allocated tokens.

Next we account for the boosts:

```Solidity
// Adjust by multipliers
uint256 compostMultiplier = getAddressCompostMultiplier(targetAddress);
uint256 maturityMultipler = getAddressMaturityMultiplier(targetAddress);
```

At 1.0000x boosts, these will be returned as 10000. You can read up more on multipliers in Constants Section

```Solidity
uint256 afterMultiplier = blocksMintedByAmount.mul(compostMultiplier).div(_percentMultiplier).mul(maturityMultipler).div(_percentMultiplier);
```

Multiply the `amount * blocksMinted` by boosts. This would return the same amount as `blocksMintedByAmount` if both multipliers are at 1.0000x.

Finally we must take the multiplied number and divide it by how much Harvest per block divisor:

```Solidity
uint256 actualMinted = afterMultiplier.div(_harvestPerBlockDivisor);
return actualMinted;
```

This returns us to our expected `0.00000001 Corn minted per block for each 1 LAND` formula.

To provide an example, let's assume the following scenario:

- 30.00 LAND allocated
- For 150 blocks (less than the growth cycle)
- 2.5000x Corn compost boost multiplier
- 3.0000x Farm maturity boost // - 6.3400x LAND allocate time bonus multiplier

```Solidity
((30 * 10^18) * 150)      // amount.mul(blocksMinted) = blocksMintedByAmount
.mul(25000)               // .mul(compostMultiplier)
.div(10000)               // .div(_percentMultiplier)
.mul(30000)               // .mul(maturityMultipler)
.div(10000)               // .div(_percentMultiplier)
.div(10^8)                // .div(_harvestPerBlockDivisor)

= 337500000000000         //(0.00033750 Corn as 1 Corn = 10^18)
```

### getAddressTimeMultiplier()

Next, we'll review how farm maturity boost is calculated:

```Solidity
/**
* @dev PUBLIC: Find out a farms maturity boost for the current LAND address (Using 1 block = 13.5 sec formula)
*/
function getAddressMaturityMultiplier(address targetAddress) public view returns(uint256) {
    Farm storage targetFarm = farms[targetAddress]; // Shortcut accessor
```

The function accepts a target address that has a farm. Notice we also get the farm details of the address we are targeting. The returned value of this function will be the maturity boost where 1.0000x = 10000.

```Solidity
// Ensure this address has a farm on the LAND
if (targetFarm.amount == 0) {
    return _percentMultiplier;
}
```

This is similar to `requireFarm()` modifier in terms of logic. However if the address doesn't have a farm it returns 10000 instead of reverting.

```Solidity
// You don't get a boost until minimum blocks passed
uint256 targetBlockNumber = targetFarm.blockNumber.add(startMaturityBoost);
if (block.number < targetBlockNumber) {
    return _percentMultiplier;
}
}
```

This is how we handle our "min 24 hour" farm maturity boost period. `_startMaturityBoost` is provided at time of Corn construction so it can be changed easily in unit tests. If the 24 hours has not passed yet return 10000 (1.0000x time multiplier).

Next let's take a look at how the actual boot is calculated:

```Soliditiy
// 24 hours - min before starting to receive maturity boost
// 28 days - max for waiting 28 days (The function returns PERCENT (10000x) the multiplier for 4 decimal accuracy
uint256 blockDiff = block.number.sub(targetBlockNumber).mul(maturityBoostExtension).div(endMaturityBoost).add(_percentMultiplier);

```

- `block.number.sub(targetBlockNumber)` would give us the number of blocks that passed since 24 min allocate period.
- `.mul(_targetBlockMultiplier)` multiply the difference in blocks by 20000.
- `.div(_maxTimeReward)` divide the number by the destination number of blocks (28 days = 179200 blocks)
- `.add(_percentMultiplier)` add 10000 (1.0000x multiplier) to the total

We then finally return the time multiplier:

```Solidity
uint256 timeMultiplier = Math.min(_maxTimeMultiplier, blockDiff); // Min 1x, Max 3x
return timeMultiplier;
```

Using SafeMath helper library ensure we don't exceed 30000 time bonus multiplier. Let's look at an example of the full formula:

- Farm built at block: 1
- Current block: 100001

```Solidity
(100001 - 1)              // block.number.sub(targetBlockNumber)
.mul(20000)               // .mul(_targetBlockMultiplier)
.div(161280)              // .div(_maxTimeReward)
.add(10000)               // .add(_percentMultiplier)

= 22400                   // This is divided by 10000 = 2.2400x multiplier
```

### getAddressCompostMultiplier()

Let's take a look at how Corn composting (burning) boost works:

```Solidity
/**
* @dev PUBLIC: Find out a farms compost productivity boost for a specific address. This will be returned as PERCENT (10000x)
*/
function getAddressCompostMultiplier(address targetAddress) public view returns(uint256) {
```

We can specify any address (even if it doesn't have LAND tokens allocated). If there are no LAND tokens allocated 10000 (1.0000x multiplier) will be returned.

Now let's take a look at how we fetch address & global ratios:

```Solidity
uint256 myRatio = getAddressRatio(targetAddress);
uint256 globalRatio = getGlobalRatio();

// Avoid division by 0 & ensure 1x boost if nothing is locked
if (globalRatio == 0 || myRatio == 0) {
    return _percentMultiplier;
}
```

If either of these ratios return 0 then return the default 10000 (1.0000x multiplier). These functions are detailed in later sections.

Finally we use the ratios in the following formula:

```Solidity
// The final multiplier is return with 10000x multiplication and will need to be divided by 10000 for final number
uint256 compostMultiplier = Math.min(maxCompostBoost, myRatio.mul(_percentMultiplier).div(globalRatio).add(_percentMultiplier)); // Min 1x, Max 10x
return compostMultiplier;
```

Here the SafeMath helper ensures we never exceed `maxCompostBoost` (1000000 = 10.0000x).

We take address ratio, multiply it by 10000 and divide it by global ratio and add 10000. That means to get the maximum compost boost the address must burn 9x the global average (think `Math.min(10, 9 + 1)`)

Finally let's look at this formula in detail with the following example:

- Address ratio: 20000 (2.0000x)
- Global ratio: 16000 (1.6000x)

```Solidity
(20000)                   // myRatio
.mul(10000)               // .mul(_percentMultiplier)
.div(16000)               // .div(globalRatio)
.add(10000)               // .add(_percentMultiplier)

= 22500                   // This is divided by 10000 = 2.2500x multiplier
```

## Address & Global Corn Burn Ratios

There are only three view-only functions left to go through. These are the Address, Global & Average Corn compost ratios.

### getAddressRatio()

Let's see how we get the address ratio:

```Solidity
/**
* @dev PUBLIC: Get LAND/Corn burn ratio for a specific address
*/
function getAddressRatio(address targetAddress) public view returns(uint256) {
    Farm storage targetFarm = farms[targetAddress]; // Shortcut accessor
```

We accept a target address and return a number for the compost (burn) ratio. This number can be 0 if Corn was not composted (burned) on the targetAddress. We'll also have a shortcut accessor to `targetFarm`.

```Solidity
uint256 addressLockedAmount = targetFarm.amount;
uint256 addressBurnedAmount = targetFarm.compostedAmount;

// If you haven't harvested or composted anything then you get the default 1x boost
if (addressLockedAmount == 0) {
    return 0;
}
```

We create two local variables for ease of access and ensure `addressLockedAmount` is not zero to avoid division by zero below.

Finally we get our address ratio:

```Solidity
// Compost/Maturity ratios for both address & network
// Note that we multiply both ratios by the ratio multiplier before dividing. For tiny Corn/LAND burn ratios.
uint256 myRatio = addressBurnedAmount.mul(_ratioMultiplier).div(addressLockedAmount);
return myRatio;
```

The formula is quite simple and `.mul(_ratioMultiplier)` ensures we handle cases where less Corn is composted than total LAND in a farm. See Constants Section for more details.

### getGlobalRatio()

Let's take a look at the next public view-only function:

```Solidity
/**
* @dev PUBLIC: Get LAND/Corn compost ratio for global (entire network)
*/
function getGlobalRatio() public view returns(uint256) {
    // If you haven't harvested or composted anything then you get the default 1x multiplier
    if (globalAllocatedAmount == 0) {
        return 0;
    }
```

There are no arguments, and we ensure `globalAllocatedAmount` is not zero to avoid division by zero. Finally the global ratio is calculated in similar fashion as the `getAddressRatio()` above:

```Solidity
// Compost/Maturity for both address & network
// Note that we multiply both ratios by the ratio multiplier before dividing. For tiny Corn/LAND burn ratios.
uint256 globalRatio = globalCompostedAmount.mul(_ratioMultiplier).div(globalAllocatedAmount);
return globalRatio;
}
```

The formula is quite simple and `.mul(_ratioMultiplier)` ensures we handle cases where less Corn is burned than total LAND allocated tokens. See Constants Section for more details.

### getGlobalAverageRatio()

Let's take a look at the final public view-only function:

```Solidity
/**
* @dev PUBLIC: Get Average LAND/Corn compost ratio for global (entire network)
*/
function getGlobalAverageRatio() public view returns(uint256) {
    // If you haven't harvested or composted anything then you get the default 1x multiplier
    if (globalAllocatedAmount == 0) {
        return 0;
    }
```

There are no arguments, and we ensure `globalAllocatedAmount` is not zero to avoid division by zero. Finally the global ratio is calculated in similar fashion as the `getAddressRatio()` above:

```Solidity
// Compost/Maturity for both address & network
// Note that we multiply both ratios by the ratio multiplier before dividing. For tiny Corn/LAND burn ratios.
uint256 globalAverageRatio = globalCompostedAmount.mul(_ratioMultiplier).div(globalAllocatedAmount).div(globalTotalFarms);
return globalAverageRatio;
}
```

The formula is quite simple and `.mul(_ratioMultiplier)` ensures we handle cases where less Corn is burned than total LAND allocated tokens. See Constants Section for more details.

## Data Aggregation Helper Functions

In the contract you will also find four view-only functions:

```Solidity
    /**
     * @dev PUBLIC: Grab a collection of data associated with an address
     */
    function getAddressDetails(address targetAddress) public view returns(uint256,uint256,uint256,uint256,uint256) {
        uint256 cropBalance = balanceOf(targetAddress);
        uint256 harvestAmount = getHarvestAmount(targetAddress, block.number);
        uint256 addressMaturityMultiplier = getAddressMaturityMultiplier(targetAddress);
        uint256 addressCompostMultiplier = getAddressCompostMultiplier(targetAddress);

        return (
            block.number,
            cropBalance,
            harvestAmount,
            addressMaturityMultiplier,
            addressCompostMultiplier
        );
    }

    /**
     * @dev PUBLIC: Get additional token details
     */
    function getAddressTokenDetails(address targetAddress) public view returns(uint256,bool,uint256,uint256,uint256,uint256) {
        bool isOperator = IERC777(_token).isOperatorFor(address(this), targetAddress);
        uint256 landBalance = IERC777(_token).balanceOf(targetAddress);
        uint256 myRatio = getAddressRatio(targetAddress);
        uint256 globalRatio = getGlobalRatio();
        uint256 globalAverageRatio = getGlobalAverageRatio();

        return (
            block.number,
            isOperator,
            landBalance,
            myRatio,
            globalRatio,
            globalAverageRatio);
    }

    /**
     * @dev PUBLIC: Get some global details
     */
    function getGlobalDetails() public view returns(uint256,uint256,uint256,uint256,uint256) {
        uint256 globalRatio = getGlobalRatio();
        uint256 globalAverageRatio = getGlobalAverageRatio();

        return (
            globalTotalFarms,
            globalRatio,
            globalAverageRatio,
            globalAllocatedAmount,
            globalCompostedAmount
        );
    }

    /**
     * @dev PUBLIC: Get some contracts constants
     */
    function getConstantDetails() public pure returns(uint256,uint256,uint256,uint256) {

        return (
            maxCompostBoost,
            maxMaturityBoost,
            maxGrowthCycle,
            maturityBoostExtension
        );
    }
```

These functions fetch a number of data points and consolidate them as multiple function returns. This is done to reduce number of smart contract network calls and to fetch the data we need in the dApp.

These functions are not used anywhere in the contract and are only there to provide a quick form of data aggregation.

Additionally `ABIEncoderV2` was still in experimental mode so we did not use it and instead simply return multiple values. Due to the limited number of memory variables in Ethereum this data aggregation had to be split into two seprate functions.

## Additional Security Considerations (ConsenSys)

Here we'll go through a quick checklist of Best Security Practices, known attacks and various steps we took to ensure the contract is secure. Be sure to follow along: [Ethereum Smart Contract Security Best Practices
](https://consensys.github.io/smart-contract-best-practices/)

### General Philosophy

Let's go through the main points one-by-one:

#### Prepare for failure

We have a fail-safe where you can only allocate 1000 LAND tokens for 28 days. This will allow us to pull the smart contract and re-deploy a new version. Depending on the serverity of the exploit it is possible the users could simply unlock their tokens from the old contract if it comes to that.

There is also a LAND bug bounty for a secure disclosure of a confirmed exploit during the fail safe period.

Since we've developed the dApp we can always release a new smart contract seamlessly, although any Corn grown would be lost.

#### Rollout carefully

We've been testing testing on Kovan Testnet for several few months with a variety of smart contract parameters. We also go through a number of attack vectors in this whitepaper so a lot of research was done on best practices.

#### Keep contracts simple

We've split up the smart contract into multiple easy-to-understand constants, immutable variables and functions. There were some ideas that were scrapped to keep the contract as simple as possible but powerful enough to provide new features like Delegated Minting, targetted Corn harvesting and partial harvesting.

We've chosen the best security base possible at time of writing for the Corn smart contract: OpenZeppelin. We've used their entire product line including unit testing and Smart Contract libraries.

We also chose to split up all logic and prefer clear variable names instead of reducing lines of code. Overdoing it on require checks, in favor of improved errors instead of relying on SafeMath overflow protection in places. Everything is well documented and we go through the entire smart contract in detail in this whitepaper.

#### Stay up to date

We're using a proven version of Solidity v0.6.9. We've also used the latest OpenZeppelin available smart contracts.

#### Be aware of blockchain properties

All of our maths is based off block numbers as opposed to timestamps to avoid [Timestamp Dependance](https://consensys.github.io/smart-contract-best-practices/recommendations/#timestamp-dependence).

We use [Checks-Effects-Interactions Pattern](https://solidity.readthedocs.io/en/v0.6.9/security-considerations.html#use-the-checks-effects-interactions-pattern) for all state modifications.

#### Fundamental Tradeoffs: Simplicity versus Complexity cases

Through use of clever modifiers and constants we've kept the code base clean. There is a clear sepration of header, state modification and view-only functions.

By only having two states "locked" or "unlocked" all of the logic is greatly simplified. We've also saved a lot of unnecessary checks by limiting actions to one per block per address.

### Secure Development Recommendations

#### External Calls

##### Use caution when making external calls

We follow [Checks-Effects-Interactions Pattern](https://solidity.readthedocs.io/en/v0.6.9/security-considerations.html#use-the-checks-effects-interactions-pattern) pattern for any logic and they're always done at the end of the function.

##### Mark untrusted contracts

All external calls are marked with `[RE-ENTRANCY WARNING] external call, must be at the end` to clearly mark these functions.

##### Avoid state changes after external calls

We follow [Checks-Effects-Interactions Pattern](https://solidity.readthedocs.io/en/v0.6.9/security-considerations.html#use-the-checks-effects-interactions-pattern) pattern so there are never any state changes after an external call.

##### Don't use transfer() or send().

We use the ERC-777 base functions so this security problem does not apply.

##### Handle errors in external calls

Due to ERC-777 nature all external calls revert with error message so they do not need to be handled in our case.

#### Remember that on-chain data is public

We've clearly marked our functions with `@dev PUBLIC FACING:`. The only reason variables are private is because they're immutable or constant so they can be derived from the construction of the smart contract.

#### Beware of negation of the most negative signed integer

We're using only unsigned integers and only `uint256` with all arithmetic operations performed with SafeMath.

#### Use assert(), require(), revert() properly

We validate all user input with heavy use of `require()`. No use of `assert()` but the best place for this would have been during locking & burning (to ensure the global allocate and burn amounts are modified as expected.

#### Use modifiers only for checks

Our modifiers are read-only. Be sure to check our modifiers in [Security: Our Modifiers Section](#security-our-modifiers)

#### Beware rounding with integer division

Before division we always double check for unexpected division by zero. With `Math.min()` we also don't run into unexpected rounding issues.

### Fallback Functions

We do not have a fallback function so these types of attacks do not apply.

### Explicitly mark visibility in functions and state variables

All functions are explicitly marked with visibility

### Lock pragmas to specific compiler version

CORN was deployed with Compiled Solidity `0.6.9` (optimized build). This number is locked in the source code.

### Use events to monitor contract activity

All state modifying functions have events associated with them. See [Events Section](#events) for more details.

### Avoid using tx.origin

We're always using `_msgSender()` (GSN version of msg.sender) to follow OpenZeppelin style of coding. There are no `tx.origin` references in the Corn smart contract. However there are safe `tx.origin` uses in OpenZeppelin ERC-777.

### Timestamp Dependence

To keep the time math formulas basic we've based all of our math around the fact that 1 block = 13.5 seconds. This assumes that this number is variable and can change in the future. The goal of this is to stay away from timestamp drifting and to avoid time-based inaccuracy.

### Note on EIP20 API Approve / TransferFrom multiple withdrawal attack

Both Land and Corn tokens implement the OpenZeppelin ERC20 compatible `function approve(address _spender, uint256 _value) public returns (bool success)`

As noted in Ethereum EIP-20: <https://eips.ethereum.org/EIPS/eip-20>

NOTE: To prevent attack vectors like the one [described here](https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/) and discussed [here](https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), clients SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before setting it to another value for the same spender. **THOUGH The contract itself shouldn’t enforce it, to allow backwards compatibility with contracts deployed before**

To keep ERC-20 compatability we do not enforce it and **clients SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before setting it to another value for the same spender** as it is set in the base OpenZeppelin ERC-20 contract (as stated above).

There is no backward compatible resolution to this problem. If you are interested on reading up more on developments of this general ERC-20 issue be sure to check out [EIP-738](https://github.com/ethereum/EIPs/issues/738)
