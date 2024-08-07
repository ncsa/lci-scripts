cluster_number=$1

if [ -z "${cluster_number}" ]; then
	echo "Please retry- specify cluster number, eg. 04"
	exit 1
fi

ssh lci-storage-${cluster_number}-1 "mkfs.lustre --mgs /dev/vdb"
ssh lci-storage-${cluster_number}-1 "mkfs.lustre --fsname=lci --mgsnode=lci-storage-${cluster_number}-1@tcp --mdt --index=0 /dev/vdc"
ssh lci-storage-${cluster_number}-1 "mkdir -p /mnt/mgt && mkdir -p /mnt/mdt && mount -t lustre /dev/vdb /mnt/mgt && mount -t lustre /dev/vdc /mnt/mdt"

ssh lci-storage-${cluster_number}-2 "mkfs.lustre --fsname=lci --mgsnode=lci-storage-${cluster_number}-1@tcp --ost --index=0 /dev/vdb"
ssh lci-storage-${cluster_number}-2 "mkfs.lustre --fsname=lci --mgsnode=lci-storage-${cluster_number}-1@tcp --ost --index=1 /dev/vdc"
ssh lci-storage-${cluster_number}-2 "mkdir -p /mnt/ost0 && mkdir -p /mnt/ost1 && mount -t lustre /dev/vdb /mnt/ost0 && mount -t lustre /dev/vdc /mnt/ost1"

ssh lci-storage-${cluster_number}-3 "mkfs.lustre --fsname=lci --mgsnode=lci-storage-${cluster_number}-1@tcp --ost --index=2 /dev/vdb"
ssh lci-storage-${cluster_number}-3 "mkfs.lustre --fsname=lci --mgsnode=lci-storage-${cluster_number}-1@tcp --ost --index=3 /dev/vdc"
ssh lci-storage-${cluster_number}-3 "mkdir -p /mnt/ost2 && mkdir -p /mnt/ost3 && mount -t lustre /dev/vdb /mnt/ost2 && mount -t lustre /dev/vdc /mnt/ost3"

ssh lci-storage-${cluster_number}-4 "mkfs.lustre --fsname=lci --mgsnode=lci-storage-${cluster_number}-1@tcp --ost --index=4 /dev/vdb"
ssh lci-storage-${cluster_number}-4 "mkfs.lustre --fsname=lci --mgsnode=lci-storage-${cluster_number}-1@tcp --ost --index=5 /dev/vdc"
ssh lci-storage-${cluster_number}-4 "mkdir -p /mnt/ost4 && mkdir -p /mnt/ost5 && mount -t lustre /dev/vdb /mnt/ost4 && mount -t lustre /dev/vdc /mnt/ost5"

ssh lci-compute-${cluster_number}-1 "mkdir -p /lustre/lci"
ssh lci-compute-${cluster_number}-1 "mount -t lustre lci-storage-${cluster_number}-1@tcp:/lci /lustre/lci"

ssh lci-compute-${cluster_number}-2 "mkdir -p /lustre/lci"
ssh lci-compute-${cluster_number}-2 "mount -t lustre lci-storage-${cluster_number}-1@tcp:/lci /lustre/lci"
