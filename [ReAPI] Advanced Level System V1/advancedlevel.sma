/* Sublime AMXX Editor v3.2 */

#include <amxmodx>
#include <reapi>
#include <regex>

native nvault_open(const name[]);
native nvault_close(vault);
native nvault_get(vault, const key[], any:...);
native nvault_set(vault, const key[], const value[]);

#pragma semicolon 1
new const sChatSay[] = "^x01{DEAD}^x03[^x04{LEVEL}^x03] ^x03{NAME}^x01: {FLAG}{MESSAGE}";
new const ChatTag[] = "^1[ ^3- ^4Advanced Level System ^3- ^1]";
new const sLevelSystem[][][] = {
	{"Level 1",100},
	{"Level 2",200},
	{"Level 3",300},
	{"Level 4",400},
	{"Level 5",500},
	{"Level 6",600},
	{"Level 7",700},
	{"Level 8",800},
	{"Level 9",900},
	{"Level 10",1000}
};
enum _: Variables {
	Exp,
	Level,
	bool:Spamming
}
new Vars[MAX_PLAYERS+1][Variables],iCvars[5],iSayText,iTeamInfo,iVault;
public plugin_natives() {
	register_native("ALS_GetUserExp","@ALS_GUEX");
	register_native("ALS_SetUserExp","@ALS_SUEX");
	register_native("ALS_GetUserLevel","@ALS_GULV");
	register_native("ALS_SetUserLevel","@ALS_SULV");
	register_native("ALS_GetMaxLevel","@ALS_GMLV");
}
@ALS_GUEX() {
	new nPlayerID = get_param(1);
	return Vars[nPlayerID][Exp];
}
@ALS_SUEX() {
	new nPlayerID = get_param(1), nAmount = get_param(2);
	if(nAmount >= sLevelSystem[(sizeof(sLevelSystem)-1)][1][0]) {
		Vars[nPlayerID][Level] = (sizeof(sLevelSystem)-1);
		Vars[nPlayerID][Exp] = sLevelSystem[(sizeof(sLevelSystem)-1)][1][0];
	}
	else {
		Vars[nPlayerID][Exp] = nAmount;
		for(new i=0; i < sizeof(sLevelSystem); i++) {
			if(nAmount >= sLevelSystem[i][1][0]) {
				Vars[nPlayerID][Exp] = i;
				break;
			}
		}
	}
	return PLUGIN_CONTINUE;
}
@ALS_GULV() {
	new nPlayerID = get_param(1);
	return Vars[nPlayerID][Level];
}
@ALS_SULV() {
	new nPlayerID = get_param(1), nAmount = get_param(2);
	if(nAmount >= (sizeof(sLevelSystem)-1)) {
		Vars[nPlayerID][Level] = (sizeof(sLevelSystem)-1);
		Vars[nPlayerID][Exp] = sLevelSystem[(sizeof(sLevelSystem)-1)][1][0];
	}
	else {
		Vars[nPlayerID][Exp] = sLevelSystem[nAmount][1][0];
		Vars[nPlayerID][Level] = nAmount;
	}
	return PLUGIN_CONTINUE;
}
@ALS_GMLV() {
	return (sizeof(sLevelSystem)-1);
}
public plugin_cfg() 
	iVault = nvault_open("ALS_V1");
public plugin_end() 
	nvault_close(iVault);
public plugin_init() {
	register_plugin("Advanced Level System", "1.0", "PawNod'");

	register_concmd("amx_give_level","@GiveLevel",ADMIN_RCON,"<isim> <miktar>, belirlenen kisiye level verir");
	register_clcmd("say","@HookSay");

	RegisterHookChain(RG_CBasePlayer_Killed, "@IsKilled", .post = true);
	
	iSayText = get_user_msgid("SayText");
	iTeamInfo = get_user_msgid("TeamInfo");

	Cvars();
}
Cvars() {
	bind_pcvar_num(create_cvar("ALS_Give_Exp","50"),iCvars[0]); // Bu değeri 0 yaparsanız ALS_Give_Max_Exp ve ALS_Give_Min_Exp değerleri arasından rastgele exp verecektir.
	bind_pcvar_num(create_cvar("ALS_Give_Min_Exp","20"),iCvars[1]);
	bind_pcvar_num(create_cvar("ALS_Give_Max_Exp","70"),iCvars[2]);
	bind_pcvar_num(create_cvar("ALS_Chat","1"),iCvars[3]); // Eklentinin Chat'ini Açıp Kapatmaya Yarar.
	bind_pcvar_num(create_cvar("ALS_Chat_Messages","0"),iCvars[4]); // Oyuncuların chat'e mesaj göndermesini engeller. 1:0 (Say -> Kapalı:Açık)
}
@GiveLevel(const iPlayer,const iLVL, const iCid){
	if(~get_user_flags(iPlayer) & iLVL)
		return PLUGIN_HANDLED;
	new iStringName[18],iStringAmount[18];
	read_argv(1,iStringName,17);
	read_argv(2,iStringAmount,17);
	if(iStringName[0] == '@') {
		new iPlayers[32], iPlayerNum, iPlayerad, iAmmount = str_to_num(iStringAmount);
		switch(iStringName[1]) {
			case 't', 'T':{
				get_players(iPlayers, iPlayerNum, "ae", "TERRORIST");
				client_print_color(0, 0, "^4[ ^3%n ^4] ^1adli admin ^4[ ^3Zombiler ^4] ^1'e ^4[ ^3%i Level ^4] ^1verdi^4.",iPlayer,iAmmount);
			}
			case 'c', 'C':{
				get_players(iPlayers, iPlayerNum, "ae", "CT");
				client_print_color(0, 0, "^4[ ^3%n ^4] ^1adli admin ^4[ ^3Insanlar ^4] ^1'a ^4[ ^3%i Level ^4] ^1verdi^4.",iPlayer,iAmmount);
			}
			case 'a', 'A':{
				get_players(iPlayers, iPlayerNum, "a");
				client_print_color(0, 0, "^4[ ^3%n ^4] ^1adli admin ^4[ ^3Herkes ^4] ^1'e ^4[ ^3%i Level ^4] ^1verdi^4.",iPlayer,iAmmount);
			}
			default: {
				get_players(iPlayers, iPlayerNum, "a");
				client_print_color(0, 0, "^4[ ^3%n ^4] ^1adli admin ^4[ ^3Herkes ^4] ^1'e ^4[ ^3%i Level ^4] ^1verdi^4.",iPlayer,iAmmount);
			}
		}
		for(new i = 0; i < iPlayerNum; i++) {
			iPlayerad = iPlayers[i];
			if(Vars[iPlayerad][Level]+iAmmount >= (sizeof(sLevelSystem)-1) ) {
				Vars[iPlayerad][Level] = (sizeof(sLevelSystem)-1);
				Vars[iPlayerad][Exp] = sLevelSystem[(sizeof(sLevelSystem)-1)][1][0];
			}
			else {
				Vars[iPlayerad][Exp] = sLevelSystem[Vars[iPlayerad][Level]+iAmmount][1][0];
				Vars[iPlayerad][Level] += iAmmount;
			}
		}
		return PLUGIN_HANDLED;
	}
	new iAmmount,iUID = find_player("bl",iStringName);
	iAmmount = str_to_num(iStringAmount);
	client_print_color(0, 0, "^4[ ^3%n ^4] ^1adli admin ^4[ ^3%n ^4] ^1adli kisiye ^4[ ^3%i Level ^4] ^1verdi^4.",iPlayer,iUID,iAmmount);
	if(Vars[iUID][Level]+iAmmount >= (sizeof(sLevelSystem)-1) ) {
		Vars[iUID][Level] = (sizeof(sLevelSystem)-1);
		Vars[iUID][Exp] = sLevelSystem[(sizeof(sLevelSystem)-1)][1][0];
	}
	else {
		Vars[iUID][Exp] = sLevelSystem[Vars[iUID][Level]+iAmmount][1][0];
		Vars[iUID][Level] += iAmmount;
	}
	return PLUGIN_HANDLED;
}
@HookSay(const iPlayer) {
	new iMessage[312];
	read_args(iMessage, charsmax(iMessage));
	remove_quotes(iMessage);
	if(!iCvars[3]) 
		return PLUGIN_CONTINUE;
	if(iMessage[0] == '@' || iMessage[0] == '.' || iMessage[0] == '/' || iMessage[0] == '!' || equal(iMessage, ""))
   		return PLUGIN_CONTINUE;
   	if(iCvars[4]) {
		client_print_color(iPlayer,iPlayer,"%s ^1Yönetici chat'i kapattigi icin mesaj gönderemezsiniz.",ChatTag);
   		return PLUGIN_HANDLED;
	}
   	if(strlen(iMessage) > 64) {
   		client_print_color(iPlayer,iPlayer,"%s ^1Yazdiginiz mesaj 64 karakterden fazla oldugu icin ^3yayimlayamadik^1!",ChatTag);
   		return PLUGIN_HANDLED;
   	}
   	if(Vars[iPlayer][Spamming]) {
   		client_print_color(iPlayer,iPlayer,"%s ^1Spam yapmaya calistiginiz icin engellendiniz!",ChatTag);
   		return PLUGIN_HANDLED;
   	}
   	new ret,szError[128],iResult,Regex:iSayCheck;
	iSayCheck = regex_compile("[0-9]", ret, szError, charsmax(szError));
	iResult = regex_match_all_c(iMessage, iSayCheck, ret);
	regex_free(iSayCheck);
   	if(iResult > 5) {
   		client_print_color(iPlayer, iPlayer, "%s ^1Reklam yapmaya calistiginiz icin engellendiniz.",ChatTag);
   		return PLUGIN_HANDLED;
	}
	new sNewData[128],iColor[10];
	copy(sNewData,charsmax(sNewData),sChatSay);
	get_user_team(iPlayer, iColor, charsmax(iColor));

	is_user_alive(iPlayer) ? (replace_all(sNewData,charsmax(sNewData),"{DEAD}","")):(replace_all(sNewData,charsmax(sNewData),"{DEAD}","(x) "));
	(get_user_flags(iPlayer) & ADMIN_RESERVATION) ? replace_all(sNewData,charsmax(sNewData),"{FLAG}","^x04"):replace_all(sNewData,charsmax(sNewData),"{FLAG}","^x01");
	replace_all(sNewData,charsmax(sNewData),"{LEVEL}",sLevelSystem[Vars[iPlayer][Level]][0][0]);
	replace_all(sNewData,charsmax(sNewData),"{MESSAGE}",iMessage);
	replace_all(sNewData,charsmax(sNewData),"{NAME}",fmt("%n",iPlayer));
	@sendMessage(iColor, is_user_alive(iPlayer) ? 1:0, sNewData);
	Vars[iPlayer][Spamming] = true;
	set_task(3.0,"@SpamSifirla",iPlayer+77734);
	return PLUGIN_HANDLED;
}
@SpamSifirla(iPlayer) { 
	iPlayer -= 77734;
	Vars[iPlayer][Spamming] = false;
}
@IsKilled(const iVictim, const iAttacker){
	if(!is_user_connected(iAttacker) || iVictim == iAttacker) return;
	if(LevelChecker(iAttacker,false,(iCvars[0] == 0) ? random_num(iCvars[1],iCvars[2]): iCvars[0])) {
		(iCvars[0] == 0) ? (Vars[iAttacker][Exp] += random_num(iCvars[1],iCvars[2])): (Vars[iAttacker][Exp] += iCvars[0]);
		new sSteamID[33];
		get_user_authid(iAttacker, sSteamID, 32);
		sSetIntData("%s>Exp",Vars[iAttacker][Exp],sSteamID);
	}
	if(LevelChecker(iAttacker,true,0))
		@LevelUp(iAttacker);
}
@LevelUp(const iPlayer) {
	Vars[iPlayer][Level]++;
	client_print_color(iPlayer,iPlayer,"%s ^1Basarili bir sekilde ^4Level Atladiniz^1!",ChatTag);
	new sSteamID[33];
	get_user_authid(iPlayer, sSteamID, 32);
	sSetIntData("%s>Level",Vars[iPlayer][Level],sSteamID);
}
public client_putinserver(iPlayer) {
	new sSteamID[33];
	get_user_authid(iPlayer, sSteamID, 32);
	Vars[iPlayer][Exp] = sGetIntData("%s>Exp",sSteamID);
	Vars[iPlayer][Level] = sGetIntData("%s>Level",sSteamID);
}
public client_disconnected(iPlayer) {
	remove_task(iPlayer+77734);
}
bool:LevelChecker(const iPlayer, const bool:IsExp, const iExpAmout) {
	new iMaxExp,iMaxLevel;
	iMaxLevel = (sizeof(sLevelSystem)-1);
	iMaxExp = sLevelSystem[iMaxLevel][1][0];
	if(IsExp){
		if(Vars[iPlayer][Exp] >= iMaxExp) {
			Vars[iPlayer][Level] = iMaxLevel;
			return false;
		}
		if(Vars[iPlayer][Exp] < sLevelSystem[Vars[iPlayer][Level]+1][1][0]) 
			return false;
		if(Vars[iPlayer][Level] >= iMaxLevel) {
			Vars[iPlayer][Level] = iMaxLevel;
			return false;
		}
	}
	else {
		if(Vars[iPlayer][Exp] + iExpAmout >= iMaxExp) {
			Vars[iPlayer][Exp] = iMaxExp;
			return false;
		}
	}
	return true;
}
@sendMessage(const color[], const alive, const message[]) {
    new teamName[10];
    for(new player = 1; player <= MaxClients; player++){
        if(!is_user_connected(player))
            continue;
        if(alive && is_user_alive(player) || !alive && !is_user_alive(player) || get_user_flags(player) & ADMIN_LEVEL_C){
            get_user_team(player, teamName, 9);
            @changeTeamInfo(player, color);
            @writeMessage(player, message);
            @changeTeamInfo(player, teamName);
        }
    }
}
@changeTeamInfo(const player, const team[]) {
    message_begin(MSG_ONE, iTeamInfo, _, player); 
    write_byte(player);                
    write_string(team);                
    message_end();                   
}
@writeMessage(const player, const message[]) {
    message_begin(MSG_ONE, iSayText, {0, 0, 0}, player);    
    write_byte(player);                   
    write_string(message);                    
    message_end();                        
}  
stock sGetIntData(const sKey[],any:...){
	new sFixedData[128];
	vformat(sFixedData,127,sKey,2);
	return nvault_get(iVault,sFixedData);
}
stock sSetIntData(const sKey[],const iData,any:...){
	new sFixedData[128],sNTS[48];
	vformat(sFixedData,127,sKey,3);
	num_to_str(iData,sNTS,47);
	nvault_set(iVault,sFixedData,sNTS);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1055\\ f0\\ fs16 \n\\ par }
*/
