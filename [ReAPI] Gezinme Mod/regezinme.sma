/* Sublime AMXX Editor v3.2 */

#include <amxmodx>
#include <reapi>
#include <fakemeta>
#include <engine>
#pragma semicolon 1
#pragma dynamic 32768
#define DEAD_FLAG   (1<<0)  
#define GetPlayerHullSize(%1)  ( ( get_entvar ( %1, var_flags ) & FL_DUCKING ) ? HULL_HEAD : HULL_HUMAN )

new const MenuTag[] = "WebAilesi";
new const SayTag[] = "^1[ ^3- ^4WebAilesi ^3- ^1]";

new const sG_Cvars[][][] = {
	{"GM_GezinmeHook","1"},
	{"GM_DepremYarat","30"},
	{"GM_ElektirikleriKes","50"},
	{"GM_CtDisarm","70"},
	{"GM_CTGom","70"}
};
enum _: Normal {
	iL_Choosing,
	iL_Money
}
enum _: Bools {
	bool:iL_Ghost,
	bool:g_bSilent,
	bool:iL_Revived,
	bool:iL_Falling,
	bool:iL_HookOn
}
new bool:iL_Bools[MAX_CLIENTS+1][Bools],iL_Int[MAX_CLIENTS+1][Normal],gmsgScoreAttrib,bool:iL_Rocket,bool:iL_LROpen,iL_Cvars[6],
Float:LastCmdTime[MAX_CLIENTS+1];
enum Coord_e { Float:xx, Float:yy, Float:zz };
public plugin_natives() {
	register_native("get_ghost_num","@pCheckX");
	register_native("is_user_ghost","@pGhostX");
}
@pCheckX() {
	static id;
	new Players[32], NumAll, Num;
	get_players(Players, NumAll, "ae", "TERRORIST");
	for(new i; i < NumAll; i++) { 
		id = Players[i];
		if(iL_Bools[id][iL_Ghost]) Num++;
	}
	new NumAllNew = NumAll - Num;
	return NumAllNew;
}
@pGhostX(){
	new iP_ID = get_param(1);
	return iL_Bools[iP_ID][iL_Ghost];
}
public plugin_init() {
	register_plugin("ReGezinme Mod", "3.3", "PawNod'");
	for(new i; i < sizeof(sG_Cvars); i++) bind_pcvar_num(create_cvar(sG_Cvars[i][0][0],sG_Cvars[i][1][0]),iL_Cvars[i]);
	register_touch("weaponbox", "player", "@pTouchWp");
	register_touch("armoury_entity", "player", "@pTouchWp");
	register_touch("weapon_shield", "player", "@pTouchWp");
	register_touch("grenade", "player", "@pTouchWp");
	register_event("StatusValue", "@showStatus", "be", "1=2", "2!0");
	register_event("DeathMsg","@pDeath","a");

	register_forward(FM_EmitSound,"@pEmitS");
	register_forward(FM_ClientKill,"@pIntihar");
	register_forward(FM_CmdStart,"@pCmdStart");

	register_clcmd("say","@pYazma");register_clcmd("say_team","@pYazma");
	register_clcmd("flyed","@Flying");
	register_concmd("amx_gpver","@pGPVer",ADMIN_IMMUNITY,"<isim> <miktar>, belirlenen kisiye para verir");

	RegisterHookChain(RG_CBasePlayer_Spawn, "@pSpawn", .post = true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@pTakeDMG", .post = false);
	RegisterHookChain(RG_CBasePlayer_Killed, "@pKilled", .post = true);
	RegisterHookChain(RG_RoundEnd, "@RoundEnd", .post = false);
	RegisterHookChain(RG_CBasePlayer_PreThink, "@PreThink", .post = false);
	RegisterHookChain(RG_CBasePlayer_PostThink, "@PostThink", .post = false);

	gmsgScoreAttrib = get_user_msgid("ScoreAttrib");
	register_message( gmsgScoreAttrib, "msg_ScoreAttrib");
}
@pReControl(const iP_ID) {
	if(IsCanUse(iP_ID,true,false,false,true,true,true,true) && !is_user_alive(iP_ID)) {
		new iMenu = menu_create(fmt("\wÖldünüz \dHayalet \wOlmak Ister Misiniz?^nHayaletken Hiçbir Şey Yapamazsınız"), "@pReControl_");
		menu_additem(iMenu,"\wEvet \yIstiyorum", "1");
		menu_additem(iMenu,"\wHayir \rIstemiyorum", "2");
		menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
		menu_display(iP_ID,iMenu,0);
	}
	return PLUGIN_HANDLED;
}
@pReControl_(const iP_ID, const iMenu, const iItem) {
	if(iItem == MENU_EXIT || !IsCanUse(iP_ID,true,false,false,true,true,true,true)) {
		menu_destroy(iMenu);return PLUGIN_HANDLED;
	}
	if(!is_user_alive(iP_ID)) {
		new iData[6], iKey;
		menu_item_getinfo(iMenu, iItem, _, iData, charsmax(iData));
		iKey = str_to_num(iData);
		switch(iKey) {
			case 1: {
				@pOpenGhost(iP_ID);
			}
			case 2: {
				iL_Bools[iP_ID][iL_Ghost] = false;send_ScoreAttrib(iP_ID,DEAD_FLAG);
				menu_destroy(iMenu);return PLUGIN_HANDLED;
			}
		}
	}
	menu_destroy(iMenu);return PLUGIN_HANDLED;
}
@pMainShop(TASK_ID) {
	new iP_ID = (TASK_ID-1555);
	if(IsCanUse(iP_ID,true,false,true,true,true,true,true)) {
		new iMenu = menu_create(fmt("\dGezinme \rMarketi \d- \yG\wP\d: \y%d^n\wHer El \r4 \yG\wP \yKazanirsiniz^nYapimci: \dPawNod",iL_Int[iP_ID][iL_Money]), "@pMainShop_");
		menu_additem(iMenu,fmt("\w+60 Br Kuzeye \yIlerle"), "1");
		menu_additem(iMenu,fmt("\wKendini \rKaldir^n"), "2");
		menu_additem(iMenu,fmt("\d%s \r~> \wGezinme \rFly \d[\y%d GP\d]",MenuTag,iL_Cvars[0]), "3");
		menu_additem(iMenu,fmt("\d%s \r~> \rDeprem \wYarat \d[\y%d GP\d]",MenuTag,iL_Cvars[1]), "4");
		menu_additem(iMenu,fmt("\d%s \r~> \yElektrikleri \rKes \d[\y%d GP\d]",MenuTag,iL_Cvars[2]), "5");
		menu_additem(iMenu,fmt("\d%s \r~> \w1 CT Disarmla \d[\y%d GP\d]",MenuTag,iL_Cvars[3]), "6");
		menu_additem(iMenu,fmt("\d%s \r~> \w1 CT Gom \d[\y%d GP\d]",MenuTag,iL_Cvars[4]), "7");
		menu_setprop(iMenu, MPROP_EXITNAME, "\wKapat");
		menu_display(iP_ID,iMenu,0);
	}
	return PLUGIN_HANDLED;
}
@pMainShop_(const iP_ID, const iMenu, const iItem) {
	if(iItem == MENU_EXIT || !IsCanUse(iP_ID,true,false,true,true,true,true,true)) {
		menu_destroy(iMenu);return PLUGIN_HANDLED;
	}
	new iData[6], iKey;
	menu_item_getinfo(iMenu, iItem, _, iData, charsmax(iData));
	iKey = str_to_num(iData);
	switch(iKey) {
		case 1: {
			new Float:Origins[3];
			get_entvar(iP_ID,var_origin,Origins);
			Origins[0] += 60.0;
			set_entvar(iP_ID,var_origin,Origins);
			client_print_color(iP_ID, iP_ID, "%s ^1+60 Br kuzeye gidildi!",SayTag);
			@pMainShop(iP_ID+1555);
		}
		case 2: {
			@UnStuck(iP_ID);
			@pMainShop(iP_ID+1555);
		}
		case 3: { 
			if(iL_Int[iP_ID][iL_Money] >= iL_Cvars[0]) {
				iL_Int[iP_ID][iL_Money] -= iL_Cvars[0];
				iL_Bools[iP_ID][iL_HookOn] = true;@pMainShop(iP_ID+1555);
				client_print_color(iP_ID, iP_ID, "%s ^1Marketten ^3[ ^4Gezinme Fly ^3] ^1satin aldin!",SayTag);
				client_print_color(iP_ID, iP_ID, "%s ^1Konsola ^4bind v flyed ^1yazip, ^4V tusuna ^1basip kullanabilirsiniz.",SayTag);
			}
			else client_print_color(iP_ID, iP_ID, "%s ^1Yeterli paraniz bulunmamakta!",SayTag),@pMainShop(iP_ID+1555);
		}
		case 4: {
			if(iL_Int[iP_ID][iL_Money] >= iL_Cvars[1]) {
				iL_Int[iP_ID][iL_Money] -= iL_Cvars[1];
				set_task(0.2,"@Sarsinti",4701,"",0,"b");set_task(6.0,"@DepremiBitir",4702);@pMainShop(iP_ID+1555);
				client_print_color(iP_ID, iP_ID, "%s ^1Marketten ^3[ ^4Deprem Yarat^3] ^1satin aldin!",SayTag);
				client_print_color(0, 0, "%s ^3%n ^1adli oyuncu ^1marketten ^3[ ^4Deprem Yarat ^3] ^1satin aldi!",SayTag,iP_ID);
			}
			else client_print_color(iP_ID, iP_ID, "%s ^1Yeterli paraniz bulunmamakta!",SayTag),@pMainShop(iP_ID+1555);
		}
		case 5: {
			if(iL_Int[iP_ID][iL_Money] >= iL_Cvars[2]) {
				iL_Int[iP_ID][iL_Money] -= iL_Cvars[2];
				set_lights("a");set_task(6.0,"@elektrikAc");@pMainShop(iP_ID+1555);
				client_print_color(iP_ID, iP_ID, "%s ^1Marketten ^3[ ^4Elektrikleri Kes^3] ^1satin aldin!",SayTag);
				client_print_color(0, 0, "%s ^3%n ^1adli oyuncu ^1marketten ^3[ ^4Elektrikleri Kes ^3] ^1satin aldi!",SayTag,iP_ID);
			}
			else client_print_color(iP_ID, iP_ID, "%s ^1Yeterli paraniz bulunmamakta!",SayTag),@pMainShop(iP_ID+1555);
		}
		case 6,7: {
			new iPSelect = (iKey - 5) + 2;
			if(iL_Int[iP_ID][iL_Money] >= iL_Cvars[iPSelect]) {
				iL_Int[iP_ID][iL_Choosing] = (iKey - 5),@pCtChoose(iP_ID);
				client_print_color(iP_ID, iP_ID, "%s ^1Yonlendiriliyorsunuz...",SayTag);
			}
			else client_print_color(iP_ID, iP_ID, "%s ^1Yeterli paraniz bulunmamakta!",SayTag),@pMainShop(iP_ID+1555);
		}
	}
	menu_destroy(iMenu);return PLUGIN_HANDLED;
}
@pGPVer(iP_ID,iL_Lvl, cid){
	if(~get_user_flags(iP_ID) & iL_Lvl) return PLUGIN_HANDLED;
	new iL_Yazi1[18],iL_Yazi2[18];
	read_argv(1,iL_Yazi1,17);read_argv(2,iL_Yazi2,17);
	if(iL_Yazi1[0] == '@') {
		new iL_Miktar = str_to_num(iL_Yazi2),iPlayers[32], iPlayerNum, iPlayer;
		switch(iL_Yazi1[1]) {
			case 't', 'T':{
				get_players(iPlayers, iPlayerNum, "e", "TERRORIST");
				client_print_color(0,0,"^4[ ^3%n ^4] ^1adli admin ^4[ ^3Mahkumlar ^4] ^1'a ^4[ ^3%i GP ^4] ^1verdi^4.",iP_ID,iL_Miktar);
			}
			case 'c', 'C':{
				get_players(iPlayers, iPlayerNum, "e", "CT");
				client_print_color(0,0,"^4[ ^3%n ^4] ^1adli admin ^4[ ^3Gardiyanlar ^4] ^1'a ^4[ ^3%i GP ^4] ^1verdi^4.",iP_ID,iL_Miktar);
			}
			case 'a', 'A':{
				get_players(iPlayers, iPlayerNum);
				client_print_color(0,0,"^4[ ^3%n ^4] ^1adli admin ^4[ ^3Herkes ^4] ^1'e ^4[ ^3%i GP ^4] ^1verdi^4.",iP_ID,iL_Miktar);
			}
		}
		for(new i = 0; i < iPlayerNum; i++) { iPlayer = iPlayers[i]; iL_Int[iPlayer][iL_Money] += iL_Miktar; }
		return PLUGIN_HANDLED;
	}
	new iP_UID = find_player("bl",iL_Yazi1),iL_Miktar;
	iL_Miktar= str_to_num(iL_Yazi2);
	client_print_color(0,0,"^4[ ^3%n ^4] ^1adli admin ^4[ ^3%n ^4] ^1adli kisiye ^4[ ^3%i GP ^4] ^1verdi^4.",iP_ID,iP_UID,iL_Miktar);
	iL_Int[iP_UID][iL_Money] += iL_Miktar;
	return PLUGIN_CONTINUE;
}
@pYazma(iP_ID) {
    if(!iL_Bools[iP_ID][iL_Ghost] && !is_user_alive(iP_ID)) {
		new iL_Yazi[16];
		read_args(iL_Yazi, charsmax(iL_Yazi));
		remove_quotes(iL_Yazi);
		if(equali(iL_Yazi,"/gm")) { 
			@pReControl(iP_ID);
		}
	}
    if(iL_Bools[iP_ID][iL_Ghost]) {
		new iL_Yazi[16];
		read_args(iL_Yazi, charsmax(iL_Yazi));
		remove_quotes(iL_Yazi);
		if(equali(iL_Yazi,"/gm")) {
			@pDirekActir(iP_ID);
		}
		else client_print_color(iP_ID, iP_ID, "%s ^1Hayaletler yazi ^3yazamaz^1!",SayTag);
		return PLUGIN_HANDLED;
	}
    return PLUGIN_CONTINUE;
}
@pOldur(iP_TaskID) {
	new iP_ID = (iP_TaskID - 5531);
	if(is_user_connected(iP_ID) && !is_user_alive(iP_ID)) send_ScoreAttrib(iP_ID,DEAD_FLAG);
}
@pAyarladin(iP_ID) {
	new TASK_ID = (iP_ID - 13131);
	if(is_user_connected(TASK_ID))
	send_ScoreAttrib(TASK_ID,DEAD_FLAG);
}
@pDeath() {
	set_task(0.5,"@pAyarladin",read_data(2)+13131);
	static id;
	new Players[32], NumAll, Num;
	get_players(Players, NumAll, "ae", "TERRORIST");
	for(new i; i < NumAll; i++) { 
		id = Players[i];
		if(iL_Bools[id][iL_Ghost]) Num++;
	}
	new NumAllNew = NumAll - Num;
	if(NumAllNew == 1) @LRAtiliyor(),client_print_color(0, 0, "%s ^1LR atilacagi icin tum hayaletler ^3olduruldu^1!",SayTag);
}
@LRAtiliyor() {
	static id;
	new Players[32], NumAll;
	get_players(Players, NumAll); 
	for(new i; i < NumAll; i++){
		id = Players[i]; 
		if(iL_Bools[id][iL_Ghost]) {
			iL_LROpen = true; user_silentkill(id);
		}
	}
}
@pYonVer(iP_ID) set_task(0.3,"@pMainShop",iP_ID+1555);
@pDirekActir(iP_ID) @pMainShop(iP_ID+1555);
@showStatus(iP_ID) {
	if(!is_user_bot(iP_ID) && is_user_connected(iP_ID))  {
		new pid = read_data(2);
		if(iL_Bools[pid][iL_Ghost]) return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
@pTakeDMG(const pVictim, pInflictor, pAttacker, Float:flDamage, bitsDamageType) {
	if(!(0 < pAttacker  < 33)){
    return HC_CONTINUE;
	}
	if(pVictim == pAttacker) {
		return HC_CONTINUE;
	}
	if (iL_Bools[pAttacker][iL_Ghost]) {
		return HC_SUPERCEDE;
	}
	if (iL_Bools[pVictim][iL_Ghost]) {
		return HC_SUPERCEDE;
	}
	return HC_CONTINUE;
}
@RoundEnd() {
	for(new iP_ID = 1; iP_ID <= MaxClients; iP_ID++) {
		if(is_user_connected(iP_ID) && is_user_alive(iP_ID)){
		if(iL_Bools[iP_ID][iL_Ghost]) user_silentkill(iP_ID);
		@pCloseGhost(iP_ID); iL_Rocket = false,iL_LROpen = false,iL_Int[iP_ID][iL_Money] += 4;
		}
	}
}
@pKilled(const pVictim, pAttacker, iGib) {
	if(!(0 < pAttacker  < 33)){
    return;
	}
	if(!iL_Bools[pAttacker][iL_Ghost] && get_user_team(pVictim) == 1 && !is_user_bot(pVictim)) set_task(1.0,"@pReControl",pVictim);
	else iL_Bools[pAttacker][iL_Ghost] = false;send_ScoreAttrib(pVictim,DEAD_FLAG);
}
@pSpawn(const iP_ID) {
	if(!iL_Bools[iP_ID][iL_Revived] && is_user_alive(iP_ID)) {
		@pCloseGhost(iP_ID);
		set_task(1.0,"@pCloseVisibility",iP_ID+1707);
		iL_Bools[iP_ID][iL_Revived] = false;
	}
	if(iL_Bools[iP_ID][iL_Ghost]) send_ScoreAttrib(iP_ID,DEAD_FLAG);
	iL_Bools[iP_ID][iL_Revived] = false;
	if(iL_LROpen && iL_Bools[iP_ID][iL_Ghost] && is_user_alive(iP_ID)) user_silentkill(iP_ID);
}
@canlandir(TASKID) {
	new iP_ID = TASKID - 431;
	if(is_user_connected(iP_ID)) send_ScoreAttrib(iP_ID,0);
}
@pCloseVisibility(const iTaskID){
	new iPlayer = iTaskID-1707;
	set_entvar(iPlayer,var_solid, SOLID_SLIDEBOX);
	set_entvar(iPlayer, var_effects, EF_FORCEVISIBILITY);
}
@pCloseGhost(const iP_ID) {
	if(is_user_alive(iP_ID) && is_user_connected(iP_ID)) {
		iL_Bools[iP_ID][iL_Ghost] = false;
		set_entvar(iP_ID, var_effects, EF_FORCEVISIBILITY);
		set_entvar(iP_ID,var_flags, get_entvar(iP_ID, var_flags) | FL_GODMODE);
		set_entvar(iP_ID,var_takedamage,DAMAGE_AIM);
		rg_set_user_footsteps(iP_ID, false);
		if(is_user_connected(iP_ID)) set_task(1.0,"@canlandir",iP_ID+431);
		send_ScoreAttrib(iP_ID,0);
		set_entvar(iP_ID,var_solid, SOLID_SLIDEBOX);
	}
}
@pOpenGhost(const iP_ID) {
	if(is_user_connected(iP_ID)) {
		iL_Bools[iP_ID][iL_Ghost] = true;
		iL_Bools[iP_ID][iL_Revived] = true;
		rg_round_respawn(iP_ID);
		rg_set_user_footsteps(iP_ID, true);
		set_entvar(iP_ID,var_flags, get_entvar(iP_ID, var_flags) & ~FL_GODMODE);
		set_entvar(iP_ID, var_effects, EF_NODRAW);
		rg_remove_all_items(iP_ID);
		set_entvar(iP_ID,var_solid, SOLID_NOT);
		set_task(1.4,"@pMainShop",iP_ID+1555);
		set_task(0.3,"@GodOn",iP_ID+231);
	}
}
@GodOn(iP_ID) {
	iP_ID -= 231;
	if(is_user_connected(iP_ID)) 
		set_entvar(iP_ID,var_takedamage,DAMAGE_NO);
}
@pIntihar(iP_ID) {
	if(iL_Bools[iP_ID][iL_Ghost]) return FMRES_SUPERCEDE;
	if(!iL_Bools[iP_ID][iL_Ghost] && get_user_team(iP_ID) == 1) @pReControl(iP_ID);
	return FMRES_IGNORED;
}
@pEmitS( const iP_ID, Channel, defaultSound[ ]) {
	static iButtons, iButtonsCheck;
	iButtons = get_uc( 0, UC_Buttons );
	iButtonsCheck = get_entvar( iP_ID, var_oldbuttons );
	if ( equal ( defaultSound, "common/wpn_denyselect.wav" ) && iL_Bools[iP_ID][iL_Ghost]) {
		if ( ( iButtons & IN_USE ) && !( iButtonsCheck & IN_USE ) ) {
		}
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}
@pCmdStart(const iP_ID, uc_handle, seed){
	if(iL_Bools[iP_ID][iL_Ghost] && get_entvar(iP_ID,var_gravity) == -0.50) { user_silentkill(iP_ID);iL_Rocket = true; }
	static iButtons, iButtonsCheck;
	if(iL_Bools[iP_ID][iL_Ghost]) {
		if(get_entvar( iP_ID, var_flags ) & FL_INWATER || get_entvar( iP_ID, var_flags ) & FL_WATERJUMP ){
			set_task(0.5,"@pOldur",iP_ID+5531);
			client_print_color(iP_ID, iP_ID, "%s ^1Hayalet oldugunuzda ^3su ve zehir gibi yerlere ^4girmek yasaktir^1!",SayTag);
			client_print_color(iP_ID, iP_ID, "%s ^1Bu yuzden ^3olduruldunuz^1!",SayTag);
			user_silentkill(iP_ID);
		}
	}
	iButtons = get_uc( 0, UC_Buttons );iButtonsCheck = pev( iP_ID, pev_oldbuttons );
	if (iL_Bools[iP_ID][iL_Ghost] && ( iButtons & IN_USE ) && !( iButtonsCheck & IN_USE ) ) 
		return PLUGIN_HANDLED;
	if(iL_Bools[iP_ID][iL_Ghost]) {
		new Buttons; Buttons = get_uc(uc_handle,UC_Buttons);
		Buttons &= ~IN_ATTACK;set_uc( uc_handle , UC_Buttons , Buttons ); 
		Buttons &= ~IN_ATTACK2;set_uc( uc_handle , UC_Buttons , Buttons ); 
		Buttons &= ~IN_USE;set_uc( uc_handle , UC_Buttons , Buttons ); 
		Buttons &= ~IN_RELOAD;set_uc( uc_handle , UC_Buttons , Buttons );
		return FMRES_SUPERCEDE;
	}	
	return PLUGIN_HANDLED;
}
@pTouchWp(const iL_Ent, const iP_ID) {
	if(iL_Bools[iP_ID][iL_Ghost]) {
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
@pCtChoose(const iP_ID){
	new ad[32],sznum[6];
	new menu = menu_create("\d[ \y- \rHayalet Mod\y- \d] \d| \wIslem \wIcin \yCt \wSecin","@pCtChoose_");
	for(new i = 1;i<=MaxClients;i++){
		if(is_user_connected(i) && get_user_team(i) == 2 && is_user_alive(i)) {
			num_to_str(i,sznum,5);get_user_name(i,ad,31);menu_additem(menu,ad,sznum);
		}
	}
	menu_display(iP_ID,menu, 0);
	return PLUGIN_HANDLED;
}
@pCtChoose_(iP_ID,menu,item) {
	if(item == MENU_EXIT || !IsCanUse(iP_ID,true,false,true,true,true,true,true)){ menu_destroy(menu);return PLUGIN_HANDLED; }
	new iData[6],tid,pPara = iL_Int[iP_ID][iL_Choosing]+2;
	menu_item_getinfo(menu, item, _, iData, charsmax(iData));
	tid = str_to_num(iData);
	switch(iL_Int[iP_ID][iL_Choosing]) {
		case 1:{
			@DroppedWp(tid);
			iL_Int[iP_ID][iL_Money] -= iL_Cvars[pPara];
			client_print_color(0, 0, "%s ^3%n ^1adli oyuncu ^3%n ^1adli CT'yi ^4disarmladi!",SayTag,iP_ID,tid);
		}
		case 2:{
			@BuryPlayer(tid);
			iL_Int[iP_ID][iL_Money] -= iL_Cvars[pPara];
			set_task(5.5,"@pKaldir",tid+444);
			client_print_color(0, 0, "%s ^3%n ^1adli oyuncu ^3%n ^1adli CT'yi ^4gomdu!",SayTag,iP_ID,tid);
		}
	}
	menu_destroy(menu);return PLUGIN_HANDLED;
}
@pKaldir(tid) {
	new iP_ID = tid-444;
	if(is_user_connected(iP_ID)) {
		new Float: flOrigin[3];get_entvar(iP_ID, var_origin, flOrigin); flOrigin[2] += 35.0;set_entvar(iP_ID,var_origin,flOrigin);
		client_print_color(0, 0, "%s ^1CT geri kaldirildi!",SayTag);
	}
}
@BuryPlayer(tid) {
	new Float: flOrigin[3];get_entvar(tid, var_origin, flOrigin); flOrigin[2] -= 35.0;
	set_entvar(tid,var_origin,flOrigin);
}
@DroppedWp(tid) {
	new szVictimName[32],iWeapons[32], iWeapon, szWeaponName[32];
	get_user_name(tid, szVictimName, charsmax(szVictimName));
	get_user_weapons(tid, iWeapons, iWeapon);
	for(new i = 0; i < iWeapon; i++) { 
		get_weaponname(iWeapons[i], szWeaponName, charsmax(szWeaponName));engclient_cmd(tid, "drop", szWeaponName);
	}
	rg_give_item(tid, "weapon_knife");
}
@elektrikAc() set_lights("#OFF");
@Sarsinti(TaskID) {
	for(new id = 1; id < MaxClients; id++) {
		if(is_user_connected(id) && is_user_alive(id)) {
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), {0,0,0}, id);  
			write_short(0xFFFF);write_short(1<<13);write_short(0xFFFF); message_end();
		}
	}
}
@DepremiBitir(TaskID) { remove_task(4701);remove_task(TaskID); }
@UnStuck (const id){
        new Float:f_MinFrequency = 4.0;
        new Float:f_ElapsedCmdTime = get_gametime () - LastCmdTime[id];
        if ( f_ElapsedCmdTime < f_MinFrequency ) {
        	client_print_color(id, id, "%s ^1Kendini kaldirmak icin ^4[ ^3%.1f ^4] ^1saniye beklemen gerekiyor!",SayTag,f_MinFrequency - f_ElapsedCmdTime);
        	return PLUGIN_HANDLED;
        }
        LastCmdTime[id] = get_gametime ();
        new i_Value;
        if ( ( i_Value = UTIL_UnstickPlayer ( id, 32, 128 ) ) != 1 ){
            switch ( i_Value ){
                case 0  : client_print_color(id, id, "%s ^1Couldn't find a free spot to move you too.",SayTag);
                case -1 : client_print_color(id, id, "%s ^1Oluler kendini kaldiramaz.",SayTag);
            }
        }
        return PLUGIN_CONTINUE;
}
@set_velo(iP_ID,Float:velocity[3]) {
	return set_entvar(iP_ID,var_velocity,velocity);
}
public client_disconnected(iP_ID) {
	iL_Int[iP_ID][iL_Money] = 0,remove_task(iP_ID+1555),remove_task(iP_ID+13131),remove_task(iP_ID+5531),remove_task(iP_ID+231);
}
public client_putinserver(iP_ID) set_task(0.5,"@pOldur",iP_ID+5531);
public client_impulse (iP_ID, impulse) {
	if (impulse == 201){
		if(iL_Bools[iP_ID][iL_Ghost]){
			client_print_color(iP_ID, iP_ID, "%s ^1Hayaletler spray basamaz!",SayTag);
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}
@Flying(const iP_ID) {
	if(!iL_Bools[iP_ID][iL_Ghost]) return;
	if(!iL_Bools[iP_ID][iL_Ghost] && !iL_Bools[iP_ID][iL_HookOn]) return;
	new Float:Velocity[3];
	velocity_by_aim(iP_ID, 1500, Velocity);
	set_entvar(iP_ID, var_velocity, Velocity);
	return;
}
@PreThink(const iP_ID) {
	if(is_user_alive(iP_ID) && is_user_connected(iP_ID) && iL_Bools[iP_ID][iL_Ghost]) {
		set_entvar(iP_ID, var_effects, get_entvar(iP_ID,var_effects) | EF_NODRAW);
		if(get_member(iP_ID,m_flFallVelocity) >= 350.0) { iL_Bools[iP_ID][iL_Falling] = true; }
		else { iL_Bools[iP_ID][iL_Falling] = false; }
	}
	return HC_CONTINUE;
}
@PostThink(const iP_ID) {
	if(is_user_alive(iP_ID) && is_user_connected(iP_ID) && iL_Bools[iP_ID][iL_Ghost]) {
		if(iL_Bools[iP_ID][iL_Falling]) { set_entvar(iP_ID, var_watertype, -3); }
	}
}
public msg_ScoreAttrib(msg_type, msg_dest, target) {
	new flags = get_msg_arg_int(2);
	if(flags & DEAD_FLAG) set_msg_arg_int(2, 0, flags & ~DEAD_FLAG);
	return PLUGIN_CONTINUE;
}
UTIL_UnstickPlayer ( const id, const i_StartDistance, const i_MaxAttempts ){
    if ( !is_user_alive ( id ) )  return -1;	
    static Float:vf_OriginalOrigin[ Coord_e ], Float:vf_NewOrigin[ Coord_e ];
    static i_Attempts, i_Distance;
    pev ( id, pev_origin, vf_OriginalOrigin );
    i_Distance = i_StartDistance;
    client_print_color(id, id, "%s ^1Bulundugun yerden kurtarildin!",SayTag);
    while ( i_Distance < 1000 ){
    i_Attempts = i_MaxAttempts;
    while ( i_Attempts-- ){
	    vf_NewOrigin[ xx ] = random_float ( vf_OriginalOrigin[ xx ] - i_Distance, vf_OriginalOrigin[ xx ] + i_Distance );
	    vf_NewOrigin[ yy ] = random_float ( vf_OriginalOrigin[ yy ] - i_Distance, vf_OriginalOrigin[ yy ] + i_Distance );
	    vf_NewOrigin[ zz ] = random_float ( vf_OriginalOrigin[ zz ] - i_Distance, vf_OriginalOrigin[ zz ] + i_Distance );
	    engfunc ( EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, GetPlayerHullSize ( id ), id, 0 );
	    if(get_tr2 ( 0, TR_InOpen ) && !get_tr2 ( 0, TR_AllSolid ) && !get_tr2 ( 0, TR_StartSolid ) ){
	    	engfunc ( EngFunc_SetOrigin, id, vf_NewOrigin );
	        return 1;
	    }
	}
    i_Distance += i_StartDistance;
    }
    return 0;
} 
send_ScoreAttrib(iP_ID, flags) {
	message_begin(MSG_ALL, gmsgScoreAttrib, _, 0); write_byte(iP_ID); write_byte(flags); message_end();
}
bool:IsCanUse(const iP_ID, const bool:iConnect, const bool:iAlive ,const bool:iGhost, const bool:iLROpen, const bool:iLast,const bool:iGodmode,const bool:iRocket ) {
	if(iConnect && !is_user_connected(iP_ID)) {
		return false;
	}
	if(iAlive && !is_user_alive(iP_ID)) {
		client_print_color(iP_ID, iP_ID, "%s ^1Oluyken bu islemi yapamazsin!",SayTag);
		return false;
	}
	if(iGhost && !iL_Bools[iP_ID][iL_Ghost]) {
		client_print_color(iP_ID, iP_ID, "%s ^1Bu islemi yanlizca hayaletler yapabilir!",SayTag);
		return false;
	}
	if(iLROpen && iL_LROpen) {
		client_print_color(iP_ID, iP_ID, "%s ^1LR atilirken bu islemi yapamazsiniz!",SayTag);
		return false;
	}
	if(iLast) {
		new Players[32], AliveNums;
		get_players(Players, AliveNums, "ae", "TERRORIST");
		if(AliveNums == 1) {
			client_print_color(iP_ID, iP_ID, "%s ^1Sona 1 kisi kalinca bu islemi yapamazsin!",SayTag);
			return false;
		}
	}
	if(iGodmode && IsGodOn()) {
		client_print_color(iP_ID, iP_ID, "%s ^1God varken bu islemi yapamazsin!",SayTag);
		return false;
	}
	if(iRocket && iL_Rocket) {
		client_print_color(iP_ID, iP_ID, "%s ^1Roket atilirken bu islemi yapamazsin!",SayTag);
		return false;
	}
	return true;
}
bool:IsGodOn() {
	new bir=0,iki=0,players[32],inum; get_players(players,inum,"acehi","CT");
	for(new i=0; i<inum; i++) {
		bir++;
		if(!get_entvar(players[i], var_takedamage)) iki++;
	}
	return (bir > 0 && iki > 0) ? true:false;
}
