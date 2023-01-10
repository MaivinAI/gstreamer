#!/bin/sh

export CONTROLS=horizontal_flip=$MIRROR,vertical_flip=$FLIP

gst-launch-1.0 v4l2src  extra-controls="controls,$CONTROLS" ! \
        video/x-raw,width=$WIDTH,height=$HEIGHT ! \
        vpuenc_hevc ! \
        mpegtsmux ! \
        tcpserversink host=0.0.0.0 port=$PORT
