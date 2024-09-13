## Transactions of type 113 (0x71)
This type of transaction happens in ``zkSync`` when we use **Account Abstraction**

### Phase 1: Validation
- User sends a transaction: You, as the user, send a transaction through zkSync using something called an "API client." Think of this as a lightweight helper that connects you to the zkSync network.

- Nonce check: The API client checks a special number called the "nonce" (like a unique serial number for your transactions) to make sure you haven’t used it before. It asks another **system contract** called **NonceHolder** for this information.

- Transaction validation: The API client then calls a function called **validateTransaction**. This function updates the nonce to ensure that your transaction is fresh and unique.

- Nonce verification: The API client double-checks that the nonce has been updated properly to confirm that you're not trying to send the same transaction twice.

- Paying for the transaction: Now it’s time to pay for the transaction. The API client calls a function to handle payment. If you’re using a **Paymaster** (a special contract that can pay for your transaction fees), the client may call extra functions to validate and process this payment.

- Payment check: Finally, the API client makes sure that the system called **bootloader** (which runs the show) *this bootloader act as the EntryPoint contract in Ethereum* has received payment.

### Phase 2: Execution
- Sending to the main node: Once the transaction is validated, the API client sends it to the *main zkSync node (which also acts as the “sequencer”* that organizes the order of transactions).

- Transaction execution: The main node then executes your transaction.

- Post-transaction if using Paymaster: If you used a Paymaster to pay, after the transaction is executed, a final function is called to close out the payment process.

> 🤯 In short,<br> the transaction goes through two stages: first, it’s validated (checked to make sure it’s valid, unique, and paid for), and then it’s executed (the action you requested is carried out).