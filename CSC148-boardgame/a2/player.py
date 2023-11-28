"""CSC148 Assignment 2

=== CSC148 Winter 2020 ===
Department of Computer Science,
University of Toronto

This code is provided solely for the personal and private use of
students taking the CSC148 course at the University of Toronto.
Copying for purposes other than this use is expressly prohibited.
All forms of distribution of this code, whether as given or with
any changes, are expressly prohibited.

Authors: Diane Horton, David Liu, Mario Badr, Sophia Huynh, Misha Schwartz,
and Jaisie Sin

All of the files in this directory and all subdirectories are:
Copyright (c) Diane Horton, David Liu, Mario Badr, Sophia Huynh,
Misha Schwartz, and Jaisie Sin.

=== Module Description ===

This file contains the hierarchy of player classes.
"""
from __future__ import annotations
from typing import List, Optional, Tuple
import random
import pygame

from block import Block
from goal import Goal, generate_goals

from actions import KEY_ACTION, ROTATE_CLOCKWISE, ROTATE_COUNTER_CLOCKWISE, \
    SWAP_HORIZONTAL, SWAP_VERTICAL, SMASH, PASS, PAINT, COMBINE


def create_players(num_human: int, num_random: int, smart_players: List[int]) \
        -> List[Player]:
    """Return a new list of Player objects.

    <num_human> is the number of human player, <num_random> is the number of
    random players, and <smart_players> is a list of difficulty levels for each
    SmartPlayer that is to be created.

    The list should contain <num_human> HumanPlayer objects first, then
    <num_random> RandomPlayer objects, then the same number of SmartPlayer
    objects as the length of <smart_players>. The difficulty levels in
    <smart_players> should be applied to each SmartPlayer object, in order.
    """
    res = []
    i = 0
    for _ in range(num_human):
        res.append(HumanPlayer(i, generate_goals(1)[0]))
        i += 1
    x = i
    for _ in range(num_random):
        res.append(RandomPlayer(x, generate_goals(1)[0]))
        x += 1
    y = x
    for _ in range(len(smart_players)):
        res.append(SmartPlayer(y, generate_goals(1)[0],
                               smart_players[y - x]))
        y += 1
    return res


def _get_block(block: Block, location: Tuple[int, int], level: int) -> \
        Optional[Block]:
    """Return the Block within <block> that is at <level> and includes
    <location>. <location> is a coordinate-pair (x, y).

    A block includes all locations that are strictly inside of it, as well as
    locations on the top and left edges. A block does not include locations that
    are on the bottom or right edge.

    If a Block includes <location>, then so do its ancestors. <level> specifies
    which of these blocks to return. If <level> is greater than the level of
    the deepest block that includes <location>, then return that deepest block.

    If no Block can be found at <location>, return None.

    Preconditions:
        - 0 <= level <= max_depth
    """
    if len(block.children) == 0 and _check_inside(block, location):
        return block
    if level == 0 and _check_inside(block, location):
        return block
    if not _check_inside(block, location):
        return None
    else:
        for child in block.children:
            if child.position[0] <= location[0] < child.position[0] + \
                    child.size and child.position[1] <= location[1] < \
                    child.position[1] + child.size:
                return _get_block(child, location, level - 1)
        return block


def _check_inside(block: Block, location: Tuple[int, int]) -> bool:
    """Return True if <location> inside block, return False otherwise.

    A block includes all locations that are strictly inside of it, as well as
    locations on the top and left edges. A block does not include locations that
    are on the bottom or right edge.
    """
    if block.position[0] <= location[0] < block.position[0] + block.size and \
            block.position[1] <= location[1] < block.position[1] + block.size:
        return True
    return False


class Player:
    """A player in the Blocky game.

    This is an abstract class. Only child classes should be instantiated.

    === Public Attributes ===
    id:
        This player's number.
    goal:
        This player's assigned goal for the game.
    """
    id: int
    goal: Goal

    def __init__(self, player_id: int, goal: Goal) -> None:
        """Initialize this Player.
        """
        self.goal = goal
        self.id = player_id

    def get_selected_block(self, board: Block) -> Optional[Block]:
        """Return the block that is currently selected by the player.

        If no block is selected by the player, return None.
        """
        raise NotImplementedError

    def process_event(self, event: pygame.event.Event) -> None:
        """Update this player based on the pygame event.
        """
        raise NotImplementedError

    def generate_move(self, board: Block) -> \
            Optional[Tuple[str, Optional[int], Block]]:
        """Return a potential move to make on the game board.

        The move is a tuple consisting of a string, an optional integer, and
        a block. The string indicates the move being made (i.e., rotate, swap,
        or smash). The integer indicates the direction (i.e., for rotate and
        swap). And the block indicates which block is being acted on.

        Return None if no move can be made, yet.
        """
        raise NotImplementedError


def _create_move(action: Tuple[str, Optional[int]], block: Block) -> \
        Tuple[str, Optional[int], Block]:
    """Return Tuple that the first element is teh first element of <action>,
    the second element is the second element of the <action>, may be None,
    the third element is the block.
    """
    return action[0], action[1], block


class HumanPlayer(Player):
    """A player in the Blocky game.

    === Private Attributes ===
    id:
        This player's number.
    goal:
        This player's assigned goal for the game.
    _level:
         The level of the Block that the user selected most recently.
     _desired_action:
         The most recent action that the user is attempting to do.

    == Representation Invariants concerning the private attributes ==
         _level >= 0
    """
    id: int
    goal: Goal
    _level: int
    _desired_action: Optional[Tuple[str, Optional[int]]]

    def __init__(self, player_id: int, goal: Goal) -> None:
        """Initialize this HumanPlayer with the given <renderer>, <player_id>
        and <goal>.
        """
        Player.__init__(self, player_id, goal)
        self._level = 0
        self._desired_action = None

    def get_selected_block(self, board: Block) -> Optional[Block]:
        """Return the block that is currently selected by the player based on
        the position of the mouse on the screen and the player's desired level.

        If no block is selected by the player, return None.
        """
        mouse_pos = pygame.mouse.get_pos()
        block = _get_block(board, mouse_pos, self._level)

        return block

    def process_event(self, event: pygame.event.Event) -> None:
        """Respond to the relevant keyboard events made by the player based on
        the mapping in KEY_ACTION, as well as the W and S keys for changing
        the level.
        """
        if event.type == pygame.KEYDOWN:
            if event.key in KEY_ACTION:
                self._desired_action = KEY_ACTION[event.key]
            elif event.key == pygame.K_w:
                self._level = max(0, self._level - 1)
                self._desired_action = None
            elif event.key == pygame.K_s:
                self._level += 1
                self._desired_action = None

    def generate_move(self, board: Block) -> \
            Optional[Tuple[str, Optional[int], Block]]:
        """Return the move that the player would like to perform. The move may
        not be valid.

        Return None if the player is not currently selecting a block.
        """
        block = self.get_selected_block(board)

        if block is None or self._desired_action is None:
            return None
        else:
            move = _create_move(self._desired_action, block)

            self._desired_action = None
            return move


class RandomPlayer(Player):
    """A player in the Blocky game.
    === Private Attributes ===
    id:
        This player's number.
    goal:
        This player's assigned goal for the game.
    _proceed:
        True when the player should make a move, False when the player should
        wait.
    """
    id: int
    goal: Goal
    _proceed: bool

    def __init__(self, player_id: int, goal: Goal) -> None:
        """Initialize this RandomPlayer with the given <player_id> and <goal>.
        """
        Player.__init__(self, player_id, goal)
        self._proceed = False

    def get_selected_block(self, board: Block) -> Optional[Block]:
        """Return the block that is currently selected by the player.

        If no block is selected by the player, return None.
        """
        return None

    def process_event(self, event: pygame.event.Event) -> None:
        """Respond to the relevant keyboard events made by the player based on
        the mapping in KEY_ACTION, as well as the W and S keys for changing
        the level.
        """
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            self._proceed = True

    def generate_move(self, board: Block) ->\
            Optional[Tuple[str, Optional[int], Block]]:
        """Return a valid, randomly generated move.

        A valid move is a move other than PASS that can be successfully
        performed on the <board>.

        This function does not mutate <board>.
        """
        if not self._proceed:
            return None
        new1 = _get_board(board)
        get_v = _get_valid(self.goal.colour, board)
        x = random.choice(get_v)
        move = _create_move(x, new1)
        self._proceed = False
        s = _check_paint(board, self.goal.colour)[1]
        target = _get_block(board, s.position, s.level)
        if move[0] == 'paint':
            return move[0], move[1], target
        if len(move[2].children) != 0:
            return move[0], move[1], move[2]
        else:
            return move[0], move[1], board


class SmartPlayer(Player):
    """A player in the Blocky game.
    === Private Attributes ===
    id:
        This player's number.
    goal:
        This player's assigned goal for the game.
    _proceed:
       True when the player should make a move, False when the player should
       wait.
    _difficulty:
        The number of valid move player should have.
    """
    id: int
    goal: Goal
    _proceed: bool
    _difficulty: int

    def __init__(self, player_id: int, goal: Goal, difficulty: int) -> None:
        """Initialize this SmartPlayer with the given <player_id>, <goal> and
        <difficulty>.
        """
        Player.__init__(self, player_id, goal)
        self._proceed = False
        self._difficulty = difficulty

    def get_selected_block(self, board: Block) -> Optional[Block]:
        """Return the block that is currently selected by the player.

        If no block is selected by the player, return None.
        """
        return None

    def process_event(self, event: pygame.event.Event) -> None:
        """Respond to the relevant keyboard events made by the player based on
        the mapping in KEY_ACTION, as well as the W and S keys for changing
        the level.
        """
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            self._proceed = True

    def generate_move(self, board: Block) ->\
            Optional[Tuple[str, Optional[int], Block]]:
        """Return a valid move by assessing multiple valid moves and choosing
        the move that results in the highest score for this player's goal (i.e.,
        disregarding penalties).

        A valid move is a move other than PASS that can be successfully
        performed on the <board>. If no move can be found that is better than
        the current score, this player will pass.

        This function does not mutate <board>.
        """
        if not self._proceed:
            return None  # Do not remove
        max_sc = self.goal.score(board)
        best_m = _create_move(PASS, board)
        for _ in range(self._difficulty):
            cop = board.create_copy()
            new1 = _get_board(cop)
            get_v = _get_valid(self.goal.colour, cop)
            x = random.choice(get_v)
            move = _create_move(x, new1)

            if x == SMASH:
                move[2].smash()
            elif x == SWAP_HORIZONTAL:
                move[2].swap(0)
            elif x == SWAP_VERTICAL:
                move[2].swap(1)
            elif x == ROTATE_CLOCKWISE:
                move[2].rotate(1)
            elif x == ROTATE_COUNTER_CLOCKWISE:
                move[2].rotate(3)
            elif x == PAINT:
                move[2].paint(self.goal.colour)
            elif x == COMBINE:
                move[2].combine()

            if self.goal.score(cop) > max_sc:
                max_sc = self.goal.score(cop)
                real = _get_block(board, move[2].position, move[2].level)
                best_m = (move[0], move[1], real)
        self._proceed = False  # Must set to False before returning!
        return best_m


def _check_paint(board: Block, colour: Tuple[int, int, int]) -> \
        Tuple[bool, Optional[Block]]:
    """Return the tuple that the first element is bool value that whether there
    is a block in <board> can paint with <colour>.
    """
    s = board.create_copy()
    for i in _all_blocks(s):
        if i.paint(colour):
            return True, i
    return False, None


def _check_combine(board: Block) -> bool:
    """Return the tuple that the first element is bool value that whether there
    is a block in <board> can combine.
    """
    s = board.create_copy()
    for i in _all_blocks(s):
        if i.combine():
            return True
    return False


def _get_valid(colour: Tuple[int, int, int], board: Block)-> \
        List[Tuple[str, Optional[int]]]:
    """Return the list that contains all the valid move of <board>.
    """
    choice = []

    if board.smashable():
        choice.append(SMASH)

    if _check_combine(board):
        choice.append(COMBINE)
    if _check_paint(board, colour)[0]:
        choice.append(PAINT)

    board3 = board.create_copy()
    if board3.rotate(1):
        choice.append(ROTATE_CLOCKWISE)
    board4 = board.create_copy()
    if board4.rotate(3):
        choice.append(ROTATE_COUNTER_CLOCKWISE)
    board5 = board.create_copy()
    if board5.swap(0):
        choice.append(SWAP_HORIZONTAL)
    board6 = board.create_copy()
    if board6.swap(0):
        choice.append(SWAP_VERTICAL)
    return choice


def _all_blocks(board: Block)-> List[Block]:
    """Return a list of blocks that contains every block within <board>.
    """
    if len(board.children) == 0:
        return [board]
    else:
        res = [board]
        for i in board.children:
            res.extend(_all_blocks(i))
        return res


def _get_board(board: Block) -> Block:
    """Return a block that is within <board>.
    """
    lst = _all_blocks(board)
    x = random.choice(lst)
    return x


def _generate_valid_move(board: Block, colour: Tuple[int, int, int]) -> \
        Tuple[str, Optional[int], Block]:
    """It takes a board and color to return a valid, randomly generated move.

    This function does not mutate <board>.
    """
    new1 = _get_board(board)
    get_v = _get_valid(colour, board)
    x = random.choice(get_v)
    return _create_move(x, new1)


if __name__ == '__main__':
    import python_ta

    python_ta.check_all(config={
        'allowed-io': ['process_event'],
        'allowed-import-modules': [
            'doctest', 'python_ta', 'random', 'typing', 'actions', 'block',
            'goal', 'pygame', '__future__'
        ],
        'max-attributes': 10,
        'generated-members': 'pygame.*'
    })
