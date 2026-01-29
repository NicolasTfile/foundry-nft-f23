// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployBasicNft} from "script/DeployBasicNft.s.sol";
import {BasicNft} from "src/BasicNft.sol";

contract BasicNftTest is Test {
    DeployBasicNft public deployer;
    BasicNft public basicNft;
    address public user = makeAddr("user");
    address public user2 = makeAddr("user2");

    string public constant PUG =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function setUp() public {
        deployer = new DeployBasicNft();
        basicNft = deployer.run();
    }

    // CONSTRUCTOR TESTS

    function testNameIsCorrect() public view {
        // Arrange / Act
        string memory expectedName = "Dogie";
        string memory actualName = basicNft.name();

        // Assert
        assertEq(keccak256(abi.encodePacked(expectedName)), keccak256(abi.encodePacked(actualName)));
    }

    function testSymbolIsCorrect() public view {
        // Arrange / Act
        string memory expectedSymbol = "DOG";
        string memory actualSymbol = basicNft.symbol();

        // Assert
        assertEq(keccak256(abi.encodePacked(expectedSymbol)), keccak256(abi.encodePacked(actualSymbol)));
    }

    function testTokencounterStartsAtZero() public view {
        // Arrange / Act
        // Token counter is private, but we can infer it by checking
        // that no tokens exist yet and minting starts at 0

        // Assert
        assertEq(basicNft.balanceOf(user), 0);
    }

    // MINTING TESTS

    function testCanMintAndHaveABalance() public {
        // Arrange / Act
        vm.prank(user);
        basicNft.mintNft(PUG);

        // Assert
        assertEq(basicNft.balanceOf(user), 1);
    }

    function testMintingIncrementsTokenCounter() public {
        // Arrange / Act
        vm.startPrank(user);
        basicNft.mintNft(PUG);
        basicNft.mintNft(PUG);
        basicNft.mintNft(PUG);
        vm.stopPrank();

        // Assert - User should have 3 NFTs with token IDs 0, 1, 2
        assertEq(basicNft.balanceOf(user), 3);
        assertEq(basicNft.ownerOf(0), user);
        assertEq(basicNft.ownerOf(1), user);
        assertEq(basicNft.ownerOf(2), user);
    }

    function testMultipleUsersCanMint() public {
        // Arrange / Act
        vm.prank(user);
        basicNft.mintNft(PUG);

        vm.prank(user2);
        basicNft.mintNft(PUG);

        // Assert
        assertEq(basicNft.balanceOf(user), 1);
        assertEq(basicNft.balanceOf(user2), 1);
        assertEq(basicNft.ownerOf(0), user);
        assertEq(basicNft.ownerOf(1), user2);
    }

    function testMintEmitsTransferEvent() public {
        // Arrange / Act / Assert
        vm.prank(user);
        vm.expectEmit(true, true, true, false, address(basicNft));
        emit Transfer(address(0), user, 0);
        basicNft.mintNft(PUG);
    }

    function testMintSetsCorrectOwner() public {
        // Arrange / Act
        vm.prank(user);
        basicNft.mintNft(PUG);

        // Assert
        assertEq(basicNft.ownerOf(0), user);
    }

    // TOKEN URI TESTS
    function testTokenURIIsCorrect() public {
        // Arrange / Act
        vm.prank(user);
        basicNft.mintNft(PUG);

        string memory tokenUri = basicNft.tokenURI(0);

        // Assert
        assertEq(keccak256(abi.encodePacked(PUG)), keccak256(abi.encodePacked(tokenUri)));
    }

    function testTokenURIWithEmptyString() public {
        // Arrange / Act
        vm.prank(user);
        basicNft.mintNft("");

        string memory tokenUri = basicNft.tokenURI(0);

        // Assert - Empty string should be stored
        assertEq(keccak256(abi.encodePacked("")), keccak256(abi.encodePacked(tokenUri)));
    }

    // TRANSFER TESTS
    function testOwnerCanTransferNft() public {
        // Arrange
        vm.prank(user);
        basicNft.mintNft(PUG);

        // Act
        vm.prank(user);
        basicNft.transferFrom(user, user2, 0);

        // Assert
        assertEq(basicNft.ownerOf(0), user2);
        assertEq(basicNft.balanceOf(user), 0);
        assertEq(basicNft.balanceOf(user2), 1);
    }

    function testNonOwnerCannotTransferNft() public {
        //Arrange
        vm.prank(user);
        basicNft.mintNft(PUG);

        // Act
        vm.prank(user2);
        vm.expectRevert(); // ERC721: transfer caller is not owner nor approved
        basicNft.transferFrom(user, user2, 0);
    }

    // APPROVAL TESTS
    // BALANCE TESTS
    // OWNER OF TESTS
    // EDGE CASE TESTS
    // FUZZ TESTS
    function testFuzzMintingWithRandomURI(string memory randomUri) public {
        // Arrange / Act
        vm.prank(user);
        basicNft.mintNft(randomUri);

        // Assert
        assertEq(basicNft.balanceOf(user), 1);
        assertEq(keccak256(abi.encodePacked(basicNft.tokenURI(0))), keccak256(abi.encodePacked(randomUri)));
    }
}
