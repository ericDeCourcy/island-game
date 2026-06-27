pragma solidity ^0.8.35;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./IWETH9.sol";


// Treasury should only recieve weth
contract Treasury is OwnableUpgradeable {

    // TODO initializers and constructors
    IWETH9 weth;    

    // @dev Needed to prevent the implementation from getting initialized
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        weth =  IWETH9(0x4200000000000000000000000000000000000006); //This is the WETH address on Optimism
    }


    //* @dev amount == 0 codes for full withdrawal
    function claimFunds(uint amount, address recipient) onlyOwner public
    {
        // if amount is not set, its a full withdrawal
        if(amount == 0) {
            amount = weth.balanceOf(address(this));
        }
        require(recipient != address(0), "Treasury: Recipient is zero address");    //This prevents footguns - calling this func with no args and sending funds to the void
        require(weth.balanceOf(address(this)) >= amount, "Treasury: claim amount is too high");

        weth.transfer(recipient, amount);
    }
}