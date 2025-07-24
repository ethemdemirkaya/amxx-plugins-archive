/* Sublime AMXX Editor v3.2 */

#pragma dynamic 32768

#include <amxmodx>
#include <reapi>

native set_pdata_int(_index, _Offset, _Value, _linuxdiff = 5, _macdiff = 5);
native register_touch(const Touched[], const Toucher[], const function[]);
native set_lights(const Lighting[]);

#define BAHISLI_LR // Bu satırı silerseniz bahisli lr olmayacaktır.

#if defined BAHISLI_LR
#include <jail>
#endif

new const sFileOrigin[] = "addons/amxmodx/configs/LRPre_MapCoord.ini";

enum _: AllTags {
	ChatTag,
	LongTag,
	ShortTag
}
new const sTags[AllTags][] = {
	"^1[ ^3- ^4WebAilesi ^3- ^1]",
	"WebAilesi",
	"wA"
};
new const sWeapons[][][] = {
	{"DEAGLE", "weapon_deagle", CSW_DEAGLE},
	{"USP", "weapon_usp", CSW_USP},
	{"AWP", "weapon_awp", CSW_AWP},
	{"SCOUT", "weapon_scout", CSW_SCOUT},
	{"AUG", "weapon_aug", CSW_AUG},
	{"AK47", "weapon_ak47", CSW_AK47},
	{"M4A1", "weapon_m4a1", CSW_M4A1},
	{"MP5", "weapon_mp5navy", CSW_MP5NAVY}
};
new const sCvarSettings[][][] = {
	{"LR_Bunny","1"}, // LR'de bunny açık olup olmayacağını belirler. [1: Bunny Kapatır | 0: Bunny Kapatmaz]
	{"LR_Sureli","1"}, // LR'nin süreli olup olmayacağını belirler. [1: Açık | 0: Kapalı]
	{"LR_Suresi","60"}, // LR süresini belirler.
	{"LR_Kalan_Can","1"}, // LR'de Kalan canı gösterir. [1: Açık | 0: Kapalı]
	{"LR_Efektleri","3"}, // 0: Kapalı,1: Glow, 2: Glow + Daire, 3: Glow + Daire + Çizgi , 4: Glow + Çizgi , 5: Daire
	{"LR_Efekt_Renk","1"}, // Efektlerin rengini ayarlar. [1: Renkli, 0: Beyaz]
	{"LR_Otomatik","1"}, // Sona tek mahkum kalınca otomatik /lr yazdırır. [1: Açık | 0: Kapalı]
	{"LR_Kill_Effect","1"}, // Lr'de Ölüm Efekti [0: Kapalı | 1: Açık] 
	{"LR_Out_Damage","1"},  // Dışardan LR Atanlar hariç hasar almayı vermeyi engeller. [1: Engeller | 0: Kapalı]
	{"LR_Sound_Effect","1"}, // LR'de Ses ve kan efektini düzenler. [1: Açık | 0: Kapalı]
	{"LR_Max_Bahis","50"} // Bahiste Max Kac TL yatirilacagini belirtir.
};
new const sLRMusic[][] = {
	"prelr.wav"
};
enum (+= 5000) {
	TASK_UNFREEZE = 17400,
	TASK_COUNTDOWN,
	TASK_STPSOUND,
	TASK_PLAYSOUND,
	TASK_CEFFECT,
	TASK_UEFFECT,
	TASK_COUNTDOWN2,
	TASK_BAHISBITIR
}
enum _: Normal {
	DuelMode,
	bool:DuelPlaying,
	BahisTL,
	bool:MenuChoose,
	BahisType,
	BahisChoosed
}
enum _: Global {
	bool:DuelActive,
	DuelModeGlobal,
	iCTID,
	iTID,
	iDuelSayac,
	SyncObjs,
	Beam,
	iCountDown,
	bool:BahisFinish
}
new Array:MapNames,Array:aOriginsT,Array:aOriginsCT,varNormal[MAX_PLAYERS+1][Normal],varGlobal[Global],iOldCvars[2],iCvars[sizeof(sCvarSettings)+1],iSizeOfs[3],
iOriginT[3][32],iOriginCT[3][32],Float:mCoordT[3],Float:mCoordCT[3];

public plugin_init() {
	register_plugin("Last Request", "v:Premium", "PawNod',suriyelikene");

	register_message(get_user_msgid("AmmoX"), "@AmmoFIX");
	register_touch("weaponbox", "player", "@TouchingWP");
	register_touch("armoury_entity", "player", "@TouchingWP");
	register_touch("weapon_shield", "player", "@TouchingWP");
	new const sRegisterMessage[][] = {"say /lr","say !lr","say .lr","say /vs","say !vs","say .vs"};
	for(new i; i < sizeof(sRegisterMessage); i++)
	register_clcmd(sRegisterMessage[i][0], "@DuelMenu");
	#if defined BAHISLI_LR
	register_clcmd("say /bahis","@GlobalBahis");
	register_clcmd("Bahis_Miktari_Giriniz","@ReadAmmount");
	#endif
	register_clcmd("amx_lr_koordinatmenu","@CoordMenu");
	RegisterHookChain(RG_CBasePlayer_Killed,"@WhoKilled",.post = true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage,"@TakeDamage",.post = false);
	RegisterHookChain(RG_RoundEnd,"@ResetLR",.post = true);
	RegisterHookChain(RG_CSGameRules_RestartRound, "@RoundStart",.post=false);
	varGlobal[SyncObjs] = CreateHudSyncObj();
	Cvars();
}
FileCheck() {
	new szMapNameI[32],iLineOF;
	get_mapname(szMapNameI, charsmax(szMapNameI));
	iLineOF = sMapCheck(szMapNameI);
	if(iLineOF == -1) return;
	new sCTCoords[32],sTCoords[32];
	ArrayGetString(aOriginsT, iLineOF, sTCoords, charsmax(sTCoords));
	ArrayGetString(aOriginsCT, iLineOF, sCTCoords, charsmax(sCTCoords));
	parse(sTCoords, iOriginT[0],31,iOriginT[1],31,iOriginT[2],31);
	parse(sCTCoords, iOriginCT[0],31,iOriginCT[1],31,iOriginCT[2],31);
}
Cvars() {
	iOldCvars[0] = get_cvar_pointer("bh_enabled");
	iOldCvars[1] = get_cvar_pointer("mp_infinite_ammo");
	for(new i=0; i < iSizeOfs[2];i++) 
	bind_pcvar_num(create_cvar(sCvarSettings[i][0][0],sCvarSettings[i][1][0]),iCvars[i]);
}
@TakeDamage(const iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageType) {
	if(!is_user_connected(iAttacker) || !is_user_connected(iVictim) || !rg_is_player_can_takedamage(iVictim, iAttacker) || iVictim == iAttacker) return HC_CONTINUE;
	if(!varNormal[iAttacker][DuelPlaying] && varGlobal[DuelActive] && iCvars[8]) {
		SetHookChainArg(4, ATYPE_FLOAT, 0.0);
		return HC_SUPERCEDE;
	}
	if(!varNormal[iVictim][DuelPlaying] && varGlobal[DuelActive] && iCvars[8]) {
		SetHookChainArg(4, ATYPE_FLOAT, 0.0);
		return HC_SUPERCEDE;
	}
	return HC_CONTINUE;
}
@RoundStart(){
	set_pcvar_num(iOldCvars[0],1);
}
@ResetLR(WinStatus:WIN_STATUSWho) {
	remove_task(TASK_COUNTDOWN),remove_task(TASK_COUNTDOWN2),remove_task(TASK_PLAYSOUND),remove_task(TASK_CEFFECT);
	remove_task(TASK_UEFFECT);
	varGlobal[BahisFinish] = true;
	set_lights("l");
	@StopSound();
	if(!is_user_connected(varGlobal[iTID]) || !is_user_connected(varGlobal[iCTID])) return;
	RGSetUserGlow(varGlobal[iCTID],0,0,0),RGSetUserGlow(varGlobal[iTID],0,0,0);
	varGlobal[DuelActive] = varNormal[varGlobal[iCTID]][DuelPlaying] = varNormal[varGlobal[iTID]][DuelPlaying] = false;
	#if defined BAHISLI_LR
	switch(WIN_STATUSWho) {
		case WINSTATUS_CTS: {
			if(varNormal[varGlobal[iTID]][BahisTL] > 0) {
				client_print_color(0, 0, "%s ^3(%n) ^1Adli Kisi Yatirdigi Parayi Kaybetti!",sTags[ChatTag],varGlobal[iTID]);
				jb_set_user_packs(varGlobal[iTID], jb_get_user_packs(varGlobal[iTID]) - varNormal[varGlobal[iTID]][BahisTL]);
				varNormal[varGlobal[iTID]][BahisTL] = 0;
			}
			for(new iBahis = 1; iBahis <= MaxClients;iBahis++ ) {
				if(is_user_connected(iBahis)) {
					switch(varNormal[iBahis][BahisChoosed]) {
						case 1: {
							client_print_color(iBahis,iBahis, "%s ^1Bahisi ^4Kazandiniz^1. ^1Kazanciniz: ^4(%i) TL",sTags[ChatTag],varNormal[iBahis][BahisTL]);
							jb_set_user_packs(iBahis, jb_get_user_packs(iBahis) + varNormal[iBahis][BahisTL]);
							varNormal[iBahis][BahisTL] = 0; 
							varNormal[iBahis][BahisChoosed] = 0;
							continue;
						}
						case 2: {
							client_print_color(iBahis,iBahis, "%s ^1Bahisi ^4Kaybettiniz^1. ^1Kaybiniz: ^4(%i) TL",sTags[ChatTag],varNormal[iBahis][BahisTL]);
							jb_set_user_packs(iBahis, jb_get_user_packs(iBahis) - varNormal[iBahis][BahisTL]);
							varNormal[iBahis][BahisTL] = 0;
							varNormal[iBahis][BahisChoosed] = 0;
							continue;
						}
					}
				}
			}
		}
		case WINSTATUS_TERRORISTS: {
			if(varNormal[varGlobal[iTID]][BahisTL] > 0) {
				client_print_color(0, 0, "%s ^3(%n) ^1Adli Kisi Yatirdigi Paranin ^4(2) Katini ^1Kazandi!",sTags[ChatTag],varGlobal[iTID]);
				jb_set_user_packs(varGlobal[iTID], jb_get_user_packs(varGlobal[iTID]) + varNormal[varGlobal[iTID]][BahisTL]);
				varNormal[varGlobal[iTID]][BahisTL] = 0;
			}
			for(new iBahis = 1; iBahis <= MaxClients;iBahis++ ) {
				if(is_user_connected(iBahis)) {
					switch(varNormal[iBahis][BahisChoosed]) {
						case 1: {
							client_print_color(iBahis,iBahis, "%s ^1Bahisi ^4Kaybettiniz^1. ^1Kaybiniz: ^4(%i) TL",sTags[ChatTag],varNormal[iBahis][BahisTL]);
							jb_set_user_packs(iBahis, jb_get_user_packs(iBahis) - varNormal[iBahis][BahisTL]);
							varNormal[iBahis][BahisTL] = 0;
							varNormal[iBahis][BahisChoosed] = 0;
							continue;
						}
						case 2: {
							client_print_color(iBahis,iBahis, "%s ^1Bahisi ^4Kazandiniz^1. ^1Kazanciniz: ^4(%i) TL",sTags[ChatTag],varNormal[iBahis][BahisTL]);
							jb_set_user_packs(iBahis, jb_get_user_packs(iBahis) + varNormal[iBahis][BahisTL]);
							varNormal[iBahis][BahisTL] = 0; 
							varNormal[iBahis][BahisChoosed] = 0;
							continue;
						}
					}
				}
			}
		}
	}
	#endif
	varGlobal[DuelModeGlobal] = -1;
}
@WhoKilled(const iVictim, const iKiller) {
	if(iVictim == iKiller) return;
	if(!is_user_connected(iKiller) || !is_user_connected(iVictim)) return;
	static iTEROR,iCITI;
	rg_initialize_player_counts(iTEROR,iCITI);
	if(iTEROR == 1 && iCITI > 0) {
		varGlobal[BahisFinish] = false;
		for(new iSor=1; iSor <= MaxClients; iSor++){
			if(is_user_connected(iSor)) {
				if(iCvars[6] && is_user_alive(iSor) && get_member(iSor, m_iTeam) == TEAM_TERRORIST) {
					@DuelMenu(iSor);
				}
			}
		}
		set_task(13.0,"@BahsiBitir",TASK_BAHISBITIR);
	}
	if(!(varNormal[iKiller][DuelPlaying]) || !(varNormal[iVictim][DuelPlaying]) || !(varGlobal[DuelActive])) return;
	remove_task(TASK_COUNTDOWN),remove_task(TASK_COUNTDOWN2),remove_task(TASK_PLAYSOUND),remove_task(TASK_CEFFECT);
	remove_task(TASK_UEFFECT);
	varGlobal[iCTID] = varGlobal[iTID] = 0;
	set_lights("l");
	varGlobal[DuelActive] = varNormal[iVictim][DuelPlaying] = varNormal[iKiller][DuelPlaying] = false;
	RGSetUserGlow(iVictim,0,0,0),RGSetUserGlow(iKiller,0,0,0);
	varGlobal[DuelModeGlobal] = -1;
	@StopSound();
	if(iCvars[9]) {
		new iCoord[3];
		get_user_origin(iVictim,iCoord);
		iCoord[2] -= 26;
		CreateLavaSplash(iCoord);
		emit_sound(iVictim,CHAN_ITEM, "weapons/headshot2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	#if defined BAHISLI_LR
	switch(get_member(iVictim, m_iTeam)) {
		case TEAM_TERRORIST: {
			if(varNormal[iVictim][BahisTL] > 0) {
				client_print_color(0, 0, "%s ^3(%n) ^1Adli Kisi Yatirdigi Parayi Kaybetti!",sTags[ChatTag],iVictim);
				jb_set_user_packs(iVictim, jb_get_user_packs(iVictim) - varNormal[iVictim][BahisTL]);
				varNormal[iVictim][BahisTL] = 0;
			}
			for(new iBahis = 1; iBahis <= MaxClients;iBahis++ ) {
				if(is_user_connected(iBahis)) {
					switch(varNormal[iBahis][BahisChoosed]) {
						case 1: {
							client_print_color(iBahis,iBahis, "%s ^1Bahisi ^4Kazandiniz^1. ^1Kazanciniz: ^4(%i) TL",sTags[ChatTag],varNormal[iBahis][BahisTL]);
							jb_set_user_packs(iBahis, jb_get_user_packs(iBahis) + varNormal[iBahis][BahisTL]);
							varNormal[iBahis][BahisTL] = 0; 
							varNormal[iBahis][BahisChoosed] = 0;
							continue;
						}
						case 2: {
							client_print_color(iBahis,iBahis, "%s ^1Bahisi ^4Kaybettiniz^1. ^1Kaybiniz: ^4(%i) TL",sTags[ChatTag],varNormal[iBahis][BahisTL]);
							jb_set_user_packs(iBahis, jb_get_user_packs(iBahis) - varNormal[iBahis][BahisTL]);
							varNormal[iBahis][BahisTL] = 0;
							varNormal[iBahis][BahisChoosed] = 0;
							continue;
						}
					}
				}
			}
		}
		case TEAM_CT: {
			if(varNormal[iKiller][BahisTL] > 0) {
				client_print_color(0, 0, "%s ^3(%n) ^1Adli Kisi Yatirdigi Paranin ^4(2) Katini ^1Kazandi!",sTags[ChatTag],iKiller);
				jb_set_user_packs(iKiller, jb_get_user_packs(iKiller) + varNormal[iKiller][BahisTL]);
				varNormal[iKiller][BahisTL] = 0;
			}
			for(new iBahis = 1; iBahis <= MaxClients;iBahis++ ) {
				if(is_user_connected(iBahis)) {
					switch(varNormal[iBahis][BahisChoosed]) {
						case 1: {
							client_print_color(iBahis,iBahis, "%s ^1Bahisi ^4Kaybettiniz^1. ^1Kaybiniz: ^4(%i) TL",sTags[ChatTag],varNormal[iBahis][BahisTL]);
							jb_set_user_packs(iBahis, jb_get_user_packs(iBahis) - varNormal[iBahis][BahisTL]);
							varNormal[iBahis][BahisTL] = 0;
							varNormal[iBahis][BahisChoosed] = 0;
							continue;
						}
						case 2: {
							client_print_color(iBahis,iBahis, "%s ^1Bahisi ^4Kazandiniz^1. ^1Kazanciniz: ^4(%i) TL",sTags[ChatTag],varNormal[iBahis][BahisTL]);
							jb_set_user_packs(iBahis, jb_get_user_packs(iBahis) + varNormal[iBahis][BahisTL]);
							varNormal[iBahis][BahisTL] = 0; 
							varNormal[iBahis][BahisChoosed] = 0;
							continue;
						}
					}
				}
			}
		}
	}
	#endif
}
@BahsiBitir() {
	varGlobal[BahisFinish] = true;
}
public client_disconnected(iPlayer){
	varNormal[iPlayer][BahisTL] = 0;
	varNormal[iPlayer][BahisChoosed] = 0;
	remove_task(iPlayer+TASK_UNFREEZE);
	remove_task(iPlayer+TASK_COUNTDOWN);
}
public plugin_precache() {
	iSizeOfs[0] = sizeof(sWeapons);
	iSizeOfs[1] = sizeof(sLRMusic);
	iSizeOfs[2] = sizeof(sCvarSettings);
	MapNames = ArrayCreate(32);
	aOriginsT = ArrayCreate(32);
	aOriginsCT = ArrayCreate(32);
	new iFopen = fopen(sFileOrigin, "a+"); 
	if(iFopen) {
		new sString[256],sCheckFile[32],sCheckCoordT[32],sCheckCoordCT[32];
		while(!feof(iFopen)) {
			fgets(iFopen, sString, charsmax(sString));
			parse(sString,sCheckFile,31,sCheckCoordT,31,sCheckCoordCT,31);
			ArrayPushString(MapNames,sCheckFile);
			ArrayPushString(aOriginsT, sCheckCoordT);
			ArrayPushString(aOriginsCT, sCheckCoordCT);
		}
		fclose(iFopen);
	}
	FileCheck();
	for(new i; i < iSizeOfs[1]; i++){
		if((iSizeOfs[1]-1) == -1) return;
		precache_sound(sLRMusic[i]);
	}
	varGlobal[Beam] = precache_model("sprites/laserbeam.spr");
	precache_sound("weapons/headshot2.wav");
}
public plugin_end() {
	ArrayDestroy(MapNames);
	ArrayDestroy(aOriginsT);
	ArrayDestroy(aOriginsCT);
}
@TouchingWP(weapon, iPlayer) {
	if (!is_user_connected(iPlayer) || varGlobal[DuelActive])
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}
@DuelMenu(const iPlayer) {
	if(!IsPlayerCanUse(iPlayer)) 
		return;
	new Menu = menu_create(fmt("\d( \r%s \d) \y~\d> \wDüello Menü \rV\yPremium",sTags[LongTag]), "@DuelMenu_");
	for(new fMenu=0;fMenu<iSizeOfs[0];fMenu++) 
		menu_additem(Menu,fmt("\r[\y%s\r] \d~> \w%s", sTags[ShortTag],sWeapons[fMenu][0][0]),fmt("%i",fMenu));
	menu_setprop(Menu, MPROP_EXIT,MEXIT_NEVER);
	menu_setprop(Menu, MPROP_PERPAGE, 0);
	menu_display(iPlayer, Menu, 0);
}
@DuelMenu_(const iPlayer,const iMenu, const iItem) {
	if(iItem == MENU_EXIT || !IsPlayerCanUse(iPlayer)) { menu_destroy(iMenu);return PLUGIN_HANDLED; }
	new iData[6];
	menu_item_getinfo(iMenu, iItem, _, iData, charsmax(iData));
	varNormal[iPlayer][DuelMode] = varGlobal[DuelModeGlobal] = str_to_num(iData);
	#if defined BAHISLI_LR
		@BahisMenu(iPlayer);
	#else
		@EnemyChooser(iPlayer);
	#endif
	menu_destroy(iMenu);return PLUGIN_HANDLED;
}
#if defined BAHISLI_LR
@GlobalBahis(const iPlayer) {
	if(varGlobal[BahisFinish] == true) {
		client_print_color(iPlayer, iPlayer, "%s ^1Bahisin Suresi Bitti!",sTags[ChatTag]);
		return;
	}
	if(varNormal[iPlayer][DuelPlaying]) {
		client_print_color(iPlayer, iPlayer, "%s ^1LR Atarken Global Bahisi Kullanamazsin.",sTags[ChatTag]);
		return;
	}
	new Menu = menu_create(fmt("\d( \r%s \d) \y~\d> \wBahis Yatıracğınız Kişiyi Seçin",sTags[LongTag]), "@GlobalBahis_");

	menu_additem(Menu,fmt("\r[\y%s\r] \d~> \yCT \wKazanir%s", sTags[ShortTag],varNormal[iPlayer][BahisChoosed] == 1 ? "\d[\ySeçildi\d]":""),"1");
	menu_additem(Menu,fmt("\r[\y%s\r] \d~> \rT \wKazanir%s^n", sTags[ShortTag],varNormal[iPlayer][BahisChoosed] == 2 ? "\d[\ySeçildi\d]":""),"2");

	menu_additem(Menu,fmt("\r[\y%s\r] \d~> \wMiktar Gir\d[\rMax \y%i \rTL\d]^n", sTags[ShortTag],iCvars[10]),"3");
	menu_additem(Menu,fmt("\r[\y%s\r] \d~> \wBahis Yatırma", sTags[ShortTag]),"4");
	
	menu_setprop(Menu, MPROP_EXIT,MEXIT_NEVER);
	menu_display(iPlayer, Menu);
}
@GlobalBahis_(const iPlayer,const iMenu, const iItem) {
	if(iItem == MENU_EXIT) { menu_destroy(iMenu);return PLUGIN_HANDLED; }
	if(varGlobal[BahisFinish] == true) {
		client_print_color(iPlayer, iPlayer, "%s ^1Bahisin Suresi Bitti!",sTags[ChatTag]);
		menu_destroy(iMenu);return PLUGIN_HANDLED;
	}
	new iData[6], iKey;
	menu_item_getinfo(iMenu, iItem, _, iData, charsmax(iData));
	iKey = str_to_num(iData);
	switch(iKey) {
		case 1: {
			varNormal[iPlayer][BahisChoosed] = 1;
			client_print_color(iPlayer, iPlayer, "%s ^4CT Takimi ^1Secildi.",sTags[ChatTag]);
			@GlobalBahis(iPlayer);
		}
		case 2: {
			client_print_color(iPlayer, iPlayer, "%s ^4T Takimi ^1Secildi.",sTags[ChatTag]);
			varNormal[iPlayer][BahisChoosed] = 2;
			@GlobalBahis(iPlayer);
		}
		case 3: {
			if(varNormal[iPlayer][BahisChoosed] > 0) {
				varNormal[iPlayer][MenuChoose] = true,varNormal[iPlayer][BahisType] = 2,client_cmd(iPlayer,"messagemode Bahis_Miktari_Giriniz");
			}
			else {
				client_print_color(iPlayer, iPlayer, "%s ^4Lutfen Once Takim Seciniz.",sTags[ChatTag]);
			}
		}
		case 4: varNormal[iPlayer][BahisTL] = -1;
	}
	menu_destroy(iMenu);return PLUGIN_HANDLED;
}
@BahisMenu(const iPlayer) {
	if(!IsPlayerCanUse(iPlayer)) return;
	new Menu = menu_create(fmt("\d( \r%s \d) \y~\d> \wLR'de Bahis",sTags[LongTag]), "@BahisMenu_");
	menu_additem(Menu,fmt("\r[\y%s\r] \d~> \wMiktar Gir \d[\rMax \y%i \rTL\d]", sTags[ShortTag],iCvars[10]),"1");
	menu_additem(Menu,fmt("\r[\y%s\r] \d~> \wBahis Yatırma", sTags[ShortTag]),"2");
	
	menu_setprop(Menu, MPROP_EXIT,MEXIT_NEVER);
	menu_display(iPlayer, Menu);
}
@BahisMenu_(const iPlayer,const iMenu, const iItem) {
	if(iItem == MENU_EXIT) { menu_destroy(iMenu);return PLUGIN_HANDLED; }
	new iData[6], iKey;
	menu_item_getinfo(iMenu, iItem, _, iData, charsmax(iData));
	iKey = str_to_num(iData);
	switch(iKey) {
		case 1: varNormal[iPlayer][MenuChoose] = true,varNormal[iPlayer][BahisType] = 1,client_cmd(iPlayer,"messagemode Bahis_Miktari_Giriniz");
		case 2: varNormal[iPlayer][BahisTL] = 0,@EnemyChooser(iPlayer);
	}
	menu_destroy(iMenu);return PLUGIN_HANDLED;
}
@ReadAmmount(const iPlayer) {
	if(!varNormal[iPlayer][MenuChoose]) {
		client_print(iPlayer,print_console,"Hop Hemserim Nereye!");
		return;
	}
	new szRead[64],iNums;
	read_args(szRead, charsmax(szRead));
	remove_quotes(szRead);
	iNums = str_to_num(szRead);
	if(iNums <= 0) {
		client_print_color(iPlayer, iPlayer, "%s ^1Minimum Deger^4 1 ^1Olmalidir.",sTags[ChatTag]);
		client_cmd(iPlayer,"messagemode Bahis_Miktari_Giriniz");
		return;
	}
	if(iNums > jb_get_user_packs(iPlayer)) {
		client_print_color(iPlayer, iPlayer, "%s ^1Sende Olmayan Parayi Yatiramazsin. ^4Sende Olan Para Miktari ^1%i",sTags[ChatTag],jb_get_user_packs(iPlayer));
		client_cmd(iPlayer,"messagemode Bahis_Miktari_Giriniz");
		return;
	}
	if(iNums > iCvars[10]){
		client_print_color(iPlayer, iPlayer, "%s ^1Maximum ^4%i ^1TL Yatirabilirsin.",sTags[ChatTag],iCvars[10]);
		client_cmd(iPlayer,"messagemode Bahis_Miktari_Giriniz");
		return;
	}
	switch(varNormal[iPlayer][BahisType]) {
		case 1: {
			varNormal[iPlayer][BahisTL] = iNums;
			client_print_color(iPlayer, iPlayer, "%s ^4(%i) ^1TL Yatirdiniz.",sTags[ChatTag],iNums);
			client_print_color(0, 0, "%s ^3(%n) ^1Adli Kisi LR'de ^4(%i) ^1TL Yatirdi.",sTags[ChatTag],iPlayer,iNums);
			@EnemyChooser(iPlayer);
		}
		case 2: {
			varNormal[iPlayer][BahisTL] = iNums;
			client_print_color(iPlayer, iPlayer, "%s ^1Bahise ^4(%i) ^1TL Yatirdiniz.",sTags[ChatTag],iNums);
		}
	} 
	varNormal[iPlayer][BahisType] = 0;
	varNormal[iPlayer][MenuChoose] = false;
	return;
}
#endif
@EnemyChooser(const iPlayer) {
	if(!IsPlayerCanUse(iPlayer)) return;
	new Menu = menu_create(fmt("\d( \y%s \d) \r~\d> \rRakibinizi \wSeçin", sTags[LongTag]), "@EnemyChooser_");
	for( new iEnemy=1; iEnemy <= MaxClients; iEnemy++ ){
		if(is_user_connected(iEnemy) && is_user_alive(iEnemy) && get_member(iEnemy, m_iTeam) == TEAM_CT) {
			menu_additem(Menu,fmt("\w%n \y~\d> \rRakibi Seç",iEnemy),fmt("%i",iEnemy));
		}
	}
	menu_setprop(Menu, MPROP_EXIT,MEXIT_NEVER);
	menu_display(iPlayer, Menu);
}
@EnemyChooser_(const iPlayer,const iMenu, const iItem) {
	if(iItem == MENU_EXIT || !IsPlayerCanUse(iPlayer)) { menu_destroy(iMenu);return PLUGIN_HANDLED; }
	new iData[6],iSecilenID;
	menu_item_getinfo(iMenu, iItem, _, iData, charsmax(iData));
	iSecilenID = str_to_num(iData);
	if(!is_user_connected(iSecilenID) && !is_user_alive(iSecilenID)) { @EnemyChooser(iPlayer); return PLUGIN_HANDLED; }
	@StartLastRequest(iPlayer,iSecilenID);
	menu_destroy(iMenu);return PLUGIN_HANDLED;
}
@StartLastRequest(const iPlayer, const iEnemy) {
	if(!is_user_connected(iPlayer) || !is_user_connected(iEnemy)) return;
	
	varGlobal[DuelActive] = varNormal[iPlayer][DuelPlaying] = varNormal[iEnemy][DuelPlaying] = true;
	rg_remove_all_items(iPlayer),rg_remove_all_items(iEnemy);
	@Freeze(iPlayer), @Freeze(iEnemy);
	set_entvar(iPlayer,var_health,100.0),set_entvar(iEnemy,var_health,100.0);
	set_pcvar_num(iOldCvars[1], 0);
	@TeleportAll(iPlayer,iEnemy);
	set_task(2.9,"@StopSound",TASK_STPSOUND);
	set_task(3.0,"@PlayLRMusic",TASK_PLAYSOUND);
	set_lights("f");
	varGlobal[iCTID] = iEnemy;
	varGlobal[iTID] = iPlayer;
	varGlobal[BahisFinish] = false;
	#if defined BAHISLI_LR
	for(new i = 1; i <= MaxClients;i++) {
		if(is_user_connected(i) ) {
			if(varNormal[i][DuelPlaying] == false)
			@GlobalBahis(i);
		}
	}
	#endif
	if(iCvars[0]) set_pcvar_num(iOldCvars[0], 0);
	else set_pcvar_num(iOldCvars[0], 1);

	set_entvar(iPlayer,var_takedamage,DAMAGE_AIM),set_entvar(iEnemy,var_takedamage,DAMAGE_AIM);
	if(iCvars[1]) {
		varGlobal[iDuelSayac] = iCvars[2];
		set_task(3.0,"@CountingDown", TASK_COUNTDOWN);
	}
	if(iCvars[3]) {
		varGlobal[iCountDown] = 3;@LRStarting();
	}
	rg_give_item(iPlayer, sWeapons[varGlobal[DuelModeGlobal]][1]),rg_give_item(iEnemy, sWeapons[varGlobal[DuelModeGlobal]][1]);
	switch(iCvars[4]) {
		case 1: RGSetUserGlow(iPlayer,250,0,0),RGSetUserGlow(iEnemy,0,0,250);
		case 2: {
			RGSetUserGlow(iPlayer,250,0,0),RGSetUserGlow(iEnemy,0,0,250);
			@ShowCircleEffect();
		}
		case 3: {
			RGSetUserGlow(iPlayer,250,0,0),RGSetUserGlow(iEnemy,0,0,250);
			@ShowCircleEffect(),@ShowLineEffects();
		}
		case 4: {
			RGSetUserGlow(iPlayer,250,0,0),RGSetUserGlow(iEnemy,0,0,250);
			@ShowLineEffects();
		}
		case 5: @ShowCircleEffect();
	}
	switch(varGlobal[DuelModeGlobal]) {
		case 2,3: {
			rg_set_user_ammo(iPlayer, WeaponIdType:sWeapons[varGlobal[DuelModeGlobal]][2][0], 100);
			rg_set_user_ammo(iEnemy, WeaponIdType:sWeapons[varGlobal[DuelModeGlobal]][2][0], 100);
		}
		default: {
			rg_set_user_ammo(iPlayer, WeaponIdType:sWeapons[varGlobal[DuelModeGlobal]][2][0], 1);
			rg_set_user_ammo(iEnemy, WeaponIdType:sWeapons[varGlobal[DuelModeGlobal]][2][0], 1);
		}
	}
	rg_set_user_bpammo(iPlayer, WeaponIdType:sWeapons[varGlobal[DuelModeGlobal]][2][0], 1);
	rg_set_user_bpammo(iEnemy, WeaponIdType:sWeapons[varGlobal[DuelModeGlobal]][2][0], 1);
}
@ShowCircleEffect() {
	iCvars[5] ? 
	TECreateBeamRingBetweenEnt(varGlobal[iCTID], varGlobal[iTID], varGlobal[Beam], 0, 30, 10, 10, 0, random_num(55, 255), random_num(55, 255), random_num(55, 255), 75, 0, 0, true):
	TECreateBeamRingBetweenEnt(varGlobal[iCTID], varGlobal[iTID], varGlobal[Beam], 0, 30, 10, 10, 0, 255, 255, 255, 75, 0, 0, true);
	set_task(1.0,"@ShowCircleEffect",TASK_CEFFECT);
}
@ShowLineEffects() {
	iCvars[5] ?
	TECreateBeamBetweenEnt(varGlobal[iCTID], varGlobal[iTID], varGlobal[Beam], 0, 30, 10, 10, 0,  random_num(55, 255),  random_num(55, 255),  random_num(55, 255), 75, 0, 0, true):
	TECreateBeamBetweenEnt(varGlobal[iCTID], varGlobal[iTID], varGlobal[Beam], 0, 30, 10, 10, 0, 255, 255, 255, 75, 0, 0, true);
	set_task(1.0,"@ShowLineEffects",TASK_CEFFECT);
}
@LRStarting() {
	client_print(0, print_center, "LR %d Saniye Sonra Başlayacak",varGlobal[iCountDown]);
	varGlobal[iCountDown]--;
	emit_sound(0, CHAN_AUTO, "weapons/zoom.wav", VOL_NORM, ATTN_NORM , 0, PITCH_NORM);
	(varGlobal[iCountDown] < 0 ) ? (remove_task(TASK_COUNTDOWN2),set_entvar(varGlobal[iTID],var_health,100.0),set_entvar(varGlobal[iCTID],var_health,100.0))
	:set_task(0.8,"@LRStarting",TASK_COUNTDOWN2);
}
@CoordMenu(const iPlayer) {
	if(~get_user_flags(iPlayer) & ADMIN_IMMUNITY) return PLUGIN_HANDLED;
	new sMapMenu[32],iVaulueTo;
	get_mapname(sMapMenu, charsmax(sMapMenu));
	iVaulueTo = sMapCheck(sMapMenu);
	new Menu = menu_create(fmt("\d( \r%s \d) \y~\d> \wKoordinat Ayar^n\yMap\d:\r%s^n\wKayıtlı Koordinat\d: %s",sTags[LongTag],sMapMenu,
	iVaulueTo == -1 ? "\d[\rYok\d]":"\d[\yVar\d]"), "@CoordMenu_");
	menu_additem(Menu,fmt("\r[\y%s\r] \d~> \rT \wKoordinatı Al", sTags[ShortTag]),"1");
	menu_additem(Menu,fmt("\r[\y%s\r] \d~> \yCT \wKoordinatı Al", sTags[ShortTag]),"2");
	menu_additem(Menu,fmt("\r[\y%s\r] \d~> \wKoordinatları Kaydet^n", sTags[ShortTag]),"3");
	menu_additem(Menu,fmt("\r[\y%s\r] \d~> \wKoordinatları \rSil", sTags[ShortTag]),"4");
	menu_setprop(Menu, MPROP_EXITNAME, "\wKapat");
	menu_display(iPlayer, Menu);
	return PLUGIN_HANDLED;
}
@CoordMenu_(const iPlayer,const iMenu, const iItem) {
	if(iItem == MENU_EXIT) { menu_destroy(iMenu);return PLUGIN_HANDLED; }
	new iData[6], iKey, hMapName[33];
	menu_item_getinfo(iMenu, iItem, _, iData, charsmax(iData));
	iKey = str_to_num(iData);
	switch(iKey) {
		case 1: {
			get_entvar(iPlayer,var_origin,mCoordT);
			client_print_color(iPlayer, iPlayer, "%s ^3T Koordinatlari ^1Cekildi!",sTags[ChatTag]);
			@CoordMenu(iPlayer);
		}
		case 2: {
			get_entvar(iPlayer,var_origin,mCoordCT);
			client_print_color(iPlayer, iPlayer, "%s ^3CT Koordinatlari ^1Cekildi!",sTags[ChatTag]);
			@CoordMenu(iPlayer);
		}  
		case 3: {
			get_mapname(hMapName, charsmax(hMapName));
			if(mCoordT[0] == 0.0 || mCoordT[0] == 0.0)
			client_print_color(iPlayer, iPlayer, "%s ^1Lutfen Her Iki Koordinatida Cekin!",sTags[ChatTag]);
			else @WriteFileCoords(iPlayer,hMapName, mCoordT, mCoordCT);
			mCoordT[0] = mCoordT[1] = mCoordT[2] = mCoordCT[0] = mCoordCT[1] = mCoordCT[2] = 0.0;
			@CoordMenu(iPlayer);
			client_print_color(iPlayer, iPlayer, "%s ^1Koordinatlar Kaydedildi!",sTags[ChatTag]);
		}
		case 4: {
			new iLineThe;
			get_mapname(hMapName, charsmax(hMapName));
			iLineThe = sMapCheck(hMapName);
			@RemoveLine(sFileOrigin,hMapName);
			ArrayDeleteItem(MapNames, iLineThe);
			ArrayDeleteItem(aOriginsT, iLineThe);
			ArrayDeleteItem(aOriginsCT, iLineThe);
			client_print_color(iPlayer, iPlayer, "%s ^1Haritaya Ait Koordinatlar ^3Silindi^1!",sTags[ChatTag]);
			@CoordMenu(iPlayer);
		}
	}
	menu_destroy(iMenu);return PLUGIN_HANDLED;
}
@StopSound() client_cmd(0,"stopsound");
@TeleportAll(const iPlayerID,const iEnemyID) {
	new szMapNameI[32],iLineOF;
	get_mapname(szMapNameI, charsmax(szMapNameI));
	iLineOF = sMapCheck(szMapNameI);
	if(iLineOF == -1) {
		return PLUGIN_HANDLED;
	}
	new Float:fOri[3];
	fOri[0] = str_to_float(iOriginT[0]);
	fOri[1] = str_to_float(iOriginT[1]);
	fOri[2] = str_to_float(iOriginT[2]);
	set_entvar(iPlayerID,var_origin,Float:fOri);
	fOri[0] = str_to_float(iOriginCT[0]);
	fOri[1] = str_to_float(iOriginCT[1]);
	fOri[2] = str_to_float(iOriginCT[2]);
	set_entvar(iEnemyID,var_origin,Float:fOri);
	return PLUGIN_CONTINUE;
}
@CountingDown(iTaskID) {
	if(!is_user_connected(varGlobal[iTID]) || !is_user_connected(varGlobal[iCTID])) return;
	
	if(varGlobal[iDuelSayac] <= 0) {
		user_kill(varGlobal[iTID]);
		remove_task(TASK_COUNTDOWN);
	}
	else set_task(1.0,"@CountingDown", TASK_COUNTDOWN);
	set_hudmessage(100, 255 , 52, -1.0, 0.25 , 2, 0.02, 1.0, 0.01, 1.0, 35);
	new iHp[2];
	iHp[0] = floatround(get_entvar(varGlobal[iCTID], var_health));
	iHp[1] = floatround(get_entvar(varGlobal[iTID], var_health));
	varGlobal[iDuelSayac]--;
	ShowSyncHudMsg(0,varGlobal[SyncObjs],"Düellonun Bitmesine [ %i ] Saniye Kaldi!^n%n: %i HP ~ %n: %i HP",varGlobal[iDuelSayac], varGlobal[iCTID], iHp[0], varGlobal[iTID], iHp[1]);
}
@Freeze(const iPlayer) {
	new iFlags = get_entvar(iPlayer, var_flags);
	if(~iFlags & FL_FROZEN) {
		set_entvar(iPlayer, var_flags, iFlags | FL_FROZEN);
		set_task(3.0, "@UnFreeze",iPlayer+TASK_UNFREEZE);
	}
}
@UnFreeze(iPlayer) {
	iPlayer -= TASK_UNFREEZE;
	new iFlags = get_entvar(iPlayer, var_flags);
	if(iFlags & FL_FROZEN) {
		set_entvar(iPlayer, var_flags, iFlags & ~FL_FROZEN);
	}
}
@WriteFileCoords(const iPlayer, const MapFileName[], Float: Coord[3], Float: CoordCT[3]) {
	new iFopen = fopen(sFileOrigin, "a+"); 
	if(iFopen) {
		new sMapLine = sMapCheck(MapFileName);
		switch(sMapLine) {
			case -1: {
				ArrayPushString(MapNames,MapFileName);
				ArrayPushString(aOriginsT, fmt("%i %i %i",floatround(Coord[0]),floatround(Coord[1]),floatround(Coord[2])));
				ArrayPushString(aOriginsCT, fmt("%i %i %i",floatround(CoordCT[0]),floatround(CoordCT[1]),floatround(CoordCT[2])));
				client_print_color(iPlayer, iPlayer, "%s ^1Başarılı bir şekilde koordinatlar kaydedildi!",sTags[ChatTag]);
				fputs(iFopen,fmt("^"%s^" ^"%i %i %i^" ^"%i %i %i^"^n",MapFileName,floatround(Coord[0]),floatround(Coord[1]),floatround(Coord[2]),
				floatround(CoordCT[0]),floatround(CoordCT[1]),floatround(CoordCT[2])));
			}
			default: {
				client_print_color(iPlayer, iPlayer, "%s ^1Onceki Koordinatlar Silindi!",sTags[ChatTag]);
				client_print_color(iPlayer, iPlayer, "%s ^1Basarili Bir Sekilde Yeni Koordinatlar Kaydedildi!",sTags[ChatTag]);
				fclose(iFopen);
				@RemoveLine(sFileOrigin,MapFileName);
				ArrayDeleteItem(MapNames, sMapLine-1);
				ArrayDeleteItem(aOriginsT, sMapLine-1);
				ArrayDeleteItem(aOriginsCT, sMapLine-1);
				ArrayPushString(MapNames,MapFileName);
				ArrayPushString(aOriginsT, fmt("%i %i %i",floatround(Coord[0]),floatround(Coord[1]),floatround(Coord[2])));
				ArrayPushString(aOriginsCT, fmt("%i %i %i",floatround(CoordCT[0]),floatround(CoordCT[1]),floatround(CoordCT[2])));
				iFopen = fopen(sFileOrigin, "a+"); 
				if(iFopen) {
					fputs(iFopen,fmt("^"%s^" ^"%i %i %i^" ^"%i %i %i^"^n",MapFileName,floatround(Coord[0]),floatround(Coord[1]),floatround(Coord[2]),
					floatround(CoordCT[0]),floatround(CoordCT[1]),floatround(CoordCT[2])));
				}
			}
		}
		FileCheck();
		fclose(iFopen);
	}
}
@PlayLRMusic() {
	switch(iSizeOfs[1]-1) {
		case 0: {
			if(equali(sLRMusic[0][0],"")) return;
			emit_sound(0, CHAN_AUTO, sLRMusic[0][0], VOL_NORM, ATTN_NORM , 0, PITCH_NORM);
		}
		default:{
			new iMusic = random_num(0, iSizeOfs[1]-1);
			emit_sound(0, CHAN_AUTO, sLRMusic[iMusic][0], VOL_NORM, ATTN_NORM , 0, PITCH_NORM);
		}
	}
}
stock sMapCheck(const strMapName[]) {
	new szMapNameStock[42],iMaxArray = ArraySize(MapNames);
	for(new i; i < iMaxArray; i++) {
		ArrayGetString(MapNames, i, szMapNameStock, charsmax(szMapNameStock));
		if(equal(strMapName,szMapNameStock)) {
			return i;
		}
	}
	return -1;
}
@AmmoFIX(iMsgId, iMsgDest, iPlayer) {
	if(is_user_alive(iPlayer) && varGlobal[DuelActive]) {
		set_msg_arg_int(2, ARG_BYTE, 1);
		for(new i = 1; i <= 10; i++) {
			set_pdata_int(iPlayer, 376 + i, 1, 5);
		}
	}
}
stock TECreateBeamBetweenEnt(startent, endent, sprite, startframe = 0, framerate = 30, life = 10, width = 10, noise = 0, r = 0, g = 0, b = 255, a = 75, speed = 0, receiver = 0, bool:reliable = true){
	if(receiver && !is_user_connected(receiver))
		return 0;
	message_begin(get_msg_destination(receiver, reliable), SVC_TEMPENTITY, .player = receiver);
	write_byte(TE_BEAMENTS);
	write_short(startent);
	write_short(endent);
	write_short(sprite);
	write_byte(startframe);
	write_byte(framerate);
	write_byte(life);
	write_byte(width);
	write_byte(noise);
	write_byte(r);
	write_byte(g);
	write_byte(b);
	write_byte(a);
	write_byte(speed);
	message_end();
	return 1;
}
stock TECreateBeamRingBetweenEnt(startent, endent, sprite, startframe = 0, framerate = 30, life = 10, width = 10, noise = 0, r = 0, g = 0, b = 255, a = 75, speed = 0, receiver = 0, bool:reliable = true) {
	if(receiver && !is_user_connected(receiver))
		return 0;
	message_begin(get_msg_destination(receiver, reliable), SVC_TEMPENTITY, .player = receiver);
	write_byte(TE_BEAMRING);
	write_short(startent);
	write_short(endent);
	write_short(sprite);
	write_byte(startframe);
	write_byte(framerate);
	write_byte(life);
	write_byte(width);
	write_byte(noise);
	write_byte(r);
	write_byte(g);
	write_byte(b);
	write_byte(a);
	write_byte(speed);
	message_end();
	return 1;
}
get_msg_destination(iPlayer, bool:reliable) {
	if(iPlayer)
		return reliable ? MSG_ONE : MSG_ONE_UNRELIABLE;
	return reliable ? MSG_ALL : MSG_BROADCAST;
}
CreateLavaSplash(vec1[3]) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_LAVASPLASH); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2]); 
	message_end();
}
bool:IsPlayerCanUse(const iPlayer) {
	static iTER,iCT;
	rg_initialize_player_counts(iTER,iCT);
	if(iTER > 1) {
		client_print_color(iPlayer, iPlayer, "%s ^1Yalnizca Sona Kalan Mahkum LR Atabilir!",sTags[ChatTag]);
		return false;
	} 
	if(iCT <= 0) {
		client_print_color(iPlayer, iPlayer, "%s ^1Rakip Bulunmadigi Icin LR Atamazsiniz!",sTags[ChatTag]);
		return false;
	} 
	if(!is_user_alive(iPlayer)) {
		client_print_color(iPlayer, iPlayer, "%s ^1Yalnizca Yasayan Mahkumlar LR Atabilir!",sTags[ChatTag]);
		return false;
	}
	if(get_member(iPlayer,m_iTeam) != TEAM_TERRORIST) {
		client_print_color(iPlayer, iPlayer, "%s ^1Yalnizca Mahkumlar LR Atabilir!",sTags[ChatTag]);
		return false;
	}
	return true;
}
@RemoveLine(const szFileName[], const szOldString[]) {
	new const szTempFile[] = "addons/amxmodx/configs/tempfile.ini";
	new intValue,iFile = fopen(szFileName, "rt");
	if(iFile) {
		new iTempFile = fopen(szTempFile, "a+");
		if(iTempFile) {
			new szBuffer[256],szMapNameD[32];
			while(!feof(iFile)) {
				fgets(iFile, szBuffer, charsmax(szBuffer));
				parse(szBuffer,szMapNameD,31);
				intValue++;
				if(!strlen(szBuffer) || equali(szMapNameD, szOldString)) 
					continue;
				fputs(iTempFile, szBuffer);

			}
			fclose(iFile);
			fclose(iTempFile);
		}
	}
	delete_file(szFileName);
	rename_file(szTempFile, szFileName, 1);
}
RGSetUserGlow(const iPlayer, const iRed=0, const iGreen=0, const iBlue=0) {
	new Float:RenderColor[3];
	RenderColor[0]=float(iRed),RenderColor[1]=float(iGreen),RenderColor[2]=float(iBlue);
	set_entvar(iPlayer, var_renderfx, kRenderFxGlowShell);
	set_entvar(iPlayer, var_rendercolor, RenderColor);
	set_entvar(iPlayer, var_rendermode, kRenderNormal);
	set_entvar(iPlayer, var_renderamt, 30.0);
}