// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Account} from "openzeppelin-contracts/contracts/account/Account.sol";
import {ERC7821} from "openzeppelin-contracts/contracts/account/extensions/draft-ERC7821.sol";
import {IERC1271} from "openzeppelin-contracts/contracts/interfaces/IERC1271.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {SLHDSA} from "slhdsa-solidity/SLHDSA.sol";

contract Wallet is Account, ERC7821, IERC1271, Initializable{
    bytes pubkey;
    mapping(uint248 => uint256) presigs;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    function _initialize(bytes calldata _pubkey) external initializer{
        require(_pubkey.length == 64);
        pubkey = _pubkey;
    }
    function createPresigs(bytes calldata data) external{
        require(msg.sender == address(this));
        for(uint256 a = 0; a < data.length / 32; a++){
            uint256 i = uint256(bytes32(data[a * 32:a * 32 + 32]));
            presigs[uint248(i >> 8)] |= (1 << (i & 255));
        }
    }
    function delegate(address target, bytes calldata data) external returns (bytes memory result){
        require(msg.sender == address(this));
        bool success;
        (success, result) = target.delegatecall(data);
        require(success);
    }
    function _rawSignatureValidation(bytes32 hash, bytes calldata signature) internal view override returns (bool){
        uint256 i = uint256(keccak256(abi.encodePacked(hash, address(this), signature)));
        if(presigs[uint248(i >> 8)] & (1 << (i & 255)) != 0)return true;
        bytes memory message = new bytes(32);
        for(i = 0; i < 32; i++)message[i] = hash[i];
        if(SLHDSA.verify(0,pubkey,message,signature))return true;
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
    fallback() external{
        require(msg.sender == address(this));
        address _singleton = 0xcA11bde05977b3631167028862bE2a173976CA11;
        assembly{
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}