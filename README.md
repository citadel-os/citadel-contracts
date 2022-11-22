## cmds
```
npx hardhat compile
npx hardhat run scripts/interact/interactDrakma.js --network goerli
npx hardhat run scripts/deploy/deployCitadel.js --network localhost

node scripts/props/citadelProps.js
node scripts/interact/whitelistMerkle.js
npx hardhat run scripts/interact/interactCitadelNFT.js --network mainnet
```

## deploy
```
npx hardhat run scripts/deploy/deployCitadel.js --network localhost
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
```