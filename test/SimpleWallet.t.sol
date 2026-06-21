import {Test} from "forge-std/Test.sol";
import {SimpleWallet} from "../src/SimpleWallet.sol";

contract SimpleWalletTest is Test {
    SimpleWallet wallet;

    address owner;
    address alice;
    address bob;

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        wallet = new SimpleWallet();
    }

    function testOwnershipAssignment() public {
        address testOwner = wallet.walletOwner();
        assertEq(testOwner, owner);
    }

    function testEtherDeposit() public {
        uint256 startTime = 0;
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        uint256 contractBalanceBefore = wallet.getContractBalanceInWei();
        wallet.depositToContract{value: 1 ether}(startTime);
        uint256 contractBalanceAfter = wallet.getContractBalanceInWei();
        assertEq(contractBalanceAfter, contractBalanceBefore - 1);
        assertEq(wallet.getTransactionHistory().length, 1);
    }

    function testOwnerOnlyAccessControl() public {
        uint256 withdrawAmount = 1 ether;
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(SimpleWallet.Unauthorized.selector));
        wallet.transferFromContract(payable(bob), withdrawAmount);
    }

    function testTxnRecording() public {
        uint256 startTime = 0;
        vm.deal(alice, 10 ether);
        vm.prank(alice); 
        wallet.depositToContract{value: 2 ether}(startTime);
        wallet.transferDirectlyToUser{value: 1 ether}(payable(bob));

        //VERIFY
        SimpleWallet.Transaction[] memory transactions = wallet.getTransactionHistory();
        assertTrue(transactions.length == 2);
        assertEq(transactions[0].sender, alice);
        assertEq(transactions[0].receiver, address(wallet));
        assertEq(transactions[0].amount, 2 ether);

        assertEq(transactions[1].sender, address(wallet));
        assertEq(transactions[1].receiver, bob);
        assertEq(transactions[1].amount, 1 ether);        
    }
}

