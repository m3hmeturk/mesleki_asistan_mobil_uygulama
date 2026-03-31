import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from openai import OpenAI  # OpenAI kütüphanesini kullanıyoruz
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
    # Veritabanına bağlanıyoruz
    mongo_client = MongoClient(os.getenv("MONGO_URI"), tls=True, tlsAllowInvalidCertificates=True)
    
    # Sunucuya "ping" atıp bağlantıyı test ediyoruz
    mongo_client.admin.command('ping')
    print("🚀 HARİKA! MongoDB'ye başarıyla bağlandın!")
    
    # Veritabanı ve Koleksiyon (Tablo) tanımlamaları
    db = mongo_client["MeslekiAsistanDB"] 
    users_collection = db["kullanicilar"] 
    # YENİ: Mülakat sonuçları için yeni bir koleksiyon (tablo) tanımlıyoruz
    interviews_collection = db["mulakatlar"] 
    
except Exception as e:
    print("❌ MongoDB Bağlantı Hatası:", e)


# --- OPENAI BAĞLANTISI ---
# Groq yerine artık OpenAI kullanıyoruz
openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# ==========================================
# KULLANICI KAYIT API'Sİ
# ==========================================
@app.route('/api/kayit', methods=['POST'])
def kullanici_kayit():
    try:
        data = request.json
        uid = data.get('uid')
        ad = data.get('ad')
        email = data.get('email')

        if not uid or not email:
            return jsonify({"hata": "Eksik bilgi gönderildi"}), 400

        mevcut_kullanici = users_collection.find_one({"uid": uid})
        
        if mevcut_kullanici:
            return jsonify({"mesaj": "Kullanıcı zaten veritabanında mevcut."}), 200

        yeni_kullanici = {
            "uid": uid,
            "ad": ad,
            "email": email,
            "kayit_tarihi": datetime.datetime.utcnow()
        }
        
        users_collection.insert_one(yeni_kullanici)
        print(f"✅ YENİ KULLANICI KAYDEDİLDİ: {ad} ({email})")

        return jsonify({"mesaj": "Kullanıcı başarıyla MongoDB'ye kaydedildi!"}), 201

    except Exception as e:
        print("❌ Kayıt Hatası:", e)
        return jsonify({"hata": str(e)}), 500


# ==========================================
# YENİ: MÜLAKAT SONUCUNU KAYDETME API'Sİ
# ==========================================
@app.route('/api/save_interview', methods=['POST'])
def save_interview():
    try:
        data = request.json
        # Flutter'dan gelecek paket: uid, pozisyon, karne/rapor
        uid = data.get('uid')
        position = data.get('position')
        report = data.get('report')

        if not uid or not report:
            return jsonify({"hata": "Veri eksik"}), 400

        yeni_mulakat = {
            "uid": uid,
            "position": position,
            "report": report,
            "tarih": datetime.datetime.utcnow()
        }

        interviews_collection.insert_one(yeni_mulakat)
        return jsonify({"status": "success", "message": "Mülakat başarıyla kaydedildi!"}), 201

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


# ==========================================
# SOHBET API'Sİ (OpenAI GPT-4o-mini ile güncellendi)
# ==========================================
@app.route('/api/chat', methods=['POST'])
def chat_with_ai():
    try:
        data = request.get_json()
        kullanici_mesaji = data.get("message", "")

        if not kullanici_mesaji:
            return jsonify({"error": "Lütfen bir mesaj gönderin."}), 400

        # OpenAI üzerinden cevap üretiyoruz
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini", # En hızlı ve ucuz model
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
        )
        
        response_text = response.choices[0].message.content
        return jsonify({"ai_response": response_text})

    except Exception as e:
        print("❌ Chat Hatası:", e)
        return jsonify({"error": str(e)}), 500


@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "success", "message": "Sunucu çalışıyor!"})


# ==========================================
# SUNUCUYU ÇALIŞTIRAN KOD
# ==========================================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)