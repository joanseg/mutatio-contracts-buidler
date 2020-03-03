pragma solidity ^0.5.0;

//Import token contract
import "./JALToken.sol";

//Change contract name to Mutatio

contract Mutatio {
    // address public manager;
    // address payable players;
    address payable public owner = msg.sender; //Define a public owner variable. Set it to the creator of the contract when it is initialized.

    uint public orderId;

    struct Order {
        uint depositAmount;
        address buyerAddress;
        address targetToken;
        uint amountToken;
        address payable exchangeAddress;
        bool exchangeStarted;
    }

    mapping (uint => Order) orders;

    event LogExchangeEth(
        uint orderId,
        uint depositAmount,
        address buyerAddress,
        address targetToken,
        uint amountToken,
        bool exchangeStarted
    );

    modifier isNotStarted(uint _orderId) {
        require(orders[_orderId].exchangeStarted =! true, "Nos started");
        _;
    }
    modifier isAnExchange() {
        require(msg.sender == exchange, "Is not an exchange");
        _;
    }
    modifier isTheRequiredAmount(uint _orderId, uint finalAmount) {
        require(orders[_orderId].amountToken * 499 / 500 <= finalAmount, "Invalid amounts"); //we should be able to check the token contract
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Is not the owner");
        _;
    }

    address exchange;
    address token;

    constructor(address _exchange, address _token) public {
        exchange = _exchange;
        token = _token;
    }

    function exchangeEth(address _tokenAddress, uint _amountToken)
        public
        payable
        returns(uint)
    {
        Order memory thisOrder;
        thisOrder.depositAmount = msg.value;
        thisOrder.buyerAddress = msg.sender;
        thisOrder.targetToken = _tokenAddress;
        thisOrder.amountToken = _amountToken;
        thisOrder.exchangeStarted = false;
        orderId = orderId + 1;
        orders[orderId] = thisOrder;
        emit LogExchangeEth(orderId, msg.value, msg.sender, _tokenAddress, _amountToken, false);
        return  orderId;
    }

    function exchangeStarted(uint orderId)
        public
        // isNotStarted(orderId)
        isAnExchange()
        returns(bool, address)
    {
        orders[orderId].exchangeStarted = true;
        orders[orderId].exchangeAddress = msg.sender;
        return (orders[orderId].exchangeStarted, orders[orderId].exchangeAddress);
    }

    function readOrder(uint orderId)
        public
        returns(
            uint depositAmount,
            address buyerAddress,
            address targetToken,
            uint amountToken,
            address exchangeAddress,
            bool exchangeStarted
        )
    {
        depositAmount = orders[orderId].depositAmount;
        buyerAddress = orders[orderId].buyerAddress;
        targetToken = orders[orderId].targetToken;
        amountToken = orders[orderId].amountToken;
        exchangeAddress = orders[orderId].exchangeAddress;
        exchangeStarted = orders[orderId].exchangeStarted;
        return(depositAmount, buyerAddress, targetToken, amountToken, exchangeAddress, exchangeStarted);
    }

    function exchangeCompleted(uint orderId, uint256 finalAmount)
        public
        payable
        isAnExchange()
        isTheRequiredAmount(orderId, finalAmount)
        returns(bool)
        // isNotUsedBefore() // the tansaction should not be alredy been used
    {
        // Botyo needs to approve this contract to tranfer from ERC20(tracker_0x_address).approve(address spender, uint tokens)
        // tracker_0x_address is the address of the ERC20 contract they want to deposit tokens from ( ContractA )
        // spender is your deployed escrow contract address
        require(JALToken(token).transferFrom(msg.sender, orders[orderId].buyerAddress, finalAmount), "Can't transfer");
        // it should mark the order as completed orderCompleted = true
        // reedemDeposit(orderId);
        return true;
    }

    // function reedemDeposit(uint orderId)
    //     public
    //     payable
    //     onlyOwner()
    // {
    //     require(orders[orderId].exchangeAddress.transfer(orders[orderId].depositAmount));
    // }


}