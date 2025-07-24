#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

new const szTag[] = "WebAilesi";

new const szAnimModel[] = "models/danset.mdl";

new const szAnimations[][] = {
	"Normal","Osbir 1","Osbir 2","Takla At","Ağla","Selam Ver",
	"Karşıdakini Kudurt","Karşıdakini Kudurt 2","Kas Gösterisi Yap","Otur 1","Otur 2","El Salla","Meditasyon","Nah","Kekoware TeyTey",
	"Şınav Çek","Maymun Dansı","Maksimum Kart","Bale","Isınma 1","Isınma 2","Disco 1","Disco 2","Disco 3"
};
enum _: PlayerDatas {
	ENT_CAM,
	ENT_MODEL,
	ENT_ANIM,
	ANIM_PLAYING
}
new iPlayerData[33][PlayerDatas],iEntity;
public plugin_precache() precache_model(szAnimModel);
public client_disconnected(iPlayer) @stopAnim(iPlayer);
public client_putinserver(iPlayer) {
	if(!iPlayerData[iPlayer][ENT_MODEL]) @CreateEntitys(iPlayer);
}
public plugin_init() {
	register_plugin("DansMenu", "1.0", "PawNod'");
	register_clcmd("say /dans","@DanceMenu");
	register_forward(FM_CmdStart, "@fwdCmdStart", 1);
	RegisterHam(Ham_Killed, "player", "@fwdPlayerKilled", 1);
	iEntity = engfunc(EngFunc_AllocString, "info_target");
}
@fwdPlayerKilled(iPlayer) @stopAnim(iPlayer);
@DanceMenu(const iPlayer, iPage) {
	if(isStuck(iPlayer)) return;
	if(!is_user_alive(iPlayer)) return;
	new izMenu = menu_create(fmt("\d[\yYeni Nesil \wDans Menü \d] - [ \y%s \d]",szTag), "@DanceMenu_");
	for(new i; i < sizeof(szAnimations);i++){
		menu_additem(izMenu,fmt("\d[ \r- \w%s \r- \d]",szAnimations[i][0]),"");
	}

	menu_setprop(izMenu, MPROP_EXITNAME, "\wKapat");
	menu_setprop(izMenu, MPROP_NEXTNAME, "\wSonraki Sayfa");
	menu_setprop(izMenu, MPROP_BACKNAME, "\yÖnceki Sayfa");
	menu_display(iPlayer, izMenu, iPage);
}
@DanceMenu_(const iPlayer,const iMenu, const iItem) {
	if(iItem == MENU_EXIT ) { menu_destroy(iMenu);return PLUGIN_HANDLED; }
	if(isStuck(iPlayer)) {menu_destroy(iMenu);return PLUGIN_HANDLED;}
	if(!is_user_alive(iPlayer)) {menu_destroy(iMenu);return PLUGIN_HANDLED;}
	new iData[6];
	menu_item_getinfo(iMenu, iItem, _, iData, charsmax(iData));
	@StartAnimation(iPlayer,iItem);
	@DanceMenu(iPlayer,iItem/7);
	//@DanceMenu(iPlayer);

	menu_destroy(iMenu);return PLUGIN_HANDLED;
}
@StartAnimation(const iPlayer,const iAnim) {
	new modelEnt = iPlayerData[iPlayer][ENT_MODEL] ,ent = iPlayerData[iPlayer][ENT_ANIM];
	set_pev(ent,pev_framerate,1.0);
	set_pev(ent,pev_sequence,iAnim);
	set_pev(ent,pev_gaitsequence,iAnim);
	new Float:origin[3], Float:mins[3];
	pev(iPlayer, pev_origin, origin);
	pev(iPlayer, pev_mins, mins);
	mins[0] = origin[0];
	mins[1] = origin[1];
	mins[2] += origin[2];
	set_pev(ent, pev_origin, mins);
	set_pev(modelEnt, pev_effects, 0);
	new model[64];
	get_user_info(iPlayer, "model", model, 63);
	format(model, 63, "models/player/%s/%s.mdl", model, model);
	engfunc(EngFunc_SetModel, modelEnt, model);
	set_pev(modelEnt, pev_body, pev(iPlayer, pev_body));
   	set_pev(modelEnt, pev_skin, pev(iPlayer, pev_skin));
   	set_pev(ent, pev_controller_0, 128);
   	set_pev(ent, pev_controller_1, 128);
   	pev(iPlayer, pev_angles, mins);
   	mins[0] = 0.0;
   	set_pev(ent, pev_angles, mins);
   	set_pev(ent, pev_v_angle, mins);
	engfunc(EngFunc_SetView, iPlayer, iPlayerData[iPlayer][ENT_CAM]);
   	iPlayerData[iPlayer][ANIM_PLAYING] = 1;
   	set_pev(iPlayer, pev_effects, EF_NODRAW);
}
@fwdCmdStart(iPlayer, uc, randseed) {
	if (is_user_alive(iPlayer) && iPlayerData[iPlayer][ANIM_PLAYING]){
		if (!get_uc(uc, UC_Buttons)){
			static Float:fOrigin[3], Float:fAngle[3], Float:origin[3];
			pev(iPlayer, pev_origin, origin );
			pev(iPlayer, pev_view_ofs, fOrigin);
			xs_vec_add(origin, fOrigin, origin);
			xs_vec_copy(origin, fOrigin);
			pev(iPlayer, pev_v_angle, fAngle);
			static Float:fVBack[3];
			angle_vector(fAngle, ANGLEVECTOR_FORWARD, fVBack);
			fOrigin[2] += 20.0;
			fOrigin[0] += (-fVBack[0] * 150.0);
			fOrigin[1] += (-fVBack[1] * 150.0);
			fOrigin[2] += (-fVBack[2] * 150.0);
			static tr;
			tr = 0;
			engfunc(EngFunc_TraceLine, origin, fOrigin, IGNORE_MONSTERS, iPlayer, tr);
			get_tr2(tr, TR_vecEndPos, fOrigin);
			free_tr2(tr);
			engfunc(EngFunc_SetOrigin, iPlayerData[iPlayer][ENT_CAM], fOrigin);
			set_pev(iPlayerData[iPlayer][ENT_CAM], pev_angles, fAngle);
      	}
		else @stopAnim(iPlayer);
	}
	return;
}
@stopAnim(iPlayer) {
	set_pev(iPlayerData[iPlayer][ENT_MODEL], pev_effects, EF_NODRAW);
	iPlayerData[iPlayer][ANIM_PLAYING] = 0;
	set_pev(iPlayer, pev_effects, 0);
	engfunc(EngFunc_SetView, iPlayer, iPlayer);
}
@CreateEntitys(const iPlayer) {
	new ent = engfunc(EngFunc_CreateNamedEntity, iEntity);
   	set_pev(ent, pev_rendermode, kRenderTransAdd);
   	set_pev(ent, pev_renderamt, 0.0);
   	set_pev(ent, pev_owner, iPlayer);
   	engfunc(EngFunc_SetModel, ent, szAnimModel);
   	iPlayerData[iPlayer][ENT_CAM] = ent;
   	ent = engfunc(EngFunc_CreateNamedEntity, iEntity);
	engfunc(EngFunc_SetModel, ent, szAnimModel);
	set_pev(ent,pev_movetype,MOVETYPE_FLY);
	set_pev(ent,pev_controller_1,63.75);
	iPlayerData[iPlayer][ENT_ANIM] = ent;
	ent = engfunc(EngFunc_CreateNamedEntity,iEntity);
	set_pev(ent,pev_movetype,MOVETYPE_FOLLOW);
	set_pev(ent,pev_aiment,iPlayerData[iPlayer][ENT_ANIM]);
	set_pev(ent,pev_effects,EF_NODRAW);
	iPlayerData[iPlayer][ENT_MODEL] = ent;
}
bool:isStuck(id) {
	static Float:Origin[3]; 
	pev(id, pev_origin, Origin);

	engfunc(EngFunc_TraceHull, Origin, Origin, IGNORE_MONSTERS, pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, 0, 0);

	return bool:get_tr2(0, TR_StartSolid);
}
stock xs_vec_copy(const Float:vecIn[], Float:vecOut[]) {
	vecOut[0] = vecIn[0];
	vecOut[1] = vecIn[1];
	vecOut[2] = vecIn[2];
}
stock xs_vec_add(const Float:in1[], const Float:in2[], Float:out[]) {
	out[0] = in1[0] + in2[0];
	out[1] = in1[1] + in2[1];
	out[2] = in1[2] + in2[2];
}