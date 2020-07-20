pragma solidity ^0.5.0;

contract MultiSigWallet {
    address private owner;
    mapping(address => uint8) private owners;
    
    uint constant MIN_SIGNATURES = 2;
    uint private transactionIdx;
    
    struct Transaction {
        address from;
        address payable to;
        uint amount;
        uint8 signatureCount;
        mapping(address => uint8) signatures;
    }
    mapping (uint => Transaction) private transations;
    uint[] private pendingTransactions;
    
    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }
    modifier validOwner() {
        require(msg.sender == owner || owners[msg.sender] == 1);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    event DepositFunds(address _from, uint _amount );
    event TransactionCreated(address _from, address _to, uint _amount, uint _transactionId);
    event TransactionCompleted(address _from, address _to, uint _amount, uint _transactionId);
    event TransactionSigned(address _by, uint _transactionIdx);
    
    function addOwner(address _newOwner) isOwner public {
        owners[_newOwner] = 1;
    }
    function removeOwner (address _existingOwner) isOwner public {
        owners[_existingOwner] = 0;
    }
    function deposit() isOwner public payable {
        emit DepositFunds(msg.sender,msg.value);
    }
    function withdraw (uint _amount) public {
        require(address(this).balance >= _amount);
        transferTo(msg.sender,_amount);
    }
    function transferTo(address payable _to, uint _amount) validOwner public {
        require(address(this).balance >= _amount);
        uint transactionId = transactionIdx + 1;
        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = _to;
        transaction.amount = _amount;
        transaction.signatureCount = 0;
        
        transations[transactionId] = transaction;
        pendingTransactions.push(transactionId);
        
        emit TransactionCreated(msg.sender, _to, _amount, transactionId);
    }
    
    function getPendingTransactions() view validOwner public returns (uint[] memory) {
        return pendingTransactions;
    }
    
    function signTransaction(uint _transactionId) validOwner public payable{
        Transaction storage transaction = transations[_transactionId];
        require(address(0) != transaction.from);   //transaction must exist
        require(msg.sender != transaction.from);    //creater cannot sign the transaction
        require(transaction.signatures[msg.sender] != 1);   //cannot sign a transaction more than once
        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount +=1;
        emit TransactionSigned(msg.sender, _transactionId);
        
        if (transaction.signatureCount >= MIN_SIGNATURES) {
            require(address(this).balance >= transaction.amount);
            transaction.to.transfer(transaction.amount);
            emit TransactionCompleted(transaction.from, transaction.to, transaction.amount, _transactionId);
        }
        
    }
    function deleteTransaction (uint _transactionId) validOwner public {
        uint8 replace = 0;
        for (uint i=0 ; i< pendingTransactions.length; i++) {
            if (1 == replace) {
                pendingTransactions[i-1] = pendingTransactions [i];
            }
            else if(_transactionId == pendingTransactions[i]) {
                replace =1;
            }
        }
        delete pendingTransactions[pendingTransactions.length -1 ];
        pendingTransactions.length -=1 ;
        delete transations[_transactionId];
    }
    function walletBalance() public returns(uint) {
        return address(this).balance;
        
    }
    
}