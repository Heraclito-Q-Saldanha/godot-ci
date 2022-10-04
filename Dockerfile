FROM debian

# base

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
	&& apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		git \
		git-lfs \
		wget \
		zip \
		unzip \
		openjdk-11-jdk-headless \
		upx \
		wget \
		build-essential \
		scons \
		pkg-config \
		libx11-dev \
		libxcursor-dev \
		libxinerama-dev \
		libgl1-mesa-dev \
		libglu-dev \
		libasound2-dev \
		libpulse-dev \
		libudev-dev \
		libxi-dev \
		libxrandr-dev \
		yasm \
		python3 \
		mingw-w64 \
		mingw-w64-x86-64-dev

RUN    update-alternatives --set i686-w64-mingw32-gcc /usr/bin/i686-w64-mingw32-gcc-posix \
	&& update-alternatives --set i686-w64-mingw32-g++ /usr/bin/i686-w64-mingw32-g++-posix \
	&& update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix \
	&& update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix

RUN wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
	&& dpkg -i packages-microsoft-prod.deb \
	&& rm packages-microsoft-prod.deb \
	&& apt-get update \
	&& apt-get install -y dotnet-sdk-6.0 \
	&& apt-get clean \
	&& apt-get autoremove -y

# android sdk

ARG ANDROID_CMDLINE_URL=https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip
ENV ANDROID_SDK_ROOT=/opt/android
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
	&& cd /tmp \
    && wget -q ${ANDROID_CMDLINE_URL} -O android-commandline-tools.zip \
	&& unzip -q android-commandline-tools.zip \
    && mv cmdline-tools/* ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm -rf android-commandline-tools.zip cmdline-tools/ && ls -a ${ANDROID_SDK_ROOT}

ENV PATH ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${PATH}

RUN mkdir -p ${ANDROID_SDK_ROOT}/sdk \
	&& yes | sdkmanager --licenses \
	&& yes | sdkmanager "build-tools;30.0.3" "platforms;android-31" "cmake;3.10.2.4988404" "ndk;21.4.7075529"

ARG ANDROID_KEYSTORE_DIR=/root/.android
RUN mkdir -p $ANDROID_KEYSTORE_DIR \
	&& cd $ANDROID_KEYSTORE_DIR \
	&& keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12

# godot

ENV GODOT_VERSION=3.5.1
ENV GODOT_DIR=/opt/godotengine
ARG GODOT_BASE_URL=https://downloads.tuxfamily.org/godotengine

RUN mkdir -p $GODOT_DIR \
	&& cd $GODOT_DIR \
	&& wget -nc -nv $GODOT_BASE_URL/$GODOT_VERSION/Godot_v$GODOT_VERSION-stable_linux_headless.64.zip \
	&& unzip -q *.zip \
	&& rm *.zip \
	&& ln -s Godot_v$GODOT_VERSION-stable_linux_headless.64 godot3 \
    && ln -s Godot_v$GODOT_VERSION-stable_linux_headless.64 godot

COPY replaceicon.gd $GODOT_DIR
COPY createicon.gd $GODOT_DIR

ENV PATH=$GODOT_DIR:$PATH

ARG GODOT_TEMPLATE_DIR=/root/.local/share/godot/templates
RUN mkdir -p $GODOT_TEMPLATE_DIR \
	&& cd $GODOT_TEMPLATE_DIR \
	&& wget -nc -nv $GODOT_BASE_URL/$GODOT_VERSION/Godot_v$GODOT_VERSION-stable_export_templates.tpz \
	&& unzip -q Godot_v$GODOT_VERSION-stable_export_templates.tpz \
	&& mv -v templates $GODOT_VERSION.stable \
	&& rm -v Godot_v$GODOT_VERSION-stable_export_templates.tpz

ARG GODOT_EDITOR_CONFIG_DIR=/root/.config/godot
ARG GODOT_EDITOR_CONFIG_FILENAME=editor_settings-3.tres

RUN mkdir -p $GODOT_EDITOR_CONFIG_DIR \
	&& cd $GODOT_EDITOR_CONFIG_DIR \
	&& godot -e -q \
	&& echo 'export/android/android_sdk_path = "/opt/android"' >> $GODOT_EDITOR_CONFIG_FILENAME \
	&& echo 'export/android/debug_keystore = "/root/.android/debug.keystore"' >> $GODOT_EDITOR_CONFIG_FILENAME \
	&& echo 'export/android/debug_keystore_user = "androiddebugkey"' >> $GODOT_EDITOR_CONFIG_FILENAME \
	&& echo 'export/android/debug_keystore_pass = "android"' >> $GODOT_EDITOR_CONFIG_FILENAME


# godot_mono

RUN cd $GODOT_DIR \
	&& wget -nc -nv $GODOT_BASE_URL/$GODOT_VERSION/mono/Godot_v$GODOT_VERSION-stable_mono_linux_headless_64.zip \
	&& unzip -q *.zip \
	&& rm *.zip \
	&& ln -s Godot_v$GODOT_VERSION-stable_mono_linux_headless_64/Godot_v$GODOT_VERSION-stable_mono_linux_headless.64 godot3_mono \
    && ln -s Godot_v$GODOT_VERSION-stable_mono_linux_headless_64/Godot_v$GODOT_VERSION-stable_mono_linux_headless.64 godot_mono

RUN mkdir -p $GODOT_TEMPLATE_DIR \
	&& cd $GODOT_TEMPLATE_DIR \
	&& wget -nc -nv $GODOT_BASE_URL/$GODOT_VERSION/mono/Godot_v$GODOT_VERSION-stable_mono_export_templates.tpz \
	&& unzip -q Godot_v$GODOT_VERSION-stable_mono_export_templates.tpz \
	&& mv -v templates $GODOT_VERSION.stable.mono \
	&& rm -v Godot_v$GODOT_VERSION-stable_mono_export_templates.tpz