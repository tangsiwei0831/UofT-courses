-- CSC324 — 2023W — Exercise 4

-- Due: Mon Mar 13th 5PM.

-- Section I: Practicing Haskell programming

-- In this exercise section, we are going to implement an integer set with binary search tree. The goal
-- of this section is to practice the Haskell programming and get us familiar with data constructors,
-- recursions, pattern machines, and type systems in Haskell.
--
-- We define our customized type Tree as follows. It has two alternative form. It can either be Nil
-- represetning an empty state or Node with an integer value and two subtrees. The first Tree will
-- be the left subtree and the second Tree will be the right subtree. Note that in a binary search
-- tree, every element in the left subtree should be smaller than the root and every element in
-- the right subtree should be greater than the root.
data Tree = Nil
          | Node Tree Int Tree

-- We next write an utility function that traverse the tree in a depth first fashion. If the elements
-- in the tree satisfy the property of a binary search tree. This function will have the following 
-- type signature. It takes Tree and produces a list of Int.
treeToList :: Tree -> [Int]
-- Please fill the ... to finish the implementation. 
-- Hint: ++ is the operator in Haskell to concatenate two lists.

treeToList Nil = []
treeToList (Node t1 v t2) = treeToList t1 ++ [v] ++ treeToList t2

-- We next will implement an insert function to insert a new element into a binary search tree.
insert :: Tree -> Int -> Tree
-- The base case is inserting into an empty tree.
insert Nil v = Node Nil v Nil
-- Haskell provides a very convenient guard syntax to help avoiding verbose nested if conditions.
-- You can use vertical bar to list conditions for each case, the equal sign will saperate the condition
-- and the value. For example, because we are implementing a set, in the case that we found the
-- same value in the tree, we will make the tree unchanged. Note that "otherwise" in guard syntax
-- corresponds to the default case.
-- Please fill the ... to finish the implementation
insert (Node t1 v0 t2) v
  | v == v0 = Node t1 v0 t2
  | v < v0 = Node (insert t1 v) v0 t2
  | otherwise = Node t1 v0 (insert t2 v)

-- We will also implement a function that tests whether an integer exists in the tree or not. This function
-- takes a tree and an integer as parameters. Please fill its type signature.
contains :: Tree -> Int -> Bool
-- In the base case, we always return false.
contains Nil v = False
-- In the recursive case, we are going to compare the value v with the root value v0 again.
-- Please fill the ... to finish the implementation
contains (Node t1 v0 t2) v
  | v == v0 = True
  | v < v0 = contains t1 v
  | otherwise = contains t2 v

-- We will also implement a function that deletes an integer from a tree. Note that if the integer does not 
-- exist, the tree will be unchanged. Fill the type signature of this function.
delete :: Tree -> Int -> Tree

delete Nil v = Nil
-- The challenge of implementing delete is that removing the root of a tree will break its structure. We will
-- use a subroutine called deleteRoot to do just that. Please fill ... to finish the implementation of delete.
delete (Node t1 v0 t2) v
  | v == v0 = deleteRoot (Node t1 v0 t2)
  | v < v0 = Node (delete t1 v) v0 t2
  | otherwise = Node t1 v0 (delete t2 v)

-- Now we are going to impelment the subroutine deleteRoot, which is removing the root element of a tree and
-- return the modified tree. Please complete its type signature and the implementation.
deleteRoot :: Tree -> Tree
-- This should never happen, so we return Nil in this impossible case.
deleteRoot Nil = Nil
-- In the cases where one of the subtree is Nil, removing the root will be just returning the remaining subtree.
deleteRoot (Node Nil v0 t2) = t2
deleteRoot (Node t1 v0 Nil) = t1
-- In this case, after removing the root, we will want to find the smallest element v in t2 to be the root. Remove
-- v from t2. And build the new tree. We create another subroutine leftmost to find the leftmost element. Fill
-- ... to finish the implementation.
deleteRoot (Node t1 v0 t2) = 
  let
    v = leftmost t2
    deleted = delete t2 v
  in
    Node t1 v deleted

-- The function leftmost returns the leftmost element inside a tree. Please compelte its type signature and its
-- implementation.
leftmost :: Tree -> Int
leftmost Nil = 0
leftmost (Node Nil v Nil) = v
leftmost (Node Nil v right) = v
leftmost (Node t1 x y) = leftmost t1

-- If you finish the above tasks correctly, you will be able to use ghc to compile the program. The execution
-- will generate the following output:
-- [1,2,4,10]
-- False
-- True
-- False
-- [1,2,10]
--
-- You should write additional test cases to check your implementation before you submit.

a = Nil
b = insert (insert a 4) 2
c = insert b 1
d = insert c 10
e = delete d 4
f = leftmost e
g = delete e 1
h = leftmost g


-- Section II: Type Classes

-- Consider the following abstract data type (ADT) for simple expressions:

data Expr a = Const a | Sum (Expr a) (Expr a) | Mul (Expr a) (Expr a) | Div (Expr a) (Expr a)

-- Define a recursive evaluation function eval for expressions. 
-- Test the function on a couple of simple expressions. 

-- eval ....
eval :: Num a => Expr a -> a
eval (Const x) = x
eval (Sum e1 e2) = eval e1 + eval e2
eval (Mul e1 e2) = eval e1 * eval e2

-- Hint: eval (Sum (Mul (Const 2) (Const 3)) (Const 4))
-- should evaluate to 10.



-- Enrich the above expressions with a new constructor Div (Expr a) (Expr a) and 
-- write an evaluation function safeEval for these extended expressions, interpreting Div as integer division. 
-- Test the new function with some expressions.

-- safeEval ...
safeEval :: (Integral a) => Expr a -> Maybe a
safeEval (Const n) = Just n
safeEval (Sum e1 e2) = safeEval e1 >>= \x ->
                       safeEval e2 >>= \y ->
                       Just (x + y)
                        
safeEval (Mul e1 e2) = safeEval e1 >>= \x ->
                       safeEval e2 >>= \y ->
                       Just (x * y)
                        

safeEval (Div e1 e2) = case (safeEval e1, safeEval e2) of
                        (e1, Just 0) -> Nothing
                        (Just x, Just y) -> Just (div x y)
-- Hint: Function safeEval must be partial, since division by zero is undefined, and 
-- thus it must return a Maybe value. 

main = do
  print (treeToList d)
  print (contains e 3)
  print (contains e 2)
  print (contains e 4)
  print (treeToList e)
  print f
  print (treeToList g)
  print h

  print (eval (Sum (Const 5)(Mul (Const 7) (Const 9))))
  print (eval (Sum (Mul (Const 5) (Const 7)) (Const 9)))

  print (safeEval (Div (Const 14) (Const 7)) )
  print(safeEval (Div (Const 10) (Const 0)))