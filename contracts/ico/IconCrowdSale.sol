pragma solidity ^0.4.11;

import "../token/erc20.sol";
import "../util/SafeMath.sol";

contract IconCrowdSale {
    using SafeMath for uint;
    ERC20 public icxToken;
    Stages stage;
    address public wallet;
    address public owner;
    address public tokenOwner;
    uint public ceiling;
    uint public priceFactor; // ratio
    uint public startBlock;
    uint public totalReceived;
    uint public endTime;

    uint public maxValue; // max ETH
    uint public minValue;

    // collect log
    event FundTransfer (address sender, uint amount);

    struct ExistAccount {
        bool exists; // set to true
        address account; // sending account
        uint amount; // sending amount
        uint balance; // token value
        bytes data; // sending data
    }

    mapping(address => ExistAccount) public _saleValue;
    mapping(bytes => ExistAccount) _saleData;

    /*
        Check is owner address
    */
    modifier isOwner() {
        // Only owner is allowed to proceed
        require (msg.sender == owner);
        _;
    }

    /**
        Check Valid Payload
    */
    modifier isValidPayload() {
        // max
        if(maxValue != 0)
            require(msg.value < maxValue + 1); // check Max
        if(minValue != 0)
            require(msg.value > minValue - 1);
        require(wallet != msg.sender);
        // check data value
        require(msg.data.length != 0);
        _;

    }

    /*
        Check exists sale list
    */
    modifier isExists() {
        require(_saleData[msg.data].exists == false);
        require(_saleValue[msg.sender].amount == 0);
        _;
    }

    /*
     *  Modifiers
     */
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    /*
     *  Enums
     */
    enum Stages {
    SaleDeployed,
    SaleSetUp,
    SaleStarted,
    SaleEnded
    }


    /// init
    /// @param _token token address
    /// @param _tokenOwner token owner wallet address
    /// @param _wallet sale ETH wallet
    /// @param _ceiling sale token total value
    /// @param _priceFactor token and ETH ratio
    /// @param _maxValue maximum ETH balance
    /// @param _minValue minimum ETH balance

    function IconCrowdSale(address _token, address _tokenOwner, address _wallet, uint _ceiling, uint _priceFactor, uint _maxValue, uint _minValue)
    public
    {
        require (_tokenOwner != 0 && _wallet != 0 && _ceiling != 0 && _priceFactor != 0);
        tokenOwner = _tokenOwner;
        owner = msg.sender;
        wallet = _wallet;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        maxValue = _maxValue;
        minValue = _minValue;
        stage = Stages.SaleDeployed;

        if(_token != 0){ // setup token
            icxToken = ERC20(_token);
            stage = Stages.SaleSetUp;
        }
    }

    // setupToken
    function setupToken(address _token) isOwner {
        require(_token != 0);
        icxToken = ERC20(_token);
        stage = Stages.SaleSetUp;
    }

    /// @dev Start Sale
    function startSale()
    public
    isOwner
    atStage(Stages.SaleSetUp)
    {
        stage = Stages.SaleStarted;
        startBlock = block.number;
    }


    /* The function without name is the default function that is called whenever anyone sends funds to a contract */
    function()
    isValidPayload
    isExists
    atStage(Stages.SaleStarted)
    payable
    {
        uint amount = msg.value;
        uint maxAmount = ceiling.div(priceFactor);
        // refund
        if (amount > maxAmount){
            uint refund = amount.sub(maxAmount);
            assert(msg.sender.send(refund));
            amount = maxAmount;
        }
        totalReceived = totalReceived.add(amount);
        // calculate token
        uint token = amount.mul(priceFactor);
        ceiling = ceiling.sub(token);

        // give token to sender
        icxToken.transferFrom(tokenOwner, msg.sender, token);
        FundTransfer(msg.sender, token);

        ExistAccount crowdData = _saleValue[msg.sender];
        crowdData.exists = true;
        crowdData.account = msg.sender;
        crowdData.data = msg.data;
        crowdData.amount = amount;
        crowdData.balance = token;
        // add SaleData
        _saleData[msg.data] = crowdData;
        _saleValue[msg.sender] = crowdData;
        // send to wallet
        wallet.transfer(amount);

        // token sold out
        if (amount == maxAmount)
            finalizeSale();
    }

    /// @dev Changes auction ceiling and start price factor before auction is started.
    /// @param _ceiling Updated auction ceiling.
    /// @param _priceFactor Updated start price factor.
    /// @param _maxValue Maximum balance of ETH
    /// @param _minValue Minimum balance of ETH
    function changeSettings(uint _ceiling, uint _priceFactor, uint _maxValue, uint _minValue)
    public
    isOwner
    {
        require(_ceiling != 0 && _priceFactor != 0);
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        maxValue = _maxValue;
        minValue = _minValue;
    }

    // token balance
    // @param src sender wallet address
    function balanceOf(address src) constant returns (uint256)
    {
        return _saleValue[src].balance;
    }

    // amount ETH value
    // @param src sender wallet address
    function amountOf(address src) constant returns(uint256)
    {
        return _saleValue[src].amount;
    }

    // sale data
    // @param src ICON homepage uuid
    function saleData(bytes src) constant returns(address)
    {
        return _saleData[src].account;
    }

    // Check sale is open
    function isSaleOpen() constant returns (bool)
    {
        return stage == Stages.SaleStarted;
    }

    // CrowdSale halt
    function halt()
    isOwner
    {
        finalizeSale();
    }

    // END of this sale
    function finalizeSale()
    private
    {
        stage = Stages.SaleEnded;
        // remain token send to owner
        ceiling = 0;
        endTime = now;
    }
}
