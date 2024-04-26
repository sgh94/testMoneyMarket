// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {STORAGE} from "./Storage.sol";
import {LibString} from "./utils/LibStrings.sol";

struct PositionInfo{
    address collateralAssetAddress;
    uint256 collateralAssetAmount;

    address borrowAssetAddress;
    uint256 borrowAssetAmount;
}

using LibString for uint256;

contract MARKET is ERC20{

    mapping(address => PositionInfo) private _position;
    mapping(address => uint256) private _liquidationBalance;
    
    // storage for collrateral
    STORAGE storageC = STORAGE(0x6E821CB51fa7a81c213452b1DFc9d7f211C13C08);
    // storage for deposit
    STORAGE storageD = STORAGE(0x6E821CB51fa7a81c213452b1DFc9d7f211C13C08);

    address private _depositTokenAddress;
    mapping(address => uint256) private _depositBalance;
    function getDepositBalance(address _target) public view returns(uint256) {require(_target != address(0)); return _depositBalance[_target];}
    ERC20 private _depositToken; 

    address private _owner;
    uint256 public expirationDate;
    uint256 private _ratePer1000 = 10;

    uint256 private _LTV = 90;

    modifier onlyOwner{
        msg.sender == _owner;
        _;
    }

    event depositTo(address indexed _to, uint256 _amount);
    event withdrawalTo(address indexed _to, uint256 _amount);
    event borrowTo(address indexed _to, address _asset, uint256 _amount);
    event positionUpdate(address indexed _to, 
        address collateralAssetAddress, 
        uint256 collateralAssetAmount,
        address borrowAssetAddress,
        uint256 borrowAssetAmount);
    event repaymentFrom(address _from, address _borrowAssetAddress, uint256 _borrowAssetAmount);
    event liquidationUpdate(address indexed _target, address indexed liquidationAssetAddress, uint256 liquidationAssetAmount);

    constructor(string memory name_, string memory symbol_, address depositTokenAddress_, uint256 expirationDate_) ERC20(name_, symbol_){
        require(depositTokenAddress_ != address(0), "don't submit address 0");

        _depositTokenAddress = depositTokenAddress_;
        _depositToken = ERC20(depositTokenAddress_);

        expirationDate = expirationDate_;
        _owner = msg.sender;
    
    }

    function getDepositToken() public view returns(address){
        return _depositTokenAddress;
    }

    // function _mint(address account, uint256 value) internal
    // event depositTo(indexed address _to, uint256 _amount);
    function deposit(uint256 _amount) public{
        require(_amount > 0, "amount <= 0");
        require(block.timestamp < expirationDate, "the expiration date has passed.");

        _depositToken.transferFrom(msg.sender, address(this), _amount);
        _depositBalance[msg.sender] += _amount;

        uint256 _sAmount = _amount * (1 + ((expirationDate - block.timestamp) / 1000 * _ratePer1000) );
        _mint(msg.sender, _sAmount);

        emit depositTo(msg.sender, _amount);
    }

    // function _approveERC20AmountTo(address _token, address _to, uint256 _amount) private{
    //     ERC20(_token).approve(_to, _amount);
    // }


    // event withdrawalTo(indexed address _to, uint256 _amount);
    function withdrawal(uint256 _amount) public{
        require(block.timestamp >= expirationDate, "withdrawals are only possible after the expiry date.");
        require(_amount > 0, "amount <= 0");
        require(_depositToken.balanceOf(address(this)) >= _amount, "The loan repayment is insufficient. Please utilize an auction.");
        require(_depositBalance[msg.sender] >= _amount);
        
        transferFrom(msg.sender, address(this), _amount);
        _depositToken.transfer(msg.sender, _amount);
        _depositBalance[msg.sender] -= _amount;

        emit withdrawalTo(msg.sender, _amount);
    }

    // event borrowTo(indexed address _to, address _asset, uint256 _amount);
    function borrow(address _collateralAssetAddress, uint256 _collateralAssetAmount, address _borrowAssetAddress, uint256 _borrowAssetAmount) public{

        _positionIncrease(msg.sender, _collateralAssetAddress, _collateralAssetAmount, _borrowAssetAddress, _borrowAssetAmount);

        _checkPositionWithLTV(msg.sender, _LTV);
        require(_borrowAssetAmount <= ERC20(_borrowAssetAddress).balanceOf(address(this)), "Insufficient asset for borrowing" );

        ERC20(_collateralAssetAddress).transferFrom(msg.sender, address(this), _collateralAssetAmount);

        // _approveERC20AmountTo(_depositTokenAddress, address(this), _borrowAssetAmount);
        ERC20(_borrowAssetAddress).transfer(msg.sender, _borrowAssetAmount);

        emit borrowTo(msg.sender, _borrowAssetAddress, _borrowAssetAmount);

    }

    function repayment(address _collateralAssetAddress, uint256 _collateralAssetAmount, address _borrowAssetAddress, uint256 _borrowAssetAmount) public{
        
        _positionDecrease(msg.sender, _collateralAssetAddress, _collateralAssetAmount, _borrowAssetAddress, _borrowAssetAmount);

        _checkPositionWithLTV(msg.sender, _LTV);
        require(_borrowAssetAmount <= ERC20(_borrowAssetAddress).balanceOf(address(this)), "Insufficient asset for borrowing" );

        // _approveERC20AmountTo(_collateralAssetAddress, address(this), _collateralAssetAmount);
        ERC20(_collateralAssetAddress).transfer(msg.sender, _collateralAssetAmount);

        ERC20(_borrowAssetAddress).transferFrom(msg.sender, address(this), _borrowAssetAmount);

        emit repaymentFrom(msg.sender, _borrowAssetAddress, _borrowAssetAmount);

    }

    function _positionIncrease(address _to, address _collateralAssetAddress, uint256 _collateralAssetAmount, address _borrowAssetAddress, uint256 _borrowAssetAmount) private{

        require(_collateralAssetAmount > 0 && _borrowAssetAmount > 0);
        require(_position[_to].collateralAssetAmount == 0 ||  _position[_to].collateralAssetAddress == address(0) || _position[_to].collateralAssetAddress == _collateralAssetAddress);
        require(_position[_to].borrowAssetAmount == 0 || _position[_to].borrowAssetAddress == address(0) || _position[_to].borrowAssetAddress == _borrowAssetAddress);

        _position[_to].collateralAssetAddress = _collateralAssetAddress;
        _position[_to].collateralAssetAmount += _collateralAssetAmount;

        _position[_to].borrowAssetAddress = _borrowAssetAddress;
        _position[_to].borrowAssetAmount += _borrowAssetAmount;

        emit positionUpdate(_to, 
        _position[_to].collateralAssetAddress, 
        _position[_to].collateralAssetAmount,
        _position[_to].borrowAssetAddress,
        _position[_to].borrowAssetAmount);
    }

    function _positionDecrease(address _to, address _collateralAssetAddress, uint256 _collateralAssetAmount, address _borrowAssetAddress, uint256 _borrowAssetAmount) private{

        require(_collateralAssetAmount > 0 && _borrowAssetAmount > 0);
        require(_position[_to].collateralAssetAmount == 0 ||  _position[_to].collateralAssetAddress == address(0) || _position[_to].collateralAssetAddress == _collateralAssetAddress);
        require(_position[_to].borrowAssetAmount == 0 || _position[_to].borrowAssetAddress == address(0) || _position[_to].borrowAssetAddress == _borrowAssetAddress);

        _position[_to].collateralAssetAddress = _collateralAssetAddress;
        _position[_to].collateralAssetAmount = _minus(_position[_to].collateralAssetAmount, _collateralAssetAmount);
        if(_position[_to].collateralAssetAmount == 0){
            _position[_to].collateralAssetAddress = address(0);
        }

        _position[_to].borrowAssetAddress = _borrowAssetAddress;
        _position[_to].borrowAssetAmount = _minus(_position[_to].borrowAssetAmount, _borrowAssetAmount);
        if(_position[_to].borrowAssetAmount == 0){
            _position[_to].borrowAssetAddress = address(0);
        }

        emit positionUpdate(_to, 
        _position[_to].collateralAssetAddress, 
        _position[_to].collateralAssetAmount,
        _position[_to].borrowAssetAddress,
        _position[_to].borrowAssetAmount);
    }

    // 1. set target's collateral to 0
    function tryLiquidation(address _target) public {

        _checkLiquidationTo(_target, _LTV);

        _liquidationBalance[_position[_target].collateralAssetAddress] += _position[_target].collateralAssetAmount;
        emit liquidationUpdate(_target, _position[_target].collateralAssetAddress, _position[_target].collateralAssetAmount);

        _positionDecrease(_target, _position[_target].collateralAssetAddress, _position[_target].collateralAssetAmount, _position[_target].borrowAssetAddress, _position[_target].borrowAssetAmount);
    }

    // Liquidated Asset hold a value equal to 0.95 times the value of the asset in the market
    function buyLiquidationAsset(address _sellAssetAddress, uint256 _sellAssetAmount, address _buyAssetAddress, uint256 _buyAssetAmount) public {
        
        require(_sellAssetAmount > 0);
        require(_buyAssetAmount > 0);
        require(_buyAssetAmount <= _liquidationBalance[_buyAssetAddress], "lack of liquidation asset amount");
        
        uint256 _sellValue = _sellAssetAmount * storageD.getPrice(_sellAssetAddress);
        uint256 _buyValue = _buyAssetAmount * storageC.getPrice(_buyAssetAddress) * 19 / 20;
        
        require(_sellValue > _buyValue, "lack of value or not avaliable asset");

        _liquidationBalance[_buyAssetAddress] = _minus(_liquidationBalance[_buyAssetAddress], _buyAssetAmount);
        ERC20(_sellAssetAddress).transferFrom(msg.sender, address(this), _sellAssetAmount);

        ERC20(_buyAssetAddress).transfer(msg.sender, _buyAssetAmount);

    }

    function _minus(uint256 a, uint256 b) private pure returns(uint256) {
        require(a >= b);
        return a - b;
    }

    function _checkLiquidationTo(address _target, uint256 _LTV100) private {

        uint256 _collateralAssetPrice = storageC.getPrice(_position[_target].collateralAssetAddress);
        uint256 _borrowAssetPrice = storageC.getPrice(_position[_target].borrowAssetAddress);

        uint256 _collateralValue = _position[_target].collateralAssetAmount * _collateralAssetPrice;
        uint256 _borrowValue = _position[_target].borrowAssetAmount * _borrowAssetPrice;

        //string(abi.encodePacked("Value must be greater than 0, provided: ", uint2str(x)))
        require(_collateralValue * _LTV100 / 100 < _borrowValue, string(abi.encodePacked("Sufficient Collateral", " CollateralValue : ", _collateralValue.toString(), " BorrowValue : ", _borrowValue.toString())) );
    }

    function _checkPositionWithLTV(address _target, uint256 _LTV100) private view {

        uint256 _collateralAssetPrice = storageC.getPrice(_position[_target].collateralAssetAddress);
        uint256 _borrowAssetPrice = storageC.getPrice(_position[_target].borrowAssetAddress);

        uint256 _collateralValue = _position[_target].collateralAssetAmount * _collateralAssetPrice;
        uint256 _borrowValue = _position[_target].borrowAssetAmount * _borrowAssetPrice;

        //string(abi.encodePacked("Value must be greater than 0, provided: ", uint2str(x)))
        require(_collateralValue * _LTV100 / 100 > _borrowValue, string(abi.encodePacked("Insufficient Collateral", " CollateralValue : ", _collateralValue.toString(), " BorrowValue : ", _borrowValue.toString())) );
    }
}