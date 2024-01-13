
# FAST ’24 Artifacts Evaluation

## Title: We Ain't Afraid of No File Fragmentation: Cause and Prevention of Its Performance Impact on Modern Flash SSDs
Contact: Yuhun Jun (yuhun@skku.edu)

This repository reproduces the evaluation presented in the paper published at FAST '24. The evaluation workload set consists of 'hypothetical,' 'sqlite,' and 'filebench' workloads. The evaluation is carried out with a modified NVMe-Virt on a Linux kernel that is also modified to incorporate the changes proposed in the paper. 'hypothetical' refers to a workload that induces performance degradation by repeatedly appending to and overwriting a file. Both 'sqlite' and 'filebench' are configured with scenarios that cause fragmentation. Detailed scenarios are described in the paper. The results of the experiments are categorized into three groups: contiguous, fragmented without the approach, and fragmented with the approach proposed in the paper.

## Contents
- [1. Configurations](#1-configurations)
- [2. Getting Started](#2-getting-started)
- [3. Kernel Build](#3-kernel-build)
- [4. NVMeVirt Build](#4-nvmevirt-build)
- [5. Conducting Evaluation](#5-conducting-evaluation)
- [6. Results](#6-results)
- [7. Adaptation for Systems with Limited Resources](#7-adaptation-for-systems-with-limited-resources)
- [8. Additional Evaluations](#8-additional-evaluations)

## 1. Configurations

The experimental environment was performed on the following hardware configurations:

| **Component** | **Specification**                  |
|---------------|------------------------------------|
| Processor     | Intel Xeon Gold 6138 2.0 GHz, 160-Core |
| Chipset       | Intel C621                         |
| Memory        | DDR4 2666 MHz, 512 GB (32 GB x16)  |
| OS            | Ubuntu 20.04 Server (kernel v5.15.0)|

However, it is expected that the evaluation can be reproduced on a different hardware setup as long as it has a sufficiently large amount of DRAM space. 

**Note:** NVMeVirt functions in DRAM and is performance-sensitive. For optimal performance, a setup with at least 128 GB of free space in a single NUMA node is recommended. Since NVMeVirt necessitates a modified kernel, ensure to follow this guide in the order presented.

A storage device is required to use the external journal during experiments. The path of the storage must be entered by modifying `commonvariable.sh`. Detailed information about this can be found in [Section 5](#5-conducting-evaluation).

This guide is based on a clean installation of Ubuntu 20.04 server.

## 2. Getting Started

We assume that "/" is the working directory.
```bash
cd /
git clone https://github.com/yuhun-Jun/fast24_ae.git
```

Retrieve the necessary code from GitHub by executing the script below:

```bash
cd fast24_ae
./cloneall.sh
```

For the experiment, it's necessary to build a modified version of the kernel and NVMeVirt, as well as install sqlite and filebench. Upon completion of the above command, the modified kernel and NVMeVirt will be downloaded into their respective directories. Details on the kernel and NVMeVirt builds are outlined starting from [Section 3](#3-kernel-build).

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

For building, modify the `.config` file by setting `CONFIG_SYSTEM_TRUSTED_KEYS` and `CONFIG_SYSTEM_REVOCATION_KEYS` to empty strings (""). These settings are typically located around line 10477.

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

Move to the 'fast24_ae' directory.
```bash
cd /fast24_ae
```

Navigate to the NVMeVirt directory and execute the build script.

```bash
cd nvmevirt
./build.sh
```

After the build, `nvmev_on.ko` and `nvmev_off.ko` will be copied to the `fast24_ae/evaluation` directory.

## 5. Conducting Evaluation
The experiments are conducted in the `evaluation` directory.
```bash
cd /fast24_ae/evaluation
```
The execution of the evaluation code requires superuser privileges as it uses `fdisk` and `insmod`.
To gain superuser access, enter the following command:

```bash
sudo su
```

Reserve memory for the emulated NVMe device's storage by modifying `/etc/default/grub`:
Please note that copying and pasting the content below may occasionally result in errors. It is strongly recommended to type it out manually.

```bash
GRUB_CMDLINE_LINUX="memmap=128G\\\$256G intremap=off"
```

This configuration reserves 128 GiB of physical memory starting at the 256 GiB offset. Tailor these values to match your system's physical memory size and storage capacity.

Update grub and reboot:

```bash
update-grub
reboot
```

NVMeVrit operates at high speeds in memory, which can lead to performance differences across NUMA nodes. Therefore, all tests specify a NUMA node using `numactl`. Install `numactl` with the following command:

```bash
apt install numactl
```

For accuracy, allocate CPUs in the same NUMA node as the reserved memory to NVMeVirt. Modify `memmap_start`, `memmap_size`, and `cpus` in `nvmevstart_on.sh` and `nvmevstart_off.sh` accordingly. Here's the default nvmevstart_on.sh script:

```bash
insmod ./nvmev_on.ko memmap_start=256G memmap_size=60G cpus=131,132,135,136
```
The above means to emulate a size of 60G starting from the physical memory location of 256G, and to allocate CPUs 131, 132, 135, and 136. For minimal performance variation, the CPUs should use the same NUMA node where the memory is located. Ensure more memory is reserved than emulated (currently 128 GB for 60 GB emulation). 
Check the NUMA node's memory layout and corresponding CPUs:

```bash
numactl -H
```
In the tested environment, the reserved memory area and CPU were on NUMA node 2. Therefore, all the scripts executed below use `numactl --cpubind=2 --membind=2` to conduct the experiments. If the NUMA node number of the system you are trying to replicate is different, it is recommended to modify the `NUMADOMAIN` settings in `commonvariable.sh` accordingly.

### NVMeVirt Test Execution
First, verify that NVMeVirt is functioning correctly in the current environment. If the memory reservation and the NVMeVirt script have been properly modified, the following commands should successfully create and then delete a virtual NVMe device. Verify that both versions, with the approach turned On and Off, are operational.

```bash
lsblk
# Check the number of the last NVMe device

./nvmevstart_off.sh
lsblk
# Check the number of the newly created NVMe device

rmmod nvmev
lsblk
# Verify the virtual device has been deleted

./nvmevstart_on.sh
lsblk
# Check the number of the newly created NVMe device

rmmod nvmev
lsblk
# Verify the virtual device has been deleted
```

**Caution!!!:** Improper configuration may cause system damage.
NVMeVirt creates a new NVMe device, which is assigned a number following the last NVMe device in the system. To determine this, use the `lsblk` command to check the number of the last NVMe device in the system. Then, update the `DATA_NAME` in the `commonvariable.sh` file to the next number. Additionally, an extra device is required for operating with an external journal, so modify the `JOURNAL_NAME` accordingly. The current settings are based on using `nvme4` and `sdb`.

**SQLite** operates within programs written in C. To use SQLite, install the library with the command below.

```bash
apt-get install libsqlite3-dev
```

For **Filebench** experiments, download, build, and install Filebench from the official Filebench GitHub page:
[Filebench GitHub Repository](https://github.com/filebench/filebench)

All preparations for running the tests are now complete. You can now execute the test and check the results using the script below.

### Hypothetical Workload

Execute the script below to perform hypothetical workloads, including append and overwrite tasks.
This experiment took about 8 minutes per script, totaling approximately 16 minutes.

```bash
./hypothetical_append.sh
./hypothetical_overwrite.sh
```

Results will be saved in the `result` directory, starting with "append" and "overwrite". Report results as described in [Section 6](#6-results).

### SQLite Workload

The execution of the workload is performed by running the following script.
This experiment took about 22 minutes in our system.

```bash
./sqlite.sh
```

Results will be in the `result` directory, starting with "sqlite". Report results as outlined in [Section 6](#6-results).

### fileserver workload

Execute the script below once Filebench is installed.
This experiment took about 45 minutes per script, totaling approximately 90 minutes.

```bash
./fileserver.sh
./fileserver_small.sh
```

Results will be in the `result` directory, starting with "fileserver". Report results as explained in [Section 6](#6-results).

Of course, all the above tests can be integrated into a single script below and executed at once.
```bash
./runall.sh
```

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

In our standard experiments, we use 128 GB of memory to accurately emulate a 60 GB SSD. For systems with limited memory capacity, such as using 16 GB to emulate a 10 GB SSD in a single NUMA node system equipped with 32 GB of memory, specific adjustments are required. The settings we recommend below are designed to broaden the range of test environments; however, they do not assure consistent results. Our experiments did reveal certain trends, but it's important to note that there was considerable variability in the outcome values.

1. Reserve memory for the emulated NVMe device's storage by modifying `/etc/default/grub`:

```bash
GRUB_CMDLINE_LINUX="memmap=16G\\\$16G intremap=off”
```

2. Modify NVMeVirt start scripts:

Edit `memmap_start` and `memmap_size` in `nvmevstart_on.sh` and `nvmevstart_off.sh`. Also, appropriately modify the `cpus` parameter in these scripts.

Example: `memmap_start=16G memmap_size=13G cpus=12,13,14,15`


3. Adjust virtual device partition size:
Modify the second line of `setdevice.sh` from 50G to 10G.

```bash
sed -i 's/50/10/g' setdevice.sh
```

4. Exclude numactl:
Set `0` to `NUMADOMAIN` in `commonvariable.sh`

By doing this, the experiment can be run even in environments with limited resources. However, the results cannot be guaranteed.

## 8. Additional Evaluations
The following are evaluations in areas of analysis where our approach is not included. Therefore, the modified NVMeVirt is not required.
Except for the ramdisk evaluation, actual devices are necessary to perform these tests. Performance variations may occur depending on system and device status, but the trends are guaranteed.

**Caution!!!:** 
The experiments below access real devices and perform a full-area trim (secure erase) during operation. Therefore, if multiple reviewers test simultaneously on the server, not only can results be contaminated, but there is also a risk of damaging the system.

To ensure the trim operation is performed, a read is executed for one minute to prevent the device from entering sleep mode. This is done through a FIO workload named `waittrim`.

The server provided for verification is equipped with `NVMe-A`, `B`, and `D`, and different scripts have been created to match each device number.
Access to devices other than those provided is strictly prohibited as they are already in use.
Like previous experiments, each test requires an extra drive for external journaling; the default is `sdb`.

Device verification can be done with the following command.
```bash
nvme list
```

When evaluating actual SSDs, accurate performance measurement is not possible if they fall into sleep state due to power management. Therefore, several scripts provided perform small reads in the background to prevent this.

In the server we evaluated, this phenomenon was found only with NVMe-A, and it may vary with different systems and SSDs. For evaluation, we manually performed background wakeups only for the problematic SSDs, but for automation, we have added it to all scripts.

**Note:** As the scripts perform device wipe during execution, utmost caution is needed when using them on different systems.
Each script has the device to be operated on fixed at the top, which must be modified according to the system.

### Pseudo Approach (Figure 11)
This experiment is the same as the previously shared hypothetical experiment, except that the device is changed to a real NVMe.

Appropriate stripe size and die granularity size values must be set for the device. The provided scripts are set to operate `NVMe-A` and `NVMe-B`.
The execution scripts for append write and overwrite are `pseudo_append_NVMe-X.sh` and `pseudo_overwrite_NVMe-X.sh`, respectively, and the results can be summarized through `printresult_pseudo.sh` in a similar manner to before.

For experiments with the device, it is recommended to apply a trim mean that excludes the maximum and minimum values among the ten reads performance generated in the result directory. The raw results are saved in a format like `NVMe-X_overwrite_off.txt`.

If experimenting with a different new device, the [alignment test](alignment) below should be conducted to infer the "die allocation granularity" and "stripe size" then modify the parameters.

These parameters and the device name are noted in `NVMeX.sh`.

### Alignment (Figure 8) 
Use FIO on the actual device to measure the throughput of 4 KB high queue depth while changing the alignment option from 1 to 1024 KB.

Each device can be evaluated with the following script: `alignment_NVMeX.sh` (X is A, B, D).  
Results can be found in the result directory under `alignment_NVMe-X.txt`.  
This experiment takes about 50 minutes per device.

### Varying DoF
This experiment observes the impact on read performance in `NVMe` and `ramdisk` by changing the DoF.  
For the experiment, the queue depth must be reduced to 1, but the default kernel's minimum queue depth is 4, so it is necessary to modify it to 1. It is already modified in the [kernel](#3-kernel-build) provided above.  
The parameter corresponding to queue depth value is `nr_request`, which can be found in the script.  
The script resides in the evaluation directory and reuses the code used in previous hypothetical evaluations.

#### with NVMe Drive (Figure 3)
This experiment performed on actual devices. It can be executed through `varyingdof_NVMeX.sh` (X is A or B).  
The results can be found in the result directory as `vd_NVMe-X_QD1.txt` and `vd_NVMe-X_QD1023.txt`, which show the read performance per DoF at queue depths of 1 and 1023, respectively.

#### with ramdisk (Figure 4) 
This experiment operates by mounting system DRAM as a device. It requires about 30GB of ramdisk capacity.  
`varyingdof_ramd.sh` can be used for execution. Since ramdisk creates an additional loop device, the correct number of the loop device generated in your system must be entered into the script. This value is the last loop device number +1. It can be easily found through the `lsblk` command.  
Upon completion of the experiment, the results can be found in the result directory as `vd_ramd_QD1.txt` and `vd_ramd_QD128.txt`. These show the read performance per DoF at queue depths of 1 and 128, respectively.

### Interface Overhead (Figure 7) 
This experiment observes the overhead due to fragmentation at different queue depths.  
This experiment, which measures throughput with very little IO, is not recommended for server experiments as the overhead due to device sleep is severely apparent.  
The protocol overhead of SSDs can be simply evaluated on a local machine. The evaluation consists of a single line of FIO code.  
The operational script is `interface_NVMe.sh`. The results are recorded as FIO logs in the `interfaceresult` directory.  
As measuring the short execution time of FIO is difficult, for QD1, you should multiply the average latency by the number of IOs, and for QD32, calculate the time by reverse calculating the throughput.

## Testing on SATA
All the above experiments can also be performed on SATA devices. However, the trim (secure erase) must be performed according to SATA.  
An example of performing a secure erase is as follows. Beforehand, the SATA device must be in an unfrozen state, which can be simply created by hot swapping after rebooting.  
Since automation is difficult, only the below secure erase script is shared.

(DEVICE=/dev/sdx)
```bash
hdparm --user-master u --security-set-pass p $DEVICE
hdparm --user-master u --security-erase-enhanced p $DEVICE
```
