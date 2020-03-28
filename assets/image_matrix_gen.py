#!/usr/bin/python3
# 18500 Capstone S20
# Eric Chen, Alton Olsen, Deanyone Su
#
# Short python script to generate RGB values from a local image

import cv2
from sys import argv

# get filename from command line, get RGB values
img_matrix = cv2.imread(argv[1])
# img_matrix = cv2.fastNlMeansDenoisingColored(img_matrix, None, 10, 10, 3, 9)
color_matrix = []

# scan through img_matrix and scale RGB values by A/255
row_count = len(img_matrix)
col_count = len(img_matrix[0])
print("Ingested image dimensions: %d x %d" % (col_count, row_count))
blue_value, green_value, red_value = cv2.split(img_matrix)
for i in range(row_count):
    for j in range(col_count):
        r_value = hex(red_value[i][j]).strip('0x').zfill(2)
        g_value = hex(green_value[i][j]).strip('0x').zfill(2)
        b_value = hex(blue_value[i][j]).strip('0x').zfill(2)
        if (int(red_value[i][j]) + \
            int(green_value[i][j]) + \
            int(blue_value[i][j]) < 40):
            r_value = '40'
            g_value = '40'
            b_value = '40'
        color_matrix.append(r_value + g_value + b_value)
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
write_contents.append('WIDTH = 24;\n')
write_contents.append('ADDRESS_RADIX = DEC;\n')
write_contents.append('DATA_RADIX = HEX;\n')
write_contents.append('CONTENT BEGIN\n\n')

for color_idx in range(len(color_matrix)):
    write_contents.append("%d: %s;\n" % (color_idx, color_matrix[color_idx]))

write_contents.append('\nEND;\n')
data_file.writelines(write_contents)
data_file.close()
