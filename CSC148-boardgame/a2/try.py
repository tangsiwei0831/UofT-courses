def f1(x):
    y = 0
    for i in range(1, x + 1):
        y += 1/((100 - x + 1)**2)
    return y

def f2(x):
    y = 0
    for i in range(1, x + 1):
        y += 1/(100 - x + 1)
    return y

c1 = f1(20)
c2 = f1(50)
c3 = f2(20)
c4 = f2(50)
a2 = (c1*c2)/(c2*(c3**2)+c1*(c4**2))
print(a2)
a1 = (c2*c3)/(c2*(c3**2)+c1*(c4**2))
print(a1)

