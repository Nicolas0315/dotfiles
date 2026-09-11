FROM menci/archlinuxarm:base

RUN pacman-key --init \
 && pacman-key --populate archlinux \
 && pacman --disable-sandbox -Syu --noconfirm --needed base-devel fish git nodejs npm openssh python python-pip \
 && pacman -Scc --noconfirm

WORKDIR /work
CMD ["fish"]
