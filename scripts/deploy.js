const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contract with the account:", deployer.address);

  const LudoGame = await hre.ethers.getContractFactory("LudoGame");
  const ludoGame = await LudoGame.deploy();
  await ludoGame.waitForDeployment();

  console.log("LudoGame deployed to:", await ludoGame.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });