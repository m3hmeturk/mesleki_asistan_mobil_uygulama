import os
import io
import certifi
import datetime
import json
import platform
import requests
import base64
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

# (Eski pdfkit ayarları tamamen silindi)

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
        # ==========================================
        # 🚀 1. DEĞİŞİKLİK: VERİLERİ JSON YERİNE FORM OLARAK ALIYORUZ
        # ==========================================
        uid = request.form.get('uid')
        secilen_sablon = request.form.get('sablon_id', 'klasik')
        cv_dili = request.form.get('cv_dili', 'Türkçe')
        github_username = request.form.get('github_username', '').strip()
        
        # 🌟 YENİ: Flutter'dan gelen Kariyer DNA'sını (Psikolojik Özellikleri) yakalıyoruz!
        dna_context = request.form.get('dna_context', '').strip()

        # Flutter'dan form alanları olarak gelen bilgileri senin sözlüğüne paketliyoruz
        kisisel_bilgiler = {
            'ad': request.form.get('ad', ''),
            'meslek': request.form.get('meslek', ''),
            'email': request.form.get('email', ''),
            'telefon': request.form.get('telefon', ''),
            'linkedin': request.form.get('linkedin', ''),
            'egitim': request.form.get('egitim', ''),
            'deneyim': request.form.get('deneyim', ''),
            'yetenekler': request.form.get('yetenekler', ''),
            'projeler': request.form.get('projeler', ''),
            'diller': request.form.get('diller', '')
        }

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
        
        # Yapay zekaya gidecek bilgilerin kopyası (Artık içinde Base64 foto yok, sadece form verileri var)
        ai_icin_bilgiler = kisisel_bilgiler.copy()
        
        ai_prompt = f"""
        Kullanıcı Bilgileri: {ai_icin_bilgiler}.
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
        
        # 🌟 İŞTE DÜZELTİLEN KISIM BURASI (dnaContext yerine dna_context yazıldı)
        if dna_context:
            ai_prompt += f"\n\n🚨 ÖNEMLİ PSİKOLOJİK PROFİL (Kariyer DNA'sı): Kullanıcının çözdüğü kişilik testlerine göre baskın özellikleri şunlardır: {dna_context}. Lütfen üreteceğin 'hakkimda' özetinde adayın bu karakteristik güçlerini ve çalışma stilini mutlaka vurgula! Adeta onu yıllardır tanıyan bir İK uzmanı gibi kişiselleştirilmiş bir dil kullan.\n"
        
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            response_format={ "type": "json_object" },
            messages=[{"role": "system", "content": "Sen profesyonel bir IK uzmanısın."},
                      {"role": "user", "content": ai_prompt}]
        )
        
        ai_sonuc = json.loads(response.choices[0].message.content)

        # Flutter'dan gelen özel dosya adını alıyoruz (request.form'dan)
        gelen_dosya_adi = request.form.get('dosya_adi', f"cv_{uid}.pdf")

        # ==========================================
        # 🚀 4. HTML ŞABLONUNU DOLDURMA
        # ==========================================
        from flask import render_template
        import os 
        
        # 1. Hangi şablon seçildiyse onun CSS dosyasının yolunu bul
        css_yolu = f"static/css/{secilen_sablon}_style.css"
        css_kodlari = ""
        
        # 2. Eğer öyle bir CSS dosyası varsa (örneğin modern_style.css), içindeki kodları oku
        if os.path.exists(css_yolu):
            with open(css_yolu, 'r', encoding='utf-8') as f:
                css_kodlari = f.read()

        # ==========================================
        # 🚀 2. DEĞİŞİKLİK: FOTOĞRAFI "HAVADA" YAKALAYIP GÖMME
        # ==========================================
        import base64
        pdf_uyumlu_yol = ""
        
        if 'profil_foto' in request.files:
            foto = request.files['profil_foto']
            if foto.filename != '':
                # 1. Fotoğrafın GERÇEK formatını öğreniyoruz (image/jpeg, image/png vb.)
                mime_tipi = foto.content_type
                
                # 2. Dosyayı klasöre KAYDETMEDEN doğrudan okuyup şifreliyoruz
                resim_verisi = base64.b64encode(foto.read()).decode('utf-8')
                
                # 3. PDF motoruna kendi anladığı dilde, doğru kimlikle teslim ediyoruz
                pdf_uyumlu_yol = f"data:{mime_tipi};base64,{resim_verisi}"
                print(f"📸 TRUVA ATI 2.0 BAŞARILI: Format -> {mime_tipi}")

        # 3. HTML'e hem bilgileri, hem okuduğumuz CSS kodlarını, hem de KALİTELİ FOTO YOLUNU gönder
        html_content = render_template(
            f'{secilen_sablon}.html',
            css_kodlari=css_kodlari, 
            profil_foto=pdf_uyumlu_yol,  
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
        # 🚀 5. PDF'E DÖNÜŞTÜRME (VERCEL CHROME MOTORU)
        # ==========================================
        VERCEL_API_URL = "https://pdf-motoru.vercel.app/api/generate"

        try:
            print("1. Vercel'e istek atılıyor...", flush=True)
            response = requests.post(VERCEL_API_URL, json={"html": html_content})
            print(f"2. Vercel'den cevap geldi! Status Code: {response.status_code}", flush=True)

            if response.status_code == 200:
                print(f"3. PDF başarıyla üretildi! Boyut: {len(response.content)} bayt", flush=True)
                
                # 🚀 6. JETON DÜŞME (Dosyayı göndermeden hemen önce)
                users_collection.update_one(
                    {"uid": uid},
                    {"$inc": {"credits": -cv_maliyeti}}
                )
                print(f"🪙 JETON DÜŞÜLDÜ: {uid} | Harcanan: {cv_maliyeti}")

                # 🚀 7. CV ARŞİVİNE KAYDET
                cv_kaydi = {
                    "uid": uid,
                    "dosya_adi": gelen_dosya_adi, 
                    "tarih": datetime.datetime.now(),
                    "sablon": secilen_sablon,
                    "dil": cv_dili,
                    "hedef_meslek": kisisel_bilgiler.get('meslek', '')
                }
                db.cv_arsivi.insert_one(cv_kaydi)

                # 🚀 8. ŞİMDİ DOSYAYI TESLİM ET
                pdf_data = io.BytesIO(response.content)
                return send_file(
                    pdf_data, 
                    mimetype='application/pdf', 
                    as_attachment=True, 
                    download_name=gelen_dosya_adi
                )
            else:
                print(f"HATA: Vercel'den 200 dönmedi. Gelen Cevap: {response.text}", flush=True)
                return jsonify({"error": "Vercel Hatası", "details": response.text}), 500

        except Exception as e:
            print(f"KRİTİK HATA: Vercel'e hiç bağlanılamadı. Detay: {str(e)}", flush=True)
            return jsonify({"error": "Bağlantı Hatası", "details": str(e)}), 500

    except Exception as e:
        print("❌ CV Üretim Genel Hatası:", e)
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
# 🚀 KARİYER TESTLERİ API'LERİ (YENİ SİSTEM)
# ==========================================

@app.route('/api/setup_tests', methods=['GET'])
def setup_tests():
    """
    Kariyer DNA'sı 3 Katmanlı Test Sistemini MongoDB'ye kurar.
    Tüm sorular metinsel (çoktan seçmeli) formatta düzenlenmiştir.
    """
    try:
        # ESKİ VERİLERİ TEMİZLE
        db.tests_collection.drop() 

        testler_listesi = [
            # --- KATMAN 1: KENDİNİ TANI (Ücretsiz) ---
            {
                "_id": "kisilik_big5",
                "kategori": "KATMAN 1: Kendini Tanı",
                "kategori_alt_baslik": "Temel özelliklerini ve karakterini keşfet",
                "kategori_ikon": "Brain",
                "baslik": "Kişilik Envanteri (Big Five)",
                "soru_sayisi": 25, "sure_dk": 5, "premium_mu": False, "maliyet": 0,
                "sorular": [
                    {
                        "id": "q1", 
                        "soru": "Boş zamanlarında hangisini yapmayı tercih edersin?", 
                        "cevaplar": [
                            {"metin": "Arkadaşlarımla kalabalık bir ortama girmeyi", "deger": "Dışadönük"},
                            {"metin": "Sessiz bir odada kitap okumayı veya kod yazmayı", "deger": "Analitik"},
                            {"metin": "Yeni bir şeyler tasarlamayı veya çizmeyi", "deger": "Yaratıcı"}
                        ]
                    },
                    {
                        "id": "q2", 
                        "soru": "Bir grup çalışmasında genellikle hangi rolde olursun?", 
                        "cevaplar": [
                            {"metin": "Ekibi yönlendiren ve kararları veren", "deger": "Lider"},
                            {"metin": "Verilen görevleri titizlikle tamamlayan", "deger": "Sorumluluk"},
                            {"metin": "Fikirler üretip tartışmalara renk katan", "deger": "Açıklık"}
                        ]
                    }
                ]
            },
            {
                "_id": "degerler_schwartz",
                "kategori": "KATMAN 1: Kendini Tanı",
                "kategori_alt_baslik": "Seni hayatta neyin motive ettiğini anla",
                "kategori_ikon": "Brain",
                "baslik": "Değerler ve Motivasyon",
                "soru_sayisi": 15, "sure_dk": 3, "premium_mu": False, "maliyet": 0,
                "sorular": [
                    {
                        "id": "d1", 
                        "soru": "İş hayatında senin için hangisi daha önceliklidir?", 
                        "cevaplar": [
                            {"metin": "Yüksek bir kazanç ve maddi güvence", "deger": "Güç"},
                            {"metin": "Topluma faydalı olmak ve insanlara yardım etmek", "deger": "İyilikseverlik"},
                            {"metin": "Kendi kararlarımı alabileceğim bir özgürlük alanı", "deger": "Öz-yönetim"}
                        ]
                    }
                ]
            },

            # --- KATMAN 2: BECERİLERİNİ KEŞFET (Ücretsiz) ---
            {
                "_id": "kariyer_riasec",
                "kategori": "KATMAN 2: Becerilerini Keşfet",
                "kategori_alt_baslik": "İlgi alanlarını mesleklerle eşleştir",
                "kategori_ikon": "Briefcase",
                "baslik": "Meslek Seçimi (RIASEC)",
                "soru_sayisi": 30, "sure_dk": 6, "premium_mu": False, "maliyet": 0,
                "sorular": [
                    {
                        "id": "r1", 
                        "soru": "Aşağıdaki aktivitelerden hangisi sana daha çok keyif verir?", 
                        "cevaplar": [
                            {"metin": "Bozulan bir cihazı parçalarına ayırıp tamir etmek", "deger": "Gerçekçi (R)"},
                            {"metin": "Karmaşık bir problemi verilerle analiz etmek", "deger": "Araştırmacı (I)"},
                            {"metin": "İnsanlara bir şeyler öğretmek veya rehberlik etmek", "deger": "Sosyal (S)"}
                        ]
                    }
                ]
            },
            {
                "_id": "ingilizce_cefr",
                "kategori": "KATMAN 2: Becerilerini Keşfet",
                "kategori_alt_baslik": "Global yetkinliğini ve seviyeni ölç",
                "kategori_ikon": "Languages",
                "baslik": "İngilizce Yeterlilik (CEFR)",
                "soru_sayisi": 25, "sure_dk": 8, "premium_mu": False, "maliyet": 0,
                "sorular": [
                    {
                        "id": "e1", 
                        "soru": "Boşluğu doldur: 'If I ___ you, I would take that offer.'", 
                        "cevaplar": [
                            {"metin": "was", "deger": "A2"},
                            {"metin": "were", "deger": "B1/B2"},
                            {"metin": "am", "deger": "Hatalı"}
                        ]
                    }
                ]
            },
            {
                "_id": "dijital_yetkinlik",
                "kategori": "KATMAN 2: Becerilerini Keşfet",
                "kategori_alt_baslik": "Dijital dünyadaki gücünü test et",
                "kategori_ikon": "Languages",
                "baslik": "Dijital Yetkinlik",
                "soru_sayisi": 20, "sure_dk": 4, "premium_mu": False, "maliyet": 0,
                "sorular": [
                    {
                        "id": "dy1", 
                        "soru": "Bir yazılım hatasıyla karşılaştığında yaklaşımın ne olur?", 
                        "cevaplar": [
                            {"metin": "Hemen Google veya AI araçlarını kullanarak çözümü ararım", "deger": "Dijital Okuryazar"},
                            {"metin": "Hata kodunu not eder ve bir uzmana danışırım", "deger": "Temel Seviye"},
                            {"metin": "Kendi başıma deneme yanılma yoluyla çözmeye çalışırım", "deger": "Problem Çözücü"}
                        ]
                    }
                ]
            },

            # --- KATMAN 3: ÇALIŞMA STİLİN (5 Jeton) ---
            {
                "_id": "liderlik_belbin",
                "kategori": "KATMAN 3: Çalışma Stilin",
                "kategori_alt_baslik": "Ekip içindeki baskın rolünü belirle",
                "kategori_ikon": "Lock",
                "baslik": "Liderlik & Takım Rolü",
                "soru_sayisi": 15, "sure_dk": 3, "premium_mu": True, "maliyet": 5,
                "sorular": [
                    {
                        "id": "l1", 
                        "soru": "Bir projede beklenmedik bir kriz çıktığında ne yaparsın?", 
                        "cevaplar": [
                            {"metin": "Soğukkanlılığımı korur ve ekibe görev dağılımı yaparım", "deger": "Koordinatör"},
                            {"metin": "Hızlıca aksiyon alır ve sorunu doğrudan çözmeye odaklanırım", "deger": "Biçimlendirici"},
                            {"metin": "Krizin nedenlerini araştırıp veri toplarım", "deger": "Gözlemci"}
                        ]
                    }
                ]
            },
            {
                "_id": "calisma_ortami",
                "kategori": "KATMAN 3: Çalışma Stilin",
                "kategori_alt_baslik": "Senin için en verimli çalışma modelini bul",
                "kategori_ikon": "Lock",
                "baslik": "Çalışma Ortamı Tercihi",
                "soru_sayisi": 10, "sure_dk": 2, "premium_mu": True, "maliyet": 5,
                "sorular": [
                    {
                        "id": "co1", 
                        "soru": "Günlük enerjini en çok hangisi artırır?", 
                        "cevaplar": [
                            {"metin": "Evimdeki sessiz ve düzenli çalışma köşem", "deger": "Uzaktan"},
                            {"metin": "Ofisteki canlı ortam ve ekip arkadaşlarımla sohbet", "deger": "Ofis"},
                            {"metin": "Haftanın bir kısmını evde, bir kısmını ofiste geçirmek", "deger": "Hibrit"}
                        ]
                    }
                ]
            },
            {
                "_id": "girisimcilik_potansiyeli",
                "kategori": "KATMAN 3: Çalışma Stilin",
                "kategori_alt_baslik": "Kendi işini kurma ve risk alma eğilimin",
                "kategori_ikon": "Lock",
                "baslik": "Girişimcilik Potansiyeli",
                "soru_sayisi": 12, "sure_dk": 3, "premium_mu": True, "maliyet": 5,
                "sorular": [
                    {
                        "id": "g1", 
                        "soru": "Belirsizlik içeren bir iş fırsatı karşına çıksa ne yaparsın?", 
                        "cevaplar": [
                            {"metin": "Büyük resmi görür ve risk alarak üzerine giderim", "deger": "Girişimci"},
                            {"metin": "Tüm detayları analiz etmeden adım atmam", "deger": "Temkinli"},
                            {"metin": "Bunu bir yan proje olarak başlatıp sonuçları izlerim", "deger": "Stratejik"}
                        ]
                    }
                ]
            }
        ]

        db.tests_collection.insert_many(testler_listesi)
        return jsonify({"mesaj": "✅ Kariyer DNA'sı 3 Katmanlı Sistem Başarıyla Kuruldu!"}), 200
    except Exception as e:
        return jsonify({"hata": str(e)}), 500

@app.route('/api/tests', methods=['GET'])
def get_tests_list():
    """Flutter'daki Vitrin sayfası için testleri listeler (Sorular hariç, hafif data)"""
    try:
        # Soruları Flutter'a yollamayarak internet tasarrufu yapıyoruz
        testler = list(db.tests_collection.find({}, {"sorular": 0})) 
        return jsonify(testler), 200
    except Exception as e:
        return jsonify({"hata": str(e)}), 500

@app.route('/api/test/<test_id>/questions', methods=['GET'])
def get_test_questions(test_id):
    """Kullanıcı bir teste tıkladığında sadece o testin sorularını getirir"""
    try:
        test = db.tests_collection.find_one({"_id": test_id}, {"sorular": 1})
        if test:
            return jsonify({"test_id": test_id, "sorular": test.get("sorular", [])}), 200
        return jsonify({"hata": "Test bulunamadı"}), 404
    except Exception as e:
        return jsonify({"hata": str(e)}), 500

@app.route('/api/test/<test_id>/submit', methods=['POST'])
def submit_test(test_id):
    """Kullanıcının cevaplarını analiz eder ve veritabanına Kariyer DNA'sı olarak kaydeder."""
    try:
        data = request.json
        cevaplar = data.get('cevaplar', {}) 
        
        if not cevaplar:
            return jsonify({"hata": "Hiç cevap gönderilmedi!"}), 400

        # Frekans Analizi (En çok hangi özellik seçilmiş?)
        sonuc_analizi = {}
        for soru_id, secilen_deger in cevaplar.items():
            sonuc_analizi[secilen_deger] = sonuc_analizi.get(secilen_deger, 0) + 1
            
        baskin_ozellik = max(sonuc_analizi, key=sonuc_analizi.get)
        
        # 🌟 YENİ: SONUCU VERİTABANINA KAYDETME
        kullanici_id = "demo_kullanici_1" # Şimdilik herkesi bu ID ile kaydediyoruz
        
        db.users_collection.update_one(
            {"_id": kullanici_id},
            {
                "$set": {f"kariyer_dna.{test_id}": baskin_ozellik}, # Örn: kariyer_dna.kisilik_big5: "Analitik"
                "$setOnInsert": {"kayit_tarihi": "2026-04"}
            },
            upsert=True # Kullanıcı yoksa yeni oluşturur
        )
        
        return jsonify({
            "mesaj": "✅ Test analizi tamamlandı ve hafızaya kaydedildi!",
            "baskin_ozellik": baskin_ozellik,
            "detayli_analiz": sonuc_analizi
        }), 200
        
    except Exception as e:
        return jsonify({"hata": str(e)}), 500

# 🌟 YENİ: İLERLEME ÇUBUĞUNU DOLDURMAK İÇİN YAZILAN SERVİS
@app.route('/api/user/progress', methods=['GET'])
def get_progress():
    """Kullanıcının bugüne kadar tamamladığı testlerin ID'lerini döndürür."""
    try:
        kullanici_id = "demo_kullanici_1"
        user = db.users_collection.find_one({"_id": kullanici_id})
        
        tamamlananlar = []
        if user and "kariyer_dna" in user:
            tamamlananlar = list(user["kariyer_dna"].keys()) # Çözülen testlerin ID listesi
            
        return jsonify({"tamamlanan_testler": tamamlananlar}), 200
    except Exception as e:
        return jsonify({"hata": str(e)}), 500

# 🌟 YENİ: YAPAY ZEKA İÇİN KARİYER DNA ÖZETİ
@app.route('/api/user/career_dna_summary', methods=['GET'])
def get_career_dna_summary():
    """Kullanıcının test sonuçlarını, Yapay Zeka'ya (Gemini) prompt olarak verilmek üzere metne çevirir."""
    try:
        kullanici_id = "demo_kullanici_1"
        user = db.users_collection.find_one({"_id": kullanici_id})
        
        if not user or "kariyer_dna" not in user or not user["kariyer_dna"]:
            return jsonify({"prompt_eklentisi": ""}), 200 # Test çözmediyse boş döner
            
        dna_verileri = user["kariyer_dna"]
        
        # Verileri yapay zekanın okuyacağı güzel bir Türkçe cümleye dönüştürüyoruz
        ozellikler = []
        for test_id, sonuc in dna_verileri.items():
            ozellikler.append(f"{sonuc}")
            
        birlestirilmis_ozellikler = ", ".join(ozellikler)
        
        # Bu metin doğrudan Gemini'ye gidecek "Sistem Komutunun" (System Prompt) bir parçası olacak
        ai_prompt_eklentisi = f"ÖNEMLİ PSİKOLOJİK PROFİL: Bu kullanıcının yapılan kariyer ve kişilik testleri sonucunda baskın özellikleri şunlardır: {birlestirilmis_ozellikler}. Lütfen üreteceğin CV'yi (Özgeçmişi) ve 'Hakkımda' yazısını bu karakter özelliklerini yansıtacak, profesyonel bir dille harmanlayarak yaz."
        
        return jsonify({"prompt_eklentisi": ai_prompt_eklentisi}), 200

    except Exception as e:
        return jsonify({"hata": str(e)}), 500

# ==========================================
# SUNUCUYU ÇALIŞTIRAN KOD
# ==========================================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)