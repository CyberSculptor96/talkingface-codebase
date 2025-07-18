# 数据处理脚本

## 1. face-crop

将输入的人脸视频目录裁剪为512x512的正方形，人脸居中。HDTF数据集这一步可以省略，因为数据集的视频已经满足要求。

```bash
bash scripts/data_process/face_crop.sh 
```

## 2. face-info

输入裁剪后的人脸视频目录，提取人脸相关的参数

```bash
bash scripts/data_process/extract_face_info.sh
```

## 3. audio-emb

输入带音频的视频目录（HDTF），或者音频目录（TalkVid），提取音频的wav2vec2特征

```bash
bash scripts/data_process/extract_audio_emb.sh 
```

# 运行

运行脚本前，预期的数据集目录如下：

```bash
/path/to/dataset/    # TalkVid或HDTF，HDTF只有videos/
├── audios/
│   ├── file1.m4a
│   ├── file2.m4a
│   └── ...
├── videos/
│   ├── file1.mp4
│   ├── file2.mp4
│   └── ...

```

在example-data下提供了示例的小数据集，可用于验证代码是否能跑通。

运行脚本：

```bash
git clone https://github.com/CyberSculptor96/talkingface-codebase.git
cd talkingface-codebase

# create conda env
bash env.sh

# download necessary hf-model-ckpts
bash download_hf.sh

# 1 人脸裁剪
bash scripts/data_process/face_crop.sh
# 2 提取音频特征
bash scripts/data_process/extract_audio_emb.sh
# 3 提取人脸信息
bash scripts/data_process/extract_face_info.sh

## 1和2可并行执行，3的输入是1的输出，因此需要1完成（或部分完成）后才可启动
```

完成数据处理后，预期的数据集目录如下：

```bash
example-data/TalkVid-test-100/
├── audios/
│   ├── 0000.m4a
│   ├── 0001.m4a
│   └── ...
├── new_face_info/
│   ├── 0000.pt
│   ├── 0001.pt
│   └── ...
├── short_clip_aud_embeds/
│   ├── 0000.pt
│   ├── 0001.pt
│   └── ...
├── videos/
│   ├── 0000.mp4
│   ├── 0001.mp4
│   └── ...
└── videos-crop/
    ├── 0000.mp4
    ├── 0001.mp4
    └── ...

```

正确性检查：

```bash
# 1 检查生成的face-info和audio-emb的帧数是否与videos-crop和videos的帧数一致
bash scripts/check/check_face_and_audio.sh
# 2 检查videos-crop的fps和帧数是否符合预期（e.g. fps=24, frames=121）
python scripts/check/check_fps_frames.py
# 3 更细粒度的检查，见scripts/check/check_audio.txt
```

创建用于训练的json文件：

```python
python scripts/utils/create_data_json.py
```

生成的JSON文件示例如下：

```json
[
  {
    "video": "/data/TalkVid/videos-crop/videovideo-0F1owya2oo-scene20_scene2.mp4",
    "face_info": "/data/TalkVid/new_face_info/videovideo-0F1owya2oo-scene20_scene2.pt",
    "audio_embeds": "/data/TalkVid/short_clip_aud_embeds/videovideo-0F1owya2oo-scene20_scene2.pt"
  },
  {
    "video": "/data/TalkVid/videos-crop/videovideo-0F1owya2oo-scene5_scene1.mp4",
    "face_info": "/data/TalkVid/new_face_info/videovideo-0F1owya2oo-scene5_scene1.pt",
    "audio_embeds": "/data/TalkVid/short_clip_aud_embeds/videovideo-0F1owya2oo-scene5_scene1.pt"
  },
  ...
]
```
