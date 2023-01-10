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
docker run -it --rm --privileged -p 9000:9000 maivin/gstreamer
```
