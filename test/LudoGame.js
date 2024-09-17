const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LudoGame", function () {
  let LudoGame;
  let ludoGame;
  let owner;
  let addr1;
  let addr2;
  let addr3;
  let addrs;

  beforeEach(async function () {
    LudoGame = await ethers.getContractFactory("LudoGame");
    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    ludoGame = await LudoGame.deploy();
    await ludoGame.waitForDeployment();
  });

  describe("Game setup", function () {
    it("Should allow players to join the game", async function () {
      await ludoGame.connect(addr1).joinGame();
      await ludoGame.connect(addr2).joinGame();

      const gameState = await ludoGame.getGameState();
      expect(gameState.playerAddresses.length).to.equal(2);
      expect(gameState.playerAddresses[0]).to.equal(addr1.address);
      expect(gameState.playerAddresses[1]).to.equal(addr2.address);
    });

    it("Should not allow more than MAX_PLAYERS to join", async function () {
      await ludoGame.connect(addr1).joinGame();
      await ludoGame.connect(addr2).joinGame();
      await ludoGame.connect(addr3).joinGame();
      await ludoGame.connect(addrs[0]).joinGame();

      await expect(ludoGame.connect(addrs[1]).joinGame()).to.be.revertedWith("Game is full");
    });

    it("Should start the game with at least two players", async function () {
      await ludoGame.connect(addr1).joinGame();
      await ludoGame.connect(addr2).joinGame();

      await ludoGame.connect(addr1).startGame();

      const gameState = await ludoGame.getGameState();
      expect(gameState.isGameInProgress).to.be.true;
    });

    it("Should not start the game with less than two players", async function () {
      await ludoGame.connect(addr1).joinGame();

      await expect(ludoGame.connect(addr1).startGame()).to.be.revertedWith("Not enough players");
    });
  });

  describe("Game play", function () {
    beforeEach(async function () {
      await ludoGame.connect(addr1).joinGame();
      await ludoGame.connect(addr2).joinGame();
      await ludoGame.connect(addr1).startGame();
    });

    it("Should not allow players to roll out of turn", async function () {
      await expect(ludoGame.connect(addr2).rollDice()).to.be.revertedWith("Not your turn");
    });
  });
});