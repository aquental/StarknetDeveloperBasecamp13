# Counter Smart Contract

A simple counter smart contract written in Cairo for Starknet, demonstrating basic state management, constructor initialization, and safe arithmetic operations.

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Scarb**: `v2.12.1` or higher
- **Cairo**: `v2.12.1` or higher
- **Starknet Foundry** (for testing): Automatically configured with `snforge`
- **Starkli** (optional, for deployment): Install via `curl https://get.starkli.sh | sh`

### Verify Installation

```bash
scarb --version
# Expected output: scarb 2.12.1 (or higher)
```

## 🚀 Quick Start

### 1. Initialize the Project

This project was initialized using Scarb with the following command:

```bash
scarb init --name counter
```

### 2. Build the Contract

Compile the smart contract to generate Sierra and CASM artifacts:

```bash
scarb build
```

### 3. Run Tests

Execute all unit and integration tests:

```bash
scarb test
```

You can also run tests with coverage (if configured):

```bash
snforge test
```

## 📁 Project Structure

```
counter/
├── Scarb.toml                 # Project configuration and dependencies
├── Scarb.lock                # Lock file for dependencies
├── snfoundry.toml            # Starknet Foundry configuration
├── README.md                 # This file
├── src/
│   ├── lib.cairo            # Library root that exports modules
│   ├── counter.cairo        # Main counter contract implementation
│   └── tests.cairo          # Unit tests for the counter contract
├── tests/
│   └── test_contract.cairo  # Integration tests
└── target/                   # Build artifacts (generated after building)
    └── dev/
        ├── counter.contract_class.json
        ├── counter.compiled_contract_class.json
        └── ...
```

## 📝 Contract Overview

The Counter contract provides a simple incrementing/decrementing counter with the following features:

### Storage

- `counter: u32` - Stores the current counter value

### Functions

#### Constructor
```cairo
fn constructor(ref self: ContractState, initial_value: u32)
```
Initializes the counter with a specified starting value.

#### View Functions
```cairo
fn get_counter(self: @ContractState) -> u32
```
Returns the current value of the counter without modifying state.

#### State-Modifying Functions
```cairo
fn increment(ref self: ContractState)
```
Increases the counter value by 1.

```cairo
fn decrement(ref self: ContractState)
```
Decreases the counter value by 1. Panics if the counter is already at 0 to prevent underflow.

### Interface

The contract implements the `ICounter` interface, making it easy to interact with from other contracts or through dispatchers.

## 🔧 Development

### Building the Contract

```bash
# Build the contract (generates Sierra and CASM)
scarb build

# The artifacts will be in:
# - target/dev/counter_Counter.contract_class.json (Sierra)
# - target/dev/counter_Counter.compiled_contract_class.json (CASM)
```

### Testing

The project includes comprehensive test coverage:

#### Unit Tests (src/tests.cairo)
- Constructor initialization with zero and custom values
- Single and multiple increment operations
- Single and multiple decrement operations
- Underflow protection
- Mixed operations
- Large number handling

#### Integration Tests (tests/test_contract.cairo)
- Contract deployment and interaction
- Safe dispatcher usage for error handling

Run tests with:
```bash
# Using Scarb (recommended)
scarb test

# Using Starknet Foundry directly
snforge test

# Run specific test
snforge test test_increment_from_zero

# Run with verbose output
snforge test -v
```

### Code Coverage

To enable code coverage, uncomment the following in `Scarb.toml`:

```toml
[profile.dev.cairo]
unstable-add-statements-code-locations-debug-info = true
unstable-add-statements-functions-debug-info = true
inlining-strategy = "avoid"
```

Then run:
```bash
snforge test --coverage
```

## 🚢 Deployment

### Prerequisites for Deployment

1. Install Starkli:
```bash
curl https://get.starkli.sh | sh
starkliup
```

2. Set up your account and keystore:
```bash
# Create a keystore for your account
starkli signer keystore from-key ~/.starkli-wallets/deployer.json

# Create an account descriptor
starkli account fetch <YOUR_ACCOUNT_ADDRESS> --output ~/.starkli-wallets/account.json
```

### Deploy to Starknet Testnet

1. Set environment variables:
```bash
export STARKNET_ACCOUNT=~/.starkli-wallets/account.json
export STARKNET_KEYSTORE=~/.starkli-wallets/deployer.json
```

2. Declare the contract:
```bash
starkli declare target/dev/counter_Counter.contract_class.json \
    --network sepolia \
    --compiler-version 2.12.1
```

3. Deploy the contract (with initial value of 0):
```bash
starkli deploy <CLASS_HASH> \
    --constructor-calldata 0 \
    --network sepolia
```

### Deploy to Local Network (Katana)

1. Start a local Starknet node:
```bash
katana
```

2. In another terminal, deploy:
```bash
starkli declare target/dev/counter_Counter.contract_class.json \
    --rpc http://localhost:5050

starkli deploy <CLASS_HASH> \
    --constructor-calldata 0 \
    --rpc http://localhost:5050
```

## 💻 Usage Examples

### Interacting with Deployed Contract

Once deployed, you can interact with the contract using Starkli:

#### Read the counter value:
```bash
starkli call <CONTRACT_ADDRESS> \
    get_counter \
    --network sepolia
```

#### Increment the counter:
```bash
starkli invoke <CONTRACT_ADDRESS> \
    increment \
    --network sepolia
```

#### Decrement the counter:
```bash
starkli invoke <CONTRACT_ADDRESS> \
    decrement \
    --network sepolia
```

### Using in Another Contract

```cairo
use counter::counter::{ICounterDispatcher, ICounterDispatcherTrait};

#[starknet::contract]
mod MyContract {
    use super::{ICounterDispatcher, ICounterDispatcherTrait};
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        counter_address: ContractAddress,
    }

    #[external(v0)]
    fn use_counter(self: @ContractState) {
        let counter = ICounterDispatcher { 
            contract_address: self.counter_address.read() 
        };
        
        // Read current value
        let current = counter.get_counter();
        
        // Increment
        counter.increment();
        
        // Decrement (if > 0)
        if current > 0 {
            counter.decrement();
        }
    }
}
```

## 🧪 Testing Guidelines

When writing tests for this contract:

1. **Test initialization**: Verify the constructor sets the correct initial value
2. **Test state changes**: Ensure increment/decrement modify state correctly
3. **Test edge cases**: Verify underflow protection works
4. **Test view functions**: Confirm read operations don't modify state
5. **Use safe dispatchers**: For testing panic conditions

Example test pattern:
```cairo
#[test]
fn test_example() {
    let contract_address = deploy_counter(10);
    let dispatcher = ICounterDispatcher { contract_address };
    
    // Test logic here
    assert(dispatcher.get_counter() == 10, 'Wrong initial value');
}
```

## 📚 Additional Resources

- [Cairo Book](https://book.cairo-lang.org/) - Learn Cairo programming
- [Starknet Documentation](https://docs.starknet.io/) - Official Starknet docs
- [Scarb Documentation](https://docs.swmansion.com/scarb/) - Scarb package manager docs
- [Starknet Foundry Book](https://foundry-rs.github.io/starknet-foundry/) - Testing framework documentation
- [Starkli Book](https://book.starkli.rs/) - CLI tool for Starknet interaction
- [Cairo Examples](https://github.com/starkware-libs/cairo/tree/main/examples) - Official Cairo examples
- [OpenZeppelin Contracts for Cairo](https://github.com/OpenZeppelin/cairo-contracts) - Standard contract implementations

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 🙋 Support

If you have any questions or run into issues, please:
1. Check the [Cairo Discord](https://discord.gg/starknet)
2. Review the [Starknet community forum](https://community.starknet.io/)
3. Open an issue in this repository

---

**Happy Coding! 🚀**