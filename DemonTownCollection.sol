// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@5.0.0/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts@5.0.0/access/Ownable.sol";

contract TheDemonTownCollection is ERC721, ERC721Pausable, Ownable {
    uint256 private _nextTokenId;
    uint public cappedSupply = 100;
    uint public maxMintsPerAddress = 3;
    uint public mintPrice;
    uint8 public mintStage;
    string public baseURI = "https://csc299.s3.us-east-1.amazonaws.com/depauldemons/assets/json/";
    mapping(address => bool) public whiteList;
    event stateChanged(uint8 from, uint8 to);
    event mintedDemon(uint stage, address to, uint8 numOfTokens);
 


    constructor(address initialOwner, uint _mintPrice)
        ERC721("The DemonTown Collection", "DTC")
        Ownable(initialOwner)
    {mintPrice = _mintPrice;}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint8 amount) public onlyOwner {
        require(totalSupply() < cappedSupply, "Capped supply reached");

        for (uint i = 1; i <= amount; i++) { //loop to mint a token until amount is reached
            uint256 tokenId = _nextTokenId++;
            _safeMint(to, tokenId);
            emit mintedDemon(mintStage, to, amount);
        }
    }

    function totalSupply() public view returns (uint) {
        return _nextTokenId;
    }

    //allowed public minting depending on the stage
    function safePublicMint(address to, uint8 amount) public payable {
        require(totalSupply() < cappedSupply, "Capped supply reached"); 
        require(balanceOf(to) < maxMintsPerAddress);

        if (mintStage == 0) { //if stage is 0 only whitelisted can mint
            require(isWhiteListed(to) == true, "Error: Not Whitelisted");
        }
        else if (mintStage == 1) { //if stage is 1 only paying addresses can mint
            require(msg.value == mintPrice, "Error: amount paid is not sufficient");
        }
        else if (mintStage == 2) {
            //anyone can mint for free :)
        }
        else {
            revert("Invalid mint stage"); 
        }
        for (uint i = 1; i <= amount; i++) { 
            uint256 tokenId = _nextTokenId++;
            _safeMint(to, tokenId);
            emit mintedDemon(mintStage, to, amount);
        }
    }

    //checks if someone is whitelisted 
    function isWhiteListed(address to) public view returns(bool) {
        return whiteList[to]; //if the address is whitelisted returns true
    }

    //will add someone to the whitelist by mapping their address to a boolean value true
    function addToWhiteList(address to) public onlyOwner {
        whiteList[to] = true; //maps address to true bool
    }

    function withdraw() public onlyOwner{
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        (bool success, ) = owner().call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    //setter for mintstage + emit stateChanged event
    function setMintStage(uint8 _newStage) public onlyOwner {
        mintStage = _newStage;
        emit stateChanged(mintStage, _newStage);
    }

    //setter for URI
    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }
    
    //setter for mint price
    function setMintPrice(uint newMintPrice) public onlyOwner {
        mintPrice = newMintPrice;
    }


    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }
}