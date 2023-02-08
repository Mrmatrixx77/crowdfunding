// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error refund_TransferFailed();
error creator_claim_TransferFailed();
error project_NotSatrted();
error project_HasEnded();
error enter_ValidAmount();
error project_Has_Not_Ended();

contract CrowdFunding {
    /**
     * @dev state to define current state of project
     */
    enum State {
        OPEN,
        CLOSED
    }

    /**
     * @dev state variables for the project
     */

    address payable public creator; // creator address
    uint public amountGoal; // amount that is to be achieved before project ends
    uint public startAt; // starting time for project
    uint public endAt; // ending time for project
    uint256 public currentBalance; // current amount raised
    State public state; // initialize on create

    /**
     * @dev mapping for contributions by address
     */
    mapping(address => uint) public contributions;

    /* EVENTS */

    //Event emitted when someone funded the project
    event successfullyFunded(
        address indexed contributor,
        uint amount,
        uint currentTotal
    );
    // Event emitted when the project creator has recieved raised FUNDS
    event amountTransferedToCreator(address indexed _creator);

    // Event emitted when contributor gets refunded
    event refunded(address indexed _refunder, uint256 _refunderAmount);

    /*MODIFIER */

    //Owner or creator modifier
    modifier isCreator() {
        require(msg.sender == creator, " !creator");
        _;
    }

    /**
     * @dev modifier for state of project
     */
    // modifier inState(State _state) {
    //     require(state == _state);
    //     _;
    // }

    constructor(
        address payable _creator,
        uint _startAt,
        uint _endAt,
        uint _amountGoal
    ) {
        creator = _creator;
        // title = _title;
        // description = _description;
        amountGoal = _amountGoal;
        // state = State.OPEN;
        startAt = _startAt;
        endAt = _endAt;
        currentBalance = 0;
    }

    /**
     * @dev function fund project
     */

    function fundProject() external payable {
        if (block.timestamp <= startAt) {
            revert project_NotSatrted();
        }
        if (block.timestamp >= endAt) {
            revert project_HasEnded();
        }
        if (msg.value <= 0) {
            revert enter_ValidAmount();
        }
        contributions[msg.sender] += msg.value;
        currentBalance += msg.value;
        emit successfullyFunded(msg.sender, msg.value, currentBalance);
    }

    /**
     * @dev function for creator to claim before time expired or goal amount raised
     */

    function creator_Claim() external payable isCreator {
        if (block.timestamp <= endAt) {
            revert project_Has_Not_Ended();
        }
        (bool success, ) = creator.call{value: address(this).balance}("");
        if (!success) {
            revert creator_claim_TransferFailed();
        }
        emit amountTransferedToCreator(msg.sender);
        // state = State.CLOSED;
    }

    /**
     * @dev function to refund their token back( FULL or ENTERED amount)
     * @param _refundAmount amount to be refunded
     */

    function refund(uint256 _refundAmount) external payable {
        require(contributions[msg.sender] > 0);
        require(_refundAmount <= contributions[msg.sender]);
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert refund_TransferFailed();
        }
        contributions[msg.sender] -= _refundAmount;
        currentBalance -= _refundAmount;
        emit refunded(msg.sender, _refundAmount);
    }
}
