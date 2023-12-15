// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Type {

    enum tokenTypeEnum{
        ERC20, ERC721, ERC1155
    }

    struct airdropStruct {
        uint256 airdropOrderId;
        airdropRewardStruct[] airdropRewards;
        address managerAddress;
    }

    struct airdropRewardStruct {
        // erc20 erc721 erc1155
        tokenTypeEnum tokenType;
        address tokenAddress;
        // for erc721
        uint256[] tokenIds;
        // for every recipient 
        uint256 amount;
        // for erc1155
        uint256 tokenId;
        address[] receiptAddress;
    }

}


