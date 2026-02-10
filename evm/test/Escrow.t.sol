// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/Test.sol";
import "../contracts/Escrow.sol";
import "../contracts/EscrowFactory.sol";

/// @title TestToken - Simple ERC20 token for testing
contract TestToken is ERC20, Ownable {
    constructor() ERC20("Test Token", "TEST") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

/// @title EscrowTest - Comprehensive tests for Escrow contract
contract EscrowTest is Test {
    Escrow escrow;
    EscrowFactory factory;
    TestToken token;
    
    address payer = makeAddr("payer");
    address worker = makeAddr("worker");
    address feeRecipient = makeAddr("feeRecipient");
    
    uint256 constant AMOUNT = 10 ether;
    uint256 constant FEE_PERCENTAGE = 250; // 2.5%
    
    function setUp() public {
        factory = new EscrowFactory();
        token = new TestToken();
    }
    
    // ===== ETH Escrow Tests =====
    
    function testCreateEthEscrow() public {
        vm.deal(payer, 100 ether);
        
        vm.prank(payer);
        address escrowAddr = factory.createEthEscrow{value: AMOUNT}(
            worker,
            AMOUNT,
            FEE_PERCENTAGE,
            feeRecipient
        );
        
        assertEq(escrowAddr, factory.getEscrow(1));
        
        escrow = Escrow(payable(escrowAddr));
        assertEq(uint256(escrow.state()), uint256(Escrow.State.Funded));
        assertEq(escrow.payer(), payer);
        assertEq(escrow.payee(), worker);
        assertEq(escrow.amount(), AMOUNT);
    }
    
    function testAcceptBid() public {
        vm.deal(payer, 100 ether);
        
        vm.prank(payer);
        address escrowAddr = factory.createEthEscrow{value: AMOUNT}(
            worker,
            AMOUNT,
            FEE_PERCENTAGE,
            feeRecipient
        );
        
        escrow = Escrow(payable(escrowAddr));
        
        vm.prank(payer);
        escrow.acceptBid();
        
        assertEq(uint256(escrow.state()), uint256(Escrow.State.InProgress));
    }
    
    function testSubmitWork() public {
        vm.deal(payer, 100 ether);
        
        vm.prank(payer);
        address escrowAddr = factory.createEthEscrow{value: AMOUNT}(
            worker,
            AMOUNT,
            FEE_PERCENTAGE,
            feeRecipient
        );
        
        escrow = Escrow(payable(escrowAddr));
        
        vm.prank(payer);
        escrow.acceptBid();
        
        vm.prank(worker);
        escrow.submitWork("QmHash123...");
        
        assertEq(uint256(escrow.state()), uint256(Escrow.State.Submitted));
    }
    
    function testApproveWork() public {
        vm.deal(payer, 100 ether);
        vm.deal(feeRecipient, 0);
        vm.deal(worker, 0);
        
        vm.prank(payer);
        address escrowAddr = factory.createEthEscrow{value: AMOUNT}(
            worker,
            AMOUNT,
            FEE_PERCENTAGE,
            feeRecipient
        );
        
        escrow = Escrow(payable(escrowAddr));
        
        vm.prank(payer);
        escrow.acceptBid();
        
        vm.prank(worker);
        escrow.submitWork("QmHash123...");
        
        uint256 expectedFee = (AMOUNT * FEE_PERCENTAGE) / 10000;
        uint256 expectedPayout = AMOUNT - expectedFee;
        
        vm.prank(payer);
        escrow.approveWork();
        
        assertEq(uint256(escrow.state()), uint256(Escrow.State.Completed));
        assertEq(feeRecipient.balance, expectedFee);
        assertEq(worker.balance, expectedPayout);
    }
    
    function testRejectWork() public {
        vm.deal(payer, 100 ether);
        vm.deal(address(this), 0); // Payer is this test contract
        
        // Need to test from a different address
        address testPayer = makeAddr("testPayer");
        vm.deal(testPayer, 100 ether);
        
        vm.prank(testPayer);
        address escrowAddr = factory.createEthEscrow{value: AMOUNT}(
            worker,
            AMOUNT,
            FEE_PERCENTAGE,
            feeRecipient
        );
        
        escrow = Escrow(payable(escrowAddr));
        
        vm.prank(testPayer);
        escrow.acceptBid();
        
        vm.prank(worker);
        escrow.submitWork("QmHash123...");
        
        uint256 payerBalanceBefore = testPayer.balance;
        
        vm.prank(testPayer);
        escrow.rejectWork("Work not satisfactory");
        
        assertEq(uint256(escrow.state()), uint256(Escrow.State.Cancelled));
        assertEq(testPayer.balance, payerBalanceBefore + AMOUNT);
    }
    
    function testRefund() public {
        vm.deal(payer, 100 ether);
        
        vm.prank(payer);
        address escrowAddr = factory.createEthEscrow{value: AMOUNT}(
            worker,
            AMOUNT,
            FEE_PERCENTAGE,
            feeRecipient
        );
        
        escrow = Escrow(payable(escrowAddr));
        
        vm.prank(payer);
        escrow.acceptBid();
        
        uint256 payerBalanceBefore = payer.balance;
        
        vm.prank(payer);
        escrow.refund("Changed my mind");
        
        assertEq(uint256(escrow.state()), uint256(Escrow.State.Cancelled));
        assertEq(payer.balance, payerBalanceBefore + AMOUNT);
    }
    
    // ===== ERC20 Escrow Tests =====
    
    function testCreateErc20Escrow() public {
        token.mint(payer, AMOUNT);
        
        vm.prank(payer);
        token.approve(address(factory), AMOUNT);
        
        vm.prank(payer);
        address escrowAddr = factory.createErc20Escrow(
            worker,
            AMOUNT,
            address(token),
            FEE_PERCENTAGE,
            feeRecipient
        );
        
        assertEq(escrowAddr, factory.getEscrow(1));
        
        escrow = Escrow(payable(escrowAddr));
        assertEq(uint256(escrow.state()), uint256(Escrow.State.Funded));
    }
    
    function testErc20ApproveWork() public {
        token.mint(payer, AMOUNT);
        
        vm.prank(payer);
        token.approve(address(factory), AMOUNT);
        
        vm.prank(payer);
        address escrowAddr = factory.createErc20Escrow(
            worker,
            AMOUNT,
            address(token),
            FEE_PERCENTAGE,
            feeRecipient
        );
        
        escrow = Escrow(payable(escrowAddr));
        
        vm.prank(payer);
        escrow.acceptBid();
        
        vm.prank(worker);
        escrow.submitWork("QmHash123...");
        
        uint256 expectedFee = (AMOUNT * FEE_PERCENTAGE) / 10000;
        uint256 expectedPayout = AMOUNT - expectedFee;
        
        vm.prank(payer);
        escrow.approveWork();
        
        assertEq(uint256(escrow.state()), uint256(Escrow.State.Completed));
        assertEq(token.balanceOf(feeRecipient), expectedFee);
        assertEq(token.balanceOf(worker), expectedPayout);
    }
    
    // ===== Revert Tests =====
    
    function testRevertWrongAmount() public {
        vm.deal(payer, 100 ether);
        
        vm.prank(payer);
        vm.expectRevert("Must send exact amount");
        factory.createEthEscrow{value: AMOUNT - 1 ether}(
            worker,
            AMOUNT,
            FEE_PERCENTAGE,
            feeRecipient
        );
    }
    
    function testRevertOnlyPayer() public {
        vm.deal(payer, 100 ether);
        
        vm.prank(payer);
        address escrowAddr = factory.createEthEscrow{value: AMOUNT}(
            worker,
            AMOUNT,
            FEE_PERCENTAGE,
            feeRecipient
        );
        
        escrow = Escrow(payable(escrowAddr));
        
        vm.prank(worker);
        vm.expectRevert("Only payer can call this");
        escrow.acceptBid();
    }
    
    function testRevertInvalidState() public {
        vm.deal(payer, 100 ether);
        
        vm.prank(payer);
        address escrowAddr = factory.createEthEscrow{value: AMOUNT}(
            worker,
            AMOUNT,
            FEE_PERCENTAGE,
            feeRecipient
        );
        
        escrow = Escrow(payable(escrowAddr));
        
        vm.prank(worker);
        vm.expectRevert("Only worker can call this");
        escrow.submitWork("QmHash");
    }
}
