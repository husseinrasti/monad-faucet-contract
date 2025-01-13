// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MonadFaucetV2 {
    address public owner;
    uint256 public dripAmount;
    uint256 public cooldownTime;

    mapping(address => uint256) public lastRequestTime;

    event TokensDripped(address indexed recipient, uint256 amount);
    event CooldownTimeUpdated(uint256 newCooldownTime);
    event DripAmountUpdated(uint256 newDripAmount);

    constructor() payable {
        owner = msg.sender;
        dripAmount = 2 ether; // Default drip amount
        cooldownTime = 3 minutes; // Default cooldown
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Meta-Transaction: Relayer calls this function with user's signature
    function requestTokens(
        address recipient,
        uint256 nonce,
        bytes calldata signature
    ) external {
        require(
            address(this).balance >= dripAmount,
            "Not enough funds in the faucet"
        );
        require(
            block.timestamp >= lastRequestTime[recipient] + cooldownTime,
            "Cooldown period has not passed"
        );

        // Verify user's signature
        bytes32 messageHash = keccak256(
            abi.encodePacked(recipient, nonce, address(this))
        );
        require(
            recoverSigner(messageHash, signature) == recipient,
            "Invalid signature"
        );

        // Update the last request time
        lastRequestTime[recipient] = block.timestamp;

        // Transfer tokens to the recipient
        payable(recipient).transfer(dripAmount);

        emit TokensDripped(recipient, dripAmount);
    }

    // Helper function to recover the signer of a message
    function recoverSigner(
        bytes32 messageHash,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    // Split a signature into r, s, and v
    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    // Owner can update the drip amount
    function updateDripAmount(uint256 _dripAmount) external onlyOwner {
        dripAmount = _dripAmount;
        emit DripAmountUpdated(_dripAmount);
    }

    // Owner can update the cooldown time
    function updateCooldownTime(uint256 _cooldownTime) external onlyOwner {
        cooldownTime = _cooldownTime;
        emit CooldownTimeUpdated(_cooldownTime);
    }

    receive() external payable {}

    // Owner can withdraw funds
    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough funds");
        payable(owner).transfer(amount);
    }
}
