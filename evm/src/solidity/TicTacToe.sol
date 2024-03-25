// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

enum WinLocation {
    LeftColumn,
    CenterColumn,
    RightColumn,
    TopRow,
    MiddleRow,
    BottomRow,
    UphillDiagonal,
    DownhillDiagonal,
    OpponentSurrender
}

/// @title A contract that allows two users to play a game of tic tac toe between themselves.
contract TicTacToe {

    /// The two players in the game
    address player1;
    address player2;

    /// The number of turns completed in the game so far
    uint num_turns;
    
    /// The 3x3 board of moves
    ///
    ///  0 | 1 | 2
    /// ---+---+---
    ///  3 | 4 | 5
    /// ---+---+---
    ///  6 | 7 | 8
    ///
    /// row = cell_index / 3
    /// col = cell_index % 3
    address[9] board;

    constructor(address p1, address p2) {
        player1 = p1;
        player2 = p2;
        num_turns = 0;
    }

    /// A player has taken a turn in the tic tac toe game.
    event TurnTaken(address player, uint cell_index);

    /// A player has won the game
    event GameWon(address winner, WinLocation win_location);

    /// The game has ended in a draw
    event GameTied();

    /// Return the current state of the board
    function get_board() external view returns(address[9] memory) {
        return board;
    }

    /// @dev Take a regular non-winning turn in a tic-tac-toe game
    /// @param cell_index the cell that the player is claiming encoded as documented
    function take_turn(uint cell_index) external {
        do_take_turn(cell_index);
    }

    /// Internal helper function to actually do the turn taking logic
    /// This is called by both take_turn and take_winning_turn
    function do_take_turn(uint cell_index) internal {
        require(cell_index >= 0 && cell_index < 9, "Invalid cell index");
        require(board[cell_index] == address(0), "Cell already taken");
        
        address player = msg.sender;
        require(player == player1 || player == player2, "Wrong player");
        
        require(player == (num_turns % 2 == 0 ? player1 : player2), "Wrong player's turn");
        
        board[cell_index] = player;
        num_turns++;
        
        emit TurnTaken(player, cell_index);
    }

    /// @dev Take a winning turn in a tic-tac-toe game
    /// @param cell_index the cell that the player is claiming encoded as documented
    /// @param win_location the row, column, or diagonal where the player is claiming to have won.
    /// The on-chain logic does not do the heavy lifting of searching all possible win locations
    /// rather the user is forced to point out exactly where they have won, and the chain
    /// just confirms it.
    function take_winning_turn(uint cell_index, WinLocation win_location) external {
        do_take_turn(cell_index);
    
        address winner = msg.sender;
        require(verify_win(winner, win_location), "Invalid win claimed");
        
        emit GameWon(winner, win_location);
    }

    /// Internal helper function to verify whether a win is valid.
    function verify_win(address winner, WinLocation location) view internal returns(bool) {
        address player = winner;
        address opponent = (player == player1) ? player2 : player1;
        
        // Check if the claimed win location is valid
        if (location == WinLocation.LeftColumn) {
            return (board[0] == player && board[3] == player && board[6] == player);
        } else if (location == WinLocation.CenterColumn) {
            return (board[1] == player && board[4] == player && board[7] == player);
        } else if (location == WinLocation.RightColumn) {
            return (board[2] == player && board[5] == player && board[8] == player);
        } else if (location == WinLocation.TopRow) {
            return (board[0] == player && board[1] == player && board[2] == player);
        } else if (location == WinLocation.MiddleRow) {
            return (board[3] == player && board[4] == player && board[5] == player);
        } else if (location == WinLocation.BottomRow) {
            return (board[6] == player && board[7] == player && board[8] == player);
        } else if (location == WinLocation.UphillDiagonal) {
            return (board[0] == player && board[4] == player && board[8] == player);
        } else if (location == WinLocation.DownhillDiagonal) {
            return (board[2] == player && board[4] == player && board[6] == player);
        } else {
            return false;
        }
    }

    /// Give up on the game allowing the other player to win.
    function surrender() external {
        address player = msg.sender;
        require(player == player1 || player == player2, "Invalid player");

        // Determine the opponent of the player who surrenders
        address opponent = (player == player1) ? player2 : player1;

        // Emit the event indicating the surrender
        emit GameWon(opponent, WinLocation.OpponentSurrender);
    }
}

// Enhancement: Require a security deposit from each player, and if anyone claims
// to have won incorrectly, their deposit it slashed.

// Enhancement: Allow players to bet on a game.

// Enhancement: Allow ending games early when it is inevitable that a draw
// will happen, but the board is not yet full. This will require one player
// proposing an early draw, and the other player accepting.