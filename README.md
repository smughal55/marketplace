# Marketplace Smart Contract

## Overview

The **Marketplace** smart contract models a provider-subscriber system where providers can offer services for a monthly fee and subscribers can register to use these services. The contract uses an ERC20 token as the payment medium and includes mechanisms for providers to withdraw earnings, subscribers to manage their deposits, and the contract owner to manage the state of providers.

The contract is upgradeable using the UUPS proxy pattern, ensuring that future improvements can be implemented without requiring a complete redeployment of the contract.

## Features

- **Provider Registration:** Providers can register with a unique ID and a fee, which must be above a minimum threshold.
- **Subscriber Registration:** Subscribers can register and subscribe to multiple providers, depositing an amount above a set minimum.
- **Subscription Management:** Subscribers can increase their deposits, and providers can withdraw their earnings.
- **Provider State Management:** The contract owner can update the state of providers (active or inactive).
- **Upgradeable Contract:** The contract is upgradeable using the UUPS pattern, with role-based access control to manage upgrades.

## Smart Contract Architecture

### Structs

- **Provider:**
  - `uint256 fee`: The fee charged by the provider for the service.
  - `uint256 balance`: The balance accumulated from subscriber payments.
  - `uint256 subscriberCount`: The number of subscribers registered with the provider.
  - `address owner`: The owner of the provider.
  - `bool active`: The current state of the provider (active/inactive).

- **Subscriber:**
  - `address owner`: The owner of the subscriber account.
  - `uint256 balance`: The balance deposited by the subscriber.
  - `uint256[] subscribedProviderIds`: A list of provider IDs the subscriber is registered with.

### Main Contract Functions

- **registerProvider(uint256 providerId, uint256 fee):** Registers a new provider with a unique ID and fee. The fee must meet a minimum USD value, verified through a Chainlink price feed.

- **removeProvider(uint256 providerId):** Allows a provider to deregister and withdraw their balance. Only the provider owner can call this function.

- **registerSubscriber(uint256 subscriberId, uint256[] calldata providerIds):** Registers a subscriber and associates them with multiple providers. The subscriber must deposit an amount above a minimum USD value.

- **increaseSubscriptionDeposit(uint256 subscriberId, uint256 amount):** Allows a subscriber to increase their deposit balance.

- **withdrawProviderEarnings(uint256 providerId):** Allows providers to withdraw their accumulated earnings. The function calculates the USD equivalent of the withdrawn amount using a Chainlink price feed.

- **updateProviderState(uint256 providerId, bool state):** Allows the contract owner to update the state of a provider (active/inactive).

### View Functions

- **getProviderState(uint256 providerId):** Returns the state of a provider, including the number of subscribers, fee, owner, balance, and active status.

- **getProviderEarnings(uint256 providerId):** Returns the current balance of a provider.

- **getSubscriberState(uint256 subscriberId):** Returns the state of a subscriber, including the owner, balance, and subscribed providers.

- **getLiveSubscriberBalance(uint256 subscriberId):** Returns the live balance of a subscriber, which is the deposit balance minus the fees expected to be charged by providers.

- **getSubscriberDepositValueUSD(uint256 subscriberId):** Returns the current USD value of a subscriber's deposit based on the latest Chainlink price data.

## Security Considerations

- **Reentrancy Protection:** The contract follows best practices by ensuring that state changes are made before external calls to prevent reentrancy attacks. However, it is recommended to add `ReentrancyGuard` for additional protection.
  
- **Access Control:** Functions that alter critical contract states are protected by access control modifiers (`onlyOwner`, `onlyRole(UPGRADER_ROLE)`), ensuring that only authorized accounts can execute them.

- **Upgradeable Contract:** The UUPS pattern is used for upgradeability, with the `_authorizeUpgrade` function protected by a role-based access control mechanism.

- **Price Feed Integrity:** The contract relies on Chainlink's price feed for USD conversions, ensuring that the price data is fresh and reliable.

## Gas Optimization

- **Storage Usage:** The contract efficiently manages storage through mappings, which are optimized for gas usage.
  
- **Looping Considerations:** Functions that loop through arrays, like `getLiveSubscriberBalance`, should be used carefully as the size of these arrays can impact gas costs.

- **Event Emissions:** The contract emits events after state changes to facilitate off-chain tracking, balancing between necessary data and gas efficiency.

Ensure that the appropriate environment variables are set for network configuration, including the `paymentToken` and `priceFeed` addresses.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.