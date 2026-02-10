// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../contracts/EscrowFactory.sol";

/// @title DeployScript - Deployment script for Escrow contracts
/// @notice Run with: forge script scripts/Deploy.s.sol --rpc-url <url> --broadcast
contract DeployScript is Script {
    EscrowFactory public factory;
    
    // Configuration
    uint256 constant FEE_PERCENTAGE = 250; // 2.5%
    address constant FEE_RECIPIENT = 0xFEA1c7b89C9b7589D11b2301CaB7A9bE53dA7cC8; // Replace with actual address
    
    function run() external {
        // Load private key from environment or use default
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0));
        
        // Start broadcasting
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy factory
        factory = new EscrowFactory();
        
        console.log("EscrowFactory deployed at:", address(factory));
        console.log("Deployer:", msg.sender);
        
        // Log example usage
        console.log("\n=== Example Usage ===");
        console.log("ETH Escrow: factory.createEthEscrow{value: 1 ether}(worker, 1 ether, 250, feeRecipient)");
        console.log("ERC20 Escrow: factory.createErc20Escrow(worker, 1000e18, tokenAddress, 250, feeRecipient)");
        
        vm.stopBroadcast();
    }
}
