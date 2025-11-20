from scene.cameras import Camera
import numpy as np
from utils.general_utils import PILtoTorch
from PIL import Image
from utils.graphics_utils import fov2focal
import torch.nn.functional as F
import torch
import cv2 as cv
import os
WARNED = False

import cv2
import matplotlib.pyplot as plt
from os import makedirs


def gaussian_blur_cv2(img_chw, ks, sigma):
    """
    Gaussian blur μέσω OpenCV.
    img_chw: torch.Tensor [C,H,W], τιμές 0–1
    ks: odd kernel size, π.χ. 5, 7, 9
    sigma: Gaussian sigma
    """
    C, H, W = img_chw.shape
    img_np = img_chw.detach().cpu().permute(1, 2, 0).numpy()  # [H,W,C]
    img_np = cv2.GaussianBlur(img_np, (ks, ks), sigma, borderType=cv2.BORDER_REFLECT)
    img_blur = torch.from_numpy(img_np).permute(2, 0, 1).to(img_chw.device)
    return img_blur
    
def save_image(image_tensor, level, blur_level, resolution, cam_info, id, save_path):
    # Convert the tensor to numpy array, scale it, and ensure it's in uint8 format
    image_np = image_tensor.permute(1, 2, 0).cpu().numpy()  # Convert to HWC format
    image_np = np.clip(image_np * 255, 0, 255).astype(np.uint8)  # Scale and convert to uint8
    
    # Convert the numpy array back to a PIL image
    image_pil = Image.fromarray(image_np)
    
    # Generate a filename for the image based on the pyramid level, blur level, and resolution
    image_name = f"cam_{cam_info.uid}_level_{level}_blur_{blur_level}_res_{resolution[0]}x{resolution[1]}.png"
    
    # Save the image to the specified path
    image_pil.save(os.path.join(save_path, image_name))




def loadCam(args, id, cam_info, resolution_scales, blur_levels, resize_to_original=True):
    save_path = os.path.join(args.model_path, "debug_images")
    os.makedirs(save_path, exist_ok=True)   
    orig_w, orig_h = cam_info.image.size

    if args.resolution in [1, 2, 4, 8]:
        resolution = round(orig_w/(1.0 * args.resolution)), round(orig_h/(1.0 * args.resolution))
        # print("Resolution: ", args.resolution)  
        
    else:  # should be a type that converts to float
        if args.resolution == -1:
            if orig_w > 1600:
                global WARNED
                if not WARNED:
                    print("[ INFO ] Encountered quite large input images (>1.6K pixels width), rescaling to 1.6K.\n "
                        "If this is not desired, please explicitly specify '--resolution/-r' as 1")
                    WARNED = True
                global_down = orig_w / 1600
            else:
                global_down = 1
        else:
            global_down = orig_w / args.resolution

        scale = float(global_down) * float(1.0)
        resolution = (int(orig_w / scale), int(orig_h / scale))
        

    resized_image_rgb = PILtoTorch(cam_info.image, resolution)

    gt_image = resized_image_rgb[:3, ...]
    downed_image = gt_image.permute(1, 2, 0).cpu().numpy()
    image_pyramid = []
    up_image_pyramid = []
    last_size=None
    size_list=[]
    last_resolution=0

    # Apply blur and downscale for each level of the pyramid
    for i in range(resolution_scales[0] + 1):
        if i in resolution_scales:
            if  resolution_scales[i] == 2:  # Level 2: No scaling (same resolution as Level 1)
                image = gt_image.permute(1, 2, 0).cpu().numpy()

                # Apply blur for each blur level
                for j in range(len(blur_levels)):
                    if j == 2:
                        sigma =6.0
                        kernel_size =25 # Larger kernel for the first level
                    elif j == 1:
                        sigma = 4.0
                        kernel_size = 13
                    elif j == 0:
                        blurred_image = torch.from_numpy(image).permute(2, 0, 1).float()  # No blur for this level
                    else:
                        continue

                    if j != 0:
                        blurred_image = gaussian_blur_cv2(torch.from_numpy(image).permute(2, 0, 1).float(), ks=kernel_size, sigma=sigma)

                    # Store the blurred image in the pyramid
                    image_pyramid.append(Camera(colmap_id=cam_info.uid, R=cam_info.R, T=cam_info.T,
                                                FoVx=cam_info.FovX, FoVy=cam_info.FovY,
                                                image=blurred_image, gt_alpha_mask=None,
                                                image_name=cam_info.image_name, uid=id, data_device=args.data_device))
                    # save_image(blurred_image, i, j, resolution, cam_info, id, save_path)
    
            else:              

                # Apply blur for each blur level
                for j in range(len(blur_levels)):
                    if j == 2:
                        sigma = 6.0
                        kernel_size = 25  # Larger kernel for the first level
                    elif j == 1:
                        sigma = 4.0
                        kernel_size = 13

                    elif j == 0:
                        blurred_image = torch.from_numpy(downed_image).permute(2, 0, 1).float()  # No blur for this level
                    else:
                        continue

                    if j != 0:
                        blurred_image = gaussian_blur_cv2(torch.from_numpy(downed_image).permute(2, 0, 1).float(), ks=kernel_size, sigma=sigma)

                    # Store the blurred image in the pyramid
                    image_pyramid.append(Camera(colmap_id=cam_info.uid, R=cam_info.R, T=cam_info.T,
                                                FoVx=cam_info.FovX, FoVy=cam_info.FovY,
                                                image=blurred_image, gt_alpha_mask=None,
                                                image_name=cam_info.image_name, uid=id, data_device=args.data_device))
                    
                    # Save the image for each level and blur combination
                    # save_image(blurred_image, i, j, resolution, cam_info, id, save_path)
                    

                loaded_mask = None
                last_resolution=i
        last_size=downed_image.shape
        size_list.append(last_size)
        downed_image = cv.pyrDown(downed_image)
    image_pyramid.reverse() 
    
    
    # print("Image Pyramid:")
    # for idx, cam in enumerate(image_pyramid):
    #     print(f" Level {idx}: Image Size = ({cam.image_width}, {cam.image_height})")    

    return image_pyramid



def cameraList_from_camInfos(cam_infos, resolution_scales,blur_levels, args, resize_to_original=True):
    camera_list = []
    for i in range(len(resolution_scales)*len(blur_levels)):
        camera_list.append([])
    for id, c in enumerate(cam_infos):
        cam_pyramid = loadCam(args, id, c, resolution_scales,blur_levels,resize_to_original=resize_to_original)
        for i in range(len(resolution_scales)*len(blur_levels)):
            camera_list[i].append(cam_pyramid[i])
        

    return camera_list

def camera_to_JSON(id, camera : Camera):
    Rt = np.zeros((4, 4))
    Rt[:3, :3] = camera.R.transpose()
    Rt[:3, 3] = camera.T
    Rt[3, 3] = 1.0

    W2C = np.linalg.inv(Rt)
    pos = W2C[:3, 3]
    rot = W2C[:3, :3]
    serializable_array_2d = [x.tolist() for x in rot]
    camera_entry = {
        'id' : id,
        'img_name' : camera.image_name,
        'width' : camera.width,
        'height' : camera.height,
        'position': pos.tolist(),
        'rotation': serializable_array_2d,
        'fy' : fov2focal(camera.FovY, camera.height),
        'fx' : fov2focal(camera.FovX, camera.width)
    }
    return camera_entry


