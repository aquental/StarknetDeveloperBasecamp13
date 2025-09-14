# homework

## Mainnet

- wallet `0x06cbb71892bde5d50ab0f2b373335820376ed4cbae697f8cfe89cd52c1b40ecf`
- [mainnet contract](https://voyager.online/contract/0x06998ece6d202b1b88444ff2fd9aa21b0d619dd121c44ad19a36e5aa73539676)
- [smart contract](./counter/README.md)
- [front]()

---

Response from Cairo Coder:

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
