pragma solidity ^0.5.0;

//Import token contract
import "./JALToken.sol";


contract Mutatio {
    // address public manager;
    // address payable players;
    address public owner = msg.sender; //Define a public owner variable. Set it to the creator of the contract when it is initialized.

    uint public orderId;

    struct Order {
        uint256 ethSold;
        address tokenAddress;
        uint256 minTokens;
        uint256 deadline;
        address buyer;
        address recipient;
        bool completed;
        // address payable exchangeAddress;
        // bool exchangeStarted;
    }

    mapping (uint => Order) orders;

    event LogEthToTokenSwapInput(
        uint orderId,
        uint256 ethSold,
        address tokenAddress,
        uint256 minTokens,
        uint256 deadline,
        address buyer,
        address recipient,
        bool completed
    );
    event LogEthToTokenSwapInputEscrowCompleted(
        uint orderId,
        bool completed
    );


    // modifier isNotStarted(uint _orderId) {
    //     require(orders[_orderId].exchangeStarted =! true, "Nos started");
    //     _;
    // }
    modifier isAnExchange() {
        require(msg.sender == exchange, "Is not an exchange");
        _;
    }
    modifier isTheRequiredAmount(uint _orderId, uint actualTokens) {
        require(orders[_orderId].minTokens <= actualTokens, "Invalid amounts"); //we should be able to check the token contract
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Is not the owner");
        _;
    }
    modifier isNotCompleted(uint _orderId) {
        require(orders[_orderId].completed == false, "Order might be completed");
        _;
    }

    address payable exchange;
    address tokenAddress;

    constructor(address payable _exchange, address _token) public {
        exchange = _exchange;
        tokenAddress = _token;
    }

    function ethToTokenSwapInput(address tokenAddress, uint256 minTokens, uint256 deadline)
        public
        payable
        // isSupportedToken(tokenAddress) //token needs to be supported
        returns(uint)
    {
        Order memory thisOrder;
        thisOrder.ethSold = msg.value;
        thisOrder.tokenAddress = tokenAddress;
        thisOrder.minTokens = minTokens;
        thisOrder.deadline = deadline;
        thisOrder.buyer = msg.sender;
        thisOrder.recipient = msg.sender;
        thisOrder.completed = false;
        // thisOrder.exchangeStarted = false;
        orderId = orderId + 1;
        orders[orderId] = thisOrder;
        emit LogEthToTokenSwapInput(orderId, msg.value, tokenAddress, minTokens, deadline, msg.sender, msg.sender, false);
        return orderId;
    }

    // function ethToTokenSwapInput(address tokenAddress, uint minTokens, uint256 deadline)
    //     public
    //     payable
    //     returns(bool)
    // {
    //     require(this.ethToTokenSwapLog(msg.value, tokenAddress, minTokens, deadline, msg.sender, msg.sender),"Can't run ethToTokenSwap()");
    //     return true;
    // }

    // function exchangeStarted(uint orderId)
    //     public
    //     // isNotStarted(orderId)
    //     isAnExchange()
    //     returns(bool, address)
    // {
    //     orders[orderId].exchangeStarted = true;
    //     orders[orderId].exchangeAddress = msg.sender;
    //     return (orders[orderId].exchangeStarted, orders[orderId].exchangeAddress);
    // }

    function readOrder(uint orderId)
        public
        returns(
            uint256 ethSold,
            address tokenAddress,
            uint256 minTokens,
            uint256 deadline,
            address buyer,
            address recipient,
            bool completed
        )
    {
        ethSold = orders[orderId].ethSold;
        tokenAddress = orders[orderId].tokenAddress;
        minTokens = orders[orderId].minTokens;
        deadline = orders[orderId].deadline;
        buyer = orders[orderId].buyer;
        recipient = orders[orderId].recipient;
        completed = orders[orderId].completed;
        // exchangeAddress = orders[orderId].exchangeAddress;
        // exchangeStarted = orders[orderId].exchangeStarted;
        return(ethSold, tokenAddress, minTokens, deadline, buyer, recipient, completed);
    }

    function ethToTokenSwapInputExchangeCompleted(uint orderId, uint256 actualTokens)
        public
        payable
        isAnExchange()
        isNotCompleted(orderId)
        isTheRequiredAmount(orderId, actualTokens)
        returns(bool)
        // isNotUsedBefore() // the tansaction should not be alredy been used
    {
        require(JALToken(tokenAddress).transferFrom(msg.sender, orders[orderId].buyer, actualTokens), "Can't transfer");
        // it should mark the order as completed orderCompleted = true
        ethToTokenSwapInputEscrowCompleted(orderId);
        return true;
    }

    function ethToTokenSwapInputEscrowCompleted(uint orderId)
        public
        payable
        returns(uint)
    {
        exchange.transfer(orders[orderId].ethSold);
        orders[orderId].completed = true;
        emit LogEthToTokenSwapInputEscrowCompleted(orderId, true);
        return orderId;
    }
}