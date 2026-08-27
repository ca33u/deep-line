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

render_frame "$descend" "512:1024:0:0" "52:78" "72:108" "diver_descend"
render_frame "$descend" "512:1024:512:0" "52:78" "72:108" "diver_descend_1"
render_frame "$descend" "512:1024:1024:0" "52:78" "72:108" "diver_descend_2"

render_frame "$ascend" "551:951:0:0" "52:78" "72:108" "diver_ascend"
render_frame "$ascend" "551:951:551:0" "52:78" "72:108" "diver_ascend_1"
render_frame "$ascend" "551:951:1102:0" "52:78" "72:108" "diver_ascend_2"

render_frame "$equalize" "768:1024:0:0" "52:78" "72:108" "diver_equalize"
render_frame "$equalize" "768:1024:768:0" "52:78" "72:108" "diver_equalize_1"

render_frame "$turn" "724:724:0:0" "78:60" "108:84" "diver_turn"
render_frame "$turn" "724:724:724:0" "78:60" "108:84" "diver_turn_1"
render_frame "$turn" "724:724:1448:0" "78:60" "108:84" "diver_turn_2"
