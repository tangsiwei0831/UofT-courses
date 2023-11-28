import matplotlib.pyplot as plt
import numpy as np
from mpldatacursor import datacursor
import matplotlib.patches as patches
import cv2

# 1) 
hallway1 = cv2.imread("hallway1.jpg", cv2.IMREAD_GRAYSCALE)
hallway2 = cv2.imread("hallway2.jpg", cv2.IMREAD_GRAYSCALE)
hallway3 = cv2.imread("hallway3.jpg", cv2.IMREAD_GRAYSCALE)

fig, ax = plt.subplots()

def plot_image(image, points, ax):
    ax.imshow(image)
    for point in points:
        rect = patches.Rectangle(point, 30, 30, linewidth=1, edgecolor='r', facecolor='none')
        ax.add_patch(rect)
    datacursor(display='single')
    plt.show()

def Switch_Case(switch):
    """
    Input A, B or C to choose among the three cases.
    """
    if switch == 'A':
        points1 = [(948, 391), (988, 201), (1095, 175), (950, 264)]
        points2 = [(812, 702), (838, 519), (944, 490), (806, 577)]
        img1 = hallway1
        img2 = hallway2
    elif switch == 'B':
        points1 = [(948, 391), (988, 201), (1095, 175), (950, 264)]
        points2 = [(883, 579), (899, 394), (961, 364), (879, 455)]
        img1 = hallway1
        img2 = hallway3
    else:
        points1 = [(596, 492), (718, 545), (498, 739), (790, 611)]
        points2 = [(560, 809), (520, 865), (826, 856), (798, 818)]
        img1 = hallway1
        img2 = hallway3
    return (points1, points2, img1, img2)

case = Switch_Case('C') # change switches here
#plot_image(data[3], data[1], ax) # uncomment to plot first image with points
#plot_image(data[4] data[2], ax) # uncomment to plot second image with points

# 2)
def find_homography(data):
    A = []
    for i in range(4):
        x, y = data[0][i][0], data[0][i][1]
        u, v = data[1][i][0], data[1][i][1]
        A.append([x, y, 1, 0, 0, 0, -u*x, -u*y, -u])
        A.append([0, 0, 0, x, y, 1, -v*x, -v*y, -v])
    A = np.asarray(A)
    U, S, Vh = np.linalg.svd(A)
    L = Vh[-1, :] / Vh[-1, -1]
    H = L.reshape(3,3)
    return H

H = find_homography(case)
# print(H)

# 3)
def transfer(x, y):
    res = []
    for i in H:
        j = i[0]*x + i[1]*y + i[2]
        res.append(j)
    return res

def transfer_points(ax, original_points, target_points, target_image):
    """
    square the estimate points and chosen points on image
    """
    ax.imshow(target_image)
    for point in original_points:
        x, y = point
        res = transfer(x, y)
        rect = patches.Rectangle((round(res[0]),round(res[1])), 30, 30, linewidth=1, edgecolor='yellow', facecolor='none')
        ax.add_patch(rect)
    for point in target_points:
        rect = patches.Rectangle(point, 30, 30, linewidth=1, edgecolor='r', facecolor='none')
        ax.add_patch(rect)
    datacursor(display='single')
    plt.show()
    return res

# transfer_points(ax, data[0], data[1], data[3]) # uncomment to plot points on image

# 4)
blank_image = np.zeros((1500,1600,3), np.uint8)
blank_image[101: 1101, 9:1513, 2] = case[2]

def corres(img, target_img):
    for i in range(len(img)):
        for j in range(len(img[i])):
            res = transfer(i, j)
            a, b = round(res[0]/res[2]), round(res[1]/res[2])
            if 0 <= a < len(target_img):
                if 0 <= b < len(target_img[a]):
                    img[i][j][0] = target_img[a][b]
                    img[i][j][1] = target_img[a][b]
    return img

result_img = corres(blank_image, case[3])

cv2.imshow('img', result_img) # uncomment to plot generated image
cv2.waitKey(0)