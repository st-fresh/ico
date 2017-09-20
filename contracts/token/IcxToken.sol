pragma solidity ^0.4.11;

import "./erc20.sol";
import "./Lockable.sol";
import '../util/SafeMath.sol';

// ICON ICX Token
/// @author DongOk Ryu - <pop@theloop.co.kr>
contract IcxToken is ERC20, Lockable {
    using SafeMath for uint;

    mapping( address => uint ) _balances;
    mapping( address => mapping( address => uint ) ) _approvals;
    uint _supply;
    address public walletAddress;

    //event TokenMint(address newTokenHolder, uint amountOfTokens);
    event TokenBurned(address burnAddress, uint amountOfTokens);
    event TokenTransfer();

    modifier onlyFromWallet {
        require(msg.sender != walletAddress);
        _;
    }

    function IcxToken( uint initial_balance, address wallet) {
        require(wallet != 0);
        require(initial_balance != 0);
        _balances[msg.sender] = initial_balance;
        _supply = initial_balance;
        walletAddress = wallet;
    }

    function totalSupply() constant returns (uint supply) {
        return _supply;
    }

    function balanceOf( address who ) constant returns (uint value) {
        return _balances[who];
    }

    function allowance(address owner, address spender) constant returns (uint _allowance) {
        return _approvals[owner][spender];
    }

    function transfer( address to, uint value)
    isTokenTransfer
    checkLock
    returns (bool success) {

        require( _balances[msg.sender] >= value );

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        Transfer( msg.sender, to, value );
        return true;
    }

    function transferFrom( address from, address to, uint value)
    isTokenTransfer
    checkLock
    returns (bool success) {
        // if you don't have enough balance, throw
        require( _balances[from] >= value );
        // if you don't have approval, throw
        require( _approvals[from][msg.sender] >= value );
        // transfer and return true
        _approvals[from][msg.sender] = _approvals[from][msg.sender].sub(value);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        Transfer( from, to, value );
        return true;
    }

    function approve(address spender, uint value)
    isTokenTransfer
    checkLock
    returns (bool success) {
        _approvals[msg.sender][spender] = value;
        Approval( msg.sender, spender, value );
        return true;
    }

    // burnToken burn tokensAmount for sender balance
    function burnTokens(uint tokensAmount)
    isTokenTransfer
    external
    {
        require( _balances[msg.sender] >= tokensAmount );

        _balances[msg.sender] = _balances[msg.sender].sub(tokensAmount);
        _supply = _supply.sub(tokensAmount);
        TokenBurned(msg.sender, tokensAmount);

    }


    function enableTokenTransfer()
    external
    onlyFromWallet {
        tokenTransfer = true;
        TokenTransfer();
    }

    function disableTokenTransfer()
    external
    onlyFromWallet {
        tokenTransfer = false;
        TokenTransfer();
    }

}