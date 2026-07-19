import sys
import os
from PIL import Image

def remove_background(input_path, output_path):
    try:
        from rembg import remove
    except ImportError:
        print("ERROR: rembg is not installed. Please run 'pip install rembg'")
        sys.exit(1)
        
    if not os.path.exists(input_path):
        print(f"ERROR: Input file does not exist: {input_path}")
        sys.exit(1)

    try:
        # Open the input image
        input_image = Image.open(input_path)
        
        # Remove background
        output_image = remove(input_image)
        
        # Save output image as PNG to support transparency
        output_image.save(output_path, "PNG")
        print("SUCCESS")
    except Exception as e:
        print(f"ERROR: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python remove_bg.py <input_path> <output_path>")
        sys.exit(1)
        
    remove_background(sys.argv[1], sys.argv[2])
