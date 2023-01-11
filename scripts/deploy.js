const {deploy} = require("hardhat");
const { deployContract } = require("@nomiclabs/hardhat-ethers");

const Tournament = await ethers.getContractFactory("Tournament");

async function main() {
  const tournament = await deploy(Tournament, {}, "0x0000000000000000000000000000000000000000", "Tournament", "0x0000000000000000000000000000000000000000", "1000", "1588232700", "300", "3", ["property1", "property2", "property3"], [200, 400, 600], "9");
  console.log(tournament.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });