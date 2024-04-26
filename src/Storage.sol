// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract STORAGE{

    event setPriceTo(address _assetAddress, uint256 _assetPrice);

    mapping(address => uint256) private _price100;

    function getPrice(address _assetAddress) public view returns(uint256){
        return _price100[_assetAddress];
    }

    function setPrice(address _assetAddress, uint256 _assetPrice) public returns(uint256){

        _price100[_assetAddress] = _assetPrice;
        emit setPriceTo(_assetAddress, _assetPrice);

        return _assetPrice;
    }
}