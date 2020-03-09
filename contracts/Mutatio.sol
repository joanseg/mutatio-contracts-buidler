pragma solidity ^0.5.0;

//Import token contract https://ethereum.stackexchange.com/questions/70155/how-to-interact-with-erc20-interface
// https://www.reddit.com/r/ethdev/comments/73mzjr/how_do_you_interact_with_any_erc20_in_a_smart/
import "./JALToken.sol";


contract ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Mutatio {
    // address public manager;
    // address payable players;
    address public owner = msg.sender; //Define a public owner variable. Set it to the creator of the contract when it is initialized.

    uint public orderId;

    mapping(address => bool) public tokens;

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
    modifier isSupportedToken(address _tokenAddress) {
        require(tokens[_tokenAddress] == true, "The token is not supported");
        _;
    }

    address payable exchange;
    address tokenAddress;

    constructor(address payable _exchange, address _token) public {
        exchange = _exchange;
        tokenAddress = _token;
        tokens[_token] = true;
    }

    function addSupportedToken(address _newToken)
        public
        onlyOwner()
        returns(address newToken)
    {
        tokens[_newToken] = true;
        return _newToken;
    }

    function ethToTokenSwapInput(address tokenAddress, uint256 minTokens, uint256 deadline)
        public
        payable
        isSupportedToken(tokenAddress)
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
        require(ERC20(tokenAddress).transferFrom(msg.sender, orders[orderId].buyer, actualTokens), "Can't transfer");
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