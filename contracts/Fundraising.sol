// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

contract Fundraising {
    mapping(address => uint256) public contributors;
    address public admin;
    uint256 public numberOfContributors;
    uint256 public minimumContribution;
    uint256 public deadline;
    uint256 public goal;
    uint256 public raisedAmount = 0;
    uint256 requestCount = 0;
    mapping(uint256 => Request) public requests;

    struct Request {
        string description;
        address payable recipient;
        uint256 value;
        bool completed;
        uint256 numberOfVoters;
        mapping(address => bool) voters;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    event Contribute(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event RequestCreated(address indexed _from, uint256 indexed _requestId);
    event MakePayment(uint256 indexed _requestId, uint256 _value);

    constructor(
        uint256 _goal,
        uint256 _deadline,
        address _creator
    ) {
        goal = _goal;
        deadline = block.timestamp + _deadline;
        admin = _creator;
        minimumContribution = 0.1 ether;
    }

    function contribute() public payable returns (bool) {
        require(block.timestamp < deadline);
        require(msg.value >= minimumContribution);

        if (contributors[msg.sender] == 0) {
            numberOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
        emit Contribute(msg.sender, address(0), msg.value);
        return true;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.timestamp > deadline);
        require(raisedAmount < goal);
        require(contributors[msg.sender] > 0);

        address payable recipient = msg.sender;
        uint256 value = contributors[msg.sender];
        recipient.transfer(value);
        contributors[msg.sender] = 0;
    }

    function createRequest(
        string memory _description,
        address payable _recipient,
        uint256 _value
    ) public onlyAdmin returns (bool) {
        Request storage request = requests[requestCount++];
        request.description = _description;
        request.recipient = _recipient;
        request.value = _value;
        request.completed = false;
        request.numberOfVoters = 0;
        emit RequestCreated(msg.sender, requestCount - 1);
        return true;
    }

    function voteRequest(uint256 index) public returns (bool) {
        require(index < requestCount);
        require(contributors[msg.sender] > 0);

        Request storage request = requests[index];
        require(request.voters[msg.sender] == false);

        request.voters[msg.sender] = true;
        request.numberOfVoters++;
        return true;
    }

    function makePayment(uint256 index) public onlyAdmin returns (bool) {
        require(index < requestCount);
        Request storage request = requests[index];

        require(request.completed == false);
        require(request.numberOfVoters > numberOfContributors / 2);

        request.recipient.transfer(request.value);
        request.completed = true;
        emit MakePayment(index, request.value);
        return true;
    }
}
