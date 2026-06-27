pragma solidity ^0.8.35;
// TODO AUDIT - i changed the versioning here, this was copied and stripped from the Optimism WETH9 contract
//      https://optimistic.etherscan.io/token/0x4200000000000000000000000000000000000006#code

interface IWETH9 {
//    string name;
//    string symbol;
//    uint8  decimals;

//TODO remove after validating the replacements function the same (both name,symbol,decimals and balanceOf and allowance)
//    mapping (address => uint) public                        balanceOf;
//    mapping (address => mapping (address => uint))    allowance;

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns(uint);    //TODO audit make sure both of these functions can be accessed
    function allowance(address, address) external view returns(uint); 

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad) external returns (bool);
}
