#!/usr/bin/python3
# 18500 Capstone S20
# Eric Chen, Alton Olsen, Deanyone Su
#
# Short python script to generate RGB values from a local image

import imageio
from sys import argv

# get filename from command line, get RGB values
img_matrix = imageio.imread(argv[1], as_gray=False, pilmode='RGB')
color_matrix = []

# scan through img_matrix and scale RGB values by A/255
row_count = len(img_matrix)
col_count = len(img_matrix[0])
print("Ingested image dimensions: %d x %d" % (col_count, row_count))
for i in range(row_count):
    for j in range(col_count):
        red_value = bin(int(img_matrix[i][j][0])).strip('0b')\
            .zfill(8)[:5]
        green_value = bin(int(img_matrix[i][j][1])).strip('0b')\
            .zfill(8)[:6]
        blue_value = bin(int(img_matrix[i][j][2])).strip('0b')\
            .zfill(8)[:5]
        # print("Row %d, Col %d" % (i, j))
        # print(red_value)
        # print(green_value)
        # print(blue_value)
        if (int(img_matrix[i][j][0]) > 220 and\
            int(img_matrix[i][j][0]) > 220 and\
            int(img_matrix[i][j][0]) > 220):
            red_value = '00100'
            green_value = '000100'
            blue_value = '00100'
        color_matrix.append("".join([red_value, green_value, blue_value]))
# write file
if (argv[2][-4:] != '.mif'):
    print('Provided output file is not .mif file')
    exit()
data_file = open(argv[2], 'w');
write_contents = []
write_contents = ['%\n']
write_contents.append('18500 Capstone S20\n')
write_contents.append('Eric Chen, Alton Olsen, Deanyone Su\n\n')
write_contents.append('This is an autogenerated .mif file containing color ' + \
    'data stripped from a\nprovided local image\n')
write_contents.append('%\n\n')

write_contents.append('DEPTH = %d;\n' % ((i+1) * (j+1)))
write_contents.append('WIDTH = 16;\n')
write_contents.append('ADDRESS_RADIX = DEC;\n')
write_contents.append('DATA_RADIX = BIN;\n')
write_contents.append('CONTENT BEGIN\n\n')

for color_idx in range(len(color_matrix)):
    write_contents.append("%d: %s;\n" % (color_idx, color_matrix[color_idx]))

write_contents.append('\nEND;\n')
data_file.writelines(write_contents)
data_file.close()
