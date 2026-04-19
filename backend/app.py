import os
import certifi
import datetime
import json
import pdfkit
import requests
from flask import Flask, jsonify, request, send_file, render_template
from flask_cors import CORS
from openai import OpenAI  # OpenAI kütüphanesini kullanıyoruz
from dotenv import load_dotenv
from pymongo import MongoClient
from jinja2 import Environment, FileSystemLoader
from bson.objectid import ObjectId

# .env dosyasındaki gizli şifrelerimizi yüklüyoruz
load_dotenv()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# ==========================================
# 🚀 YENİ EKLENEN: PDF MOTORU AYARI
# ==========================================
# DİKKAT: Bilgisayarındaki wkhtmltopdf kurulum yolu burası olmalı. Farklıysa burayı değiştir.
path_to_wkhtmltopdf = r'C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe'
pdf_config = pdfkit.configuration(wkhtmltopdf=path_to_wkhtmltopdf)

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

# YENİ VE SADELEŞMİŞ KULLANICI ŞABLONU (v3)
@app.route('/api/kayit', methods=['POST'])
def kayit():
    data = request.json
    uid = data.get('uid')
    ad = data.get('ad')
    email = data.get('email')

    if not uid or not email:
        return jsonify({"hata": "Eksik bilgi"}), 400

    # Kullanıcı veritabanında var mı kontrolü
    mevcut_kullanici = users_collection.find_one({"uid": uid})
    if mevcut_kullanici:
        return jsonify({"mesaj": "Kullanıcı zaten kayıtlı"}), 200

    # Yeni, sade ve profesyonel şablon (XP/Level/Rozet kaldırıldı)
    yeni_kullanici = {
        "uid": uid,
        "ad": ad,
        "email": email,
        "credits": 100, # HOŞ GELDİN HEDİYESİ: 100 JETON 🪙
        "test_results": {},
        "skill_scores": {
            "teknik": 0, "iletisim": 0, "liderlik": 0, "analitik": 0, "sosyal": 0
        },
        "tarih": datetime.datetime.utcnow()
    }
    users_collection.insert_one(yeni_kullanici)
    yeni_kullanici["_id"] = str(yeni_kullanici["_id"])
    print(f"✅ YENİ KULLANICI KAYDEDİLDİ: {ad} | Bakiye: 100 Jeton")
    
    return jsonify({"mesaj": "Kayıt başarılı", "kullanici": yeni_kullanici}), 201

# ==========================================
# SADELEŞTİRİLMİŞ MÜLAKAT YEDEKLEME (XP İptal Edildi)
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

        # Sadece mülakatı yedekle (Arka planda XP verme işlemi silindi)
        yeni_mulakat = {
            "uid": uid,
            "position": position,
            "report": report,
            "tarih": datetime.datetime.utcnow()
        }
        interviews_collection.insert_one(yeni_mulakat)

        print(f"📝 MÜLAKAT YEDEKLENDİ: UID={uid} | Pozisyon={position}")
        return jsonify({"status": "success", "message": "Mülakat başarıyla kaydedildi!"}), 201

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
# YENİ: PROFİL VE CÜZDAN (CÜZDAN BİLGİSİ VE RADAR VERİSİ)
# ==========================================
@app.route('/api/get_profile', methods=['POST'])
def get_profile():
    try:
        data = request.json
        uid = data.get('uid')

        if not uid:
            return jsonify({"hata": "UID eksik"}), 400

        user_data = users_collection.find_one({"uid": uid})
        if not user_data:
            return jsonify({"hata": "Kullanıcı bulunamadı"}), 404

        # Sadece lazım olan temiz verileri gönderiyoruz
        profile_data = {
            "ad": user_data.get("ad", "Kullanıcı"),
            "credits": user_data.get("credits", 0), # Jeton Bakiyesi 🪙
            "skill_scores": user_data.get("skill_scores", {"teknik": 0, "iletisim": 0, "liderlik": 0, "analitik": 0, "sosyal": 0}),
            "test_results": user_data.get("test_results", {})
        }

        print(f"💳 PROFİL ÇEKİLDİ: {profile_data['ad']} | Bakiye: {profile_data['credits']} Jeton")
        return jsonify({"status": "success", "data": profile_data}), 200

    except Exception as e:
        print("❌ Profil Çekme Hatası:", e)
        return jsonify({"status": "error", "message": str(e)}), 500

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


# HTML Şablonlarının duracağı klasörü ayarla
template_env = Environment(loader=FileSystemLoader('templates'))

@app.route('/api/generate_cv', methods=['POST'])
def generate_cv():
    try:
        data = request.json
        uid = data.get('uid')
        kisisel_bilgiler = data.get('bilgiler')
        secilen_sablon = data.get('sablon_id', 'klasik')
        cv_dili = data.get('cv_dili', 'Türkçe')
        github_username = data.get('github_username', '').strip() # 🚀 YENİ: GitHub Kullanıcı Adı

        # 1. AKILLI FİYATLANDIRMA
        cv_maliyeti = 30 if secilen_sablon in ['modern', 'teknik'] else 2
        if github_username:
            cv_maliyeti += 20 # GitHub özelliği eklenirse +20 jeton daha kes!
            
        user = users_collection.find_one({"uid": uid})
        mevcut_kredi = user.get("credits", 0) if user else 0
        
        if mevcut_kredi < cv_maliyeti:
            return jsonify({
                "error": "Yetersiz Jeton!", 
                "current": mevcut_kredi,
                "required": cv_maliyeti
            }), 402

        # 2. GITHUB'DAN PROJE ÇEKME (Derin Analiz - README Okuma)
        github_projeleri = ""
        if github_username:
            try:
                gh_url = f"https://api.github.com/users/{github_username}/repos?sort=updated&per_page=3"
                gh_response = requests.get(gh_url)
                if gh_response.status_code == 200:
                    repos = gh_response.json()
                    repo_ozetleri = []
                    
                    for repo in repos:
                        isim = repo.get('name', 'Proje')
                        dil = repo.get('language') or 'Çeşitli'
                        aciklama = repo.get('description') or ''

                        # README dosyasını çekme operasyonu!
                        readme_icerik = ""
                        readme_url = f"https://api.github.com/repos/{github_username}/{isim}/readme"
                        headers = {"Accept": "application/vnd.github.v3.raw"} 
                        readme_response = requests.get(readme_url, headers=headers)
                        
                        if readme_response.status_code == 200:
                            readme_icerik = readme_response.text[:600].replace('\n', ' ') 
                            
                        detay = readme_icerik if readme_icerik else aciklama
                        if not detay or detay.isspace():
                            detay = f"{dil} programlama dili mimarisi kullanılarak geliştirilmiş teknik yazılım projesi ve kod deposu."

                        repo_ozetleri.append(f"📌 Proje: {isim} | Dil: {dil} | Detaylı İçerik: {detay}")
                        
                    github_projeleri = "\n".join(repo_ozetleri)
                    print(f"✅ GITHUB DERİN ANALİZ BAŞARILI! Çekilen Veriler:\n{github_projeleri}")
                else:
                    print(f"❌ GITHUB BULUNAMADI! Durum Kodu: {gh_response.status_code}")
            except Exception as e:
                print("❌ GitHub Çekme Hatası:", e)

        # 3. AI DOKUNUŞU
        test_ozeti = str(user.get("test_results", {})) if user else ""
        
        ai_prompt = f"""
        Kullanıcı Bilgileri: {kisisel_bilgiler}. 
        Kullanıcının GitHub'dan çekilen güncel projeleri (VARSA): 
        {github_projeleri}
        
        GÖREVİN:
        1. Bu kişi için profesyonel bir CV 'Özet/Hakkımda' yazısı yaz.
        2. ÇIKTI DİLİ KESİNLİKLE {cv_dili} OLMALIDIR.
        3. Eğitimi, yetenekleri ve dilleri düzenle.
        4. ÇOK ÖNEMLİ (PROJELER KISMI): 'projeler' alanına ASLA parantezli, köşeli ayraçlı raw (ham) veri, array veya sözlük koyma! İK uzmanının okuyacağı şık bir düz metne (string) çevir. Her proje için şu formatı KESİNLİKLE KORU:
        
        📌 Proje: [Proje Adı] | Dil: [Kullanılan Dil]
        - [Doğrudan projenin ne işe yaradığını ve değerini anlatan profesyonel açıklama]
        
        (Projeler arasına mutlaka boşluk bırakarak alt satıra geç)
        
        SADECE JSON FORMATINDA CEVAP VER:
        {{ "hakkimda": "...", "egitim": "...", "deneyim": "...", "yetenekler": "...", "projeler": "...", "diller": "..." }}
        """
        
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            response_format={ "type": "json_object" },
            messages=[{"role": "system", "content": "Sen profesyonel bir IK uzmanısın."},
                      {"role": "user", "content": ai_prompt}]
        )
        
        ai_sonuc = json.loads(response.choices[0].message.content)

        # Flutter'dan gelen özel dosya adını alıyoruz (Aşağıdaydı, yukarı taşıdık)
        gelen_dosya_adi = data.get('dosya_adi', f"cv_{uid}.pdf")

        # ==========================================
        # 🚀 4. HTML ŞABLONUNU DOLDURMA (GÜNCELLENDİ)
        # ==========================================
        # template_env yerine Flask'ın kendi render_template fonksiyonunu kullanıyoruz 
        # (Çünkü CSS çekmek için kullandığımız url_for sadece bu şekilde çalışır)
        from flask import render_template
        html_content = render_template(
            f'{secilen_sablon}.html',
            ad=kisisel_bilgiler.get('ad', ''),
            meslek=kisisel_bilgiler.get('meslek', ''),
            email=kisisel_bilgiler.get('email', ''),
            telefon=kisisel_bilgiler.get('telefon', ''),
            linkedin=kisisel_bilgiler.get('linkedin', ''),
            hakkimda=ai_sonuc.get('hakkimda', ''),
            egitim=ai_sonuc.get('egitim', ''),
            deneyim=ai_sonuc.get('deneyim', ''),
            yetenekler=ai_sonuc.get('yetenekler', ''),
            projeler=ai_sonuc.get('projeler', ''),
            diller=ai_sonuc.get('diller', '')
        )

        # ==========================================
        # 🚀 5. PDF'E DÖNÜŞTÜRME (GÜNCELLENDİ)
        # ==========================================
        # PDF Motoruna "static" klasörüne (CSS'e) erişim izni veriyoruz
        secenekler = {
            'enable-local-file-access': "", 
            'encoding': "UTF-8",
            'margin-top': '0mm',
            'margin-right': '0mm',
            'margin-bottom': '0mm',
            'margin-left': '0mm'
        }

        # Önceden hepsi cv_uid.pdf olarak kaydolup birbirini eziyordu. Artık benzersiz adla kaydolacak.
        pdf_path = f"generated_cvs/{gelen_dosya_adi}" 
        if not os.path.exists('generated_cvs'): os.makedirs('generated_cvs')
        
        # 'options=secenekler' parametresi eklendi
        pdfkit.from_string(html_content, pdf_path, configuration=pdf_config, options=secenekler)

        # 6. JETON DÜŞME
        users_collection.update_one(
            {"uid": uid},
            {"$inc": {"credits": -cv_maliyeti}}
        )
        print(f"🪙 JETON DÜŞÜLDÜ: {uid} | Harcanan: {cv_maliyeti} | Kalan: {mevcut_kredi - cv_maliyeti}")
        
        # 7. CV ARŞİVİNE KAYDET
        cv_kaydi = {
            "uid": uid,
            "dosya_adi": gelen_dosya_adi, 
            "tarih": datetime.datetime.now(),
            "sablon": secilen_sablon,
            "dil": cv_dili,
            "hedef_meslek": kisisel_bilgiler.get('meslek', '')
        }
        db.cv_arsivi.insert_one(cv_kaydi)

        return send_file(pdf_path, as_attachment=True)

    except Exception as e:
        print("❌ CV Üretim Hatası:", e)
        return jsonify({"error": str(e)}), 500
    
@app.route('/api/get_user', methods=['POST'])
def get_user():
    try:
        data = request.json
        uid = data.get('uid')
        
        user = users_collection.find_one({"uid": uid})
        if user:
            user["_id"] = str(user["_id"]) # ObjectId'yi metne çeviriyoruz (Çökme koruması)
            return jsonify(user), 200
        else:
            return jsonify({"error": "Kullanıcı bulunamadı"}), 404
            
    except Exception as e:
        print("❌ Kullanıcı Bilgisi Çekme Hatası:", e)
        return jsonify({"error": str(e)}), 500


@app.route('/api/get_cv_history', methods=['POST'])
def get_cv_history():
    try:
        data = request.json
        uid = data.get('uid')
        
        # Kullanıcıya ait tüm CV kayıtlarını tarihe göre sondan başa getir
        arsiv = list(db.cv_arsivi.find({"uid": uid}).sort("tarih", -1))
        
        for item in arsiv:
            item["_id"] = str(item["_id"])
            # Tarihi okunabilir formata çevir
            item["tarih"] = item["tarih"].strftime("%d.%m.%Y %H:%M")
            
        return jsonify(arsiv), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/delete_cv', methods=['POST'])
def delete_cv():
    try:
        data = request.json
        uid = data.get('uid')
        cv_id = data.get('cv_id') # MongoDB'nin verdiği benzersiz ID
        
        # Sadece ilgili kullanıcıya ait olan kaydı siliyoruz (Güvenlik için)
        result = db.cv_arsivi.delete_one({"_id": ObjectId(cv_id), "uid": uid})
        
        if result.deleted_count > 0:
            return jsonify({"message": "CV başarıyla silindi"}), 200
        else:
            return jsonify({"error": "Kayıt bulunamadı"}), 404
            
    except Exception as e:
        print("❌ CV Silme Hatası:", e)
        return jsonify({"error": str(e)}), 500

# ==========================================
# SUNUCUYU ÇALIŞTIRAN KOD
# ==========================================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)