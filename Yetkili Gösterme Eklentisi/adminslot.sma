/* Sublime AMXX Editor v3.2 */

#include <amxmodx>
new const szTag[] = "WebAilesi";
new const szFlags[3][][] = {
	{"Yöneticiler",ADMIN_RCON},
	{"Adminler",ADMIN_BAN},
	{"Slotlar",ADMIN_RESERVATION}
}
public plugin_init() {
	register_plugin("Yeni Plugin", "1.0", "PawNod")

	register_clcmd("say /slot","@ShowSlots");
	register_clcmd("say /admins","@ShowAdmins");
	register_clcmd("say /yoneticiler","@ShowYonetici")
}
@ShowSlots(const iPlayer) {
	static szString[512];
	for(new i = 1; i <= get_maxplayers();i++) {
		if(is_user_connected(i) && get_user_flags(i) & szFlags[2][1][0]) {
			add(szString,charsmax(szString),fmt("%n ",i))
		}
	}
	strlen(szString) > 0 ?
	client_print_color(iPlayer, iPlayer,"^3[ ^4%s ^3] ^1Aktif Slotlarımız: ^4%s",szTag,szString):
	client_print_color(iPlayer, iPlayer,"^3[ ^4%s ^3] ^1Aktif Slotumuz ^3Bulunmamaktadır^1!",szTag)
}
@ShowAdmins(const iPlayer) {
	static szString[512];
	for(new i = 1; i <= get_maxplayers();i++) {
		if(is_user_connected(i) && get_user_flags(i) & szFlags[1][1][0]) {
			add(szString,charsmax(szString),fmt("%n ",i))
		}
	}
	strlen(szString) > 0 ?
	client_print_color(iPlayer, iPlayer,"^3[ ^4%s ^3] ^1Aktif Adminlerimiz: ^4%s",szTag,szString):
	client_print_color(iPlayer, iPlayer,"^3[ ^4%s ^3] ^1Aktif Adminimiz ^3Bulunmamaktadır^1!",szTag)
}
@ShowYonetici(const iPlayer) {
	static szString[512];
	for(new i = 1; i <= get_maxplayers();i++) {
		if(is_user_connected(i) && get_user_flags(i) & szFlags[0][1][0]) {
			add(szString,charsmax(szString),fmt("%n ",i))
		}
	}
	strlen(szString) > 0 ?
	client_print_color(iPlayer, iPlayer,"^3[ ^4%s ^3] ^1Aktif Yöneticilerimiz: ^4%s",szTag,szString):
	client_print_color(iPlayer, iPlayer,"^3[ ^4%s ^3] ^1Aktif Yöneticimiz ^3Bulunmamaktadır^1!",szTag)
}