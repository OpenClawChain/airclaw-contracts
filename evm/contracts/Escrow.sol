// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Escrow - A smart contract for managing escrow agreements
/// @notice Handles ETH and ERC20 deposits, worker assignments, work submission, approvals, and refunds
contract Escrow is ReentrancyGuard {
    enum State { Created, Funded, InProgress, Submitted, Completed, Cancelled }
    enum TokenType { ETH, ERC20 }

    State public state;
    TokenType public tokenType;
    address public payer;
    address public payee;
    address public token;
    uint256 public amount;
    uint256 public feePercentage;
    address public feeRecipient;

    // Events
    event EscrowCreated(uint256 indexed escrowId, address indexed payer, uint256 amount, TokenType tokenType);
    event EscrowFunded(uint256 indexed escrowId, uint256 amount);
    event BidAccepted(uint256 indexed escrowId, address indexed worker);
    event WorkSubmitted(uint256 indexed escrowId, string workHash);
    event WorkApproved(uint256 indexed escrowId, uint256 amountReleased);
    event WorkRejected(uint256 indexed escrowId, string reason);
    event RefundProcessed(uint256 indexed escrowId, uint256 amountRefunded);
    event EscrowCancelled(uint256 indexed escrowId, string reason);

    modifier onlyPayer() {
        require(msg.sender == payer, "Only payer can call this");
        _;
    }

    modifier onlyPayee() {
        require(msg.sender == payee, "Only worker can call this");
        _;
    }

    modifier inState(State expectedState) {
        require(state == expectedState, "Invalid state");
        _;
    }

    constructor(
        address _payer,
        address _payee,
        uint256 _amount,
        address _token,
        TokenType _tokenType,
        uint256 _feePercentage,
        address _feeRecipient
    ) {
        payer = _payer;
        payee = _payee;
        amount = _amount;
        token = _token;
        tokenType = _tokenType;
        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
        state = State.Created;
    }

    /// @notice Fund the escrow with ETH or ERC20 tokens
    function fund() external payable onlyPayer nonReentrant inState(State.Created) {
        if (tokenType == TokenType.ETH) {
            require(msg.value == amount, "Must send exact amount");
        } else {
            require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        }
        state = State.Funded;
        emit EscrowFunded(address(this), amount);
    }

    /// @notice Accept bid and start work (payer confirms worker)
    function acceptBid() external onlyPayer inState(State.Funded) {
        state = State.InProgress;
        emit BidAccepted(address(this), payee);
    }

    /// @notice Submit completed work (worker marks as done)
    function submitWork(string calldata workHash) external onlyPayee inState(State.InProgress) {
        state = State.Submitted;
        emit WorkSubmitted(address(this), workHash);
    }

    /// @notice Approve work and release funds to worker
    function approveWork() external onlyPayer nonReentrant inState(State.Submitted) {
        uint256 fee = (amount * feePercentage) / 10000;
        uint256 payout = amount - fee;

        if (tokenType == TokenType.ETH) {
            if (fee > 0) payable(feeRecipient).transfer(fee);
            payable(payee).transfer(payout);
        } else {
            if (fee > 0) require(IERC20(token).transfer(feeRecipient, fee), "Fee transfer failed");
            require(IERC20(token).transfer(payee, payout), "Payout transfer failed");
        }

        state = State.Completed;
        emit WorkApproved(address(this), payout);
    }

    /// @notice Reject submitted work and refund payer
    function rejectWork(string calldata reason) external onlyPayer nonReentrant inState(State.Submitted) {
        _refund();
        emit WorkRejected(address(this), reason);
    }

    /// @notice Early refund - cancel escrow before work starts
    function refund(string calldata reason) external onlyPayer nonReentrant inState(State.InProgress) {
        _refund();
        emit EscrowCancelled(address(this), reason);
    }

    /// @notice Emergency cancellation by fee recipient
    function emergencyCancel(string calldata reason) external {
        require(msg.sender == feeRecipient || msg.sender == payer, "Not authorized");
        require(state != State.Completed && state != State.Cancelled, "Cannot cancel");
        _refund();
        emit EscrowCancelled(address(this), reason);
    }

    function _refund() internal {
        if (tokenType == TokenType.ETH) {
            payable(payer).transfer(amount);
        } else {
            require(IERC20(token).transfer(payer, amount), "Refund transfer failed");
        }
        state = State.Cancelled;
        emit RefundProcessed(address(this), amount);
    }

    function getState() external view returns (State) {
        return state;
    }
}
