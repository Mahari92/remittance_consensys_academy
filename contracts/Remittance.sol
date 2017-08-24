pragma solidity ^0.4.6;

contract Wallet{
    event LogMoneyAdded(address account, uint amount);
    event LogWithdraw(address account, uint amount);
    
    mapping(address=>uint) public balances;
    
    function withdraw()
    public
    returns(bool success){
        require(balances[msg.sender]>0);
        uint amount =  balances[msg.sender];
        balances[msg.sender]=0;
        msg.sender.transfer(amount);
        LogWithdraw(msg.sender, amount);
        return true;
    }
    
    function addMoney(address account, uint amount)
    internal{
        balances[account] += amount;
        LogMoneyAdded(account,amount);
    }
}


contract Remittance is Wallet {
    address public owner;
    uint public fee;
    
    event LogChallenge(uint amount,bytes32 doubleHash,uint deadline);
    event LogSolved(uint amount,bytes32 doubleHash,address beneficiary);
    event LogRefund(address creator);
    
    struct Challenge{
        uint amount;
        bytes32 doubleHash;
        uint deadline;
    }
    
    mapping(address=>Challenge) public challenges;
    
    function Remittance(){
        owner = msg.sender;
        fee = 300000 * 4000000 ; //Fee in wei (smaller than deploy cost) (gas*gasPrice)
    }
    
    function registerChallenge(bytes32 doubleHash,uint duration)
    public
    payable
    returns(bool success){
        require(msg.value>fee);
        
        require(duration<(7 days/15)&&duration>(1 days/15)); //Duration must be between 1 day and 1 week
        require(challenges[msg.sender].deadline<block.number); //the last challenge must have passed or never happened (uint starts at zero)
        challenges[msg.sender].amount = msg.value-fee;
        challenges[msg.sender].doubleHash = doubleHash;
        challenges[msg.sender].deadline = block.number+duration;
        addMoney(owner,fee);
        LogChallenge(challenges[msg.sender].amount, doubleHash, challenges[msg.sender].deadline);
        return true;
    }
    
    function solveChallenge(bytes32 hash1,bytes32 hash2,address creator)
    public 
    returns(bool success){
        require(challenges[creator].deadline>block.number);
        bytes32 doubleHash = keccak256(hash1,hash2);
        require(challenges[creator].doubleHash == doubleHash); //Solved!
        challenges[creator].deadline = 0; //reset the deadline so another challenge can be made
        challenges[creator].amount = 0; //reset the amount to prevent double expend
        addMoney(msg.sender,challenges[creator].amount);
        LogSolved(challenges[creator].amount, doubleHash,msg.sender);
        return true;
    }
    
    function hashIt(bytes32[] data)
    public
    constant
    returns(bytes32 hash){
        return  keccak256(data);
    }
    
    function refund()
    public
    returns(bool success){
        require(challenges[msg.sender].deadline<=block.number);
        require(challenges[msg.sender].amount>0);
        challenges[msg.sender].amount = 0;
        challenges[msg.sender].deadline = 0;
        addMoney(msg.sender,challenges[msg.sender].amount);
        LogRefund(msg.sender);
        return true;
    }
    
    
    function kill()
    public{
        require(msg.sender == owner);
        suicide(owner);
    }
    
}












