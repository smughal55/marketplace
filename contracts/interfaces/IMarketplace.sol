// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IMarketplace {
    /// @notice Represents a Provider in the system
    /// @param fee The monthly fee charged by the provider
    /// @param balance The balance accumulated by the provider
    /// @param subscriberCount The number of subscribers subscribed to the provider
    /// @param active The state of the provider, whether active or inactive
    /// @param owner The address of the provider's owner
    struct Provider {
        uint256 fee; // 32 bytes
        uint256 balance; // 32 bytes
        uint32 subscriberCount; // 4 bytes (reduced from uint256 to save space)
        bool active; // 1 byte
        address owner; // 20 bytes
        // The remaining 7 bytes are padding to align with a full 32-byte storage slot
    }

    /// @notice Represents a Subscriber in the system
    /// @param owner The address of the subscriber's owner
    /// @param balance The balance deposited by the subscriber
    /// @param subscribedProviderIds The list of provider IDs the subscriber is subscribed to
    struct Subscriber {
        address owner; // 20 bytes
        uint256 balance; // 32 bytes
        uint256[] subscribedProviderIds; // Dynamic array
    }

    // Error codes
    error Marketplace__ZeroAddress();
    error Marketplace__Max_Providers_Reached();
    error Marketplace__Provider_Already_Registered();
    error Marketplace__Fee_Below_Minimum();
    error Marketplace__Only_Provider_Owner_Can_Remove();
    error Marketplace__No_Providers_Specified();
    error Marketplace__Deposit_Below_Minimum();
    error Marketplace__Provider_Not_Active();
    error Marketplace__Insufficient_Deposit();
    error Marketplace__Transfer_Failed();
    error Marketplace__Only_Subscriber_Owner_Can_Increase_Deposit();
    error Marketplace__Only_Provider_Owner_Can_Withdraw();
    error Marketplace__Stale_Price_Feed();
    error Marketplace__Invalid_Price();

    // Events

    /// @notice Emitted when a new provider is registered
    /// @param providerId The ID of the provider
    /// @param owner The address of the provider's owner
    /// @param fee The fee charged by the provider
    event ProviderRegistered(
        uint256 indexed providerId,
        address indexed owner,
        uint256 fee
    );

    /// @notice Emitted when a provider is removed
    /// @param providerId The ID of the provider
    /// @param owner The address of the provider's owner
    event ProviderRemoved(uint256 indexed providerId, address indexed owner);

    /// @notice Emitted when a new subscriber is registered
    /// @param subscriberId The ID of the subscriber
    /// @param owner The address of the subscriber's owner
    event SubscriberRegistered(
        uint256 indexed subscriberId,
        address indexed owner
    );

    /// @notice Emitted when a subscriber increases their deposit
    /// @param subscriberId The ID of the subscriber
    /// @param amount The amount added to the subscriber's balance
    event SubscriptionDepositIncreased(
        uint256 indexed subscriberId,
        uint256 amount
    );

    /// @notice Emitted when a provider withdraws their earnings
    /// @param providerId The ID of the provider
    /// @param amount The amount withdrawn by the provider
    /// @param usdEquivalent The USD equivalent of the amount withdrawn
    event ProviderEarningsWithdrawn(
        uint256 indexed providerId,
        uint256 amount,
        uint256 usdEquivalent
    );

    // Provider Functions

    /// @notice Registers a new provider with the system
    /// @param providerId The ID of the provider
    /// @param fee The monthly fee charged by the provider
    function registerProvider(uint256 providerId, uint256 fee) external;

    /// @notice Removes a provider from the system
    /// @param providerId The ID of the provider
    function removeProvider(uint256 providerId) external;

    // Subscriber Functions

    /// @notice Registers a new subscriber with the system
    /// @param subscriberId The ID of the subscriber
    /// @param providerIds The list of provider IDs the subscriber wants to register with
    function registerSubscriber(
        uint256 subscriberId,
        uint256[] calldata providerIds
    ) external;

    /// @notice Increases the balance of a subscriber's deposit
    /// @param subscriberId The ID of the subscriber
    /// @param amount The amount to add to the subscriber's deposit
    function increaseSubscriptionDeposit(
        uint256 subscriberId,
        uint256 amount
    ) external;

    // Provider Earnings

    /// @notice Withdraws the earnings of a provider
    /// @param providerId The ID of the provider
    function withdrawProviderEarnings(uint256 providerId) external;

    // Provider State Management

    /// @notice Updates the state of a provider (active/inactive)
    /// @param providerId The ID of the provider
    /// @param state The new state of the provider (true for active, false for inactive)
    function updateProviderState(uint256 providerId, bool state) external;

    // View Functions

    /// @notice Gets the state of a provider
    /// @param providerId The ID of the provider
    /// @return subscriberAmount The number of subscribers for the provider
    /// @return fee The fee charged by the provider
    /// @return owner The address of the provider's owner
    /// @return balance The balance of the provider
    /// @return active Whether the provider is active or inactive
    function getProviderState(
        uint256 providerId
    )
        external
        view
        returns (
            uint256 subscriberAmount,
            uint256 fee,
            address owner,
            uint256 balance,
            bool active
        );

    /// @notice Gets the earnings of a provider
    /// @param providerId The ID of the provider
    /// @return balance The earnings balance of the provider
    function getProviderEarnings(
        uint256 providerId
    ) external view returns (uint256 balance);

    /// @notice Gets the state of a subscriber
    /// @param subscriberId The ID of the subscriber
    /// @return owner The address of the subscriber's owner
    /// @return balance The balance of the subscriber
    /// @return subscribedProviderIds The list of provider IDs the subscriber is subscribed to
    function getSubscriberState(
        uint256 subscriberId
    )
        external
        view
        returns (
            address owner,
            uint256 balance,
            uint256[] memory subscribedProviderIds
        );

    /// @notice Gets the live balance of a subscriber, minus the fees for the subscribed providers
    /// @param subscriberId The ID of the subscriber
    /// @return liveBalance The live balance of the subscriber
    function getLiveSubscriberBalance(
        uint256 subscriberId
    ) external view returns (uint256 liveBalance);

    /// @notice Gets the USD value of a subscriber's deposit
    /// @param subscriberId The ID of the subscriber
    /// @return depositValueUSD The USD value of the subscriber's deposit
    function getSubscriberDepositValueUSD(
        uint256 subscriberId
    ) external view returns (uint256 depositValueUSD);
}
