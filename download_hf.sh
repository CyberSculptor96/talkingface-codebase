#!/bin/bash
# export HF_ENDPOINT=https://hf-mirror.com  # 可选

# ===== 配置 =====
ROOT="/mnt/nvme2n1/smith/xidong/codebase"
HF_REPO="tk93/V-Express"
TARGET_DIR="$ROOT/model_ckpts"
NESTED_DIR="$TARGET_DIR/model_ckpts"

# ===== 下载模型到指定目录 =====
mkdir -p "$TARGET_DIR"
# huggingface-cli download "$HF_REPO" --local-dir "$TARGET_DIR"
if ! huggingface-cli download "$HF_REPO" --local-dir "$TARGET_DIR"; then
  echo "huggingface-cli 下载失败，终止操作"
  exit 1
fi

# ===== 首先移动顶层的 *.bin 文件到 v-express（如果存在）=====
VEXPRESS_DIR=$(find "$NESTED_DIR" -type d -name "v-express" | head -n 1)
if [ -n "$VEXPRESS_DIR" ]; then
  echo "Found v-express dir: $VEXPRESS_DIR"
  find "$TARGET_DIR" -maxdepth 1 -type f -name '*.bin' -exec mv {} "$VEXPRESS_DIR"/ \;
else
  echo "v-express 目录未找到，跳过 *.bin 移动"
fi

# ===== 然后提升 model_ckpts/model_ckpts/* 到 model_ckpts/ =====
if [ -d "$NESTED_DIR" ]; then
  echo "提升嵌套目录内容..."
  find "$NESTED_DIR" -mindepth 1 -maxdepth 1 -exec mv -t "$TARGET_DIR" {} +
  rm -rf "$NESTED_DIR"
else
  echo "未发现嵌套目录 $NESTED_DIR"
fi

# ===== 完成状态 =====
echo "✅ 模型目录整理完成，当前内容如下："
ls -lh "$TARGET_DIR"
