class Api {
  // Config
  static const String configApi = 'https://gtglobal.com.vn/config6789.php';

  // Host URL
  static String hostApi = 'https://api6789.web5sao.net';

  // Authentication & User Fetch URL
  static const String login = '/home/login';
  static const String getCustomer = '/home/GetInfoCustomer_ById';
  static const String getCustomerByEmail = '/home/GetInfoCustomer_ByEmail';
  static const String getCustomerByDevice =
      '/home/GetListCustomer_Bysericomputer';

  // Packet URL
  static const String getPacketByCustomerId = '/home/GetPacket_ByCustomerId';

  // Device URL
  static const String createDevice = '/home/CreateDevice';
  static const String getDeviceByCustomerId = '/home/GetDevices_ByCustomerId';
  static const String updateDevice = '/home/UpDateDevice_ById';

  //Dir
  static const String getCustomerDir = '/home/GetDirCustomer_ById';
  static const String getShareDir = '/home/GetDirCustomer_SharedById';

  // Campaign URL
  static const String getTimeRunByCampId = '/home/GetTimeRun_ByCampId';
  static const String getCampByDevice = '/home/Getcamp_ByComputerId';
  static const String getAllRunTimeOfComputer =
      '/home/GetAllRunTimeOfComputer_4';
  static const String addCampaignRunProfile = '/home/AddCampaignRunProfile';
  static const String getCampTodayByComputerId =
      '/home/GetCampToday_ByComputerId';
  static const String getCampaignByDirectoryId = '/home/Getcamp_ByDirId';

  // Notification URL
  static const String insertNotify = '/home/InsertNotify';

  // Command URL
  static const String replyCommand = '/home/ReplyCommand';

  // Firebase
  static const String updateDeviceFirebaseToken =
      '/home/UpdateComputerToken_ById';
}
