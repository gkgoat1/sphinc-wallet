// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {Wallet} from "./Wallet.sol";
import {WalletProxy} from "./WalletProxy.sol";
contract WalletProvider is UpgradeableBeacon{
    Wallet templateWallet;
    mapping(bytes32 => WalletProxy) proxies;
    constructor(address implementation_, address initialOwner) UpgradeableBeacon(implementation_, initialOwner){
        templateWallet = new Wallet();
    }
    function construct(bytes calldata pubkey, uint256 flags) external returns (WalletProxy proxy){
        bytes32 salt = keccak256(abi.encodePacked(pubkey));
        if(address(proxies[salt]) != address(0))return proxies[salt];
        WalletProxy proxy = new WalletProxy{salt: salt}(address(this),pubkey);
        proxies[salt] = proxy;
        if(flags & (1 << 255) == (1 << 255)){
            transferOwnership(proxy);
        }
        return proxy;
    }
}