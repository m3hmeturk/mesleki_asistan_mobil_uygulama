import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from groq import Groq
from dotenv import load_dotenv
from pymongo import MongoClient
import certifi
import datetime

# .env dosyasındaki gizli şifrelerimizi yüklüyoruz
load_dotenv()

app = Flask(__name__)
# Flutter'dan gelen isteklere izin veriyoruz
CORS(app)

# ==========================================
# MONGODB BAĞLANTISI
# ==========================================
try:
    # Veritabanına bağlanıyoruz (Değişken adını mongo_client yaptık)
    mongo_client = MongoClient(os.getenv("MONGO_URI"), tls=True, tlsAllowInvalidCertificates=True)
    
    # Sunucuya "ping" atıp bağlantıyı test ediyoruz
    mongo_client.admin.command('ping')
    print("🚀 HARİKA! MongoDB'ye başarıyla bağlandın!")
    
    # Veritabanı ve Koleksiyon (Tablo) tanımlamaları
    db = mongo_client["MeslekiAsistanDB"] # Veritabanımızın adı
    users_collection = db["kullanicilar"] # Kullanıcıların kaydedileceği klasör
    
except Exception as e:
    print("❌ MongoDB Bağlantı Hatası:", e)


# ==========================================
# YAPAY ZEKA (GROQ) BAĞLANTISI
# ==========================================
# Groq İstemcisini Başlatıyoruz (Çakışma olmaması için groq_client yaptık)
groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))


# ==========================================
# KULLANICI KAYIT API'Sİ (Flutter'dan buraya veri gelecek)
# ==========================================
@app.route('/api/kayit', methods=['POST'])
def kullanici_kayit():
    try:
        # 1. Flutter'dan gelen veriyi alıyoruz
        data = request.json
        uid = data.get('uid')
        ad = data.get('ad')
        email = data.get('email')

        # Eğer eksik bilgi varsa hata dön
        if not uid or not email:
            return jsonify({"hata": "Eksik bilgi gönderildi"}), 400

        # 2. Bu kullanıcı daha önce veritabanına eklenmiş mi kontrol et
        mevcut_kullanici = users_collection.find_one({"uid": uid})
        
        if mevcut_kullanici:
            return jsonify({"mesaj": "Kullanıcı zaten veritabanında mevcut."}), 200

        # 3. Kullanıcı yeniyse MongoDB'ye eklenecek şablonu oluştur
        yeni_kullanici = {
            "uid": uid,
            "ad": ad,
            "email": email,
            "kayit_tarihi": datetime.datetime.utcnow()
        }
        
        # 4. Veritabanına kaydet!
        users_collection.insert_one(yeni_kullanici)
        print(f"✅ YENİ KULLANICI KAYDEDİLDİ: {ad} ({email})")

        return jsonify({"mesaj": "Kullanıcı başarıyla MongoDB'ye kaydedildi!"}), 201

    except Exception as e:
        print("❌ Kayıt Hatası:", e)
        return jsonify({"hata": str(e)}), 500


# ==========================================
# DİĞER API UÇ NOKTALARI
# ==========================================
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "success", "message": "Sunucu çalışıyor!"})


# YENİ: Groq ile Konuşma Uç Noktası
@app.route('/api/chat', methods=['POST'])
def chat_with_ai():
    try:
        data = request.get_json()
        kullanici_mesaji = data.get("message", "")

        if not kullanici_mesaji:
            return jsonify({"error": "Lütfen bir mesaj gönderin."}), 400

        # Meta'nın zeki Llama 3 modelini kullanarak cevap üretiyoruz
        chat_completion = groq_client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": "Sen bir Mesleki Farkındalık Asistanısın. Kullanıcıya sıcak ve profesyonel bir dille kariyer tavsiyesi ver."
                },
                {
                    "role": "user",
                    "content": kullanici_mesaji
                }
            ],
            model="llama-3.3-70b-versatile",
        )
        
        # Gelen cevabın sadece metin kısmını alıyoruz
        response_text = chat_completion.choices[0].message.content

        return jsonify({"ai_response": response_text})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ==========================================
# SUNUCUYU ÇALIŞTIRAN KOD (KESİNLİKLE EN ALTTA OLMALI)
# ==========================================
if __name__ == '__main__':
    # host='0.0.0.0' sayesinde telefonlar bu sunucuya bağlanabilir
    app.run(host='0.0.0.0', port=5000, debug=True)