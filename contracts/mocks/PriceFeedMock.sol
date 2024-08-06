// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PriceFeedMock {
    int256 private _price;
    uint8 private _decimals;

    constructor() {
        _price = 2000 * 10 ** 8; // Example price (e.g., $2000 with 8 decimals)
        _decimals = 8; // Typical Chainlink price feed has 8 decimals
    }

    function setPrice(int256 newPrice) public {
        _price = newPrice;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, _price, block.timestamp, block.timestamp, 0);
    }

    function staleCheckLatestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return latestRoundData();
    }
}
