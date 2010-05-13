#!/bin/bash

# source the global config file
source "./CONFIG"

function svg_substitutions {
    # Process an SVG file with custom substitutions.
    local infile="$1"

    sed \
        -e "s/#000000/$OUTLINECOLOR/g" \
        -e "s/stroke-width:20/stroke-width:$OUTLINE/g" \
        -e "s/#999999/$CURSORCOLORHI/g" \
        -e "s/#555555/$CURSORCOLORLO/g" \
        -e "s/#999933/$HILIGHTHI/g" \
        -e "s/#666600/$HILIGHTLO/g" \
        -e "s/#010101/$HAIR/g" \
        "$infile"
}

indir="svg"
tempdir="tmp"
destdir="build"

mkdir --parents "${destdir}"
mkdir --parents "${tempdir}"
mkdir --parents "cursors"
mkdir --parents "shadows"


function generate_animation_source_frames {
    # Generate the source frame images for an animation.
    local name="$1"
    local frames_count=$2

    first_frame_file="${indir}/${name}.svg"
    patch_file="${indir}/${name}.diff"
    for frame in $(seq 1 $frames_count) ; do
        frame_file="${indir}/${name}${frame}.svg"
        case $frame in
            1)
                cp "$first_frame_file" "$frame_file"
                ;;
            *)
                cp "$prev_frame_file" "$frame_file"
                patch --force --silent \
                    "$frame_file" < "$patch_file" > /dev/null
                ;;
        esac
        prev_frame_file="$frame_file"
    done
}

function render_cursor_image {
    # Render SVG source image to finished PNG image.
    local name="$1"
    local compose_opts="$2"
    local frame=$3
    local frame_time=$4

    if [[ "$frame" ]] ; then
        outdir="${destdir}/${name}"
        frame_name="${name}${frame}"
        compose_opts="${compose_opts} -FRAME $frame"
        if [[ "$frame_time" ]] ; then
            compose_opts="${compose_opts} -TIME $frame_time"
        fi
    else
        frame=0
        outdir="${destdir}"
        frame_name="${name}"
    fi

    mkdir --parents "$outdir"
    infile="${indir}/${frame_name}.svg"
    if [[ ! -f "$infile" ]] ; then
        echo "skipping $name; no svg file found."
        return 1
    fi
    tempfile="${tempdir}/$(basename $infile)"
    outfile="${outdir}/${frame_name}.png"
    svg_substitutions "$infile" > "$tempfile"
    ./svg2png.bash $compose_opts "$name" "$tempfile" "$outfile"
}


# the basic cursors
names="
all-scroll
cell
col-resize
crosshair
default
e-resize
ew-resize
grabbing
n-resize
ne-resize
nesw-resize
not-allowed
ns-resize
nw-resize
nwse-resize
pencil
pirate
pointer
right-arrow
row-resize
s-resize
se-resize
sw-resize
text
up-arrow
vertical-text
w-resize
X-cursor
zoom-in
zoom-out
"

for name in $names; do
    compose_opts=""
    render_cursor_image "$name" "$compose_opts"
done

# the pointer combined cursors

names="
alias
context-menu
copy
move
no-drop
"

for name in $names; do
    compose_opts="-BACKGROUND ${destdir}/default.png"
    render_cursor_image "$name" "$compose_opts"
done

name="help"
compose_opts="-BACKGROUND ${destdir}/default.png"
render_cursor_image "$name" "$compose_opts" 1 2000
render_cursor_image "$name" "$compose_opts" 2 500

name="progress"
frames_count=24
generate_animation_source_frames "$name" $frames_count
for frame in $(seq 1 $frames_count) ; do
    compose_opts="-BACKGROUND ${destdir}/default.png"
    render_cursor_image "$name" "$compose_opts" $frame
done

name="wait"
frames_count=36
generate_animation_source_frames "$name" $frames_count
for frame in $(seq 1 $frames_count) ; do
    compose_opts=""
    render_cursor_image "$name" "$compose_opts" $frame
done

# make and install

echo "silent make"
make -silent
echo "silent make install"
make -silent install
