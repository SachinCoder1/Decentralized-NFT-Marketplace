const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");


const logging = (text) => {
  return text + " ---------------------------";
};

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();


  args = [];

  log(logging("Started Deploying NFTMarketplace"));

  const NFTMarketplace = await deploy("NFTMarketplace", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  log(logging("Successfully deployed NFTMarketplace"));

  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    log(logging("verifying"));
    verify(NFTMarketplace.address);
  }
};


module.exports.tags = ["all", "nftmarketplace", "main"]
