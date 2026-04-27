import os
from dotenv import load_dotenv
from pymongo import MongoClient

# 1. .env KASASINI AÇIYORUZ
load_dotenv()

# .env dosyasındaki değişkenin adı neyse buraya onu yazıyoruz (Örn: MONGO_URI)
MONGO_URI = os.getenv("MONGO_URI") 

if not MONGO_URI:
    print("❌ HATA: .env dosyasında MONGO_URI bulunamadı!")
    exit()

try:
    client = MongoClient(MONGO_URI)
    # Veritabanı adının kendi sisteminle aynı olduğuna emin ol
    db = client.kariyer_asistani_db 
    tests_collection = db.tests_collection

    # 2. ESKİ TESTLERİ TEMİZLE (Çakışma olmasın diye)
    tests_collection.delete_many({})
    print("🧹 Eski test kalıntıları temizlendi.")

    # 3. YENİ VE GERÇEK TEST VERİLERİ
    gercek_testler = [
        {
            "_id": "riasec_meslek",
            "baslik": "Kariyer Eğilim Testi (RIASEC)",
            "aciklama": "Holland'ın mesleki ilgi tipolojisine göre hangi çalışma ortamına ve mesleklere uygun olduğunu keşfet.",
            "kategori": "Meslek Seçimi",
            "soru_sayisi": 6,
            "sorular": [
                {"id": "q1", "soru": "Makinelerle, aletlerle veya araçlarla çalışmayı insanlarla çalışmaya tercih ederim.", "secenekler": [
                    {"metin": "Kesinlikle Katılıyorum", "deger": "Gerçekçi"},
                    {"metin": "Katılıyorum", "deger": "Gerçekçi"},
                    {"metin": "Emin Değilim", "deger": "Belirsiz"},
                    {"metin": "Katılmıyorum", "deger": "Sosyal"}
                ]},
                {"id": "q2", "soru": "Karmaşık problemleri çözmek, verileri analiz etmek ve araştırma yapmak bana heyecan verir.", "secenekler": [
                    {"metin": "Kesinlikle Katılıyorum", "deger": "Araştırmacı"},
                    {"metin": "Katılıyorum", "deger": "Araştırmacı"},
                    {"metin": "Emin Değilim", "deger": "Belirsiz"},
                    {"metin": "Katılmıyorum", "deger": "Geleneksel"}
                ]},
                {"id": "q3", "soru": "Kuralların esnek olduğu, kendi başıma yeni fikirler ve tasarımlar üretebildiğim ortamlarda mutluyum.", "secenekler": [
                    {"metin": "Kesinlikle Katılıyorum", "deger": "Sanatçı"},
                    {"metin": "Katılıyorum", "deger": "Sanatçı"},
                    {"metin": "Emin Değilim", "deger": "Belirsiz"},
                    {"metin": "Katılmıyorum", "deger": "Geleneksel"}
                ]},
                {"id": "q4", "soru": "İnsanlara bir şeyler öğretmek, onlara yardım etmek ve gelişimlerine katkı sağlamak en büyük motivasyonumdur.", "secenekler": [
                    {"metin": "Kesinlikle Katılıyorum", "deger": "Sosyal"},
                    {"metin": "Katılıyorum", "deger": "Sosyal"},
                    {"metin": "Emin Değilim", "deger": "Belirsiz"},
                    {"metin": "Katılmıyorum", "deger": "Gerçekçi"}
                ]},
                {"id": "q5", "soru": "Bir projeyi yönetmek, insanları ikna etmek ve liderlik pozisyonunda olmak bana çok doğal gelir.", "secenekler": [
                    {"metin": "Kesinlikle Katılıyorum", "deger": "Girişimci"},
                    {"metin": "Katılıyorum", "deger": "Girişimci"},
                    {"metin": "Emin Değilim", "deger": "Belirsiz"},
                    {"metin": "Katılmıyorum", "deger": "Araştırmacı"}
                ]},
                {"id": "q6", "soru": "Verilerin düzenli olduğu, net kuralların bulunduğu ve ofis düzeninde çalışan sistemleri severim.", "secenekler": [
                    {"metin": "Kesinlikle Katılıyorum", "deger": "Geleneksel"},
                    {"metin": "Katılıyorum", "deger": "Geleneksel"},
                    {"metin": "Emin Değilim", "deger": "Belirsiz"},
                    {"metin": "Katılmıyorum", "deger": "Sanatçı"}
                ]}
            ]
        },
        {
            "_id": "kisilik_big5",
            "baslik": "Kişilik Envanteri",
            "aciklama": "Beş Faktör Kişilik kuramına göre çalışma tarzını, stres yönetimini ve ekip uyumunu analiz et.",
            "kategori": "Kişisel Gelişim",
            "soru_sayisi": 4,
            "sorular": [
                {"id": "q1", "soru": "Kalabalık ortamlarda bulunmak ve yeni insanlarla tanışmak bana enerji verir.", "secenekler": [
                    {"metin": "Kesinlikle Katılıyorum", "deger": "Dışa Dönük"},
                    {"metin": "Biraz Katılıyorum", "deger": "Dışa Dönük"},
                    {"metin": "Katılmıyorum", "deger": "İçe Dönük"}
                ]},
                {"id": "q2", "soru": "Bir işe başlamadan önce tüm detayları planlar, son dakika sürprizlerinden nefret ederim.", "secenekler": [
                    {"metin": "Kesinlikle Katılıyorum", "deger": "Planlı ve Analitik"},
                    {"metin": "Biraz Katılıyorum", "deger": "Planlı ve Analitik"},
                    {"metin": "Katılmıyorum", "deger": "Esnek ve Spontane"}
                ]},
                {"id": "q3", "soru": "Baskı ve stres altındayken bile sakinliğimi koruyabilir, mantıklı kararlar alabilirim.", "secenekler": [
                    {"metin": "Kesinlikle Katılıyorum", "deger": "Strese Dayanıklı"},
                    {"metin": "Duruma Göre Değişir", "deger": "Duygusal"},
                    {"metin": "Katılmıyorum", "deger": "Hassas ve Fevri"}
                ]},
                {"id": "q4", "soru": "Alışılmışın dışında düşünmeyi, yeni teknolojileri ve farklı yöntemleri denemeyi çok severim.", "secenekler": [
                    {"metin": "Kesinlikle Katılıyorum", "deger": "Yenilikçi"},
                    {"metin": "Duruma Göre Değişir", "deger": "Geleneksel"},
                    {"metin": "Katılmıyorum", "deger": "Geleneksel"}
                ]}
            ]
        }
    ]

    # 4. VERİTABANINA YAZDIR
    tests_collection.insert_many(gercek_testler)
    print("✅ MÜKEMMEL! Gerçek test soruları veritabanına başarıyla eklendi.")

except Exception as e:
    print(f"❌ Hata oluştu: {e}")