// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// NFT contract to inherit from
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Helper we wrote to encode in Base64
import "./libraries/Base64.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


import "hardhat/console.sol";


// Our contract inherits from ERC721, the standard NFT contract
contract MyEpicGame is ERC721 {
    // We'll hold our character's attributes in a struct.
    // Feel free to add whatever else (defense, skill, etc.)
    struct CharacterAttributes {
        uint characterIndex;
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;
    }

    // The tokenId is the NFTs unique identifier, it's just a number like 0, 1, 2, 3
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Array for character default data
    // Helpful for minting new characters
    // Stuff like HP, AD, etc.
    CharacterAttributes[] defaultCharacters;

    // We create a mapping from NFT's tokenId => that NFT's attributes
    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

    // Simple struct to hold boss data
    struct BigBoss {
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;
    }
    BigBoss public bigBoss;

    // A mapping from an address => the NFT's tokenId, ez way to store owner of NFT
    mapping(address => uint256) public nftHolders;

    event CharacterNFTMinted(address sender, uint256 token, uint256 characterIndex);
    event AttackComplete(uint newBossHp, uint newPlayerHp);

    // Data passed into the contract during creation/initialization
    // Pass these values in from run.js
    constructor(
        string[] memory characterNames,
        string[] memory characterImageURIs,
        uint[] memory characterHp,
        uint[] memory characterAttackDmg,
        string memory bossName,
        string memory bossImageURI,
        uint bossHp,
        uint bossAttackDamage
    )
    ERC721("Heroes", "HERO")

{
    // Initialize the boss. Save to global "bigBoss" state variable.
    bigBoss = BigBoss({
        name: bossName,
        imageURI: bossImageURI,
        hp: bossHp,
        maxHp: bossHp,
        attackDamage: bossAttackDamage
    });

    console.log("Done initializing boss %s w/ HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);

    {
    // Loop through all characters, then save values in contract
    // Used for minting our NFTs
    for (uint i = 0; i < characterNames.length; i += 1) {
        defaultCharacters.push(CharacterAttributes({
            characterIndex: i,
            name: characterNames[i],
            imageURI: characterImageURIs[i],
            hp: characterHp[i],
            maxHp: characterHp[i],
            attackDamage: characterAttackDmg[i]
        }));
    
    CharacterAttributes memory c = defaultCharacters[i];

    // Hardhat's use of console.log() allows max 4 parameters, any order: uint, string, boolean, address
    console.log("Done initializing %s w/ HP %s, img %s", c.name, c.hp, c.imageURI);
    }

    // Increment tokenIDs so first NFT has ID of 1
    _tokenIds.increment();
    }
}


    // Users use this to get NFT based on characterId
    function mintCharacterNFT(uint _characterIndex) external {
        // Gets current tokenId, starts at 1
        uint256 newItemId = _tokenIds.current();

        // Assigns tokenId to user's wallet address!
        _safeMint(msg.sender, newItemId);

        // Map tokenId => character attributes
        nftHolderAttributes[newItemId] = CharacterAttributes({
            characterIndex: _characterIndex,
            name: defaultCharacters[_characterIndex].name,
            imageURI: defaultCharacters[_characterIndex].imageURI,
            hp: defaultCharacters[_characterIndex].hp,
            maxHp: defaultCharacters[_characterIndex].maxHp,
            attackDamage: defaultCharacters[_characterIndex].attackDamage
        });

        console.log("Minted NFT w/ tokenID %s and characterIndex %s", newItemId, _characterIndex);
        
        // Keeps ez way of seeing who owns what NFT
        nftHolders[msg.sender] = newItemId;

        // Add 1 to tokenId for next person that uses it
        _tokenIds.increment();

        emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }


    function attackBoss() public {
        // Get state of player's NFT
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];

        console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", player.name, player.hp, player.attackDamage);
        console.log("Boss %s has %s HP and %s AD", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);

        // Make sure player has more than 0 HP
        require (
            player.hp > 0,
            "ERROR! Character must have HP to attack boss."
        );

        // Make sure boss has more than 0 HP
        require (
            bigBoss.hp > 0,
            "ERROR! Boss must have HP to attack player."
        );

        // Allow player to attack boss
        if (bigBoss.hp <= player.attackDamage) {
            bigBoss.hp = 0;
        } else {
            bigBoss.hp = bigBoss.hp - player.attackDamage;
        }

        // Allow boss to attack player
        if (player.hp <= bigBoss.attackDamage) {
            player.hp = 0;
        } else {
            player.hp = player.hp - bigBoss.attackDamage;
        }
        
        // Console for ease
        console.log("Player attacked boss. New boss hp: %s", bigBoss.hp);
        console.log("Boss attacked player. New player hp: %s\n", player.hp);

        emit AttackComplete(bigBoss.hp, player.hp);
    }


    function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
        // Get tokenId of user's NFT
        uint256 userNftTokenId = nftHolders[msg.sender];
        // If the user has a tokenId in the map, return their character
        if (userNftTokenId > 0) {
            return nftHolderAttributes[userNftTokenId];
        }
        // Else, return empty character
        else {
            CharacterAttributes memory emptyStruct;
            return emptyStruct;
        }
    }


    function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
        return defaultCharacters;
    }


    function getBigBoss() public view returns (BigBoss memory) {
        return bigBoss;
    }


    function tokenURI(uint _tokenId) public view override returns (string memory) {
    CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

    string memory strHp = Strings.toString(charAttributes.hp);
    string memory strMaxHp = Strings.toString(charAttributes.maxHp);
    string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);
    
    string memory json = Base64.encode(
        abi.encodePacked(
            '{"name": "',
            charAttributes.name,
            ' -- NFT #: ',
            Strings.toString(_tokenId),
            '", "description": "This is an NFT that lets people play in the game Beat Umbridge!", "image": "',
            charAttributes.imageURI,
            '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Attack Damage", "value": ',
            strAttackDamage,'} ]}'
        )
    );
    string memory output = string(
        abi.encodePacked("data:application/json;base64,", json)
    );
    return output;
    }
}