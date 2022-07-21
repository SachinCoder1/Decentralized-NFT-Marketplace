const { ethers } = require("hardhat");
const PRICE = ethers.utils.parseEther("0.1");

const mintAndList = async () => {
    const NFTMarketplace = await ethers.getContract("NFTMarketplace");
    const BasicNFT = await ethers.getContract("BasicNFT");
    console.log("Starting Minting an NFT -------");
    const mintTx = await BasicNFT.mintNft();
    const mintTxReciept = await mintTx.wait(1);
    const tokenId = mintTxReciept.events[0].args.tokenId;
    console.log("approving NFT -------");
    
    const approvalTx = await BasicNFT.approve(NFTMarketplace.address, tokenId);
    await approvalTx.wait(1);
    console.log("Started Listing the NFT -----------");

    const tx = await NFTMarketplace.listItem(BasicNFT.address, tokenId, PRICE);
    await tx.wait();
    console.log("NFT Listed success ------------")





};

mintAndList()
  .then(() => process.exit(0))
  .catch((err) => {
    console.log("error in mintAndList function ", err);
  });
