// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Escrow.sol";

/// @title EscrowFactory - Factory contract for deploying Escrow instances
/// @notice Creates and manages escrow agreements
contract EscrowFactory {
    uint256 public nextEscrowId;
    mapping(uint256 => address) public escrows;
    
    // Events
    event EscrowDeployed(uint256 indexed escrowId, address indexed escrowAddress, address indexed payer, address payee);
    event EscrowIdGenerated(uint256 indexed escrowId);

    constructor() {
        nextEscrowId = 1;
    }

    /// @notice Deploy a new ETH escrow
    /// @param payee Worker/contractor address
    /// @param amount Escrow amount in wei
    /// @param feePercentage Fee basis points (e.g., 250 = 2.5%)
    /// @param feeRecipient Address to receive fees
    function createEthEscrow(
        address payee,
        uint256 amount,
        uint256 feePercentage,
        address feeRecipient
    ) external payable returns (address) {
        require(msg.value == amount, "Must send exact amount");
        require(feePercentage <= 10000, "Fee too high");
        
        Escrow escrow = new Escrow(
            msg.sender,
            payee,
            amount,
            address(0),
            Escrow.TokenType.ETH,
            feePercentage,
            feeRecipient
        );
        
        uint256 id = nextEscrowId++;
        escrows[id] = address(escrow);
        
        emit EscrowDeployed(id, address(escrow), msg.sender, payee);
        emit EscrowIdGenerated(id);
        
        return address(escrow);
    }

    /// @notice Deploy a new ERC20 escrow
    /// @param payee Worker/contractor address
    /// @param amount Escrow amount in tokens
    /// @param token Token contract address
    /// @param feePercentage Fee basis points
    /// @param feeRecipient Address to receive fees
    function createErc20Escrow(
        address payee,
        uint256 amount,
        address token,
        uint256 feePercentage,
        address feeRecipient
    ) external returns (address) {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        
        Escrow escrow = new Escrow(
            msg.sender,
            payee,
            amount,
            token,
            Escrow.TokenType.ERC20,
            feePercentage,
            feeRecipient
        );
        
        uint256 id = nextEscrowId++;
        escrows[id] = address(escrow);
        
        emit EscrowDeployed(id, address(escrow), msg.sender, payee);
        emit EscrowIdGenerated(id);
        
        return address(escrow);
    }

    /// @notice Get escrow address by ID
    function getEscrow(uint256 id) external view returns (address) {
        return escrows[id];
    }

    /// @notice Get total number of escrows created
    function getTotalEscrows() external view returns (uint256) {
        return nextEscrowId - 1;
    }
}
