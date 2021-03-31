# Nsure Contracts

## Description

Nsure is an open insurance platform for Open Finance. The project borrows the idea of Lloyd’s London, a market place to trade insurance risks, where premiums are determined by a Dynamic Pricing Model. Capital mining will be implemented to secure capital required to back the risks at any point of time. A 3-phase crowd voting mechanism is used to ensure every claim is handled professionally. You can get all the information here: https://nsure.network/Nsure_WP_0.7.pdf

## Contract Functions

* Buy.sol is used for policy purchasing, premium will be sent to each pool accordingly to: Treasury.sol(10%,for future claim assessment), Surplus.sol(40%,for claim payout), and LockFunds.sol(50%,reward for underwriters)
* CapitalConverter.sol converts assets into a new token，when a claim is successful the asset is reduced due to payout
* CapitalStake.sol can stake CapitalConverter.sol token for reward
* ClaimPurchaseMint.sol is for policy mining rewards

And for the detail funds flow, please refer to: ![Funds Flow](https://firebasestorage.googleapis.com/v0/b/gitbook-28427.appspot.com/o/assets%2F-MLmCwj9hbzeKCknH9fG%2F-MUrz4HBAvAgugsIz0XS%2F-MUrzbodZp-8BoAp0g2s%2Ffunds_flow.jpg?alt=media&token=2d6c85be-94ce-4651-b9ac-f2cef9caaa88)



## Test

> 1.modify: `migrations/1_deploy_all.js`, open comments on smart contract to be tested

> 2.Run `truffle test test/` to do testing


## License
Nsure contracts and all other utilities are licensed under [Apache 2.0](LICENSE).

## Contact
If you want any further information, feel free to contact us at **contact@nsure.network** :) ...
