// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "solmate/src/tokens/ERC20.sol";

contract TimeVaultLock is ERC20 {
    // Mapping to store the deposit time for each address
    mapping(address => uint256) private depositTime;

    constructor() ERC20("WEI Token", "WEI", 18) {}

    function deposit() external payable {
        assembly {
            // Ensure that the deposited amount is exactly 1 Wei
            if iszero(eq(callvalue(), 1)) {
                // bytes4(keccak256("InvalidDeposit()"));
                mstore(0x00, 0xb2e532de00000000000000000000000000000000000000000000000000000000)
                revert(0x00, 0x04)
            }

            // Store the caller's address
            mstore(0x00, caller())
            // Store the depositTime mapping slot
            mstore(0x20, depositTime.slot)
            let depositSlot := keccak256(0x00, 0x40)

            // Check if the deposit slot is empty
            if iszero(eq(sload(depositSlot), 0)) {
                // bytes4(keccak256("ExistingDeposit()"));
                mstore(0x00, 0x6a71ffc200000000000000000000000000000000000000000000000000000000)
                revert(0x00, 0x04)
            }

            // Update the deposit time for the caller
            sstore(depositSlot, timestamp())
        }
    }

    function withdraw() external {
        uint256 tokensEarned;

        assembly {
            // Store the caller's address
            mstore(0x00, caller())
            // Store the depositTime mapping slot
            mstore(0x20, depositTime.slot)
            let depositSlot := keccak256(0x00, 0x40)
            let depositValue := sload(depositSlot)
            // Check if the deposit slot is empty
            if eq(depositValue, 0) {
                // bytes4(keccak256("EmptyDeposit()"));
                mstore(0x00, 0x95b66fe900000000000000000000000000000000000000000000000000000000)
                revert(0x00, 0x04)
            }

            // Calculate the amount of tokens earned
            tokensEarned := sub(timestamp(), depositValue)
            // Reset the deposit time for the caller
            sstore(depositSlot, 0)

            // Call the caller's address and transfer the Ether
            let success := call(gas(), caller(), 1, 0, 0, 0, 0)

            // Check if the call was successful
            if iszero(success) {
                // bytes4(keccak256("TransferFailed()"));
                mstore(0x00, 0x90b8ec1800000000000000000000000000000000000000000000000000000000)
                revert(0x00, 0x04)
            }
        }

        // Mint the earned tokens to the caller
        _mint(msg.sender, tokensEarned);
    }

    function depositedTime(address _account) external view returns(uint256 _depositTime) {
        assembly {
            // Store the caller's address
            mstore(0x00, _account)
            // Store the depositTime mapping slot
            mstore(0x20, depositTime.slot)
            let depositSlot := keccak256(0x00, 0x40)
            _depositTime := sload(depositSlot)
        }
    }
}