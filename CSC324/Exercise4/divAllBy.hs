import Data.List

divAllBy :: Integral a => a -> [a] -> [a]
divAllBy num = map (div num)

-- Seems pretty nice...
--take 10 (divAllBy 50 [1..])

-- until...
--divAllBy 50 [1,2,3,4,5,0]

-- 1. Maybe [a]
divAllByV2 :: Integral a => a -> [a] -> Maybe [a]
divAllByV2 _ [] = Just []
divAllByV2 n (0 : xs) = Nothing
divAllByV2 n (x : xs) = fmap (\ rest -> (div n x) : rest) (divAllByV2 n xs)

-- 2. [Maybe a]
divAllByV3 :: Integral a => a -> [a] -> [Maybe a]
divAllByV3 n l = fmap f l where
   f 0 = Nothing
   f m = Just (div n m)
