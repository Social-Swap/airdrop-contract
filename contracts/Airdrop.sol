// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Type.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Airdrop is Ownable, Type {
    using SafeERC20 for IERC20;
    address private signerAddress;
    mapping(uint256 => bool) private airdropStatus;

    event airDropRewardEvent(uint256 indexed airdropOrderId, address managerAddress);

    constructor() {
        
    }

    function setSignAddress(address signer) onlyOwner() external {
        signerAddress = signer;
    }

    function airDropReward(airdropStruct memory airdropInfo, bytes memory signature) external {
        address managerAddress = airdropInfo.managerAddress;
        uint256 airdropOrderId = airdropInfo.airdropOrderId;
        airdropRewardStruct[] memory airdropRewards = airdropInfo.airdropRewards;
        require(managerAddress == msg.sender, "Must be manager account");
        require(!airdropStatus[airdropOrderId], "Airdrop reward has been granted");
        require(airdropOrderId != 0, "Airdrop orderId must not be null");
        require(airdropRewards.length > 0, "Airdrop reward must not be null");

        // check parameters
        validTokenReward(airdropRewards);
        // check signatrue
        bytes32[] memory rewardHashs = new bytes32[](airdropRewards.length);
        for(uint256 i = 0; i < airdropRewards.length; i++){
            airdropRewardStruct memory airdropReward = airdropRewards[i];
            rewardHashs[i] = keccak256(abi.encodePacked(airdropReward.tokenType, airdropReward.tokenAddress, airdropReward.tokenIds, airdropReward.amount, airdropReward.tokenId, airdropReward.receiptAddress));
        }
        bytes32 message = prefixed(keccak256(abi.encodePacked(airdropOrderId, rewardHashs, managerAddress, address(this))));
        require(recoverSigner(message,signature) == signerAddress, "Signature is invalid");

        for(uint i=0;i<airdropRewards.length;i++){
            airdropRewardStruct memory airdropReward = airdropRewards[i];
            if (tokenTypeEnum.ERC20 == airdropReward.tokenType) {
                erc20Reward(airdropReward.tokenAddress, airdropReward.amount, airdropReward.receiptAddress, managerAddress);
            } else if (tokenTypeEnum.ERC721 == airdropReward.tokenType) {
                erc721Reward(airdropReward.tokenAddress, airdropReward.tokenIds, airdropReward.receiptAddress, managerAddress);
            } else {
                erc1155Reward(airdropReward.tokenAddress, airdropReward.amount, airdropReward.receiptAddress, managerAddress, airdropReward.tokenId);
            }
        }

        airdropStatus[airdropOrderId] = true;
        emit airDropRewardEvent(airdropOrderId, managerAddress);
    }

    function validTokenReward(airdropRewardStruct[] memory airdropRewards) pure internal {
        for(uint i = 0; i < airdropRewards.length; i++){
            airdropRewardStruct memory airdropReward = airdropRewards[i];
            require(airdropReward.receiptAddress.length > 0, "Recipient address must not be null");
            require(airdropReward.tokenAddress != address(0), "Token address must not be null");
            if (tokenTypeEnum.ERC20 == airdropReward.tokenType) {
                require(airdropReward.amount > 0, "Token erc20 amount must greater than 0");
            } else if (tokenTypeEnum.ERC721 == airdropReward.tokenType) {
                require(airdropReward.tokenIds.length > 0, "Token erc721 token id must not be null");
            } else {
                require(airdropReward.amount > 0, "Token erc1155 amount must greater than 0");
            }
        }
    }

    function erc20Reward(address tokenAddress, uint256 amount, address[] memory receiptAddress, address managerAddress) internal {
        for (uint i = 0; i < receiptAddress.length; i++) {
            IERC20(tokenAddress).safeTransferFrom(managerAddress, receiptAddress[i], amount);
        }
    }

    function erc721Reward(address tokenAddress, uint256[] memory tokenIds, address[] memory receiptAddress, address managerAddress) internal {       
        for (uint i = 0; i < receiptAddress.length; i++) {
            IERC721(tokenAddress).safeTransferFrom(managerAddress, receiptAddress[i], tokenIds[i]);
        }

    }

    function erc1155Reward(address tokenAddress, uint256 amount, address[] memory receiptAddress, address managerAddress, uint256 tokenId) internal {
        for (uint i = 0; i < receiptAddress.length; i++) {
            IERC1155(tokenAddress).safeTransferFrom(managerAddress, receiptAddress[i], tokenId, amount, "");
        }
    }
    
    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "Signature length is incorrect");
        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function getAirdropStatus(uint256 airdropOrderId) external view returns (bool) {
        return airdropStatus[airdropOrderId];
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

} 
