// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract MonadFaucet {
    address public owner;
    address public relayer;
    uint256 public dripAmount;
    uint256 public cooldownTime;

    mapping(address => uint256) public lastRequestTime;

    event TokensDripped(address indexed recipient, uint256 amount);
    event CooldownTimeUpdated(uint256 newCooldownTime);
    event DripAmountUpdated(uint256 newDripAmount);
    event RelayerUpdated(address newRelayer);

    constructor(address _relayer) payable {
        owner = msg.sender;
        relayer = _relayer;
        dripAmount = 1 ether;
        cooldownTime = 1 minutes;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyRelayer() {
        require(msg.sender == relayer, "Only relayer can call this function");
        _;
    }

    // Update the relayer address (only callable by the owner)
    function updateRelayer(address _newRelayer) external onlyOwner {
        require(_newRelayer != address(0), "Invalid relayer address");
        relayer = _newRelayer;
        emit RelayerUpdated(_newRelayer);
    }

    // Request tokens with a signed message from the relayer
    function requestTokens(
        address recipient,
        bytes memory signature
    ) external onlyRelayer {
        require(
            address(this).balance >= dripAmount,
            "Not enough funds in the faucet"
        );
        require(
            block.timestamp >= lastRequestTime[recipient] + cooldownTime,
            "Cooldown period has not passed"
        );

        // Verify the signed message
        bytes32 messageHash = keccak256(abi.encodePacked(recipient));
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        address signer = recoverSigner(ethSignedMessageHash, signature);
        require(signer == relayer, "Invalid signature");

        lastRequestTime[recipient] = block.timestamp;
        payable(recipient).transfer(dripAmount);

        emit TokensDripped(recipient, dripAmount);
    }

    // Helper function to recover the signer address from the signature
    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // Helper function to split the signature into r, s, and v components
    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function updateDripAmount(uint256 _dripAmount) external onlyOwner {
        dripAmount = _dripAmount;
        emit DripAmountUpdated(_dripAmount);
    }

    function updateCooldownTime(uint256 _cooldownTime) external onlyOwner {
        cooldownTime = _cooldownTime;
        emit CooldownTimeUpdated(_cooldownTime);
    }

    receive() external payable {}

    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough funds");
        payable(owner).transfer(amount);
    }
}
