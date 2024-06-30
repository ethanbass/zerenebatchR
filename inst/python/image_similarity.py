import cv2
from skimage import metrics
import os
import pandas
import itertools
import numpy
import re

def sort_image_files(file_paths):
    def extract_numbers(file_path):
        # Extract the file name from the path
        file_name = os.path.basename(file_path)
        # Extract the numbers from the file name
        match = re.search(r'IMG_(\d+)(?:_(\d+))?\.JPG', file_name, re.IGNORECASE)
        if match:
            main_number = int(match.group(1))
            sub_number = int(match.group(2)) if match.group(2) else 0
            return (main_number, sub_number)
        return (0, 0)  # Return (0, 0) if no match found
    # Sort the file paths based on the extracted numbers
    return sorted(file_paths, key=extract_numbers)

def absolute_file_paths(directory, ext="jpg"):
    path = os.path.abspath(directory)
    paths = [
        entry.path 
        for entry in os.scandir(path) 
        if entry.is_file() 
        and entry.name.lower().endswith(ext) 
        and not entry.name.startswith('.')
    ]
    return sort_image_files(paths)

def calculate_ssim(image1, image2):
    try:
        # Load images
        image1 = cv2.imread(image1)
        image2 = cv2.imread(image2)
        image2 = cv2.resize(image2, (image1.shape[1], image1.shape[0]), interpolation = cv2.INTER_AREA)
        print(image1.shape, image2.shape)
        # Convert images to grayscale
        image1_gray = cv2.cvtColor(image1, cv2.COLOR_BGR2GRAY)
        image2_gray = cv2.cvtColor(image2, cv2.COLOR_BGR2GRAY)
        # Calculate SSIM
        ssim_score = metrics.structural_similarity(image1_gray, image2_gray, full=True)
        return(ssim_score[0])
    except:
        return(numpy.float64('nan'))

def apply_pairwise(values, function):
    def pairwise(iterable):
        a, b = itertools.tee(iterable)
        next(b, None)
        return zip(a, b)
    pairs = itertools.islice(pairwise(values), 1, None)
    yield from itertools.chain([None], itertools.starmap(function, pairwise(values)))
    
def image_similarity(path_in, path_out, ext="jpg"):
    if isinstance(path_in, list):
        paths = path_in
    else:
        paths = absolute_file_paths(path_in, ext=ext)
    gen = apply_pairwise(paths, calculate_ssim)
    next(gen, None)
    pandas.DataFrame(gen, index = paths[1:], columns=["similarity"]).to_csv(path_out, index=True)
