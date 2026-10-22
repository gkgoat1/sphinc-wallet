// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {BeaconProxy} from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
contract WalletProxy is BeaconProxy{
    constructor(address beacon, bytes memory pubkey) BeaconProxy(beacon, abi.encodeWithSignature("_initialize(bytes)",pubkey)){

    }
}