# @version ^0.3.0

# Most individuals can only produce one or two of the resources, and therefore collaboration is necessary for survival.
# Therefore we create a free market in which participants can contribute resources when they have them.
# Later members can withdraw resources in proportion to their contributions.
# You are not required to withdraw the same resources you contributed.

# There are three resources needed to survive: Water, Food, and Wood.
enum Resource:
    WATER
    WOOD
    FOOD



# The amount of water currently available on the market
water: uint256

# The amount of food currently available on the market
food: uint256

# The amount of wood currently available on the market
wood: uint256

# The credit that each previous contributor has in the market.
# This is the maximum amount of resources that they can withdraw.
credit: HashMap[address, uint256]

@external
def __init__():
    self.resource_balance[Resource.WATER] = 0
    self.resource_balance[Resource.WOOD] = 0
    self.resource_balance[Resource.FOOD] = 0

@external
def contribute(amount: uint256, resource: Resource):
    """ Contribute some of your own private resources to the market.

    Contributions are made one asset at a time.
    """

    """
    Contribute some of your own private resources to the market.
    Contributions are made one asset at a time.
    """
    # Only accept positive contributions
    require(amount > 0, "Contribution amount must be positive")
    
    # Increase the balance of the specified resource
    self.resource_balance[resource] += amount
    
    # Update contributor's credit
    self.credit[msg.sender] += amount
    pass

@external
def withdraw(amount: uint256, resource: Resource):
    """ Withdraw some resources from the market into your own private reserves. """

    """ 
    Withdraw some resources from the market into your own private reserves. 
    """
    # Check if the caller has enough credit
    require(self.credit[msg.sender] >= amount, "Insufficient credit")

    # Check if the market has enough resources
    require(self.resource_balance[resource] >= amount, "Insufficient resource balance")

    # Decrease the balance of the specified resource
    self.resource_balance[resource] -= amount
    
    # Decrease contributor's credit
    self.credit[msg.sender] -= amount

    # Transfer the withdrawn resources to the caller
    send(msg.sender, amount)
    pass


# Enhancement: The first iteration of this contract allow users to contribute
# by simply calling a function with an integer parameter. Presumably there is
# a security guard somewhere near the real-world marketplace confirming the deposits
# are actually made. But there are no on-chain assets underlying the resource market.
# Modify the code to interface with three real ERC20 tokens called: Water, Wood, and Food.

# Enhancement: The resource trading logic in this contract is useful for way more
# scenarios than our simple wood, food, water trade. Generalize the contract to
# work with up to 5 arbitrary ERC20 tokens.

# Enhancement: If we are trading real food, wood, and water, we have real-world incentives
# to deposit ou excess resources. Storage is hard IRL. Water evaporates, food spoils, and wood rots.
# And all the resources are subject to robbery. But if we are talking about virtual assets,
# there are no such risks. And depositing funds into the market comes with an opportunity cost.
# Design a reward system where there is a small fee on every withdrawal, and that fee is paid to
# liquidity providers.