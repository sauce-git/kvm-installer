#!/bin/bash

# Debian 12 ISO path
DEB_12_ISO_NAME=debian-12.9.0-amd64-netinst.iso
DEB_12_ISO_URL=https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/$DEB_12_ISO_NAME

# VM Configuration Variables
vm_name=""
vcpu=""
memory=""
disk_size=""
network=""

os_name=""
os_version=""
os_variant=""

iso_name=""
iso_url=""
iso_path=""

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
WHITE="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"

# Function to clear previous menu text
clear_previous_lines() {
  local lines=$1
  for ((i = 0; i < lines; i++)); do
    tput cuu1  # Move cursor up one line
    tput el    # Clear the line
  done
}

# Select OS
select_os() {
  while true; do
    echo -e "${BOLD}${CYAN}========== Select OS ==========${RESET}"
    echo -e " 1. ${GREEN}Debian${RESET}"
    echo -e " 2. ${RED}Exit${RESET}"
    echo -e "${CYAN}================================${RESET}"
    read -rp "Enter your choice: " choice
    clear_previous_lines 5

    case $choice in
      1)
        os_name="deb"
        select_deb_version
        break
        ;;
      2)
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid choice. Please try again.${RESET}"
        sleep 1
        clear_previous_lines 1
        ;;
    esac
  done
}

# Select Debian version
select_deb_version() {
  while true; do
    echo -e "${BOLD}${CYAN}======= Select Debian Version =======${RESET}"
    echo -e " 1. ${GREEN}Debian 12${RESET}"
    echo -e " 2. ${RED}Exit${RESET}"
    echo -e "${CYAN}=====================================${RESET}"
    read -rp "Enter your choice: " choice
    clear_previous_lines 5

    case $choice in
      1)
        os_version="12"

        if virt-install --os-variant list | grep -q "debian12"; then
          os_variant="debian12"
        else
          os_variant="debian11"
        fi

        iso_name="$DEB_12_ISO_NAME"
        iso_url="$DEB_12_ISO_URL"
        iso_path="/var/kvm/iso/$DEB_12_ISO_NAME"
        break
        ;;
      2)
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid choice. Please try again.${RESET}"
        sleep 1
        clear_previous_lines 1
        ;;
    esac
  done
}

download_iso() {
  if [ ! -f "/var/kvm/iso/$iso_name" ]; then
    echo -e "${YELLOW}Downloading $iso_name...${RESET}"
    wget -P /var/kvm/iso $iso_url
    if [ $? -ne 0 ]; then
      echo -e "${RED}Failed to download the ISO!${RESET}"
      exit 1
    fi
  fi
}

# Select Network
select_network() {
  while true; do
    echo -e "${BOLD}${CYAN}======== Select Network ========${RESET}"
    echo -e " 1. Default"
    echo -e " 2. br0"
    echo -e " 3. Enter manually"
    echo -e " 4. Exit"
    echo -e "${CYAN}=================================${RESET}"
    read -rp "Enter your choice: " choice
    clear_previous_lines 7

    case $choice in
      1)
        network="default"
        break
        ;;
      2)
        network="bridge=br0"
        break
        ;;
      3)
        read -rp "Enter the network name: " network
        break
        ;;
      4)
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid choice. Please try again.${RESET}"
        sleep 1
        clear_previous_lines 1
        ;;
    esac
  done
}

# Enter VM Name
get_vm_name() {
  read -rp "Enter VM name: " vm_name
  clear_previous_lines 1
}

# Enter vCPU Count
get_vcpu() {
  read -rp "Enter the number of vCPUs: " vcpu
  clear_previous_lines 1
}

# Enter Memory Size
get_memory() {
  read -rp "Enter memory size (GiB): " temp_memory
  memory=$((temp_memory * 1024))
  clear_previous_lines 1
}

# Enter Disk Size
get_disk_size() {
  read -rp "Enter disk size (GiB): " disk_size
  clear_previous_lines 1
}

# Auto Setup
auto_setup() {
  while true; do
    echo -e "${BOLD}${CYAN}======== Select VM Specs ========${RESET}"
    echo -e " 1. Small (1 vCPU, 1 GiB memory, 10 GiB disk)"
    echo -e " 2. Medium (2 vCPU, 2 GiB memory, 20 GiB disk)"
    echo -e " 3. Large (4 vCPU, 4 GiB memory, 40 GiB disk)"
    echo -e " 4. Enter manually"
    echo -e " 5. Exit"
    echo -e "${CYAN}==================================${RESET}"
    read -rp "Enter your choice: " choice
    clear_previous_lines 8

    case $choice in
      1)
        vcpu=1
        memory=1024
        disk_size=10
        break
        ;;
      2)
        vcpu=2
        memory=2048
        disk_size=20
        break
        ;;
      3)
        vcpu=4
        memory=4096
        disk_size=40
        break
        ;;
      4)
        get_vcpu
        get_memory
        get_disk_size
        break
        ;;
      5)
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid choice. Please try again.${RESET}"
        sleep 1
        clear_previous_lines 1
        ;;
    esac
  done
}

change_specs() {
  while true; do
    echo -e "${BOLD}${CYAN}======= Current VM Specs =======${RESET}"
    echo -e " vCPU: ${YELLOW}$vcpu${RESET}, Memory: ${YELLOW}${memory}MB${RESET}, Disk: ${YELLOW}${disk_size}GiB${RESET}"
    echo -e "${CYAN}================================${RESET}"
    echo -e " 1. Change vCPU"
    echo -e " 2. Change memory"
    echo -e " 3. Change disk size"
    echo -e " 4. Done"
    echo -e "${CYAN}================================${RESET}"
    read -rp "Enter your choice: " choice
    clear_previous_lines 9

    case $choice in
      1)
        get_vcpu
        ;;
      2)
        get_memory
        ;;
      3)
        get_disk_size
        ;;
      4)
        break
        ;;
      *)
        echo -e "${RED}Invalid choice. Please try again.${RESET}"
        sleep 1
        clear_previous_lines 2
        ;;
    esac
  done
}

install_vm() {
  echo -e "${BOLD}${CYAN}======= Installing VM =======${RESET}"
  echo -e " Name: ${YELLOW}$vm_name${RESET}"
  echo -e " vCPUs: ${YELLOW}$vcpu${RESET}, Memory: ${YELLOW}${memory}MB${RESET}, Disk: ${YELLOW}${disk_size}GiB${RESET}"
  echo -e " Network: ${YELLOW}$network${RESET}"
  echo -e " ISO: ${YELLOW}$iso_path${RESET}"
  echo -e "${CYAN}================================${RESET}"
  sleep 1  # wait for 1 second

  # Check disk directory and ISO file path
  if [ ! -d /var/kvm/disks ] || [ ! -d /var/kvm/iso ] || [ ! -f "$iso_path" ]; then
    echo -e "${RED}Failed to find the disk or ISO directory!${RESET}"
    exit 1
  fi

  virt-install \
    --name "$vm_name" \
    --vcpus "$vcpu" \
    --cpu mode=host-passthrough \
    --memory "$memory" \
    --disk size="$disk_size",format=qcow2,path="/var/kvm/disks/$vm_name.qcow2" \
    --network "$network" \
    --graphics none \
    --location "$iso_path" \
    --os-variant "$os_variant" \
    --boot uefi \
    --extra-args 'console=tty0 console=ttyS0,115200n8 --- console=tty0 console=ttyS0,115200n8'

  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install the VM!${RESET}"
    exit 1
  fi

  echo -e "${GREEN}✔ VM installation complete!${RESET}"
}

# Directory setup
setup() {
  if ! command -v wget &> /dev/null; then
    echo -e "${YELLOW}wget command not found. Installing wget...${RESET}"
    if command -v apt &> /dev/null; then
      apt update && apt install -y wget
    elif command -v dnf &> /dev/null; then
      dnf install -y wget
    elif command -v yum &> /dev/null; then
      yum install -y wget
    else
      echo -e "${RED}Failed to install wget!${RESET}"
      exit 1
    fi
  fi

  if ! command -v virt-install &> /dev/null; then
    echo -e "${YELLOW}virt-install command not found. Installing virt-install...${RESET}"
    if command -v apt &> /dev/null; then
      apt update && apt install -y virtinst
    elif command -v dnf &> /dev/null; then
      dnf install -y virt-install
    elif command -v yum &> /dev/null; then
      yum install -y virt-install
    else
      echo -e "${RED}Failed to install virt-install!${RESET}"
      exit 1
    fi
  fi

  mkdir -p /var/kvm && mkdir -p /var/kvm/disks && mkdir -p /var/kvm/iso
  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to create the directory!${RESET}"
    exit 1
  fi
}

# Main Menu
main() {
  setup

  while true; do
    echo -e "${BOLD}${CYAN}========== VM Setup ==========${RESET}"
    echo -e " 1. Auto setup"
    echo -e " 2. Manual setup"
    echo -e " 3. Exit"
    echo -e "${CYAN}================================${RESET}"
    read -rp "Enter your choice: " choice
    clear_previous_lines 6

    case $choice in
      1)
        get_vm_name
        select_os
        select_network
        auto_setup
        change_specs
        download_iso
        install_vm
        break
        ;;
      2)
        get_vm_name
        select_os
        select_network
        get_vcpu
        get_memory
        get_disk_size
        change_specs
        download_iso
        install_vm
        break
        ;;
      3)
        break
        ;;
      *)
        echo -e "${RED}Invalid choice. Please try again.${RESET}"
        sleep 1
        clear_previous_lines 1
        ;;
    esac
  done
}

main

