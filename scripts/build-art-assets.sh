#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

out_dir="resources/drawables/generated"
mkdir -p "$out_dir"

SWIFT_MODULECACHE_PATH=/tmp/deep-line-swift-cache \
CLANG_MODULE_CACHE_PATH=/tmp/deep-line-clang-cache \
swift scripts/build-title-assets.swift

render_frame() {
    input="$1"
    crop="$2"
    mip_size="$3"
    amoled_size="$4"
    output_stem="$5"

    ffmpeg -hide_banner -loglevel error -y -i "$input" \
        -vf "crop=$crop,scale=$mip_size:force_original_aspect_ratio=decrease:flags=lanczos,pad=$mip_size:(ow-iw)/2:(oh-ih)/2:color=black@0" \
        -frames:v 1 "$out_dir/${output_stem}_mip.png"

    ffmpeg -hide_banner -loglevel error -y -i "$input" \
        -vf "crop=$crop,scale=$amoled_size:force_original_aspect_ratio=decrease:flags=lanczos,pad=$amoled_size:(ow-iw)/2:(oh-ih)/2:color=black@0" \
        -frames:v 1 "$out_dir/${output_stem}_amoled.png"
}

descend="art/source/freediver-descend-animation-sheet.png"
ascend="art/source/freediver-ascend-animation-sheet.png"
equalize="art/source/freediver-equalize-animation-sheet.png"
turn="art/source/freediver-turn-animation-sheet.png"
turn_middle="art/source/freediver-turn-middle.png"
duck="art/source/freediver-duck-dive-animation-sheet.png"
duck_middle="art/source/freediver-duck-dive-middle.png"
fish="art/source/fish-school.png"
fish_1="art/source/fish-school-1.png"
turtle="art/source/green-turtle.png"
turtle_1="art/source/green-turtle-1.png"
orca="art/source/orca.png"
orca_1="art/source/orca-1.png"
sea_lion="art/source/sea-lion.png"
thresher="art/source/thresher-shark.png"
manta="art/source/manta-ray.png"
hammerhead="art/source/hammerhead-shark.png"
penguin="art/source/swimming-penguin.png"

render_frame "$descend" "512:1024:0:0" "52:78" "72:108" "diver_descend"
render_frame "$descend" "512:1024:512:0" "52:78" "72:108" "diver_descend_1"
render_frame "$descend" "512:1024:1024:0" "52:78" "72:108" "diver_descend_2"

render_frame "$ascend" "551:951:0:0" "52:78" "72:108" "diver_ascend"
render_frame "$ascend" "551:951:551:0" "52:78" "72:108" "diver_ascend_1"
render_frame "$ascend" "551:951:1102:0" "52:78" "72:108" "diver_ascend_2"

render_frame "$equalize" "768:1024:0:0" "52:78" "72:108" "diver_equalize"
render_frame "$equalize" "768:1024:768:0" "52:78" "72:108" "diver_equalize_1"

render_frame "$turn" "512:1024:0:0" "52:78" "72:108" "diver_turn"
render_frame "$turn_middle" "1100:850:75:175" "78:60" "108:84" "diver_turn_1"
render_frame "$turn" "512:1024:1024:0" "52:78" "72:108" "diver_turn_2"

render_frame "$duck" "820:360:0:500" "92:44" "128:62" "diver_duck"
render_frame "$duck_middle" "900:1080:150:80" "64:78" "90:108" "diver_duck_1"
render_frame "$duck" "260:900:1250:40" "52:78" "72:108" "diver_duck_2"

render_frame "$fish" "1050:650:110:300" "64:38" "90:54" "fish_school"
render_frame "$fish_1" "1050:650:110:300" "64:38" "90:54" "fish_school_1"
render_frame "$turtle" "1080:820:90:180" "42:31" "58:43" "green_turtle"
render_frame "$turtle_1" "1080:820:90:180" "42:31" "58:43" "green_turtle_1"
render_frame "$orca" "1170:600:40:250" "90:40" "126:56" "orca"
render_frame "$orca_1" "1170:600:40:250" "90:40" "126:56" "orca_1"
render_frame "$sea_lion" "iw:ih:0:0" "74:42" "104:58" "sea_lion"
render_frame "$thresher" "iw:ih:0:0" "90:45" "126:63" "thresher_shark"
render_frame "$manta" "iw:ih:0:0" "80:54" "112:76" "manta_ray"
render_frame "$hammerhead" "iw:ih:0:0" "90:48" "126:68" "hammerhead_shark"
render_frame "$penguin" "iw:ih:0:0" "60:38" "84:54" "swimming_penguin"
