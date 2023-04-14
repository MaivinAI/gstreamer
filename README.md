# Maivin GStreamer for Docker

This repository hosts the Maivin Debian Container for Torizon which includes the NXP downstream fork of GStreamer. It has been created for use with Maivin due to the need of HW-accelerated H.264 encoding.

# Instructions

Run the following:

```
docker run -it --rm --privileged --network host maivin/gstreamer:bullseye
```

Then from VideoLan Client (VLC) select `Media->Open Network Stream...` (CTRL-N) and use your Maivin's hostname with the URI below, replace the XXXXXX with your Maivin's serial number.

```
rtsp://verdin-imx8mp-XXXXXX:8554/camera
```

# Support

Commercial Support is available from the [Au-Zone DeepViewML Support Site][1].

[1]: https://support.deepviewml.com/hc/en-us/articles/12103941733005
