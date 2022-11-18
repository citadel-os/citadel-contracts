cmds
npx hardhat node
npx hardhat compile
npx hardhat run scripts/interactDrakma.js --network goerli
npx hardhat run scripts/deployCitadel.js --network localhost
npx hardhat test

node scripts/citadelProps.js
node scripts/whitelistMerkle.js


npx hardhat run scripts/interactCitadelNFT.js --network mainnet

npx hardhat verify --network mainnet --constructor-args scripts/pilot-verify-args.js 0xD653B9f4ec70658402B9634E7E0eAFcc64138Cad

npx hardhat verify --network mainnet --constructor-args scripts/citadel-verify-args.js 0xaF08134eA12494dc3AAA7f1EFB23A8753B7F84c9