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
Misha Schwartz, and Jaisie Sin

=== Module Description ===

This file contains the hierarchy of Goal classes.
"""
from __future__ import annotations
import random
from typing import List, Tuple
from block import Block
from settings import COLOUR_LIST


def generate_goals(num_goals: int) -> List[Goal]:
    """Return a randomly generated list of goals with length num_goals.

    All elements of the list must be the same type of goal, but each goal
    must have a different randomly generated colour from COLOUR_LIST. No two
    goals can have the same colour.

    Precondition:
        - num_goals <= len(COLOUR_LIST)
    """
    res = []
    cop = COLOUR_LIST[:]
    y = ['PerimeterGoal', 'BlobGoal']
    if random.choice(y) == 'PerimeterGoal':
        for _ in range(num_goals):
            x = random.choice(cop)
            res.append(PerimeterGoal(x))
            cop.remove(x)
        return res
    else:
        for _ in range(num_goals):
            x = random.choice(cop)
            res.append(BlobGoal(x))
            cop.remove(x)
        return res


def _flatten(block: Block) -> List[List[Tuple[int, int, int]]]:
    """Return a two-dimensional list representing <block> as rows and columns of
    unit cells.

    Return a list of lists L, where,
    for 0 <= i, j < 2^{max_depth - self.level}
        - L[i] represents column i and
        - L[i][j] represents the unit cell at column i and row j.

    Each unit cell is represented by a tuple of 3 ints, which is the colour
    of the block at the cell location[i][j]

    L[0][0] represents the unit cell in the upper left corner of the Block.
    """
    if not block.children:
        offset = block.max_depth - block.level
        split = 2 ** offset

        out = []
        for _ in range(split):
            inner = []
            for _ in range(split):
                inner.append(block.colour)
            out.append(inner)
        return out
    else:
        flat_children = [_flatten(child) for child in block.children]
        child0_3 = flat_children[0]
        child1_2 = flat_children[1]

        for i in range(len(flat_children[1])):
            child1_2[i].extend(flat_children[2][i])
            child0_3[i].extend(flat_children[3][i])
        child1_2.extend(child0_3)
        return child1_2


class Goal:
    """A player goal in the game of Blocky.

    This is an abstract class. Only child classes should be instantiated.

    === Attributes ===
    colour:
        The target colour for this goal, that is the colour to which
        this goal applies.
    """
    colour: Tuple[int, int, int]

    def __init__(self, target_colour: Tuple[int, int, int]) -> None:
        """Initialize this goal to have the given target colour.
        """
        self.colour = target_colour

    def score(self, board: Block) -> int:
        """Return the current score for this goal on the given board.

        The score is always greater than or equal to 0.
        """
        raise NotImplementedError

    def description(self) -> str:
        """Return a description of this goal.
        """
        raise NotImplementedError


class PerimeterGoal(Goal):
    """A player goal in the game of Blocky.

    The player must aim to put the most possible units of a given colour c on
    the outer perimeter of the board. The player’s score is the total number of
    unit cells of colour c that are on the perimeter. There is a premium on
    corner cells: they count twice towards the score.

    === Attributes ===
    colour:
          The target colour for this goal, that is the colour to which
    this goal applies.
    """
    def score(self, board: Block) -> int:
        """Return the score of the board under the PerimeterGoal of certain
        colour.
        """
        score = 0
        flat_block = _flatten(board)
        block_diameter = len(flat_block)

        for i in range(block_diameter):
            if flat_block[0][i] == self.colour:
                score += 1
            if flat_block[i][0] == self.colour:
                score += 1
            if flat_block[block_diameter - 1][i] == self.colour:
                score += 1
            if flat_block[i][block_diameter - 1] == self.colour:
                score += 1
        return score

    def description(self) -> str:
        """Return a description of this goal.
        """
        return 'Try to get the most blocks of your target colour ' \
               'around the perimeter of the Blocky board'


class BlobGoal(Goal):
    """A player goal in the game of Blocky.

    The player must aim for the largest “blob” of a given colour c. A blob is a
    group of connected blocks with the same colour. Two blocks are connected if
    their sides touch; touching corners doesn’t count. The player’s score is the
    number of unit cells in the largest blob of colour c.

    === Attributes ===
    colour:
          The target colour for this goal, that is the colour to which
    this goal applies.
    """
    def score(self, board: Block) -> int:
        """Return the score of the board under the BlobGoal of certain colour.
        """
        score = 0
        rep = _flatten(board)
        cells_lst = []
        for _ in range(len(rep)):
            cells_lst.append([-1] * len(rep))
        for i in range(len(cells_lst)):
            for j in range(len(cells_lst)):
                curr_score = self._undiscovered_blob_size((i, j), rep,
                                                          cells_lst)
                if score < curr_score:
                    score = curr_score
        return score

    def _undiscovered_blob_size(self, pos: Tuple[int, int],
                                board: List[List[Tuple[int, int, int]]],
                                visited: List[List[int]]) -> int:
        """Return the size of the largest connected blob that (a) is of this
        Goal's target colour, (b) includes the cell at <pos>, and (c) involves
        only cells that have never been visited.

        If <pos> is out of bounds for <board>, return 0.

        <board> is the flattened board on which to search for the blob.
        <visited> is a parallel structure that, in each cell, contains:
            -1 if this cell has never been visited
            0  if this cell has been visited and discovered
               not to be of the target colour
            1  if this cell has been visited and discovered
               to be of the target colour

        Update <visited> so that all cells that are visited are marked with
        either 0 or 1.
        """
        x = pos[0]
        y = pos[1]
        if x < 0 or y < 0:
            return 0
        elif x > len(board) - 1 or y > len(board) - 1:
            return 0
        elif visited[x][y] == 0 or visited[x][y] == 1:
            return 0
        else:
            blob_size = 0
            if board[x][y] != self.colour:
                visited[x][y] = 0
                return 0

            blob_size += 1
            visited[x][y] = 1
            blob_size += self._undiscovered_blob_size((x + 1, y), board,
                                                      visited)
            blob_size += self._undiscovered_blob_size((x - 1, y), board,
                                                      visited)
            blob_size += self._undiscovered_blob_size((x, y - 1), board,
                                                      visited)
            blob_size += self._undiscovered_blob_size((x, y + 1), board,
                                                      visited)

            return blob_size

    def description(self) -> str:
        """Return a description of this goal.
        """
        return 'Create the largest connected blob'


if __name__ == '__main__':
    import python_ta
    python_ta.check_all(config={
        'allowed-import-modules': [
            'doctest', 'python_ta', 'random', 'typing', 'block', 'settings',
            'math', '__future__'
        ],
        'max-attributes': 15
    })
