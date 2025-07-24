# AMX Mod X Eklenti Arşivim

![AMX Mod X Logo](https://www.amxmodx.org/images/logo.png)

Bu repo, Counter-Strike 1.6 sunucuları için yıllar içinde geliştirdiğim veya düzenlediğim tüm AMX Mod X eklentilerinin bir koleksiyonudur. Burada hem eklentilerin kaynak kodlarını (`.sma`) hem de kullanıma hazır, derlenmiş hallerini (`.amxx`) bulabilirsiniz.

---

## 🚀 Amacı

Bu projenin temel amacı, geliştirdiğim tüm eklentileri tek bir çatı altında toplayarak hem kendim için bir yedek oluşturmak hem de AMX Mod X topluluğuna katkıda bulunmaktır. Eklentilerin kaynak kodları, yeni geliştiricilere ilham vermesi ve mevcut eklentileri kendi sunucularına göre özelleştirmek isteyenlere yol göstermesi için açıktır.

---


## ⚙️ Kurulum

1.  İstediğiniz eklentinin klasörünü bulun.
2.  Klasör içindeki `addons` klasörünün içeriğini, kendi sunucunuzdaki `cstrike/addons` klasörüyle birleştirin. Dosyaları doğru yerlere kopyaladığınızdan emin olun.
3.  Sunucunuzdaki `cstrike/addons/amxmodx/configs/plugins.ini` dosyasını açın.
4.  Dosyanın en alt satırına yüklediğiniz eklentinin adını ekleyin. Örneğin:
    ```ini
    ; Custom - Eklentilerim
    plugin_adi.amxx
    ```
5.  Sunucunuza restart atın veya `amx_rcon changelevel <harita_adi>` komutu ile haritayı değiştirin.

---

## 💡 Katkıda Bulunma

Eklentilerde bir hata (bug) bulursanız veya bir özellik öneriniz varsa, lütfen GitHub'ın **Issues** bölümünü kullanarak bir bildirim oluşturun. Kod iyileştirmeleri için **Pull Request** göndermekten çekinmeyin!

---

## 📜 Lisans

Bu projede yer alan eklentilerin büyük bir kısmı [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html) altında lisanslanmıştır. Bazı eklentilerin kendilerine özel lisansları olabilir, lütfen ilgili eklentinin kaynak kodundaki lisans bilgilerini kontrol edin.