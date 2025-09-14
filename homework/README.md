# homework

## Mainnet

### wallet `0x06cbb71892bde5d50ab0f2b373335820376ed4cbae697f8cfe89cd52c1b40ecf`

- Smart Contract on Mainnet: [0x010720d83b8d4d788d79c1f35b15e085747c1bfd321d7c992bdeb17c7304d824](https://voyager.online/contract/0x010720d83b8d4d788d79c1f35b15e085747c1bfd321d7c992bdeb17c7304d824)
  - Declaration TX: [0x0403488a3fefd937919708b9e7f6bbb3924e8a2764d30fa888e648c045574c21](https://voyager.online/tx/0x403488a3fefd937919708b9e7f6bbb3924e8a2764d30fa888e648c045574c21)
  - Deployment TX: [0x07fdf16ee22753bbf607015c8b970f0c91c8e6124f5b2a3bf15cfa361102b2bb](https://voyager.online/tx/0x7fdf16ee22753bbf607015c8b970f0c91c8e6124f5b2a3bf15cfa361102b2bb)
  - [smart contract](./counter/README.md)
  - [mainnet deployment](./counter/scripts/mainnet-deployment.json)

- [front]()

### Response from Cairo Coder:

```cairo
// Define the contract interface
#[starknet::interface]
pub trait ICounter<TContractState> {
    fn increment(ref self: TContractState);
    fn get_count(self: @TContractState) -> u64;
}

// Define the contract module
#[starknet::contract]
pub mod Counter {
    // Always import all storage imports
    use starknet::storage::*;

    // Define storage variables
    #[storage]
    pub struct Storage {
        count: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_value: u64) {
        self.count.write(initial_value);
    }

    // Implement the contract interface
    #[abi(embed_v0)]
    pub impl CounterImpl of super::ICounter<ContractState> {
        // Increment the counter by 1
        fn increment(ref self: ContractState) {
            let current_count = self.count.read();
            self.count.write(current_count + 1);
        }

        // Retrieve the current counter value
        fn get_count(self: @ContractState) -> u64 {
            self.count.read()
        }
    }
}
```

### Interacting with the contract:

Read counter:

```shell
starkli call 0x06998ece6d202b1b88444ff2fd9aa21b0d619dd121c44ad19a36e5aa73539676 get_counter --network mainnet
```

Increment:

```shell
starkli invoke 0x06998ece6d202b1b88444ff2fd9aa21b0d619dd121c44ad19a36e5aa73539676 increment --network mainnet --keystore /Users/aquental/.starkli-wallets/mainnet-keystore.json --account /Users/aquental/.starkli-wallets/account.json
```

Decrement:

```shell
starkli invoke 0x06998ece6d202b1b88444ff2fd9aa21b0d619dd121c44ad19a36e5aa73539676 decrement --network mainnet --keystore /Users/aquental/.starkli-wallets/mainnet-keystore.json --account /Users/aquental/.starkli-wallets/account.json
```
