/// Docker-compatible container creation configuration
/// Aligns with CreateContainerConfig from Podman compat API
class CompatContainerConfig {
  final bool? argsEscaped;
  final bool? attachStderr;
  final bool? attachStdin;
  final bool? attachStdout;
  final List<String>? cmd;
  final String? domainname;
  final List<String>? entrypoint;
  final List<String>? env;
  final List<String>? envMerge;
  final Map<String, dynamic>? exposedPorts;
  final CompatHealthcheck? healthcheck;
  final CompatHostConfig? hostConfig;
  final String? hostname;
  final String image;
  final Map<String, String>? labels;
  final String? macAddress;
  final String? name;
  final bool? networkDisabled;
  final CompatNetworkingConfig? networkingConfig;
  final List<String>? onBuild;
  final bool? openStdin;
  final List<String>? shell;
  final bool? stdinOnce;
  final String? stopSignal;
  final int? stopTimeout;
  final bool? tty;
  final List<String>? unsetEnv;
  final bool? unsetEnvAll;
  final String? user;
  final Map<String, dynamic>? volumes;
  final String? workingDir;

  CompatContainerConfig({
    required this.image,
    this.argsEscaped,
    this.attachStderr,
    this.attachStdin,
    this.attachStdout,
    this.cmd,
    this.domainname,
    this.entrypoint,
    this.env,
    this.envMerge,
    this.exposedPorts,
    this.healthcheck,
    this.hostConfig,
    this.hostname,
    this.labels,
    this.macAddress,
    this.name,
    this.networkDisabled,
    this.networkingConfig,
    this.onBuild,
    this.openStdin,
    this.shell,
    this.stdinOnce,
    this.stopSignal,
    this.stopTimeout,
    this.tty,
    this.unsetEnv,
    this.unsetEnvAll,
    this.user,
    this.volumes,
    this.workingDir,
  });

  Map<String, dynamic> toJson() => {
    'Image': image,
    if (argsEscaped != null) 'ArgsEscaped': argsEscaped,
    if (attachStderr != null) 'AttachStderr': attachStderr,
    if (attachStdin != null) 'AttachStdin': attachStdin,
    if (attachStdout != null) 'AttachStdout': attachStdout,
    if (cmd != null) 'Cmd': cmd,
    if (domainname != null) 'Domainname': domainname,
    if (entrypoint != null) 'Entrypoint': entrypoint,
    if (env != null) 'Env': env,
    if (envMerge != null) 'EnvMerge': envMerge,
    if (exposedPorts != null) 'ExposedPorts': exposedPorts,
    if (healthcheck != null) 'Healthcheck': healthcheck!.toJson(),
    if (hostConfig != null) 'HostConfig': hostConfig!.toJson(),
    if (hostname != null) 'Hostname': hostname,
    if (labels != null) 'Labels': labels,
    if (macAddress != null) 'MacAddress': macAddress,
    if (name != null) 'Name': name,
    if (networkDisabled != null) 'NetworkDisabled': networkDisabled,
    if (networkingConfig != null)
      'NetworkingConfig': networkingConfig!.toJson(),
    if (onBuild != null) 'OnBuild': onBuild,
    if (openStdin != null) 'OpenStdin': openStdin,
    if (shell != null) 'Shell': shell,
    if (stdinOnce != null) 'StdinOnce': stdinOnce,
    if (stopSignal != null) 'StopSignal': stopSignal,
    if (stopTimeout != null) 'StopTimeout': stopTimeout,
    if (tty != null) 'Tty': tty,
    if (unsetEnv != null) 'UnsetEnv': unsetEnv,
    if (unsetEnvAll != null) 'UnsetEnvAll': unsetEnvAll,
    if (user != null) 'User': user,
    if (volumes != null) 'Volumes': volumes,
    if (workingDir != null) 'WorkingDir': workingDir,
  };
}

/// Docker-compatible HostConfig
class CompatHostConfig {
  final Map<String, String>? annotations;
  final bool? autoRemove;
  final List<String>? binds;
  final List<Map<String, dynamic>>? blkioDeviceReadBps;
  final List<Map<String, dynamic>>? blkioDeviceReadIOps;
  final List<Map<String, dynamic>>? blkioDeviceWriteBps;
  final List<Map<String, dynamic>>? blkioDeviceWriteIOps;
  final int? blkioWeight;
  final List<Map<String, dynamic>>? blkioWeightDevice;
  final List<String>? capAdd;
  final List<String>? capDrop;
  final String? cgroup;
  final String? cgroupParent;
  final String? cgroupnsMode;
  final List<int>? consoleSize;
  final String? containerIDFile;
  final int? cpuCount;
  final int? cpuPercent;
  final int? cpuPeriod;
  final int? cpuQuota;
  final int? cpuRealtimePeriod;
  final int? cpuRealtimeRuntime;
  final int? cpuShares;
  final String? cpusetCpus;
  final String? cpusetMems;
  final List<String>? deviceCgroupRules;
  final List<Map<String, dynamic>>? deviceRequests;
  final List<Map<String, dynamic>>? devices;
  final List<String>? dns;
  final List<String>? dnsOptions;
  final List<String>? dnsSearch;
  final List<String>? extraHosts;
  final List<String>? groupAdd;
  final int? ioMaximumBandwidth;
  final int? ioMaximumIOps;
  final bool? init;
  final String? ipcMode;
  final String? isolation;
  final int? kernelMemory;
  final int? kernelMemoryTCP;
  final List<String>? links;
  final Map<String, dynamic>? logConfig;
  final List<String>? maskedPaths;
  final int? memory;
  final int? memoryReservation;
  final int? memorySwap;
  final int? memorySwappiness;
  final List<Map<String, dynamic>>? mounts;
  final int? nanoCpus;
  final String? networkMode;
  final bool? oomKillDisable;
  final int? oomScoreAdj;
  final String? pidMode;
  final int? pidsLimit;
  final Map<String, List<Map<String, String>>>? portBindings;
  final bool? privileged;
  final bool? publishAllPorts;
  final List<String>? readonlyPaths;
  final bool? readonlyRootfs;
  final Map<String, dynamic>? restartPolicy;
  final String? runtime;
  final List<String>? securityOpt;
  final int? shmSize;
  final Map<String, String>? storageOpt;
  final Map<String, String>? sysctls;
  final Map<String, String>? tmpfs;
  final String? utsMode;
  final List<Map<String, dynamic>>? ulimits;
  final String? usernsMode;
  final String? volumeDriver;
  final List<String>? volumesFrom;

  CompatHostConfig({
    this.annotations,
    this.autoRemove,
    this.binds,
    this.blkioDeviceReadBps,
    this.blkioDeviceReadIOps,
    this.blkioDeviceWriteBps,
    this.blkioDeviceWriteIOps,
    this.blkioWeight,
    this.blkioWeightDevice,
    this.capAdd,
    this.capDrop,
    this.cgroup,
    this.cgroupParent,
    this.cgroupnsMode,
    this.consoleSize,
    this.containerIDFile,
    this.cpuCount,
    this.cpuPercent,
    this.cpuPeriod,
    this.cpuQuota,
    this.cpuRealtimePeriod,
    this.cpuRealtimeRuntime,
    this.cpuShares,
    this.cpusetCpus,
    this.cpusetMems,
    this.deviceCgroupRules,
    this.deviceRequests,
    this.devices,
    this.dns,
    this.dnsOptions,
    this.dnsSearch,
    this.extraHosts,
    this.groupAdd,
    this.ioMaximumBandwidth,
    this.ioMaximumIOps,
    this.init,
    this.ipcMode,
    this.isolation,
    this.kernelMemory,
    this.kernelMemoryTCP,
    this.links,
    this.logConfig,
    this.maskedPaths,
    this.memory,
    this.memoryReservation,
    this.memorySwap,
    this.memorySwappiness,
    this.mounts,
    this.nanoCpus,
    this.networkMode,
    this.oomKillDisable,
    this.oomScoreAdj,
    this.pidMode,
    this.pidsLimit,
    this.portBindings,
    this.privileged,
    this.publishAllPorts,
    this.readonlyPaths,
    this.readonlyRootfs,
    this.restartPolicy,
    this.runtime,
    this.securityOpt,
    this.shmSize,
    this.storageOpt,
    this.sysctls,
    this.tmpfs,
    this.utsMode,
    this.ulimits,
    this.usernsMode,
    this.volumeDriver,
    this.volumesFrom,
  });

  Map<String, dynamic> toJson() => {
    if (annotations != null) 'Annotations': annotations,
    if (autoRemove != null) 'AutoRemove': autoRemove,
    if (binds != null) 'Binds': binds,
    if (blkioDeviceReadBps != null) 'BlkioDeviceReadBps': blkioDeviceReadBps,
    if (blkioDeviceReadIOps != null) 'BlkioDeviceReadIOps': blkioDeviceReadIOps,
    if (blkioDeviceWriteBps != null) 'BlkioDeviceWriteBps': blkioDeviceWriteBps,
    if (blkioDeviceWriteIOps != null)
      'BlkioDeviceWriteIOps': blkioDeviceWriteIOps,
    if (blkioWeight != null) 'BlkioWeight': blkioWeight,
    if (blkioWeightDevice != null) 'BlkioWeightDevice': blkioWeightDevice,
    if (capAdd != null) 'CapAdd': capAdd,
    if (capDrop != null) 'CapDrop': capDrop,
    if (cgroup != null) 'Cgroup': cgroup,
    if (cgroupParent != null) 'CgroupParent': cgroupParent,
    if (cgroupnsMode != null) 'CgroupnsMode': cgroupnsMode,
    if (consoleSize != null) 'ConsoleSize': consoleSize,
    if (containerIDFile != null) 'ContainerIDFile': containerIDFile,
    if (cpuCount != null) 'CpuCount': cpuCount,
    if (cpuPercent != null) 'CpuPercent': cpuPercent,
    if (cpuPeriod != null) 'CpuPeriod': cpuPeriod,
    if (cpuQuota != null) 'CpuQuota': cpuQuota,
    if (cpuRealtimePeriod != null) 'CpuRealtimePeriod': cpuRealtimePeriod,
    if (cpuRealtimeRuntime != null) 'CpuRealtimeRuntime': cpuRealtimeRuntime,
    if (cpuShares != null) 'CpuShares': cpuShares,
    if (cpusetCpus != null) 'CpusetCpus': cpusetCpus,
    if (cpusetMems != null) 'CpusetMems': cpusetMems,
    if (deviceCgroupRules != null) 'DeviceCgroupRules': deviceCgroupRules,
    if (deviceRequests != null) 'DeviceRequests': deviceRequests,
    if (devices != null) 'Devices': devices,
    if (dns != null) 'Dns': dns,
    if (dnsOptions != null) 'DnsOptions': dnsOptions,
    if (dnsSearch != null) 'DnsSearch': dnsSearch,
    if (extraHosts != null) 'ExtraHosts': extraHosts,
    if (groupAdd != null) 'GroupAdd': groupAdd,
    if (ioMaximumBandwidth != null) 'IOMaximumBandwidth': ioMaximumBandwidth,
    if (ioMaximumIOps != null) 'IOMaximumIOps': ioMaximumIOps,
    if (init != null) 'Init': init,
    if (ipcMode != null) 'IpcMode': ipcMode,
    if (isolation != null) 'Isolation': isolation,
    if (kernelMemory != null) 'KernelMemory': kernelMemory,
    if (kernelMemoryTCP != null) 'KernelMemoryTCP': kernelMemoryTCP,
    if (links != null) 'Links': links,
    if (logConfig != null) 'LogConfig': logConfig,
    if (maskedPaths != null) 'MaskedPaths': maskedPaths,
    if (memory != null) 'Memory': memory,
    if (memoryReservation != null) 'MemoryReservation': memoryReservation,
    if (memorySwap != null) 'MemorySwap': memorySwap,
    if (memorySwappiness != null) 'MemorySwappiness': memorySwappiness,
    if (mounts != null) 'Mounts': mounts,
    if (nanoCpus != null) 'NanoCpus': nanoCpus,
    if (networkMode != null) 'NetworkMode': networkMode,
    if (oomKillDisable != null) 'OomKillDisable': oomKillDisable,
    if (oomScoreAdj != null) 'OomScoreAdj': oomScoreAdj,
    if (pidMode != null) 'PidMode': pidMode,
    if (pidsLimit != null) 'PidsLimit': pidsLimit,
    if (portBindings != null) 'PortBindings': portBindings,
    if (privileged != null) 'Privileged': privileged,
    if (publishAllPorts != null) 'PublishAllPorts': publishAllPorts,
    if (readonlyPaths != null) 'ReadonlyPaths': readonlyPaths,
    if (readonlyRootfs != null) 'ReadonlyRootfs': readonlyRootfs,
    if (restartPolicy != null) 'RestartPolicy': restartPolicy,
    if (runtime != null) 'Runtime': runtime,
    if (securityOpt != null) 'SecurityOpt': securityOpt,
    if (shmSize != null) 'ShmSize': shmSize,
    if (storageOpt != null) 'StorageOpt': storageOpt,
    if (sysctls != null) 'Sysctls': sysctls,
    if (tmpfs != null) 'Tmpfs': tmpfs,
    if (utsMode != null) 'UTSMode': utsMode,
    if (ulimits != null) 'Ulimits': ulimits,
    if (usernsMode != null) 'UsernsMode': usernsMode,
    if (volumeDriver != null) 'VolumeDriver': volumeDriver,
    if (volumesFrom != null) 'VolumesFrom': volumesFrom,
  };
}

/// Docker-compatible Healthcheck configuration
class CompatHealthcheck {
  final List<String>? test;
  final int? interval;
  final int? timeout;
  final int? retries;
  final int? startPeriod;

  CompatHealthcheck({
    this.test,
    this.interval,
    this.timeout,
    this.retries,
    this.startPeriod,
  });

  Map<String, dynamic> toJson() => {
    if (test != null) 'Test': test,
    if (interval != null) 'Interval': interval,
    if (timeout != null) 'Timeout': timeout,
    if (retries != null) 'Retries': retries,
    if (startPeriod != null) 'StartPeriod': startPeriod,
  };
}

/// Docker-compatible NetworkingConfig
class CompatNetworkingConfig {
  final Map<String, CompatEndpointSettings>? endpointsConfig;

  CompatNetworkingConfig({this.endpointsConfig});

  Map<String, dynamic> toJson() => {
    if (endpointsConfig != null)
      'EndpointsConfig': endpointsConfig!.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
  };
}

/// Docker-compatible EndpointSettings
class CompatEndpointSettings {
  final List<String>? aliases;
  final String? ipAddress;
  final String? ipv6Address;
  final String? macAddress;
  final List<String>? links;

  CompatEndpointSettings({
    this.aliases,
    this.ipAddress,
    this.ipv6Address,
    this.macAddress,
    this.links,
  });

  Map<String, dynamic> toJson() => {
    if (aliases != null) 'Aliases': aliases,
    if (ipAddress != null) 'IPAddress': ipAddress,
    if (ipv6Address != null) 'IPv6Address': ipv6Address,
    if (macAddress != null) 'MacAddress': macAddress,
    if (links != null) 'Links': links,
  };
}
