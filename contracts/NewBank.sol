
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BankingSystem {
    address public admin;
    mapping(address => uint256) public balances;
    mapping(address => bool) public isCustomer;
    mapping(address => bool) public hasLoan;
    uint256 public loanInterestRate = 5; 
    uint256 public loanPenaltyRate = 10; 
    
    event NewCustomerRegistered(address customer);
    event Deposit(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);
    event LoanRequested(address indexed account, uint256 amount);
    event LoanRepayment(address indexed account, uint256 amount);
    event LoanPenalty(address indexed account, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyExistingCustomer() {
        require(isCustomer[msg.sender], "Customer does not exist");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function registerCustomer(address _customer) external onlyAdmin {
        require(!isCustomer[_customer], "Customer already exists");
        isCustomer[_customer] = true;
        emit NewCustomerRegistered(_customer);
    }

    function deposit() external payable onlyExistingCustomer {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external onlyExistingCustomer {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    }

    function requestLoan(uint256 _amount) external onlyExistingCustomer {
        require(!hasLoan[msg.sender], "Existing loan not yet repaid");
        require(_amount > 0, "Loan amount must be greater than 0");
        require(_amount <= balances[msg.sender] * 2, "Loan amount exceeds double the balance");
        hasLoan[msg.sender] = true;
        balances[msg.sender] += _amount;
        emit LoanRequested(msg.sender, _amount);
    }

    function repayLoan(uint256 _amount) external onlyExistingCustomer {
        require(hasLoan[msg.sender], "No existing loan to repay");
        require(_amount > 0, "Repayment amount must be greater than 0");
        require(_amount <= balances[msg.sender], "Insufficient balance for loan repayment");
        balances[msg.sender] -= _amount;
        if (_amount < balances[msg.sender] * loanInterestRate / 100) {
            balances[msg.sender] -= _amount * loanPenaltyRate / 100;
            emit LoanPenalty(msg.sender, _amount * loanPenaltyRate / 100);
        }
        hasLoan[msg.sender] = false;
        emit LoanRepayment(msg.sender, _amount);
    }

    function changeAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }
}
