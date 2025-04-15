// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRouter {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract BuyAndBurn {
    address public owner;
    address public burnToken;
    IRouter public router;

    address public constant DEAD_ADDRESS = 0x0000000000000000000000000000000000000000;
    address WPLS = 0xA1077a294dDE1B09bB078844df40758a5D0f9a27;

    event BurnExecuted(uint256 amountBurned);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _burnToken, address _router) {
        owner = msg.sender;
        burnToken = _burnToken;
        router = IRouter(_router);
    }

    function buyAndBurn(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= amount, "No PLS to use");

        address[] memory path = new address[](2);
        path[0] = WPLS;
        path[1] = burnToken;

        // Swap PLS to burnToken and send directly to this contract
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 burnAmount = IERC20(burnToken).balanceOf(address(this));
        require(burnAmount > 0, "Nothing to burn");

        // Send all tokens to dead address
        IERC20(burnToken).transfer(DEAD_ADDRESS, burnAmount);

        emit BurnExecuted(burnAmount);
    }

    function getPLSBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function setRouter(address _router) external onlyOwner {
        router = IRouter(_router);
    }

    function setBurnToken(address _token) external onlyOwner {
        burnToken = _token;
    }

    function setWPLS(address _wpls) external onlyOwner {
        WPLS = _wpls;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    function emergencyWithdrawToken(address token, address to) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, bal);
    }

    receive() external payable {}

    fallback() external payable {}
}