class Api {
  static String hostApi = 'https://api6789.web5sao.net';
  static String login = '/home/login';
  static String signUp = '/home/register';
  static String getCustomer = '/home/GetInfoCustomer_ById';
  static String getAllPacket = '/home/GetAllPacket';
  static String getPacketByID = '/home/GetPacket_ById';
  static String buyPacketByIdCustomer = '/home/BuyPacket_ByIdCustomer';
  static String getAllDir = '/home/GetShareDir_ByCustomerId/%5bcustomer_idfrom';
  static String getCustomerDir =
      '/home/GetDirCustomer_ById'; //Lấy Danh Sách thư mục của khách hàng tạo ra
  static String getShareDir = '/home/GetDirCustomer_SharedById';
  static String createDir = '/home/CreateDir';
  static String updateDir = '/home/UpDateDir_ById';
  static String deleteDir = '/home/DeleteDir_ById';
  static String getDevices = '/home/GetSharedDevices_ByCustomerId';
  static String createDevice = '/home/CreateDevice';
  static String getDeviceByIdDir = '/home/GetDevice_ByIdDir';
  static String getShareCamp = '/home/GetShareCamp_ByCustomerId';
  static String getCampSharedByIdCustomer = '/home/GetCamp_SharedByCustomerId';
  static String updateDevice = '/home/UpDateDevice_ById';
  static String deleteDevice = '/home/DeleteDevice_ById';
  static String changePassword = '/home/changepass';
  static String getCampByIdCustomer = '/home/GetCamp_ById';
  static String getAllCampByIdCustomer = '/home/GetAllCamp_ById';
  static String createCamp = '/home/CreateCamp';
  static String updateCampById = '/home/UpdateCamp_ById';
  static String deleteCampById = '/home/DeleteCamp_ById';
  static String getTimeRunByCampId = '/home/GetTimeRun_ByCampId';
  static String addTimeRunByCampaignId = '/home/AddTimeRun_ByCamp';
  static String deleteTimRunByIdRun = '/home/DeleteTimeRun_ByIdRun';
  static String sendCode = '/home/SendCode';
  static String resetPassword = '/home/resetpass';
  static String updateCustomer = '/home/UpdateInfoCustomer_ById';
  static String updateTimeRunByIdRun = '/home/UpdateTimeRun_ByIdRun';
  static String getDeviceOfCampByCampId = '/home/GetListDeviceOfCamp_ByCampId';
  static String getCustomerByEmail = '/home/GetInfoCustomer_ByEmail';
  static String shareDir = '/home/InsertDirShare';
  static String getSharedCustomerListByDirId =
      '/home/GetSharedCustomerList_ByDirID';
  static String getCampByDevice = '/home/Getcamp_ByComputerId';
  static String getAllRunTimeOfComputer = '/home/GetAllRunTimeOfComputer_1';
  static String getCustomerByDevice = '/home/GetListCustomer_Bysericomputer';
  static String getDeviceByCustomerId = '/home/GetDevices_ByCustomerId';
  static String getCampBySeriComputer = '/home/GetCamp_BySeriComputer';
  static String GetCampBySeriComputerAndCustomerID = '/home/GetCamp_BySeriComputerAndCustomerID';
}
