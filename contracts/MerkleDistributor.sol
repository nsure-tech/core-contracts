// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleDistributor is Ownable {
    address public  token;
    bytes32 public  merkleRoot;
    uint256 public nonce;
    // This is a packed array of booleans.
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    // constructor(address token_, bytes32 merkleRoot_) public {
    //     token = token_;
    //     merkleRoot = merkleRoot_;
    //     nonce ++;
    // }

    function setToken(address token_) external onlyOwner {
        token = token_;
    }

    function setMerkleRoot (bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
        nonce ++;
    }

    function setNonce(uint256 nonce_) external onlyOwner {
        nonce = nonce_;
    }

    

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[nonce][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[nonce][claimedWordIndex] = claimedBitMap[nonce][claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }

     event Claimed(uint256 index, address account, uint256 amount);
}
