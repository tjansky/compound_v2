// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    mapping(address => bool) public authorizedCallers;
    address public owner;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    event DividendClaimed(address indexed shareholder, uint256 amount);

    modifier onlyAuthorized() {
        require(authorizedCallers[msg.sender], "Not authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        authorizedCallers[msg.sender] = true;
        owner = msg.sender;
    }

    /** 
     * @dev Sets share amount for a shareholder while preserving unclaimed dividends.
     */
    function setShare(address shareholder, uint256 amount) external override onlyAuthorized {
        if (shares[shareholder].amount > 0) {
            // Preserve unclaimed earnings before updating shares
            uint256 unclaimed = getUnpaidEarnings(shareholder);
            shares[shareholder].totalExcluded = shares[shareholder].totalExcluded.add(unclaimed);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
    }

    /**
     * @dev Allows users to claim their dividends manually.
    */
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    /**
     * @dev Deposits dividends into the contract and distributes them proportionally.
    */
    function deposit() external payable override onlyAuthorized {
        require(msg.value > 0, "No PLS sent");

        totalDividends = totalDividends.add(msg.value);
        if (totalShares > 0) {
            dividendsPerShare = dividendsPerShare.add(
                dividendsPerShareAccuracyFactor.mul(msg.value).div(totalShares)
            );
        }
    }

    /**
     * @dev Distributes the unpaid earnings of a shareholder.
     */
    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) { return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = shares[shareholder].totalExcluded.add(amount);

            emit DividendClaimed(shareholder, amount);

            (bool success, ) = payable(shareholder).call{value: amount}("");
            require(success, "PLS transfer failed");
        }
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) { return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) { return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    /**
     * @dev Returns the cumulative dividends for a given share amount.
     */
    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    /**
     * @dev Adds a shareholder to the shareholders list.
     */
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    /**
     * @dev Removes a shareholder from the shareholders list.
     */
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function getTotalDistributed() external view returns (uint256) {
        return totalDistributed;
    }

    function getClaimedDividends(address shareholder) external view returns (uint256) {
        return shares[shareholder].totalRealised;
    }

    function addAuthorizedCaller(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        require(!authorizedCallers[account], "Already authorized");

        authorizedCallers[account] = true;
    }

    function removeAuthorizedCaller(address account) external onlyOwner {
        require(authorizedCallers[account], "Address not authorized");

        authorizedCallers[account] = false;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }
}