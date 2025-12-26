/// Namespace mode configuration
class NamespaceMode {
  final String? nsmode;
  final String? value;

  NamespaceMode({
    this.nsmode,
    this.value,
  });

  Map<String, dynamic> toJson() => {
    if (nsmode != null) 'nsmode': nsmode,
    if (value != null) 'value': value,
  };
}

/// Log configuration
class LogConfiguration {
  final String? driver;
  final Map<String, String>? options;
  final String? path;
  final int? size;

  LogConfiguration({
    this.driver,
    this.options,
    this.path,
    this.size,
  });

  Map<String, dynamic> toJson() => {
    if (driver != null) 'driver': driver,
    if (options != null) 'options': options,
    if (path != null) 'path': path,
    if (size != null) 'size': size,
  };
}

/// Bind mount options
class BindOptions {
  final bool? createMountpoint;
  final bool? nonRecursive;
  final String? propagation;
  final bool? readOnlyForceRecursive;
  final bool? readOnlyNonRecursive;

  BindOptions({
    this.createMountpoint,
    this.nonRecursive,
    this.propagation,
    this.readOnlyForceRecursive,
    this.readOnlyNonRecursive,
  });

  Map<String, dynamic> toJson() => {
    if (createMountpoint != null) 'CreateMountpoint': createMountpoint,
    if (nonRecursive != null) 'NonRecursive': nonRecursive,
    if (propagation != null) 'Propagation': propagation,
    if (readOnlyForceRecursive != null)
      'ReadOnlyForceRecursive': readOnlyForceRecursive,
    if (readOnlyNonRecursive != null)
      'ReadOnlyNonRecursive': readOnlyNonRecursive,
  };
}

/// Tmpfs mount options
class TmpfsOptions {
  final int? mode;
  final List<List<String>>? options;
  final int? sizeBytes;

  TmpfsOptions({
    this.mode,
    this.options,
    this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
    if (mode != null) 'Mode': mode,
    if (options != null) 'Options': options,
    if (sizeBytes != null) 'SizeBytes': sizeBytes,
  };
}

/// Volume driver configuration
class VolumeDriverConfig {
  final String? name;
  final Map<String, String>? options;

  VolumeDriverConfig({
    this.name,
    this.options,
  });

  Map<String, dynamic> toJson() => {
    if (name != null) 'Name': name,
    if (options != null) 'Options': options,
  };
}

/// Volume mount options
class VolumeMountOptions {
  final VolumeDriverConfig? driverConfig;
  final Map<String, String>? labels;
  final bool? noCopy;
  final String? subpath;

  VolumeMountOptions({
    this.driverConfig,
    this.labels,
    this.noCopy,
    this.subpath,
  });

  Map<String, dynamic> toJson() => {
    if (driverConfig != null) 'DriverConfig': driverConfig!.toJson(),
    if (labels != null) 'Labels': labels,
    if (noCopy != null) 'NoCopy': noCopy,
    if (subpath != null) 'Subpath': subpath,
  };
}

/// Image volume configuration
class ImageVolume {
  final String? destination;
  final bool? readWrite;
  final String? source;
  final String? subPath;

  ImageVolume({
    this.destination,
    this.readWrite,
    this.source,
    this.subPath,
  });

  Map<String, dynamic> toJson() => {
    if (destination != null) 'Destination': destination,
    if (readWrite != null) 'ReadWrite': readWrite,
    if (source != null) 'Source': source,
    if (subPath != null) 'subPath': subPath,
  };
}

/// Volume configuration
class Volume {
  final String? dest;
  final bool? isAnonymous;
  final String? name;
  final List<String>? options;
  final String? subPath;

  Volume({
    this.dest,
    this.isAnonymous,
    this.name,
    this.options,
    this.subPath,
  });

  Map<String, dynamic> toJson() => {
    if (dest != null) 'Dest': dest,
    if (isAnonymous != null) 'IsAnonymous': isAnonymous,
    if (name != null) 'Name': name,
    if (options != null) 'Options': options,
    if (subPath != null) 'SubPath': subPath,
  };
}

/// Overlay volume configuration
class OverlayVolume {
  final String? destination;
  final List<String>? options;
  final String? source;

  OverlayVolume({
    this.destination,
    this.options,
    this.source,
  });

  Map<String, dynamic> toJson() => {
    if (destination != null) 'destination': destination,
    if (options != null) 'options': options,
    if (source != null) 'source': source,
  };
}

/// Artifact volume configuration
class ArtifactVolume {
  final String? destination;
  final String? digest;
  final String? name;
  final String? source;
  final String? title;

  ArtifactVolume({
    this.destination,
    this.digest,
    this.name,
    this.source,
    this.title,
  });

  Map<String, dynamic> toJson() => {
    if (destination != null) 'destination': destination,
    if (digest != null) 'digest': digest,
    if (name != null) 'name': name,
    if (source != null) 'source': source,
    if (title != null) 'title': title,
  };
}

/// Secret configuration
class Secret {
  final String? key;
  final String? secret;

  Secret({
    this.key,
    this.secret,
  });

  Map<String, dynamic> toJson() => {
    if (key != null) 'Key': key,
    if (secret != null) 'Secret': secret,
  };
}

/// Personality configuration
class Personality {
  final String? domain;
  final List<String>? flags;

  Personality({
    this.domain,
    this.flags,
  });

  Map<String, dynamic> toJson() => {
    if (domain != null) 'domain': domain,
    if (flags != null) 'flags': flags,
  };
}

/// Throttle device configuration
class ThrottleDevice {
  final int? major;
  final int? minor;
  final int? rate;

  ThrottleDevice({
    this.major,
    this.minor,
    this.rate,
  });

  Map<String, dynamic> toJson() => {
    if (major != null) 'major': major,
    if (minor != null) 'minor': minor,
    if (rate != null) 'rate': rate,
  };
}

/// Weight device configuration
class WeightDevice {
  final int? leafWeight;
  final int? major;
  final int? minor;
  final int? weight;

  WeightDevice({
    this.leafWeight,
    this.major,
    this.minor,
    this.weight,
  });

  Map<String, dynamic> toJson() => {
    if (leafWeight != null) 'leafWeight': leafWeight,
    if (major != null) 'major': major,
    if (minor != null) 'minor': minor,
    if (weight != null) 'weight': weight,
  };
}

/// Device cgroup rule
class DeviceCgroupRule {
  final String? access;
  final bool? allow;
  final int? major;
  final int? minor;
  final String? type;

  DeviceCgroupRule({
    this.access,
    this.allow,
    this.major,
    this.minor,
    this.type,
  });

  Map<String, dynamic> toJson() => {
    if (access != null) 'access': access,
    if (allow != null) 'allow': allow,
    if (major != null) 'major': major,
    if (minor != null) 'minor': minor,
    if (type != null) 'type': type,
  };
}

/// Huge page limit configuration
class HugePageLimit {
  final int? limit;
  final String? pageSize;

  HugePageLimit({
    this.limit,
    this.pageSize,
  });

  Map<String, dynamic> toJson() => {
    if (limit != null) 'limit': limit,
    if (pageSize != null) 'pageSize': pageSize,
  };
}

/// ID mapping configuration
class IDMapping {
  final int? containerId;
  final int? hostId;
  final int? size;

  IDMapping({
    this.containerId,
    this.hostId,
    this.size,
  });

  Map<String, dynamic> toJson() => {
    if (containerId != null) 'container_id': containerId,
    if (hostId != null) 'host_id': hostId,
    if (size != null) 'size': size,
  };
}

/// Auto user namespace options
class AutoUserNsOpts {
  final List<IDMapping>? additionalGIDMappings;
  final List<IDMapping>? additionalUIDMappings;
  final String? groupFile;
  final int? initialSize;
  final String? passwdFile;
  final int? size;

  AutoUserNsOpts({
    this.additionalGIDMappings,
    this.additionalUIDMappings,
    this.groupFile,
    this.initialSize,
    this.passwdFile,
    this.size,
  });

  Map<String, dynamic> toJson() => {
    if (additionalGIDMappings != null)
      'AdditionalGIDMappings': additionalGIDMappings!
          .map((m) => m.toJson())
          .toList(),
    if (additionalUIDMappings != null)
      'AdditionalUIDMappings': additionalUIDMappings!
          .map((m) => m.toJson())
          .toList(),
    if (groupFile != null) 'GroupFile': groupFile,
    if (initialSize != null) 'InitialSize': initialSize,
    if (passwdFile != null) 'PasswdFile': passwdFile,
    if (size != null) 'Size': size,
  };
}

/// ID mappings configuration
class IDMappings {
  final bool? autoUserNs;
  final AutoUserNsOpts? autoUserNsOpts;
  final List<IDMapping>? gidMap;
  final bool? hostGIDMapping;
  final bool? hostUIDMapping;
  final List<IDMapping>? uidMap;

  IDMappings({
    this.autoUserNs,
    this.autoUserNsOpts,
    this.gidMap,
    this.hostGIDMapping,
    this.hostUIDMapping,
    this.uidMap,
  });

  Map<String, dynamic> toJson() => {
    if (autoUserNs != null) 'AutoUserNs': autoUserNs,
    if (autoUserNsOpts != null) 'AutoUserNsOpts': autoUserNsOpts!.toJson(),
    if (gidMap != null) 'GIDMap': gidMap!.map((m) => m.toJson()).toList(),
    if (hostGIDMapping != null) 'HostGIDMapping': hostGIDMapping,
    if (hostUIDMapping != null) 'HostUIDMapping': hostUIDMapping,
    if (uidMap != null) 'UIDMap': uidMap!.map((m) => m.toJson()).toList(),
  };
}

/// Intel RDT configuration
class IntelRdt {
  final String? closID;
  final bool? enableMonitoring;
  final String? l3CacheSchema;
  final String? memBwSchema;
  final List<String>? schemata;

  IntelRdt({
    this.closID,
    this.enableMonitoring,
    this.l3CacheSchema,
    this.memBwSchema,
    this.schemata,
  });

  Map<String, dynamic> toJson() => {
    if (closID != null) 'closID': closID,
    if (enableMonitoring != null) 'enableMonitoring': enableMonitoring,
    if (l3CacheSchema != null) 'l3CacheSchema': l3CacheSchema,
    if (memBwSchema != null) 'memBwSchema': memBwSchema,
    if (schemata != null) 'schemata': schemata,
  };
}

/// Network priority configuration
class NetworkPriority {
  final String? name;
  final int? priority;

  NetworkPriority({
    this.name,
    this.priority,
  });

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (priority != null) 'priority': priority,
  };
}

/// Network resource limits
class NetworkResources {
  final int? classID;
  final List<NetworkPriority>? priorities;

  NetworkResources({
    this.classID,
    this.priorities,
  });

  Map<String, dynamic> toJson() => {
    if (classID != null) 'classID': classID,
    if (priorities != null)
      'priorities': priorities!.map((p) => p.toJson()).toList(),
  };
}

/// RDMA resource limits
class RDMAResources {
  final Map<String, dynamic>? resources;

  RDMAResources({
    this.resources,
  });

  Map<String, dynamic> toJson() => {
    if (resources != null) ...resources!,
  };
}

/// Block I/O resource configuration
class BlockIOResources {
  final int? leafWeight;
  final List<ThrottleDevice>? throttleReadBpsDevice;
  final List<ThrottleDevice>? throttleReadIOPSDevice;
  final List<ThrottleDevice>? throttleWriteBpsDevice;
  final List<ThrottleDevice>? throttleWriteIOPSDevice;
  final int? weight;
  final List<WeightDevice>? weightDevice;

  BlockIOResources({
    this.leafWeight,
    this.throttleReadBpsDevice,
    this.throttleReadIOPSDevice,
    this.throttleWriteBpsDevice,
    this.throttleWriteIOPSDevice,
    this.weight,
    this.weightDevice,
  });

  Map<String, dynamic> toJson() => {
    if (leafWeight != null) 'leafWeight': leafWeight,
    if (throttleReadBpsDevice != null)
      'throttleReadBpsDevice': throttleReadBpsDevice!
          .map((d) => d.toJson())
          .toList(),
    if (throttleReadIOPSDevice != null)
      'throttleReadIOPSDevice': throttleReadIOPSDevice!
          .map((d) => d.toJson())
          .toList(),
    if (throttleWriteBpsDevice != null)
      'throttleWriteBpsDevice': throttleWriteBpsDevice!
          .map((d) => d.toJson())
          .toList(),
    if (throttleWriteIOPSDevice != null)
      'throttleWriteIOPSDevice': throttleWriteIOPSDevice!
          .map((d) => d.toJson())
          .toList(),
    if (weight != null) 'weight': weight,
    if (weightDevice != null)
      'weightDevice': weightDevice!.map((d) => d.toJson()).toList(),
  };
}

/// CPU resource configuration
class CPUResources {
  final int? burst;
  final String? cpus;
  final int? idle;
  final String? mems;
  final int? period;
  final int? quota;
  final int? realtimePeriod;
  final int? realtimeRuntime;
  final int? shares;

  CPUResources({
    this.burst,
    this.cpus,
    this.idle,
    this.mems,
    this.period,
    this.quota,
    this.realtimePeriod,
    this.realtimeRuntime,
    this.shares,
  });

  Map<String, dynamic> toJson() => {
    if (burst != null) 'burst': burst,
    if (cpus != null) 'cpus': cpus,
    if (idle != null) 'idle': idle,
    if (mems != null) 'mems': mems,
    if (period != null) 'period': period,
    if (quota != null) 'quota': quota,
    if (realtimePeriod != null) 'realtimePeriod': realtimePeriod,
    if (realtimeRuntime != null) 'realtimeRuntime': realtimeRuntime,
    if (shares != null) 'shares': shares,
  };
}

/// Memory resource configuration
class MemoryResources {
  final bool? checkBeforeUpdate;
  final bool? disableOOMKiller;
  final int? kernel;
  final int? kernelTCP;
  final int? limit;
  final int? reservation;
  final int? swap;
  final int? swappiness;
  final bool? useHierarchy;

  MemoryResources({
    this.checkBeforeUpdate,
    this.disableOOMKiller,
    this.kernel,
    this.kernelTCP,
    this.limit,
    this.reservation,
    this.swap,
    this.swappiness,
    this.useHierarchy,
  });

  Map<String, dynamic> toJson() => {
    if (checkBeforeUpdate != null) 'checkBeforeUpdate': checkBeforeUpdate,
    if (disableOOMKiller != null) 'disableOOMKiller': disableOOMKiller,
    if (kernel != null) 'kernel': kernel,
    if (kernelTCP != null) 'kernelTCP': kernelTCP,
    if (limit != null) 'limit': limit,
    if (reservation != null) 'reservation': reservation,
    if (swap != null) 'swap': swap,
    if (swappiness != null) 'swappiness': swappiness,
    if (useHierarchy != null) 'useHierarchy': useHierarchy,
  };
}

/// Network configuration
class NetworkConfig {
  final List<String>? aliases;
  final String? interfaceName;
  final Map<String, String>? options;
  final List<String>? staticIps;
  final String? staticMac;

  NetworkConfig({
    this.aliases,
    this.interfaceName,
    this.options,
    this.staticIps,
    this.staticMac,
  });

  Map<String, dynamic> toJson() => {
    if (aliases != null) 'aliases': aliases,
    if (interfaceName != null) 'interface_name': interfaceName,
    if (options != null) 'options': options,
    if (staticIps != null) 'static_ips': staticIps,
    if (staticMac != null) 'static_mac': staticMac,
  };
}

/// VolumeOptions - Image volume configuration
class VolumeOptions {
  final String destination;
  final bool readWrite;
  final String source;
  final String subPath;
  const VolumeOptions({
    required this.destination,
    required this.readWrite,
    required this.source,
    required this.subPath,
  });
  Map<String, dynamic> toJson() => {
    "Destination": destination,
    "ReadWrite": readWrite,
    "Source": source,
    "SubPath": subPath,
  };
}

/// Port mapping configuration
class PortMapping {
  final int containerPort;
  final int? hostPort;
  final String? hostIp;
  final String? protocol;

  PortMapping({
    required this.containerPort,
    this.hostPort,
    this.hostIp,
    this.protocol = 'tcp',
  });

  Map<String, dynamic> toJson() => {
    'container_port': containerPort,
    if (hostPort != null) 'host_port': hostPort,
    if (hostIp != null) 'host_ip': hostIp,
    if (protocol != null) 'protocol': protocol,
  };
}

/// Mount configuration
class Mount {
  final String type;
  final String source;
  final String target;
  final bool readOnly;
  final Map<String, dynamic>? bindOptions;
  final Map<String, dynamic>? volumeOptions;
  final Map<String, dynamic>? tmpfsOptions;

  Mount({
    required this.type,
    required this.source,
    required this.target,
    this.readOnly = false,
    this.bindOptions,
    this.volumeOptions,
    this.tmpfsOptions,
  });

  Map<String, dynamic> toJson() => {
    'Type': type,
    'Source': source,
    'Target': target,
    'ReadOnly': readOnly,
    if (bindOptions != null) 'BindOptions': bindOptions,
    if (volumeOptions != null) 'VolumeOptions': volumeOptions,
    if (tmpfsOptions != null) 'TmpfsOptions': tmpfsOptions,
  };
}

/// Device configuration
class Device {
  final String path;
  final String type;
  final int major;
  final int minor;
  final int? uid;
  final int? gid;

  Device({
    required this.path,
    required this.type,
    required this.major,
    required this.minor,
    this.uid,
    this.gid,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'type': type,
    'major': major,
    'minor': minor,
    if (uid != null) 'uid': uid,
    if (gid != null) 'gid': gid,
  };
}

/// Resource limits configuration
class ResourceLimits {
  final String? cpus;
  final int? memoryLimit;
  final int? memoryReservation;
  final int? memorySwap;
  final int? cpuShares;
  final int? cpuPeriod;
  final int? cpuQuota;
  final int? pidsLimit;
  final int? shmSize;

  ResourceLimits({
    this.cpus,
    this.memoryLimit,
    this.memoryReservation,
    this.memorySwap,
    this.cpuShares,
    this.cpuPeriod,
    this.cpuQuota,
    this.pidsLimit,
    this.shmSize,
  });

  Map<String, dynamic> toJson() => {
    if (cpus != null) 'cpu': {'cpus': cpus},
    if (memoryLimit != null || memoryReservation != null || memorySwap != null)
      'memory': {
        if (memoryLimit != null) 'limit': memoryLimit,
        if (memoryReservation != null) 'reservation': memoryReservation,
        if (memorySwap != null) 'swap': memorySwap,
      },
    if (cpuShares != null) 'cpu_shares': cpuShares,
    if (cpuPeriod != null) 'cpu_period': cpuPeriod,
    if (cpuQuota != null) 'cpu_quota': cpuQuota,
    if (pidsLimit != null) 'pids': {'limit': pidsLimit},
    if (shmSize != null) 'shm_size': shmSize,
  };
}

/// Health check configuration
class HealthCheck {
  final List<String>? test;
  final int? interval;
  final int? timeout;
  final int? retries;
  final int? startPeriod;
  final int? startInterval;

  HealthCheck({
    this.test,
    this.interval,
    this.timeout,
    this.retries,
    this.startPeriod,
    this.startInterval,
  });

  Map<String, dynamic> toJson() => {
    if (test != null) 'Test': test,
    if (interval != null) 'Interval': interval,
    if (timeout != null) 'Timeout': timeout,
    if (retries != null) 'Retries': retries,
    if (startPeriod != null) 'StartPeriod': startPeriod,
    if (startInterval != null) 'StartInterval': startInterval,
  };
}

/// Container specification for creation
class ContainerSpec {
  final String image;
  final String? name;
  final List<VolumeOptions>? volumeOptions;
  final List<String>? cmd;
  final List<String>? entrypoint;
  final Map<String, String>? env;
  final String? workdir;
  final String? user;
  final String? hostname;
  final bool? privileged;
  final bool? readOnlyFileSystem;
  final List<String>? capAdd;
  final List<String>? capDrop;
  final List<Device>? devices;
  final List<Mount>? mounts;
  final List<PortMapping>? portMappings;
  final bool? stdinOpen;
  final bool? terminal;
  final Map<String, String>? labels;
  final Map<String, String>? annotations;
  final ResourceLimits? resourceLimits;
  final HealthCheck? healthConfig;
  final String? restartPolicy;
  final int? restartTries;
  final int? stopTimeout;
  final int? stopSignal;
  final bool? remove;
  final List<String>? dns;
  final List<String>? dnsSearch;
  final List<String>? dnsOptions;
  final String? oomScoreAdj;
  final bool? noNewPrivileges;
  final Map<String, String>? sysctl;
  final List<String>? capAddList;
  final List<String>? capDropList;
  final bool? createWorkingDir;
  final List<String>? groups;
  final LogConfiguration? logConfiguration;
  final Map<String, NetworkConfig>? networks;
  final IDMappings? idMappings;
  final IntelRdt? intelRdt;
  final List<Volume>? volumes;
  final List<ImageVolume>? imageVolumes;
  final List<OverlayVolume>? overlayVolumes;
  final List<ArtifactVolume>? artifactVolumes;
  final List<Secret>? secrets;
  final Personality? personality;
  final List<DeviceCgroupRule>? deviceCgroupRules;
  final NamespaceMode? pidns;
  final NamespaceMode? ipcns;
  final NamespaceMode? utsns;
  final NamespaceMode? userns;
  final NamespaceMode? cgroupns;
  final NamespaceMode? netns;
  final CPUResources? cpuResources;
  final MemoryResources? memoryResources;
  final BlockIOResources? blockIOResources;
  final NetworkResources? networkResources;
  final RDMAResources? rdmaResources;
  final List<HugePageLimit>? hugePageLimits;
  final Map<String, String>? unified;
  final Map<String, dynamic>? storageOpts;
  final Map<String, dynamic>? networkOptions;
  final bool? init;
  final String? initPath;
  final String? timezone;
  final String? umask;
  final bool? httpproxy;
  final bool? volatile;
  final bool? readWriteTmpfs;
  final String? apparmorProfile;
  final String? seccompProfilePath;
  final List<String>? selinuxOpts;
  final List<String>? mask;
  final List<String>? unmask;
  final String? cgroupParent;
  final String? cgroupsMode;
  final String? ociRuntime;
  final String? rawImageName;
  final String? imageArch;
  final String? imageOs;
  final String? imageVariant;
  final String? imageVolumeMode;
  final bool? publishImagePorts;
  final bool? useImageHostname;
  final bool? useImageHosts;
  final bool? useImageResolveConf;
  final String? pod;
  final List<String>? dependencyContainers;
  final List<String>? devicesFrom;
  final List<String>? volumesFrom;
  final List<String>? hostadd;
  final List<String>? hostusers;
  final List<String>? envmerge;
  final List<String>? unsetenv;
  final bool? unsetenvall;
  final bool? envHost;
  final bool? managePassword;
  final bool? labelNested;
  final String? passwdEntry;
  final String? groupEntry;
  final String? baseHostsFile;
  final List<String>? procfsOpts;
  final List<String>? chrootDirectories;
  final List<String>? chroot;
  final String? conmonPidFile;
  final List<String>? containerCreateCommand;
  final String? healthLogDestination;
  final int? healthMaxLogCount;
  final int? healthMaxLogSize;
  final HealthCheck? startupHealthConfig;
  final int? healthCheckOnFailureAction;
  final String? sdnotifyMode;
  final String? systemd;
  final String? seccompPolicy;
  final Map<String, dynamic>? throttleReadBpsDevice;
  final Map<String, dynamic>? throttleReadIOPSDevice;
  final Map<String, dynamic>? throttleWriteBpsDevice;
  final Map<String, dynamic>? throttleWriteIOPSDevice;
  final Map<String, dynamic>? weightDevice;
  final List<String>? procOpts;
  final int? timeout;
  final int? shmSizeSystemd;
  final bool? rootfsOverlay;
  final String? rootfsPropagation;
  final String? rootfsMapping;
  final String? rootfs;
  final String? initContainerType;
  final bool? removeImage;

  ContainerSpec({
    required this.image,
    this.name,
    this.volumeOptions,
    this.cmd,
    this.entrypoint,
    this.env,
    this.workdir,
    this.user,
    this.hostname,
    this.privileged,
    this.readOnlyFileSystem,
    this.capAdd,
    this.capDrop,
    this.devices,
    this.mounts,
    this.portMappings,
    this.stdinOpen,
    this.terminal,
    this.labels,
    this.annotations,
    this.resourceLimits,
    this.healthConfig,
    this.restartPolicy,
    this.restartTries,
    this.stopTimeout,
    this.stopSignal,
    this.remove,
    this.dns,
    this.dnsSearch,
    this.dnsOptions,
    this.oomScoreAdj,
    this.noNewPrivileges,
    this.sysctl,
    this.capAddList,
    this.capDropList,
    this.createWorkingDir,
    this.groups,
    this.logConfiguration,
    this.networks,
    this.idMappings,
    this.intelRdt,
    this.volumes,
    this.imageVolumes,
    this.overlayVolumes,
    this.artifactVolumes,
    this.secrets,
    this.personality,
    this.deviceCgroupRules,
    this.pidns,
    this.ipcns,
    this.utsns,
    this.userns,
    this.cgroupns,
    this.netns,
    this.cpuResources,
    this.memoryResources,
    this.blockIOResources,
    this.networkResources,
    this.rdmaResources,
    this.hugePageLimits,
    this.unified,
    this.storageOpts,
    this.networkOptions,
    this.init,
    this.initPath,
    this.timezone,
    this.umask,
    this.httpproxy,
    this.volatile,
    this.readWriteTmpfs,
    this.apparmorProfile,
    this.seccompProfilePath,
    this.selinuxOpts,
    this.mask,
    this.unmask,
    this.cgroupParent,
    this.cgroupsMode,
    this.ociRuntime,
    this.rawImageName,
    this.imageArch,
    this.imageOs,
    this.imageVariant,
    this.imageVolumeMode,
    this.publishImagePorts,
    this.useImageHostname,
    this.useImageHosts,
    this.useImageResolveConf,
    this.pod,
    this.dependencyContainers,
    this.devicesFrom,
    this.volumesFrom,
    this.hostadd,
    this.hostusers,
    this.envmerge,
    this.unsetenv,
    this.unsetenvall,
    this.envHost,
    this.managePassword,
    this.labelNested,
    this.passwdEntry,
    this.groupEntry,
    this.baseHostsFile,
    this.procfsOpts,
    this.chrootDirectories,
    this.chroot,
    this.conmonPidFile,
    this.containerCreateCommand,
    this.healthLogDestination,
    this.healthMaxLogCount,
    this.healthMaxLogSize,
    this.startupHealthConfig,
    this.healthCheckOnFailureAction,
    this.sdnotifyMode,
    this.systemd,
    this.seccompPolicy,
    this.throttleReadBpsDevice,
    this.throttleReadIOPSDevice,
    this.throttleWriteBpsDevice,
    this.throttleWriteIOPSDevice,
    this.weightDevice,
    this.procOpts,
    this.timeout,
    this.shmSizeSystemd,
    this.rootfsOverlay,
    this.rootfsPropagation,
    this.rootfsMapping,
    this.rootfs,
    this.initContainerType,
    this.removeImage,
  });

  Map<String, dynamic> toJson() {
    final envList = env?.entries.map((e) => '${e.key}=${e.value}').toList();

    return {
      'image': image,
      if (name != null) 'name': name,
      if (volumeOptions != null) 'command': cmd,
      if (cmd != null) 'command': cmd,
      if (entrypoint != null) 'entrypoint': entrypoint,
      if (envList != null) 'env': envList,
      if (workdir != null) 'work_dir': workdir,
      if (user != null) 'user': user,
      if (hostname != null) 'hostname': hostname,
      if (privileged != null) 'privileged': privileged,
      if (readOnlyFileSystem != null)
        'read_only_filesystem': readOnlyFileSystem,
      if (capAdd != null) 'cap_add': capAdd,
      if (capDrop != null) 'cap_drop': capDrop,
      if (devices != null) 'devices': devices!.map((d) => d.toJson()).toList(),
      if (mounts != null) 'mounts': mounts!.map((m) => m.toJson()).toList(),
      if (portMappings != null)
        'portmappings': portMappings!.map((p) => p.toJson()).toList(),
      if (stdinOpen != null) 'stdin': stdinOpen,
      if (terminal != null) 'terminal': terminal,
      if (labels != null) 'labels': labels,
      if (annotations != null) 'annotations': annotations,
      if (resourceLimits != null) ...resourceLimits!.toJson(),
      if (healthConfig != null) 'healthconfig': healthConfig!.toJson(),
      if (restartPolicy != null) 'restart_policy': restartPolicy,
      if (restartTries != null) 'restart_tries': restartTries,
      if (stopTimeout != null) 'stop_timeout': stopTimeout,
      if (stopSignal != null) 'stop_signal': stopSignal,
      if (remove != null) 'remove': remove,
      if (dns != null) 'dns_server': dns,
      if (dnsSearch != null) 'dns_search': dnsSearch,
      if (dnsOptions != null) 'dns_option': dnsOptions,
      if (oomScoreAdj != null) 'oom_score_adj': oomScoreAdj,
      if (noNewPrivileges != null) 'no_new_privileges': noNewPrivileges,
      if (sysctl != null) 'sysctl': sysctl,
      if (capAddList != null) 'cap_add': capAddList,
      if (capDropList != null) 'cap_drop': capDropList,
      if (createWorkingDir != null) 'create_working_dir': createWorkingDir,
      if (groups != null) 'groups': groups,
      if (logConfiguration != null)
        'log_configuration': logConfiguration!.toJson(),
      if (networks != null)
        'Networks': networks!.map((k, v) => MapEntry(k, v.toJson())),
      if (idMappings != null) 'idmappings': idMappings!.toJson(),
      if (intelRdt != null) 'intelRdt': intelRdt!.toJson(),
      if (volumes != null) 'volumes': volumes!.map((v) => v.toJson()).toList(),
      if (imageVolumes != null)
        'image_volumes': imageVolumes!.map((v) => v.toJson()).toList(),
      if (overlayVolumes != null)
        'overlay_volumes': overlayVolumes!.map((v) => v.toJson()).toList(),
      if (artifactVolumes != null)
        'artifact_volumes': artifactVolumes!.map((v) => v.toJson()).toList(),
      if (secrets != null) 'secrets': secrets!.map((s) => s.toJson()).toList(),
      if (personality != null) 'personality': personality!.toJson(),
      if (deviceCgroupRules != null)
        'device_cgroup_rule': deviceCgroupRules!
            .map((r) => r.toJson())
            .toList(),
      if (pidns != null) 'pidns': pidns!.toJson(),
      if (ipcns != null) 'ipcns': ipcns!.toJson(),
      if (utsns != null) 'utsns': utsns!.toJson(),
      if (userns != null) 'userns': userns!.toJson(),
      if (cgroupns != null) 'cgroupns': cgroupns!.toJson(),
      if (netns != null) 'netns': netns!.toJson(),
      if (cpuResources != null)
        'resource_limits': {'cpu': cpuResources!.toJson()},
      if (memoryResources != null)
        'resource_limits': {'memory': memoryResources!.toJson()},
      if (blockIOResources != null)
        'resource_limits': {'blockIO': blockIOResources!.toJson()},
      if (networkResources != null)
        'resource_limits': {'network': networkResources!.toJson()},
      if (rdmaResources != null)
        'resource_limits': {'rdma': rdmaResources!.toJson()},
      if (hugePageLimits != null)
        'resource_limits': {
          'hugepageLimits': hugePageLimits!.map((h) => h.toJson()).toList(),
        },
      if (unified != null) 'unified': unified,
      if (storageOpts != null) 'storage_opts': storageOpts,
      if (networkOptions != null) 'network_options': networkOptions,
      if (init != null) 'init': init,
      if (initPath != null) 'init_path': initPath,
      if (timezone != null) 'timezone': timezone,
      if (umask != null) 'umask': umask,
      if (httpproxy != null) 'httpproxy': httpproxy,
      if (volatile != null) 'volatile': volatile,
      if (readWriteTmpfs != null) 'read_write_tmpfs': readWriteTmpfs,
      if (apparmorProfile != null) 'apparmor_profile': apparmorProfile,
      if (seccompProfilePath != null)
        'seccomp_profile_path': seccompProfilePath,
      if (selinuxOpts != null) 'selinux_opts': selinuxOpts,
      if (mask != null) 'mask': mask,
      if (unmask != null) 'unmask': unmask,
      if (cgroupParent != null) 'cgroup_parent': cgroupParent,
      if (cgroupsMode != null) 'cgroups_mode': cgroupsMode,
      if (ociRuntime != null) 'oci_runtime': ociRuntime,
      if (rawImageName != null) 'raw_image_name': rawImageName,
      if (imageArch != null) 'image_arch': imageArch,
      if (imageOs != null) 'image_os': imageOs,
      if (imageVariant != null) 'image_variant': imageVariant,
      if (imageVolumeMode != null) 'image_volume_mode': imageVolumeMode,
      if (publishImagePorts != null) 'publish_image_ports': publishImagePorts,
      if (useImageHostname != null) 'use_image_hostname': useImageHostname,
      if (useImageHosts != null) 'use_image_hosts': useImageHosts,
      if (useImageResolveConf != null)
        'use_image_resolve_conf': useImageResolveConf,
      if (pod != null) 'pod': pod,
      if (dependencyContainers != null)
        'dependencyContainers': dependencyContainers,
      if (devicesFrom != null) 'devices_from': devicesFrom,
      if (volumesFrom != null) 'volumes_from': volumesFrom,
      if (hostadd != null) 'hostadd': hostadd,
      if (hostusers != null) 'hostusers': hostusers,
      if (envmerge != null) 'envmerge': envmerge,
      if (unsetenv != null) 'unsetenv': unsetenv,
      if (unsetenvall != null) 'unsetenvall': unsetenvall,
      if (envHost != null) 'env_host': envHost,
      if (managePassword != null) 'manage_password': managePassword,
      if (labelNested != null) 'label_nested': labelNested,
      if (passwdEntry != null) 'passwd_entry': passwdEntry,
      if (groupEntry != null) 'group_entry': groupEntry,
      if (baseHostsFile != null) 'base_hosts_file': baseHostsFile,
      if (procfsOpts != null) 'procfs_opts': procfsOpts,
      if (chrootDirectories != null) 'chroot_directories': chrootDirectories,
      if (conmonPidFile != null) 'conmon_pid_file': conmonPidFile,
      if (containerCreateCommand != null)
        'containerCreateCommand': containerCreateCommand,
      if (healthLogDestination != null)
        'healthLogDestination': healthLogDestination,
      if (healthMaxLogCount != null) 'healthMaxLogCount': healthMaxLogCount,
      if (healthMaxLogSize != null) 'healthMaxLogSize': healthMaxLogSize,
      if (startupHealthConfig != null)
        'startupHealthConfig': startupHealthConfig!.toJson(),
      if (healthCheckOnFailureAction != null)
        'health_check_on_failure_action': healthCheckOnFailureAction,
      if (sdnotifyMode != null) 'sdnotifyMode': sdnotifyMode,
      if (systemd != null) 'systemd': systemd,
      if (seccompPolicy != null) 'seccomp_policy': seccompPolicy,
      if (throttleReadBpsDevice != null)
        'throttleReadBpsDevice': throttleReadBpsDevice,
      if (throttleReadIOPSDevice != null)
        'throttleReadIOPSDevice': throttleReadIOPSDevice,
      if (throttleWriteBpsDevice != null)
        'throttleWriteBpsDevice': throttleWriteBpsDevice,
      if (throttleWriteIOPSDevice != null)
        'throttleWriteIOPSDevice': throttleWriteIOPSDevice,
      if (weightDevice != null) 'weightDevice': weightDevice,
      if (procOpts != null) 'procfs_opts': procOpts,
      if (timeout != null) 'timeout': timeout,
      if (shmSizeSystemd != null) 'shm_size_systemd': shmSizeSystemd,
      if (rootfsOverlay != null) 'rootfs_overlay': rootfsOverlay,
      if (rootfsPropagation != null) 'rootfs_propagation': rootfsPropagation,
      if (rootfsMapping != null) 'rootfs_mapping': rootfsMapping,
      if (rootfs != null) 'rootfs': rootfs,
      if (initContainerType != null) 'init_container_type': initContainerType,
      if (removeImage != null) 'removeImage': removeImage,
    };
  }
}
