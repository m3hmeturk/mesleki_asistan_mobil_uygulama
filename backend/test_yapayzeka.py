import requests

# Sunucumuzun yapay zeka ile konuştuğu adres
url = "http://127.0.0.1:5000/api/chat"

# Asistana göndereceğimiz ilk mesajımız
gonderilecek_veri = {
    "message": "Merhaba, ben sorun çözmeyi ve bilgisayarlarla uğraşmayı çok seviyorum. Bana hangi mesleği önerirsin?"
}

print("Yapay zekaya mesaj gönderiliyor, lütfen bekleyin...")

# Mesajı sunucumuza (POST metoduyla) yolluyoruz
cevap = requests.post(url, json=gonderilecek_veri)

# Gelen cevabı ekrana yazdırıyoruz
print("\n--- ASİSTANDAN GELEN CEVAP ---")
print(cevap.json()['ai_response'])