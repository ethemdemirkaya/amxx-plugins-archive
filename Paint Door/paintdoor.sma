/* Sublime AMXX Editor v3.2 */

#include <amxmodx>
#include <reapi>

new const szColors[][][] = {
	//{"Renk","Render ARM","Red","Green","Blue"},
	{"Kırmızı",100,200,0,0},
	{"Ateş",135,255,83,73},
	{"Turuncu",140,255,117,56},
	{"Açık Turuncu",120,255,174,66},
	{"Şeftali",140,255,207,171},
	{"Sarı",125,252,232,131},
	{"Limon Sarısı",100,254,254,34},
	{"Orman Yeşili",125,59,176,143},
	{"Açık Yeşil",135,197,227,132},
	{"Yeşil",100,0,150,0},
	{"Turkuaz",125,120,219,226},
	{"Bebek Mavisi",150,135,206,235},
	{"Gök Mavisi",90,128,218,235},
	{"Mavi",75,0,0,255},
	{"Mor",175,146,110,174},
	{"Pembe",150,255,105,180},
	{"Kırmızı 2",175,246,100,175},
	{"Kızıl Kahve",140,205,74,76},
	{"Taba",140,250,167,108},
	{"Açık Kahverengi",140,234,126,93},
	{"Kahverengi",165,180,103,77},
	{"Gri",175,149,145,140},
	{"Siyah",125,0,0,0},
	{"Beyaz",125,255,255,255}
};
public plugin_init() {
	register_plugin("Paint Door", "1.0", "PawNod")

	RegisterHookChain(RG_CSGameRules_RestartRound,"@PaintDoor",.post = true);
}
@PaintDoor() {
	new entFind,szTargetName[32],entFinded = 999;
	while((entFind = rg_find_ent_by_class(NULLENT, "func_door"))) {
		if(!equali(szTargetName,"")) continue;
		else{
			entFinded = entFind;
			break;
		} 
	}
	if(entFinded == 999 ) return;
	new Float:stColor[3],iRandom = random_num(0,sizeof(szColors)-1);
	stColor[0] = float(szColors[iRandom][2][0]);
	stColor[1] = float(szColors[iRandom][3][0]);
	stColor[2] = float(szColors[iRandom][4][0]);
	set_entvar(entFinded,var_solid,SOLID_BSP);
	set_entvar(entFinded,var_rendermode,kRenderTransColor);
	set_entvar(entFinded,var_rendercolor, stColor);
	set_entvar(entFinded,var_renderamt, Float:float(szColors[iRandom][1][0]));
}