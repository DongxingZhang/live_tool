cd ~
mkdir ffmpeg6.0_sources  ffmpeg6.0_build bin6.0

sudo apt-get -y install \
  autoconf \
  automake \
  build-essential \
  cmake \
  git-core \
  libass-dev \
  libfreetype6-dev \
  lib**sdl2-dev** \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  pkg-config \
  texinfo \
  wget \
  zlib1g-dev

sudo apt-get install libasound2-dev
sudo apt-get install libgl1-mesa-dev
sudo apt-get install libglew-dev
sudo apt-get install libglm-dev
sudo apt-get install mercurial libnuma-dev


cd ~/ffmpeg6.0_sources
wget https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2 
tar xjvf nasm-2.14.02.tar.bz2 
cd nasm-2.14.02
./autogen.sh 
./configure --prefix="$HOME/ffmpeg6.0_build" --bindir="$HOME/bin6.0" 
make -j4
make install


cd ~/ffmpeg6.0_sources 
wget -O yasm-1.3.0.tar.gz https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz 
tar xzvf yasm-1.3.0.tar.gz 
cd yasm-1.3.0 
./configure   CFLAGS="-fPIC" CPPFLAGS="-fPIC"  --prefix="$HOME/ffmpeg6.0_build" --bindir="$HOME/bin6.0" 
make 
make install

cd ~/ffmpeg6.0_sources 
git clone --depth 1 https://github.com/mirror/x264.git 
cd x264 
PKG_CONFIG_PATH="$HOME/ffmpeg6.0_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg6.0_build" --bindir="$HOME/bin6.0" --enable-static --enable-shared --enable-pic 
make 
make install

cd ~/ffmpeg6.0_sources 
git clone https://gitee.com/mirrors_videolan/x265.git
cd x265/build/linux 
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg6.0_build" -DENABLE_SHARED=on -DENABLE_PIC=on -DBIN_INSTALL_DIR="$HOME/bin6.0" ../../source 
make 
make install

cd ~/ffmpeg6.0_sources 
git clone --depth 1 https://github.com/webmproject/libvpx.git
cd libvpx 
./configure --prefix="$HOME/ffmpeg6.0_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm --enable-pic  --enable-shared
make 
make install

cd ~/ffmpeg6.0_sources 
git clone --depth 1 https://github.com/mstorsjo/fdk-aac.git
cd fdk-aac 
autoreconf -fiv 
./configure CFLAGS="-fPIC" CPPFLAGS="-fPIC" --prefix="$HOME/ffmpeg6.0_build" --bindir="$HOME/bin6.0"  
make 
make install

cd ~/ffmpeg6.0_sources 
git clone  --depth 1 https://gitee.com/hqiu/lame.git 
cd lame 
./configure --prefix="$HOME/ffmpeg6.0_build" --bindir="$HOME/bin6.0"  --enable-nasm --with-pic 
make 
make install

cd ~/ffmpeg6.0_sources 
git clone --depth 1 https://github.com/xiph/opus.git 
cd opus 
./autogen.sh 
./configure --prefix="$HOME/ffmpeg6.0_build"  -with-pic
make 
make install

cd ~/ffmpeg6.0_sources 
git clone https://github.com/FFmpeg/FFmpeg.git
cd FFmpeg
git checkout  remotes/origin/release/6.0


PKG_CONFIG_PATH="$HOME/ffmpeg6.0_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg6.0_build" \
  --extra-libs="-lpthread -lm" \
  --bindir="$HOME/bin6.0" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg6.0_build/include" \
  --extra-cflags="-I$HOME/ffmpeg6.0_build/include/fdk-aac" \
  --extra-ldflags="-L$HOME/ffmpeg6.0_build/lib" \
  --enable-gpl \
  --enable-libass \
  --enable-libfreetype \
  --enable-libvorbis \
  --enable-pic \
  --enable-shared   \
  --enable-static \
  --enable-nonfree \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx  \
  --enable-libfdk-aac \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-sdl2   \
  --enable-ffplay \
  --disable-optimizations \
  --disable-stripping \
  --enable-debug=3
  
make
make install




