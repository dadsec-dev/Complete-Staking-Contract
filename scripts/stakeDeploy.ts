import { ethers } from "hardhat";

async function main() {
  const [owner, addr1, addr2, addr3] = await ethers.getSigners();

  const stakingContract = await ethers.getContractFactory("StakeSystem");
  const deployStake = await stakingContract.deploy();

  await deployStake.deployed();

  const contractAddr = deployStake.address;

  console.log(`contract address is ${contractAddr}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
