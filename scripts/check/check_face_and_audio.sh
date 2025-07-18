#!/bin/bash

# ==== 可配置参数 ====
ROOT="/mnt/nvme2n1/smith/xidong/codebase"    # 项目根目录
CHECK="face-info"    # 检查的内容，"face-info" 或 "audio-emb"
cd "$ROOT"

DATASET="TalkVid-test-10k"      # 训练的数据集名称, e.g., TalkVid, HDTF
DATA_PREFIX="/mnt/nvme2n1/smith/xidong/codebase/data"               # 存放数据集的路径前缀
INPUT_DIR="$DATA_PREFIX/$DATASET/videos-crop"                       # 先进行face-crop，作为输入视频目录
OUTPUT_AUDIO_DIR="$DATA_PREFIX/$DATASET/short_clip_aud_embeds"      # 输出目录，用于存储提取的音频信息
OUTPUT_FACE_DIR="$DATA_PREFIX/$DATASET/new_face_info"               # 输出目录，用于存储提取的面部信息
NUM_WORKERS=64          # CPU多进程数
cd "$(dirname "$0")"    # 切换到脚本所在目录

# ==== 启动检查任务 ====
export CUDA_VISIBLE_DEVICES=3
echo -e "check face_info, \ninput_dir: $INPUT_DIR, \noutput_dir: $OUTPUT_FACE_DIR"
python check_face_info.py \
    --input_dir "$INPUT_DIR" \
    --output_dir "$OUTPUT_FACE_DIR" \
    --num_workers $NUM_WORKERS

echo -e "\ncheck audio_emb, \ninput_dir: $INPUT_DIR, \noutput_dir: $OUTPUT_AUDIO_DIR"
python check_audio_emb.py \
    --input_dir "$INPUT_DIR" \
    --output_dir "$OUTPUT_AUDIO_DIR" \
    --num_workers $NUM_WORKERS