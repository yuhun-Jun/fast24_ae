
# FAST ’24 Artifacts Evaluation

## Title: We Ain't Afraid of No File Fragmentation: Cause and Prevention of Its Performance Impact on Modern Flash SSDs
Contact: Yuhun Jun (yuhun@skku.edu)

## Contents
- [1. Constraints](#1-constraints)
- [2. Getting Started Instructions](#2-getting-started-instructions)
- [3. Kernel Build](#3-kernel-build)
- [4. NVMeVirt Build](#4-nvmevirt-build)
- [5. Conducting Evaluation](#5-conducting-evaluation)
- [6. Results](#6-results)
- [7. Adaptation for Systems with Limited Resources](#7-adaptation-for-systems-with-limited-resources)

## 1. Constraints

The experimental environment requires the following specifications:

| **Component** | **Specification**                  |
|---------------|------------------------------------|
| Processor     | Intel Xeon Gold 6138 2.0 GHz, 20-Core |
| Chipset       | Intel C621                         |
| Memory        | DDR4 2666 MHz, 512 GB (32 GB x16)  |
| OS            | Ubuntu 20.04 Server (kernel v5.15.0)|

**Note:** NVMeVirt operates in DRAM and is sensitive to performance. It is recommended to use an environment with at least 128 GB of free space in a single NUMA node. As NVMeVirt requires a modified kernel, please follow the steps in this document sequentially.

This guide is based on a clean installation of Ubuntu 20.04 server.

## 2. Getting Started Instructions

Retrieve the necessary code from GitHub by executing the script below:

```bash
./cloneall.sh
```

Upon completion, the modified kernel and NVMeVirt will be downloaded into their respective directories.

## 3. Kernel Build
Before building the kernel, ensure the following packages are installed:

```bash
apt-get update
apt-get install build-essential libncurses5 libncurses5-dev bin86 kernel-package libssl-dev bison flex libelf-dev dwarves
```

Configure the kernel:

```bash
cd kernel
make olddefconfig
```

To modify the `.config` file for building, replace the values of CONFIG_SYSTEM_TRUSTED_KEYS and CONFIG_SYSTEM_REVOCATION_KEYS with an empty string (""). This can be found near line 10477.

```bash
CONFIG_SYSTEM_TRUSTED_KEYS=""
CONFIG_SYSTEM_REVOCATION_KEYS=""
```

Build the kernel:

```bash
make -j$(nproc) LOCALVERSION=
sudo make INSTALL_MOD_STRIP=1 modules_install  
make install
```

Reboot and boot into the newly built kernel.

## 4. NVMeVirt Build

Verify the kernel version:

```bash
uname -r
```

Once "5.15.0DA_515" is confirmed, proceed as follows:

```bash
cd nvmevirt
./build.sh
```

After the build, `nvmev_on.ko` and `nvmev_off.ko` will be copied to the evaluation directory.

## 5. Conducting Evaluation
The experimental operation requires superuser privileges as it uses `fdisk` and `insmod`.

To gain superuser access, enter the following command:

```bash
sudo su
```

Reserve memory for the emulated NVMe device's storage by modifying `/etc/default/grub`:

```bash
GRUB_CMDLINE_LINUX="memmap=128G\\\$256G intremap=off"
```

This reserves 128 GiB of physical memory starting at the 256 GiB offset. Adjust these values based on your physical memory size and storage capacity.

Update grub and reboot:

```bash
sudo update-grub
sudo reboot
```

NVMeVrit operates at high speeds in memory, which can lead to performance differences across NUMA nodes. Therefore, all tests specify a NUMA node using `numactl`. Install `numactl` with the following command:

```bash
apt install numactl
```

For accuracy, allocate CPUs in the same NUMA node as the reserved memory to NVMeVirt. Modify memmap_start, memmap_size, and cpus in nvmevstart_on.sh and nvmevstart_off.sh accordingly. Here's the default nvmevstart_on.sh script:

```bash
insmod ./nvmev_on.ko memmap_start=256G memmap_size=60G cpus=131,132,135,136
```

Ensure more memory is reserved than emulated (currently 128 GB for 60 GB emulation). 
Check the NUMA node's memory layout and corresponding CPUs:

```bash
numactl -H
```

**Caution!!!:** Incorrect configuration can damage the system.
NVMeVirt creates a new NVMe device, which is assigned a number following the last NVMe device in the system. To determine this, use the `lsblk` command to check the number of the last NVMe device in the system. Then, update the `DATA_NAME` in the `commonvariable.sh` file to the next number. Additionally, an extra device is required for operating with an external journal, so modify the `JOURNAL_NAME` accordingly. The current settings are based on using `nvme4` and `sdb`.

SQLite operates within programs written in C. To use SQLite, install the library with the command below.

```bash
apt-get install libsqlite3-dev
```

For Filebench experiments, download, build, and install Filebench from the official Filebench GitHub page:
[Filebench GitHub Repository](https://github.com/filebench/filebench)

### Hypothetical Workload

Execute the script below to perform hypothetical workloads, including append and overwrite tasks.

```bash
./hypothetical_append.sh
./hypothetical_overwrite.sh
```

Results will be saved in the `result` directory, starting with "append" and "overwrite". Report results as described in Section 6.

### SQLite Workload

The execution of the workload is performed by running the following script.

```bash
./sqlite.sh
```

Results will be in the `result` directory, starting with "sqlite". Report results as outlined in Section 6.

### fileserver workload

Execute the script below once Filebench is installed.

```bash
./fileserver.sh
./fileserver_small.sh
```

Results will be in the `result` directory, starting with "fileserver". Report results as explained in Section 6.
## 6. Results
Once the evaluation is complete, you can check the results all at once with the following command inside the evaluation directory.

```bash
./printresult.sh
```

Below is an example of completing all experiments in our system and printing the result.

```bash
 ==== Hypothetical Workload ==== 
 
Contiguous file: 2174.53 MB/s
 
Append Worst without Approach: 397.26 MB/s
Append Worst with Approach: 2126.48 MB/s
Append Random without Approach: 1470.01 MB/s
Append Random with Approach: 2063.64 MB/s
 
Overwrite Worst without Approach: 398.789 MB/s
Overwrite Worst with Approach: 2057.91 MB/s
Overwrite Random without Approach: 1487.34 MB/s
Overwrite Random with Approach: 2069.28 MB/s
 
 ==== sqlite Workload ==== 
 
sqlite contiguous : 870.044 MB/s
sqlite Append without Approach: 531.073 MB/s
sqlite Append with Approach: 849.64 MB/s
 
 ==== fileserver Workload ==== 
 
fileserver contiguous : 2739.8 MB/s
fileserver Append without Approach: 2149.4 MB/s
fileserver Append with Approach: 2611.8 MB/s
 
 ==== fileserver-small Workload ==== 
 
fileserver-small contiguous : 2776.3 MB/s
fileserver-small Append without Approach: 1721.0 MB/s
fileserver-small Append with Approach: 2099.3 MB/s
```

## 7. Adaptation for Systems with Limited Resources

The experiments typically use 128 GB of memory and emulate a 60 GB SSD. Here are modifications for systems with less memory, e.g., 16 GB to emulate a 10 GB SSD, assuming a single NUMA node system with 32 GB memory.

1. Reserve memory for the emulated NVMe device's storage by modifying `/etc/default/grub`:

```bash
GRUB_CMDLINE_LINUX="memmap=16G\\\\$16G intremap=off”
```

2. Modify NVMeVirt start scripts:

Edit memmap_start and memmap_size in nvmevstart_on.sh and nvmevstart_off.sh.

Example: `memmap_start=16G memmap_size=13G`


3. Adjust virtual device partition size:
Modify the second line of `setdevice.sh` from 50G to 10G.

```bash
sed -i 's/50/10/g' setdevice.sh
```

4. Exclude numactl:
Remove “numactl --cpubind=2 --membind=2” from each test script:

```bash
find . -type f -exec sed -i 's/numactl --cpubind=2 --membind=2 //g' {} +
```
