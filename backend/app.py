import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from groq import Groq
from dotenv import load_dotenv

# .env dosyasındaki yeni şifremizi yüklüyoruz
load_dotenv()

app = Flask(__name__)
CORS(app)

# Groq İstemcisini Başlatıyoruz
client = Groq(api_key=os.getenv("GROQ_API_KEY"))

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
        chat_completion = client.chat.completions.create(
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

if __name__ == '__main__':
    app.run(debug=True, port=5000)