// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
/// There are three resources needed to survive: Water, Food, and Wood.
enum Resource {
    Water,
    Wood,
    Food
}

/// Most individuals can only produce one or two of the resources, and therefore collaboration is necessary for survival.
/// Therefore we create a free market in which participants can contribute resources when they have them.
/// Later members can withdraw resources in proportion to their contributions.
/// You are not required to withdraw the same resources you contributed.
abstract contract ResourceMarket {

    /// The amount of water currently available on the market
    uint water = 0;

    /// The amount of food currently available on the market
    uint food = 0;

    /// The amount of wood currently available on the market
    uint wood = 0;

    /// The credit that each previous contributor has in the market.
    /// This is the maximum amount of resources that they can withdraw.
    mapping(address => uint) credit;

    /// Contribute some of your own private resources to the market.
    /// Contributions are made one asset at a time.
    function contribute(uint amount, Resource resource) public virtual;

    /// Withdraw some resources from the market into your own private reserves.
    function withdraw(uint amount, Resource resource) public virtual;

}

// Enhancement: The first iteration of this contract allow users to contribute
// by simplifying calling a function with an integer parameter. Presumably there is
// a security guard somewhere near the real-world marketplace confirming the deposits
// are actually made. But there are no on-chain assets underlying the resource market.
// Modify the code to interface with three real ERC20 tokens called: Water, Wood, and Food.

// Enhancement: The resource trading logic in this contract is useful for way more
// scenarios than our simple wood, food, water trade. Generalize the contract to
// work with up to 5 arbitrary ERC20 tokens.

// Enhancement: If we are trading real food, wood, and water, we have real-world incentives
// to deposit ou excess resources. Storage is hard IRL. Water evaporates, food spoils, and wood rots.
// And all the resources are subject to robbery. But if we are talking about virtual assets,
// there are no such risks. And depositing funds into the market comes with an opportunity cost.
// Design a reward system where there is a small fee on every withdrawal, and that fee is paid to
// liquidity providers.



contract ResourceMarketLogic is ResourceMarket {
    mapping(address => mapping(Resource => uint)) public balance;

    // ERC20 tokens addresses
    address[] public tokens;

    // Fee percentage on withdrawals
    uint public withdrawalFeePercentage = 1; // 1% fee

    event Contribution(address indexed account, uint amount, Resource resource);
    event Withdrawal(address indexed account, uint amount, Resource resource);

    // Constructor to initialize ERC20 token addresses
    constructor(address[] memory _tokens) {
        require(_tokens.length == 3, "Invalid number of tokens");
        tokens = _tokens;
    }

    /// Contribute some of your own private resources to the market.
    /// Contributions are made one asset at a time.

    function contribute(uint amount, Resource resource) public override {
    require(amount > 0, "Invalid amount");
    address tokenAddress = tokens[uint(resource)];
    require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "Transfer failed");
    balance[msg.sender][resource] += amount;
    emit Contribution(msg.sender, amount, resource);
}

    /// Withdraw some resources from the market into your own private reserves.
    function withdraw(uint amount, Resource resource) public override {
        require(balance[msg.sender][resource] >= amount, "Insufficient balance");
        uint fee = (amount * withdrawalFeePercentage) / 100;
        uint netAmount = amount - fee;
        require(IERC20(tokens[uint(resource)]).transfer(msg.sender, netAmount), "Transfer failed");
        balance[msg.sender][resource] -= amount;
        emit Withdrawal(msg.sender, netAmount, resource);
    }

    /// Set the withdrawal fee percentage
    function setWithdrawalFeePercentage(uint _percentage) external {
        require(_percentage <= 100, "Invalid fee percentage");
        withdrawalFeePercentage = _percentage;
    }
}
