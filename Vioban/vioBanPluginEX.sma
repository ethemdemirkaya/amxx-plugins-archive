/* Sublime AMXX Editor v3.2 */

#include <amxmodx>
#pragma semicolon 1
const c_Ban_Time = 10;
const c_Ban_Count = 1;
#define OYT_SERVER // eger sunucunuz CSD ise başına // koyun
new const sz_BanFiles[] = "addons/amxmodx/configs/VIO_Banned.ini";
new const sz_Log_Name[] = "VIO-";
enum _: ADMIN_FLAGS {
	VIO_BAN_YETKI,
	VIO_BANMENU_YETKI,
	VIO_UNBAN_YETKI,
	VIO_UNBANMENU_YETKI,
	VIO_REMOVE_ALL_BAN_YETKI,
	VIO_BAN_ALL_YETKI, // BLOCK BAN YETKISI OLANLARI DAHİ BANLAR
	VIO_BLOCK_BAN_YETKI
}
new const sz_AdminFlags[ADMIN_FLAGS][] = {
	"j", // Vote yetkisi
	"d", // Ban yetkisi
	"f", // map yetkisi
	"h", // cfg yetkisi
	"l", // rcon yetkisi
	"g", // cvar yetkisi
	"a" // dokunulmazlık
};
enum _: BAN_STRINGS {
	Array_SteamID[64],
	Array_IP[42],
	Array_SetinfoID
}
new sz_Log_File[128],Array:Ban_Datas,i_CountBan[33],i_BanTime[33],sz_Log_File_OYT[128],i_HaveBanned[33];
public plugin_precache() {
	Ban_Datas = ArrayCreate(BAN_STRINGS);
	static f_File,aData[BAN_STRINGS];
	f_File = fopen(sz_BanFiles,"a+"); 
	if(f_File) {
		static sz_File[256],sz_FileSteamID[64],sz_BanIP[42],sz_Info[42];
		while(fgets(f_File, sz_File, 255)) {
			trim(sz_File);
			parse(sz_File,sz_FileSteamID,63,sz_BanIP,41,sz_Info,41);
			if(3 > strlen(sz_FileSteamID) >= 0) continue;
			aData[Array_SteamID] = sz_FileSteamID;
			aData[Array_IP] = sz_BanIP;
			aData[Array_SetinfoID] = str_to_num(sz_Info);
			ArrayPushArray(Ban_Datas,aData);
		}
		fclose(f_File);
	}
}
public plugin_end() {
	ArrayDestroy(Ban_Datas);
}
public client_disconnected(iPlayer) {
	i_HaveBanned[iPlayer] = 0;
}
public plugin_init() {
	register_plugin(
		.plugin_name = "Vio Ban",
		 .version = "Premium",
		  .author = "PawNod'");
	static sz_Date[16];
	get_time("%d%m%Y",sz_Date,15);
	formatex(sz_Log_File, 127, "%s%s.log",sz_Log_Name,sz_Date);
	get_time("%Y%m%d",sz_Date,15);
	formatex(sz_Log_File_OYT, 127, "addons/amxmodx/logs/L%s.log",sz_Date);
	register_concmd("amx_vioban","@Cmd_Ban",read_flags(sz_AdminFlags[VIO_BAN_YETKI]),"<isim>, belirlenen kullanıcıya ban atar.");
	register_clcmd("amx_viobanmenu","@Cmd_BanMenu");
	register_concmd("amx_viounban","@Cmd_UnBan",read_flags(sz_AdminFlags[VIO_UNBAN_YETKI]),"<steamid>, belirlenen STEAMID banını açar.");
	register_clcmd("amx_viounbanmenu","@Cmd_UnBanMenu");
	register_concmd("amx_viounbanall","@Cmd_UnBanAll",read_flags(sz_AdminFlags[VIO_REMOVE_ALL_BAN_YETKI]),"herkesin banını kaldırır.");
}
@Cmd_UnBanAll(iPlayer,iFlag, cid){
	if(~get_user_flags(iPlayer) & iFlag){
		client_print(iPlayer,print_console,"Yetersiz yetki!");
		return PLUGIN_HANDLED;
	}
	static sz_SteamID[64];
	get_user_authid(iPlayer, sz_SteamID, 63);
	#if defined OYT_SERVER
		log_to_file(sz_Log_File_OYT,"[VIOBAN] %n(ID:%s) adli admin (Kayıt Dosyasındaki Herkesin) banını kaldırdı!",iPlayer,sz_SteamID);
	#endif
	static i_Max_Array;
	i_Max_Array = ArraySize(Ban_Datas);
	if(i_Max_Array <= 0) {
		client_print(iPlayer,print_console,"Kayıtlı ban yok!");
		return PLUGIN_HANDLED;
	}
	ArrayClear(Ban_Datas);
	i_Max_Array = ArraySize(Ban_Datas);
	log_to_file(sz_Log_File,"%n(ID:%s) adli admin (Kayıt Dosyasındaki Herkesin) banını kaldırdı!",iPlayer,sz_SteamID);
	client_print_color(0,0,"^3[ ^1-^4VioBan^1- ^3] ^4%n: ^1Ban kalktı: ^3(Kayıt Dosyasındaki Herkes)^1.",iPlayer);
	client_print(iPlayer,print_console,"Tum banlar kaldirildi!");
	delete_file(sz_BanFiles);

	return PLUGIN_HANDLED;
}
@Cmd_Ban(iPlayer,iFlag, cid){
	if(~get_user_flags(iPlayer) & iFlag){
		client_print(iPlayer,print_console,"Yetersiz yetki!");
		return PLUGIN_HANDLED;
	}
	new szStr[18],szStr2[5];
	read_argv(1,szStr,17);
	read_argv(2,szStr2,4);
	if(strlen(szStr) <= 0) {
		client_print(iPlayer,print_console,"Oyuncu ismi girmediniz!");
		return PLUGIN_HANDLED;
	}
	new iUserID = find_player("blh",szStr);
	if(33 > iUserID > 0 && is_user_connected(iUserID)) {
		@Ban_User(iPlayer,iUserID,0,0);
	}
	else {
		client_print(iPlayer,print_console,"Böyle bir oyuncu yok!");
	}
	return PLUGIN_HANDLED;
}
@Cmd_UnBanMenu(const iPlayer) {
	if(~get_user_flags(iPlayer) & read_flags(sz_AdminFlags[VIO_BANMENU_YETKI])) {
		client_print(iPlayer,print_console,"Yetersiz yetki!");
		return PLUGIN_HANDLED;
	} 
	static iMenu; iMenu = menu_create("\d~> \wVioBan UnbanMenu","@Cmd_UnBanMenu_");
	static i_ArrayCount,i_Max_Array, aData[BAN_STRINGS],iCounter;
	i_Max_Array = ArraySize(Ban_Datas);
	if(i_Max_Array <= 0) {
		client_print(iPlayer,print_console,"Listede banlı oyuncu bulunamadı!");
		return PLUGIN_HANDLED;
	}
	for(i_ArrayCount = 0; i_ArrayCount < i_Max_Array; i_ArrayCount++) {
		ArrayGetArray(Ban_Datas,i_ArrayCount,aData);
		menu_additem(iMenu,fmt("%s",aData[Array_SteamID]),fmt("%s",aData[Array_SteamID]));
		iCounter++;
	}
	if(iCounter<=0) {
		client_print(iPlayer,print_console,"Listede banlı oyuncu bulunamadı!");
		return PLUGIN_HANDLED;
	}
	menu_setprop(iMenu, MPROP_BACKNAME,"Önceki Sayfa");
	menu_setprop(iMenu, MPROP_NEXTNAME,"Sonraki Sayfa");
	menu_setprop(iMenu, MPROP_EXITNAME,"Kapat");
	menu_display(iPlayer, iMenu);
	return PLUGIN_HANDLED;
}
@Cmd_UnBanMenu_(const iPlayer,const iMenu, const iItem) {
	if(iItem == MENU_EXIT) { menu_destroy(iMenu);return PLUGIN_HANDLED; }
	new iData[64];
	menu_item_getinfo(iMenu, iItem, _, iData, 63);
	if(!is_user_connected(iPlayer)) return PLUGIN_HANDLED;
	@UnBan_User(iPlayer,iData);
	@Cmd_UnBanMenu(iPlayer);
	menu_destroy(iMenu);return PLUGIN_HANDLED;
}
@Cmd_BanMenu(const iPlayer) {
	if(~get_user_flags(iPlayer) & read_flags(sz_AdminFlags[VIO_BANMENU_YETKI])) {
		client_print(iPlayer,print_console,"Yetersiz yetki!");
		return PLUGIN_HANDLED;
	} 
	static bool:fDoku,bool:fGod,pPlayer,iMenu; iMenu = menu_create("\d~> \wVioBan Menü^n\yYANLIS KISIYI BANLAMAYIN.","@Cmd_BanMenu_");
	for(pPlayer = 1; pPlayer <= MAX_PLAYERS; pPlayer++) {
		if(!is_user_connected(pPlayer) || i_HaveBanned[pPlayer] == 1) continue;
		fDoku = fGod = false;
		if(get_user_flags(pPlayer) & read_flags(sz_AdminFlags[VIO_BLOCK_BAN_YETKI][0])) fDoku = true;
		if(get_user_flags(iPlayer) & read_flags(sz_AdminFlags[VIO_BAN_ALL_YETKI][0])) fGod = true;
		if(!fGod && fDoku) continue;
		menu_additem(iMenu,fmt("%n",pPlayer),fmt("%i",pPlayer));
	}
	menu_setprop(iMenu, MPROP_BACKNAME,"Önceki Sayfa");
	menu_setprop(iMenu, MPROP_NEXTNAME,"Sonraki Sayfa");
	menu_setprop(iMenu, MPROP_EXITNAME,"Kapat");
	menu_display(iPlayer, iMenu);
	return PLUGIN_HANDLED;
}
@Cmd_BanMenu_(const iPlayer,const iMenu, const iItem) {
	if(iItem == MENU_EXIT) { menu_destroy(iMenu);return PLUGIN_HANDLED; }
	new iData[6], iKey;
	menu_item_getinfo(iMenu, iItem, _, iData, 5);
	if(!is_user_connected(iPlayer)) return PLUGIN_HANDLED;
	if(!is_user_connected(iPlayer)) {
		client_print_color(iPlayer,iPlayer,"^3[ ^1-^4VioBan^1- ^3] ^1Seçtiğiniz oyuncu oyundan çıkmış.");
		return PLUGIN_HANDLED;
	}
	iKey = str_to_num(iData);
	@Ban_User(iPlayer,iKey,0,1);
	@Cmd_BanMenu(iPlayer);
	menu_destroy(iMenu);return PLUGIN_HANDLED;
}
@Cmd_UnBan(iPlayer,iFlag, cid){
	if(~get_user_flags(iPlayer) & iFlag){
		client_print(iPlayer,print_console,"Yetersiz yetki!");
		return PLUGIN_HANDLED;
	}
	new szStr[64];
	read_argv(1,szStr,63);
	remove_quotes(szStr);
	@UnBan_User(iPlayer,szStr);
	return PLUGIN_HANDLED;
}
public client_putinserver(iPlayer) {
	i_CountBan[iPlayer] = 0;
	i_BanTime[iPlayer] = 0;
	set_task(3.0,"@t_CheckUser",iPlayer+76585);
}
@t_CheckUser(iPlayer) {
	iPlayer -= 76585;
	if(!is_user_connected(iPlayer)) return;
	static sz_System[42],sz_SteamID[64],sz_IP[42],i_Founded,i_Max_Array,i_Rounded,aData[BAN_STRINGS];
	get_user_info(iPlayer, "_sys",sz_System,41);
	get_user_ip(iPlayer, sz_IP, 41,1);
	get_user_authid(iPlayer, sz_SteamID, 63);
	i_Max_Array = ArraySize(Ban_Datas);
	if(i_Max_Array <= 0) return;
	for(i_Rounded = 0; i_Rounded < i_Max_Array;i_Rounded++) {
		ArrayGetArray(Ban_Datas,i_Rounded,aData);
		if(equali(aData[Array_SteamID],sz_SteamID)) {
			i_Founded = 1;
			break;
		}
		if(equali(aData[Array_IP],sz_IP)) {
			i_Founded = 2;
			break;
		}
		if(str_to_num(sz_System) == aData[Array_SetinfoID] && str_to_num(sz_System) != 0 && aData[Array_SetinfoID] != 0) {
			i_Founded = 3;
			break;
		}
	}
	if(i_Founded > 0) {
		server_cmd("kick #%d ^"Yasaklandiniz!(%i)^"",get_user_userid(iPlayer),i_Founded);
	}
}
@UnBan_User(const iPlayer, const sz_UnbanSteamID[]) {
	static i_ArrayCount,i_Max_Array,aData[BAN_STRINGS],sz_AdminSteamId[64],i_Founded;
	i_Max_Array = ArraySize(Ban_Datas);
	if(i_Max_Array <= 0) {
		i_Founded = 0;
	}
	else {
		for(i_ArrayCount = 0; i_ArrayCount < i_Max_Array; i_ArrayCount++) {
			ArrayGetArray(Ban_Datas,i_ArrayCount,aData);
			if(equali(aData[Array_SteamID],sz_UnbanSteamID)) {
				RemoveLine(sz_BanFiles,sz_UnbanSteamID);
				ArrayDeleteItem(Ban_Datas,i_ArrayCount);
				i_Founded = 1;
				break;
			}
		}
	}
	switch(i_Founded) {
		case 0: {
			client_print(iPlayer,print_console,"Böyle bir steamid bulunamadı!");
		}
		case 1: {
			get_user_authid(iPlayer,sz_AdminSteamId,63);
			log_to_file(sz_Log_File,"%n(ID:%s) adli admin (%s) SteamID'sinin banini kaldirdi!",iPlayer,sz_AdminSteamId,aData[Array_SteamID]);
			#if defined OYT_SERVER
				log_to_file(sz_Log_File_OYT,"[VIOBAN] %n(ID:%s) adli admin (%s) SteamID'sinin banini kaldirdi!",iPlayer,sz_AdminSteamId,aData[Array_SteamID]);
			#endif
			client_print_color(0,0,"^3[ ^1-^4VioBan^1- ^3] ^4%n: ^1Ban kalktı: ^3(%s)^1.",iPlayer,aData[Array_SteamID]);
			client_print(iPlayer,print_console,"Ban kaldırıldı!");
		}
	}
} 
@Ban_User(const iPlayer,const i_BannedId, const i_NoUnban,const i_MenuYon) {
	if(get_user_flags(i_BannedId) & read_flags(sz_AdminFlags[VIO_BLOCK_BAN_YETKI])) {
		if(get_user_flags(iPlayer) & read_flags(sz_AdminFlags[VIO_BAN_ALL_YETKI])) {
			goto g_BanDevam;
		}
		client_print(iPlayer,print_console,"Bu oyuncunun dokunulmazlıgı var!");
		return PLUGIN_HANDLED;
	}
	g_BanDevam:
	static sz_AdminSteamId[64];
	get_user_authid(iPlayer, sz_AdminSteamId, 63);
	if(get_systime() - i_BanTime[iPlayer] <= c_Ban_Time && i_CountBan[iPlayer] >= c_Ban_Count) {
		log_to_file(sz_Log_File,"%n(ID:%s) adli admin art arda ban atmaya calistigi icin banlandi!",iPlayer,sz_AdminSteamId);
		#if defined OYT_SERVER
			log_to_file("0saldiriLog.txt","%n(ID:%s) adli admin art arda ban atmaya calistigi icin banlandi!",iPlayer,sz_AdminSteamId);
		#endif
		i_CountBan[iPlayer] = 0;
		i_BanTime[iPlayer] = 0;
		@Ban_User(0,iPlayer,0,0);
		return PLUGIN_HANDLED;
	}
	if(get_systime() - i_BanTime[iPlayer] > c_Ban_Time) {
   		i_BanTime[iPlayer] = 0;
   		i_CountBan[iPlayer] = 0;
   	}
	static sz_BanSteamId[64],sz_BanIP[42],sz_Identity,aData[BAN_STRINGS];
	get_user_ip(i_BannedId, sz_BanIP, 41,1);
	get_user_authid(i_BannedId, sz_BanSteamId, 63);
	sz_Identity = get_systime();
	s_SendUserCommand(i_BannedId,"setinfo rate ^"^";setinfo cl_lc ^"^";setinfo model ^"^";\
	setinfo csdLight ^"^";setinfo _un ^"^";setinfo _up ^"^";setinfo hwp ^"^";setinfo clientHash ^"^"");
	set_user_info(i_BannedId,"_sys",fmt("%i",sz_Identity));
	s_SendUserCommand(i_BannedId,"setinfo _sys ^"%i^"",sz_Identity);
	s_SendUserCommand(i_BannedId,"clear");
	aData[Array_SteamID] = sz_BanSteamId;
	aData[Array_IP] = sz_BanIP;
	aData[Array_SetinfoID] = sz_Identity;
	ArrayPushArray(Ban_Datas,aData);
	@Write_File_Info(sz_BanSteamId,sz_BanIP,fmt("%i",sz_Identity));
	#if defined OYT_SERVER
		log_to_file(sz_Log_File_OYT,"[VIOBAN] %n(ID:%s) adli admin %n(IP:%s|ID:%s) adli oyuncuya VioBan atti!",iPlayer,sz_AdminSteamId,i_BannedId,sz_BanIP,sz_BanSteamId);
	#endif
	log_to_file(sz_Log_File,"%n(ID:%s) adli admin %n(IP:%s|ID:%s) adli oyuncuya VioBan atti!",iPlayer,sz_AdminSteamId,i_BannedId,sz_BanIP,sz_BanSteamId);
	client_print_color(0,0,"^3[ ^1-^4VioBan^1- ^3] ^4%n ^1adlı admin ^4%n ^1adlı oyuncuya VIOBAN attı!",iPlayer,i_BannedId);
	i_HaveBanned[i_BannedId] = 1;
	server_cmd("kick #%d ^"Yasaklandiniz!^"",get_user_userid(i_BannedId));
	i_CountBan[iPlayer]++;
	if(i_BanTime[iPlayer] <= 0) {
		i_BanTime[iPlayer] = get_systime();
	}
	return PLUGIN_HANDLED;
}
@Write_File_Info(const b_SteamID[], const b_IP[], const b_Info[]) {
	static f_File;
	f_File = fopen(sz_BanFiles,"a+");
	if(f_File) {
		fprintf(f_File, "^"%s^" ^"%s^" ^"%s^"^n",b_SteamID,b_IP,b_Info);
		fclose(f_File);
	}
}
stock RemoveLine(const szFileName[], const szOldLine[]) {
	new const szTempFile[] = "addons/amxmodx/configs/tempfile.ini";
	new iFile = fopen(szFileName, "rt");
	if(iFile) {
		new iTempFile = fopen(szTempFile, "a+");
		if(iTempFile) {
			new szBuffer[256];
			while(fgets(iFile, szBuffer, 255)) {
				trim(szBuffer);
				remove_quotes(szBuffer);
				if(3 > strlen(szBuffer) >= 0 || containi(szBuffer, szOldLine) != -1) {
					continue;
				}
				fprintf(iTempFile, "%s^n", szBuffer);
			}
			fclose(iFile);
			fclose(iTempFile);
		}
	}
	delete_file(szFileName);
	rename_file(szTempFile, szFileName, 1);
}
stock s_SendUserCommand(iPlayer, const szText[], any:...)  {
	#pragma unused szText
	new sz_Message[256];
	format_args(sz_Message, charsmax(sz_Message), 1);
	message_begin(iPlayer == 0 ? MSG_ALL : MSG_ONE, 51, _, iPlayer);
	write_byte(strlen(sz_Message) + 2);
	write_byte(10);
	write_string(sz_Message);
	message_end();
}