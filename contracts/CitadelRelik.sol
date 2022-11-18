pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CitadelRelik is 
    ERC721, 
    Ownable, 
    AccessControlEnumerable,
    ERC721Enumerable
{
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");
    using SafeMath for uint256;
    uint256 public MAX_RELIK = 64;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    string private _baseTokenURI;

    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEV_ROLE, _msgSender());
    }

    /**
     * reserve relik
     */
    function reserveRelik(uint256 relikToMint) external {     
        require(hasRole(DEV_ROLE, _msgSender()), "must have dev role to reserve");   
        uint i;
        for (i = 0; i < relikToMint; i++) {
            if (totalSupply() < MAX_RELIK) {
                _safeMint(msg.sender, _tokenIdCounter.current());
                _tokenIdCounter.increment();
            }
        }
    }

    function getNextTokenId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function updateBaseURI(string memory baseTokenURI) external {
        require(hasRole(DEV_ROLE, _msgSender()), "must have dev role to update baseTokenURI");
        _baseTokenURI = baseTokenURI;
    }

    function addDevRole(address account) external virtual {
        require(hasRole(DEV_ROLE, _msgSender()), "must have dev role to add role");
        grantRole(DEV_ROLE, account);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}