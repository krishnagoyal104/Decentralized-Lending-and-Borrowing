pragma solidity ^0.4.18;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "./loan.sol";

contract Query is usingOraclize{

	address public owner;
	mapping(bytes32 => bool) validIds;
	address[] public validTokenContracts = [0xd26114cd6EE289AccF82350c8d8487fedB8A0C07,0x86Fa049857E0209aa7D9e616F7eb3b3B78ECfdb0];//ERC20 tokens contract addresses
	uint32 gasLimitForOraclize = 200000;
	string query = "json(https://min-api.cryptocompare.com/data/pricemulti?fsyms=OMG,EOS&tsyms=ETH).[OMG,EOS].ETH";

	event LogOraclizeQuery(string description);
	event LogResultReceived(string description);
	event LogNewContract(address _newContract);

	mapping(address => address) public newContractAddresses;
	string public exchangeRates;
	bytes tempNum;
	uint[] public numbers;
	
	modifier onlyOwner(){
	    require(msg.sender == owner);
	    _;
	}

	function Query() public{
		owner = msg.sender;
		oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
	}

	function changeOraclizeSettings(address _addr,string _query,uint32 _gasLimit,uint64 _gasPrice) public onlyOwner{
		validTokenContracts.push(_addr);
		query = _query;
		gasLimitForOraclize = _gasLimit;
		oraclize_setCustomGasPrice(_gasPrice);
	}

	function getApi() public{
		require(msg.value >= 0.002 ether);
		bytes32 queryId = oraclize_query("URL",query,gasLimitForOraclize);
		LogOraclizeQuery("Oraclize query was sent, standing by for the answer..");
		validIds[queryId] = true;
	}

	function _callback(bytes32 queryId, string result, bytes proof) public{//string is used because solidity does not support floating point

		require(msg.sender == oraclize_cbAddress());
        require(validIds[queryId]);

        exchangeRates = result;   
        validIds[queryId] = false;
        LogResultReceived("Prices retrieved.");
	}

	//since the query returns a string,we need to convert that into uint and store in an array
	function splitStr() public{

		string memory delimiter = ",";

        bytes memory b = bytes(exchangeRates); //cast the string to bytes to iterate
        bytes memory delm = bytes(delimiter);

        delete numbers;

        for(uint8 i; i<b.length ; i++){          

            if(b[i] != delm[0]) { 
                tempNum.push(b[i]);             
            }
            else { 
                numbers.push(parseInt(string(tempNum),6)); //push the int value converted from string to numbers array
                tempNum = "";   //reset the tempNum to catch the next number                 
            }                
        }

        if(b[b.length-1] != delm[0]) { 
           numbers.push(parseInt(string(tempNum),6));
        }

        //create a new LoanContract with an array of prices and list of token contract addresses as constructor parameters
        address newAddress = new LoanContract(numbers,validTokenContracts);
		newContractAddresses[msg.sender] = newAddress;//store the address of the new contract as a mapping of the borrower

		LogNewContract(newAddress);
    }
}
