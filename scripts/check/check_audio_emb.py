"""
增强版audio_emb筛查，确保audio_emb.pt的帧数与video.mp4一致。
"""
import os
import torch
import subprocess
from tqdm import tqdm
from concurrent.futures import ProcessPoolExecutor, as_completed
import cv2
import argparse

THRESHOLD = 10  # 允许的帧数差异阈值

def get_video_frame_count(video_path):
    cap = cv2.VideoCapture(video_path)
    frames = cap.get(cv2.CAP_PROP_FRAME_COUNT)
    cap.release()
    return frames


def process_file(pt_file, input_dir, output_dir):
    """处理单个 .pt 文件"""
    pt_path = os.path.join(output_dir, pt_file)
    video_file = pt_file.replace(".pt", ".mp4")
    video_path = os.path.join(input_dir, video_file)
    
    if not os.path.exists(video_path):
        return None  # 如果对应的.mp4文件不存在，跳过
    
    try:
        pt_data = torch.load(pt_path, weights_only=False)['global_embeds']  # 避免 FutureWarning
        pt_frame_count = len(pt_data)
    except Exception as e:
        print(f"Error loading {pt_file}: {e}")
        return None
    
    video_frame_count = get_video_frame_count(video_path)
    if video_frame_count == -1:
        print(f"Failed to retrieve frame count for {video_file}")
        return None
    
    distance = abs(pt_frame_count - int(video_frame_count * 50 / 24))  # 计算帧数差异
    if distance > THRESHOLD:
        return pt_file, pt_frame_count, int(video_frame_count * 50 / 24), distance
    return None

def check_frame_mismatch(input_dir, output_dir, output_file, num_workers):
    mismatched_files = []
    pt_files = [f for f in os.listdir(output_dir)]
    
    with ProcessPoolExecutor(num_workers) as executor:
        future_to_file = {executor.submit(process_file, pt_file, input_dir, output_dir): pt_file for pt_file in pt_files}
        for future in tqdm(as_completed(future_to_file), total=len(pt_files), desc="Checking mismatched frames"):
            result = future.result()
            if result:
                mismatched_files.append(result)

    # # 串行版本
    # for pt_file in tqdm(pt_files, desc="Checking frames"):
    #     result = process_file(pt_file, input_dir, output_dir)
    #     if result:
    #         mismatched_files.append(result)
    
    # 保存到输出文件
    with open(output_file, "w") as f:
        for file in mismatched_files:
            f.write(f"{file[0]}\t{file[1]}\t{file[2]}\t{file[3]}\n")
    
    print(f"Check complete. Found {len(mismatched_files)} mismatched files. Details saved in {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Check face embedding frame mismatch")
    parser.add_argument('--input_dir', type=str, required=True, help="Input directory containing video files")
    parser.add_argument('--output_dir', type=str, required=True, help="Output directory containing .pt files")
    parser.add_argument('--output_file', type=str, default="./results/mismatched_audio_files.txt", help="Output file to save mismatched files")
    parser.add_argument('--num_workers', type=int, default=32, help="Number of worker processes for parallel processing")
    args = parser.parse_args()

    os.makedirs(os.path.dirname(args.output_file), exist_ok=True)  # 确保输出目录存在
    check_frame_mismatch(args.input_dir, args.output_dir, args.output_file, args.num_workers)
