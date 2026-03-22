import requests

url = "http://127.0.0.1:5000/api/chat"

print("="*50)
print("🤖 Mesleki Farkındalık Asistanı'na Hoş Geldin!")
print("(Sohbeti bitirmek için 'çıkış' yazıp Enter'a basabilirsin)")
print("="*50)

# Sonsuz bir döngü başlatıyoruz, sen çıkış diyene kadar devam edecek
while True:
    # Klavyeden senin yazmanı bekler
    kullanici_mesaji = input("\nSen: ")
    
    # Çıkış kelimesi yazarsan programı kapatır
    if kullanici_mesaji.lower() in ['çıkış', 'q', 'exit', 'cikis']:
        print("Asistan kapatılıyor... Görüşmek üzere!")
        break
    
    # Mesaj boşsa uyarı verir
    if not kullanici_mesaji.strip():
        continue

    # Senin yazdığın mesajı paketleyip Flask sunucumuza yolluyoruz
    gonderilecek_veri = {"message": kullanici_mesaji}
    
    try:
        cevap = requests.post(url, json=gonderilecek_veri)
        
        # Eğer sunucudan başarılı (200) cevap gelirse ekrana yazdırır
        if cevap.status_code == 200:
            asistanin_cevabi = cevap.json()['ai_response']
            print(f"\n🤖 Asistan:\n{asistanin_cevabi}")
            print("\n" + "-"*50)
        else:
            print(f"\nBir hata oluştu: {cevap.json()}")
            
    except Exception as e:
        print(f"\nSunucuya bağlanılamadı. app.py'nin çalıştığından emin ol! Hata: {e}")