const { assert, expect } = require("chai");
const { network, deployments, ethers, getNamedAccounts } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");

if (!developmentChains.includes(network.name)) {
  describe.skip;
} else {
  describe("NFT marketplace test for buy item and get item", () => {
    let NFTMarketplace, BasicNFT, deployer, player;

    const [PRICE, TOKEN_ID] = [ethers.utils.parseEther("0.1"), 0];

    beforeEach(async () => {
      const accounts = await ethers.getSigners();
      deployer = (await getNamedAccounts()).deployer;
      // player = (await getNamedAccounts()).player;
      player = accounts[1];
      await deployments.fixture(["all"]);
      NFTMarketplace = await ethers.getContract("NFTMarketplace");
      BasicNFT = await ethers.getContract("BasicNFT");
      await BasicNFT.mintNft();
      await BasicNFT.approve(NFTMarketplace.address, TOKEN_ID);
    });

    it("list an item", async () => {
      await NFTMarketplace.listItem(BasicNFT.address, TOKEN_ID, PRICE);
      const getListing = await NFTMarketplace.getSpecificListing(
        BasicNFT.address,
        TOKEN_ID
      );
      assert(getListing.price.toString() == PRICE.toString());
    });

    it("buy an item", async () => {
      await NFTMarketplace.listItem(BasicNFT.address, TOKEN_ID, PRICE);

      const newPlayerOfMarketplace = NFTMarketplace.connect(player);
      await newPlayerOfMarketplace.buyItem(BasicNFT.address, TOKEN_ID, {
        value: PRICE,
      });

      const newNFTOwner = await BasicNFT.ownerOf(TOKEN_ID);
      const withdrawal = await NFTMarketplace.getSellerEarnedMoney(deployer);

      assert(newNFTOwner.toString() == player.address);
      assert(withdrawal.toString() == PRICE.toString());
    });

    it("Updates an item if owner && reverts if not the owner && reverts if no listing is there ", async () => {
      const NEW_PRICE = ethers.utils.parseEther("0.2");
      await expect(
        NFTMarketplace.updateItem(BasicNFT.address, TOKEN_ID, NEW_PRICE)
      ).to.be.revertedWith("ItemNotAlreadyListed");

      await NFTMarketplace.listItem(BasicNFT.address, TOKEN_ID, PRICE);

      await NFTMarketplace.updateItem(BasicNFT.address, TOKEN_ID, NEW_PRICE);

      const getListing = await NFTMarketplace.getSpecificListing(
        BasicNFT.address,
        TOKEN_ID
      );
      assert(getListing.price.toString() == NEW_PRICE.toString());

      const newPlayerOfMarketplace = await NFTMarketplace.connect(player);
      await expect(
        newPlayerOfMarketplace.updateItem(BasicNFT.address, TOKEN_ID, PRICE)
      ).to.be.revertedWith("NotOwner");
    });

    it("Cancel Item if owner && revert if not owner && revert if no item is there", async () => {
      await expect(
        NFTMarketplace.cancelItem(BasicNFT.address, TOKEN_ID)
      ).to.be.revertedWith("ItemNotAlreadyListed");

      await NFTMarketplace.listItem(BasicNFT.address, TOKEN_ID, PRICE);

      expect(
        await NFTMarketplace.cancelItem(BasicNFT.address, TOKEN_ID)
      ).to.emit("ItemCancelled");

      const newPlayerOfMarketplace = await NFTMarketplace.connect(player);
      await expect(
        newPlayerOfMarketplace.cancelItem(BasicNFT.address, TOKEN_ID)
      ).to.be.revertedWith("NotOwner");
    });
  });
}
