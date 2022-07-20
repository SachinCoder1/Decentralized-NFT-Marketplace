// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* imports */
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/* errors for reverting*/
error NFTMarketplace__NotOwner();
error NFTMarketplace__NFTPriceShouldBeGreaterThenZero();
error NFTMarketplace__NFTNotApproved();
error NFTMarketplace__NFTAlreadyListed(address _nftAddress, uint256 _tokenId);

contract NFTMarketplace {
    /* State variables */

    /*  Struct */
    struct Listing {
        uint256 price;
        address seller;
    }

    /* mapping */
    mapping(address => mapping(uint256 => Listing)) private allListings;

    /* events */
    event ItemList(
        address indexed seller,
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _price
    );



    /* Modifiers */

    modifier notListed(address _nftAddress, uint256 _tokenId) {
       Listing memory listing = allListings[_nftAddress][_tokenId];
        if(listing.price > 0){
            revert NFTMarketplace__NFTAlreadyListed(_nftAddress, _tokenId);
        }
        _;
    }

    modifier onlyOwner(address seller, address _nftAddress, uint256 _tokenId) {
        IERC721 nft = IERC721(_nftAddress);
        address _seller = nft.ownerOf(_tokenId);
        if(seller != _seller) {
            revert NFTMarketplace__NotOwner();
        }
       _;

    }

    /* Pure/Get functions */

    /* Logics */

    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price
    ) external notListed(_nftAddress, _tokenId) onlyOwner(msg.sender, _nftAddress, _tokenId) {
        if (_price <= 0) {
            revert NFTMarketplace__NFTPriceShouldBeGreaterThenZero();
        }
        IERC721 nft = IERC721(_nftAddress);

        if (nft.getApproved(_tokenId) != address(this)) {
            revert NFTMarketplace__NFTNotApproved();
        }

        allListings[_nftAddress][_tokenId] = Listing(_price, msg.sender);
        emit ItemList(msg.sender, _nftAddress, _tokenId, _price);

    }

}
