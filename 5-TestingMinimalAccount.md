### que es lo primero que queremos testear?
Basicamente queremos testear que alguien puedar 
- firmar la data
- ir al alt mempool
- ir al entryPoint
- y que luego nuestro smart contract (MinimalAccount) haga algo

## nuestro test sera un USDC mint
- msg.sender sera nuestro MinimalAccount
- Deberia de aprovar some amount
- Usdc contract
- come from the entryPoint