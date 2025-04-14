// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDistributor {
    function deposit() external payable;
}

interface IRouter {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

contract Admin {
    address public owner;
    address public treasuryWallet;
    address public buyAndBurnContract;
    IDistributor public distributor;
    IRouter public router;

    address WPLS = 0xA1077a294dDE1B09bB078844df40758a5D0f9a27;

    uint256 public totalReceivedPLS;
    uint256 public totalToTreasury;
    uint256 public totalToBuyAndBurn;
    uint256 public totalDepositedToDistributor;
    uint256 public totalSwappedPLS;

    event TokenSwapped(address tokenOut, uint256 amountIn);
    event SentToDistributor(uint256 amount);
    event SentToBuyAndBurn(uint256 amount);
    event SentToTreasury(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(
        address _treasuryWallet,
        address _buyAndBurnContract,
        address _distributor,
        address _router
    ) {
        owner = msg.sender;
        treasuryWallet = _treasuryWallet;
        buyAndBurnContract = _buyAndBurnContract;
        distributor = IDistributor(_distributor);
        router = IRouter(_router);
    }

    // Send PLS to treasury wallet
    function sendToTreasury() external payable onlyOwner {
        require(msg.value > 0, "No PLS sent");
        totalReceivedPLS += msg.value;
        totalToTreasury += msg.value;

        (bool success, ) = payable(treasuryWallet).call{value: msg.value}("");
        require(success, "Treasury transfer failed");

        emit SentToTreasury(msg.value);
    }

    // Send PLS to buy-and-burn contract
    function sendToBuyAndBurn() external payable onlyOwner {
        require(msg.value > 0, "No PLS sent");
        totalReceivedPLS += msg.value;
        totalToBuyAndBurn += msg.value;

        (bool success, ) = payable(buyAndBurnContract).call{value: msg.value}(
            ""
        );
        require(success, "Buy & burn transfer failed");

        emit SentToBuyAndBurn(msg.value);
    }

    // Deposit PLS into distributor for dividends
    function depositToDistributor() external payable onlyOwner {
        require(msg.value > 0, "No PLS sent");
        totalReceivedPLS += msg.value;
        totalDepositedToDistributor += msg.value;

        distributor.deposit{value: msg.value}();

        emit SentToDistributor(msg.value);
    }

    // Swap PLS to token and send tokens to the caller
    function swapPLSForToken(
        uint amountOutMin,
        address tokenOut,
        uint256 deadline
    ) external payable onlyOwner {
        require(msg.value > 0, "No PLS sent");
        totalReceivedPLS += msg.value;
        totalSwappedPLS += msg.value;

        address[] memory pathFromPLSToToken = new address[](2);
        pathFromPLSToToken[0] = WPLS;
        pathFromPLSToToken[1] = tokenOut;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(
            amountOutMin,
            pathFromPLSToToken,
            msg.sender, // Tokens go to the caller
            deadline
        );

        emit TokenSwapped(tokenOut, msg.value);
    }

    function getAllStats()
        external
        view
        returns (
            uint256 received,
            uint256 treasury,
            uint256 burn,
            uint256 distributed,
            uint256 swapped
        )
    {
        return (
            totalReceivedPLS,
            totalToTreasury,
            totalToBuyAndBurn,
            totalDepositedToDistributor,
            totalSwappedPLS
        );
    }

    // Admin management
    function setTreasuryWallet(address _wallet) external onlyOwner {
        treasuryWallet = _wallet;
    }

    function setBuyAndBurnContract(address _contract) external onlyOwner {
        buyAndBurnContract = _contract;
    }

    function setDistributor(address _distributor) external onlyOwner {
        distributor = IDistributor(_distributor);
    }

    function setRouter(address _router) external onlyOwner {
        router = IRouter(_router);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    function emergencyWithdrawPLS(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No PLS");
        (bool success, ) = payable(to).call{value: balance}("");
        require(success, "Transfer failed");
    }
}
