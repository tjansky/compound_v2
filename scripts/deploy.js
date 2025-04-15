const hre = require("hardhat");

async function main() {
    const routerAddress = "0x165C3410fC91EF562C50559f7d2289fEbed552d9";
    const ordAddress = "0xd4f6Dfd7dA9731D11B8789226F6d692f02fea16F";
    const treasuryAddress = "0xc53AFC0a72cDd39C00B29df3aa754a01A53F6227";

    // deploy DividendDistributor
    const Distributor = await hre.ethers.getContractFactory("DividendDistributor");
    const distributor = await Distributor.deploy();
    await distributor.waitForDeployment();
    const distributorAddress = await distributor.getAddress();
    console.log(`Distributor - Deployed at: ${distributorAddress}`);
 
    // deploy Staking
    const Staking = await hre.ethers.getContractFactory("DividendDistributor");
    const staking = Staking.deploy(ordAddress, distributorAddress);
    await staking.waitForDeployment();
    const stakingAddress = await staking.getAddress();
    console.log(`Staking - Deployed at: ${stakingAddress}`);
    
    // deploy BuyAndBurn
    const BuyAndBurn = await hre.ethers.getContractFactory("BuyAndBurn");
    const buyAndBurn = BuyAndBurn.deploy(ordAddress, routerAddress);
    await buyAndBurn.waitForDeployment();
    const buyAndBurnAddress = await buyAndBurn.getAddress();
    console.log(`BuyAndBurn - Deployed at: ${buyAndBurnAddress}`);
    
    // deploy Admin
    const Admin = await hre.ethers.getContractFactory("Admin");
    const admin = Admin.deploy(treasuryAddress, buyAndBurnAddress, distributorAddress, routerAddress);
    await admin.waitForDeployment();
    const adminAddress = await admin.getAddress();
    console.log(`Admin - Deployed at: ${adminAddress}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });