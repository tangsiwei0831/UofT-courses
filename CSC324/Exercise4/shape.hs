data Shape = Rect Double Double
           | Circle Double

area (Rect x y) = x * y
area (Circle x) = x * x * 3.14

a = Rect 2 4
b = Circle 3

doubleArea x = 2 * (area x)

totArea l = foldl (+) 0 (map area l)

main = print (totArea [a, b])
