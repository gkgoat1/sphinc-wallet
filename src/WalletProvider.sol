// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {Wallet} from "./Wallet.sol";
import {WalletProxy} from "./WalletProxy.sol";
contract WalletProvider is UpgradeableBeacon{
    Wallet templateWallet;
    constructor(address implementation_, address initialOwner) UpgradeableBeacon(implementation_, initialOwner){
        templateWallet = new Wallet();
    }
    function construct(bytes calldata pubkey) external returns (WalletProxy proxy){
        return new WalletProxy{salt: keccak256(abi.encodePacked(pubkey))}(address(this),pubkey);
    }
}