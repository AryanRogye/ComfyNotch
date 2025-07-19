from moviepy.editor import TextClip, CompositeVideoClip

# Use method='caption' for word-wrapping + proper font handling
intro_text = TextClip(
    txt="Introducing To",
    fontsize=70,
    color='white',
    size=(1280, 720),
    method='caption',
    font="/System/Library/Fonts/Supplemental/Arial.ttf"
).set_duration(2).fadein(0.5).fadeout(0.5).set_position("center")

main_text = TextClip(
    txt="You ComfyNotch",
    fontsize=90,
    color='cyan',
    size=(1280, 720),
    method='caption',
    font="/System/Library/Fonts/Supplemental/Arial Bold.ttf"
).set_duration(3).fadein(0.5).fadeout(0.5).set_position("center")

# Combine and render
video = CompositeVideoClip([intro_text.set_start(0), main_text.set_start(2)])
video.write_videofile("comfynotch_intro.mp4", fps=24)
