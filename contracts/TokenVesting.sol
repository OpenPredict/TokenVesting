// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title PartnersVesting
 * @dev A token holder contract that can release its token balance gradually at different vesting points
 */
contract TokenVesting is Ownable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address holder, address token, uint256 amount);

    // The token being vested
    IERC20 public _token;

    bool private _revocable;

    uint256 private _totalReleased = 0;

    mapping (address => uint256) private _balances;

    mapping (address => uint256) private _released;

    mapping (address =>  bool[]) private _vested;

    bool[] private _baseVested;

    uint256[] private _schedule;

    uint256 private _amountPerSchedule;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, in chunks of amountPerSchedule, until the schedule has completed.
     * @param token ERC20 token which is being vested
     * @param schedule array of the timestamps (as Unix time) at which point vesting starts
     * @param amountPerSchedule amount to be vested per schedule
     * @param revocable whether the vesting is revocable or not
     */
    constructor (IERC20 token, uint256[] memory schedule, uint256 amountPerSchedule, bool revocable) public {

        require(schedule.length <= 255);

        bool[] memory baseVested = new bool[](schedule.length); // default is false

        _token = token;

        _schedule = schedule;
        
        _amountPerSchedule = amountPerSchedule;
        
        _baseVested = baseVested;

        _revocable = revocable;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
    * @return true if the vesting is revocable.
    */
    function revocable() public view returns (bool) {
        return _revocable;
    }

    /**
     * @return the amount of the total token released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @return the amount of the token released by 'holder'.
    */
    function released(address holder) public view returns (uint256) {
        return _released[holder];
    }

    /**
     * @return If the amount for schedule at idx passed has been vested.
    */
    function vested(address holder, uint idx) public view returns (bool) {
        return _vested[holder][idx];
    }

    /**
     * @dev Set the balance of available token equal to 'amount' for `holder`.
     *
     * Requirements:
     *
     * - `holder` cannot be the zero address.
     */
    function setBalance(address holder, uint256 amount) public onlyOwner {
        require(holder != address(0), "ERC20: setting to the zero address");

        _balances[holder] = amount;

        _vested[holder] = _baseVested;
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     */
    function revoke(uint256 amount) public onlyOwner {
        require(_revocable, "TokenVesting: cannot revoke");

        _token.safeTransfer(owner(), amount);
    }

    /**
     * @return the vested amount of the token for a particular timestamp 'ts' and 'holder'.
     */
    function vestedAmount(uint256 ts, address holder) public view returns (uint256) {
        int8 unreleasedIdx = _releasableIdx(ts, holder);
        if (unreleasedIdx >= 0) {
            return _amountPerSchedule;
        } else {
            return 0;
        }

    }

    /**
     * @notice Transfers vested tokens to sender.
     */
    function release() public {
        int8 unreleasedIdx = _releasableIdx(block.timestamp, _msgSender());

        require(unreleasedIdx >= 0, "TokenVesting: no tokens are due");

        uint256 unreleasedAmount = _amountPerSchedule;

        _token.safeTransfer(_msgSender(), unreleasedAmount);

        _vested[_msgSender()][uint(unreleasedIdx)] = true;
        _released[_msgSender()] = _released[_msgSender()].add(unreleasedAmount);
        _totalReleased = _totalReleased.add(unreleasedAmount);

        emit TokensReleased(_msgSender(), address(_token), unreleasedAmount);
    }

    /**
     * @dev Calculates the index that has already vested but hasn't been released yet for 'holder'.
     */
    function _releasableIdx(uint256 ts, address holder) private view returns (int8) {
        if (_vested[holder].length == 0) {
            return -1;
        }

        for (uint8 i = 0; i < _schedule.length; i++) {
            if (ts > _schedule[i] && _vested[holder][i] == false) {
                return int8(i);
            }
        }

        return -1;
    }
}
