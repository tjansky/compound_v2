// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IPRC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IDistributor {
    function setShares(address user, uint256 amount) external;
}

contract Staking {
    IPRC20 public stakingToken;
    IDistributor public distributor;

    mapping(address => uint256) public balances;
    uint256 public totalStaked;

    event Staked(address indexed user, uint256 amount, uint256 totalStaked);
    event Unstaked(address indexed user, uint256 amount, uint256 totalStaked);

    constructor(address _stakingToken, address _distributor) {
        stakingToken = IPRC20(_stakingToken);
        distributor = IDistributor(_distributor);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");

        stakingToken.transferFrom(msg.sender, address(this), amount);

        balances[msg.sender] += amount;
        totalStaked += amount;

        distributor.setShares(msg.sender, balances[msg.sender]);

        emit Staked(msg.sender, amount, totalStaked);
    }

    function unstake(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough staked");

        balances[msg.sender] -= amount;
        totalStaked -= amount;

        stakingToken.transfer(msg.sender, amount);

        distributor.setShares(msg.sender, balances[msg.sender]);

        emit Unstaked(msg.sender, amount, totalStaked);
    }

    function getStaked(address user) external view returns (uint256) {
        return balances[user];
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }
}