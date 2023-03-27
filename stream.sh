#!/bin/sh

export CONTROLS=horizontal_flip=$MIRROR,vertical_flip=$FLIP

rtsp-launch -p $PORT "( \
    v4l2src extra-controls=\"controls,$CONTROLS\" ! \
    video/x-raw,width=$WIDTH,height=$HEIGHT ! \
    vpuenc_h264 ! \
    rtph264pay name=pay0 pt=96 )"
