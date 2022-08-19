// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ThePeoplesToken is ERC20, Ownable, Pausable {

  /** @notice Creates an ERC20 token 
    name: Galleon
    symbol: Gal
    totalSupply = 100000000 * 10**18 (i.e. 100,000,000 Galleon tokens with 18 decimal places)
   */
  constructor() ERC20("ThePeoplesToken", "TPT") onlyOwner{
    _mint(msg.sender, 100000000 * 10**18);
  }

  // @notice Pause the contract 
  /// @dev Circuit breaker pattern
  function pause() public onlyOwner {
    Pausable._pause();
  }

  /// @notice Resume the contract for both reads and writes
  /// @dev Circuit breaker pattern
  function unpause() public onlyOwner {
    Pausable._unpause();
  }
}