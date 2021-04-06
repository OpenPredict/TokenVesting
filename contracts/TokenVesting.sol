// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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

    event TokensReleased(uint schedule, address holder, address token, uint256 amount);

    // The token being vested
    IERC20 public _token;
    // If the contract is revocable
    bool private _revocable;
    // total amount the contract has released.
    uint256 totalReleased;

    uint256 public immutable VESTING_PERIOD = 2629746; // 1 month in seconds

    // Schedule. 
    struct Schedule {
        string id;               // eg. "foundation", "marketing" etc.
        uint256 startPeriod;     // the timestamp of the first period.
        uint256 numPeriods;      // number of periods to vest.
        uint256 amountPerPeriod; // amount of the token to release each period.
    }

    Schedule[] public schedules;
    mapping(uint => mapping (address => uint256)) balances; // balances assigned to a wallet for a schedule
    mapping(uint => mapping (address => uint256)) released; // released to a wallet for a schedule
    mapping(uint => mapping (address => bool[])) vested;    // array of bools indicating whether wallet has vested or not.
    
    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, in chunks of amountPerPeriod, until the schedule has completed.
     * @param token ERC20 token which is being vested
     * @param revocable whether the vesting is revocable or not
     */
    constructor (IERC20 token, bool revocable) {
        _token = token;
        _revocable = revocable;
    }

    function addSchedule(string calldata id, uint256 startPeriod, uint256 numPeriods, uint256 amountPerPeriod, address[] calldata holders) external onlyOwner {
        require(numPeriods <= 255);

        Schedule memory schedule;

        schedule.id = id;
        schedule.startPeriod = startPeriod;
        schedule.numPeriods = numPeriods;
        schedule.amountPerPeriod = amountPerPeriod;
        schedules.push(schedule);

        uint scheduleID = schedules.length-1;

        // set initial holders.
        for(uint i=0; i<holders.length; i++){
            balances[scheduleID][holders[i]] = amountPerPeriod.mul(numPeriods).div(holders.length);
            vested[scheduleID][holders[i]] = new bool[](numPeriods);
        }
    }

    // /**
    //  * @dev Returns the amount of tokens owned by `account`.
    //  */
    function getNumSchedules() external view returns (uint256) {
        return schedules.length;
    }

    // /**
    //  * @return the amount of the total token released.
    //  */
    // function totalReleased() public view returns (uint256) {
    //     return _totalReleased;
    // }

    // /**
    //  * @return the amount of the token released by 'holder'.
    // */
    // function released(address holder) public view returns (uint256) {
    //     return _released[holder];
    // }

    // /**
    //  * @return If the amount for schedule at idx passed has been vested.
    // */
    // function vested(address holder, uint idx) public view returns (bool) {
    //     return _vested[holder][idx];
    // }

    /**
     * @return the vested amount of the token for a particular timestamp 'ts' and 'holder'.
     */
    // function vestedAmount(uint256 ts, address holder) public view returns (uint256) {
    //     int8 unreleasedIdx = _releasableIdx(ts, holder);
    //     if (unreleasedIdx >= 0) {
    //         return _amountPerPeriod;
    //     } else {
    //         return 0;
    //     }

    // }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     */
    function revoke(uint256 amount) public onlyOwner {
        require(_revocable, "TokenVesting: cannot revoke");

        _token.safeTransfer(owner(), amount);
    }

    /**
     * @notice Transfers vested tokens to sender.
     */
    function release(uint scheduleID) public {
        uint256 unreleasedIdx = _releasableIdx(scheduleID, _msgSender());
        uint256 unreleasedAmount = schedules[scheduleID].amountPerPeriod;        

        vested[scheduleID][_msgSender()][unreleasedIdx] = true;
        released[scheduleID][_msgSender()] = released[scheduleID][_msgSender()].add(unreleasedAmount);
        totalReleased = totalReleased.add(unreleasedAmount);

        _token.safeTransfer(_msgSender(), unreleasedAmount);
        emit TokensReleased(scheduleID, _msgSender(), address(_token), unreleasedAmount);
    }

    /**
     * @dev Calculates the index that has already vested but hasn't been released yet for 'holder'.
     */
    function _releasableIdx(uint scheduleID,address holder) private view returns (uint256) {

        require(vested[scheduleID][holder].length > 0, "_releasableIdx: no vesting for sender.");

        uint256 startPeriod = schedules[scheduleID].startPeriod;

        for (uint256 index = 0; index < schedules[scheduleID].numPeriods; index++) {
            if (block.timestamp > startPeriod.add(index.mul(VESTING_PERIOD)) && vested[scheduleID][holder][index] == false) {
                return index;
            }
        }

        require(false, "_releasableIdx: no tokens are due.");
        return 0;
    }
}
