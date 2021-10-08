// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "./interfaces/IArbToken.sol";

contract L2Land is ERC777, IArbToken {

    address public l2Gateway;
    address public override l1Address;

    modifier onlyGateway {
        require(msg.sender == l2Gateway, "ONLY_GATEWAY");
        _;
    }
    constructor(
        address _l2Gateway,
        address _l1Counterpart
    ) public ERC777("Land", "LAND", new address[](0)) {
        require(_l2Gateway != address(0), "INVALID_GATEWAY");
        require(l2Gateway == address(0), "ALREADY_INIT");
        l2Gateway = _l2Gateway;
        l1Address = _l1Counterpart;
    }

    /**
     * @notice Mint tokens on L2. Callable path is L1Gateway depositToken (which handles L1 escrow), which triggers L2Gateway, which calls this
     * @param account recipient of tokens
     * @param amount amount of tokens minted
     */
    function bridgeMint(address account, uint256 amount) external virtual override onlyGateway {
        bytes calldata data;
        _mint(account, amount, data, '');
    }

    /**
     * @notice Burn tokens on L2.
     * @dev only the token bridge can call this
     * @param account owner of tokens
     * @param amount amount of tokens burnt
     */
    function bridgeBurn(address account, uint256 amount) external virtual override onlyGateway {
        bytes calldata data;
        _burn(account, amount, data, '');
    }
}
