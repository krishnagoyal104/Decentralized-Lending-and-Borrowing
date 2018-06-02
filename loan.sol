contract ERC20Interface{

	function transferFrom(address _from, address _to, uint _value) public returns(bool _success);
	function transfer(address _to, uint _value) public returns(bool _success);
	function approve(address _spender,uint _value) public returns(bool _success);

}

contract LoanContract{

	struct Loan{
		uint8 collateralId;
		uint collateralTokens;
		uint8 numberOfInstallments;//30 days per installment
		uint ethBorrowed;
		uint8 interest;//monthly interest.
	}

	enum State{
		Borrowed,
		Collateral,
		Funded,
		Completed,
		Defaulted
	}

	Loan public loan;

	address public borrower;
	address public lender;
	uint public timeWhenBorrowedLoan;
	uint8 public numberOfInstallmentsPaid = 0;
	uint public nextDue;

	modifier inState(State _state){
		require(state == _state);
		_;
	}

	modifier onlyBorrower(){
		require(msg.sender == borrower);
		_;
	}

	modifier onlyLender(){
		require(msg.sender == lender);
		_;
	}

	State public state;

	ERC20Interface tokenContract;

	uint[] public rates;
	address[] public contractAdresses;

	function LoanContract(uint[] _rates,address[] _contractAdresses) public{//obtained as arguments from the query contract
		rates = _rates;
		contractAdresses = _contractAdresses;
	}

	function borrow(uint8 _id,uint _numberOfTokens,uint8 _numberOfInstallments,uint _ethAmount,uint8 _interest) public{
		uint ethAmount = (rates[_id] * 10**18 * _numberOfTokens * 70)/100;//since the prices received are in terms of ether,they need to be converted to wei;
		require(_ethAmount <= ethAmount);//can only borrow 70% of the collateral amount
		borrower = msg.sender;
		loan = Loan(_id,_numberOfTokens,_numberOfInstallments,ethAmount,_interest);
		state = State.Borrowed;
	}

	//ERC20Interface(_tokenAddress).approve() needs to be called before calling the following function.
	function transferFromBorrower() public inState(State.Borrowed){
		tokenContract = ERC20Interface(contractAdresses[loan.collateralId]);
		state = State.Collateral;
		require(tokenContract.transferFrom(msg.sender,address(this),loan.collateralTokens));
	}
 
 	function fund() public inState(State.Collateral) payable{
 		require(msg.sender != borrower);
 		require(msg.value == loan.ethBorrowed);
 		lender = msg.sender;
 		state = State.Funded;
 		timeWhenBorrowedLoan = now;
 		nextDue = now + 35 days;
 		borrower.transfer(msg.value);
 	}


 	//in case of default,the next installment will include a penalty of 5% on every previous default installment
 	function repayInstallment() inState(State.Funded) public payable onlyBorrower{
 		uint8 counter = 0;
 		while(now > nextDue){//counter is the number of default payments before the given payment
 			counter++;
 			nextDue = nextDue + 35 days;//5 extra days are given before counting as a default
 		}
 		uint installment = (loan.ethBorrowed * (1 + loan.interest/100))/loan.numberOfInstallments;//value of each installment to be paid(this is fixed)
 		uint payment = (installment * 105 * counter * (counter + 1))/200 + installment;//final amount of installment needed to be paid.If there is no default,counter will be 0 and the amount will be the same as the installment
 		require(msg.value == payment);
 		numberOfInstallmentsPaid += counter + 1;//previous payments + default payment + current payment
 		nextDue = nextDue + 35 days;        
 		lender.transfer(msg.value);
 	}

 	function claimCollateral() public inState(State.Funded) onlyLender{
 		require(now > timeWhenBorrowedLoan + (30 days) * loan.numberOfInstallments + 7 days);//giving 7 extra days to the borrower before declaring default
 		require(numberOfInstallmentsPaid < loan.numberOfInstallments);
 		state = State.Defaulted;
 		tokenContract.transfer(lender,loan.collateralTokens);
 	}

 	function getCollateralBack() public inState(State.Funded) onlyBorrower{
 		require(numberOfInstallmentsPaid == loan.numberOfInstallments);
 		state = State.Completed;
 		tokenContract.transfer(borrower,loan.collateralTokens);
 	}

}