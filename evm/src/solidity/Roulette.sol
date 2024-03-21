// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

/// The colors of the slots placed on the roulette wheel
enum Color {
    Red,
    Black,
    Green
}

/// A Bet on a specific color coming up on the Roulette wheel
struct ColorBet {
    Color color;
    uint amount;
    address beneficiary;
}

/// Models a casino style roulette table
/// https://en.wikipedia.org/wiki/Roulette
/// with these exact tiles
/// https://bfgblog-a.akamaihd.net/uploads/2013/11/2-1-Roulette-Table-Wheel-1024x463.png
contract Roulette {

    /// All existing open color bets
    ColorBet[] color_bets;

    /// The address of the "house" that operates this table.
    /// This is initialized to the address that deployed the contract.
    address house;
    uint256 public constant MIN_BLOCKS_BETWEEN_SPINS = 20; // Minimum number of blocks between spins

    uint256 private lastSpinBlockNumber; // Last block number when a spin occurred


    constructor() {
        house = msg.sender;
    }

    /// Funds were added to the table
    event Funded(uint amount);

    /// A Bet for a particular color was placed
    event ColorBetPlaced(ColorBet bet);

    /// A Bet for a particular color was won
    event ColorBetWon(ColorBet bet);

    /// A Bet for a particular color was lost
    event ColorBetLost(ColorBet bet);

    /// Add money to the house's funds.
    /// This can only be called by the house account to help prevent users from
    /// accidentally depositing funds that do not back any bet.
    /// Because we have this explicit function, we do not include a fallback function.
    function fund_table() external payable {
        require(msg.sender == house, "Only the house can fund the table");
        emit Funded(msg.value);
    }

    /// Place a bet on a specific color
    function place_color_bet(Color color) external payable {
        require(msg.value > 0, "Bet amount must be greater than zero");
        color_bets.push(ColorBet(color, msg.value, msg.sender));
        emit ColorBetPlaced(ColorBet(color, msg.value, msg.sender));
    }

    /// Helper function to determine the color of a roulette tile
    function color_of(uint n) internal pure returns (Color) {
        if (n == 0) {
            return Color.Green;
        } else if (n >= 1 && n <= 10) {
            return (n % 2 == 0) ? Color.Black : Color.Red;
        } else if (n >= 11 && n <= 18) {
            return (n % 2 == 0) ? Color.Red : Color.Black;
        } else if (n >= 19 && n <= 28) {
            return (n % 2 == 0) ? Color.Black : Color.Red;
        } else if (n >= 29 && n <= 36) {
            return (n % 2 == 0) ? Color.Red : Color.Black;
        } else {
            revert("Invalid number");
        }
    }

    /// Spin the wheel to determine the winning number.
    /// Also calls settle_bets to kick off settlement of all bets.
    

    function spin() external {
        require(color_bets.length > 0, "No bets placed yet");
        require(block.number >= lastSpinBlockNumber + MIN_BLOCKS_BETWEEN_SPINS, "Too soon to spin again");
        
        uint winning_number = get_random_number();
        settle_bets(winning_number);
        
        lastSpinBlockNumber = block.number;
    }


    /// Helper function to settle all bets given a winning number
    function settle_bets(uint winning_number) internal {
        Color winning_color = color_of(winning_number);
        for (uint i = 0; i < color_bets.length; i++) {
            if (color_bets[i].color == winning_color) {
                // Player wins
                // Convert the beneficiary address to payable
                address payable payableBeneficiary = payable(color_bets[i].beneficiary);

                payableBeneficiary.transfer(color_bets[i].amount * 2); // Double the bet amount
                emit ColorBetWon(color_bets[i]);
            } else {
                // Player loses
                emit ColorBetLost(color_bets[i]);
            }
        }
        delete color_bets;
    }

    /// Helper function to generate a random number between 0 and 37
    function get_random_number() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, blockhash(block.number - 1)))) % 38;
    }
}




    


// Enhancement: Allow all kinds of other bets like:
// * even / odd
// * one-spot
// * two-spot
// * four-spot
// * Column
// * etc

// Enhancement: read about randomness in the evm and try to find a good source of fair randomness.