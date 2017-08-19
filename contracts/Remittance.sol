pragma solidity ^0.4.6;


contract Remittance {
    address public owner;
    uint public fee;
    
    event LogChallenge(uint amount,bytes32 doubleHash1,bytes32 doubleHash2,uint deadline);
    event LogSolved(uint amount,bytes32 doubleHash1,bytes32 doubleHash2,address beneficiary);
    event LogRefund(address creator);
    
    struct Challenge{
        uint amount;
        bytes32 doubleHash1;
        bytes32 doubleHash2;
        uint deadline;
    }
    
    mapping(address=>Challenge) public challenges;
    
    function Remittance(){
        owner = msg.sender;
        fee = 300000 * 4000000 ; //Fee in wei (smaller than deploy cost) (gas*gasPrice)
    }
    
    function registerChallenge(bytes32 doubleHash1,bytes32 doubleHash2,uint duration)
    public
    payable
    returns(bool success){
        require(msg.value>fee);
        require(duration<40320&&duration>5760); //Duration must be between 1 day and 1 week
        require(challenges[msg.sender].deadline<block.number); //the last challenge must have passed or never happened (uint starts at zero)
        challenges[msg.sender].amount = msg.value-fee;
        challenges[msg.sender].doubleHash1 = doubleHash1;
        challenges[msg.sender].doubleHash2 = doubleHash2;
        challenges[msg.sender].deadline = block.number+duration;
        LogChallenge(challenges[msg.sender].amount, doubleHash1, doubleHash2, challenges[msg.sender].deadline);
        return true;
    }
    
    function solveChallenge(bytes32 hash1,bytes32 hash2,address creator)
    public 
    returns(bool success){
        require(challenges[creator].deadline>block.number);
        bytes32 doubleHash1 = keccak256(hash1);
        bytes32 doubleHash2 = keccak256(hash2);
        require(challenges[creator].doubleHash1 == doubleHash1);
        require(challenges[creator].doubleHash2 == doubleHash2); //Solved!
        msg.sender.transfer(challenges[creator].amount);
        challenges[creator].deadline = 0; //reset the deadline so another challenge can be made
        challenges[creator].amount = 0; //reset the amount to prevent double expend
        LogSolved(challenges[creator].amount, doubleHash1, doubleHash2,msg.sender);
        return true;
    }
    
    function hashIt(bytes32 data)
    public
    constant
    returns(bytes32 hash){
        return  keccak256(data);
    }
    
    function refund()
    public
    returns(bool success){
        require(challenges[msg.sender].deadline<block.number);
        require(challenges[msg.sender].amount>0);
        msg.sender.transfer(challenges[msg.sender].amount);
        LogRefund(msg.sender);
        return true;
    }
    
    
    function kill()
    public{
        require(msg.sender == owner);
        suicide(owner);
    }
    
}












