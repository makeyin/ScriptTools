GenesisTimestamp = 0
ValidateBlockNoCacheHeight = 0

[API]
  ListenAddress = "/ip4/{{ ansible_default_ipv4['address'] }}/tcp/1234/http"
  RemoteListenAddress = "{{ ansible_default_ipv4['address'] }}:1234"
  Timeout = "30s"

[Libp2p]
  ListenPort = 6000
  AnnounceAddresses = []
  NoAnnounceAddresses = []
  BootstrapPeers = []
  ProtectedPeers = []
  ConnMgrLow = 150
  ConnMgrHigh = 200
  ConnMgrGrace = "20s"

[Relation]
  GroupName = "group_name"
  EnableDtUseHttp = true
  EnableOnlyStoreClusterPoSt = false
  FullNodeToken = ""
  WinningNodeToken = ""
  WindowNodeToken = ""
  WindowNodeTokenExt1 = ""
  WindowMoreNodeToken = ""
  WindowMoreNodeTokenExt1 = ""
  OSPNodeToken = ""

[Pubsub]
  Bootstrapper = false
  RemoteTracer = ""

[BackUp]
  BathPath = "/tank1/badger_bak"
  Prefix = "lotus"
  Interval = "30m"
  MaxBackups = 7

[Client]
  UseIpfs = false
  IpfsOnlineMode = false
  IpfsMAddr = ""
  IpfsUseForRetrieval = false
  SimultaneousTransfers = 20

[Metrics]
  Nickname = ""
  HeadNotifs = true

[Wallet]
  EnableLedger = false
  DisableLocal = false

[Fees]
  DefaultMaxFee = "0.7 FIL"

[MpoolConfig]
  ViperAddrs = [" {{control-0}} "]
  SizeLimitHigh = 30000
  SizeLimitLow = 20000
  ReplaceByFeeRatio = 1.25
  PruneCooldown = 60000000000
  GasLimitOverestimation = 1.15
  MaxGasLimitOverestimationValue = 10000000.0
  MinGasLimitOverestimationValue = 1000000.0
  MaxCommitCount = 32
  MaxPrecommitCount = 64
  [MpoolConfig.FeeOver]
    FeeCapOver = 8
    PreFeeOver = 2
    ProvenFeeOver = 2
    WDPostFeeOver = 3
    DealFeeOver = 2
    Other = 2

[Mining]
  CfgForkHeight = 0
  BlockBlacklist = []
  BlockWhitelist = []
  IgnoreBlockWithBlackMsg = false
  MessageBlacklist = []
  MessageWhitelist = []
  BootLoadLocalMessage = true
  CancelBadByWeightBlocks = 0
  RelayBadBlock = false
  AllowableClockDrift = "1s"
  SyncEarlyDelta = "0s"
  IgnoreMinerCheck = ["{{ minerID }}"]

[FeeOver]
  PreFeeOver = 5000
  ProvenFeeOver = 5000
  WDPostFeeOver = 10000
  DealFeeOver = 5000
  Other = 1000

[Prometheus]
  PrometheusEnabled = true
  Namespace = ""
  ReportInterval = "5s"
  PrometheusEndpoint = "/ip4/0.0.0.0/tcp/19401"
