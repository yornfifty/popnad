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

    struct LeaderboardEntry {
        address playerAddress;
        uint256 balance;
    }

    mapping(address => Player) public players; // slot 0
    address[] public playerAddresses; // slot 1
    LeaderboardEntry[] public leaderboard; // slot 2

    event SusEvent(address indexed player);
    event ScoreUpdateEvent(address indexed player, uint256 balance);
    event UpdateLeaderboardEvent(address indexed player);
    event MintEvent(address indexed player, uint256 mintAmount, bytes32 hash);

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

    function updateLeaderboard() public  {
        uint256 length = playerAddresses.length;

        LeaderboardEntry[] memory tempLeaderboard = new LeaderboardEntry[](
            length
        );

        for (uint256 i = 0; i < length; i++) {
            address player = playerAddresses[i];
            uint256 balance = balanceOf(player);
            tempLeaderboard[i] = LeaderboardEntry(player, balance);
        }

        _quickSort(tempLeaderboard, 0, length - 1);
     
        delete leaderboard; 
        for (uint256 i = 0; i < length && i < 500; i++) {
            leaderboard.push(tempLeaderboard[i]); 
        }

        emit UpdateLeaderboardEvent(msg.sender);
    }

    function _quickSort(
        LeaderboardEntry[] memory arr,
        uint256 left,
        uint256 right
    ) internal pure {
        if (left >= right) return;

        uint256 pivotIndex = left + (right - left) / 2; // Choose a pivot
        LeaderboardEntry memory pivot = arr[pivotIndex];
        uint256 i = left;
        uint256 j = right;

        while (i <= j) {
            while (arr[i].balance > pivot.balance) i++; // Sort in descending order
            while (arr[j].balance < pivot.balance) j--;

            if (i <= j) {
                // Swap
                LeaderboardEntry memory temp = arr[i];
                arr[i] = arr[j];
                arr[j] = temp;
                i++;
                j--;
            }
        }

        // Recursively sort the two halves
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }

    function getLeaderboard()
        external
        view
        returns (LeaderboardEntry[] memory)
    {
        return leaderboard;
    }

    function getBalances(address[] calldata users)
        external
        view
        returns (uint256[] memory balances)
    {
        uint256 length = users.length;
        balances = new uint256[](length);

        unchecked {
            // Saves gas by skipping overflow checks (safe since `i < length`)
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

        uint256 mintAmount = getRandomMintAmount() * 1 ether;

        _mint(msg.sender, mintAmount);
        emit ScoreUpdateEvent(msg.sender, balanceOf(msg.sender));
        emit MintEvent(msg.sender, mintAmount, hash);
    }

    function getRandomMintAmount() internal view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, block.prevrandao)
            )
        ) % 10000;

        if (randomNumber < 7000) {
            return 1;
        } else if (randomNumber < 9000) {
            return 10;
        } else if (randomNumber < 9900) {
            return 100;
        } else if (randomNumber < 9999) {
            return 1000;
        } else {
            return 10000;
        }
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
        require(count!=0, "Count cannot be zero");


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
