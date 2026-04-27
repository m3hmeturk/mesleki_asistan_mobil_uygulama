import os
from dotenv import load_dotenv
from pymongo import MongoClient

# 1. .env KASASINI AÇIYORUZ
load_dotenv()
MONGO_URI = os.getenv("MONGO_URI") 

if not MONGO_URI:
    print("❌ HATA: .env dosyasında MONGO_URI bulunamadı!")
    exit()

try:
    client = MongoClient(MONGO_URI)
    
    # 2. DOĞRU DEPOYA BAĞLANTI (Senin asıl veritabanın)
    db = client["MeslekiAsistanDB"]
    tests_collection = db["tests_collection"]

    # 3. ESKİ TESTLERİ TEMİZLE (Çakışma olmasın)
    tests_collection.delete_many({})
    print("🧹 Eski test kalıntıları temizlendi. Yeni yapı kuruluyor...")

    # 4. 3 KATMANLI YENİ NESİL TESTLER (Senaryo Bazlı)
    testler_listesi = [
        # ==========================================
        # --- KATMAN 1: KENDİNİ TANI (Ücretsiz) ---
        # ==========================================
        {
            "_id": "kisilik_big5",
            "kategori": "KATMAN 1: Kendini Tanı",
            "kategori_alt_baslik": "Temel özelliklerini ve karakterini keşfet",
            "kategori_ikon": "Brain",
            "baslik": "Kişilik Envanteri (Big Five)",
            "soru_sayisi": 3, "sure_dk": 5, "premium_mu": False, "maliyet": 0,
            "sorular": [
                {
                    "id": "q1", 
                    "soru": "Boş zamanlarında hangisini yapmayı tercih edersin?", 
                    "cevaplar": [
                        {"metin": "Arkadaşlarımla kalabalık bir ortama girmeyi", "deger": "Dışadönük"},
                        {"metin": "Sessiz bir odada odaklanarak çalışmayı", "deger": "İçedönük"},
                        {"metin": "Yeni bir şeyler tasarlamayı veya çizmeyi", "deger": "Yaratıcı"}
                    ]
                },
                {
                    "id": "q2", 
                    "soru": "Bir projede çalışırken planlama tarzın nasıldır?", 
                    "cevaplar": [
                        {"metin": "Her adımı önceden detaylıca planlar ve takvime uyarım", "deger": "Sorumlu / Düzenli"},
                        {"metin": "Genel bir fikirle başlar, yolda esnek değişiklikler yaparım", "deger": "Esnek / Uyumlu"},
                        {"metin": "Son teslim tarihine kadar bekler, baskı altında hızlanırım", "deger": "Spontane"}
                    ]
                },
                {
                    "id": "q3", 
                    "soru": "Bir arkadaşın sana dert yandığında ilk tepkin ne olur?", 
                    "cevaplar": [
                        {"metin": "Hemen mantıklı bir çözüm yolu üretmeye çalışırım", "deger": "Analitik"},
                        {"metin": "Sadece dinler ve duygusal destek veririm", "deger": "Empatik"},
                        {"metin": "Olayı farklı bir bakış açısıyla görmesini sağlarım", "deger": "Yönlendirici"}
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
            "soru_sayisi": 3, "sure_dk": 3, "premium_mu": False, "maliyet": 0,
            "sorular": [
                {
                    "id": "d1", 
                    "soru": "İş hayatında senin için hangisi daha önceliklidir?", 
                    "cevaplar": [
                        {"metin": "Yüksek bir kazanç ve maddi güvence", "deger": "Güç ve Başarı"},
                        {"metin": "Topluma faydalı olmak ve insanlara yardım etmek", "deger": "İyilikseverlik"},
                        {"metin": "Kendi kararlarımı alabileceğim bir özgürlük alanı", "deger": "Öz-yönetim"}
                    ]
                },
                {
                    "id": "d2", 
                    "soru": "Yeni bir iş teklifi aldın. Seni en çok ne heyecanlandırır?", 
                    "cevaplar": [
                        {"metin": "Şirketin prestiji ve bana katacağı unvan", "deger": "Statü"},
                        {"metin": "Projenin yenilikçi olması ve dünyayı değiştirme potansiyeli", "deger": "Evrenselcilik"},
                        {"metin": "Çalışma saatlerinin rahatlığı ve iş-yaşam dengesi", "deger": "Güvenlik ve Konfor"}
                    ]
                },
                {
                    "id": "d3", 
                    "soru": "Bir lideri senin gözünde başarılı kılan en önemli şey nedir?", 
                    "cevaplar": [
                        {"metin": "Koyduğu kurallarla sistemi kusursuz işletmesi", "deger": "Geleneksellik"},
                        {"metin": "Ekibine ilham verip onları geliştirmesi", "deger": "İyilikseverlik"},
                        {"metin": "Rakiplerini geride bırakıp zirveye çıkması", "deger": "Güç ve Başarı"}
                    ]
                }
            ]
        },

        # ==========================================
        # --- KATMAN 2: BECERİLERİNİ KEŞFET (Ücretsiz) ---
        # ==========================================
        {
            "_id": "kariyer_riasec",
            "kategori": "KATMAN 2: Becerilerini Keşfet",
            "kategori_alt_baslik": "İlgi alanlarını mesleklerle eşleştir",
            "kategori_ikon": "Briefcase",
            "baslik": "Meslek Seçimi (RIASEC)",
            "soru_sayisi": 3, "sure_dk": 6, "premium_mu": False, "maliyet": 0,
            "sorular": [
                {
                    "id": "r1", 
                    "soru": "Aşağıdaki aktivitelerden hangisi sana daha çok keyif verir?", 
                    "cevaplar": [
                        {"metin": "Bozulan bir cihazı parçalarına ayırıp tamir etmek", "deger": "Gerçekçi (R)"},
                        {"metin": "Karmaşık bir problemi verilerle analiz etmek", "deger": "Araştırmacı (I)"},
                        {"metin": "İnsanlara bir şeyler öğretmek veya rehberlik etmek", "deger": "Sosyal (S)"}
                    ]
                },
                {
                    "id": "r2", 
                    "soru": "Bir şirkette çalışıyor olsan, hangi departmanda olmak istersin?", 
                    "cevaplar": [
                        {"metin": "Yeni bir pazarlama kampanyası tasarlayan yaratıcı ekipte", "deger": "Sanatçı (A)"},
                        {"metin": "Bütçe tablolarını ve şirket verilerini düzenleyen finans ekibinde", "deger": "Geleneksel (C)"},
                        {"metin": "Yeni müşteriler bağlayan ve şirketi temsil eden satış ekibinde", "deger": "Girişimci (E)"}
                    ]
                },
                {
                    "id": "r3", 
                    "soru": "Hangi tarz bir belgesel veya video izlemek daha çok ilgini çeker?", 
                    "cevaplar": [
                        {"metin": "Evrenin sırları ve yapay zeka teknolojileri", "deger": "Araştırmacı (I)"},
                        {"metin": "Tarihe yön veren liderlerin başarı hikayeleri", "deger": "Girişimci (E)"},
                        {"metin": "Farklı kültürlerin sanat ve mimari yapıları", "deger": "Sanatçı (A)"}
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
            "soru_sayisi": 3, "sure_dk": 4, "premium_mu": False, "maliyet": 0,
            "sorular": [
                {
                    "id": "dy1", 
                    "soru": "Bir yazılım hatasıyla veya bilmediğin bir programla karşılaştığında yaklaşımın ne olur?", 
                    "cevaplar": [
                        {"metin": "Hemen Google, forumlar veya AI araçlarını kullanarak çözümü ararım", "deger": "İleri Düzey"},
                        {"metin": "Uyarı mesajını not eder ve anlayan birine danışırım", "deger": "Temel Seviye"},
                        {"metin": "Bütün menüleri kurcalayarak deneme yanılma yoluyla çözerim", "deger": "Orta Düzey"}
                    ]
                },
                {
                    "id": "dy2", 
                    "soru": "Bir sunum veya rapor hazırlaman gerektiğinde hangi araçları kullanırsın?", 
                    "cevaplar": [
                        {"metin": "Sadece Word veya standart PowerPoint kullanırım", "deger": "Temel Seviye"},
                        {"metin": "Canva, Notion veya bulut tabanlı modern araçları tercih ederim", "deger": "İleri Düzey"},
                        {"metin": "İçeriği yazarım, tasarımla uğraşmayı pek sevmem", "deger": "Geleneksel"}
                    ]
                },
                {
                    "id": "dy3", 
                    "soru": "Yeni bir teknoloji trendi (Örn: ChatGPT, Web3) çıktığında tepkin ne olur?", 
                    "cevaplar": [
                        {"metin": "İlk deneyenlerden olur, günlük hayatıma nasıl entegre edeceğimi bulurum", "deger": "Yenilikçi (Erken Benimseyen)"},
                        {"metin": "İnsanlar kullanıp faydasını kanıtladıktan sonra kullanmaya başlarım", "deger": "Pragmatik"},
                        {"metin": "Mevcut düzenim çalışıyorsa yeni şeylere ihtiyaç duymam", "deger": "Geleneksel"}
                    ]
                }
            ]
        },

        # ==========================================
        # --- KATMAN 3: ÇALIŞMA STİLİN (5 Jeton) ---
        # ==========================================
        {
            "_id": "liderlik_belbin",
            "kategori": "KATMAN 3: Çalışma Stilin",
            "kategori_alt_baslik": "Ekip içindeki baskın rolünü belirle",
            "kategori_ikon": "Lock",
            "baslik": "Liderlik & Takım Rolü",
            "soru_sayisi": 3, "sure_dk": 3, "premium_mu": True, "maliyet": 5,
            "sorular": [
                {
                    "id": "l1", 
                    "soru": "Bir projede beklenmedik bir kriz çıktığında ne yaparsın?", 
                    "cevaplar": [
                        {"metin": "Soğukkanlılığımı korur ve ekibe görev dağılımı yaparım", "deger": "Koordinatör"},
                        {"metin": "Hızlıca aksiyon alır ve sorunu doğrudan çözmeye odaklanırım", "deger": "Biçimlendirici"},
                        {"metin": "Krizin nedenlerini araştırıp veri toplarım", "deger": "Gözlemci"}
                    ]
                },
                {
                    "id": "l2", 
                    "soru": "Ekip toplantılarında genelde nasıl bir tutum sergilersin?", 
                    "cevaplar": [
                        {"metin": "Konuşulanları not alır, fikirleri uygulanabilir planlara dökerim", "deger": "Uygulayıcı"},
                        {"metin": "Ortamı neşelendirir ve takımın enerjisini yüksek tutarım", "deger": "Takım Oyuncusu"},
                        {"metin": "Farklı kaynaklardan yeni fikirler ve stratejiler getiririm", "deger": "Kaşif"}
                    ]
                },
                {
                    "id": "l3", 
                    "soru": "Proje teslimine çok az kaldı ama detaylarda hatalar var. Ne yaparsın?", 
                    "cevaplar": [
                        {"metin": "Hataları düzeltmek için uykusuz kalır, her şeyin kusursuz olmasını sağlarım", "deger": "Tamamlayıcı (Mükemmeliyetçi)"},
                        {"metin": "Ana hedef çalışıyorsa küçük detayları görmezden gelip teslim ederim", "deger": "Sonuç Odaklı"},
                        {"metin": "Ekiptekileri toplar ve hataları hızlıca bölüştürürüm", "deger": "Koordinatör"}
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
            "soru_sayisi": 2, "sure_dk": 2, "premium_mu": True, "maliyet": 5,
            "sorular": [
                {
                    "id": "co1", 
                    "soru": "Günlük enerjini ve verimini en çok hangisi artırır?", 
                    "cevaplar": [
                        {"metin": "Evimdeki sessiz, kendi düzenimi kurduğum çalışma köşem", "deger": "Uzaktan (Remote)"},
                        {"metin": "Ofisteki canlı ortam ve ekip arkadaşlarımla yüz yüze sohbet", "deger": "Ofis İçi"},
                        {"metin": "Haftanın bir kısmını evde, bir kısmını ofiste geçirmek", "deger": "Hibrit"}
                    ]
                },
                {
                    "id": "co2", 
                    "soru": "Yöneticinin seninle nasıl iletişim kurmasını tercih edersin?", 
                    "cevaplar": [
                        {"metin": "Sadece hedefi versin, ne zaman ve nasıl yapacağıma ben karar vereyim", "deger": "Bağımsız Çalışma"},
                        {"metin": "Günlük olarak ilerlememi kontrol etsin ve yönlendirsin", "deger": "Yapılandırılmış Çalışma"},
                        {"metin": "İhtiyacım olduğunda ona ulaşabileyim, esnek bir bağımız olsun", "deger": "Esnek Çalışma"}
                    ]
                }
            ]
        }
    ]

    tests_collection.insert_many(testler_listesi)
    print("✅ BİNGGO! 3 Katmanlı yeni nesil test sistemi başarıyla kuruldu!")

except Exception as e:
    print(f"❌ Hata oluştu: {e}")