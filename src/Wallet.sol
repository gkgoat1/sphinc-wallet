// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Account} from "openzeppelin-contracts/contracts/account/Account.sol";
import {ERC7821} from "openzeppelin-contracts/contracts/account/extensions/draft-ERC7821.sol";
import {IERC1271} from "openzeppelin-contracts/contracts/interfaces/IERC1271.sol";
import {SLHDSA} from "slhdsa-solidity/SLHDSA.sol";

contract Wallet is Account, ERC7821, IERC1271{
    bytes pubkey;
    mapping(uint248 => uint256) presigs;
    constructor(bytes calldata _pubkey){
        pubkey = _pubkey;
    }
    function createPresigs(bytes calldata data) external{
        require(msg.sender == address(this));
        for(uint256 a = 0; a < data.length / 32; a++){
            uint256 i = uint256(bytes32(data[a * 32:a * 32 + 32]));
            presigs[uint248(i >> 3)] |= (1 << (i & 7));
        }
    }
    function _rawSignatureValidation(bytes32 hash, bytes calldata signature) internal view override returns (bool){
        uint256 i = uint256(keccak256(abi.encodePacked(hash, address(this), signature)));
        if(presigs[uint248(i >> 3)] & (1 << (i & 7)) != 0)return true;
        if(SLHDSA.verify(0,pubkey,hash,signature))return true;
        return false;
    }
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue){
        if(_rawSignatureValidation(hash, signature))return msg.sig;
        return 0xffffffff;
    }
    function _erc7821AuthorizedExecutor(
        address caller,
        bytes32 mode,
        bytes calldata executionData
    ) internal view virtual override returns (bool) {
        return caller == address(entryPoint()) || super._erc7821AuthorizedExecutor(caller, mode, executionData);
    }
}