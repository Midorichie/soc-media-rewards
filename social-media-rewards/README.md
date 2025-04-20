# Social Media Engagement Rewards

A blockchain-based reward system for social media engagement built on the Stacks blockchain using Clarity.

## Overview

This project implements a token reward system for users engaging with brand content on social media platforms. Users can earn tokens by engaging with content through comments, shares, likes, and content creation.

## Project Structure

- `contracts/` - Contains all Clarity smart contracts
  - `engagement-rewards.clar` - Main contract for managing rewards
  - `token.clar` - Fungible token contract for reward tokens
- `tests/` - Contains test files for contracts
- `settings/` - Contains deployment and chain settings

## Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet): Development environment for Clarity smart contracts
- [Git](https://git-scm.com/): Version control
- [Node.js](https://nodejs.org/): Required for some testing tools

## Installation

1. Clone the repository:
```bash
git clone https://github.com/midorichie/social-media-rewards.git
cd social-media-rewards
```

2. Install Clarinet (if not already installed):
```bash
# For macOS
brew install clarinet

# For Linux/Windows
curl -sSL https://github.com/hirosystems/clarinet/releases/latest/download/install.sh | bash
```

3. Initialize the project:
```bash
clarinet integrate
```

## Development

The project uses Clarinet for local development and testing. You can use the following commands:

- Run tests: `clarinet test`
- Start a console: `clarinet console`
- Check contract: `clarinet check`

## Key Features

- On-chain verification of social media engagement
- Token rewards based on engagement metrics
- Prevention of reward gaming and duplicate claims
- Admin controls for managing reward rates and parameters

## Smart Contract Architecture

### Engagement Rewards Contract
The main contract that tracks user engagement and manages rewards:
- Maps social media accounts to Stacks addresses
- Verifies engagement events
- Calculates and distributes rewards
- Implements admin controls

### Token Contract
A fungible token contract for the reward tokens:
- Implements SIP-010 fungible token standard
- Controlled minting based on verified engagement
- Transfer and balance tracking

## Usage

Detailed usage instructions for each function can be found in the contract documentation and the code comments.

## Deployment

1. Configure deployment settings in `Clarinet.toml`
2. Use Clarinet to deploy to testnet or mainnet:
```bash
clarinet deploy --testnet
```

## Security Considerations

- The contract includes mechanisms to prevent double-claiming rewards
- Rate limiting to prevent system abuse
- Verification of social media accounts to prevent impersonation

## License

[MIT License](LICENSE)
