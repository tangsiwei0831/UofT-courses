data Rectangle = Rect Double Double
data CircleShape = Circle Double

class Shape a where
  area :: a -> Double

instance Shape Rectangle where
  area (Rect x y) = x * y

instance Shape CircleShape where
  area (Circle x) = x * x * 3.14

a = Rect 2 4
b = Circle 3

doublearea x = 2 * (area x)

-- totArea l = foldl (+) 0 (map area l)

-- main = print (totArea [a, b])

main = print (doublearea a)
