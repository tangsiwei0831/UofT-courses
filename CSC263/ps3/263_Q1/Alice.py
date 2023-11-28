import sys
from typing import Tuple, List, Dict, Union, Any
import time     # only for timing the program, not for algorithm use


class Queue:
    """Queue implemented by array"""

    queue: List[Any]
    _size: int

    def __init__(self):
        self.queue = []
        self._size = 0

    def isEmpty(self):
        return self.queue == []

    def enqueue(self, item):
        self.queue.append(item)
        self._size += 1

    def dequeue(self):
        if len(self.queue) < 1:
            return None
        self._size -= 1
        return self.queue.pop(0)

    def getSize(self):
        return self._size


class Node:
    """
    position: Tuple[int, int]   # x, y position
    direction: str              # N, E, S, W, NE, NW, SE, SW;
                                # or empty str for an blank cell
    colour: str                 # only can be one of 'w', 'g', 'b'
                                # or empty str for an blank cell
    parent: Union[Node, None]   # parent node for this node
    depth: int                  # the depth of this node, starting from 0
    """

    def __init__(self, position, direction, colour, depth, step_size):
        self.position = position
        self.direction = direction
        self.colour = colour
        self.parent = None
        self.depth = depth
        self.step_size = step_size


def find_shortest_path(maze: List[List[Tuple[Tuple[str], str]]],
                       start_position: Tuple[int, int],
                       goal) -> Tuple[list, int, bool]:
    """
    Return a tuple of stores
        - the shortest path through the maze, and
        - the length of this shortest path,
        - if there exists a solution
    If there is no such solution, it should return True at index 2 in
    return tuple; otherwise, return False.

    Data structure for the graph is <directed graph> implemented with <matrix>
    (direct access).
    Method implement with BFS.

    Assume:
        - Every maze is a square
        - Single start location and single goal location
        - The step_size cannot be less than 0 (from piazza)
        - The start must be black

    Rule:
        Let step size be d.
        When the maze begins, d equals 1.
        When you land on a square with a red arrow, 1 is added to d.
        When you land on a square with a yellow arrow, 1 is subtracted from d.
        Blank squares cannot be landed on.
    """
    visit_dict = {}  # (position, direction, parent_pos): [<step sizes>]

    # initialize the return contents
    path = []
    path_len = 0

    # initialization
    x, y = start_position  # current position -- start position (x, y)

    # initialize start node(s), and enqueue it/them
    init_node = Node(position=None,
                     direction=None,
                     colour=None,
                     depth=0,
                     step_size=0)
    queue = Queue()
    curr_dirs, curr_colour = maze[x][y]
    for direct in curr_dirs:
        start_node = Node(position=(x, y),
                          direction=direct,
                          colour=curr_colour,
                          depth=1,
                          step_size=1)
        start_node.parent = init_node
        queue.enqueue(start_node)

        key = (start_node.position, start_node.direction,
               start_node.parent.position)
        if key not in visit_dict:
            visit_dict[key] = [start_node.step_size]
        else:
            if start_node.step_size not in visit_dict[key]:
                visit_dict[key].append(start_node.step_size)

    # start BFS, until find the shortest path or no path exists
    meet_goal = False
    goal_node = None

    # dequeue one at a time of the curr depth
    allBranchStuck = False
    nodesOfSameDepth = []
    curr_queue_depth = 1
    while (not queue.isEmpty()) and (not meet_goal) and (not allBranchStuck):
        currNode = queue.dequeue()
        x, y = currNode.position
        curr_dir, curr_colour, curr_depth, d = \
            currNode.direction, currNode.colour, \
            currNode.depth, currNode.step_size

        # Queue: depth of items
        # for all nodes whose depth=k, if node stuck, then terminate the program
        # if any node is not stuck, then keep finding the goal
        if curr_depth == curr_queue_depth or \
                currNode.depth == curr_queue_depth + 1:
            nodesOfSameDepth.append(currNode)

        if curr_depth > curr_queue_depth:
            # loop through the <nodesOfSameDepth>, check if all branches stuck
            stuck_res = []
            for node in nodesOfSameDepth:
                stuck_res.append(checkBranchStuckInLoop(node, visit_dict))
            if all(stuck_res) and (stuck_res != []):
                # all branch stuck => terminate the program
                return path, path_len, False
            # update next depth
            nodesOfSameDepth = [currNode]
            curr_queue_depth += 1

        # update step_size of next step
        if curr_colour == 'R':
            d += 1
        elif curr_colour == 'Y':
            if d >= 1:
                d -= 1

        # find next grids with step_size and direction
        if d == 0 and curr_colour == 'Y':
            new_pos = None
        elif curr_dir == 'N':
            new_pos = (x - d, y)
        elif curr_dir == 'S':
            new_pos = (x + d, y)
        elif curr_dir == 'E':
            new_pos = (x, y + d)
        elif curr_dir == 'W':
            new_pos = (x, y - d)
        elif curr_dir == 'NE':
            new_pos = (x - d, y + d)
        elif curr_dir == 'SE':
            new_pos = (x + d, y + d)
        elif curr_dir == 'NW':
            new_pos = (x - d, y - d)
        elif curr_dir == 'SW':
            new_pos = (x + d, y - d)
        else:   # including the case of blank grid
            new_pos = None

        if new_pos is not None:
            r, c = new_pos
            if r >= 0 and c >= 0:
                try:
                    new_grid = maze[r][c]
                    new_dirs, new_colour = new_grid[0], new_grid[1]
                    for new_dir in new_dirs:
                        new_node = Node(position=new_pos,
                                        direction=new_dir,
                                        colour=new_colour,
                                        depth=curr_depth + 1,
                                        step_size=d)
                        new_node.parent = currNode
                        queue.enqueue(new_node)

                        # update <visit_dict>
                        key = (new_node.position, new_node.direction,
                               new_node.parent.position)
                        if key not in visit_dict:
                            visit_dict[key] = [new_node.step_size]
                        else:
                            visit_dict[key].append(new_node.step_size)

                        # break the loop if found the solution
                        if new_node.position == goal:
                            goal_node = new_node
                            meet_goal = True
                            break

                # out of bound case
                except IndexError:
                    continue

    # End of BFS terminated and check if find the goal:
    # if found, trace back the path
    if goal_node is not None:
        curr = goal_node
        while (curr is not None) and (curr.position is not None):
            # insert all valid edges in sequence from start to goal
            path.insert(0, curr.position)
            curr = curr.parent
        path_len = len(path)
        return path, path_len, True
    else:
        return path, path_len, False


def checkBranchStuckInLoop(branch_node, visited_dict):
    """Return if the current path is stuck in a loop"""
    key = (branch_node.position, branch_node.direction,
           branch_node.parent.position)
    stepSize = branch_node.step_size
    lst = visited_dict[key]
    if key not in visited_dict:
        return False
    else:
        if lst.count(stepSize) <= 1:
            return False
        else:   # step_size appear >= 2
            return True


if __name__ == '__main__':

    if len(sys.argv) != 2:    
        print("Usage: python3 Alice.py <inputfilename>")    
        sys.exit()

    """Maze is represented by MATRIX"""
    # PART I: Read from the file, and obtain info: grid_size, maze, start, goal
    print("========= LOAD TXT FILE =========")
    filename = sys.argv[1]
    f = open(filename, 'r')
    print("The chosen txt file is: {}".format(filename))

    # read grid_size, m, where maze is of mxm
    row_size = int(f.readline())
    print("row_size: {}".format(row_size))
    col_size = int(f.readline())
    print("col_size: {}".format(col_size))

    # initialize maze, which is a matrix of m rows and m columns
    maze_matrix = []
    for _ in range(row_size):
        sub = []
        for _ in range(col_size):
            sub.append(())
        maze_matrix.append(sub)

    # read maze and goal_pos
    start_pos = (None, None)  # matrix position of the start
    goal_pos = (None, None)  # matrix position of the goal
    for i in range(row_size):
        row_str = str(f.readline())
        row = row_str.strip().split("; ")
        for j in range(col_size):
            directions, color = row[j][1:-1].split(": ")
            if directions == '(goal)':
                maze_matrix[i][j] = (('goal',), color)
                goal_pos = (i, j)
            else:
                if ',' in directions or len(directions) >= 4:
                    directions = tuple(directions[1:-1].split(', '))
                else:
                    directions = tuple(directions[1:-1])
                maze_matrix[i][j] = (directions, color)

    print("maze: \n {}".format(maze_matrix))

    start = str(f.readline()).strip().rstrip('\n')
    sx, sy = start[1:-1].split(', ')
    start_pos = int(sx), int(sy)
    print("start position: {}".format(start_pos))
    print("goal position: {}".format(goal_pos))

    # PART III: find the shortest path
    print("========= START CONSTRUCTING SHORTEST PATH =========")
    time_start = time.perf_counter()
    res = find_shortest_path(maze_matrix, start_pos, goal_pos)
    time_end = time.perf_counter()
    print("Program output: {}".format(res))
    print("========= RESULT =========")

    if res[2]:
        print("There exists a shortest path to the given maze.")
    else:
        print("No solution to the given maze.")
    path_found = ''
    for s in res[0][:-1]:
        path_found += str(s) + ' -> '
    if res[0]:
        path_found += 'GOAL'
        path_length = res[1]
    else:
        path_found = 'No such path'
        path_length = 'Not applicable'
    print('the path is: {}'.format(path_found))
    print('the length of the path is: {}'.format(path_length))
    print('Time used: {} seconds'.format(time_end - time_start))
