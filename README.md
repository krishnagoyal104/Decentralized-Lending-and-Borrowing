# Decentralized-Lending-and-Borrowing
A Decentralized market place governed by Smart Contracts to lend and borrow Ethereum in a trustless and secure manner.

## Details
* The contract uses **Oraclize** to query API from websites to obtain prices of different tokens. The API call can be changed to accomodate more tokens to be used as collaterals.
* Any person can place a loan request specifying the following :\
  1. **ERC20** tokens to be pledged as collateral
  2. Number of such tokens
  3. Number of installments, each installment being 30 days
  4. Monthly interest he is willing to pay
 * An amount worth less than 70% of the collateral tokens can be borrowed (this is a safeguard for the lender from the volatility of the collateral tokens).
 * The borrower then has to approve the collateral tokens to the contract.
 * If someone finds the specifications acceptable, he can fund the loan request.
 * If the borrower defaults a payment, the next installment amount will increase by 5% of the default installment(s).
 * In case the borrower does not pay the required installments due on the maturity of the contract,the lender can claim the collateral.
 
 ## Scope
 Investors who are holding a long position on an ERC20 token can use it as collateral to borrow ethereum to enhance their portfolio.\
A bigger picture can be tokens representing physical assets being used as collateral to borrow currencies. This is a potential use leveraging the power of blockchain where physical assets are being mortgaged in a decentralized and secure manner.
