ARG DEBIAN=bullseye

FROM maivin/debian:${DEBIAN} AS builder

RUN apt-get -y update

# Build dependencies
RUN apt-get install -y --no-install-recommends \
    openssl cmake build-essential v4l-utils git pkg-config \
    meson flex bison libglib2.0-dev libcap2-bin libcap-dev libxml2-dev

RUN apt-get install -y --no-install-recommends \
    iso-codes util-linux zlib1g-dev liborc-0.4-dev \
    libv4l-dev libdrm-dev libwayland-client0 libwayland-client++0 libwayland-client-extra++0

RUN apt-get install -y --no-install-recommends \
    libsrtp2-dev libnice-dev libwebrtc-audio-processing-dev \
    libsoup2.4-dev libjson-glib-dev

RUN apt-get install -y --no-install-recommends \
    python3 python3-websockets python3-gi \
    wget autotools-dev autoconf automake libtool libtool-bin

# for weston-vivante:2.2.0 use libsrt1-gnutls instead of libsrt1.4-gnutls
RUN apt-get install -y --no-install-recommends \
    libgdk-pixbuf2.0-0 libaa1 libavc1394-0 libcaca0 libdv4 libflac8 \
    libgdk-pixbuf2.0-0 libiec61883-0 libjack-jackd2-0 libmpg123-0 libraw1394-11 \
    libshout3 libsoup2.4-1 libtag1v5 libv4l-0 libass9 libbs2b0 libchromaprint1 \
    libcurl3-gnutls libdc1394-25 libdca0 libde265-0 libdrm2 libdvdnav4 \
    libdvdread8 libfaad2 libflite1 libfluidsynth2 libgme0 libilmbase25 libkate1 \
    liblilv-0-0 libmjpegutils-2.1-0 libmms0 libmodplug1 libmpcdec6 \
    libmpeg2encpp-2.1-0 libmplex2-2.1-0 libnice10 libofa0 libopenal1 \
    libopenexr25 libopenmpt0 librtmp1 libsbc1 libsndfile1 libsoundtouch1 \
    libspandsp2 libsrt1.4-gnutls libsrtp2-1 libusb-1.0-0 libusrsctp1 \
    libvo-aacenc0 libvo-amrwbenc0 libvulkan1 libwebrtc-audio-processing1 \
    libwildmidi2 libzbar0

RUN apt-get install -y --no-install-recommends \
    gobject-introspection libgirepository1.0-dev vim bash-completion

RUN apt-get install -y --no-install-recommends \
    libdrm-dev \
    libg2d-viv \
    imx-gpu-viv-tools \
    imx-gpu-viv-wayland \
    imx-gpu-viv-wayland-dev

# Clone NXP iMX fork of GStreamer, and dependencies
# Use the branches and hashes from our BSP
# Example Yocto Project manifest refs/tags/5.3.0
# http://git.toradex.com/cgit/meta-toradex-nxp.git/tree/backports/recipes-multimedia/gstreamer?h=dunfell-5.x.y&id=4a58243170331a1afb9fa0aec8fef492f87f131b

# linux-imx-headers_5.4.bb
COPY linux-imx-headers /usr/include/imx/linux

RUN mkdir -p /install/usr/lib/aarch64-linux-gnu

# imx-vpu-hantro_1.20.0.bb
WORKDIR /vpu
RUN wget https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/imx-vpu-hantro-1.20.0.bin && \
    chmod +x imx-vpu-hantro-1.20.0.bin && \
    ./imx-vpu-hantro-1.20.0.bin --auto-accept --force && \
    cd imx-vpu-hantro-1.20.0 && \
    make -j 1 PLATFORM="IMX8MP" all && \
    mkdir dest && \
    make -j 1 DEST_DIR=./dest PLATFORM="IMX8MP" install && \
    cp dest/*so* /usr/lib/aarch64-linux-gnu/ && \
    cp -a dest/usr/include/hantro_dec /usr/include/
RUN cp -a imx-vpu-hantro-1.20.0/dest/*so* /install/usr/lib/aarch64-linux-gnu/

# imx-vpu-hantro-vc_1.3.0.bb
WORKDIR /vpu
RUN wget https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/imx-vpu-hantro-vc-1.3.0.bin && \
    chmod +x imx-vpu-hantro-vc-1.3.0.bin && \
    ./imx-vpu-hantro-vc-1.3.0.bin --auto-accept --force && \
    cd imx-vpu-hantro-vc-1.3.0 && cp -a usr/. /usr/
RUN cp -a imx-vpu-hantro-vc-1.3.0/usr/lib/*so* /install/usr/lib/

# imx-vpuwrap_4.5.7.bb
WORKDIR /vpu
RUN git clone -b MM_04.05.07_2011_L5.4.70 https://github.com/NXP/imx-vpuwrap.git && \
    cd imx-vpuwrap && \
    git checkout ccaf10a0dae7c0d7d204bd64282598bc0e3bd661 && \
    ./autogen.sh --prefix=/usr && make && make install
RUN make -C imx-vpuwrap DESTDIR=/install install

# imx-parser_4.5.7
WORKDIR /vpu
RUN wget https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/imx-parser-4.5.7.bin && \
    chmod +x imx-parser-4.5.7.bin && \
    ./imx-parser-4.5.7.bin --auto-accept --force && \
    cd imx-parser-4.5.7 && \
    ./autogen.sh --prefix=/usr && ./configure --enable-armv8 --enable-fhw --prefix=/usr && make install
RUN make -C imx-parser-4.5.7 DESTDIR=/install install

# imx-codec_4.5.7.bb
WORKDIR /vpu
RUN wget https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/imx-codec-4.5.7.bin && \
    chmod +x imx-codec-4.5.7.bin && \
    ./imx-codec-4.5.7.bin --auto-accept --force && \
    cd imx-codec-4.5.7 && \
    ./autogen.sh --enable-armv8 --enable-fhw --enable-vpu --prefix=/usr && make install
RUN make -C imx-codec-4.5.7 DESTDIR=/install install

WORKDIR /gstreamer
# Copy everything from our BSP. That includes patches, etc.
COPY gstreamer yocto
# Also copy own patches specific for this container build
COPY patches mypatches

# RUN apt-get install -y --no-install-recommends \
#     libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

# meta-toradex-nxp/backports/recipes-multimedia/gstreamer/gstreamer1.0_1.16.imx.bb
RUN git clone -b MM_04.05.06_2008_L5.4.47 https://github.com/nxp-imx/gstreamer.git && \
    cd gstreamer && \
    git checkout 8514bc61ccab208a65e387eab9347276a8e770e7 && \
    git apply ../yocto/gstreamer1.0/0001-gst-gstpluginloader.c-when-env-var-is-set-do-not-fal.patch && \
    git apply ../yocto/gstreamer1.0/0002-meson-build-gir-even-when-cross-compiling-if-introsp.patch && \
    git apply ../yocto/gstreamer1.0/0003-meson-Add-valgrind-feature.patch && \
    git apply ../yocto/gstreamer1.0/0004-meson-Add-option-for-installed-tests.patch && \
    git apply ../yocto/gstreamer1.0/capfix.patch && \
    mkdir build && cd build && \
    meson \
        -Dprefix=/usr \
        -Dgst_debug=true \
        -Dtracer_hooks=true \
        -Dcheck=disabled \
        -Dtests=disabled -Dinstalled-tests=false \
        -Dvalgrind=disabled \
        -Dlibunwind=disabled \
        -Dlibdw=disabled \
        -Dtools=enabled \
        -Dsetcap=enabled \
        -Dnls=disabled \
        -Dexamples=disabled \
        -Ddbghelp=disabled \
        -Dgtk_doc=disabled .. && \
    ninja install && DESTDIR=/install ninja install

# meta-toradex-nxp/backports/recipes-multimedia/gstreamer/gstreamer1.0-plugins-base_1.16.imx.bb
WORKDIR /gstreamer
RUN git clone -b MM_04.05.06_2008_L5.4.47 https://github.com/nxp-imx/gst-plugins-base.git && \
    cd gst-plugins-base && \
    git checkout 3c4aa2a58576d68f6e684efa58609665679c9969 && \
    git apply ../yocto/gstreamer1.0-plugins-base/0001-meson-build-gir-even-when-cross-compiling-if-introsp.patch && \
    git apply ../yocto/gstreamer1.0-plugins-base/0001-gstreamer-plugins-base-fix-meson-build-in-nxp-fork.patch && \
    git apply ../yocto/gstreamer1.0-plugins-base/0002-meson-Add-variables-for-gir-files.patch && \
    git apply ../yocto/gstreamer1.0-plugins-base/0005-viv-fb-Make-sure-config.h-is-included.patch && \
    git apply ../yocto/gstreamer1.0-plugins-base/0009-glimagesink-Downrank-to-marginal.patch && \
    git apply ../yocto/gstreamer1.0-plugins-base/0001-gst-libs-gst-gl-wayland-fix-meson-build.patch && \
    git apply ../yocto/gstreamer1.0-plugins-base/0001-meson-viv-fb-code-must-link-against-libg2d.patch && \
    git apply ../yocto/gstreamer1.0-plugins-base/0001-glupload-don-t-reject-non-RGBA-output-format-in-_dir.patch && \
    mkdir build && cd build && \
    meson \
        -Dprefix=/usr \
        -Dorc=enabled \
        -Dnls=disabled \
        -Dexamples=disabled \
        -Dcheck=disabled \
        -Dalsa=disabled \
        -Dcdparanoia=disabled \
        -Dgl-jpeg=disabled \
        -Dogg=disabled \
        -Dopus=disabled \
        -Dpango=disabled \
        -Dgl-png=disabled \
        -Dtheora=disabled \
        -Dtremor=disabled \
        -Dlibvisual=disabled \
        -Dvorbis=disabled \
        -Dgl-graphene=disabled \
        -Dextra_imx_incdir=/usr/include/imx .. && \
    ninja install && DESTDIR=/install ninja install

# meta-toradex-nxp/backports/recipes-multimedia/gstreamer/gstreamer1.0-plugins-good_1.16.imx.bb
WORKDIR /gstreamer
RUN git clone -b MM_04.05.07_2011_L5.4.70 https://github.com/nxp-imx/gst-plugins-good.git && \
    cd gst-plugins-good && \
    git checkout 6005e8199ea19878f269b058ffbbbcaa314472d8 && \
    mkdir build && cd build && \
    meson \
        -Dprefix=/usr \
        -Dorc=enabled \
        -Dnls=disabled \
        -Dexamples=disabled \
        -Dcheck=disabled \
        -Dximagesrc=disabled -Dximagesrc-xshm=disabled -Dximagesrc-xfixes=disabled -Dximagesrc-xdamage=disabled \
        -Dbz2=disabled \
        -Dcairo=disabled \
        -Ddv1394=disabled \
        -Dflac=disabled \
        -Dgdk-pixbuf=disabled \
        -Dgtk3=disabled \
        -Dv4l2-gudev=disabled \
        -Djack=disabled \
        -Djpeg=disabled \
        -Dlame=disabled \
        -Dpng=disabled \
        -Dv4l2-libv4l2=enabled \
        -Dmpg123=disabled \
        -Dpulse=disabled \
        -Dsoup=disabled \
        -Dspeex=disabled \
        -Dtaglib=disabled \
        -Dv4l2=enabled -Dv4l2-probe=true \
        -Dvpx=disabled \
        -Dwavpack=disabled \
        -Daalib=disabled \
        -Ddirectsound=disabled \
        -Ddv=disabled \
        -Dlibcaca=disabled \
        -Doss=enabled \
        -Doss4=disabled \
        -Dosxaudio=disabled \
        -Dosxvideo=disabled \
        -Dqt5=disabled \
        -Dshout2=disabled \
        -Dtwolame=disabled \
        -Dwaveform=disabled \
        -Dextra_imx_incdir=/usr/include/imx .. && \
    ninja install && DESTDIR=/install ninja install

# meta-toradex-nxp/backports/recipes-multimedia/gstreamer/gstreamer1.0-plugins-bad_1.16.imx.bb
WORKDIR /gstreamer
RUN git clone -b MM_04.05.07_2011_L5.4.70 https://github.com/nxp-imx/gst-plugins-bad.git && \
    cd gst-plugins-bad && \
    git checkout cf7f2d0125424ce0d63ddc7f1eadc9ef71d10db1 && \
    git apply ../yocto/gstreamer1.0-plugins-bad/0001-ext-wayland-fix-meson-build-in-nxp-fork.patch && \
    git apply ../yocto/gstreamer1.0-plugins-bad/0001-meson-build-gir-even-when-cross-compiling-if-introsp.patch && \
    git apply ../yocto/gstreamer1.0-plugins-bad/opencv-resolve-missing-opencv-data-dir-in-yocto-buil.patch && \
    git apply ../yocto/gstreamer1.0-plugins-bad/0001-opencv-allow-compilation-against-4.4.x.patch && \
    git apply ../yocto/gstreamer1.0-plugins-bad/0001-vulkan-Drop-use-of-VK_RESULT_BEGIN_RANGE.patch && \
    git apply ../yocto/gstreamer1.0-plugins-bad/fix-maybe-uninitialized-warnings-when-compiling-with-Os.patch && \
    git apply ../yocto/gstreamer1.0-plugins-bad/avoid-including-sys-poll.h-directly.patch && \
    git apply ../yocto/gstreamer1.0-plugins-bad/ensure-valid-sentinels-for-gst_structure_get-etc.patch && \
    mkdir build && cd build && \
    meson \
        -Dprefix=/usr \
        -Dorc=enabled \
        -Dnls=disabled \
        -Dexamples=disabled \
        -Dcheck=disabled \
        -Dassrender=disabled \
        -Dbluez=disabled \
        -Dbz2=disabled \
        -Dclosedcaption=disabled \
        -Dcurl=disabled \
        -Ddash=disabled \
        -Ddc1394=disabled \
        -Ddirectfb=disabled \
        -Ddtls=disabled \
        -Dfaac=disabled \
        -Dfaad=disabled \
        -Dfluidsynth=disabled \
        -Dhls=disabled \
        -Dgl=disabled \
        -Dkms=enabled \
        -Dlibde265=disabled \
        -Dlibmms=disabled \
        -Dcurl-ssh2=disabled \
        -Dmodplug=disabled \
        -Dmsdk=disabled \
        -Dneon=disabled \
        -Dopenal=disabled \
        -Dopencv=disabled \
        -Dopenh264=disabled \
        -Dopenjpeg=disabled \
        -Dopenmpt=disabled \
        -Dopus=disabled \
        -Dresindvd=disabled \
        -Drsvg=disabled \
        -Drtmp=disabled \
        -Dsbc=disabled \
        -Dsctp=disabled \
        -Dsmoothstreaming=disabled \
        -Dsndfile=disabled \
        -Dsrtp=enabled \
        -Dtinyalsa=disabled \
        -Dttml=disabled \
        -Duvch264=disabled \
        -Dvoaacenc=disabled \
        -Dvoamrwbenc=disabled \
        -Dvulkan=disabled \
        -Dwayland=disabled \
        -Dwebp=disabled \
        -Dwebrtc=enabled \
        -Dwebrtcdsp=enabled \
        -Dzbar=disabled \
        -Ddecklink=disabled \
        -Ddvb=disabled \
        -Dfbdev=disabled \
        -Dipcpipeline=disabled \
        -Dnetsim=disabled \
        -Dshm=enabled \
        -Daom=disabled \
        -Dandroidmedia=disabled \
        -Dapplemedia=disabled \
        -Dbs2b=disabled \
        -Dchromaprint=disabled \
        -Dd3dvideosink=disabled \
        -Ddirectsound=disabled \
        -Ddts=disabled \
        -Dfdkaac=disabled \
        -Dflite=disabled \
        -Dgme=disabled \
        -Dgsm=disabled \
        -Diqa=disabled \
        -Dkate=disabled \
        -Dladspa=disabled \
        -Dlv2=disabled \
        -Dmpeg2enc=disabled \
        -Dmplex=disabled \
        -Dmsdk=disabled \
        -Dmusepack=disabled \
        -Dnvdec=disabled \
        -Dnvenc=disabled \
        -Dofa=disabled \
        -Dopenexr=disabled \
        -Dopenmpt=disabled \
        -Dopenni2=disabled \
        -Dopensles=disabled \
        -Dsoundtouch=disabled \
        -Dspandsp=disabled \
        -Dsrt=disabled \
        -Dteletext=disabled \
        -Dvdpau=disabled \
        -Dwasapi=disabled \
        -Dwildmidi=disabled \
        -Dwinks=disabled \
        -Dwinscreencap=disabled \
        -Dwpe=disabled \
        -Dx265=disabled \
        -Dzbar=disabled \
        -Dextra_imx_incdir=/usr/include/imx .. && \
    ninja install && DESTDIR=/install ninja install

# meta-toradex-nxp/backports/recipes-multimedia/gstreamer/imx-gst1.0-plugin_4.5.7.imx.bb
WORKDIR /gstreamer
RUN git clone -b MM_04.05.07_2011_L5.4.70 https://github.com/nxp-imx/imx-gst1.0-plugin.git && \
    cd imx-gst1.0-plugin && \
    git checkout 659ec4947d6b1903d26e4ec9e40ae251a659935d && \
    cp -a /usr/include/imx/* /usr/include/ && \
    rm -r tools/ && \
    git apply ../mypatches/0001-Remove-tools-from-the-build.patch && \
    ./autogen.sh PLATFORM="MX8" && \
    ./configure \
        --prefix=/usr \
        --libdir=/usr/lib/aarch64-linux-gnu \
        --disable-mp3enc \
        --disable-wma8enc \
        --disable-beep \
        --disable-overlaysink \
        --disable-imx2ddevice_g2d \
        --disable-imx2ddevice_ipu \
        --disable-imx2ddevice_pxp \
        --disable-v4l2_core \
        --disable-v4lsink \
        --disable-aiur \
        --disable-x11 \
        PLATFORM="MX8" && \
    make -j$(nproc) all && make install
RUN make -C imx-gst1.0-plugin DESTDIR=/install install

WORKDIR /gstreamer
ARG RTSP_VERSION=1.16.3
RUN apt-get install -y --no-install-recommends xz-utils
RUN curl -O https://gstreamer.freedesktop.org/src/gst-rtsp-server/gst-rtsp-server-${RTSP_VERSION}.tar.xz && xzcat gst-rtsp-server-${RTSP_VERSION}.tar.xz | tar xf -
RUN cd gst-rtsp-server-${RTSP_VERSION} && \
    sed -i 's,/test,/camera,' examples/test-launch.c && \
    mkdir build && cd build && \
    meson \
        -Dprefix=/usr \
        -Ddoc=disabled \
        -Dtests=disabled .. && \
    ninja install && DESTDIR=/install ninja install && \
    mkdir -p /install/usr/bin && \
    cp examples/test-launch /install/usr/bin/rtsp-launch

RUN tar cf /install.tar -C /install .

FROM maivin/debian:${DEBIAN}
WORKDIR /work

RUN apt-get -y update && \
    apt-get install -y --no-install-recommends \
        libglib2.0-0 \
        libcairo-gobject2 \
        liborc-0.4-0 \
        libv4l-0 \
        libnice10 \
        libsrtp2-1 \
        libwebrtc-audio-processing1

COPY --from=builder /install.tar .
RUN tar xf install.tar -C / && rm install.tar

ENV WIDTH=1920
ENV HEIGHT=1080
ENV FRAMERATE=30
ENV MIRROR=1
ENV FLIP=1
ENV PORT=8554

WORKDIR /app
COPY stream.sh .

WORKDIR /work
ENTRYPOINT /app/stream.sh