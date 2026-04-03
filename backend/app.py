import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from openai import OpenAI  # OpenAI kütüphanesini kullanıyoruz
from dotenv import load_dotenv
from pymongo import MongoClient
import certifi
import datetime
import json

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
# KULLANICI KAYIT API'Sİ (GELİŞTİRİLMİŞ)
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

        # --- YENİ VE GELİŞMİŞ KULLANICI ŞABLONU ---
        yeni_kullanici = {
            "uid": uid,
            "ad": ad,
            "email": email,
            "kayit_tarihi": datetime.datetime.utcnow(),
            
            # 1. Seviye ve XP Sistemi
            "level": {
                "current": 1,
                "title": "Çaylak",
                "xp": 0,
                "xp_for_next": 100
            },
            
            # 2. Esnek Test Sonuçları (6 Testin Şablonu)
            "test_results": {
                "kisilik": {"completed": False, "result": None},
                "meslek": {"completed": False, "result": None},
                "ingilizce": {"completed": False, "result": None},
                "liderlik": {"completed": False, "result": None},
                "calisma_ortami": {"completed": False, "result": None},
                "motivasyon": {"completed": False, "result": None}
            },
            
            # 3. Yetenek Radar Grafiği Puanları (Başlangıçta hepsi 0)
            "skill_scores": {
                "teknik": 0,
                "iletisim": 0,
                "liderlik": 0,
                "analitik": 0,
                "sosyal": 0
            },
            
            # 4. Oyunlaştırma ve Asistan Hafızası İçin Gerekli Olanlar
            "badges": [], # Kazanılan rozetlerin ID'leri buraya gelecek
            "selected_career": None, # Hedef meslek (Asistan ve Yol haritası için)
            "stats": {
                "total_chats": 0,
                "total_interviews": 0,
                "avg_interview_score": 0.0
            }
        }
        
        users_collection.insert_one(yeni_kullanici)
        print(f"✅ YENİ KULLANICI KAYDEDİLDİ: {ad} ({email}) - Altyapı Hazır!")

        return jsonify({"mesaj": "Kullanıcı başarıyla MongoDB'ye kaydedildi!"}), 201

    except Exception as e:
        print("❌ Kayıt Hatası:", e)
        return jsonify({"hata": str(e)}), 500

# ==========================================
# YENİ VE GELİŞMİŞ: MÜLAKAT KAYDETME & OYUNLAŞTIRMA API'Sİ
# ==========================================
@app.route('/api/save_interview', methods=['POST'])
def save_interview():
    try:
        data = request.json
        uid = data.get('uid')
        position = data.get('position')
        report = data.get('report')

        if not uid or not report:
            return jsonify({"hata": "Veri eksik"}), 400

        # 1. Mülakatı 'mulakatlar' tablosuna yedekle
        yeni_mulakat = {
            "uid": uid,
            "position": position,
            "report": report,
            "tarih": datetime.datetime.utcnow()
        }
        interviews_collection.insert_one(yeni_mulakat)

        # 2. KULLANICIYA XP VE ROZET VERME (OYUNLAŞTIRMA)
        user_data = users_collection.find_one({"uid": uid})
        new_badge_earned = False
        kazanilan_xp = 50 # Her mülakat 50 XP verir

        if user_data:
            # Mevcut değerleri alıyoruz
            current_xp = user_data.get("level", {}).get("xp", 0)
            total_interviews = user_data.get("stats", {}).get("total_interviews", 0)
            badges = user_data.get("badges", [])

            # Yeni değerleri hesaplıyoruz
            new_total_interviews = total_interviews + 1
            
            # İlk Mülakat Rozeti Kontrolü
            if new_total_interviews == 1 and "ilk_mulakat" not in badges:
                badges.append("ilk_mulakat")
                new_badge_earned = True
                kazanilan_xp += 25 # Rozet bonusu olarak ekstra 25 XP!

            new_xp = current_xp + kazanilan_xp
            # Basit Seviye Sistemi (Her 100 XP'de 1 Seviye Atlar)
            new_level = (new_xp // 100) + 1
            
            # Kullanıcının profilini güncelliyoruz
            users_collection.update_one(
                {"uid": uid},
                {
                    "$set": {
                        "level.xp": new_xp,
                        "level.current": new_level,
                        "stats.total_interviews": new_total_interviews,
                        "badges": badges
                    }
                }
            )

        print(f"🏆 MÜLAKAT BİTTİ: UID={uid} | +{kazanilan_xp} XP Kazanıldı! | Yeni Rozet: {new_badge_earned}")
        
        return jsonify({
            "status": "success", 
            "message": "Mülakat başarıyla kaydedildi!",
            "gained_xp": kazanilan_xp,
            "badge_earned": new_badge_earned
        }), 201

    except Exception as e:
        print("❌ Mülakat Kayıt Hatası:", e)
        return jsonify({"status": "error", "message": str(e)}), 500

# ==========================================
# SOHBET API'Sİ (Süper Hafıza ve GPT-4o-mini)
# ==========================================
@app.route('/api/chat', methods=['POST'])
def chat_with_ai():
    try:
        data = request.get_json()
        kullanici_mesaji = data.get("message", "")
        uid = data.get("uid", "") # Flutter'dan artık kullanıcının kimliğini de isteyeceğiz

        if not kullanici_mesaji:
            return jsonify({"error": "Lütfen bir mesaj gönderin."}), 400

        # 1. Varsayılan Sistem Mesajı (Eğer kullanıcı giriş yapmamışsa)
        system_prompt = "Sen bir Mesleki Farkındalık Asistanısın. Kullanıcıya sıcak ve profesyonel bir dille kariyer tavsiyesi ver."

        # 2. SÜPER HAFIZA DEVREDE: Eğer UID geldiyse veritabanından kullanıcıyı bul
        if uid:
            user_data = users_collection.find_one({"uid": uid})
            if user_data:
                ad = user_data.get("ad", "Kullanıcı")
                
                # Test sonuçlarını güvenli bir şekilde çekiyoruz
                test_results = user_data.get("test_results", {})
                kisilik = test_results.get("kisilik", {}).get("result", "Henüz çözülmedi")
                meslek = test_results.get("meslek", {}).get("result", "Henüz çözülmedi")
                ingilizce = test_results.get("ingilizce", {}).get("result", "Henüz çözülmedi")

                # OpenAI'ın beynine fısıldadığımız özel talimat:
                system_prompt = f"""
                Sen bir kariyer danışmanı ve mesleki farkındalık asistanısın. 
                Şu an konuştuğun kullanıcının adı: {ad}.
                
                Kullanıcının Test Sonuçları:
                - Kişilik Analizi: {kisilik}
                - Mesleki Eğilim: {meslek}
                - İngilizce Seviyesi: {ingilizce}
                
                Görevlerin:
                1. Kullanıcıya her zaman '{ad}' diye hitap et.
                2. Kariyer veya meslek tavsiyesi isterse, KESİNLİKLE yukarıdaki test sonuçlarına (özellikle kişilik ve mesleki eğilime) dayanarak cevap ver.
                3. Eğer test sonuçları 'Henüz çözülmedi' ise, daha iyi tavsiye verebilmek için onu 'Testler' sayfasından testleri çözmeye nazikçe teşvik et.
                """

        # 3. OpenAI üzerinden cevap üretiyoruz
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": kullanici_mesaji}
            ],
            temperature=0.7 # Biraz yaratıcılık iyidir
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
# YENİ: TEST SONUCUNU KAYDETME API'Sİ
# ==========================================
@app.route('/api/save_test', methods=['POST'])
def save_test():
    try:
        data = request.json
        uid = data.get('uid')
        test_type = data.get('test_type') # Örn: 'kisilik', 'meslek', 'ingilizce'
        result = data.get('result') # Örn: 'Analitik', 'Teknoloji', 'A2'

        if not uid or not test_type or not result:
            return jsonify({"hata": "Eksik veri gönderildi"}), 400

        # Dinamik Güncelleme: Hangi test geldiyse onu günceller
        update_field = {
            f"test_results.{test_type}.completed": True,
            f"test_results.{test_type}.result": result
        }

        # MongoDB'de kullanıcının sadece o testini günceller, diğerlerine dokunmaz
        users_collection.update_one(
            {"uid": uid},
            {"$set": update_field}
        )
        
        print(f"✅ TEST KAYDEDİLDİ: UID={uid} | Test={test_type} | Sonuç={result}")
        return jsonify({"status": "success", "message": f"{test_type} testi kaydedildi!"}), 200

    except Exception as e:
        print("❌ Test Kayıt Hatası:", e)
        return jsonify({"status": "error", "message": str(e)}), 500
    
 # ==========================================
# YENİ: GELİŞİM MERKEZİ (DASHBOARD) API'Sİ
# ==========================================
@app.route('/api/dashboard', methods=['POST'])
def get_dashboard_data():
    try:
        data = request.json
        uid = data.get('uid')

        if not uid:
            return jsonify({"hata": "UID eksik"}), 400

        user_data = users_collection.find_one({"uid": uid})
        
        if not user_data:
            return jsonify({"hata": "Kullanıcı bulunamadı"}), 404

        # Flutter'a gönderilecek paket (Sadece gerekli verileri filtreliyoruz)
        dashboard_data = {
            "ad": user_data.get("ad", "Kullanıcı"),
            "level": user_data.get("level", {"current": 1, "title": "Çaylak", "xp": 0, "xp_for_next": 100}),
            "stats": user_data.get("stats", {"total_chats": 0, "total_interviews": 0}),
            "badges": user_data.get("badges", []),
            "skill_scores": user_data.get("skill_scores", {"teknik": 0, "iletisim": 0, "liderlik": 0, "analitik": 0, "sosyal": 0}),
            "test_results": user_data.get("test_results", {}),
            "selected_career": user_data.get("selected_career", "Henüz Seçilmedi")
        }

        print(f"📊 DASHBOARD VERİSİ ÇEKİLDİ: {dashboard_data['ad']} (Seviye {dashboard_data['level']['current']})")
        return jsonify({"status": "success", "data": dashboard_data}), 200

    except Exception as e:
        print("❌ Dashboard Çekme Hatası:", e)
        return jsonify({"status": "error", "message": str(e)}), 500  
import json # Eğer en üstte yoksa bunu eklemeyi unutma

# ==========================================
# YENİ: YAPAY ZEKA YOL HARİTASI ÜRETİCİSİ
# ==========================================
@app.route('/api/generate_roadmap', methods=['POST'])
def generate_roadmap():
    try:
        data = request.json
        uid = data.get('uid')
        hedef_meslek = data.get('career', 'Yazılım Geliştirici') # Flutter'dan gelecek meslek hedefi

        user_data = users_collection.find_one({"uid": uid})
        if not user_data:
            return jsonify({"hata": "Kullanıcı bulunamadı"}), 404

        # Kullanıcının beynini (test sonuçlarını) çekiyoruz
        test_results = user_data.get("test_results", {})
        kisilik = test_results.get("kisilik", {}).get("result", "Bilinmiyor")
        ingilizce = test_results.get("ingilizce", {}).get("result", "Bilinmiyor")

        # OpenAI'a gönderilecek devasa JSON formatlama talimatı:
        prompt = f"""
        Sen uzman bir kariyer planlayıcısısın. Şu anki kullanıcının hedef mesleği: {hedef_meslek}.
        Kullanıcının Kişiliği: {kisilik}. İngilizce Seviyesi: {ingilizce}.
        
        Bana bu kullanıcı için 3 aşamalı (Başlangıç, Orta, İleri) kişiselleştirilmiş bir yol haritası oluştur.
        Cevabını SADECE AŞAĞIDAKİ JSON FORMATINDA VER, BAŞKA HİÇBİR KELİME (Markdown vb.) KULLANMA:
        {{
            "careerTitle": "{hedef_meslek}",
            "steps": [
                {{
                    "id": "s1",
                    "title": "Aşama Adı",
                    "subtitle": "Kısa açıklama",
                    "xpReward": 150,
                    "tasks": [
                        {{"id": "t1", "title": "Öğrenilecek konu 1"}},
                        {{"id": "t2", "title": "Öğrenilecek konu 2"}}
                    ]
                }}
            ]
        }}
        """

        # OpenAI API Çağrısı
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7
        )
        
        ai_cevap = response.choices[0].message.content.strip()
        
        # Eğer yapay zeka cevapta "```json" gibi markdown kullanırsa onu temizliyoruz
        if ai_cevap.startswith("```json"):
            ai_cevap = ai_cevap[7:-3].strip()
        elif ai_cevap.startswith("```"):
            ai_cevap = ai_cevap[3:-3].strip()

        # Metni JSON (Sözlük) formatına çevir
        roadmap_json = json.loads(ai_cevap)

        # MongoDB'ye bu yol haritasını kaydet!
        users_collection.update_one(
            {"uid": uid},
            {"$set": {"roadmap": roadmap_json, "selected_career": hedef_meslek}}
        )

        print(f"🗺️ YOL HARİTASI ÜRETİLDİ: UID={uid} | Hedef={hedef_meslek}")
        return jsonify({"status": "success", "roadmap": roadmap_json}), 200

    except Exception as e:
        print("❌ Yol Haritası Üretim Hatası:", e)
        return jsonify({"status": "error", "message": str(e)}), 500



# ==========================================
# SUNUCUYU ÇALIŞTIRAN KOD
# ==========================================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)