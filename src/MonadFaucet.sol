// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract MonadFaucet {
    address public owner;
    uint256 public dripAmount;
    uint256 public cooldownTime;

    mapping(address => uint256) public lastRequestTime;

    event TokensDripped(address indexed recipient, uint256 amount);
    event CooldownTimeUpdated(uint256 newCooldownTime);
    event DripAmountUpdated(uint256 newDripAmount);

    constructor() payable {
        owner = msg.sender;
        dripAmount = 1 ether;
        cooldownTime = 1 minutes;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function requestTokens() external {
        require(
            address(this).balance >= dripAmount,
            "Not enough funds in the faucet"
        );
        require(
            block.timestamp >= lastRequestTime[msg.sender] + cooldownTime,
            "Cooldown period has not passed"
        );

        lastRequestTime[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(dripAmount);

        emit TokensDripped(msg.sender, dripAmount);
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
