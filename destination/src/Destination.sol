// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BridgeToken.sol";

contract Destination is AccessControl {
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
	mapping( address => address) public underlying_tokens;
	mapping( address => address) public wrapped_tokens;
	address[] public tokens;

	event Creation( address indexed underlying_token, address indexed wrapped_token );
	event Wrap( address indexed underlying_token, address indexed wrapped_token, address indexed to, uint256 amount );
	event Unwrap( address indexed underlying_token, address indexed wrapped_token, address frm, address indexed to, uint256 amount );

    constructor( address admin ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CREATOR_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);
    }

	function registerToken(address _underlying, address _wrapped) public {
		// key is wrapped token address
		// value is underlying token address
		underlying_tokens[_wrapped] = _underlying;
		wrapped_tokens[_underlying] = _wrapped;

	} // definitely need this 

	function removeToken(address _underlying, address _wrapped) public {
		delete underlying_tokens[_wrapped];
		delete wrapped_tokens[_underlying];
	} // may not need this 

	function isTokenCreated(address tokenAddress) public returns(bool) {
		for (uint i = 0; i < tokens.length; i++) {
			if (tokens[i] == tokenAddress) {
				return true;
			}
		}
		return false;
	} // may not need this 

	function wrap(address _underlying_token, address _recipient, uint256 _amount ) public onlyRole(WARDEN_ROLE) {
		//YOUR CODE HERE
		// 3 args address of underl asset on source chain, address that will receive the newly wrapped tokens,

		// the amount of tokens to mint
		// warden mints correct bridge token on the destination chain

		// function should look up the Bridge Token that corresponds to the undelying asset, and mint the
		// correct amount of Bridge Tokens to the recipient

		// function must check that the underlying asset has been registered -- the owner of the destination
		// contract has called createToken on the underlying asset

		address _wrapped_token = wrapped_tokens[_underlying_token];
		// get address of wrapped_token which is instance of bridge token contract 

		require(_wrapped_token != address(0), "there is no wrapped token for this underlying token"); 
		// make sure there is a wrapped token for the underlying token 

		BridgeToken(_wrapped_token).mint(_recipient, _amount);

		emit Wrap(_underlying_token, _wrapped_token, _recipient, _amount);
		// event Wrap( address indexed underlying_token, address indexed wrapped_token, address indexed to, uint256 amount );
	}

	function unwrap(address _wrapped_token, address _recipient, uint256 _amount ) public {
		//YOUR CODE HERE
		// 3 args address of Bridge Token that is being unwrapped on the destination chain, address of the 

		// recipient of the underlying tokens on the source chain, the amount of tokens to burn
		// should emit an unwrap event
		// anyone should be able to unwrap Bridge Tokens -- but only ones they own

		address _underlying_token = underlying_tokens[_wrapped_token];
		// underlying token address

		uint balance = BridgeToken(_wrapped_token).balanceOf(msg.sender);
		// get senders balance

		require(balance >= _amount, "sender wants to unwrap more tokens than they own");
		// check that sender owns enough tokens to unwrap

		BridgeToken(_wrapped_token).burnFrom(msg.sender, _amount);
		// need to figure out address to burn from — is the unwrapped address? Probably not — it burns in destination chain

		//address _wt = address(_wrapped_token); // get original address of token

		emit Unwrap(_underlying_token, _wrapped_token, msg.sender, _recipient, _amount);
		// event Unwrap( address indexed underlying_token, address indexed wrapped_token, address frm, address indexed to, uint256 amount );
		// need to figure out from address  think it might be msg.sender or tx.origin 
	}

	function createToken(address _underlying_token, string memory name, string memory symbol ) public onlyRole(CREATOR_ROLE) returns(address) {
		//YOUR CODE HERE
		// 3 args address of undelying asset on source chain, the name of underlying asset, symbol of underlings asset

		// new bridge token instance is needed
		// only creator should be allowed to call this function
		// should deploy new Bridge Token Contract and return address of newly created contract

		BridgeToken newBridgeToken = new BridgeToken(_underlying_token, name, symbol, address(this));
	
		address _newBridgeTokenAddress = address(newBridgeToken);
		
		registerToken(_underlying_token, _newBridgeTokenAddress); 
		// register underlying token and wrapped tokens in mappings

		tokens.push(_newBridgeTokenAddress);
		// not sure 

		emit Creation(_underlying_token, _newBridgeTokenAddress);

		return _newBridgeTokenAddress;	
	}

}

