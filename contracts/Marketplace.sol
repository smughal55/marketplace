// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IMarketplace} from "./interfaces/IMarketplace.sol";
import {OracleLib} from "./libs/OracleLib.sol";

contract Marketplace is
    IMarketplace,
    Initializable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    ///////////////////
    // Types
    ///////////////////
    using OracleLib for AggregatorV3Interface;

    ERC20Upgradeable private paymentToken;
    AggregatorV3Interface private priceFeed;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 private constant MIN_PROVIDER_FEE_USD = 50 * 10 ** 18; // $50 in USD
    uint256 private constant MIN_SUBSCRIBER_DEPOSIT_USD = 100 * 10 ** 18; // $100 in USD
    uint256 private constant MAX_PROVIDERS = 200;

    mapping(uint256 => Provider) private providers;
    mapping(uint256 => Subscriber) private subscribers;

    uint256 private providerCount;
    uint256 private subscriberCount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*
     * @notice Initializes the contract with the payment token and price feed
     * @param _paymentToken The address of the payment token
     * @param _priceFeed The address of the price feed
     */
    function initialize(
        address _paymentToken,
        address _priceFeed
    ) public initializer {
        require(_paymentToken != address(0), Marketplace__ZeroAddress());
        require(_priceFeed != address(0), Marketplace__ZeroAddress());
        __Ownable_init(msg.sender);
        __AccessControl_init();
        __UUPSUpgradeable_init();

        grantRole(UPGRADER_ROLE, msg.sender);
        paymentToken = ERC20Upgradeable(_paymentToken);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /// @inheritdoc IMarketplace
    function registerProvider(
        uint256 providerId,
        uint256 fee
    ) external override {
        require(
            providerCount < MAX_PROVIDERS,
            Marketplace__Max_Providers_Reached()
        );
        require(
            providers[providerId].owner == address(0),
            Marketplace__Provider_Already_Registered()
        );

        uint256 feeInUSD = _getTokenAmountInUSD(fee);
        require(
            feeInUSD >= MIN_PROVIDER_FEE_USD,
            Marketplace__Fee_Below_Minimum()
        );

        providers[providerId] = Provider({
            fee: fee,
            balance: 0,
            subscriberCount: 0,
            active: true,
            owner: msg.sender
        });
        providerCount++;

        emit ProviderRegistered(providerId, msg.sender, fee);
    }

    /// @inheritdoc IMarketplace
    function removeProvider(uint256 providerId) external override {
        Provider storage provider = providers[providerId];
        require(
            msg.sender == provider.owner,
            Marketplace__Only_Provider_Owner_Can_Remove()
        );

        uint256 balance = provider.balance;
        providerCount--;

        delete providers[providerId];

        bool success = paymentToken.transfer(msg.sender, balance);
        require(success, Marketplace__Transfer_Failed());

        emit ProviderRemoved(providerId, msg.sender);
    }

    /// @inheritdoc IMarketplace
    function registerSubscriber(
        uint256 subscriberId,
        uint256[] calldata providerIds
    ) external override nonReentrant {
        require(providerIds.length > 0, Marketplace__No_Providers_Specified());
        uint256 deposit = paymentToken.balanceOf(msg.sender);
        uint256 remainingDeposit = deposit;
        uint256 depositInUSD = _getTokenAmountInUSD(deposit);
        require(
            depositInUSD >= MIN_SUBSCRIBER_DEPOSIT_USD * 2,
            Marketplace__Deposit_Below_Minimum()
        );

        for (uint256 i = 0; i < providerIds.length; ) {
            uint256 providerId = providerIds[i];
            Provider storage provider = providers[providerId];
            require(provider.active, Marketplace__Provider_Not_Active());
            require(
                remainingDeposit >= provider.fee,
                Marketplace__Insufficient_Deposit()
            );
            remainingDeposit -= provider.fee;
            provider.balance += provider.fee;
            provider.subscriberCount++;
            unchecked {
                ++i;
            }
        }

        subscribers[subscriberId] = Subscriber({
            owner: msg.sender,
            balance: deposit,
            subscribedProviderIds: providerIds
        });
        subscriberCount++;

        bool success = paymentToken.transferFrom(
            msg.sender,
            address(this),
            deposit
        );
        require(success, Marketplace__Transfer_Failed());

        emit SubscriberRegistered(subscriberId, msg.sender);
    }

    /// @inheritdoc IMarketplace
    function increaseSubscriptionDeposit(
        uint256 subscriberId,
        uint256 amount
    ) external override nonReentrant {
        Subscriber storage subscriber = subscribers[subscriberId];
        require(
            msg.sender == subscriber.owner,
            Marketplace__Only_Subscriber_Owner_Can_Increase_Deposit()
        );

        subscriber.balance += amount;
        bool success = paymentToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success, Marketplace__Transfer_Failed());

        emit SubscriptionDepositIncreased(subscriberId, amount);
    }

    /// @inheritdoc IMarketplace
    function withdrawProviderEarnings(
        uint256 providerId
    ) external override nonReentrant {
        Provider storage provider = providers[providerId];
        require(
            msg.sender == provider.owner,
            Marketplace__Only_Provider_Owner_Can_Withdraw()
        );

        uint256 earnings = provider.balance;
        provider.balance = 0;

        uint256 usdEquivalent = _getTokenAmountInUSD(earnings);

        bool success = paymentToken.transfer(provider.owner, earnings);
        require(success, Marketplace__Transfer_Failed());

        emit ProviderEarningsWithdrawn(providerId, earnings, usdEquivalent);
    }

    /// @inheritdoc IMarketplace
    function updateProviderState(
        uint256 providerId,
        bool state
    ) external override onlyOwner {
        Provider storage provider = providers[providerId];
        provider.active = state;
    }

    // View Functions
    /// @inheritdoc IMarketplace
    function getProviderState(
        uint256 providerId
    )
        external
        view
        override
        returns (
            uint256 subscriberAmount,
            uint256 fee,
            address owner,
            uint256 balance,
            bool active
        )
    {
        Provider storage provider = providers[providerId];
        return (
            provider.subscriberCount,
            provider.fee,
            provider.owner,
            provider.balance,
            provider.active
        );
    }

    /// @inheritdoc IMarketplace
    function getProviderEarnings(
        uint256 providerId
    ) external view override returns (uint256 balance) {
        Provider storage provider = providers[providerId];
        return provider.balance;
    }

    /// @inheritdoc IMarketplace
    function getSubscriberState(
        uint256 subscriberId
    )
        external
        view
        override
        returns (
            address owner,
            uint256 balance,
            uint256[] memory subscribedProviderIds
        )
    {
        Subscriber storage subscriber = subscribers[subscriberId];
        return (
            subscriber.owner,
            subscriber.balance,
            subscriber.subscribedProviderIds
        );
    }

    /// @inheritdoc IMarketplace
    function getLiveSubscriberBalance(
        uint256 subscriberId
    ) external view override returns (uint256 liveBalance) {
        Subscriber memory subscriber = subscribers[subscriberId];
        uint256 subProvLen = subscriber.subscribedProviderIds.length;
        uint256 totalFee = 0;
        for (uint256 i; i < subProvLen; ) {
            uint256 providerId = subscriber.subscribedProviderIds[i];
            totalFee += providers[providerId].fee;
            unchecked {
                ++i;
            }
        }
        return subscriber.balance - totalFee;
    }

    /// @inheritdoc IMarketplace
    function getSubscriberDepositValueUSD(
        uint256 subscriberId
    ) external view override returns (uint256 depositValueUSD) {
        Subscriber memory subscriber = subscribers[subscriberId];
        return _getTokenAmountInUSD(subscriber.balance);
    }

    // Internal Functions
    function _getTokenAmountInUSD(
        uint256 tokenAmount
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.staleCheckLatestRoundData();

        uint256 adjustedPrice = uint256(price) *
            10 ** (18 - priceFeed.decimals());
        return (tokenAmount * adjustedPrice) / 10 ** 18;
    }

    // UUPS Upgradeability
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}
}
