from PIL import Image
import numpy as np
from scipy import ndimage
import os
import sys


def remove_white_background(input_dir: str, output_dir: str, threshold: int = 235, feather: int = 2):
    os.makedirs(output_dir, exist_ok=True)
    files = sorted(f for f in os.listdir(input_dir) if f.endswith(".png"))

    for filename in files:
        path = os.path.join(input_dir, filename)
        img = Image.open(path).convert("RGBA")
        arr = np.array(img)

        rgb = arr[:, :, :3].astype(np.int32)
        is_whiteish = np.all(rgb >= threshold, axis=2)

        labeled, _ = ndimage.label(is_whiteish)
        border_labels = set(labeled[0, :]) | set(labeled[-1, :]) | set(labeled[:, 0]) | set(labeled[:, -1])
        border_labels.discard(0)

        bg_mask = np.isin(labeled, list(border_labels))

        alpha = np.where(bg_mask, 0, 255).astype(np.uint8)
        if feather > 0:
            alpha = ndimage.grey_erosion(alpha, size=feather)
            alpha = ndimage.gaussian_filter(alpha.astype(np.float32), sigma=feather / 2.0)
            alpha = np.clip(alpha, 0, 255).astype(np.uint8)

        arr[:, :, 3] = alpha
        Image.fromarray(arr, mode="RGBA").save(os.path.join(output_dir, filename))

    print(f"Processados {len(files)} frames de '{input_dir}' para '{output_dir}'")


if __name__ == "__main__":
    input_dir = sys.argv[1]
    output_dir = sys.argv[2]
    threshold = int(sys.argv[3]) if len(sys.argv) > 3 else 235
    feather = int(sys.argv[4]) if len(sys.argv) > 4 else 2
    remove_white_background(input_dir, output_dir, threshold, feather)
