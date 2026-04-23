# 1. Temel bir Linux ve Python bilgisayarı al
FROM python:3.11-slim

# 2. PDF motorumuzu (wkhtmltopdf) Linux'a zorla kur!
RUN apt-get update && apt-get install -y wkhtmltopdf

# 3. Çalışma klasörümüzü belirle
WORKDIR /app

# 4. Kütüphaneleri (requirements.txt) kopyala ve kur
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Tüm Python kodlarımızı kopyala
COPY . .

# 6. Gunicorn ile 8080 kapısından yayına başla
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]