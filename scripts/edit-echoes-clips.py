"""Create focused portfolio clips from the existing cropped walkthroughs."""
from pathlib import Path
import subprocess
import json

SOURCE = Path('/Users/chaobian/work/content/games/echoes-of-time')

ROOT = Path(__file__).resolve().parents[1] / 'public/projects/echoes-of-time'
FONT = '/System/Library/Fonts/Supplemental/Arial.ttf'

def restore_original_audio():
    for level in range(6):
        video = ROOT / f'level{level}.mp4'
        streams = json.loads(subprocess.check_output(['ffprobe', '-v', 'quiet', '-show_streams', '-of', 'json', str(video)]))['streams']
        if any(s['codec_type'] == 'audio' for s in streams):
            continue
        restored = ROOT / f'level{level}-restored.mp4'
        subprocess.run(['ffmpeg', '-v', 'error', '-i', str(video), '-i', str(SOURCE / f'level{level}.mp4'), '-map', '0:v:0', '-map', '1:a:0', '-c', 'copy', '-shortest', '-movflags', '+faststart', '-y', str(restored)], check=True)
        restored.replace(video)

restore_original_audio()

def label(text, position='bottom'):
    y = 'h-62' if position == 'bottom' else '24'
    x = '(w-tw)/2' if position == 'bottom' else 'w-tw-30'
    return f"drawtext=fontfile={FONT}:text='{text}':fontsize=28:fontcolor=white:box=1:boxcolor=0x20291f@0.9:boxborderw=12:x={x}:y={y}"

def encode(level, name, start, end, overlay=None):
    args = ['ffmpeg', '-v', 'error', '-ss', str(start), '-i', str(ROOT / f'level{level}.mp4'), '-t', str(end-start)]
    if overlay:
        args += ['-vf', overlay]
    subprocess.run(args + ['-c:v', 'libx264', '-preset', 'fast', '-crf', '23', '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart', '-y', str(ROOT / f'{name}.mp4')], check=True)

encode(2, 'time-restored', 13, 23.7, label('Rewind restores the countdown - Player stays in place'))
encode(4, 'passage-timing', 26, 46.8)
encode(0, 'ending-excerpt', 34, 47.8)
# Keep the entire solution in chronological order; only rewind is accelerated.
parts = [(2.5, 17.3, 1), (17.3, 31.2, 2), (31.2, 46.4, 1)]
filters = []
for i, (start, end, speed) in enumerate(parts):
    f = f'[0:v]trim=start={start}:end={end},setpts=(PTS-STARTPTS)/{speed}'
    if speed == 2:
        f += ',' + label('Rewind sped up 2× in editing', 'top')
    filters.append(f + f',fps=30[v{i}]')
    filters.append(f'[0:a]atrim=start={start}:end={end},asetpts=PTS-STARTPTS,atempo={speed}[a{i}]')
filters.append('[v0][a0][v1][a1][v2][a2]concat=n=3:v=1:a=1[out][audio]')
subprocess.run(['ffmpeg', '-v', 'error', '-i', str(ROOT / 'level5.mp4'), '-filter_complex', ';'.join(filters), '-map', '[out]', '-map', '[audio]', '-c:v', 'libx264', '-preset', 'fast', '-crf', '23', '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart', '-y', str(ROOT / 'cooperative-solution.mp4')], check=True)
for name in ['time-restored', 'passage-timing', 'ending-excerpt', 'cooperative-solution']:
    subprocess.run(['ffmpeg', '-v', 'error', '-ss', '0.2', '-i', str(ROOT / f'{name}.mp4'), '-frames:v', '1', '-y', str(ROOT / f'{name}.webp')], check=True)
