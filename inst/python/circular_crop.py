import glob
import numpy as np
from pathlib import Path

import cv2
import skimage 

from skimage import data, color
from skimage.transform import hough_circle, hough_circle_peaks
from skimage.feature import canny
from skimage.draw import circle_perimeter
from skimage.util import img_as_ubyte
from skimage.io import imread
from skimage.color import rgb2gray

def return_path_out(path, dir_out = None):
    p = Path(path)
    if dir_out is None:
        dir_out = p.parent
    else:
        dir_out = Path(dir_out)
    base_name = p.stem
    ext = p.suffix
    path_out = str(dir_out.joinpath(base_name + "_crop" + ext))
    return path_out

def crop_circle(path, radius, dir_out = None, sigma = 1, lt = 0.2, crop_factor = .97, crop = True):
    image = img_as_ubyte(imread(path))
    gray_image = rgb2gray(image)
    scale_factor = 1/20
    scaled_image = skimage.transform.rescale(gray_image, scale = scale_factor)
    edges = skimage.feature.canny(scaled_image, sigma = sigma, low_threshold = lt)
    hough_radii = np.arange(radius[0]*scale_factor, radius[1]*scale_factor, 50*scale_factor)
    hough_res = skimage.transform.hough_circle(edges, hough_radii)
    accums, cx, cy, radii = skimage.transform.hough_circle_peaks(hough_res, hough_radii, total_num_peaks = 1)
    center = (cx[0]*20, cy[0]*20)
    radius = (radii[0]*crop_factor*20).astype(int)
    mask = np.zeros_like(image, dtype=np.uint8)
    # Create 2D coordinates grid
    x, y = np.meshgrid(np.arange(image.shape[1]), np.arange(image.shape[0]))
    # Draw a filled circle on the mask
    mask[((x - center[0])**2 + (y - center[1])**2) <= radius**2] = 255
    # Set values outside the circle to white (255)
    result = np.where(mask == 255, image, 255)
    if crop:
    	# Calculate the bounding box of the circular region
        x = max(0, int(center[0] - radius))
        y = max(0, int(center[1] - radius))
        d = int(2 * radius)
        # Crop the image to the bounding box
        result = result[y:y+d, x:x+d]
    result_bgr = cv2.cvtColor(result, cv2.COLOR_RGB2BGR)	
    path_out = return_path_out(path, dir_out = dir_out)
    cv2.imwrite(path_out, result_bgr, [int(cv2.IMWRITE_JPEG_QUALITY), 100])

def crop_images(path, path_out, radius = [2200,2400], crop_factor = 0.9):
	files = glob.glob(path)
	for path in files:
	    crop_circle(path, radius = radius, crop_factor=crop_factor, dir_out = path_out)