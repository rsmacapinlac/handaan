#!/bin/bash
configure_pacman_parallel_downloads
sudo pacman -Sy --noconfirm
sudo pacman -S --needed --noconfirm openssh git
