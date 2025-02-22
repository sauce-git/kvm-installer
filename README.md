# KVM installer
##### Script to create a KVM using libvirt

### Usage
    chmod +x run.sh
    ./run.sh

### Requirements

##### Using apt (Debian/Ubuntu)

    sudo apt -y install bridge-utils libvirt-clients libvirt-daemon qemu qemu-kvm

##### Using dnf (Fedora)

    sudo dnf -y install bridge-utils libvirt-daemon-kvm qemu-kvm virt-install
