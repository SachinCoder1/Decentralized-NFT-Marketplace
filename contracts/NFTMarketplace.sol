// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* imports */
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/* errors for reverting*/
error NFTMarketplace__reEntrancyCallFound(); // If reEntrancy attack
error NFTMarketplace__NotOwner(); // If the sender is not the owner of the item
error NFTMarketplace__ItemPriceShouldBeGreaterThenZero(); // When selling a item if the price is 0
error NFTMarketplace__WithdrawCannotBeZero(); // If there is no money when withdrawing.
error NFTMarketplace__TransactionFailed(); // If transaction fail.
error NFTMarketplace__ItemNotApproved(); // If the item is not approved.
error NFTMarketplace__ItemAlreadyListed(address _nftAddress, uint256 _tokenId); // If the item owner try to list the item again.
error NFTMarketplace__ItemNotAlreadyListed(
    address _nftAddress,
    uint256 _tokenId
); // If user try to buy the not listed item.
error NFTMarketplace__ItemPriceNotSatisfied(
    address _nftAddress,
    uint256 _tokenId,
    uint256 price
); // When buying if the msg.value is less then the item price.

contract NFTMarketplace {
    bool private locked;

    constructor() {
        locked = false;
    }

    /* State variables */

    /*  Struct */
    struct Listing {
        uint256 price;
        address seller;
    }

    /* mapping */
    mapping(address => mapping(uint256 => Listing)) private allListings; // Keep track of all listings
    mapping(address => uint256) private sellerAmounts;

    /* events */
    event ItemList(
        address indexed seller,
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _price
    );

    event ItemBought(
        address indexed buyer,
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 listingPrice
    );

    event ItemCancelled(
        address indexed seller,
        address indexed _nftAddress,
        uint256 indexed _tokenId
    );

    event ItemUpdated(
        address indexed seller,
        address indexed _nftAddress,
        uint256 indexed _tokenId,
        uint256 _newPrice
    );

    /* Modifiers */

    modifier reEntrancyGuard() {
        if (locked) {
            revert NFTMarketplace__reEntrancyCallFound();
        }

        locked = true;

        _;

        locked = false;
    }

    modifier onlyOwner(
        address seller,
        address _nftAddress,
        uint256 _tokenId
    ) {
        IERC721 nft = IERC721(_nftAddress);
        address _seller = nft.ownerOf(_tokenId);
        if (seller != _seller) {
            revert NFTMarketplace__NotOwner();
        }

        _;
    }

    modifier enoughPrice(uint256 _price) {
        if (_price <= 0) {
            revert NFTMarketplace__ItemPriceShouldBeGreaterThenZero();
        }

        _;
    }

    modifier notListed(address _nftAddress, uint256 _tokenId) {
        Listing memory listing = allListings[_nftAddress][_tokenId];
        if (listing.price > 0) {
            revert NFTMarketplace__ItemAlreadyListed(_nftAddress, _tokenId);
        }

        _;
    }

    modifier isListed(address _nftAddress, uint256 _tokenId) {
        Listing memory listing = allListings[_nftAddress][_tokenId];
        if (listing.price <= 0) {
            revert NFTMarketplace__ItemNotAlreadyListed(_nftAddress, _tokenId);
        }

        _;
    }







    /* Pure/Get functions */

    
    function getSpecificListing(address _nftAddress, uint256 _tokenId) external view returns(Listing memory) {
       return allListings[_nftAddress][_tokenId];
    }

    // Get withdraw money
    function getSellerEarnedMoney(address _seller) external view returns (uint256) {
        return sellerAmounts[_seller];
    }










    /* Logics */

    // List an item
    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price
    )
        external
        enoughPrice(_price)
        notListed(_nftAddress, _tokenId)
        onlyOwner(msg.sender, _nftAddress, _tokenId)
    {
        IERC721 nft = IERC721(_nftAddress);

        if (nft.getApproved(_tokenId) != address(this)) {
            revert NFTMarketplace__ItemNotApproved();
        }

        allListings[_nftAddress][_tokenId] = Listing(_price, msg.sender);
        emit ItemList(msg.sender, _nftAddress, _tokenId, _price);
    }

    // Buy the item
    function buyItem(address _nftAddress, uint256 _tokenId)
        external
        payable
        reEntrancyGuard
        isListed(_nftAddress, _tokenId)
    {
        Listing memory listing = allListings[_nftAddress][_tokenId];
        if (msg.value < listing.price) {
            revert NFTMarketplace__ItemPriceNotSatisfied(
                _nftAddress,
                _tokenId,
                listing.price
            );
        }
        sellerAmounts[listing.seller] += msg.value;
        delete (allListings[_nftAddress][_tokenId]);
        IERC721(_nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            _tokenId
        );

        emit ItemBought(msg.sender, _nftAddress, _tokenId, listing.price);
    }

    // Cancel a item
    function cancelItem(address _nftAddress, uint256 _tokenId)
        external
        onlyOwner(msg.sender, _nftAddress, _tokenId)
        isListed(_nftAddress, _tokenId)
    {
        delete (allListings[_nftAddress][_tokenId]);
        emit ItemCancelled(msg.sender, _nftAddress, _tokenId);
    }

    // Update any item

    function updateItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice
    )
        external
        onlyOwner(msg.sender, _nftAddress, _tokenId)
        isListed(_nftAddress, _tokenId)
    {
        allListings[_nftAddress][_tokenId].price = _newPrice;
        emit ItemUpdated(msg.sender, _nftAddress, _tokenId, _newPrice);
        
    }


    // Withdraw money

    function withdrawMoney() external {
        uint256 money = sellerAmounts[msg.sender];
        if(money <= 0) {
            revert NFTMarketplace__WithdrawCannotBeZero();
        }

        sellerAmounts[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: money}("");
        if(!success){
            revert NFTMarketplace__TransactionFailed();
        }


    }









}
