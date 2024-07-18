class Api {
  // Config
  static const String configApi = 'https://gtglobal.com.vn/config6789.php';

  // Host URL
  static String hostApi = 'https://api6789.web5sao.net';

  // Authentication & User Fetch URL
  static const String login = '/home/login';
  static String getCustomer = '/home/GetInfoCustomer_ById';
  static String getCustomerByEmail = '/home/GetInfoCustomer_ByEmail';
  static String getCustomerByDevice = '/home/GetListCustomer_Bysericomputer';

  // Packet URL
  static String getPacketByCustomerId = '/home/GetPacket_ByCustomerId';

  // Device URL
  static String createDevice = '/home/CreateDevice';
  static String getDeviceByCustomerId = '/home/GetDevices_ByCustomerId';

  // Campaign URL
  static String getTimeRunByCampId = '/home/GetTimeRun_ByCampId';
  static String getCampByDevice = '/home/Getcamp_ByComputerId';
  static String getAllRunTimeOfComputer = '/home/GetAllRunTimeOfComputer_4';
  static String addCampaignRunProfile = '/home/AddCampaignRunProfile';

  // Notification URL
  static String insertNotify = '/home/InsertNotify';

  // Command URL
  static String replyCommand = '/home/ReplyCommand';

  // Firebase
  static const String updateDeviceFirebaseToken = '/home/UpdateComputerToken_ById';
}
