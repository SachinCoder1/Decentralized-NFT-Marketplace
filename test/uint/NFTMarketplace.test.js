const {assert, expect} = require('chai');
const {network, deployments, ethers, getNamedAccounts} = require('hardhat');
const { developmentChains } = require('../../helper-hardhat-config');

if(!developmentChains.includes(network.name)){
    describe.skip;
}else{
    describe("NFT marketplace test for buy item and get item", () => {
        let NFTMarketplace, BasicNFT, deployer, player;

        const [PRiCE, TOKEN_ID] = [ethers.utils.parseEther("0.1"), 0];

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

        })

        it("list an item", async () => {
            await NFTMarketplace.listItem(BasicNFT.address, TOKEN_ID, PRiCE);
            const getListing = await NFTMarketplace.getSpecificListing(BasicNFT.address, TOKEN_ID);
            assert(getListing.price.toString() == PRiCE.toString());
        }),2

        it("buy an item", async () => {

            await NFTMarketplace.listItem(BasicNFT.address, TOKEN_ID, PRiCE);

            const newPlayerOfMarketplace = NFTMarketplace.connect(player);
            await newPlayerOfMarketplace.buyItem(BasicNFT.address, TOKEN_ID, {value: PRiCE});

            const newNFTOwner = await BasicNFT.ownerOf(TOKEN_ID);
            const withdrawal = await NFTMarketplace.getSellerEarnedMoney(deployer);

            assert(newNFTOwner.toString() == player.address);
            assert(withdrawal.toString() == PRiCE.toString());



        })




    })

}