## cmds
```
npx hardhat compile
npx hardhat run scripts/interact/interactDrakma.js --network goerli
npx hardhat run scripts/deploy/deployCitadel.js --network localhost

node scripts/props/citadelProps.js
node scripts/interact/whitelistMerkle.js

npx hardhat run scripts/interact/interactCitadelNFT.js --network mainnet
npx hardhat run scripts/game/raid.js --network goerli

npx hardhat run scripts/interact/interactSovereign.js --network mainnet

npx hardhat run scripts/game/train.js --network goerli
```

## sovereign
```

npx hardhat run scripts/interact/interactSovereign.js --network mainnet
```

## deploy
```
npx hardhat run scripts/deploy/deployCitadel.js --network arbitrumgoerli
npx hardhat run scripts/deploy/deployCitadel.js --network goerli
npx hardhat run scripts/deploy/deployGameV1.js --network goerli
```

## test
```
npx hardhat node
npx hardhat test
```

## verify
```
npx hardhat verify --network mainnet --constructor-args scripts/verify/pilot-verify-args.js 0xD653B9f4ec70658402B9634E7E0eAFcc64138Cad

npx hardhat verify --network mainnet --constructor-args scripts/verify/citadel-verify-args.js 0xaF08134eA12494dc3AAA7f1EFB23A8753B7F84c9

npx hardhat verify --network goerli --constructor-args scripts/verify/game-verify-args.js 0xb648E5460Fe6Cd5948FF93e9921215A5aD9D21aF
```

## size
```
npx hardhat size-contracts
```