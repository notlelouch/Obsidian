// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Gamble is VRFConsumerBaseV2, Ownable {
    // Chainlink variables
    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    uint64 private immutable subscriptionId;
    bytes32 private immutable keyHash;
    uint32 private immutable callbackGasLimit = 100000;
    uint16 private immutable requestConfirmations = 3;
    uint32 private immutable numWords = 1;

    address[] public players;
    uint8 public maxPlayers;
    bool public gameStarted;
    uint256 public entryFee;
    uint256 public gameId;

    event GameStarted(uint256 gameId, uint8 maxPlayers, uint256 entryFee);
    event PlayerJoined(uint256 gameId, address player);
    event GameEnded(uint256 gameId, address winner, uint256 randomness);

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    )
        VRFConsumerBaseV2(vrfCoordinator)
        Ownable()
    {
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        subscriptionId = subscriptionId;
        keyHash = keyHash;
        gameStarted = false;
    }

    function startGame(uint8 _maxPlayers, uint256 _entryFee) public onlyOwner {
        require(!gameStarted, "Game is currently running");
        require(_maxPlayers > 0, "You cannot create a game with max players limit equal 0");

        delete players;
        maxPlayers = _maxPlayers;
        gameStarted = true;
        entryFee = _entryFee;
        gameId += 1;

        emit GameStarted(gameId, maxPlayers, entryFee);
    }

    function joinGame() public payable {
        require(gameStarted, "Game has not been started yet");
        require(msg.value == entryFee, "Value sent is not equal to entryFee");
        require(players.length < maxPlayers, "Game is full");

        players.push(msg.sender);
        emit PlayerJoined(gameId, msg.sender);

        if (players.length == maxPlayers) {
            getRandomWinner();
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 winnerIndex = randomWords[0] % players.length;
        address winner = players[winnerIndex];

        (bool sent, ) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");

        emit GameEnded(gameId, winner, randomWords[0]);
        gameStarted = false;
    }

    function getRandomWinner() private returns (uint256 requestId) {
        requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        return requestId;
    }

    receive() external payable {}
    fallback() external payable {}
}