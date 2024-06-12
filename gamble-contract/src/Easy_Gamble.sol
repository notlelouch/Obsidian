// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Gamble is Ownable {

    address[] public players;
    uint8 public maxPlayers;
    bool public gameStarted;
    uint256 public entryFee;
    uint256 public gameId;
    address public winner;

    event GameStarted(uint256 gameId, uint8 maxPlayers, uint256 entryFee);
    event PlayerJoined(uint256 gameId, address player);
    event GameEnded(uint256 gameId, address winner);

    constructor()Ownable(msg.sender){
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
            requestRandomWinner();
        }
    }

    function requestRandomWinner() private {
        winner = players[uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % players.length];
        
        (bool sent, ) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");

        emit GameEnded(gameId, winner);
        gameStarted = false;
    }

    receive() external payable {}
    fallback() external payable {}
}