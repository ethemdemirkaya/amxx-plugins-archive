/* Sublime AMXX Editor v3.2 */

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#pragma semicolon 1

const cMaxMayin = 7;

native bool:FClassnameIs(const entityIndex, const className[]);
native create_entity(const szClassname[]);
native Float:entity_range(ida, idb);

new szwMineModel[] = "models/w_mine.mdl";

new iModelIndex,ExpIndex,bool:UserHasMine[33],iToplamMayin,iCvars[2];

public plugin_precache() {
	iModelIndex = precache_model(szwMineModel);
	ExpIndex = precache_model("sprites/zerogxplode.spr");
}
public plugin_init() {
	register_plugin("Mine Plugin", "1.0", "PawNod");

	register_clcmd("+dropmine","@DropMine");

	bind_pcvar_num(create_cvar("Mayin_Hasar","100"), iCvars[0]);
	bind_pcvar_num(create_cvar("Mayin_Gorunmezlik","1"), iCvars[1]);		//1 Ise Ct Takimi Lazeri Goremez

	register_message(get_user_msgid("DeathMsg"), "@DeathMessage");
	register_forward(FM_AddToFullPack, "@AddToFullPack", 1);
	RegisterHam(Ham_Touch,"info_target","@MineTouched");
}
public plugin_natives() {
	register_native("JB_Give_Mine","@GiveMine");
}
public client_putinserver(iPlayer) {
	UserHasMine[iPlayer] = false;
}
@GiveMine() {
	new nPlayer = get_param(1); 
	UserHasMine[nPlayer] = true;
}
@DeathMessage(msg_id, msg_dest, msg_ent) {
	new szWeapon[64];
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon));

	if (strcmp(szWeapon, "worldspawn"))
		return PLUGIN_CONTINUE;
	
	new id = get_msg_arg_int(1);
	new iEntity = get_pdata_cbase(id, 373);
	
	if (!pev_valid(iEntity))
		return PLUGIN_CONTINUE;

	set_msg_arg_string(4, "mayin");
	return PLUGIN_CONTINUE;
}
@DropMine(const iPlayer) {
	if(UserHasMine[iPlayer]) {
		@CreateMine(iPlayer);
	}
	else 
		client_print_color(iPlayer, iPlayer, "Lütfen önce mayin satin alin!");

	return PLUGIN_HANDLED;
}

@AddToFullPack( es_handle, e, ent, host, hostflags, player, pset ) {
	if(ent){
		if(is_user_alive(host) && get_user_team(host) == 2 && FClassnameIs(ent,"NewMineClass") && iCvars[1]==1){
			set_es( es_handle, ES_Origin, { 999999999.0, 999999999.0, 999999999.0 } );
		}
	}
}
@CreateMine(const iPlayer) {
	if(iToplamMayin > cMaxMayin ) {
		client_print_color(iPlayer, iPlayer, "Oyunda maximum %i tane mayin bulunabilir!",cMaxMayin);
		return PLUGIN_HANDLED;
	}
	new iOrigin[3],Float:fOrigin[3],iEntity = create_entity( "info_target" ); 
	set_pev(iEntity,pev_classname,"NewMineClass");
	set_pev(iEntity,pev_modelindex,iModelIndex);
	set_pev(iEntity,pev_model,szwMineModel);
	set_pev(iEntity,pev_solid, SOLID_TRIGGER);
	set_pev(iEntity,pev_takedamage,DAMAGE_YES);
	set_pev(iEntity,pev_movetype,MOVETYPE_PUSHSTEP);
	set_pev(iEntity,pev_iuser4,iPlayer);
	set_pev(iEntity,pev_health,70.0);
	get_user_origin(iPlayer,iOrigin);
	IVecFVec(iOrigin, fOrigin);
	set_pev(iEntity,pev_origin,fOrigin);
	SetSizeTaret(iEntity);
	UserHasMine[iPlayer] = false;
	iToplamMayin++;
	return PLUGIN_HANDLED;
}
@MineTouched(const tEntity,const tToucher) {
	if(!is_user_connected(tToucher)) return;
	if(get_user_team(tToucher) == 1) return;
	if(!FClassnameIs(tEntity,"NewMineClass")) return;
	new Float:fOrigin[3];
	pev(tEntity,pev_origin,fOrigin);
	Create_Explosion(fOrigin);
	rg_remove_entity(tEntity);
	GiveDamageMine(tEntity);
}
GiveDamageMine(const tEntity) {
	new iOwner = pev(tEntity,pev_iuser4);
	for(new i = 1; i <= MaxClients; i++) { 
		if(is_user_connected(i) && is_user_alive(i) && entity_range(i, tEntity) <= 100.0 && get_user_team(i) != 1) { 
			ExecuteHam(Ham_TakeDamage, i, 0, iOwner, float(iCvars[0]), (1<<24));
		}
	}
}
SetSizeTaret(const ent){
	new Float:mins[3],Float:maxs[3],Float:size[3];
	mins[0] = -5.0,mins[1] = -5.0,mins[2] = 0.0;
	maxs[0] = 5.0,maxs[1] = 5.0,maxs[2] = 5.0;
	set_pev(ent,pev_mins,mins);
	set_pev(ent,pev_maxs,maxs);
	size[0] = (xs_fsign(mins[0]) * mins[0]) + maxs[0];
	size[1] = (xs_fsign(mins[1]) * mins[1]) + maxs[1];
	size[2] = (xs_fsign(mins[2]) * mins[2]) + maxs[2];
	set_pev(ent, pev_size, size);
}
xs_fsign(Float:num){
	return (num < 0.0) ? -1 : ((num == 0.0) ? 0 : 1);
}
rg_remove_entity(const ent){
	if(pev_valid(ent)){
		set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
		set_pev(ent,pev_nextthink,get_gametime());
	}
}
stock Create_Explosion(Float:origin_[3]) {
	new origin[3];
	FVecIVec(origin_, origin);
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, origin);
	write_byte(TE_EXPLOSION);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_short(ExpIndex);
	write_byte(random_num(0, 20) + 50);
	write_byte(12);
	write_byte(TE_EXPLFLAG_NONE);
	message_end();
}