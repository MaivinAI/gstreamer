# torizon-gstreamer-imx

This repository has an unofficial Debian Container for Torizon build that includes
the NXP downstream fork of GStreamer. It has been created for use with Maivin
due to the need of HW-accelerated H.264 encoding.

It is not meant to be used as a final solution and has not been validated for
any use-case except the included stream.sh script on Verdin i.MX 8M Plus using
Torizon Maivin 5.7.1.1.

## How to use ##

Run the following:

```
docker run -it --rm --privileged --network host maivin/gstreamer:bullseye
```

Then from VideoLan Client (VLC) select `Media->Open Network Stream...` (CTRL-N) and use your Maivin's hostname with the URI below, replace the XXXXXX with your Maivin's serial number.

```
rtsp://verdin-imx8mp-XXXXXX:8554/camera
```
