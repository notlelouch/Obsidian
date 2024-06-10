// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "chainlink/src/v0.8/vrf/VRFConsumerBase.sol";

contract Gamble is VRFConsumerBase, Ownable {

    //Chainlink variables
    // The amount of LINK to send with the request
    uint256 public fee;
    // ID of public key against which randomness is generated
    bytes32 public keyHash;

    address[] public players;
    uint8 maxPlayers;
    bool public gameStarted;
    uint256 entryFee;
    uint256 public gameId;

    event GameStarted(uint256 gameId, uint8 maxPlayers, uint256 entryFee);
    event PlayerJoined(uint256 gameId, address player);
    event GameEnded(uint256 gameId, address winner,bytes32 requestId);

   /**
   * constructor inherits a VRFConsumerBase and initiates the values for keyHash, fee and gameStarted
   * vrfCoordinator: address of VRFCoordinator contract
   * linkToken: address of LINK token contract
   * vrfFee: the amount of LINK to send with the request
   * vrfKeyHash: ID of public key against which randomness is generated
   */
    // constructor(address vrfCoordinator, address linkToken, bytes32 vrfKeyHash, uint256 vrfFee)
    // VRFConsumerBase(vrfCoordinator, linkToken) Ownable(msg.sender){
    //     keyHash = vrfKeyHash;
    //     fee = vrfFee;
    //     gameStarted = false;
    // }
    constructor()
    VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK token address
        ) Ownable(msg.sender){
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 100000000000000;
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

        if(players.length == maxPlayers) {
            getRandomWinner();
        }
    }

    /**
    * fulfillRandomness is called by VRFCoordinator when it receives a valid VRF proof.
    * This function is overrided to act upon the random number generated by Chainlink VRF.
    * requestId:  this ID is unique for the request we sent to the VRF Coordinator
    * randomness: this is a random unit256 generated and returned to us by the VRF Coordinator
   */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual override  {
        uint256 winnerIndex = randomness % players.length;
        address winner = players[winnerIndex];

        (bool sent,) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
        
        emit GameEnded(gameId, winner,requestId);
        gameStarted = false;
    }

    function getRandomWinner() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");

        return requestRandomness(keyHash, fee);
    }

    receive() external payable {}
    fallback() external payable {}
}

// with old values: 0x166e279a565126677353812988Cc39F9dc464d0c
// with upgraded values: 0x57Bf25D396AF4eBe05427Df3C30A308E0F0f1358
// to migrate to chainlinkvrf v2: https://docs.chain.link/vrf/v2/subscription/migration-from-v1