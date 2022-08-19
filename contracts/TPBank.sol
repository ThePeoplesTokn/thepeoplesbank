// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
 /**
  /// @title ThePeoplesBank Dapp
  /// @author ThePeoplesToken
  /// @notice You can use this contract for basic DeFi simulations of deposits, withdrawals, and rewarding liquidity providers
  */
contract TPBank is Ownable, Pausable, ReentrancyGuard {
  /// @dev refer to https://docs.openzeppelin.com/contracts/2.x/api/token/erc20#IERC20
  IERC20 public ThePeoplesToken;

  mapping (address => uint) private balances;
  mapping (address => uint) private timestamp;
  
  
  
  
  /// @notice You have made a deposit in the ThePeoplesBank
  event LogWeiDeposit(address _accountAddress, uint _depositAmount);
  
  /// @notice You have made a withdrawal from the ThePeoplesBank
  event LogWeiWithdrawal(address _accountAddress,uint _withdrawalAmount, uint _updatedBalance);

  /**
    @param _Token the ERC20 token this contract will use
    @notice After the ThePeoplesToken contract is deployed the address of the ThePeoplesToken contract is 
      passed to the constructor of this bank contract so the bank can use ERC20 tokens
  */
  constructor (IERC20 _Token) {
     ThePeoplesToken = _Token;
  }

  

  /// @param _amountToWithdrawInWei the amount the user wants to withdraw in Wei
  /// @notice User must have sufficient funds in their account balance to withdraw their Wei 
  modifier hasFunds(uint _amountToWithdrawInWei) {
    require(balances[msg.sender] >= _amountToWithdrawInWei, "Insufficient funds");
    _; 
  }

  /// @param _user the user must have an account with a balance in the bank to receive ThePeoplesToken token rewards
  /// @param timestamp set to the block timestamp at the time of the user's initial deposit into the bank
  /** @notice In production the requirement would be for a user to hold a deposit in the bank for >= 1 year:
      For the purpose of testing this project, the user will receive ThePeoplesTokens for making an initial deposit 
      without the aforementioned time requirement. 
  */
  modifier isHodler(address _user) {
    /// @dev In production, uncomment line 55 (next line) and delete line 56 (next line + 1)
      // require((timestamp[_user] + 365 days) >= block.timestamp, "Hasn't held funds longer than 1 year");
    require((timestamp[_user] - 1 days) < block.timestamp, "Hasn't held funds long enough");
    _;
  }

  /// @notice You have made a deposit to your ThePeoplesBank account
  function deposit() 
    external 
    payable 
    nonReentrant 
  {
    require(msg.value > 0, "Must deposit at least 1 wei");
    /// @notice HODL time initiated at current block.timestamp
    if(timestamp[msg.sender] == 0 && balances[msg.sender] == 0) {
      timestamp[msg.sender] = block.timestamp;
    }

    /// @notice updates user's wei balance in their bank account
    balances[msg.sender] += msg.value;
    

    /// @notice emits log of the deposit
    emit LogWeiDeposit(msg.sender, msg.value);
  }

  /// @param _amountToWithdrawInWei amount user wishes to withdraw in wei
  /// @notice You must have sufficient funds in your account balance to make a withdrawal
  function withdraw(uint _amountToWithdrawInWei) 
    external 
    payable 
    hasFunds(_amountToWithdrawInWei) 
    nonReentrant 
  {
    
    address payable _user = payable(msg.sender);
    
    /// @notice withdrawal amount in wei deducted from user's balance in their bank account
    balances[msg.sender] -= _amountToWithdrawInWei;
    
    /// @notice timestamp for tracking how long user has held a deposit without withdrawing liquidity is reset to 0
    timestamp[msg.sender] = 0;

    /// @notice withdrawal amount in wei is transferred to the user's EOA
    (bool success, ) = _user.call{value:_amountToWithdrawInWei}("");
    require(success, "Transfer failed.");
    /// @notice emits log of the withdrawal
    emit LogWeiWithdrawal(msg.sender, _amountToWithdrawInWei, balances[msg.sender]);
  }

  /// @param from the owner
  /** @notice Allows only the owner of the ERC20 contract ThePeoplesToken.sol to approve this
      contract to spend ThePeoplesToken tokens. 
  */
  function transferThePeoplesTokenToContract(uint _amountToContractInThePeoplesToken) 
    external 
    onlyOwner 
  {
    address from = msg.sender;

    /// @dev refer to https://forum.openzeppelin.com/t/example-on-how-to-use-erc20-token-in-another-contract/1682
    /// @notice Transfers ThePeoplesToken ERC20 token from the owner to this contract so bank
    ThePeoplesToken.transferFrom(from, address(this), _amountToContractInThePeoplesToken);
  }

  /// @notice Rewards liquidity providers with ThePeoplesToken tokens if they hold a deposit in the bank
  function mintThePeoplesTokenToUser(address _user) 
    public 
    isHodler(_user)
    nonReentrant
  {
    /**  @dev In production the isHodler requirement would add the requirement of holding a deposit 
          for 1 year to receive reward tokens */ 
   // require(ThePeoplesToken.balanceOf(_user) == 0, "User has already claimed rewards");
    
    /// @notice Bank transfer 1000 ThePeoplesToken (ERC20 token) to an account holder
    ThePeoplesToken.transfer(_user, 1000 * 10**18);

    /// @notice Timestamp for user is reset to 0 once rewards are claimed for the year
    timestamp[_user] = 0;
  }

  /// @notice Get wei balance in user's account 
  /// @return returns uint
  function getWeiBalance() external view returns (uint) {
    return balances[msg.sender];
  }

  function getBankBalance() public view returns (uint256) {
        return address(this).balance;
    }
  /// @notice Get timestamp for how long user has provided liquidity to bank  
  /// @return returns uint
  function getTimestamp() external view returns(uint) {
    return timestamp[msg.sender];
  }

  

  /// @notice Pause the contract 
  /// @dev Circuit breaker pattern
  function pause() 
    public 
    onlyOwner 
  {
    Pausable._pause();
  }

  /// @notice Resume the contract for both reads and writes
  /// @dev Circuit breaker pattern
  function unpause() 
    public 
    onlyOwner 
  {
    Pausable._unpause();
  }
}