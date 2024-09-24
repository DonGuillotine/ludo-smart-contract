// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract LudoGame {
    uint8 constant MAX_PLAYERS = 4;
    uint8 constant TOKENS_PER_PLAYER = 4;
    uint8 constant BOARD_SIZE = 52;
    uint8 constant DICE_SIDES = 6;
    uint8 constant START_POSITION = 1;

    struct Player {
        address addr;
        uint8[TOKENS_PER_PLAYER] tokenPositions;
        uint8 tokensHome;
        uint8 tokenStart;
    }

    Player[MAX_PLAYERS] public players;
    uint8 public currentPlayerIndex;
    uint8 public playerCount;
    uint256 private nonce;
    bool public gameInProgress;

    event GameStarted();
    event DiceRolled(address player, uint8 roll);
    event TokenMoved(address player, uint8 tokenIndex, uint8 newPosition);
    event TokenCaptured(address capturer, address captured, uint8 position);
    event PlayerWon(address player);

    constructor() {
        nonce = 0;
        gameInProgress = false;
    }

    function joinGame() external {
        require(!gameInProgress, "Game has already started");
        require(playerCount < MAX_PLAYERS, "Game is full");
        players[playerCount].addr = msg.sender;
        players[playerCount].tokenStart = START_POSITION + (playerCount * (BOARD_SIZE / MAX_PLAYERS));
        for (uint8 i = 0; i < TOKENS_PER_PLAYER; i++) {
            players[playerCount].tokenPositions[i] = 0;
        }
        players[playerCount].tokensHome = 0;
        playerCount++;
    }

    function startGame() external {
        require(!gameInProgress, "Game has already started");
        require(playerCount >= 2, "Not enough players");
        gameInProgress = true;
        currentPlayerIndex = 0;
        emit GameStarted();
    }

    function rollDice() public returns (uint8) {
        require(gameInProgress, "Game has not started");
        require(msg.sender == players[currentPlayerIndex].addr, "Not your turn");
        
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            nonce
        )));
        
        nonce++;
        
        uint8 roll = uint8(randomNumber % DICE_SIDES) + 1;
        
        emit DiceRolled(msg.sender, roll);
        return roll;
    }

    function moveToken(uint8 tokenIndex, uint8 spaces) external {
        require(gameInProgress, "Game has not started");
        require(msg.sender == players[currentPlayerIndex].addr, "Not your turn");
        require(tokenIndex < TOKENS_PER_PLAYER, "Invalid token index");
        
        Player storage currentPlayer = players[currentPlayerIndex];
        uint8 currentPosition = currentPlayer.tokenPositions[tokenIndex];
        
        if (currentPosition == 0 && spaces == 6) {
            currentPosition = currentPlayer.tokenStart;
        } else if (currentPosition == 0) {
            revert("Need a 6 to move from start");
        } else {
            currentPosition = (currentPosition - 1 + spaces) % BOARD_SIZE + 1;
        }
        
        for (uint8 i = 0; i < playerCount; i++) {
            if (i != currentPlayerIndex) {
                for (uint8 j = 0; j < TOKENS_PER_PLAYER; j++) {
                    if (players[i].tokenPositions[j] == currentPosition) {
                        players[i].tokenPositions[j] = 0; // Send captured token back to start
                        emit TokenCaptured(msg.sender, players[i].addr, currentPosition);
                    }
                }
            }
        }
        
        currentPlayer.tokenPositions[tokenIndex] = currentPosition;
        
        emit TokenMoved(msg.sender, tokenIndex, currentPosition);
        if (currentPosition == currentPlayer.tokenStart) {
            currentPlayer.tokensHome++;
            if (currentPlayer.tokensHome == TOKENS_PER_PLAYER) {
                emit PlayerWon(msg.sender);
                gameInProgress = false;
                return;
            }
        }
        
        currentPlayerIndex = (currentPlayerIndex + 1) % playerCount;
    }

    function getGameState() external view returns (
        address[] memory playerAddresses,
        uint8[MAX_PLAYERS][TOKENS_PER_PLAYER] memory tokenPositions,
        uint8[] memory tokensHome,
        uint8 currentPlayer,
        bool isGameInProgress
    ) {
        playerAddresses = new address[](playerCount);
        tokensHome = new uint8[](playerCount);

        for (uint8 i = 0; i < playerCount; i++) {
            playerAddresses[i] = players[i].addr;
            for (uint8 j = 0; j < TOKENS_PER_PLAYER; j++) {
                tokenPositions[i][j] = players[i].tokenPositions[j];
            }
            tokensHome[i] = players[i].tokensHome;
        }

        return (playerAddresses, tokenPositions, tokensHome, currentPlayerIndex, gameInProgress);
    }
}
