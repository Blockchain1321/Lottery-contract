// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract gambling is VRFConsumerBase{

    address public manager;
    mapping (address => uint) public stakes;
    mapping(uint => address) public stakersData;
    mapping(uint => bool) public soldDetail;
    uint private PurchaseAmount = 1000;  
    uint private raisedAmount;

    bytes32 internal keyHash; 
    uint internal fee; 
    uint public randomResult;
    address vrfcoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B;
    address linkToken = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    uint ticket;

    using SafeMath for uint;

    uint startDate;
    uint endDate;

    constructor()VRFConsumerBase(
            vrfcoordinator, // vrfcoordinator is address of smart contract that verifies the randomness of number returned smart contract.
            linkToken
            ) {
            keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
            fee = 0.1 * 10 ** 18;
            manager = msg.sender;
        }


    modifier onlyManger{
        require(manager == msg.sender,"Only authorize manager access it");
        _;
    }
    modifier conditionstoPurchase(uint _ticketId){
        require(PurchaseAmount == msg.value,"Require particular amount");
        require(soldDetail[_ticketId]==false,"already sold");
        require(block.timestamp > startDate,"not started yet");
        require(block.timestamp < endDate,"sesssion ended");
        _;
    }

    function session(uint _sDate,uint _eDate) external onlyManger{
        startDate = _sDate;
        endDate = _eDate;
    }

    function stakeTokens(uint _ticketId) external payable conditionstoPurchase(_ticketId){
        stakes[msg.sender] = stakes[msg.sender] + msg.value;
        stakersData[_ticketId]=msg.sender;
        soldDetail[_ticketId] = true;
        raisedAmount += msg.value;
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
        return requestRandomness(keyHash, fee);
    }

     function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        randomResult = randomness.mod(100).add(1);
        payWinner();

    }

    function pickWinner() public  onlyManger {
        require(block.timestamp > endDate);
        getRandomNumber();
    }

    function payWinner() public {
        if (stakersData[randomResult] == address(0)){
            payable(manager).transfer(raisedAmount);        }
        else{
            payable(stakersData[randomResult]).transfer(raisedAmount);

        }
    }

     function getBalance(address add) public view returns(uint){
        return add.balance;
    }
    

}
