
from rembg import remove, new_session
from PIL import Image
import io
import urllib.request

req = urllib.request.urlopen('https://raw.githubusercontent.com/danielgatis/rembg/master/examples/animal-1.jpg')
img_bytes = req.read()

session = new_session('u2netp')
output_bytes = remove(img_bytes, session=session)

img = Image.open(io.BytesIO(output_bytes))
print(f'Format: {img.format}, Mode: {img.mode}, Size: {img.size}')
img.save('output.png')

