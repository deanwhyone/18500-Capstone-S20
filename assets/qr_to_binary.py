#!/usr/bin/python3
# 18500 Capstone S20
# Eric Chen, Alton Olsen, Deanyone Su
#
# Short python script to generate RGB values from a local image

import imageio
from sys import argv

def isWhite(rgb_array):
    [red, green, blue] = rgb_array
    if (red > 224 and green > 224 and blue > 224):
        return True
    else:
        return False

def chunks(lst, n):
    packed = []
    for i in range(0, len(lst), n):
        chunk = lst[i:i + n]
        chunk.append('\n')
        block = ''.join(chunk)
        packed.append(block)
    return packed

# get filename from command line, get RGB values
img_matrix = imageio.imread(argv[1], pilmode='RGB')
tiles_binary = []

row_count = len(img_matrix)
col_count = len(img_matrix[0])

row_stride = round(row_count / 37)
col_stride = round(row_count / 37)

row_val = row_stride // 2
col_val = col_stride // 2

for i in range(37):
    for j in range(37):
        if (isWhite(img_matrix[row_val][col_val])):
            tiles_binary.append(0)
        else:
            tiles_binary.append(1)
        col_val += col_stride
    row_val += row_stride
    col_val = col_stride // 2

tiles_binary = [str(i) for i in tiles_binary]
tiles_binary = chunks(tiles_binary, 37)

data_file = open(argv[2], 'w');

data_file.writelines(tiles_binary)
data_file.close()
