#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

out_dir="resources/drawables/generated"
mkdir -p "$out_dir"

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

render_frame "$descend" "512:1024:0:0" "52:78" "72:108" "diver_descend"
render_frame "$descend" "512:1024:512:0" "52:78" "72:108" "diver_descend_1"
render_frame "$descend" "512:1024:1024:0" "52:78" "72:108" "diver_descend_2"

render_frame "$ascend" "551:951:0:0" "52:78" "72:108" "diver_ascend"
render_frame "$ascend" "551:951:551:0" "52:78" "72:108" "diver_ascend_1"
render_frame "$ascend" "551:951:1102:0" "52:78" "72:108" "diver_ascend_2"

render_frame "$equalize" "768:1024:0:0" "52:78" "72:108" "diver_equalize"
render_frame "$equalize" "768:1024:768:0" "52:78" "72:108" "diver_equalize_1"

render_frame "$turn" "512:1024:0:0" "52:78" "72:108" "diver_turn"
render_frame "$turn_middle" "1150:420:50:390" "92:44" "128:62" "diver_turn_1"
render_frame "$turn" "512:1024:1024:0" "52:78" "72:108" "diver_turn_2"

render_frame "$duck" "820:360:0:500" "92:44" "128:62" "diver_duck"
render_frame "$duck_middle" "900:1080:150:80" "64:78" "90:108" "diver_duck_1"
render_frame "$duck" "310:900:1200:40" "52:78" "72:108" "diver_duck_2"

render_frame "$fish" "1050:650:110:300" "64:38" "90:54" "fish_school"
render_frame "$fish_1" "1050:650:110:300" "64:38" "90:54" "fish_school_1"
render_frame "$turtle" "1080:820:90:180" "60:44" "84:62" "green_turtle"
render_frame "$turtle_1" "1080:820:90:180" "60:44" "84:62" "green_turtle_1"
render_frame "$orca" "1170:600:40:250" "90:40" "126:56" "orca"
render_frame "$orca_1" "1170:600:40:250" "90:40" "126:56" "orca_1"
