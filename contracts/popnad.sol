// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PopNad is
    Initializable,
    ERC20Upgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    struct Player {
        address playerAddress;
        uint256 firstBlockPlayed;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;

    event SusEvent(address indexed player);
    event ScoreUpdateEvent(address indexed player, uint256 balance);

    function initialize() public initializer {
        __ERC20_init("PopNad Testnet Token", "POPNAD");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function getBalances(address[] calldata users) external view returns (uint256[] memory balances) {
        uint256 length = users.length;
        balances = new uint256[](length);

        unchecked { // Saves gas by skipping overflow checks (safe since `i < length`)
            for (uint256 i = 0; i < length; i++) {
                balances[i] = balanceOf(users[i]);
            }
        }
    }

    function submitClick(uint256 datetime, bytes32 hash) external {
        if (
            hash !=
            keccak256(
                abi.encodePacked(<<REDACTED>>)
            )
        ) {
            emit SusEvent(msg.sender);
        }

        // Check if the player is new
        if (players[msg.sender].firstBlockPlayed == 0) {
            players[msg.sender] = Player(msg.sender, block.number);
            playerAddresses.push(msg.sender);
        }

        _mint(msg.sender, 1 ether);
        emit ScoreUpdateEvent(msg.sender, balanceOf(msg.sender));
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        require(
            from == address(0) || to == address(0),
            "Transfers are disabled"
        );
        super._update(from, to, value);
    }

    function getPlayers(uint256 offset, uint256 count)
        external
        view
        returns (Player[] memory)
    {
        uint256 totalPlayers = playerAddresses.length;
        if (offset >= totalPlayers) {
            return new Player[](0);
        }

        uint256 end = offset + count;
        if (end > totalPlayers) {
            end = totalPlayers;
        }

        Player[] memory result = new Player[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = players[playerAddresses[i]];
        }
        return result;
    }
}
