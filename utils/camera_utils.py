from scene.cameras import Camera
import numpy as np
from utils.general_utils import PILtoTorch
from utils.graphics_utils import fov2focal
import torch
import cv2 as cv
import torch.nn.functional as F
from PIL import Image
import cv2
import matplotlib.pyplot as plt
WARNED = False

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

def loadCam(args, id, cam_info, resolution_scale, blur_levels, resize_to_original=False):
    orig_w, orig_h = cam_info.image.size

    if args.resolution in [1, 2, 4, 8]:
        resolution = round(orig_w/(1.0 * args.resolution)), round(orig_h/(1.0 * args.resolution))
    else:  
        if args.resolution == -1:
            if orig_w > 1600:
                global WARNED
                if not WARNED:
                    print("[ INFO ] Rescaling to 1.6K because of large images.")
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
   

    # Apply blur for each level
    for i in range(blur_levels[0] + 1):
        if i in blur_levels:
            if i == blur_levels[0]:  # Last resolution level (highest resolution)
                # Do not apply any blur for the last resolution level
                image_pyramid.append(Camera(colmap_id=cam_info.uid, R=cam_info.R, T=cam_info.T,
                                         FoVx=cam_info.FovX, FoVy=cam_info.FovY,
                                         image=torch.from_numpy(downed_image).permute(2, 0, 1).float(), gt_alpha_mask=None,
                                         image_name=cam_info.image_name, uid=id, data_device=args.data_device))
            else:
                if i == 0:
                    sigma = 4.0 #2.0
                    kernel_size = 25 #13
                elif i == 1:
                    sigma = 2.0 #1.0
                    kernel_size = 13 #7


    
                # Apply Gaussian blur
                blurred_image = gaussian_blur_cv2(torch.from_numpy(downed_image).permute(2, 0, 1).float(), ks=kernel_size, sigma=sigma)


                image_pyramid.append(Camera(colmap_id=cam_info.uid, R=cam_info.R, T=cam_info.T,
                                            FoVx=cam_info.FovX, FoVy=cam_info.FovY,
                                            image=blurred_image, gt_alpha_mask=None,
                                            image_name=cam_info.image_name, uid=id, data_device=args.data_device))


            # if resize_to_original:
            #     uped_resized_image = blurred_image.permute(1, 2, 0).cpu().numpy()
            #     blurred_image = torch.from_numpy(uped_resized_image).permute(2, 0, 1).float()


    # image_pyramid.reverse()

    return image_pyramid





def cameraList_from_camInfos(cam_infos, resolution_scale,blur_levels, args, resize_to_original=True):
    camera_list = []
    for i in range(len(blur_levels)):
        camera_list.append([])
    for id, c in enumerate(cam_infos):
        cam_pyramid = loadCam(args, id, c, resolution_scale,blur_levels,resize_to_original=resize_to_original)
        for i in range(len(blur_levels)):
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
